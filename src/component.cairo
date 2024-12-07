use core::starknet::{ContractAddress, get_caller_address};

#[starknet::interface]
pub trait IOwnable<TContractState> {
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn owner(self: @TContractState) -> ContractAddress;
    fn renounce_ownership(ref self: TContractState);
}

// Error messages
pub mod Errors {
    pub const ZERO_ADDRESS_OWNER: felt252 = 'Owner cannot be address zero';
    pub const ZERO_ADDRESS_CALLER: felt252 = 'Caller cannot be address zero';
    pub const NOT_OWNER: felt252 = 'Caller not owner';
}

#[starknet::component] // use this attribute to decorate a component
pub mod ownable_component {
    use super::IOwnable;
    use super::{
        ContractAddress, get_caller_address
    }; // import contract address & caller address modules
    use core::num::traits::Zero; // import modules for working with is.zero()
    use super::Errors;

    #[storage] // storage stores the owner
    struct Storage {
        owner: ContractAddress,
    }

    #[event] // event that would emit ownership has been transferred
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred { // ownerShipTransferred struct
        previous_owner: ContractAddress,
        new_owner: ContractAddress
    }

    // Ownable Implementation. External interaction of the component
    // This makes it publically accessible to external contracts
    #[embeddable_as(Ownable)]
    impl OwnableImpl<
        TContractState, +HasComponent<TContractState>
    > of super::IOwnable<ComponentState<TContractState>> {
        // This function reads the state to get the owner
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }
        // This transfers ownership from previous owner to a new owner.
        fn transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress
        ) {
            assert(
                !new_owner.is_zero(), Errors::ZERO_ADDRESS_CALLER
            ); // ensure new owner is NOT address zero
            self.assert_only_owner(); // implementing internal function, assert_only_owner
            self
                ._transfer_ownership(
                    new_owner
                ); // implemting the internal function, _transfer_ownership
        }
        fn renounce_ownership(ref self: ComponentState<TContractState>) {
            self.assert_only_owner(); // implementing internal function, assert_only_owner
            self
                ._transfer_ownership(
                    Zero::zero()
                ); // implementing the internal function, _transfer_ownership
        }
    }

    // This is for the internal implementation of the component
    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        // sets the initial owner
        fn initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            self._transfer_ownership(owner);
        }
        // the function transfers ownership from previous owner to new owner
        fn _transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress
        ) {
            let previous_owner: ContractAddress = self.owner.read(); // get the previous owner
            self.owner.write(new_owner); // writes the new owner to the state
            self
                .emit(
                    OwnershipTransferred { previous_owner: previous_owner, new_owner: new_owner }
                ); //emits OwnershipTransferred events
        }
        // this function strictly ensures that ony the owner has rights
        fn assert_only_owner(self: @ComponentState<TContractState>) {
            let owner: ContractAddress = self.owner.read(); // get owner contract address
            let caller: ContractAddress = starknet::get_caller_address(); // gets caller address
            assert(caller == owner, Errors::NOT_OWNER); //ensures caller is the owner
            assert(
                !caller.is_zero(), Errors::ZERO_ADDRESS_OWNER
            ); // ensures caller is not address zero
        }
    }
}
