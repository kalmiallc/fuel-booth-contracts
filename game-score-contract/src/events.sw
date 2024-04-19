library;

use std::string::String;

pub struct FinishScoreEvent {
    email_hash: b256,
    damage: u64,
    top_speed: u64,
    race_number: u64,
    result_time: u64, // seconds
}

pub struct LiveScoreEvent {
    email_hash: b256,
    speed: u64,
    damage: u64,
    distance: u64,
    current_lap: u64,
    seconds_racing: u64,
}

