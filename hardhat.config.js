const { task } = require("hardhat/config");
const { getSelectors, FacetCutAction } = require('./scripts/libraries/diamond.js')
const utils = require('ethers').utils

require("@nomiclabs/hardhat-waffle");

// async function deployDiamond() {
//   const accounts = await ethers.getSigners()
//   const contractOwner = await accounts[0]
//   console.log(`contractOwner ${contractOwner.address}`)

//   // deploy DiamondCutFacet
//   const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
//   const diamondCutFacet = await DiamondCutFacet.deploy()
//   await diamondCutFacet.deployed()

//   console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

//   // deploy Diamond
//   const Diamond = await ethers.getContractFactory('OpenDiamond')
//   const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
//   await diamond.deployed()
//   console.log('Diamond deployed:', diamond.address)

//   // deploy DiamondInit
//   // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
//   // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
//   const DiamondInit = await ethers.getContractFactory('DiamondInit')
//   const diamondInit = await DiamondInit.deploy()
//   await diamondInit.deployed()
//   console.log('DiamondInit deployed:', diamondInit.address)

//   // deploy facets
//   console.log('')
//   console.log('Deploying facets')
//   const FacetNames = [
//       'DiamondLoupeFacet'
//   ]
//   const cut = []
//   for (const FacetName of FacetNames) {
//       const Facet = await ethers.getContractFactory(FacetName)
//       const facet = await Facet.deploy()
//       await facet.deployed()
//       console.log(`${FacetName} deployed: ${facet.address}`)
//       cut.push({
//           facetAddress: facet.address,
//           action: FacetCutAction.Add,
//           functionSelectors: getSelectors(facet),
//           facetId: 1
//       })
//   }

//   // upgrade diamond with facets
//   console.log('')
//   // console.log('Diamond Cut:', cut)
//   const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
//   let tx
//   let receipt
//   // call to init function
//   let functionCall = diamondInit.interface.encodeFunctionData('init')
//   tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
//   console.log('Diamond cut tx: ', tx.hash)
//   receipt = await tx.wait()
//   if (!receipt.status) {
//       throw Error(`Diamond upgrade failed: ${tx.hash}`)
//   }

//   console.log('Completed diamond cut')
  
//   return diamond.address
// }

// async function deployOpenFacets(diamondAddress) {
//   const accounts = await ethers.getSigners()
//   const contractOwner = accounts[0]
//   console.log(" ==== Begin deployOpenFacets === ");
//   // const diamondAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
//   diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
//   diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

//   console.log("Begin deploying facets");
//   const OpenNames = [
//       'TokenList',
//       'Comptroller',
//       'Liquidator',
//       'Reserve',
//       'OracleOpen',
//       'Loan',
//       'Loan1',
//       'Deposit',
//       'AccessRegistry'
//   ]
//   const opencut1 = []
//   let facetId = 10;
//   for (const FacetName of OpenNames) {
//       const Facet = await ethers.getContractFactory(FacetName)
//       const facet = await Facet.deploy()
//       await facet.deployed()
//       console.log(`${FacetName} deployed: ${facet.address}`)
//       opencut1.push({
//           facetAddress: facet.address,
//           action: FacetCutAction.Add,
//           functionSelectors: getSelectors(facet),
//           facetId :facetId
//       })
//       facetId ++;
//   }

//   console.log("Begin diamondcut facets");

//   tx = await diamondCutFacet.diamondCut(
//       opencut1, ethers.constants.AddressZero, '0x', { gasLimit: 8000000 }
//   )
//   receipt = await tx.wait()


//   if (!receipt.status) {
//       throw Error(`Diamond upgrade failed: ${tx.hash}`)
//   }

// }
// async function addMarkets(diamondAddress) {
//   const accounts = await ethers.getSigners()
//   const contractOwner = accounts[0]

//   const tokenList = await ethers.getContractAt('TokenList', diamondAddress)
//   const comptroller = await ethers.getContractAt('Comptroller', diamondAddress);
 
//   const comit_TWOWEEKS = utils.formatBytes32String("comit_TWOWEEKS")
//   const comit_NONE = utils.formatBytes32String("comit_NONE")
//   const comit_ONEMONTH = utils.formatBytes32String("comit_ONEMONTH")
//   const comit_THREEMONTHS = utils.formatBytes32String("comit_THREEMONTHS")

//   console.log("setCommitment begin");
//   await comptroller.connect(contractOwner).setCommitment(comit_NONE);
//   await comptroller.connect(contractOwner).setCommitment(comit_TWOWEEKS);
//   await comptroller.connect(contractOwner).setCommitment(comit_ONEMONTH);
//   await comptroller.connect(contractOwner).setCommitment(comit_THREEMONTHS);
  
//   console.log("updateAPY begin");
//   await comptroller.connect(contractOwner).updateAPY(comit_NONE, 6);
//   await comptroller.connect(contractOwner).updateAPY(comit_TWOWEEKS, 16);
//   await comptroller.connect(contractOwner).updateAPY(comit_ONEMONTH, 13);
//   await comptroller.connect(contractOwner).updateAPY(comit_THREEMONTHS, 10);

//   console.log("updateAPR");
//   await comptroller.connect(contractOwner).updateAPY(comit_NONE, 15);
//   await comptroller.connect(contractOwner).updateAPY(comit_TWOWEEKS, 15);
//   await comptroller.connect(contractOwner).updateAPY(comit_ONEMONTH, 18);
//   await comptroller.connect(contractOwner).updateAPY(comit_THREEMONTHS, 18);


//   // await tokenList.connect(contractOwner).addMarketSupport(
//   //     utils.formatBytes32String("WONE"),
//   //     18,
//   //     "0x7466d7d0c21fa05f32f5a0fa27e12bdc06348ce2", // WONE already deployed harmony
//   //     1, 
//   //     { gasLimit: 250000 }
//   // )

//   // await tokenList.connect(contractOwner).addMarketSupport(
//   //     utils.formatBytes32String("WONE"),
//   //     18,
//   //     "0xD77B20D7301E6F16291221f50EB37589fdAB3720", // WONE   we deployed tWONE
//   //     1, 
//   //     { gasLimit: 800000 }
//   // )

//   await tokenList.connect(contractOwner).addMarketSupport(
//       utils.formatBytes32String("USDT.t"),
//       18,
//       '0x0Fcb7A59C1Af082ED077a972173cF49430EfD0dC',
//       // "0xaBB5e17e3B1e2fc1F7a5F28E336B8130158e4E2c", // USDT.t
//       1, 
//       { gasLimit: 800000 }
//   )

//   await tokenList.connect(contractOwner).addMarketSupport(
//       utils.formatBytes32String("USDC.t"),
//       18,
//       "0xe767f958a81Df36e76F96b03019eDfE3aAFd1CcD", // USDC.t
//       1, 
//       { gasLimit: 800000 }
//   ) 

//   await tokenList.connect(contractOwner).addMarketSupport(
//       utils.formatBytes32String("BTC.t"),
//       8,
//       "0xa48f5ab4cF6583029A981ccfAf0626EA37123a14", // BTC.t
//       1, 
//       { gasLimit: 800000 }
//   )
// }

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
  // const diamondAddress = await deployDiamond();
  // await deployOpenFacets(diamondAddress)
  // await addMarkets(diamondAddress)
  // const tokenList = await ethers.getContractAt("TokenList", diamondAddress);
  // const comptroller = await ethers.getContractAt("Comptroller", diamondAddress);
  // const deposit = await ethers.getContractAt("Deposit", diamondAddress);
  // const loan = await ethers.getContractAt("Loan", diamondAddress);
  // const loan1 = await ethers.getContractAt("Loan1", diamondAddress);
  // const reverser = await ethers.getContractAt("Reserve", diamondAddress);
  // const oracle = await ethers.getContractAt("OracleOpen", diamondAddress);
  // const accessregistry = await ethers.getContractAt("AccessRegistry", diamondAddress);
  // const diamond = await ethers.getContractAt("OpenDiamond", diamondAddress);
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
      timeout: 200000
    },
//     harmony: {
//       url: 'https://api.s0.b.hmny.io',
//       timeout: 200000,
//       accounts: [process.env.HARMONY_PRIVATE_KEY],
//       gas: 2100000, 
//       gasPrice: 8000000000
//     }

    },
    avax: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      timeout: 200000,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 43114
    }
  }
  solidity: {
    version: "0.8.1"
    settings: {
      optimizer: {
        enabled: true
        runs: 1000
      }
    }
  }
  mocha: {
    timeout: 200000
  }
  tenderly: {
    project: "Test"
    username: "dinh"
  }

