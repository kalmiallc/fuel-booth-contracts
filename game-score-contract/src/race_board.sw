contract;

/**
*
*   1. Racing Drivers Score Board, for 
*      Individual Time Trial (ITT), and
*   2. Live Feed for current drive
*
* Storage & Access of data for a race.
* One contractID instance is for One race track only!
* 
* Does Store pure EMAIL string in persistent data.
* This contract uses sha256 to hash emails
* Multiple races for a player-hashed_email are distinguished by race_number_uid
*
*   Usage calls:
*    
*
* */




mod errors;
mod player;
mod game_score;
mod events;

use player::PlayerProfile;
use game_score::GameScore;

use errors::{SetError, GetError};
use events::{LiveScoreEvent, FinishScoreEvent};

use std::{call_frames::contract_id, hash::*,storage::storage_string::*, string::String};

use std::logging::log; // https://docs.fuel.network/docs/sway/basics/comments_and_logging/

abi RaceBoard {
    #[storage(read)]fn players_count() -> u64;
    #[storage(read)]fn all_players() -> Vec<PlayerProfile>;
    #[storage(read)]fn player_email(seq_id: u64) -> String;
    #[storage(read)]fn player_email_exists(email: String) -> bool;
    #[storage(read)]fn id_player_profile(seq_id: u64) -> Option<PlayerProfile>;
    #[storage(read)]fn email_player_profile(email: String) -> Option<PlayerProfile>;
    #[storage(write)]fn register_email_player(email: String) -> PlayerProfile;
    #[storage(read)]fn times_raced_id(seq_id: u64) -> u64;
    #[storage(read)]fn times_raced_email(email: String) -> u64;
    #[storage(write)]fn submit_score(_email: String, _vehicle_damage: u64, _finish_time_seconds: u64) -> GameScore;
    #[storage(read)]fn player_last_race_score(email: String) -> GameScore;
    #[storage(read)]fn player_id_race_score(seq_id: u64, race_number: u64) -> GameScore;
    #[storage(read)]fn all_player_scores(email: String) -> Vec<GameScore>;

}

storage {
    players_count: u64 = 0, // number n
    players_emails : StorageMap<u64, StorageString> = StorageMap {}, // n => "user@mail.io"
    players_profiles: StorageMap<b256, PlayerProfile> = StorageMap {}, // hash(email)=> Struct
    players_game_scores: StorageMap<(u64, u64), GameScore> = StorageMap {}, // (player_ID, player_race_count) => Struct 
}



impl RaceBoard for Contract {
    
    #[storage(read)]fn players_count() -> u64 
    {   storage.players_count.try_read().unwrap()   }

    #[storage(read)]fn player_email(seq_id: u64) -> String  
    {   storage.players_emails.get(seq_id).read_slice().unwrap()   }

    #[storage(read)]fn player_email_exists(email: String) -> bool  
    {   !storage.players_profiles.get(sha256(email)).try_read().is_none()   }

    #[storage(read)]fn id_player_profile(seq_id: u64) -> Option<PlayerProfile> 
    {
        require(seq_id <= storage.players_count.try_read().unwrap(), GetError::IdIsOverMax);
        let email: String = storage.players_emails.get(seq_id).read_slice().unwrap();
        storage.players_profiles.get(sha256(email)).try_read() 
    }

    #[storage(read)]fn email_player_profile(email: String) -> Option<PlayerProfile>
    {   storage.players_profiles.get(sha256(email)).try_read() }

    #[storage(write)]
    fn register_email_player(email: String) -> PlayerProfile
    {
        let current_seq_id: u64 = storage.players_count.try_read().unwrap();
        let email_hash: b256 = sha256(email);

        require(storage.players_profiles.get(email_hash).try_read().is_none(), SetError::ValueAlreadySet);

        // NEW PLAYER
        let new_player_profile = PlayerProfile::new(current_seq_id);
        storage.players_profiles.insert(email_hash, new_player_profile);


        // ID => EMAIL 
        let initialize_new_slot: Result<StorageString, StorageMapError<StorageString>> = storage.players_emails.try_insert(current_seq_id, StorageString {});
        storage.players_emails.get(current_seq_id).write_slice(email);  //let email_string: String = String::from_ascii_str(email:str);

        // PLAYERS COUNT++
        storage.players_count.write(current_seq_id + 1);

        new_player_profile
    }

    #[storage(read)]
    fn times_raced_id(seq_id: u64) -> u64 
    {
        require(seq_id <= storage.players_count.try_read().unwrap(), GetError::IdIsOverMax);
        let email: String = storage.players_emails.get(seq_id).read_slice().unwrap();
        let player: PlayerProfile = storage.players_profiles.get(sha256(email)).try_read().unwrap();
        player.total_races
    }

    #[storage(read)]
    fn times_raced_email(email: String) -> u64 
    {
        let player: PlayerProfile = storage.players_profiles.get(sha256(email)).try_read().unwrap();
        player.total_races
    }

    #[storage(read)]
    fn all_players() -> Vec<PlayerProfile>
    {   // list all players: ID-email-PlayerProfile
        let mut vector_profiles: Vec<PlayerProfile> = Vec::new();

        let mut cc: u64 = 0;
        let range: u64 = storage.players_count.try_read().unwrap();
        
        while cc < range {
            let email: String = storage.players_emails.get(cc).read_slice().unwrap();
            let profile: PlayerProfile = storage.players_profiles.get(sha256(email)).try_read().unwrap();
            vector_profiles.push(profile);
            cc = cc + 1;
        }
        vector_profiles
    }


    #[storage(write)]
    fn submit_score(
        _email: String, 
        _vehicle_damage: u64, 
        _finish_time_seconds: u64
    ) -> GameScore
    {
        let email_hash: b256 = sha256(_email);
        let mut profile: PlayerProfile = storage.players_profiles.get(email_hash).try_read().unwrap();

        // increment and assign to use this race ID for player
        let current_race_number = profile.count_finished_race(_finish_time_seconds);

        // create new GameScore
        let new_game_score = GameScore::new(
            _vehicle_damage,
            profile.player_id,
            _finish_time_seconds,
            current_race_number
            );

        // update Player Profile stats
        storage.players_game_scores.insert((profile.player_id, current_race_number), new_game_score);
        storage.players_profiles.insert(email_hash, profile);

        // trigger event
        log(FinishScoreEvent {
            top_speed: 0,
            email_hash: email_hash,
            damage: _vehicle_damage,
            race_number: current_race_number,
            result_time: _finish_time_seconds
        });

        new_game_score
    }

    #[storage(read)]fn player_last_race_score(email: String) -> GameScore
    {
        let profile: PlayerProfile = storage.players_profiles.get(sha256(email)).try_read().unwrap();
        storage.players_game_scores.get((profile.player_id, profile.total_races)).try_read().unwrap()
    }

    #[storage(read)]fn player_id_race_score(seq_id: u64, race_number: u64) -> GameScore
    {storage.players_game_scores.get((seq_id, race_number)).try_read().unwrap()}

    #[storage(read)]
    fn all_player_scores(email: String) -> Vec<GameScore> 
    {
        let mut cc: u64 = 1;
        let mut vector_scores: Vec<GameScore> = Vec::new();
        let profile: PlayerProfile = storage.players_profiles.get(sha256(email)).try_read().unwrap();

        let player_id: u64 = profile.player_id;

        let range: u64 = profile.total_races;
        while cc <= range {
            
            let game_score: GameScore = storage.players_game_scores.get((player_id, cc)).try_read().unwrap();
            vector_scores.push(game_score);
            cc = cc + 1;
        }
        vector_scores

    }

}

  