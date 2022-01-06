const { keccak256 } = require('@ethersproject/keccak256')
const { utils, ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function main() {
    const diamondAddress = await deployDiamond();
    await deployOpenFacets(diamondAddress)
    await addMarkets(diamondAddress)
}

async function deployDiamond() {
    const accounts = await ethers.getSigners()
    const contractOwner = await accounts[0]
    console.log(`contractOwner ${contractOwner.address}`)

    // deploy DiamondCutFacet
    const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
    const diamondCutFacet = await DiamondCutFacet.deploy()
    await diamondCutFacet.deployed()

    console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

    // deploy Diamond
    const Diamond = await ethers.getContractFactory('OpenDiamond')
    const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
    await diamond.deployed()
    console.log('Diamond deployed:', diamond.address)

    // deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
    // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
    const DiamondInit = await ethers.getContractFactory('DiamondInit')
    const diamondInit = await DiamondInit.deploy()
    await diamondInit.deployed()
    console.log('DiamondInit deployed:', diamondInit.address)

    // deploy facets
    console.log('')
    console.log('Deploying facets')
    const FacetNames = [
        'DiamondLoupeFacet'
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

    // upgrade diamond with facets
    console.log('')
    // console.log('Diamond Cut:', cut)
    const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
    let tx
    let receipt
    // call to init function
    let functionCall = diamondInit.interface.encodeFunctionData('init')
    tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
    console.log('Diamond cut tx: ', tx.hash)
    receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }

    console.log('Completed diamond cut')

    return diamond.address
}

async function deployOpenFacets(diamondAddress) {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]
    console.log(" ==== Begin deployOpenFacets === ");
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)

    console.log("Begin deploying facets");
    const OpenNames = [
        'TokenList',
        'Comptroller',
        'Liquidator',
        'Reserve',
        'OracleOpen',
        'Loan',
        'Loan1',
        'Deposit',
        'AccessRegistry'
    ]
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

    tx = await diamondCutFacet.diamondCut(
        opencut, ethers.constants.AddressZero, '0x', { gasLimit: 8000000 }
    )
    receipt = await tx.wait()


    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
}

async function addMarkets(diamondAddress) {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]
    

    const diamond = await ethers.getContractAt('OpenDiamond', diamondAddress)
    const tokenList = await ethers.getContractAt('TokenList', diamondAddress)
    const comptroller = await ethers.getContractAt('Comptroller', diamondAddress);

    const symbolWBNB = "0x57424e4200000000000000000000000000000000000000000000000000000000"; // WBNB
    const symbolUsdt = "0x555344542e740000000000000000000000000000000000000000000000000000"; // USDT.t
    const symbolUsdc = "0x555344432e740000000000000000000000000000000000000000000000000000"; // USDC.t
    const symbolBtc = "0x4254432e74000000000000000000000000000000000000000000000000000000"; // BTC.t
    const symbolEth = "0x4554480000000000000000000000000000000000000000000000000000000000";
    const symbolSxp = "0x5358500000000000000000000000000000000000000000000000000000000000"; // SXP
    const symbolCAKE = "0x43414b4500000000000000000000000000000000000000000000000000000000"; // CAKE
   
    const comit_NONE = "0x636f6d69745f4e4f4e4500000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x636f6d69745f54574f5745454b53000000000000000000000000000000000000";
    const comit_ONEMONTH = "0x636f6d69745f4f4e454d4f4e5448000000000000000000000000000000000000";
    const comit_THREEMONTHS = "0x636f6d69745f54485245454d4f4e544853000000000000000000000000000000";

    console.log("Add fairPrice addresses");
    await diamond.addFairPriceAddress(symbolWBNB, '0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526');
    await diamond.addFairPriceAddress(symbolUsdt, '0xEca2605f0BCF2BA5966372C99837b1F182d3D620');
    await diamond.addFairPriceAddress(symbolUsdc, '0x90c069C4538adAc136E051052E14c1cD799C41B7');
    await diamond.addFairPriceAddress(symbolBtc, '0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf');
    await diamond.addFairPriceAddress(symbolEth, '0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7');
    await diamond.addFairPriceAddress(symbolSxp, '0xE188A9875af525d25334d75F3327863B2b8cd0F1');
    await diamond.addFairPriceAddress(symbolCAKE, '0xB6064eD41d4f67e353768aA239cA86f4F73665a1');

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
    await comptroller.connect(contractOwner).updateAPR(comit_NONE, 15);
    await comptroller.connect(contractOwner).updateAPR(comit_TWOWEEKS, 15);
    await comptroller.connect(contractOwner).updateAPR(comit_ONEMONTH, 18);
    await comptroller.connect(contractOwner).updateAPR(comit_THREEMONTHS, 18);


    console.log("Deploy test tokens");
    const tBTC = await ethers.getContractFactory('tBTC')
    
    // const admin_ = '0x14e7bBbDAc66753AcABcbf3DFDb780C6bD357d8E';
    const admin_ = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
    const tbtc = await tBTC.deploy(admin_)
    await tbtc.deployed()
    const tBtcAddress = tbtc.address
    console.log("tBTC deployed: ", tbtc.address)
    console.log("50000000 tBTC mint to hashstack deployer");

    const tUSDC = await ethers.getContractFactory('tUSDC')
    const tusdc = await tUSDC.deploy(admin_)
    await tusdc.deployed()
    const tUsdcAddress = tusdc.address
    console.log("tUSDC deployed: ", tusdc.address)
    console.log("500000000000 tUSDC mint to hashstack deployer");

    const tUSDT = await ethers.getContractFactory('tUSDT')
    const tusdt = await tUSDT.deploy(admin_)
    await tusdt.deployed()
    const tUsdtAddress = tusdt.address
    console.log("tUSDT deployed: ", tusdt.address)
    console.log("500000000000 tUSDT mint to hashstack deployer");

    console.log("addMarket");
    await tokenList.connect(contractOwner).addMarketSupport(
        symbolUsdt,
        18,
        tusdt.address, // USDT.t
        1, 
        { gasLimit: 800000 }
    )

    await tokenList.connect(contractOwner).addMarketSupport(
        symbolUsdc,
        18,
        tusdc.address, // USDC.t
        1, 
        { gasLimit: 800000 }
    ) 
    console.log("tusdc added");

    await tokenList.connect(contractOwner).addMarketSupport(
        symbolBtc,
        8,
        tbtc.address, // BTC.t
        1, 
        { gasLimit: 800000 }
    )
    console.log("tbtc added");

    await tokenList.connect(contractOwner).addMarketSupport(
        symbolWBNB,
        18,
        '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd',
        1,
        { gasLimit: 800000 }
    )
    
    console.log("addMarket2");
    await tokenList.connect(contractOwner).addMarket2Support(
        symbolUsdt,
        18,
        tusdt.address, // USDT.t
        { gasLimit: 800000 }
    )

    await tokenList.connect(contractOwner).addMarket2Support(
        symbolUsdc,
        18,
        tusdc.address, // USDC.t
        { gasLimit: 800000 }
    ) 

    await tokenList.connect(contractOwner).addMarket2Support(
        symbolBtc,
        8,
        tbtc.address, // BTC.t
        { gasLimit: 800000 }
    )

    await tokenList.connect(contractOwner).addMarket2Support(
        symbolSxp,
        8,
        '0x833d9fd415df4ae8c71f411d5a819b6f78ebb134',
        { gasLimit: 800000 }
    )
    const tSxpAddress = '0x833d9fd415df4ae8c71f411d5a819b6f78ebb134'

    await tokenList.connect(contractOwner).addMarket2Support(
        symbolWBNB,
        18,
        '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd',
        { gasLimit: 800000 }
    )

    await tokenList.connect(contractOwner).addMarket2Support(
        symbolCAKE,
        18,
        '0xB6064eD41d4f67e353768aA239cA86f4F73665a1',
        { gasLimit: 800000 }
    )
    const tCakeAddress = '0xB6064eD41d4f67e353768aA239cA86f4F73665a1'

    return {tBtcAddress, tUsdtAddress, tUsdcAddress, tSxpAddress, tCakeAddress}
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
exports.deployOpenFacets = deployOpenFacets
exports.addMarkets = addMarkets