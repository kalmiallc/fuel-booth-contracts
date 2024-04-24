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
* Does NOT STORE pure EMAIL string in persistent data.
* This contract uses sha256 to hash emails
* Multiple races for a hashed email are distinguished by uid
*
*   Usage calls:
*   - Register before race: register_driver(email)
*   - Save user finished race: to_finish_score(...)
*   - Announce to Live Feed Score: to_live_score(...)
*   Usage gets:
*   - Drivers List: drivers()
*   - 
*   - 
*
* */




mod errors;
mod player;
mod events;
//mod abi_race_board;//use abi_race_board::RaceBoard;


use errors::{SetError, GetError};
use player::PlayerProfile;
use events::{LiveScoreEvent, FinishScoreEvent};
use std::{call_frames::contract_id, hash::*,storage::storage_string::*, string::String};

abi RaceBoard {
    #[storage(read)]fn players_count() -> u64;
    #[storage(read)]fn player_email(seq_id: u64) -> String;
    #[storage(read)]fn player_email_exists(email: String) -> bool;
    #[storage(read)]fn id_player_profile(seq_id: u64) -> Option<PlayerProfile>;
    #[storage(read)]fn email_player_profile(email: String) -> Option<PlayerProfile>;
    #[storage(write)]fn register_email_player(email: String) -> PlayerProfile;
    
}

storage {
    players_count: u64 = 0, // number
    players_emails : StorageMap<u64, StorageString> = StorageMap {}, // n => "user@mail.io"
    players_profiles: StorageMap<b256, PlayerProfile> = StorageMap {}, // hash(email)=> Struct
}



impl RaceBoard for Contract {
    
    #[storage(read)]fn players_count() -> u64 {   storage.players_count.try_read().unwrap()   }

    #[storage(read)]fn player_email(seq_id: u64) -> String  {   storage.players_emails.get(seq_id).read_slice().unwrap()   }

    #[storage(read)]fn player_email_exists(email: String) -> bool  {   storage.players_profiles.get(sha256(email)).try_read().is_none()   }

    #[storage(read)]fn id_player_profile(seq_id: u64) -> Option<PlayerProfile> 
    {
        require(seq_id <= storage.players_count.try_read().unwrap(), GetError::IdIsOverMax);
        let email: String = storage.players_emails.get(seq_id).read_slice().unwrap();
        storage.players_profiles.get(sha256(email)).try_read() 
    }

    #[storage(read)]fn email_player_profile(email: String) -> Option<PlayerProfile>{   storage.players_profiles.get(sha256(email)).try_read() }

    #[storage(write)]fn register_email_player(email: String) -> PlayerProfile
    {
        let current_seq_id: u64 = storage.players_count.try_read().unwrap();
        let email_hash: b256 = sha256(email);

        require(storage.players_profiles.get(email_hash).try_read().is_none(), SetError::ValueAlreadySet);

        // NEW PLAYER
        let new_player_profile = PlayerProfile::new(current_seq_id);
        storage.players_profiles.insert(email_hash, new_player_profile);


        // ID => EMAIL 
        // Setup and initialize storage for the StorageString.
        let new_slot: Result<StorageString, StorageMapError<StorageString>> = storage.players_emails.try_insert(current_seq_id, StorageString {});
        storage.players_emails.get(current_seq_id).write_slice(email);  //let email_string = String::from_ascii_str(email:str);

        // COUNT++
        storage.players_count.write(current_seq_id + 1);

        
        new_player_profile
    }

    


}

  