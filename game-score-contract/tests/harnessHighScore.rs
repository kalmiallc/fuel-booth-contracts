use fuels::{prelude::*, types::ContractId};
//use tokio::{sync::mpsc::Receiver, task::JoinHandle, time::sleep};
//use core::time::Duration;

abigen!(Contract(
    name = "HighScore",
    abi = "out/debug/game-score-contract-abi.json"
));


async fn get_contract_instance() -> (HighScore<WalletUnlocked>, ContractId) {
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

    let instance = HighScore::new(id.clone(), wallet);

    (instance, id.into())
}



async fn new_player(instance: &HighScore<WalletUnlocked>, _username: String, _email: String) {
    let player_created = instance.methods().new_player(_username, _email).call().await;
    match player_created {
        Ok(_) => {
            println!("{} {:?} \n", "New username & Email Player Created:", player_created.unwrap().value);
        }
        Err(_) => println!("error New username & Email Player Created {:?}", player_created),
    }
}

async fn submit_player_score(instance: &HighScore<WalletUnlocked>, username: String, damage: u64, time: u64) {
    let score_created = instance.methods().submit_new_score(3, 90, damage, username, time, 22).call().await;
    match score_created {
        Ok(_) => {
            println!("New Score Created: {:?}", score_created.unwrap().value);
        }
        Err(_) => println!("Error: {:?}", score_created),
    }
}

async fn amount_players(instance: &HighScore<WalletUnlocked>) -> u64 {
    let response = instance.methods().count_players().call().await.unwrap();
    println!("Number of Players is: {:?}", response.value);
    response.value
}


async fn all_players(instance: &HighScore<WalletUnlocked>) {
    let response = instance.methods().get_players().call().await;
    match response {
        Ok(_) => { println!("{}  => {:?} \n", "All Players", response.unwrap().value); }
        Err(_) => { println!("Captured Error All Players  {:?} \n", response.err()); }
    }
}

#[tokio::test]
async fn high_score_register_and_score() {
    let (instance, _id) = get_contract_instance().await;

    let usernames = [
        "1username.si",
        "2username.si", 
        "3username.si", 
        "4username.si",
        "1username.si", // This will attempt to register a duplicate and should be handled accordingly
        "1username.si", // Another attempt at a duplicate
    ];
    
    assert_eq!(amount_players(&instance).await, 0, "Initial player count should be 0.");  

    for username in usernames.iter() {
        new_player(&instance, username.to_string(), "emailString".to_string()).await;
    }

    // Assuming the contract prevents duplicate registrations, we expect 4 unique players
    assert_eq!(amount_players(&instance).await, 4, "Expected player count after registration attempts should be 4.");   

    // Example of submitting a score for a specific player
    submit_player_score(&instance, "2username.si".to_string(), 22, 156).await;

    // Further tests and assertions can be added here following the same pattern
}

// Additional test functions and scenarios can be added below as needed