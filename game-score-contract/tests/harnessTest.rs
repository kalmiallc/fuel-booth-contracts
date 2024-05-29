use fuels::{prelude::*, types::ContractId};
//use tokio::{sync::mpsc::Receiver, task::JoinHandle, time::sleep};
//use core::time::Duration;
//use sha256::{digest, try_digest};
//use fuels::tx::Bytes32; 
//use std::str::FromStr;
//let _hex_string = "0x0000000000100000000000000000000000000000000000000000000000000000";
//let b256 = Bytes32::from_str(_hex_string).expect("failed to create Bytes32 from string");
//Bits256(*b256)
//use fuels::types::errors::Error;


use sha2::{Digest, Sha256};
use fuels::types::Bits256;

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
async fn new_player(instance: &RaceBoard<WalletUnlocked>, username: String, email: String) -> String {

    // hash sha256 username
    let mut hasher_username = Sha256::new();
    hasher_username.update(username.clone());
    let _arg_username: [u8; 32] = hasher_username.finalize().into();

    // hash sha256 username and email
    let mut hasher = Sha256::new();
    hasher.update(username.clone() + &email);
    let arg: [u8; 32] = hasher.finalize().into();


    let player_created = instance.methods()
    .register(username, Bits256(arg)).call().await;
    
    match player_created {
        Ok(_) => {
            //println!("player_created: {:?}", player_created.unwrap().value); 
            format!("{:?}", player_created.unwrap().value)
        }
        Err(error) => {
            //println!("Error: {:?}", error); 
            error.to_string()
        }
    }
}
async fn new_player_score(instance: &RaceBoard<WalletUnlocked>, username: String, score_type: u64, time: u64) {

    // hash sha256 username
    let mut hasher_username = Sha256::new();
    hasher_username.update(username.clone());
    let _arg_username: [u8; 32] = hasher_username.finalize().into();



    // let score_created = instance.methods().submit_score(Bits256(arg_username), 10, time, score_type).call().await;
    let score_created = instance.methods().submit_score(username, 10, time, score_type).call().await;
    
    match score_created {
        Ok(_) => {
            println!("score_created ------------: {:?}", score_created.unwrap().value); 
            //format!("{:?}", score_created.unwrap().value)
        }
        Err(error) => {
            println!("Error new_player_score: {:?}", error); 
            //error.to_string()
        }
    }
}


async fn get_a_player(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let mut hasher = Sha256::new();
    hasher.update(username.clone());
    let arg: [u8; 32] = hasher.finalize().into();
    let response = instance.methods().player(Bits256(arg)).call().await;
    match response {
        Ok(_) => { println!("get_a_player {} {} {:?} \n", "player", username, response.unwrap().value); }
        Err(_) => { println!("get_a_player error {:?} \n", response.err()); }
    }
}
async fn get_a_username(instance: &RaceBoard<WalletUnlocked>, index: u64) -> String{
    let response = instance.methods().username(index.clone()).call().await;
    match response {
        Ok(_) => { /*println!("{} {} {:?} \n", "player username vector_index:", index, response.unwrap().value);*/ 
                response.unwrap().value
                 }
        Err(_) => { /*println!("{:?} \n", response.err());*/ "error".to_string() }
    }
}


async fn usernames_length(instance: &RaceBoard<WalletUnlocked>) -> u64 {
    
    let response = instance.methods().total_players().call().await;
    //let meme = response.clone();
    match response {
        Ok(_) => { /*println!("{}  {:?} \n", "usernames_length", response.unwrap().value);*/ response.unwrap().value }
        Err(_) => { println!("usernames_length Error {:?} \n", response.err());  0}
    }
}
async fn list_player_scores(instance: &RaceBoard<WalletUnlocked>, username: String) {
    let mut hasher = Sha256::new();
    hasher.update(username);
    let arg: [u8; 32] = hasher.finalize().into();
    let response = instance.methods().scores(Bits256(arg)).call().await;
    match response {
        Ok(_) => { println!("{}  {:?} \n", "get_scores", response.unwrap().value); }
        Err(_) => { println!("{:?} \n", response.err()); }
    }
}

async fn list_players(instance: &RaceBoard<WalletUnlocked>) {
    let response = instance.methods().players().call().await;
    match response {
        Ok(_) => { println!("{}  {:?} \n", "get_players", response.unwrap().value); }
        Err(_) => { println!("{:?} \n", response.err()); }
    }
}

#[tokio::test]
async fn players_can_register() {
    let (instance, _id) = get_contract_instance().await;

    let usr1 = ("primoz".to_string(), "primoz@mail.com".to_string());
    let usr2 = ("marko".to_string(), "marko@mail.com".to_string());
    let usr3 = ("jure".to_string(), "jure@mail.com".to_string());
    let usr4 = ("tine".to_string(), "tine@mail.com".to_string());
    let usr5 = ("nina".to_string(), "nina@mail.com".to_string());
    
    assert!(usernames_length(&instance).await == 0, "Usernames length should be 0");
    let first_user = new_player(&instance, usr1.0.clone(), usr1.1.clone()).await;
    assert!(first_user.contains("vector_index: 0,"), "vector_index should be 0");
    
    let second_user = new_player(&instance, usr2.0.clone(), usr2.1).await;
    assert!(second_user.contains("vector_index: 1,"), "vector_index should be 1");
    assert!(usernames_length(&instance).await == 2, "Usernames length should be 2");

    let existing_user = new_player(&instance, usr1.0.clone(), usr1.1).await;
    assert!(existing_user.contains("UsernameExists"), "UsernameExists was not thrown!");
    assert!(usernames_length(&instance).await == 2, "Usernames length should be 2");


    let third_user = new_player(&instance, usr3.0.clone(), usr3.1).await;
    assert!(third_user.contains("vector_index: 2,"), "vector_index should be 1");
    assert!(usernames_length(&instance).await == 3, "Usernames length should be 3");
   
    get_a_player(&instance, usr3.0.clone()).await;
    assert!(get_a_username(&instance, 2).await == usr3.0.clone(), "Wrong username at usernames index 2");
    assert!(usernames_length(&instance).await == 3, "Usernames length should be 3");
   

    new_player_score(&instance, usr1.0.clone(), 1, 222).await;
    new_player_score(&instance, usr3.0.clone(), 1, 453).await;
    new_player_score(&instance, usr3.0.clone(), 1, 243).await;
    new_player_score(&instance, "krneki".to_string(), 1, 223).await;
    new_player_score(&instance, usr3.0.clone(), 1, 1223).await;
    new_player_score(&instance, usr3.0.clone(), 1, 1023).await;
    new_player_score(&instance, usr3.0.clone(), 2, 173).await;
    new_player_score(&instance, usr3.0.clone(), 2, 2123).await;
    new_player_score(&instance, usr3.0.clone(), 1, 23).await;

    list_player_scores(&instance, usr1.0.clone()).await;
    list_player_scores(&instance, usr3.0.clone()).await;

    new_player(&instance, usr4.0.clone(), usr4.1).await;
    assert!(usernames_length(&instance).await == 4, "Usernames length should be 4");
    get_a_player(&instance, usr4.0.clone()).await;
    get_a_player(&instance, usr3.0.clone()).await;

    assert!(get_a_username(&instance, 3).await == usr4.0.clone(), "Wrong username at usernames index 3");
    assert!(get_a_username(&instance, 0).await == usr1.0.clone(), "Wrong username at usernames index 0");
    assert!(get_a_username(&instance, 1).await == usr2.0.clone(), "Wrong username at usernames index 1");
    assert!(get_a_username(&instance, 2).await == usr3.0.clone(), "Wrong username at usernames index 2");
    assert!(get_a_username(&instance, 4).await == "error".to_string(), "Expected IndexIsOverMax error for usernames index");


    new_player(&instance, usr5.0.clone(), usr5.1).await;
    assert!(usernames_length(&instance).await == 5, "Usernames length should be 5");
    get_a_player(&instance, usr5.0.clone()).await;

    assert!(get_a_username(&instance, 4).await == usr5.0.clone(), "Wrong username at usernames index 4");
    assert!(get_a_username(&instance, 0).await == usr1.0.clone(), "Wrong username at usernames index 0");
    assert!(get_a_username(&instance, 1).await == usr2.0.clone(), "Wrong username at usernames index 1");
    assert!(get_a_username(&instance, 2).await == usr3.0.clone(), "Wrong username at usernames index 2");
    assert!(get_a_username(&instance, 3).await == usr4.0.clone(), "Wrong username at usernames index 3");


    list_players(&instance).await;
    assert!(usernames_length(&instance).await == 5, "Usernames length should be 5");
    assert!(get_a_username(&instance, 5).await == "error".to_string(), "Expected IndexIsOverMax error for usernames index");
    assert!(get_a_username(&instance, 6).await == "error".to_string(), "Expected IndexIsOverMax error for usernames index");

   
}

// Additional test functions and scenarios can be added below as needed