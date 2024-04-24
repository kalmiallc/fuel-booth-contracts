library;

use std::string::String;


abi RaceBoard {
    #[storage(write)]
    fn register_email_player(email: String) -> PlayerProfile;
}


