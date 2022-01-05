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

async function testCallUpgrade() {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]
  const diamond = await ethers.getContractAt('OpenDiamond', '0x2290FD0130DbC36dbdA32Cfa24415f0fEBD7E7Fe')
    const diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', '0x2290FD0130DbC36dbdA32Cfa24415f0fEBD7E7Fe')
    const diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', '0x2290FD0130DbC36dbdA32Cfa24415f0fEBD7E7Fe')
    const deposit = await ethers.getContractAt('Deposit', '0x2290FD0130DbC36dbdA32Cfa24415f0fEBD7E7Fe')

    const retUp = await deposit.upgradeTestAccount(contractOwner.address);
  // const retUp = await deposit.upgradeTest(contractOwner.address);
  console.log("upgradeTest ret = ", retUp);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
updateDepositAddFunc()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  