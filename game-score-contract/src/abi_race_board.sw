library;

abi RaceBoard {

    #[storage(read)]
    fn drivers() -> Option<StorageMap<u64, b256>>;

    #[storage(write)]
    fn register_driver(_email: str) -> u64;

    #[storage(write)]
    fn to_live_score(
        _email: str, 
        _speed: u64, 
        _damage: u64,
        _distance: u64,
        _current_lap: u64, 
        _seconds_racing: u64 
    );

    #[storage(write)]
    fn to_finish_score(
        _email: str,
        _damage: u64,
        _top_speed: u64,
        _result_time: u64
    );
}


