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

mod events;
mod abi_race_board;
mod data_structures;

use std::hash::*;
use std::string::String;
use std::storage::StorageMap; // https://fuellabs.github.io/sway/v0.19.0/common-collections/storage_map.html
use events::LiveScoreEvent;
use events::FinishScoreEvent;
use std::constants::ZERO_B256;
use abi_race_board::RaceBoard;
use data_structures::LiveScore;
use data_structures::FinishScore;

storage {
    // so we know to what number read for drivers email hash
    drivers_count: u64 = 0, 

    // sequential ID => hash(email)
    drivers: StorageMap<u64, b256> = StorageMap {},

    // hash(email) => amount races completed/finished 
    finish_races_counter: StorageMap<b256, u64> = StorageMap {},

    live_scores: StorageMap<(b256, u64), LiveScore> = StorageMap {}, 

    finish_scores: StorageMap<(b256, u64), FinishScore> = StorageMap {},
}

impl RaceBoard for Contract {
    
    #[storage(write)]
    fn register_driver(_email: String) -> u64 {

        let hash_mail: b256 = sha256(_email);

        // first time email
        if storage.finish_races_counter.get(hash_mail).try_read().is_none() {

            // save new driver: sequential ID => hash(email)
            storage.drivers.insert(storage.drivers_count.try_read().unwrap(), hash_mail);

            // save new driver races counter, set to 0 finished races
            storage.finish_races_counter.insert(hash_mail, 0);

            // increase sequential ID
            storage.drivers_count.write(storage.drivers_count.try_read().unwrap() + 1);

            // return first time on the track
            0
        } else {

            // return current counter of races for driver
            storage.finish_races_counter.get(hash_mail).try_read().unwrap()
        }
    }


    #[storage(write)]
    fn to_finish_score(
        _email: str,
        _damage: u64,
        _top_speed: u64,
        _result_time: u64
    ) {
        let hash_mail: b256 = sha256(_email);

        // TODO change if user registered and from that assume existence of email hash in finish_races_counter
        // TODO modifier if user registered 
        // counter of races for this driver
        let mut this_driver_race_count: u64 =  1;
        if !storage.finish_races_counter.get(hash_mail).try_read().is_none() {
            this_driver_race_count = storage.finish_races_counter.get(hash_mail).try_read().unwrap() + 1;
        }
        storage.finish_races_counter.insert(hash_mail, this_driver_race_count);

        // save racing result to storage
        storage.finish_scores.insert(
            (hash_mail, this_driver_race_count),
            FinishScore {
                mail: hash_mail,
                damage: _damage, 
                top_speed: _top_speed,
                race_number: this_driver_race_count,
                result_time: _result_time
            }
        );

        // trigger event
        log(FinishScoreEvent {
            email_hash: hash_mail,
            damage: _damage,
            top_speed: _top_speed,
            race_number: this_driver_race_count,
            result_time: _result_time
        });
    }


    #[storage(write)]
    fn to_live_score(
        _email: str, 
        _speed: u64, 
        _damage: u64,
        _distance: u64,
        _current_lap: u64, 
        _seconds_racing: u64 
    ) {
        let hash_mail: b256 = sha256(_email);

        // TODO uid for current race, wait for now if reading events is enough for timetable
        let uniq_score_id: u64 = 111;  

        storage.live_scores.insert(
            (hash_mail, uniq_score_id),
            LiveScore {
                speed: _speed,
                damage: _damage, 
                distance: _distance,
                current_lap: _current_lap,
                seconds_racing: _seconds_racing
            }
        );

        // trigger event
        log(LiveScoreEvent {
            email_hash: hash_mail,
            speed: _speed,
            damage: _damage, 
            distance: _distance,
            current_lap: _current_lap,
            seconds_racing: _seconds_racing
        });
    }

    #[storage(read)]
    fn drivers() -> Option<StorageMap<u64, b256>> {
        storage.drivers.try_read().unwrap()
    }

/*
    #[storage(read)]
    fn driver_races(_email: str) -> struct {
        let hash_mail: b256 = sha256(_email);

        let driver_races_count: u64 = storage.finish_races_counter.get(hash_mail).try_read().unwrap();
        

        storage.finish_scores.get(hash_mail).try_read()
    }
*/
}

