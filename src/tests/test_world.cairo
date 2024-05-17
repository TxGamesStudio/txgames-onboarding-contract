#[cfg(test)]
mod tests {
    use array::{ArrayTrait};
    use option::OptionTrait;
    use box::BoxTrait;
    use clone::Clone;
    use debug::PrintTrait;
    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};
    use dojo::test_utils::{spawn_test_world};
    use txgames::models::player::{Player};
    use txgames::models::config::{GlobalConfig};
    use txgames::models::item::{ClaimItemConfig};

    use txgames::systems::{
        onboarding::{actions, IActions, IActionsDispatcher, IActionsDispatcherTrait}
    };

    use core::fmt::Display;

    // helper setup function
    // reusable function for tests
    fn setup_world() -> (IWorldDispatcher, IActionsDispatcher) {
        let world = spawn_test_world(array![]);

        // // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        starknet::testing::set_block_timestamp(4001);
        let actions_system = IActionsDispatcher { contract_address };

        (world, actions_system)
    }

    #[test]
    #[available_gas(30000000)]
    fn test_spin() {
        // caller
        // let caller = starknet::contract_address_const::<0x0>();

        let (world, actions_system) = setup_world();
        actions_system.set_spin_lock_config(120);

        starknet::testing::set_block_timestamp(4000);
        let point = actions_system.spin();
        assert!(point >= 1 && point <= 10, "invalid point");
    }

    #[test]
    #[available_gas(30000000)]
    fn test_set_activation() {
        let (world, actions_system) = setup_world();
        let globalConfig = get!(world, (1), GlobalConfig);
        assert!(globalConfig.activation == 0, "It must be 0");
        actions_system.set_activation(1);
        let globalConfig = get!(world, (1), GlobalConfig);
        assert!(globalConfig.activation == 1, "It must be 1");
    }

    #[test]
    #[available_gas(30000000)]
    fn test_set_claim_configuration() {
        let (world, actions_system) = setup_world();
        let globalConfig = get!(world, (1), GlobalConfig);
        assert!(globalConfig.is_claim_configured == false, "It must be false");

        // config
        actions_system.set_claim_config(array![1, 2, 3], array![10, 20, 30]);
        let globalConfig = get!(world, (1), GlobalConfig);
        assert!(globalConfig.is_claim_configured == true, "It must be true");
    }

    use core::fmt::{Formatter, Error};
    #[test]
    #[available_gas(300000000)]
    fn test_claim() {
        let player_contract = starknet::contract_address_const::<0x0>();
        starknet::testing::set_caller_address(player_contract);

        let (world, actions_system) = setup_world();

        // config
        actions_system.set_claim_config(array![1, 2, 3], array![10, 20, 30]);
        let globalConfig = get!(world, (1), GlobalConfig);
        assert!(globalConfig.is_claim_configured == true, "It must be true");

        let claimItemConfig = get!(world, (1), ClaimItemConfig);
        set!(
            world,
            (Player {
                player: player_contract, point: 10, earned_point: 0, updated_at: 0, last_spin_at: 0
            })
        );
        let player_data = get!(world, (player_contract), Player);
        assert!(player_data.point == 10, "It must be 0");
        actions_system.claim(1);
    }
}
