contract;

/**
* Racing Drivers Score Board for Individual Time Trial (ITT) and Live Feed for current drive
*/

mod errors;  // Import the errors module
// mod player;  // Import the player module

// Use necessary items from player and errors modules
// use player::PlayerProfile;
// use player::Score;
use errors::{SetError, GetError};

// Standard library components for hashing, logging, strings, and storage
use std::{
    hash::*, 
    logging::log,
    string::String,
    storage::storage_vec::*,
    storage::storage_string::*, 
};

// 'Score' to represent a player's score and status in a game
pub struct Score {
    // The time taken by the player, measured in seconds
    time: u64,
    
    // The status of the player:
    // 0 - Racing, 1 - Finished, 2 - Destroyed
    status: u64,
    
    // The distance covered by the player
    distance: u64,
}

// Define a struct 'PlayerProfile' to store information about a player's profile
pub struct PlayerProfile {
    // The highest score achieved by the player
    high_score: u256,
    
    // A hash of the player's username for identifying and comparing user info in storage
    username_hash: b256,
    
    // An index pointing to the player's username in the storage vector
    usernames_vector_index: u64,
    
    // A hash of the player's username and email for preventing duplicate emails
    username_and_email_hash: b256,
    
    // A flag indicating whether the player has set an email
    has_email_set: bool,
}

// Implement methods for the 'PlayerProfile' struct
impl PlayerProfile {

    // Constructor function to create a new 'PlayerProfile' instance
    pub fn new(
        vector_index: u64, 
        username_hash: b256, 
        username_mail_hash: b256
    ) -> Self {   
        // Initialize and return a new 'PlayerProfile' instance
        Self { 
            high_score: 0,  // Set the initial high score to 0
            has_email_set: username_hash == username_mail_hash,  // Set the email flag based on the hash comparison
            username_hash: username_hash,  // Assign the provided username hash
            usernames_vector_index: vector_index,  // Assign the provided vector index
            username_and_email_hash: username_mail_hash  // Assign the provided username and email hash
        }
    }
}

// Struct to represent a score event
pub struct ScoreEvent {
    score: Score,        // The score details
    username_hash: b256  // The hash of the username associated with this score
}

// The ABI (Application Binary Interface) for the RaceBoard contract
abi RaceBoard {
    // Read-only storage access functions
    #[storage(read)] fn players() -> Vec<PlayerProfile>;  // Retrieve all player profiles
    #[storage(read)] fn total_players() -> u64; // Retrieve the amount of all player profiles
    #[storage(read)] fn username(vec_index: u64) -> String;  // Retrieve a username by its storage vector index
    #[storage(read)] fn scores(username_hash: b256) -> Vec<Score>;  // Retrieve scores for a given username hash
    #[storage(read)] fn player(username_hash: b256) -> Option<PlayerProfile>;  // Retrieve a player profile by username hash

    // Write and read/write storage access functions
    #[storage(write)] fn submit_score(username: String, distance: u64, time: u64, status: u64) -> u256;  // Submit a new score for a player
    #[storage(read, write)] fn register(username: String, username_email_hash: b256) -> PlayerProfile;  // Register a new player profile
}

// Storage structure for the contract
storage {
    counter: u64 = 0,  // A counter for unique user IDs
    usernames: StorageMap<u64, StorageString> = StorageMap {},  // Map of user IDs to usernames
    players: StorageMap<b256, PlayerProfile> = StorageMap {},  // Map of username hashes to player profiles
    player_scores: StorageMap<b256, StorageVec<Score>> = StorageMap {},  // Map of username hashes to vectors of scores
}

impl RaceBoard for Contract {
        
    // Retrieve all player profiles
    #[storage(read)] 
    fn players() -> Vec<PlayerProfile>
    {   
        let mut vector_profiles: Vec<PlayerProfile> = Vec::new();  // Vector to store player profiles
        let mut i = 0;
        while i < storage.counter.try_read().unwrap() {
            let user_hash = sha256(storage.usernames.get(i).read_slice().unwrap());  // Calculate hash for each username
            let player: PlayerProfile = storage.players.get(user_hash).try_read().unwrap();  // Retrieve player profile by hash
            vector_profiles.push(player);  // Add player profile to vector
            i += 1;
        }
        vector_profiles
    }

    #[storage(read)] 
    fn total_players() -> u64 {storage.counter.try_read().unwrap()}

    // Retrieve scores for a given username hash
    #[storage(read)] 
    fn scores(username_hash: b256) -> Vec<Score>
    {
        // Ensure the player exists
        require(storage.players.get(username_hash).try_read().is_some(), 
                GetError::UsernameDoesNotExists);
        
        let mut vector_profile_scores: Vec<Score> = Vec::new();  // Vector to store scores
        let mut i = 0;
        while i < storage.player_scores.get(username_hash).len() {
            let score: Score = storage.player_scores.get(username_hash).get(i).unwrap().read();  // Retrieve each score
            vector_profile_scores.push(score);  // Add score to vector
            i += 1;
        }
        vector_profile_scores
    }
    
    // Retrieve a player profile by username hash
    #[storage(read)] 
    fn player(username_hash: b256) -> Option<PlayerProfile>
    {
        storage.players.get(username_hash).try_read()  // Return player profile if exists
    }
  
    // Retrieve a username by its storage vector index
    #[storage(read)] 
    fn username(vector_index: u64) -> String
    {
        // Ensure the index is within bounds
        require(storage.counter.try_read().unwrap() > vector_index, GetError::IndexIsOverMax);
        storage.usernames.get(vector_index).read_slice().unwrap()  // Return the username
    }

    // Register a new player profile
    #[storage(read, write)]
    fn register(username: String, username_email_hash: b256) -> PlayerProfile
    {   
        let username_hash: b256 = sha256(username);  // Calculate hash of the username
        // Ensure the username does not already exist
        require(storage.players.get(username_hash).try_read().is_none(), 
                SetError::UsernameExists);
        
        let current_user_id: u64 = storage.counter.try_read().unwrap();  // Get the current user ID
        let new_player = PlayerProfile::new(current_user_id, username_hash, username_email_hash);  // Create a new player profile

        let _: Result<StorageString, StorageMapError<StorageString>> = storage.usernames.try_insert(current_user_id, StorageString {});  // Insert username into storage
        storage.usernames.get(current_user_id).write_slice(username);  // Write username to storage
        storage.players.insert(username_hash, new_player);  // Insert player profile into storage
        storage.player_scores.insert(username_hash, StorageVec {});  // Initialize score vector for the player
        storage.counter.write(current_user_id + 1);  // Increment the user ID counter

        new_player  // Return the new player profile
    }

    // Submit a new score for a player
    #[storage(write)]
    fn submit_score(username: String, distance: u64, time: u64, status: u64) -> u256 
    {    
        let username_hash = sha256(username);  // Calculate hash of the username
        // Ensure the player exists
        require(!storage.players.get(username_hash).try_read().is_none(), 
                GetError::UsernameDoesNotExists);
        
        let mut profile = storage.players.get(username_hash).try_read().unwrap();  // Retrieve the player profile
        let new_score = Score { time: time, status: status, distance: distance };  // Create a new score
        log(ScoreEvent{ username_hash: username_hash, score: new_score });  // Log the score event
        
        if status == 1 {  // Status 1 indicates a finished score
            storage.player_scores.get(username_hash).push(new_score);  // Add score to the player's scores
            let inverted_time_score = 1_000_000 - time;  // Calculate an inverted time score
            let final_time_score = 1_000_000 + inverted_time_score;  // Calculate the final time score
            
            if final_time_score.as_u256() > profile.high_score {
                profile.high_score = final_time_score.as_u256();  // Update the high score if the new score is higher
                storage.players.insert(username_hash, profile);  // Save the updated profile
            }
            
        } else if status == 2 {  // Status 2 indicates a destroyed score
            storage.player_scores.get(username_hash).push(new_score);  // Add score to the player's scores
            if distance.as_u256() > profile.high_score {
                profile.high_score = distance.as_u256();  // Update the high score if the new distance is greater
                storage.players.insert(username_hash, profile);  // Save the updated profile
            }
        }
        profile.high_score  // Return the player's high score
    }

}
