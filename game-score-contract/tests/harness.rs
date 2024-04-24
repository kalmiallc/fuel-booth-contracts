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
    // create some random mail, can be with random or timestamp
    
    let player_created = instance.methods().register_email_player(_mail).call().await;
    match player_created {
        Ok(_) => {
            println!("{} {:?} \n", "New Email Player Created:", player_created.unwrap().value);
        }
        Err(_) => println!("{:?}", player_created),
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

    // Error
    player_profile_by_email(&instance, "WRONG_EMAIL_neki112@mail.si".to_string()).await;
    player_profile_by_id(&instance, 8).await;
    
    
    // tokio::time::sleep(period * 2).await;

    

}   


