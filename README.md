[![Slither tests](https://github.com/0xHashstack/Open-protocol/actions/workflows/slither.yml/badge.svg?branch=staging)](https://github.com/0xHashstack/Open-protocol/actions/workflows/slither.yml)     [![Unit tests](https://github.com/0xHashstack/Open-contracts/actions/workflows/main.yml/badge.svg)](https://github.com/0xHashstack/Open-contracts/actions/workflows/main.yml)

<!-- [![Test](https://github.com/0xHashstack/Open-contracts/actions/workflows/test.yml/badge.svg)](https://github.com/0xHashstack/Open-contracts/actions/workflows/test.yml) -->

In this repository, you will find the latest smart contracts enabling Open protocol.

------


### Deployment Guide

This is a complete deployment guide on how you can deploy contracts by yourself. Initially we are deploying on Binance smart chain testnet, 
you can deploy on any chain with minor changes in hardhatconfig.js file. Initially you will require some test bnb so grab some tokens from
the [faucet](https://testnet.binance.org/faucet-smart).

Open your terminal and follow the steps

```
$ git clone -b review https://github.com/0xHashstack/Open-protocol
```
After the repository is cloned

```
$ npm install
```
Now all node dependencies are installed, you're ready to go!

```
$ npx hardhat run --network bsctestnet scripts/deploy_all.js
```
Congrats! you have successfully deployed all the contracts on bsc testnet.
Dont forget to check it out on [bscscan testnet](https://testnet.bscscan.com/)



# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

