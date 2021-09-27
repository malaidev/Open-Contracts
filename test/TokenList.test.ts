import {expect, use} from 'chai';
import {Contract} from 'ethers';
import {deployContract, MockProvider, solidity} from 'ethereum-waffle';
import TokenList from './contracts/TokenList.sol';

use(solidity);

describe("TokenList", () => {
    let token: TokenList;
    beforeEach(async () => {
        
    });

    it("isTokenSupported : random symbol", async() => {
        expect(await token.isTokenSupported(223323423)).to.be.revertedWith("Token is not supported");
        
    });


});