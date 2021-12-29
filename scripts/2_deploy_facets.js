const { keccak256 } = require('@ethersproject/keccak256')
const { utils, ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function deployOpenFacets() {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]
    console.log(" ==== Begin deployOpenFacets === ");
    const diamondAddress = "0xC63D5215B393743Cf255E0FF2260a4c17b23dD01"
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

if (require.main === module) {
    deployOpenFacets()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
}

exports.deployFacets = deployOpenFacets