library;

pub struct GameScore { 
    damage: u64,
    player_id: u64,
    finish_time: u64, // seconds
    seq_race_number: u64,  // example: value is 3 if this was the third race for this player
}

impl GameScore {
    pub fn new(
        _damage: u64, 
        _player_id: u64, 
        _finish_time: u64, 
        _seq_race_number: u64
    ) -> Self 
    {
        Self { 
            damage: _damage, 
            player_id: _player_id, 
            finish_time: _finish_time, 
            seq_race_number: _seq_race_number
        }
    }
}