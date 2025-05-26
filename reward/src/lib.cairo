use starknet::ContractAddress;

#[starknet::interface]
trait IRewardContract<TContractState> {
    fn get_points(self: @TContractState, user: ContractAddress) -> felt252;
    fn add_points(ref self: TContractState, user: ContractAddress, points: felt252);
    fn redeem_points(ref self: TContractState, user: ContractAddress, points: felt252) -> felt252;
    fn transfer_points(ref self: TContractState, from: ContractAddress, to: ContractAddress, points: felt252);
}

#[starknet::contract]
mod RewardContract {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StoragePointerWriteAccess, StorageMapReadAccess, StorageMapWriteAccess};

    #[storage]
    struct Storage {
        // Mapping: user address -> points balance
        user_points: Map<ContractAddress, felt252>,
        owner: ContractAddress,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PointsAdded: PointsAdded,
        PointsRedeemed: PointsRedeemed,
        PointsTransferred: PointsTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct PointsAdded {
        #[key]
        user: ContractAddress,
        points: felt252,
        new_balance: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct PointsRedeemed {
        #[key]
        user: ContractAddress,
        points: felt252,
        remaining_balance: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct PointsTransferred {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        points: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl RewardContractImpl of super::IRewardContract<ContractState> {
        
        // Get points balance for a specific user
        fn get_points(self: @ContractState, user: ContractAddress) -> felt252 {
            self.user_points.read(user)
        }

        // Add points to a user's balance
        fn add_points(ref self: ContractState, user: ContractAddress, points: felt252) {
            let current_points = self.user_points.read(user);
            let new_balance = current_points + points;
            self.user_points.write(user, new_balance);
            
            // Emit event
            self.emit(Event::PointsAdded(PointsAdded {
                user: user,
                points: points,
                new_balance: new_balance,
            }));
        }

        // Redeem points from a user's balance
        fn redeem_points(ref self: ContractState, user: ContractAddress, points: felt252) -> felt252 {
            let current_points = self.user_points.read(user);
            
            // Check if user has enough points (using assert as required)
            let current_u256: u256 = current_points.into();
            let points_u256: u256 = points.into();
            assert(current_u256 >= points_u256, 'Not enough points to redeem');
            
            let remaining_balance = current_points - points;
            self.user_points.write(user, remaining_balance);
            
            // Emit event
            self.emit(Event::PointsRedeemed(PointsRedeemed {
                user: user,
                points: points,
                remaining_balance: remaining_balance,
            }));
            
            points
        }

        // Extra Challenge: Transfer points between users
        fn transfer_points(ref self: ContractState, from: ContractAddress, to: ContractAddress, points: felt252) {
            let caller = get_caller_address();
            
            // Only the owner of the points can transfer them
            assert(caller == from, 'Only point owner can transfer');
            
            let from_balance = self.user_points.read(from);
            let from_u256: u256 = from_balance.into();
            let points_u256: u256 = points.into();
            assert(from_u256 >= points_u256, 'Not enough points to transfer');
            
            let to_balance = self.user_points.read(to);
            
            // Update balances
            self.user_points.write(from, from_balance - points);
            self.user_points.write(to, to_balance + points);
            
            // Emit event
            self.emit(Event::PointsTransferred(PointsTransferred {
                from: from,
                to: to,
                points: points,
            }));
        }
    }
}