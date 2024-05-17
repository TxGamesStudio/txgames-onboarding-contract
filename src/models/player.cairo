use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde)]
struct Player {
    #[key]
    player: ContractAddress,
    updated_at: u64,
    point: u64,
    earned_point: u64,
    last_spin_at: u64,
}