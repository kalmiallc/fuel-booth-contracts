use fuels::{prelude::*, types::ContractId};

// Load abi from json
abigen!(Contract(
    name = "ScoreBoard",
    abi = "out/debug/game-score-contract-abi.json"
));

async fn get_contract_instance() -> (ScoreBoard<WalletUnlocked>, ContractId) {
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

    let instance = ScoreBoard::new(id.clone(), wallet);

    (instance, id.into())
}

#[tokio::test]
async fn can_get_contract_id() {
    let (_instance, _id) = get_contract_instance().await;
    let result_game_version = _instance.methods().version_of_the_game().call().await.unwrap();
    assert_eq!(result_game_version.value, 1);
    // Now you have an instance of your contract you can use to test each function
}
