const { task } = require("hardhat/config");
const { getSelectors, FacetCutAction } = require('./scripts/libraries/diamond.js')
const utils = require('ethers').utils

require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  console.log("Task run");
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

task("Tenderly", "Test contracts", async(taskArgs, hre) => {

  const diamondAddress = "0xC63D5215B393743Cf255E0FF2260a4c17b23dD01";
  const tokenListAddress = "0x8b4E9Db1DA675139F3a56b155dD4f4cE99a9f245";
  const comptrollerAddress = "0x77De5CF8c84F8b936deb167Ed37b95c0F75ddCbD";
  const liquidatorAddress = "0x2676191e2dFFBE246600B2D77F23e0539ce3d901";
  const reserveAddress = "0x322cC8175a3b3a230c368981c31E50Ef918daA4b";
  const oracleAddress = "0x9c34a1eD973D95dbA464cae4a6c8903cD91fE30b";
  const loanAddress = "0x9bed8B8745aCA8405d550789f602F10D160aC7f5";
  const loan1Address = "0x372d8090170E275cA85723823eeBAa0ea98f03A4";
  const depositAddress = "0xC593a45a14E04821d9DcEF234559C7504908317b";
  const accessAddress = "0x6Dc785CC760Dae9E34679d0ecfa6c112E3352c84";
  const contracts = [
    {
        name: "TokenList",
        address: tokenListAddress
    },
    {
        name: "Comptroller",
        address: comptrollerAddress
    },
    {
        name: "Deposit",
        address: depositAddress
    },
    {
        name: "Liquidator",
        address: liquidatorAddress
    },
    {
        name: "Loan",
        address: loanAddress
    },
    {
        name: "Loan1",
        address: loan1Address
    },
    {
        name: "Reserve",
        address: reserveAddress
    },
    {
        name: "OracleOpen",
        address: oracleAddress
    },
    {
        name: "AccessRegistry",
        address: accessAddress
    },
    {
        name: "OpenDiamond",
        address: diamondAddress
    }
  ]

    await hre.tenderly.verify(...contracts)


  // const Test = await ethers.getContractFactory("Test");
  // const test = await Test.deploy();

  // await test.deployed()

  // await hre.tenderly.verify({
  //     name: "Test",
  //     address: test.address,
  // })
});

 require('hardhat-contract-sizer');
 require("@nomiclabs/hardhat-etherscan");
 require('dotenv').config();

 require("@tenderly/hardhat-tenderly");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // forking: {
      //   url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      //   blockNumber: 13327183,
      // }
    },
    ropsten: {
      chainId: 3,
      url: process.env.API_URL,
      accounts: {
        mnemonic: process.env.MNEMONIC
      },
      gas: 2100000, 
      gasPrice: 8000000000
    },
    
    kovan: {
      accounts: 
      {
          mnemonic: process.env.MNEMONIC,
      },
      url: "https://kovan.infura.io/v3/99b8947af7e14278ae235bb21eb81f53",
      chainId: 42,
      timeout: 200000,
      gas: 2100000, 
      gasPrice: 8000000000,
      nonce:150
    },
    bsctestnet: {
      accounts: {
        mnemonic: process.env.MNEMONIC
      },
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      timeout: 200000,
      gas: 2100000, 
    },
//     harmony: {
//       url: 'https://api.s0.b.hmny.io',
//       timeout: 200000,
//       accounts: [process.env.HARMONY_PRIVATE_KEY],
//       gas: 2100000, 
//       gasPrice: 8000000000
//     },
//     avax: {
//       url: 'https://api.avax.network/ext/bc/C/rpc',
//       timeout: 200000,
//       accounts: [process.env.PRIVATE_KEY],
//       chainId: 43114
//     }
  },
  solidity: {
    compilers: [
      {
        version: "0.8.1",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.7.3",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  mocha: {
    timeout: 200000
  },
  tenderly: {
    project: "Test",
    username: "dinh",
  }
};
