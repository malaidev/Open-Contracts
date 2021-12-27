const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
    getSelectors,
    get,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
    } = require('../scripts/libraries/diamond.js')
  
const { assert } = require('chai')
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
describe("DiamondTest", function () {
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let tx
    let receipt
    let result
    const addresses = []
    const symbol = "0x74657374737472696e6700000000000000000000000000000000000000000000"
    const symbol2 = "0x25B29858A2529819179178979ABD797997979AD97987979AC7979797979797DF"
    //NONE, TWOWEEKS, ONEMONTH, THREEMONTHS
    const comit_NONE = "0x94557374737472696e6700000000000000000000000000000000000000000000";
    const comit_TWOWEEKS = "0x78629858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_ONEMONTH = "0x54567858A2529819179178879ABD797997979AD97987979AC7979797979797DF";
    const comit_THREEMONTHS = "0x78639858A2529819179178879ABD797997979AD97987979AC7979797979797DF";

    before(async function () {
        diamondAddress = await deployDiamond()
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    })

    it('should have three facets -- call to facetAddresses function', async () => {
        for (const address of await diamondLoupeFacet.facetAddresses()) {
            addresses.push(address)
        }
        assert.equal(addresses.length, 2)
    })

    it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
        let selectors = getSelectors(diamondCutFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
        assert.sameMembers(result, selectors)
        selectors = getSelectors(diamondLoupeFacet)
        result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
        assert.sameMembers(result, selectors)
    })

    it('add TokenList functions', async () => {
      const TokenList = await ethers.getContractFactory('TokenList')
      const tokenList = await TokenList.deploy()
      await tokenList.deployed()
      addresses.push(tokenList.address)
      console.log("TokenList funcs count = ", getSelectors(tokenList).length)
      const selectors = getSelectors(tokenList)
      console.log("TokenList add funcs count = ", selectors.length)
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: tokenList.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors,
          facetId: 10
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(tokenList.address)
      assert.sameMembers(result, selectors)
    })
    
    it('function call to TokenList', async () => {
      const tokenList = await ethers.getContractAt('TokenList', diamondAddress)
      await expect(tokenList.isMarket2Supported(symbol)).to.be.revertedWith("Secondary Token is not supported");

    })

    it('remove some TokenList functions', async () => {
      const tokenList = await ethers.getContractAt('TokenList', diamondAddress)
      const functionsToKeep = ['isMarket2Supported(bytes32)', 
        'getMarketDecimal(bytes32)',
      ]
      const selectors = getSelectors(tokenList).remove(functionsToKeep)
      tx = await diamondCutFacet.diamondCut(
          [{
          facetAddress: ethers.constants.AddressZero,
          action: FacetCutAction.Remove,
          functionSelectors: selectors,
          facetId: 10
          }],
          ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
          throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2])
      assert.sameMembers(result, getSelectors(tokenList).get(functionsToKeep))

      await expect(tokenList.isMarket2Supported(symbol)).to.be.revertedWith("Secondary Token is not supported");

    })

    it('Add Comptroller functions', async () => {
      const Comptroller = await ethers.getContractFactory('Comptroller')
      const comptroller = await Comptroller.deploy()
      await comptroller.deployed()
      addresses.push(comptroller.address)
      console.log("Comptroller func count", getSelectors(comptroller).length)
      const selectors = getSelectors(comptroller)
      console.log("Comptroller add funcs count = ", selectors.length)
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: comptroller.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors,
          facetId: 11
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 8000000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(comptroller.address)
      assert.sameMembers(result, selectors)
    })

    

    it('function call to Comptroller', async () => {
      const accounts = await ethers.getSigners()
      const contractOwner = await accounts[0]
      const comptroller = await ethers.getContractAt('Comptroller', diamondAddress)
      await comptroller.connect(contractOwner).updateAPY(comit_NONE, 2, {gasLimit: 250000});
        expect(await comptroller.getAPY(comit_NONE)).to.be.equal(2);
    })

    it('Liquidator functions', async () => {
      const Liquidator = await ethers.getContractFactory('Liquidator')
      const liquidator = await Liquidator.deploy()
      await liquidator.deployed()
      addresses.push(liquidator.address)
      const selectors = getSelectors(liquidator)
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: liquidator.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors,
          facetId: 12
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(liquidator.address)
      assert.sameMembers(result, selectors)
    })

    it('add Reserve functions', async () => {
      const Reserve = await ethers.getContractFactory('Reserve')
      const reserve = await Reserve.deploy()
      await reserve.deployed()
      addresses.push(reserve.address)
      const selectors = getSelectors(reserve)
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: reserve.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors,
          facetId: 12
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(reserve.address)
      
      assert.sameMembers(result, selectors)
    })

    it('add OracleOpen functions', async () => {
      const OracleOpen = await ethers.getContractFactory('OracleOpen')
      const oracle = await OracleOpen.deploy()
      await oracle.deployed()
      addresses.push(oracle.address)
      const selectors = getSelectors(oracle)
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: oracle.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors,
          facetId: 13
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 8000000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(oracle.address)
      
      assert.sameMembers(result, selectors)
    })

    // it('add Loan functions', async () => {
    //   const Loan = await ethers.getContractFactory('Loan')
    //   const loan = await Loan.deploy()
    //   await loan.deployed()
    //   addresses.push(loan.address)
    //   const selectors = getSelectors(loan)
    //   tx = await diamondCutFacet.diamondCut(
    //     [{
    //       facetAddress: loan.address,
    //       action: FacetCutAction.Add,
    //       functionSelectors: selectors
    //     }],
    //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    //   receipt = await tx.wait()
    //   if (!receipt.status) {
    //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
    //   }
    //   result = await diamondLoupeFacet.facetFunctionSelectors(loan.address)
      
    //   assert.sameMembers(result, selectors)
    // })

    // it('add Loan1 functions', async () => {
    //   const Loan1 = await ethers.getContractFactory('Loan1')
    //   const loan1 = await Loan1.deploy()
    //   await loan1.deployed()
    //   addresses.push(loan1.address)
    //   const selectors = getSelectors(loan1)
    //   tx = await diamondCutFacet.diamondCut(
    //     [{
    //       facetAddress: loan1.address,
    //       action: FacetCutAction.Add,
    //       functionSelectors: selectors
    //     }],
    //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    //   receipt = await tx.wait()
    //   if (!receipt.status) {
    //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
    //   }
    //   result = await diamondLoupeFacet.facetFunctionSelectors(loan1.address)
      
    //   assert.sameMembers(result, selectors)
    // })

    // it('add Deposit functions', async () => {
    //   const Deposit = await ethers.getContractFactory('Deposit')
    //   const deposit = await Deposit.deploy()
    //   await deposit.deployed()
    //   addresses.push(deposit.address)
    //   const selectors = getSelectors(deposit)
    //   tx = await diamondCutFacet.diamondCut(
    //     [{
    //       facetAddress: deposit.address,
    //       action: FacetCutAction.Add,
    //       functionSelectors: selectors
    //     }],
    //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    //   receipt = await tx.wait()
    //   if (!receipt.status) {
    //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
    //   }
    //   result = await diamondLoupeFacet.facetFunctionSelectors(deposit.address)
      
    //   assert.sameMembers(result, selectors)
    // })

    // it('add AccessRegistry functions', async () => {
    //   const accounts = await ethers.getSigners()
    //   const contractOwner = accounts[0]
    //   const AccessRegistry = await ethers.getContractFactory('AccessRegistry')
    //   const accessR = await AccessRegistry.deploy()
    //   await accessR.deployed()
    //   addresses.push(accessR.address)
    //   const selectors = getSelectors(accessR)
    //   tx = await diamondCutFacet.diamondCut(
    //     [{
    //       facetAddress: accessR.address,
    //       action: FacetCutAction.Add,
    //       functionSelectors: selectors
    //     }],
    //     ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    //   receipt = await tx.wait()
    //   if (!receipt.status) {
    //     throw Error(`Diamond upgrade failed: ${tx.hash}`)
    //   }
    //   result = await diamondLoupeFacet.facetFunctionSelectors(accessR.address)
      
    //   assert.sameMembers(result, selectors)
    // })
});
