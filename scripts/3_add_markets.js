const { ethers } = require('hardhat')
const utils = require('ethers').utils


async function test(){
    console.log("Bytes32 for comit_NONE is ", utils.formatBytes32String("comit_NONE"))
    console.log("Bytes32 for comit_TWOWEEKS is ", utils.formatBytes32String("comit_TWOWEEKS"))
    console.log("Bytes32 for comit_ONEMONTH is ", utils.formatBytes32String("comit_ONEMONTH"))
    console.log("Bytes32 for comit_THREEMONTHS is ", utils.formatBytes32String("comit_THREEMONTHS"))
    console.log("Bytes32 for WONE is ", utils.formatBytes32String("WONE"))
    console.log("Bytes32 for USDT.t is ", utils.formatBytes32String("USDT.t"))
    console.log("Bytes32 for USDC.t is ", utils.formatBytes32String("USDC.t"))
    console.log("Bytes32 for BTC.t is ", utils.formatBytes32String("BTC.t"))
    console.log("Bytes32 for ETH is ", utils.formatBytes32String("ETH"))
    console.log("Bytes32 for SXP is ", utils.formatBytes32String("SXP"))
    console.log("Bytes32 for CAKE is ", utils.formatBytes32String("CAKE"))
    console.log("Bytes32 for WBNB is ", utils.formatBytes32String("WBNB"))

}

async function addMarkets() {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]
    const diamondAddress = "0xC63D5215B393743Cf255E0FF2260a4c17b23dD01"

    const tokenList = await ethers.getContractAt('TokenList', diamondAddress)
    const comptroller = await ethers.getContractAt('Comptroller', diamondAddress);
   
    const comit_TWOWEEKS = utils.formatBytes32String("comit_TWOWEEKS")
    const comit_NONE = utils.formatBytes32String("comit_NONE")
    const comit_ONEMONTH = utils.formatBytes32String("comit_ONEMONTH")
    const comit_THREEMONTHS = utils.formatBytes32String("comit_THREEMONTHS")

    console.log("setCommitment begin");
    await comptroller.connect(contractOwner).setCommitment(comit_NONE);
    await comptroller.connect(contractOwner).setCommitment(comit_TWOWEEKS);
    await comptroller.connect(contractOwner).setCommitment(comit_ONEMONTH);
    await comptroller.connect(contractOwner).setCommitment(comit_THREEMONTHS);
    
    console.log("updateAPY begin");
    await comptroller.connect(contractOwner).updateAPY(comit_NONE, 6);
    await comptroller.connect(contractOwner).updateAPY(comit_TWOWEEKS, 16);
    await comptroller.connect(contractOwner).updateAPY(comit_ONEMONTH, 13);
    await comptroller.connect(contractOwner).updateAPY(comit_THREEMONTHS, 10);

    console.log("updateAPR");
    await comptroller.connect(contractOwner).updateAPY(comit_NONE, 15);
    await comptroller.connect(contractOwner).updateAPY(comit_TWOWEEKS, 15);
    await comptroller.connect(contractOwner).updateAPY(comit_ONEMONTH, 18);
    await comptroller.connect(contractOwner).updateAPY(comit_THREEMONTHS, 18);


    // await tokenList.connect(contractOwner).addMarketSupport(
    //     utils.formatBytes32String("WONE"),
    //     18,
    //     "0x7466d7d0c21fa05f32f5a0fa27e12bdc06348ce2", // WONE already deployed harmony
    //     1, 
    //     { gasLimit: 250000 }
    // )

    // await tokenList.connect(contractOwner).addMarketSupport(
    //     utils.formatBytes32String("WONE"),
    //     18,
    //     "0xD77B20D7301E6F16291221f50EB37589fdAB3720", // WONE   we deployed tWONE
    //     1, 
    //     { gasLimit: 800000 }
    // )

    await tokenList.connect(contractOwner).addMarketSupport(
        utils.formatBytes32String("USDT.t"),
        18,
        '0xe3367b181D051f756135c91c27DA23D958FE2708',
        // "0xaBB5e17e3B1e2fc1F7a5F28E336B8130158e4E2c", // USDT.t
        1, 
        { gasLimit: 800000 }
    )

    await tokenList.connect(contractOwner).addMarketSupport(
        utils.formatBytes32String("USDC.t"),
        18,
        "0x80a73792dB00175a889f5A6E03ED8E925b2cF06b", // USDC.t
        1, 
        { gasLimit: 800000 }
    ) 

    await tokenList.connect(contractOwner).addMarketSupport(
        utils.formatBytes32String("BTC.t"),
        8,
        "0x2f92c5A5FCcb195a924f09aDCF430419450c3C34", // BTC.t
        1, 
        { gasLimit: 800000 }
    )
}

// async function mintToDeposit() {
//     const deposit = await ethers.getContractAt('Deposit', "0xA662457999811886CA10c5c6b9b4C9578ef83264")
//     const tusdt = await ethers.getContractAt('tUSDT', '0x8e4eb87Eb892aD8fBCf9a2d32fAc267F17D977dE')
//     await tusdt.transfer(deposit.address, 1000000000000000)
//     console.log('Deposit balance is ', await tusdt.balanceOf(deposit.address))
// }

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    test()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
    
}