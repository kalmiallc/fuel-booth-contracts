contract;

/**
* High Scores Contracts. Keeps history for each player username.
* */
mod a_player;
use a_player::APlayer;

use std::{hash::*,storage::storage_string::*, string::String};
use std::logging::log;
use std::constants::ZERO_B256;



pub enum SetterError { Exists: () }
pub enum GetterError { NotFound: (), IdOverflow: () }

fn score_function(
    lap: u64,
    speed: u64,
    damage: u64,
    time_seconds: u64) 
-> u64 
{ lap + speed + damage + time_seconds } // TODO


abi HighScore {
    #[storage(read)] fn count_players() -> u64;
    #[storage(read)] fn get_players() -> Vec<APlayer>;
    #[storage(write)] fn new_player(username: String, email: String) -> APlayer;
    #[storage(write)] fn submit_new_score(
            lap: u64,
            speed: u64,
            damage: u64,
            username: String, 
            time_seconds: u64,
            checkpoint_id: u64, 
        ) -> APlayer;
}

storage {
    user_counter: u64 = 0,
    id_usernames : StorageMap<u64, StorageString> = StorageMap {},
    players: StorageMap<b256, APlayer> = StorageMap {}, // hash(username)
}


const LAPS: u64 = 3;
const LAST_CHECKPOINT_ID: u64 = 22;

impl HighScore for Contract {
    

    #[storage(read)]
    fn count_players() 
    -> u64 
    { storage.user_counter.try_read().unwrap() }

    
   

    #[storage(write)]
    fn new_player(username: String, email: String) 
    -> APlayer
    {
        let uname_hash: b256 = sha256(username);
        let current_user_id: u64 = storage.user_counter.try_read().unwrap();
        require(
            storage.players.get(uname_hash).try_read().is_none(), 
            SetterError::Exists
        );
        
        let new_profile = APlayer::new(current_user_id, username, email);
        
        storage.players.insert(uname_hash, new_profile);

        let _: Result<StorageString, StorageMapError<StorageString>> = storage.id_usernames.try_insert(current_user_id, StorageString {});
        storage.id_usernames.get(current_user_id).write_slice(username);

        storage.user_counter.write(current_user_id + 1);

        new_profile
    }

   
    #[storage(read)]
    fn get_players() 
    -> Vec<APlayer>
    {   
        let mut counter: u64 = 0;
        let mut vector_profiles: Vec<APlayer> = Vec::new();
        let range: u64 = storage.user_counter.try_read().unwrap();
        
        while counter < range {
            let username: String = storage.id_usernames.get(counter).read_slice().unwrap();
            let profile: APlayer = storage.players.get(sha256(username)).try_read().unwrap();
            vector_profiles.push(profile);
            counter = counter + 1;
        }
        vector_profiles
    }

    #[storage(write)]
    fn submit_new_score(
            lap: u64,
            speed: u64,
            damage: u64,
            username: String, 
            time_seconds: u64,
            checkpoint_id: u64, 
    ) -> APlayer
    {
        let uname_hash: b256 = sha256(username);

        require(
            !storage.players.get(uname_hash).try_read().is_none(), 
            GetterError::NotFound
        );
        
        let mut profile: APlayer = storage.players.get(uname_hash).try_read().unwrap();

        let new_score: u64 = score_function(lap, speed, damage, time_seconds);

        profile._submit_score(new_score);

        if lap >= LAPS && checkpoint_id >= LAST_CHECKPOINT_ID 
        {   profile._count_race();   }

        storage.players.insert(uname_hash, profile);
        profile
    }

}

  