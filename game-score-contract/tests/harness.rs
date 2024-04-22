use fuels::{prelude::*, types::ContractId};
//use tokio::{sync::mpsc::Receiver, task::JoinHandle, time::sleep};
use core::time::Duration;

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


#[tokio::test]
async fn can_register_driver_with_fake_email() {
    let (_instance, _id) = get_contract_instance().await;
    let drivers = _instance.methods().drivers().call().await.unwrap();
    println!("{}", "drivers");
    println!("{:?}", drivers);

    let period = Duration::from_millis(500);
    // Define an array of emails
    let emails = [
        "neki1@mail.si",
        "neki1@mail.si",
        "neki1@mail.si",
        "neki2@mail.si",
        "neki3@mail.si",
        "neki4@mail.si",
    ];

    for email in &emails {
        let email_string = email.to_string(); // Convert &str to String
        let sss = _instance.methods().register_driver(email_string).call().await.unwrap();
        println!("{:?}", "register driver");
        println!("{:?}", sss);
        println!("{:?}", "");
        println!("{:?}", "");
    }
    tokio::time::sleep(period * 2).await;

    let new_drivers = _instance.methods().drivers().call().await.unwrap();
    println!("{}", "new_drivers");
    println!("{:?}", new_drivers);

}   


