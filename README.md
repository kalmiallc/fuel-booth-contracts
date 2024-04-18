# fuel-contracts

smart contracts enviroment for fuel network.   
the contract to store and give data about the scores users have accomplished in the game
- [game repository](https://github.com/BKcore/HexGL/tree/master/textures/ships/feisar)


## Fuel Documentation
- [How to: Make local Fuel dev enviroment](https://docs.fuel.network/docs/intro/quickstart-contract/)
- [Use sway programming language](https://docs.fuel.network/docs/sway/)
 

## Getting started
- work, test and do your thing on the **develop** branch **!**
- ```git clone```, use ssh if you don't have account password (for Bitbucket)
- ```fuelup --version``` should give you a verison
- use cargo for testing
- **```forc build```** to build contracts for testing

## local wallet & account
- [Read and use forc wallet](https://github.com/FuelLabs/forc-wallet)
- check that you have at least 1 address. ```forc-wallet accounts```
- if not create using ```forc-wallet new```

## testing with cargo
- first time ever? please install ```cargo install cargo-generate``` (a tool for testing)
- no test file in project? make one with: ```cargo generate --init fuellabs/sway templates/sway-test-rs --name game-score-contracts```
- write your tests in **/tests/harness.rs**
- **```cargo test```** to run test script(s) (make sure to use ```forc build``` to have latest changes from smart contract before running tests)

## deploy:
- first get some free gas money [Faucet test tokens](https://faucet-beta-5.fuel.network/)
- deploy using ```forc deploy --testnet``` and follow prompt

