use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde)]
struct Item {
    #[key]
    player: ContractAddress,
    #[key]
    item_id: u32,
    updated_at: u64,
    quantity: u64,
}

#[derive(Model, Copy, Drop, Serde)]
struct ClaimItemConfig {
    #[key]
    item_id: u32,
    required_point: u64,
    updated_at: u64,
}

