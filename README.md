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

# Contract Records
This section would have all the records regarding latest contracts deployed , markets being used and faucet liquidity

## Contracts Deployed :

## Markets Used :

tBTC deployed:  `0x664aABd659Ae578454c7A7FC5b850DFB2203a87C`

tUSDC deployed:  `0x07D293cFc6E76430af18Ab6Ac3f41828e202D159`

tUSDT deployed:  `0x3d2b1f363c79BaB4320DD0522239617aF31DaFde`

tSxp deployed:  `0xb6c2c0764e69FBb1CeC2254ec927Ddc7fe42738F`

tCake deployed:  `0x498D69f8ddf475E21C3d036F0bf0C6Ef82FEF2Ea`

t.wBNB address : `0x359A0A7DffEa6B95a436d5E558d20EC8972EbC4B`

## Faucet Liquidity :

Faucet addr :
`0x281890B95BaFe28587a93fAA1eF737563fd79205`

tBTC : `false`

tUSDC : `false`

tUSDT : `false`

t.wBNB : `false`


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

