const { utils, ethers } = require('hardhat')

async function deploytTest() {
    // const accounts = await ethers.getSigners()

    const Test = await ethers.getContractFactory('Test')
    const test = await Test.deploy()
    await test.deployed()
    console.log("Test deployed: ", test.address)

}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    deploytTest()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
}
