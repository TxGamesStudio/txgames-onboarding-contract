use core::option::OptionTrait;
use core::array::ArrayTrait;
use traits::{Into, TryInto};
use debug::PrintTrait;

fn random(seed: u128) -> u128 {
    let seed_felt: felt252 = seed.into();
    let mut rolling_seed_arr: Array<felt252> = ArrayTrait::new();
    rolling_seed_arr.append(seed_felt);
    rolling_seed_arr.append(seed_felt * 7);
    rolling_seed_arr.append(seed_felt * 29);
    let rolling_hash: u256 = poseidon::poseidon_hash_span(rolling_seed_arr.span()).into();
    let x: u128 = (rolling_hash.low);
    x
}

fn spin(seed: u128) -> u8 {
    let random_number = random(seed);
    let x: u8 = random_number.try_into().unwrap() % 10;
    x + 1
}
