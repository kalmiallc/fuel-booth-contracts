use fuels::{prelude::*, types::ContractId};
//use tokio::{sync::mpsc::Receiver, task::JoinHandle, time::sleep};
//use core::time::Duration;

abigen!(Contract(
    name = "RaceBoard",
    abi = "out/debug/game-score-contract-abi.json"
));


async fn get_contract_instance() -> (RaceBoard<WalletUnlocked>, ContractId) {
    // Launch a local network and deploy the contract
    let mut wallets = launch_custom_provider_and_get_wallets(
        WalletsConfig::new(
            Some(1),             /* Single wallet */
            Some(1),             /* Single coin (UTXO) */
            Some(1_000_000_000), /* Amount per coin */
        ),
        None,
        None,
    )
    .await
    .unwrap();
    let wallet = wallets.pop().unwrap();

    let id = Contract::load_from(
        "./out/debug/game-score-contract.bin",
        LoadConfiguration::default(),
    )
    .unwrap()
    .deploy(&wallet, TxPolicies::default())
    .await
    .unwrap();

    let instance = RaceBoard::new(id.clone(), wallet);

    (instance, id.into())
}

fn print_result(print_val : String, msg : String) {
    println!("{} {:?} \n", msg, print_val);
}

async fn new_player(instance: &RaceBoard<WalletUnlocked>, _username: String) {
    let player_created = instance.methods().register_username_player(_username).call().await;
    match player_created {
        Ok(_) => {
            println!("{} {:?} \n", "New username Player Created:", player_created.unwrap().value);
        }
        Err(_) => println!("{:?}", player_created),
    }
}

async fn new_player_with_email(instance: &RaceBoard<WalletUnlocked>, _username: String, _email: String) {
    let player_created = instance.methods().register_username_email_player(_username, _email).call().await;
    match player_created {
        Ok(_) => {
            println!("{} {:?} \n", "New username & Email Player Created:", player_created.unwrap().value);
        }
        Err(_) => println!("{:?}", player_created),
    }
}

async fn submit_player_score(
    instance: &RaceBoard<WalletUnlocked>, 
    _username: String,
    _damage: u64,
    _time: u64
) {
    let score_created = instance.methods().submit_score(_username, _damage, _time).call().await;
    match score_created {
        Ok(_) => {
            println!("{} {:?} \n", "New  Score Created:", score_created.unwrap().value);
        }
        Err(_) => println!("Error Captured on Score create {:?}", score_created),
    }
}

async fn amount_players(instance: &RaceBoard<WalletUnlocked>) -> u64 {
    let response = instance.methods().players_count().call().await.unwrap();
    print_result(response.value.to_string(), "Number of Players is:".to_string());
    response.value

}

async fn player_username(instance: &RaceBoard<WalletUnlocked>, seq_id: u64) -> String {
    let response = instance.methods().player_username(seq_id).call().await.unwrap();
    print_result(response.value.to_string(), "Player username:".to_string());
    response.value

}

async fn player_profile_by_username(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let response = instance.methods().username_player_profile(username.clone()).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Profile for username", username, response.unwrap().value); }
        Err(_) => { println!("{:?} \n", response.err()); }
    }
}

async fn player_profile_by_id(instance: &RaceBoard<WalletUnlocked>, seq_id: u64) {
    let response = instance.methods().id_player_profile(seq_id).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Profile for ID", seq_id, response.unwrap().value); }
        Err(_) => { println!("{} {}: {:?} \n", "Profile for ID", seq_id, response); }
    }
}
async fn username_exists(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let response = instance.methods().player_username_exists(username.clone()).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "username registered", username, response.unwrap().value);}
        Err(_) => { println!("{} {}: {:?} \n", "username is NOT registered", username, response); }
    }
}


async fn times_raced_id(instance: &RaceBoard<WalletUnlocked>, seq_id: u64) {
    let response = instance.methods().times_raced_id(seq_id).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Times Raced Player for ID", seq_id, response.unwrap().value); }
        Err(_) => { println!("{} {}: {:?} \n", "Captured Error Times Race Player for ID ", seq_id, response); }
    }
}
async fn times_raced_username(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let response = instance.methods().times_raced_username(username.clone()).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Times Race username Player username", username, response.unwrap().value);}
        Err(_) => { println!("{} {}: {:?} \n", "Captured Error Times Race Player username", username, response); }
    }
}


async fn player_last_score(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let response = instance.methods().player_last_race_score(username.clone()).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Last score for username", username, response.unwrap().value); }
        Err(_) => { println!("Captured Error Last score for username {:?} \n", response.err()); }
    }
}


async fn player_id_score(instance: &RaceBoard<WalletUnlocked>, seq_id: u64, race_num: u64) {
    let response = instance.methods().player_id_race_score(seq_id, race_num).call().await;
    match response {
        Ok(_) => { println!("{} ({}, {}) => {:?} \n", "Player score for GameScore-Key", seq_id, race_num, response.unwrap().value); }
        Err(_) => { println!("Captured Error Player score  {:?} \n", response.err()); }
    }
}

async fn all_players(instance: &RaceBoard<WalletUnlocked>) {
    let response = instance.methods().all_players().call().await;
    match response {
        Ok(_) => { println!("{}  => {:?} \n", "All Players", response.unwrap().value); }
        Err(_) => { println!("Captured Error All Players  {:?} \n", response.err()); }
    }
}
// async fn all_usernames_profiles(instance: &RaceBoard<WalletUnlocked>) {
//     let response = instance.methods().all_usernames_profiles().call().await;
//     match response {
//         Ok(_) => { println!("{}  => {:?} \n", "All Username Players", response.unwrap().value); }
//         Err(_) => { println!("Captured Error All Username Players  {:?} \n", response.err()); }
//     }
// }
// async fn all_usernames(instance: &RaceBoard<WalletUnlocked>) {
//     let response = instance.methods().all_usernames().call().await;
//     match response {
//         Ok(_) => { println!("{}  => {:?} \n", "All Username Players", response.unwrap().value); }
//         Err(_) => { println!("Captured Error All Username Players  {:?} \n", response.err()); }
//     }
// }

async fn all_player_scores(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let response = instance.methods().all_player_scores(username).call().await;
    match response {
        Ok(_) => { println!("{}  => {:?} \n", "All Player Scores", response.unwrap().value); }
        Err(_) => { println!("Captured Error All Player Scores {:?} \n", response.err()); }
    }
}

async fn submit_track_progress(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let response = instance.methods().submit_track_progress(username, 1, 2, 3, 4, 5).call().await;
    match response {
        Ok(_) => { println!("{}  => {:?} \n", "Track Score Submitted Event", response.unwrap().value); }
        Err(_) => { println!("Captured Error Track Score Submitted Event {:?} \n", response.err()); }
    }
}


async fn assert_amount_players(instance: &RaceBoard<WalletUnlocked>, assert_value: u64) {
    assert_eq!(amount_players(&instance).await, assert_value);
}

#[tokio::test]
async fn can_register_driver_with_fake_username() {

    // use another wallet: // get_wallet_balance(&wallet1.wallet, &asset_id).await,

    let (instance, _id) = get_contract_instance().await;

    let usernames = [
        "1username.si",
        "2username.si", 
        "3username.si", 
        "4username.si",

        "1username.si", // Err(_)ValueAlreadySet
        "1username.si", // Err(_)ValueAlreadySet
        ];
    
    // 0 Players
    assert_amount_players(&instance, 0).await;  

    for username in usernames {
        new_player(&instance, username.to_string()).await;
    }

    // 4 Players
    assert_amount_players(&instance, 4).await;   

    // == "neki2@username.si"
    assert_eq!(player_username(&instance, 2).await, usernames[2]); 
    
    // returns error
    //assert_eq!(player_username(&instance, 20).await, usernames[2]); 
    
    // PlayerProfile "neki2@username.si"
    player_profile_by_id(&instance, 2).await; 
    player_profile_by_username(&instance, usernames[2].to_string()).await; 

    // Errors, that are handled here-Web2
    player_profile_by_username(&instance, "WRONG_username_neki112@username.si".to_string()).await;
    player_profile_by_id(&instance, 8).await;
    username_exists(&instance, usernames[2].to_string()).await;
    username_exists(&instance, "WRONG_username_neki112@username.si".to_string()).await;
    times_raced_username(&instance, usernames[2].to_string()).await;
    times_raced_username(&instance, "WRONG_username_neki112@username.si".to_string()).await;
    

    // Submitting Scores
    times_raced_id(&instance, 2).await;
    submit_player_score(&instance, usernames[2].to_string(), 22, 156).await;
    times_raced_username(&instance, usernames[2].to_string()).await;
    player_profile_by_username(&instance, usernames[2].to_string()).await; 

    
    submit_player_score(&instance, usernames[2].to_string(), 44, 132).await;
    submit_player_score(&instance, usernames[2].to_string(), 33, 130).await;
    submit_player_score(&instance, usernames[2].to_string(), 1, 170).await;
    submit_player_score(&instance, usernames[2].to_string(), 16, 125).await;

    player_last_score(&instance, usernames[2].to_string()).await; 
    player_id_score(&instance, 2, 1).await; 
    player_id_score(&instance, 2, 2).await; 
    player_id_score(&instance, 2, 3).await; 
    
    player_profile_by_id(&instance, 2).await; 

    submit_player_score(&instance, usernames[1].to_string(), 4, 120).await;
    player_id_score(&instance, 1, 1).await; 

    new_player_with_email(&instance, usernames[2].to_string(), "email@mail.com".to_string()).await; // Value already set
    new_player_with_email(&instance, "mojUserName".to_string(), "email@mail.com".to_string()).await;
    all_players(&instance).await; 
    //all_usernames(&instance).await; 
    //all_usernames_profiles(&instance).await; 
    all_player_scores(&instance, usernames[2].to_string()).await; 

    let mut c: u64 = 0;
    while c <= 100{
        submit_track_progress(&instance, usernames[2].to_string()).await; 
        c = c+1;
    }

        

    // tokio::time::sleep(period * 2).await;

    //cargo test -- --nocapture

}   


