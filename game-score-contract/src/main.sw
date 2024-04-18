contract;

mod interface;

use interface::ScoreBoard;


storage {
    game_version: u64 = 1,
}

impl ScoreBoard for Contract {
    
    #[storage(read)]
    fn version_of_the_game() -> u64 {
        storage.game_version.read()
    }
}
