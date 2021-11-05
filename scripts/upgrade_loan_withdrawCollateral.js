const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function updateLoanFacet() {
    console.log("=== Upgradibility check ===")
    
    const Loan = await ethers.getContractFactory('Loan')
    const diamond = await ethers.getContractAt('OpenDiamond', '0x09F73B51a33454567269B970BE44F4A07f3d1b97')
    const diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', '0x09F73B51a33454567269B970BE44F4A07f3d1b97')
    const diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', '0x09F73B51a33454567269B970BE44F4A07f3d1b97')
    const loan = await ethers.getContractAt('Loan', diamond.address)

    console.log("Diamond address is ", diamond.address)
    console.log("diamondCutFacet address is ", diamondCutFacet.address)
    console.log("diamondLoupeFacet address is ", diamondLoupeFacet.address)
    console.log("loan address is ", loan.address)
    const selectors = getSelectors(loan).get(['withdrawCollateral(bytes32 _market, bytes32 _commitment)'])
    tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: loan.address,
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
updateLoanFacet()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
