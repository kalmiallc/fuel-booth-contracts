library;

use std::{call_frames::contract_id, hash::*,storage::storage_string::*, string::String};

pub struct APlayer
{
    level: u64,
    player_id: u64,
    total_score: u64,
    number_of_races: u64,
    username_and_email_hash: b256,
}

impl APlayer {

    pub fn _submit_score(ref mut self, new_score: u64)
    { self.total_score += new_score; }

    pub fn _count_race(ref mut self)
    { self.number_of_races += 1; }

    pub fn new(p_id: u64, username: String, email: String) 
    -> Self 
    {
        Self { 
            level: 1, 
            player_id: p_id, 
            total_score: 0, 
            number_of_races: 0, 
            username_and_email_hash: sha256([username, email]),
        }
    }
    
}
