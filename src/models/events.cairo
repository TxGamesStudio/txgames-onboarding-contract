use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde)]
#[dojo::event]
struct Spinned {
    #[key]
    player: ContractAddress,
    #[key]
    spinned_at: u64,
    point: u8
}
