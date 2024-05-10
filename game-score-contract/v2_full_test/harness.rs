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
async fn new_player(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let player_created = instance.methods().register_username_player(username).call().await;
    match player_created {
        Ok(_) => {
            println!("New username Player Created: {:?}", player_created.unwrap().value);
        }
        Err(_) => println!("Error: {:?}", player_created),
    }
}

async fn submit_player_score(instance: &RaceBoard<WalletUnlocked>, username: String, damage: u64, time: u64) {
    let score_created = instance.methods().submit_score(username, damage, time).call().await;
    match score_created {
        Ok(_) => {
            println!("New Score Created: {:?}", score_created.unwrap().value);
        }
        Err(_) => println!("Error: {:?}", score_created),
    }
}

async fn amount_players(instance: &RaceBoard<WalletUnlocked>) -> u64 {
    let response = instance.methods().players_count().call().await.unwrap();
    println!("Number of Players is: {:?}", response.value);
    response.value
}

#[tokio::test]
async fn can_register_driver_with_fake_username() {
    let (instance, _id) = get_contract_instance().await;

    let usernames = [
        "1username.seri",
        "2username.seri", 
        "3username.seri", 
        "4username.seri",
        "1username.seri", // This will attempt to register a duplicate and should be handled accordingly
        "1username.seri", // Another attempt at a duplicate
    ];
    
    assert_eq!(amount_players(&instance).await, 0, "Initial player count should be 0.");  

    for username in usernames.iter() {
        new_player(&instance, username.to_string()).await;
    }

    // Assuming the contract prevents duplicate registrations, we expect 4 unique players
    assert_eq!(amount_players(&instance).await, 4, "Expected player count after registration attempts should be 4.");   

    // Example of submitting a score for a specific player
    submit_player_score(&instance, "2username.seri".to_string(), 22, 156).await;

    // Further tests and assertions can be added here following the same pattern
}

// Additional test functions and scenarios can be added below as needed