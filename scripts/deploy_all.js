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

    const tokenList = await ethers.getContractAt('TokenList', diamondAddress)
    const comptroller = await ethers.getContractAt('Comptroller', diamondAddress);

    const symbolUsdt = "0x555344542e740000000000000000000000000000000000000000000000000000"; // USDT.t
    const symbolUsdc = "0x555344432e740000000000000000000000000000000000000000000000000000"; // USDC.t
    const symbolBtc = "0x4254432e74000000000000000000000000000000000000000000000000000000"; // BTC.t
   
    const comit_NONE = "0x636f6d69745f4e4f4e4500000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x636f6d69745f54574f5745454b53000000000000000000000000000000000000";
    const comit_ONEMONTH = "0x636f6d69745f4f4e454d4f4e5448000000000000000000000000000000000000";
    const comit_THREEMONTHS = "0x636f6d69745f54485245454d4f4e544853000000000000000000000000000000";

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

    console.log("addMarket");
    await tokenList.connect(contractOwner).addMarketSupport(
        symbolUsdt,
        18,
        '0x0fcb7a59c1af082ed077a972173cf49430efd0dc', // USDT.t
        1, 
        { gasLimit: 800000 }
    )

    await tokenList.connect(contractOwner).addMarketSupport(
        symbolUsdc,
        18,
        "0xe767f958a81df36e76f96b03019edfe3aafd1ccd", // USDC.t
        1, 
        { gasLimit: 800000 }
    ) 

    await tokenList.connect(contractOwner).addMarketSupport(
        symbolBtc,
        8,
        "0xa48f5ab4cf6583029a981ccfaf0626ea37123a14", // BTC.t
        1, 
        { gasLimit: 800000 }
    )

    console.log("addMarket2");
    await tokenList.connect(contractOwner).addMarket2Support(
        symbolUsdt,
        18,
        '0x0fcb7a59c1af082ed077a972173cf49430efd0dc', // USDT.t
        { gasLimit: 800000 }
    )

    await tokenList.connect(contractOwner).addMarket2Support(
        symbolUsdc,
        18,
        "0xe767f958a81df36e76f96b03019edfe3aafd1ccd", // USDC.t
        { gasLimit: 800000 }
    ) 

    await tokenList.connect(contractOwner).addMarket2Support(
        symbolBtc,
        8,
        "0xa48f5ab4cf6583029a981ccfaf0626ea37123a14", // BTC.t
        { gasLimit: 800000 }
    )

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
