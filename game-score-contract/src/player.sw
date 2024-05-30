library;
use std::{
    hash::*, 
    logging::log,
    string::String,
    storage::storage_vec::*,
    storage::storage_string::*, 
};


pub struct Score{
    time: u64,
    status: u64,  // 0 Racing , 1 Finished , 2 Destroyed
    distance: u64,
}

pub struct PlayerProfile{
    high_score: u64,
    username_hash: b256,  // for backtrace access   
    usernames_vector_index: u64, // storage.usernames[index]
    username_and_email_hash: b256, // checking prevents duplicates
    has_email_set: bool, 
    
}

impl PlayerProfile {

    pub fn new(
        vector_index: u64, 
        username_hash: b256, 
        username_mail_hash: b256)
    -> Self 
    {   
        Self { 
            high_score: 0,
            has_email_set: username_hash == username_mail_hash,
            username_hash: username_hash,
            usernames_vector_index: vector_index,
            username_and_email_hash: username_mail_hash
            }
    }

}
