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
$ npx hardhat run --network bsctestnet scripts/1_deploy_diamond.js
```
Congrats ! You have successfully ran the first script.You might have recieved a *new Diamond address*, keep that it will come handy in a while. Now type

```
$ code .
```
This will open the Open-protocol repository in vscode. Feel free to use any IDE you like.
Now go into scripts folder, 
inside that *2_deploy_facets.js* inside that replace your *new Diamond address* with the old one.
Similarly replace with the *new Diamond address* in *3_add_markets.js*.
Great! You have added your newly deployed Diamond address. Dont forget to save all the files.

Now, get back to your terminal and type
```
$ npx hardhat run --network bsctestnet scripts/2_deploy_facets.js
```
This will run the second script that is  2_deploy_facets.js

Finally, type

```
$ npx hardhat run --network bsctestnet scripts/3_add_markets.js
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
[![Static Analysis](https://github.com/0xHashstack/Open-protocol/actions/workflows/slither.yml/badge.svg?branch=staging)](https://github.com/0xHashstack/Open-protocol/actions/workflows/slither.yml)

[![Test](https://github.com/0xHashstack/Open-protocol/actions/workflows/test.yml/badge.svg?branch=staging)](https://github.com/0xHashstack/Open-protocol/actions/workflows/test.yml)
