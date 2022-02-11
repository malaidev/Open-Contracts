const { utils, ethers } = require('hardhat')

async function deploytBTC() {
    // const accounts = await ethers.getSigners()

    const tBTC = await ethers.getContractFactory('tBTC')
    // const name_ = 'Bitcoin';
    // const symbol_ = 'BTC.t';
    // const decimals_ = 8;
    // const cappedSupply_ = 2100000000000000;
    const admin_ = '0x14e7bBbDAc66753AcABcbf3DFDb780C6bD357d8E'; // ERC20 address
//     const admin_ = '0x39eA12dA7D4991D96572FD8addb8E397C113401B';
    // const admin_ = 'one1znnmh0dvve6n4j4uhu7lmduqc67n2lvw256rhn'; // Harmony equivalent
    const tbtc = await tBTC.deploy(admin_)
    await tbtc.deployed()
    console.log("tBTC deployed: ", tbtc.address)
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    deploytBTC()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
}
