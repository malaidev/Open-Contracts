[![Static Analysis](https://github.com/0xHashstack/Open-contracts/actions/workflows/slither.yml/badge.svg?branch=development-v0.2.0)](https://github.com/0xHashstack/Open-contracts/actions/workflows/slither.yml)     [![Build Updated](https://github.com/0xHashstack/Open-contracts/actions/workflows/main.yml/badge.svg?branch=development-v0.2.0)](https://github.com/0xHashstack/Open-contracts/actions/workflows/main.yml)     [![Build Yaml](https://github.com/0xHashstack/Open-contracts/actions/workflows/build.yml/badge.svg?branch=development-v0.2.0)](https://github.com/0xHashstack/Open-contracts/actions/workflows/build.yml)     
<!-- [![.github/workflows/greetings.yml](https://github.com/0xHashstack/Open-contracts/actions/workflows/greetings.yml/badge.svg?branch=development-v0.2.0&event=push)](https://github.com/0xHashstack/Open-contracts/actions/workflows/greetings.yml) -->

<!-- [![Test](https://github.com/0xHashstack/Open-contracts/actions/workflows/test.yml/badge.svg)](https://github.com/0xHashstack/Open-contracts/actions/workflows/test.yml) -->

In this repository, you will find the latest smart contracts enabling Open protocol.

------


### Deployment Guide

This is a complete deployment guide on how you can deploy contracts by yourself. Initially we are deploying on Binance smart chain testnet, 
you can deploy on any chain with minor changes in hardhatconfig.js file. Initially you will require some test bnb so grab some tokens from
the [faucet](https://testnet.binance.org/faucet-smart).

Open your terminal and follow the steps

```
$ git clone -b development https://github.com/0xHashstack/Open-protocol
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
AccessRegistry: `0x844B4a66EcDdFd54Ec6cCe12536B653cbefFc6Cd`

Diamond: `0xe11b598A5345fC67E8a41108d690fFd0E7278105`

## Markets Used :

tBTC deployed:  `0x4b129FE33Ed077aBD649da2e56Daf02aE9A67766`

tUSDC deployed:  `0xacE2E33264Dd184ef563Ceb3db636044BFE8d0E2`

tUSDT deployed:  `0xdb594B15797c47e04c85E209b04B8C27F27D9A0D`

tSxp deployed:  `0x0343b91e5dD17D749a5D44E3Ecb90196b056967b`

tCake deployed:  `0x72987967c5ae63e263B16822689970d66F33fCc2`

t.wBNB address : `0x14EbA6ea192aC6C937D80EA3Fa623fcBE11170f6`

## Faucet Liquidity :

Faucet addr :
`0x372a7C4482A9E4E1FBe017BB4C5f2d0f3CC200fc`

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

Open protocol's source code is secured under Business Source License [Read more](https://github.com/0xHashstack/Open-contracts/blob/release-v0.1.2/LICENSE.md)
