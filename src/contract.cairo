#[starknet::interface] // interface
pub trait IOwnableCounter<TContractState> {
    fn increment(ref self: TContractState, count: u256);
    fn decrement(ref self: TContractState, count: u256);
    fn get_count(self: @TContractState) -> u256;
}

#[starknet::contract] // contract
pub mod OwnableCounter {
    use ownable_component::InternalTrait;
    use super::IOwnableCounter; // import the inteface
    use component_interaction::component::ownable_component; // import the component
    use core::starknet::ContractAddress; // import the contract address
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess
    }; // import storage modules: ead-only & write-only access

    // component macro/function specifing the path, storage & events.
    // This line is essential in creating a reusable piece of functionality within the contract.
    component!(path: ownable_component, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)] // instructs compiler how to generate the contract's interface
    // handles public-facing ownership operations
    impl OwnableImpl =
        ownable_component::Ownable<ContractState>;
    // deals with internal ownership checks and modifications.
    impl OwnableInternalImpl = ownable_component::InternalImpl<ContractState>;

    #[storage] // storage
    struct Storage {
        counter: u256,
        #[substorage(v0)]
        ownable: ownable_component::Storage, // ownable component in storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: ownable_component::Event, // ownable component in event
    }

    // owner: ContractAddress: This parameter represents the address of the owner when the contract
    // is deployed.
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // The constructor initializes the ownership of the contract with the specified owner.
        self.ownable.initializer(owner); // component's initializer function been implemented.
    }

    // Main functions of the contract
    #[abi(embed_v0)]
    impl OwnableCounterImpl of IOwnableCounter<ContractState> {
        fn increment(ref self: ContractState, count: u256) {
            self.ownable.assert_only_owner(); // component's assert_only function been implemented.
            let current_count: u256 = self.counter.read();
            self.counter.write(current_count + count);
        }
        fn decrement(ref self: ContractState, count: u256) {
            self.ownable.assert_only_owner(); // component's assert_only function been implemented.
            let current_count: u256 = self.counter.read();
            self.counter.write(current_count + count);
        }
        fn get_count(self: @ContractState) -> u256 {
            self.counter.read()
        }
    }
}

