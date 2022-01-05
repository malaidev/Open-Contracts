const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function updateLoanAddTest() {
    
    const diamond = await ethers.getContractAt('OpenDiamond', '0x2290FD0130DbC36dbdA32Cfa24415f0fEBD7E7Fe')
    const diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', '0xd7c2ABefe9a8997664E088eB6f5E269d3f2342aC')
    const diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', '0x604523e6D2e860a7Da13a46166b8F2040128e885')
    const deposit = await ethers.getContractAt('Deposit', diamond.address)

    console.log("Diamond address is ", diamond.address)
    console.log("diamondCutFacet address is ", diamondCutFacet.address)
    console.log("diamondLoupeFacet address is ", diamondLoupeFacet.address)
    const selectors = getSelectors(deposit).get(['upgradeTest(address _account)'])
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

    receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    // result = await diamondLoupeFacet.facetFunctionSelectors(deposit)
    // assert.sameMembers(result, getSelectors(Loan))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
updateLoanAddTest()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  