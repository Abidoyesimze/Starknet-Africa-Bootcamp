#[starknet::interface]
 trait INotebookContract<TContractState> {
    fn read_message(ref self: TContractState) -> felt252;
    fn write_message(ref self: TContractState, message: felt252)

 }

 #[storage]
 struct Storage {
    message: felt252,
    owner: ContractAddress,
 }

 #[starknet::contract]
 mod Notebook{
    use starknet::get_caller_address;
    use starknet::ContractAddress;
 }
 

 #[constructor]
 fn constructor(ref self: ContractState, initial_owner: ContractAddress){
   self.owner.write(initial_owner);
 }

 #[abi(embed_v0)]
  impl MyNotebookImpl of super::INotebookContract<ContractState> {
    fn read_message(ref self: @ContractState) -> felt252 {
        return self.message.read();
    }

    fn write_message(ref self: ContractState, message: felt252) {
        let caller = get_caller_address();
        let owner = self.owner.read();
        assert(caller, owner, "Only the owner can write a message");
        self.message.write(message);
    }
}