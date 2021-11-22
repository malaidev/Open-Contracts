require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

 require("@nomiclabs/hardhat-waffle");
 require('hardhat-contract-sizer');
 require("@nomiclabs/hardhat-etherscan");
//  require("solidity-coverage");
 require('dotenv').config()

module.exports = {
  defaultNetwork: "harmony",
  networks: {
    hardhat: {
      // forking: {
      //   url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      //   blockNumber: 13327183,
      // }
    },
    kovan: {
      accounts: {
        mnemonic: process.env.MNEMONIC
      },
      url: "https://kovan.infura.io/v3/99b8947af7e14278ae235bb21eb81f53",
      chainId: 42,
      timeout: 2000000
    },
    bsctestnet: {
      accounts: {
        mnemonic: process.env.MNEMONIC
      },
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      timeout: 2000000
    },
    harmony: {
      url: 'https://api.s0.b.hmny.io',
      timeout: 2000000,
      accounts: [process.env.HARMONY_PRIVATE_KEY],
      gas: 2100000, 
      gasPrice: 8000000000
    }
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  mocha: {
    timeout: 2000000
  },
  
};
