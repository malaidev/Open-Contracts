const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function updateLoanAddTest() {
    
    const diamond = await ethers.getContractAt('OpenDiamond', '0x06e0deC6B1C4e426bD754a910ebd4DA044d814da')
    const diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', '0x9d7b85944aBd8D4eEFD3054916961b26b6E42fA0')
    const diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', '0xC67B833c848fD95958fD2fe40C7cDe503af260fe')
    const loan = await ethers.getContractAt('Loan', diamond.address)

    console.log("Diamond address is ", diamond.address)
    console.log("diamondCutFacet address is ", diamondCutFacet.address)
    console.log("diamondLoupeFacet address is ", diamondLoupeFacet.address)
    console.log("loan address is ", loan.address)
    const selectors = getSelectors(loan).get(['testFunc()'])
    tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: tokenList.address,
          action: FacetCutAction.Replace,
          functionSelectors: selectors
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
    //   result = await diamondLoupeFacet.facetFunctionSelectors(loan)
    //   assert.sameMembers(result, getSelectors(Loan))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
updateLoanAddTest()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  