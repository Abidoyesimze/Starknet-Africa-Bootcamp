#[starknet::interface]

trait IStoreValueContract<TContractState> {

    fn get_value(ref self: TContractState, a: felt252);

    fn read_value(self: @TContractState) -> felt252;

 

}

 

#[starknet::contract]

mod StoreValueContract {

    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

 

    #[storage]

    struct Storage {

        stored_value: felt252,

    }

 

    #[abi(embed_v0)]

    impl StoreValueContract of super::IStoreValueContract<ContractState> {

        fn get_value(ref self: ContractState, a: felt252){

            self.stored_value.write(a)

        }

 

        fn read_value(self: @ContractState) -> felt252 {

            self.stored_value.read()

        }

    }

    

    

 

}