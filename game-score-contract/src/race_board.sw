contract;

/**
*
*   1. Racing Drivers Score Board, for 
*      Individual Time Trial (ITT), and
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
    damage: u64,
    username_hash: b256,
    result_time_in_seconds: u64
}



abi RaceBoard {
    #[storage(read)] fn total_players() -> u64;
    #[storage(read)] fn players() -> Vec<PlayerProfile>;
    #[storage(read)] fn username(vec_index: u64) -> String;
    #[storage(read)] fn scores(username_hash: b256) -> Vec<Score>;
    #[storage(read)] fn player(username_hash: b256) -> Option<PlayerProfile>;
    #[storage(write)] fn submit_score(username_hash: b256, distance: u64, damage: u64, time: u64, speed: u64, status: u64);
    #[storage(read, write)] fn register(username: String, username_hash: b256, username_email_hash: b256) -> PlayerProfile;
}

storage {
    usernames: StorageVec<StorageString> = StorageVec {},
    players: StorageMap<b256, PlayerProfile> = StorageMap {}, // username_hash->Struct 
    player_scores: StorageMap<b256, StorageVec<Score>> = StorageMap {}, // username_hash->Struct 
}



impl RaceBoard for Contract {
        
    #[storage(read)] 
    fn players() -> Vec<PlayerProfile>
    {   
        let mut vector_profiles: Vec<PlayerProfile> = Vec::new();
        let mut i = 0;
        while i < storage.usernames.len() {
            let user_hash = sha256(storage.usernames.get(i).unwrap().read_slice().unwrap());
            let player: PlayerProfile = storage.players.get(user_hash).try_read().unwrap();
            vector_profiles.push(player);
            i += 1;
        }
        vector_profiles
    }
    
    #[storage(read)] 
    fn total_players() -> u64 {storage.usernames.len()}

    #[storage(read)] 
    fn scores(username_hash: b256) -> Vec<Score>
    {
    //    require(
    //         storage.player_scores.get(username_hash).try_read().is_some(), 
    //         GetError::UsernameDoesNotExists
    //     );
        
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
        require(storage.usernames.len() > vector_index, GetError::IndexIsOverMax);
        storage.usernames.get(vector_index).unwrap().read_slice().unwrap()
    }


    #[storage(read, write)]
    fn register(username: String, username_hash: b256, username_email_hash: b256) 
    -> PlayerProfile
    {        
        require(  // Check if username exists
            storage.players.get(username_hash).try_read().is_none(),
            SetError::UsernameExists
        );

        storage.usernames.push(StorageString {});
        let vector_id = storage.usernames.len() - 1;
        storage.usernames.get(vector_id).unwrap().write_slice(username);

        let new_player = PlayerProfile::new(vector_id, username_hash, username_email_hash);
        
        storage.players.insert(username_hash, new_player);
        storage.player_scores.insert(username_hash, StorageVec {});
        
        new_player
    }

    #[storage(write)]
    fn submit_score(username_hash: b256, distance: u64, damage: u64, time: u64, speed: u64, status: u64) 
    {
        
        // require(
        //     !storage.player_scores.get(username_hash).try_read().is_none(), 
        //     GetError::UsernameDoesNotExists
        // );
        
        let mut profile = storage.players.get(username_hash).try_read().unwrap();

        let new_score = Score {
                            time: time,
                            speed: speed,
                            status: status,
                            damage: damage,
                            distance: distance
                            };
        
        if status == 1{
            storage.player_scores.get(username_hash).push(new_score);

            let total_score = 1000 + damage + speed - time;
            if total_score > profile.high_score{
                profile.high_score = total_score;
            }
            storage.players.insert(username_hash, profile);
            log(FinishScoreEvent{username_hash: username_hash, damage: damage, result_time_in_seconds: time });

        } else {
            log(RacingScoreEvent{username_hash: username_hash, score: new_score });
        }
    }

}

  