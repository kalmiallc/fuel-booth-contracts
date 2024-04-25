library;

pub struct PlayerProfile{
    level: u64,
    avg_time: u64,         // in seconds
    player_id: u64,        // &players_emails[id]
    total_races: u64,
}

impl PlayerProfile {

    pub fn new(p_id: u64) -> Self {
        Self { level: 1, player_id: p_id, avg_time: 0, total_races: 0 }
    }

    pub fn count_finished_race(ref mut self) -> u64 {
        self.total_races += 1;
        self.total_races
    }
}
