contract;

/**
*
*   1. Racing Drivers Score Board, for Individual Time Trial (ITT), and
*   2. Live Feed for current drive
*
*/ 

mod errors;
mod player;

use player::PlayerProfile;
use player::Score;
use errors::{SetError, GetError};

use std::{
    hash::*, 
    logging::log,
    string::String,
    storage::storage_vec::*,
    storage::storage_string::*, 
};

pub struct RacingScoreEvent {
    score: Score,
    username_hash: b256
}

pub struct FinishScoreEvent {
    username_hash: b256,
    result_time_in_seconds: u64
}

pub struct DestroyedScoreEvent {
    username_hash: b256,
    distance: u64
}

abi RaceBoard {
    #[storage(read)] fn total_players() -> u64;
    #[storage(read)] fn players() -> Vec<PlayerProfile>;
    #[storage(read)] fn username(vec_index: u64) -> String;
    #[storage(read)] fn scores(username_hash: b256) -> Vec<Score>;
    #[storage(read)] fn player(username_hash: b256) -> Option<PlayerProfile>;
    #[storage(write)] fn submit_score(username: String, distance: u64, time: u64, status: u64) -> u64;
    #[storage(read, write)] fn register(username: String, username_email_hash: b256) -> PlayerProfile;
}

storage {
    counter: u64 = 0, // storage.counter.write(current_user_id + 1);
    usernames: StorageMap<u64, StorageString> = StorageMap {},
    players: StorageMap<b256, PlayerProfile> = StorageMap {}, // username_hash->Struct 
    player_scores: StorageMap<b256, StorageVec<Score>> = StorageMap {}, // username_hash->Struct 
}

impl RaceBoard for Contract {
        
    #[storage(read)] 
    fn players() -> Vec<PlayerProfile>
    {   
        let mut vector_profiles: Vec<PlayerProfile> = Vec::new();
        let mut i = 0;
        while i < storage.counter.try_read().unwrap() {
            let user_hash = sha256(storage.usernames.get(i).read_slice().unwrap());
            let player: PlayerProfile = storage.players.get(user_hash).try_read().unwrap();
            vector_profiles.push(player);
            i += 1;
        }
        vector_profiles
    }
    
    #[storage(read)] 
    fn total_players() -> u64 {storage.counter.try_read().unwrap()}

    #[storage(read)] 
    fn scores(username_hash: b256) -> Vec<Score>
    {
        require(storage.players.get(username_hash).try_read().is_some(), 
                GetError::UsernameDoesNotExists);
        
        let mut vector_profile_scores: Vec<Score> = Vec::new();
        let mut i = 0;
        while i < storage.player_scores.get(username_hash).len() {
            
            let score: Score = storage.player_scores.get(username_hash).get(i).unwrap().read();
            vector_profile_scores.push(score);
            i += 1;
        }
        vector_profile_scores
    }
    
    #[storage(read)] 
    fn player(username_hash: b256) -> Option<PlayerProfile>
    {
        storage.players.get(username_hash).try_read()
    }
  
    #[storage(read)] 
    fn username(vector_index: u64) -> String
    {
        require(storage.counter.try_read().unwrap() > vector_index, GetError::IndexIsOverMax);
        storage.usernames.get(vector_index).read_slice().unwrap()
    }

    #[storage(read, write)]
    fn register(username: String, username_email_hash: b256) 
    -> PlayerProfile
    {   
        let username_hash: b256 = sha256(username);
        // Check if username exists
        require(storage.players.get(username_hash).try_read().is_none(),
                SetError::UsernameExists);
        
        let current_user_id: u64 = storage.counter.try_read().unwrap();
        let new_player = PlayerProfile::new(current_user_id, username_hash, username_email_hash);

        let _: Result<StorageString, StorageMapError<StorageString>> = storage.usernames.try_insert(current_user_id, StorageString {});
        storage.usernames.get(current_user_id).write_slice(username);
        storage.players.insert(username_hash, new_player);
        storage.player_scores.insert(username_hash, StorageVec {});
        storage.counter.write(current_user_id + 1);

        new_player
    }

    #[storage(write)]
    fn submit_score(username: String, distance: u64, time: u64, status: u64) -> u64 
    {    
        let username_hash = sha256(username);
        require(!storage.players.get(username_hash).try_read().is_none(), 
                GetError::UsernameDoesNotExists);
        
        let mut profile = storage.players.get(username_hash).try_read().unwrap();
        let new_score = Score { time: time, status: status, distance: distance };

        if status == 1 {  // 1 Finish score

            storage.player_scores.get(username_hash).push(new_score);
            let inverted_time_score = 10_000 - time;
            let final_time_score = 10_000 + inverted_time_score;
            
            if final_time_score > profile.high_score{
                profile.high_score = final_time_score;
                storage.players.insert(username_hash, profile);
            }
            log(FinishScoreEvent{ username_hash: username_hash, result_time_in_seconds: time });

        } else if status == 2 {  // 2 Destroyed score
            storage.player_scores.get(username_hash).push(new_score);
            if distance > profile.high_score{
                profile.high_score = distance;
                storage.players.insert(username_hash, profile);
            }
            log(DestroyedScoreEvent{ username_hash: username_hash, distance: distance });

        } else { // 0 Track score
            log(RacingScoreEvent{ username_hash: username_hash, score: new_score });
        }
        profile.high_score
    }

}

  