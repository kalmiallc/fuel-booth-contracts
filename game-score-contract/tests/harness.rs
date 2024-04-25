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

async fn new_player(instance: &RaceBoard<WalletUnlocked>, _mail: String) {
    let player_created = instance.methods().register_email_player(_mail).call().await;
    match player_created {
        Ok(_) => {
            println!("{} {:?} \n", "New Email Player Created:", player_created.unwrap().value);
        }
        Err(_) => println!("{:?}", player_created),
    }
}

async fn submit_player_score(
    instance: &RaceBoard<WalletUnlocked>, 
    _mail: String,
    _damage: u64,
    _time: u64
) {
    let score_created = instance.methods().submit_score(_mail, _damage, _time).call().await;
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

async fn player_email(instance: &RaceBoard<WalletUnlocked>, seq_id: u64) -> String {
    let response = instance.methods().player_email(seq_id).call().await.unwrap();
    print_result(response.value.to_string(), "Player Email:".to_string());
    response.value

}

async fn player_profile_by_email(instance: &RaceBoard<WalletUnlocked>, email: String) {
    let response = instance.methods().email_player_profile(email.clone()).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Profile for email", email, response.unwrap().value); }
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
async fn email_exists(instance: &RaceBoard<WalletUnlocked>, email: String) {
    let response = instance.methods().player_email_exists(email.clone()).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "email registered", email, response.unwrap().value);}
        Err(_) => { println!("{} {}: {:?} \n", "email is NOT registered", email, response); }
    }
}


async fn times_raced_id(instance: &RaceBoard<WalletUnlocked>, seq_id: u64) {
    let response = instance.methods().times_raced_id(seq_id).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Times Raced Player for ID", seq_id, response.unwrap().value); }
        Err(_) => { println!("{} {}: {:?} \n", "Captured Error Times Race Player for ID ", seq_id, response); }
    }
}
async fn times_raced_email(instance: &RaceBoard<WalletUnlocked>, email: String) {
    let response = instance.methods().times_raced_email(email.clone()).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Times Race Email Player email", email, response.unwrap().value);}
        Err(_) => { println!("{} {}: {:?} \n", "Captured Error Times Race Player email", email, response); }
    }
}


async fn player_last_score(instance: &RaceBoard<WalletUnlocked>, email: String) {
    let response = instance.methods().player_last_race_score(email.clone()).call().await;
    match response {
        Ok(_) => { println!("{} {}: {:?} \n", "Last score for email", email, response.unwrap().value); }
        Err(_) => { println!("Captured Error Last score for email {:?} \n", response.err()); }
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

async fn all_player_scores(instance: &RaceBoard<WalletUnlocked>, email: String) {
    let response = instance.methods().all_player_scores(email).call().await;
    match response {
        Ok(_) => { println!("{}  => {:?} \n", "All Player Scores", response.unwrap().value); }
        Err(_) => { println!("Captured Error All Player Scores {:?} \n", response.err()); }
    }
}


async fn assert_amount_players(instance: &RaceBoard<WalletUnlocked>, assert_value: u64) {
    assert_eq!(amount_players(&instance).await, assert_value);
}

#[tokio::test]
async fn can_register_driver_with_fake_email() {

    // use another wallet: // get_wallet_balance(&wallet1.wallet, &asset_id).await,

    let (instance, _id) = get_contract_instance().await;

    let emails = [
        "neki1@mail.si",
        "neki2@mail.si", 
        "neki3@mail.si", 
        "neki4@mail.si",

        "neki1@mail.si", // Err(_)ValueAlreadySet
        "neki1@mail.si", // Err(_)ValueAlreadySet
        ];
    
    // 0 Players
    assert_amount_players(&instance, 0).await;  

    for email in emails {
        new_player(&instance, email.to_string()).await;
    }

    // 4 Players
    assert_amount_players(&instance, 4).await;   

    // == "neki2@mail.si"
    assert_eq!(player_email(&instance, 2).await, emails[2]); 
    
    // returns error
    //assert_eq!(player_email(&instance, 20).await, emails[2]); 
    
    // PlayerProfile "neki2@mail.si"
    player_profile_by_id(&instance, 2).await; 
    player_profile_by_email(&instance, emails[2].to_string()).await; 

    // Errors, that are handled here-Web2
    player_profile_by_email(&instance, "WRONG_EMAIL_neki112@mail.si".to_string()).await;
    player_profile_by_id(&instance, 8).await;
    email_exists(&instance, emails[2].to_string()).await;
    email_exists(&instance, "WRONG_EMAIL_neki112@mail.si".to_string()).await;
    times_raced_email(&instance, emails[2].to_string()).await;
    times_raced_email(&instance, "WRONG_EMAIL_neki112@mail.si".to_string()).await;
    

    // Submitting Scores
    times_raced_id(&instance, 2).await;
    submit_player_score(&instance, emails[2].to_string(), 22, 156).await;
    times_raced_email(&instance, emails[2].to_string()).await;
    player_profile_by_email(&instance, emails[2].to_string()).await; 

    
    submit_player_score(&instance, emails[2].to_string(), 44, 132).await;
    submit_player_score(&instance, emails[2].to_string(), 33, 130).await;
    submit_player_score(&instance, emails[2].to_string(), 1, 170).await;
    submit_player_score(&instance, emails[2].to_string(), 16, 125).await;

    player_last_score(&instance, emails[2].to_string()).await; 
    player_id_score(&instance, 2, 1).await; 
    player_id_score(&instance, 2, 2).await; 
    player_id_score(&instance, 2, 3).await; 
    
    player_profile_by_id(&instance, 2).await; 

    submit_player_score(&instance, emails[1].to_string(), 4, 120).await;
    player_id_score(&instance, 1, 1).await; 


    all_players(&instance).await; 
    all_player_scores(&instance, emails[2].to_string()).await; 

    // tokio::time::sleep(period * 2).await;

    

}   


