const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function updateOracleFacet() {
    console.log("=== Upgrade OracleOpen ===")
    
    const diamond = await ethers.getContractAt('OpenDiamond', '0x09F73B51a33454567269B970BE44F4A07f3d1b97')
    const diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', '0x09F73B51a33454567269B970BE44F4A07f3d1b97')
    const diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', '0x09F73B51a33454567269B970BE44F4A07f3d1b97')
    const oracle = await ethers.getContractAt('OracleOpen', diamond.address)

    console.log("Diamond address is ", diamond.address)
    console.log("diamondCutFacet address is ", diamondCutFacet.address)
    console.log("diamondLoupeFacet address is ", diamondLoupeFacet.address)
    console.log("oracle address is ", oracle.address)
    const selectors = getSelectors(oracle).get(['getLatestPrice(address _addrMarket)'])
    tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: oracle.address,
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
updateOracleFacet()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });