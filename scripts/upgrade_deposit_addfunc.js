const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function updateDepositAddFunc() {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

    let diamond = await ethers.getContractAt('OpenDiamond', '0x2290FD0130DbC36dbdA32Cfa24415f0fEBD7E7Fe')
    let diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', '0x2290FD0130DbC36dbdA32Cfa24415f0fEBD7E7Fe')
    let diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', '0x2290FD0130DbC36dbdA32Cfa24415f0fEBD7E7Fe')
    let Deposit = await ethers.getContractFactory('Deposit')
    let deposit = await Deposit.deploy()
    await deposit.deployed()

    console.log("New Deposit deployed at ", deposit.address)

    console.log("Diamond address is ", diamond.address)
    console.log("diamondCutFacet address is ", diamondCutFacet.address)
    console.log("diamondLoupeFacet address is ", diamondLoupeFacet.address)
    const selectors = getSelectors(deposit).get(['upgradeTestAccount(address)'])

    tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: deposit.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors,
          facetId:17
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
    // result = await diamondLoupeFacet.facetFunctionSelectors(deposit)
    // assert.sameMembers(result, getSelectors(Loan))

}
async function updateOracleAddFunc() {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

    let diamond = await ethers.getContractAt('OpenDiamond', '0x123De8ceb0C3a2582bd7Bcf7d885187CdE016067')
    let diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', '0x123De8ceb0C3a2582bd7Bcf7d885187CdE016067')
    let diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', '0x123De8ceb0C3a2582bd7Bcf7d885187CdE016067')
    let OracleOpen = await ethers.getContractFactory('OracleOpen')
    let oracle = await OracleOpen.deploy()
    await oracle.deployed()

    console.log("New Oracle deployed at ", oracle.address)

    console.log("Diamond address is ", diamond.address)
    console.log("diamondCutFacet address is ", diamondCutFacet.address)
    console.log("diamondLoupeFacet address is ", diamondLoupeFacet.address)
    const selectors = getSelectors(oracle).get(['setFairPrice(uint, uint, bytes32, uint)'])

    tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: oracle.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors,
          facetId:17
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
    // result = await diamondLoupeFacet.facetFunctionSelectors(deposit)
    // assert.sameMembers(result, getSelectors(Loan))

}

async function testCallUpgrade() {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]
  const diamond = await ethers.getContractAt('OpenDiamond', '0x123De8ceb0C3a2582bd7Bcf7d885187CdE016067')
    const diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', '0x123De8ceb0C3a2582bd7Bcf7d885187CdE016067')
    const diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', '0x123De8ceb0C3a2582bd7Bcf7d885187CdE016067')
    const oracle = await ethers.getContractAt('OracleOpen', '0x123De8ceb0C3a2582bd7Bcf7d885187CdE016067')

    const retUp = await oracle.setFairPrice(12,32,"0x57424e4200000000000000000000000000000000000000000000000000000000",2);
  // const retUp = await deposit.upgradeTest(contractOwner.address);
  console.log("upgradeTest ret = ", retUp);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
testCallUpgrade()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  