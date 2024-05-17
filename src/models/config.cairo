use starknet::ContractAddress;


#[derive(Model, Copy, Drop, Serde)]
struct GlobalConfig {
    #[key]
    id: u64,
    activation: u8,
    is_claim_configured: bool,
    spin_lock_duration: u8
}
