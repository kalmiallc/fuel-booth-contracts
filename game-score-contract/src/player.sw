library;

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
    high_score: u64,
    
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
