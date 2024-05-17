use dojo::world::{IWorldDispatcher};
use starknet::{ContractAddress};
use debug::PrintTrait;

#[dojo::interface]
trait IActions {
    fn spin();
    fn claim(item_id: u32);
    fn set_claim_config(item_ids: Array<u32>, required_points: Array<u64>);
    fn set_spin_lock_config(spin_lock_duration: u8);
    fn set_activation(activation: u8);
}

// dojo decorator
#[dojo::contract]
mod actions {
    use super::{IActions};
    use starknet::{ContractAddress, get_caller_address};
    use starknet::{get_block_info};
    // entities
    use txgames::models::player::{Player};
    use txgames::models::events::{Spinned};
    use txgames::models::item::{ClaimItemConfig, Item};
    use txgames::models::config::{GlobalConfig};
    use txgames::utils::{random};
    use debug::PrintTrait;

    #[abi(embed_v0)]
    impl actions_impl of IActions<ContractState> {
        fn spin(world: IWorldDispatcher) {
            let globalConfig = get!(world, (1), GlobalConfig);
            assert(globalConfig.activation == 1, 'not activation');
            assert(globalConfig.spin_lock_duration > 0, 'not define lock time');

            let address = get_caller_address();
            let blockts: u64 = starknet::get_block_timestamp();
            let player = get!(world, (address), Player);

            if player.last_spin_at > 0 {
                assert(
                    blockts
                        - player
                            .last_spin_at >= globalConfig
                            .spin_lock_duration
                            .try_into()
                            .unwrap(),
                    'Please wait'
                );
            }

            // build seed
            let mut rolling_seed_arr: Array<felt252> = ArrayTrait::new();
            rolling_seed_arr.append(blockts.into());
            rolling_seed_arr.append(address.into());
            let rolling_hash: u256 = poseidon::poseidon_hash_span(rolling_seed_arr.span()).into();
            let seed: u128 = (rolling_hash.low);

            // calculate point
            let win_point: u8 = random::spin(seed);

            let player = get!(world, (address), Player);
            let earned_point = player.earned_point + win_point.try_into().unwrap();
            set!(
                world,
                (Player {
                    player: address,
                    point: player.point + win_point.try_into().unwrap(),
                    earned_point: earned_point,
                    updated_at: blockts,
                    last_spin_at: blockts
                })
            );
            emit!(world, (Spinned { player: address, spinned_at: blockts, point: win_point }));
        }

        fn claim(world: IWorldDispatcher, item_id: u32) {
            let globalConfig = get!(world, (1), GlobalConfig);
            assert(globalConfig.activation == 1, 'not activation');
            assert(globalConfig.is_claim_configured == true, 'not configured');

            let address = get_caller_address();
            let player = get!(world, (address), Player);
            let claimItemConfig = get!(world, (item_id), ClaimItemConfig);
            assert(player.point >= claimItemConfig.required_point, 'Not enough point');

            let blockts = starknet::get_block_timestamp();
            // update player point
            set!(
                world,
                (Player {
                    player: address,
                    point: player.point - claimItemConfig.required_point,
                    earned_point: player.earned_point,
                    updated_at: blockts,
                    last_spin_at: player.last_spin_at
                })
            );

            // update player item
            let item = get!(world, (address, item_id), Item);
            assert(item.quantity == 0, 'already claimed');

            let add_quantity: u8 = 1;
            let total_quantity = item.quantity + add_quantity.try_into().unwrap();
            set!(
                world,
                (Item {
                    player: address, item_id: item_id, quantity: total_quantity, updated_at: blockts
                })
            );
        }

        fn set_claim_config(
            world: IWorldDispatcher, item_ids: Array<u32>, required_points: Array<u64>
        ) {
            let caller = get_caller_address();
            _require_world_owner(world, caller);
            let globalConfig = get!(world, (1), GlobalConfig);

            let blockts = starknet::get_block_timestamp();

            let item_ids_len = item_ids.len();
            let required_points_len = required_points.len();
            assert(item_ids_len == required_points_len, 'length missmatch');
            let mut index = 0;
            loop {
                let item_id: u32 = *item_ids.at(index);
                let required_point: u64 = *required_points.at(index);
                set!(
                    world,
                    (ClaimItemConfig {
                        item_id: item_id, required_point: required_point, updated_at: blockts
                    })
                );
                index += 1;
                if (index == item_ids_len) {
                    break ();
                };
            };

            set!(
                world,
                (GlobalConfig {
                    id: 1,
                    activation: globalConfig.activation,
                    is_claim_configured: true,
                    spin_lock_duration: globalConfig.spin_lock_duration
                })
            )
        }

        fn set_spin_lock_config(world: IWorldDispatcher, spin_lock_duration: u8) {
            let caller = get_caller_address();
            _require_world_owner(world, caller);
            let globalConfig = get!(world, (1), GlobalConfig);
            set!(
                world,
                (GlobalConfig {
                    id: 1,
                    activation: 1,
                    is_claim_configured: globalConfig.is_claim_configured,
                    spin_lock_duration: spin_lock_duration,
                })
            )
        }


        fn set_activation(world: IWorldDispatcher, activation: u8) {
            let caller = get_caller_address();
            _require_world_owner(world, caller);
            let globalConfig = get!(world, (1), GlobalConfig);
            set!(
                world,
                (GlobalConfig {
                    id: 1,
                    activation: activation,
                    is_claim_configured: globalConfig.is_claim_configured,
                    spin_lock_duration: globalConfig.spin_lock_duration,
                })
            )
        }
    }

    fn _require_world_owner(world: dojo::world::IWorldDispatcher, caller: ContractAddress) {
        let granted = world.is_owner(caller, dojo::world::world::WORLD);
        // granted.print();
        assert(granted, 'required world owner');
    }
}
