const path = require("path");
require('dotenv').config({ path: './.env' });
const HDWalletProvider = require("@truffle/hdwallet-provider");
const Web3 = require("web3");
const web3 = new Web3();
const MetaMaskAccountIndex = 2;
const privateKeyTest = '0xa51ce828724031ad92a4965e12b39c82a73a1db926719060c8511efb81fd05f7';ovider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      port: process.env.PORT,
      host: "127.0.0.1",
      network_id: "*",
      gas: 4710000,
    },
    local: {
      host: "localhost",
      port: process.env.PORT,
      network_id: "*",
      gas: 4710000,
     },
    main: {
      provider: function() {
        return new HDWalletProvider(
          //private keys array
          process.env.MNEMONIC,
          //url to ethereum node
          process.env.WEB3_PROVIDER_ADDRESS
        )
      },
      network_id: 1,
      gas: 4000000,
      gasPrice: 200000000000,
      confirmations: 2,
      websockets: true
    },
    kovan: {
      provider: function() {
        return new HDWalletProvider(
          //private keys array
          process.env.MNEMONIC,
          //url to ethereum node
          process.env.WEB3_PROVIDER_ADDRESS
        )
      },
      network_id: 42,
      gas: 12450000,
      gasPrice: 20000000000,
      confirmations: 2,
      websockets: true
    },
    rinkeby_infura: {
      provider: function () {
        return new HDWalletProvider(process.env.MNEMONIC, "wss://rinkeby.infura.io/ws/v3/239a6062fd364546bdceba84ab5e75fb", MetaMaskAccountIndex)
      },
      network_id: 4,
      gasPrice: web3.utils.toWei('30', 'gwei'),
      gas: 5000000,
      timeoutBlocks: 250,
      networkCheckTimeout: 999999
    }
  },
  compilers: {
    solc: {
      version: ">=0.8.7 <0.9.0",
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API
  },
  
};