library;

use std::string::String;

//mod abi_race_board;//use abi_race_board::RaceBoard;

abi RaceBoard {
    #[storage(write)]
    fn register_email_player(email: String) -> PlayerProfile;
}


