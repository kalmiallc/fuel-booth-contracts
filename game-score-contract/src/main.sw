contract;

mod interface;

use interface::ScoreBoard;

use std::hash::{Hash, Hasher};

// https://docs.fuel.network/docs/sway/blockchain-development/storage/#manual-storage-management
// https://forum.fuel.network/t/how-do-i-create-a-storagemap-of-vectors-with-a-tuple-of-2-strings/5081/3
// https://forum.fuel.network/t/workaround-for-creating-a-storagemap-as-part-of-a-struct-or-an-enum/1642/2
// https://docs.fuel.network/docs/sway/common-collections/storage_map/
// https://github.com/fuellabs/sway?tag=v0.49.3#0dc6570377ee9c4a6359ade597fa27351e02a728
// https://github.com/FuelLabs/sway/tree/v0.49.3/sway-lib-std/src/storage
// https://github.com/FuelLabs/sway-standards

struct DriverRaceLog {
    idHash: b256, // https://docs.fuel.network/docs/fuels-ts/types/bits256/
    name: str[180],
    damage: u64,
    speed: u64,
    seconds_racing: u64,
    distance: u64,
    current_lap: u64,
    used_boost_count: u64,
    time_stamp: u64,
}
    

// https://docs.fuel.network/docs/sway/common-collections/storage_map/
storage {
    game_version: u64 = 1,
    uid_to_struct_map: StorageMap<u64, DriverRaceLog> = StorageMap {}, // unique indentifier for each user    
    hash_to_struct_map: StorageMap<b256, DriverRaceLog> = StorageMap {}, // unique indentifier for each user    
    uid_email_to_struct_map: StorageMap<(u64, str[50]), DriverRaceLog> = StorageMap {}, // uuid & email for each user to struct
}

impl ScoreBoard for Contract {
    
    #[storage(read)]
    fn version_of_the_game() -> u64 {
        storage.game_version.read()
    }
}

