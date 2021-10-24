const {expect, use}  = require( 'chai');
const {deployContract, MockProvider, solidity} = require ('ethereum-waffle');

use(solidity);

describe("OracleOpen Contract", async () => {
    let oracle;
    const [wallet, account1] = new MockProvider().getWallets();
    const OracleOpen  = require("../build/contracts/OracleOpen.json");

    before(async () => {
        oracle = await deployContract(wallet, OracleOpen, [wallet.address]);
    })

    it("Check Deployement", async() => {
        expect(oracle.address).to.not.equal("0x" + "0".repeat(40));
        console.log("OracleOpen deployed at: ", oracle.address);
    });

    // === getLatesPrice() can be tested after deplyoing to testnet === 

    // it("getLatestPrice", async () => {
    //     const price = await oracle.getLatestPrice();
    //     console.log("Price is ", price);
    // });
});