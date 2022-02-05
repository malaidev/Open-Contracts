const { keccak256 } = require('@ethersproject/keccak256');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat')
const utils = require('ethers').utils
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function main() {
    const diamondAddress = await deployDiamond();
    await addMarkets(diamondAddress)
}

async function deployDiamond() {
    const accounts = await ethers.getSigners()
    const upgradeAdmin = accounts[0]

	const superAdmin = 0x72b5b8ca10202b2492d7537bf1f6abcda23a980f7acf51a1ec8a0ce96c7d7ca8;
    console.log(`upgradeAdmin ${upgradeAdmin.address}`)

    // deploy DiamondCutFacet
    const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
    let diamondCutFacet = await DiamondCutFacet.deploy()
    await diamondCutFacet.deployed()

    console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

    // deploy facets
    console.log('')
    console.log('Deploying facets')
    const FacetNames = ['DiamondLoupeFacet'
    ]
    const cut = []
    for (const FacetName of FacetNames) {
        const Facet = await ethers.getContractFactory(FacetName)
        const facet = await Facet.deploy()
        await facet.deployed()
        console.log(`${FacetName} deployed: ${facet.address}`)
        cut.push({
            facetAddress: facet.address,
            action: FacetCutAction.Add,
            functionSelectors: getSelectors(facet),
            facetId: 1
        })
    }

    const AccessRegistry = await ethers.getContractFactory("AccessRegistry");
    const accessRegistry = await AccessRegistry.deploy(upgradeAdmin.address)
    console.log("AccessRegistry deployed at ", accessRegistry.address)

    console.log("Begin deploying facets");
    const OpenNames = ['TokenList','Comptroller','Liquidator','Reserve','OracleOpen','Loan','LoanExt','Deposit']
    const opencut = []
    let facetId = 10;
    for (const FacetName of OpenNames) {
        const Facet = await ethers.getContractFactory(FacetName)
        const facet = await Facet.deploy()
        await facet.deployed()
        console.log(`${FacetName} deployed: ${facet.address}`)
        opencut.push({
            facetAddress: facet.address,
            action: FacetCutAction.Add,
            functionSelectors: getSelectors(facet),
            facetId :facetId
        })
        facetId ++;
    }

    console.log("Begin diamondcut facets");

    // deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
    // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
    const DiamondInit = await ethers.getContractFactory('DiamondInit')
    const diamondInit = await DiamondInit.deploy()
    await diamondInit.deployed()
    console.log('DiamondInit deployed:', diamondInit.address)

    // deploy Diamond
     const Diamond = await ethers.getContractFactory('OpenDiamond')
     const diamond = await Diamond.deploy(upgradeAdmin.address, diamondCutFacet.address)
     await diamond.deployed()
     console.log('Diamond deployed:', diamond.address)


    // upgrade diamond with facets
    console.log('')
    // console.log('Diamond Cut:', cut)
    const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
    let tx
    let receipt
    let args = []
    args.push(upgradeAdmin.address)
    args.push(opencut[3]["facetAddress"])
    args.push(accessRegistry.address)
    console.log(args)
    // call to init function
    let functionCall = diamondInit.interface.encodeFunctionData('init', args)
    console.log("functionCall is ", functionCall)
    tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
    console.log('Diamond cut tx: ', tx.hash)
    receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }

    console.log('Completed diamond cut')
    console.log("Begin diamondcut facets");

    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamond.address)

    tx = await diamondCutFacet.diamondCut(
        opencut, ethers.constants.AddressZero, '0x', { gasLimit: 8000000 }
    )
    receipt = await tx.wait()


    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }

    return diamond.address
}

// async function deployOpenFacets(diamondAddress) {
//     const accounts = await ethers.getSigners()
//     const upgradeAdmin = accounts[0]
//     console.log(" ==== Begin deployOpenFacets === ");
//     diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
//     diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

//     console.log("Begin deploying facets");
//     const OpenNames = ['TokenList','Comptroller','Liquidator','Reserve','OracleOpen','Loan','LoanExt','Deposit','AccessRegistry'
//     ]
//     const opencut = []
//     let facetId = 10;
//     for (const FacetName of OpenNames) {
//         const Facet = await ethers.getContractFactory(FacetName)
//         const facet = await Facet.deploy()
//         await facet.deployed()
//         console.log(`${FacetName} deployed: ${facet.address}`)
//         opencut.push({
//             facetAddress: facet.address,
//             action: FacetCutAction.Add,
//             functionSelectors: getSelectors(facet),
//             facetId :facetId
//         })
//         facetId ++;
//     }

//     console.log("Begin diamondcut facets");

//     tx = await diamondCutFacet.diamondCut(
//         opencut, ethers.constants.AddressZero, '0x', { gasLimit: 8000000 }
//     )
//     receipt = await tx.wait()


//     if (!receipt.status) {
//         throw Error(`Diamond upgrade failed: ${tx.hash}`)
//     }
// }

async function addMarkets(diamondAddress) {
    const accounts = await ethers.getSigners()
    const upgradeAdmin = accounts[0]

    const diamond = await ethers.getContractAt('OpenDiamond', diamondAddress)
    const tokenList = await ethers.getContractAt('TokenList', diamondAddress)
    const comptroller = await ethers.getContractAt('Comptroller', diamondAddress);

    const symbolWBNB = "0x57424e4200000000000000000000000000000000000000000000000000000000"; // WBNB
    const symbolUsdt = "0x555344542e740000000000000000000000000000000000000000000000000000"; // USDT.t
    const symbolUsdc = "0x555344432e740000000000000000000000000000000000000000000000000000"; // USDC.t
    const symbolBtc = "0x4254432e74000000000000000000000000000000000000000000000000000000"; // BTC.t
    const symbolSxp = "0x5358500000000000000000000000000000000000000000000000000000000000"; // SXP
    const symbolCAKE = "0x43414b4500000000000000000000000000000000000000000000000000000000"; // CAKE
    // const symbolEth = "0x4554480000000000000000000000000000000000000000000000000000000000";
   
    const comit_NONE = "0x636f6d69745f4e4f4e4500000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x636f6d69745f54574f5745454b53000000000000000000000000000000000000";
    const comit_ONEMONTH = "0x636f6d69745f4f4e454d4f4e5448000000000000000000000000000000000000";
    const comit_THREEMONTHS = "0x636f6d69745f54485245454d4f4e544853000000000000000000000000000000";

    // console.log("Add fairPrice addresses");
    // await diamond.addFairPriceAddress(symbolWBNB, '0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526');
    // await diamond.addFairPriceAddress(symbolUsdt, '0xEca2605f0BCF2BA5966372C99837b1F182d3D620');
    // await diamond.addFairPriceAddress(symbolUsdc, '0x90c069C4538adAc136E051052E14c1cD799C41B7');
    // await diamond.addFairPriceAddress(symbolBtc, '0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf');
    // await diamond.addFairPriceAddress(symbolEth, '0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7');
    // await diamond.addFairPriceAddress(symbolSxp, '0xE188A9875af525d25334d75F3327863B2b8cd0F1');
    // await diamond.addFairPriceAddress(symbolCAKE, '0xB6064eD41d4f67e353768aA239cA86f4F73665a1');

    console.log("setCommitment begin");
    await comptroller.connect(upgradeAdmin).setCommitment(comit_NONE);
    await comptroller.connect(upgradeAdmin).setCommitment(comit_TWOWEEKS);
    await comptroller.connect(upgradeAdmin).setCommitment(comit_ONEMONTH);
    await comptroller.connect(upgradeAdmin).setCommitment(comit_THREEMONTHS);
    console.log("setCommitment complete");
    
    console.log("updateAPY begin");
    await comptroller.connect(upgradeAdmin).updateAPY(comit_NONE, 780);
    await comptroller.connect(upgradeAdmin).updateAPY(comit_TWOWEEKS, 1000);
    await comptroller.connect(upgradeAdmin).updateAPY(comit_ONEMONTH, 1500);
    await comptroller.connect(upgradeAdmin).updateAPY(comit_THREEMONTHS, 1800);
    console.log("updateAPY complete");

    console.log("updateAPR begin");
    await comptroller.connect(upgradeAdmin).updateAPR(comit_NONE, 1800);
    await comptroller.connect(upgradeAdmin).updateAPR(comit_TWOWEEKS, 1800);
    await comptroller.connect(upgradeAdmin).updateAPR(comit_ONEMONTH, 1500);
    await comptroller.connect(upgradeAdmin).updateAPR(comit_THREEMONTHS, 1500);
    console.log("updateAPR complete");

    // console.log("Deploy test tokens");

    /// PREVIOUSLY COMMENTED
    // const admin_ = '0x14e7bBbDAc66753AcABcbf3DFDb780C6bD357d8E';
    const admin_ = upgradeAdmin.address;
    const Mockup = await ethers.getContractFactory('MockBep20')
    const tbtc = await Mockup.deploy("Bitcoin", "BTC.t", 8, admin_, 21000000)
    await tbtc.deployed()
    const tBtcAddress = tbtc.address;
    // console.log("tBTC deployed: ", tbtc.address)

    const tusdc = await Mockup.deploy("USD-Coin", "USDC.t", 18, admin_, 10000000000)
    await tusdc.deployed()
    const tUsdcAddress = tusdc.address;
    // console.log("tUSDC deployed: ", tusdc.address)

    const tusdt = await Mockup.deploy("USD-Tether", "USDT.t", 18, admin_, 10000000000)
    await tusdt.deployed()
    const tUsdtAddress = tusdt.address;
    // console.log("tUSDT deployed: ", tusdt.address)

    const tsxp = await Mockup.deploy("SXP", "SXP.t", 18, admin_, 1000000000)
    await tsxp.deployed()
    const tSxpAddress = tsxp.address;
    // console.log("tSxp deployed: ", tsxp.address)

    const tcake = await Mockup.deploy("CAKE", "CAKE.t", 18, admin_, 2700000000)
    await tcake.deployed()
    const tCakeAddress = tcake.address;
    // console.log("tCake deployed: ", tcake.address)

    const twbnb = await Mockup.deploy("WBNB", "WBNB.t", 18, admin_, 90000000)
    await twbnb.deployed()
    const tWBNBAddress = twbnb.address;
    // console.log("tWBNB deployed: ", twbnb.address)

    /// TILL HERE

    
    /// console.log(`Deploying test tokens...`);
    // const tBtcAddress = "0xe97C64CD9Ab8e8BcB077C59f6121381d129D3F27";
    // const tUsdcAddress = "0xC3F0414C9a849C52Eb508a7eeFEaDB4D65A3d944";
    // const tUsdtAddress = "0x3d2b1f363c79BaB4320DD0522239617aF31DaFde";
    // const tWBNBAddress = "0x426699E9B9ad3a1d37554965618d5f3cFC872eE4";
    // const tSxpAddress = "0xC60904295Bac181be6E9aFB3d6C36aa691516ec8";
    // const tCakeAddress = "0x6857EfAa30Bc52C75F76fE47EADd6C79C8B80AC4";

    console.log(`Test tokens deployed at
        BTC: ${tBtcAddress}
        USDC: ${tUsdcAddress}
        USDT: ${tUsdtAddress}
        WBNB: ${tWBNBAddress}
        SXP: ${tSxpAddress}
        CAKE: ${tCakeAddress}`
    );

        
    console.log("Add fairPrice addresses");
    await diamond.addFairPriceAddress(symbolWBNB,tWBNBAddress );
    await diamond.addFairPriceAddress(symbolUsdt, tUsdtAddress );
    await diamond.addFairPriceAddress(symbolUsdc, tUsdcAddress);
    await diamond.addFairPriceAddress(symbolBtc,tBtcAddress );
    await diamond.addFairPriceAddress(symbolSxp, tSxpAddress);
    await diamond.addFairPriceAddress(symbolCAKE,tCakeAddress);
    
    
    console.log("addMarket & minAmount");
    
    // 100 USDT [minAmount]
    // await tokenList.connect(upgradeAdmin).addMarketSupport(symbolUsdt,18,tUsdtAddress,1e20, { gasLimit: 800000 })
    
    const minUSDT = BigNumber.from('100000000000000000000'); // 100 USDT, or 100 USDC
    const minUSDC = BigNumber.from('100000000000000000000'); // 100 USDT, or 100 USDC
    const minBTC = BigNumber.from('1000000'); // 0.1 BTC
    const minBNB = BigNumber.from('250000000000000000'); // 0.25

    await tokenList.connect(upgradeAdmin).addMarketSupport(symbolUsdt,18,tUsdtAddress, minUSDT, { gasLimit: 800000 })
    console.log(`tUSDT added ${minUSDT}`);

    // 100 USDC [minAmount]
    await tokenList.connect(upgradeAdmin).addMarketSupport(symbolUsdc,18,tUsdcAddress, minUSDC, { gasLimit: 800000 }) 
    console.log(`tUSDC added ${minUSDC}`);

    // 0.1 BTC [minAmount]
    // await tokenList.connect(upgradeAdmin).addMarketSupport(symbolBtc,8,tBtcAddress, 10000000, { gasLimit: 800000 })
    await tokenList.connect(upgradeAdmin).addMarketSupport(symbolBtc,8,tBtcAddress, minBTC, { gasLimit: 800000 })
    console.log(`tBTC added ${minBTC}`);

    // 0.25 BNB
    // await tokenList.connect(upgradeAdmin).addMarketSupport(symbolWBNB,18,tWBNBAddress,25e16,{ gasLimit: 800000 })
    await tokenList.connect(upgradeAdmin).addMarketSupport(symbolWBNB,18,tWBNBAddress, minBNB,{ gasLimit: 800000 })
    console.log(`twBNB added ${minBNB}`);
    
    console.log("primary markets added");



    console.log("adding secondary markets");
    // await tokenList.connect(upgradeAdmin).addMarket2Support(symbolUsdt,18,tUsdtAddress, // USDT.t{ gasLimit: 800000 })
    // await tokenList.connect(upgradeAdmin).addMarket2Support(symbolUsdc,18,tUsdcAddress, // USDC.t{ gasLimit: 800000 }) 
    // await tokenList.connect(upgradeAdmin).addMarket2Support(symbolBtc,8,tBtcAddress, // BTC.t{ gasLimit: 800000 })
    // await tokenList.connect(upgradeAdmin).addMarket2Support(symbolWBNB,18,tWBNBAddress,{ gasLimit: 800000 })
    await tokenList.connect(upgradeAdmin).addMarket2Support(symbolSxp,8,tSxpAddress,{ gasLimit: 800000 })
    await tokenList.connect(upgradeAdmin).addMarket2Support(symbolCAKE,18,tCakeAddress,{ gasLimit: 800000 })


    console.log(`Secondary markets
        SXP: ${symbolSxp}: ${tSxpAddress}
        CAKE: ${symbolCAKE}: ${tCakeAddress}`
    );
    console.log("secondary markets added");

    /*const Faucet = await ethers.getContractFactory("Faucet");
    const faucet = await Faucet.deploy(tUsdtAddress,tUsdcAddress,tBtcAddress,tWBNBAddress)
    console.log("Faucet deployed at ", faucet.address)

    await tusdt.transfer(faucet.address,"3000000000000000000000000000")
    console.log("3000000000 Usdt transfered to faucet. Token being :", tUsdtAddress)

    await tusdc.transfer(faucet.address,"3000000000000000000000000000")
    console.log("3000000000 tusdc transfered to faucet. Token being :", tUsdcAddress)

    await tbtc.transfer(faucet.address,630000000000000)
    console.log("6300000 tbtc transfered to faucet. Token being :", tBtcAddress)

    await twbnb.transfer(faucet.address,"1200000000000000000000000")
    console.log("1200000 twbnb transfered to faucet. Token being :", tWBNBAddress)
    console.log(await twbnb.balanceOf(faucet.address));*/

    return {tBtcAddress, tUsdtAddress, tUsdcAddress, tSxpAddress, tCakeAddress, tWBNBAddress}
    
}

if (require.main === module) {
    main()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
}
exports.deployDiamond = deployDiamond
// exports.deployOpenFacets = deployOpenFacets

exports.addMarkets = addMarkets



// async function addMarkets(diamondAddress) {
//     const accounts = await ethers.getSigners()
//     const upgradeAdmin = accounts[0]
    

//     const diamond = await ethers.getContractAt('OpenDiamond', diamondAddress)
//     const tokenList = await ethers.getContractAt('TokenList', diamondAddress)
//     const comptroller = await ethers.getContractAt('Comptroller', diamondAddress);

//     const symbolWBNB = "0x57424e4200000000000000000000000000000000000000000000000000000000"; // WBNB
//     const symbolUsdt = "0x555344542e740000000000000000000000000000000000000000000000000000"; // USDT.t
//     const symbolUsdc = "0x555344432e740000000000000000000000000000000000000000000000000000"; // USDC.t
//     const symbolBtc = "0x4254432e74000000000000000000000000000000000000000000000000000000"; // BTC.t
//     const symbolEth = "0x4554480000000000000000000000000000000000000000000000000000000000";
//     const symbolSxp = "0x5358500000000000000000000000000000000000000000000000000000000000"; // SXP
//     const symbolCAKE = "0x43414b4500000000000000000000000000000000000000000000000000000000"; // CAKE
   
//     const comit_NONE = "0x636f6d69745f4e4f4e4500000000000000000000000000000000000000000000";
//     const comit_TWOWEEKS = "0x636f6d69745f54574f5745454b53000000000000000000000000000000000000";
//     const comit_ONEMONTH = "0x636f6d69745f4f4e454d4f4e5448000000000000000000000000000000000000";
//     const comit_THREEMONTHS = "0x636f6d69745f54485245454d4f4e544853000000000000000000000000000000";

//     console.log("Add fairPrice addresses");
//     await diamond.addFairPriceAddress(symbolWBNB, '0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526');
//     await diamond.addFairPriceAddress(symbolUsdt, '0xEca2605f0BCF2BA5966372C99837b1F182d3D620');
//     await diamond.addFairPriceAddress(symbolUsdc, '0x90c069C4538adAc136E051052E14c1cD799C41B7');
//     await diamond.addFairPriceAddress(symbolBtc, '0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf');
//     await diamond.addFairPriceAddress(symbolEth, '0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7');
//     await diamond.addFairPriceAddress(symbolSxp, '0xE188A9875af525d25334d75F3327863B2b8cd0F1');
//     await diamond.addFairPriceAddress(symbolCAKE, '0xB6064eD41d4f67e353768aA239cA86f4F73665a1');

//     console.log("setCommitment begin");
//     await comptroller.connect(upgradeAdmin).setCommitment(comit_NONE);
//     await comptroller.connect(upgradeAdmin).setCommitment(comit_TWOWEEKS);
//     await comptroller.connect(upgradeAdmin).setCommitment(comit_ONEMONTH);
//     await comptroller.connect(upgradeAdmin).setCommitment(comit_THREEMONTHS);
    
//     console.log("updateAPY begin");
//     await comptroller.connect(upgradeAdmin).updateAPY(comit_NONE, 780);
//     await comptroller.connect(upgradeAdmin).updateAPY(comit_TWOWEEKS, 1000);
//     await comptroller.connect(upgradeAdmin).updateAPY(comit_ONEMONTH, 1500);
//     await comptroller.connect(upgradeAdmin).updateAPY(comit_THREEMONTHS, 1800);

//     console.log("updateAPR");
//     await comptroller.connect(upgradeAdmin).updateAPR(comit_NONE, 1800);
//     await comptroller.connect(upgradeAdmin).updateAPR(comit_TWOWEEKS, 1800);
//     await comptroller.connect(upgradeAdmin).updateAPR(comit_ONEMONTH, 1500);
//     await comptroller.connect(upgradeAdmin).updateAPR(comit_THREEMONTHS, 1500);


//     console.log("Deploy test tokens");
//     // const admin_ = '0x14e7bBbDAc66753AcABcbf3DFDb780C6bD357d8E';
//     // const admin_ = '0x14e7bBbDAc66753AcABcbf3DFDb780C6bD357d8E';
//     const admin_ = upgradeAdmin.address;
//     // const tBTC = await ethers.getContractFactory('tBTC')
//     // const tbtc = await tBTC.deploy(admin_)
// //     // await tbtc.deployed()
//     const tBtcAddress = "0xe97C64CD9Ab8e8BcB077C59f6121381d129D3F27";
//     console.log("tBTC used: ", tBtcAddress)

// //     // const tUSDC = await ethers.getContractFactory('tUSDC')
// //     // const tusdc = await tUSDC.deploy(admin_)
// //     // await tusdc.deployed()
//     const tUsdcAddress = "0xC3F0414C9a849C52Eb508a7eeFEaDB4D65A3d944";
//     console.log("tUSDC used: ", tUsdcAddress)

// //     // const tUSDT = await ethers.getContractFactory('tUSDT')
// //     // const tusdt = await tUSDT.deploy(admin_)
// //     // await tusdt.deployed()
//     const tUsdtAddress = "0x3d2b1f363c79BaB4320DD0522239617aF31DaFde";
//     console.log("tUSDT used: ", tUsdtAddress)

// //     // const tSxp = await ethers.getContractFactory('tSxp')
// //     // const tsxp = await tSxp.deploy(admin_)
// //     // await tsxp.deployed()
//     const tSxpAddress = "0xC60904295Bac181be6E9aFB3d6C36aa691516ec8";
//     console.log("tSxp used: ", tSxpAddress)

// //     // const tCake = await ethers.getContractFactory('tCake')
// //     // const tcake = await tCake.deploy(admin_)
// //     // await tcake.deployed()
//     const tCakeAddress = "0x6857EfAa30Bc52C75F76fE47EADd6C79C8B80AC4";
//     console.log("tCake used: ", tCakeAddress)

//     const tWBNBAddress = "0x426699E9B9ad3a1d37554965618d5f3cFC872eE4";
//     console.log("tWBNB used: ", tWBNBAddress)

     

//     console.log("addMarket");
//     await tokenList.connect(upgradeAdmin).addMarketSupport//         symbolUsdt//         18//         tUsdtAddress, // USDT.//         100, { gasLimit: 800000 //     )
//     console.log("tusdt added");


//     await tokenList.connect(upgradeAdmin).addMarketSupport//         symbolUsdc//         18//         tUsdcAddress, // USDC.//         100, { gasLimit: 800000 //     ) 
//     console.log("tusdc added");

//     await tokenList.connect(upgradeAdmin).addMarketSupport//         symbolBtc//         8//         tBtcAddress, // BTC.//         1, { gasLimit: 800000 //     )
//     console.log("tbtc added");//     await tokenList.connect(upgradeAdmin).addMarketSupport//         symbolWBNB//         18,'0x359A0A7DffEa6B95a436d5E558d20EC8972EbC4B'//         1,{ gasLimit: 800000 //     )
//     console.log("wbnb added");
//     console.log("addMarket2")//     await tokenList.connect(upgradeAdmin).addMarket2Support//         symbolSxp//         8//         tSxpAddress,{ gasLimit: 800000 //     )//     await tokenList.connect(upgradeAdmin).addMarket2Support//         symbolCAKE//         18//         tCakeAddress,{ gasLimit: 800000 //     )

//     return {tBtcAddress, tUsdtAddress, tUsdcAddress, tSxpAddress, tCakeAddress}
// }

