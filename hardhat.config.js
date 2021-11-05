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
  networks: {
    testnet: {
      accounts: {
        mnemonic: process.env.MNEMONIC
      },
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      timeout: 2000000
    },
    harmony: {
      url: `https://api.s0.b.hmny.io`,
      accounts: [process.env.HARMONY_PRIVATE_KEY]
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
  }
};
