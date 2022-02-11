const { expect } = require("chai");
// const { ethers } = require("hardhat");
const ethers = require('ethers');
const utils = require('ethers').utils
require('dotenv').config()
const Web3 = require('web3');
const {
    getSelectors,
    get,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
    } = require('../scripts/libraries/diamond.js')
  
const { assert } = require('chai')

const {deployDiamond}= require('../scripts/deploy_all.js')
const {deployOpenFacets}= require('../scripts/deploy_all.js')
const {addMarkets}= require('../scripts/deploy_all.js')


// const ethers = require('ethers');
const addresses = {
  WETH: '0xc778417e063141139fce010982780140aa0cd5ab',
  router: '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
  recipient: '0x84c86da0a5c4f3Be99695f37811B8b154a6aD241',
  swapper: '0x3D0Fc2b7A17d61915bcCA984B9eAA087C5486d18',
  usdt: '0x0Fcb7A59C1Af082ED077a972173cF49430EfD0dC',
  usdc: '0xe767f958a81Df36e76F96b03019eDfE3aAFd1CcD'
}
const mnemonic = process.env.MNEMONIC;
const provider = new ethers.providers.WebSocketProvider('https://eth-ropsten.alchemyapi.io/v2/fxrejtNAKunh--Iym4w8DI4mpb4pEEbA');
const wallet = ethers.Wallet.fromMnemonic(mnemonic);
const account = wallet.connect(provider);

const router = new ethers.Contract(
    addresses.router,
    [
      'function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts)',
      'function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)',
      'function swapExactETHForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)'
    ],
    account
);

const auguSwapper = new ethers.Contract(
    addresses.swapper, 
    [
        'function simpleSwap(address fromToken,address toToken,uint256 fromAmount,uint256 toAmount,uint256 expectedAmount,address[] memory callees,bytes memory exchangeData,uint256[] memory startIndexes,uint256[] memory values,address payable beneficiary,string memory referrer,bool useReduxToken) external payable returns (uint256 receivedAmount)',
        'function swapOnUniswap(uint256 amountIn,uint256 amountOutMin,address[] calldata path,uint8 referrer) external payable',
        'function getTokenTransferProxy() external view returns (address)',
    ],
    account
);

const usdtToken = new ethers.Contract(
    addresses.usdt, 
    [
        'function approve(address spender, uint256 amount) external returns (bool)',
        'function allowance(address owner, address spender) external view returns (uint256)',
        'function transfer(address recipient, uint256 amount) external returns (bool)'
    ],
    account
);

const usdcToken = new ethers.Contract(
    addresses.usdc, 
    [
        'function approve(address spender, uint256 amount) external returns (bool)'
    ],
    account
);

async function UniSwap(){
    const ethAmount = ethers.utils.parseEther("0.03");
    const usdtAmount = ethers.utils.parseUnits("500", 18);
    const btcAmount = ethers.utils.parseUnits("0.2", 8);
    console.log("Begin ParaSend");
    // const tx = await router.swapExactETHForTokens(
    const tx = await router.swapExactTokensForTokens(
        usdtAmount,
      0,
      ['0x0Fcb7A59C1Af082ED077a972173cF49430EfD0dC', '0xa48f5ab4cF6583029A981ccfAf0626EA37123a14'],
      addresses.recipient, 
      Date.now() + 1000 * 60 * 10, //10 minutes,
      {
          'gasLimit': 300000,
          'gasPrice': ethers.utils.parseUnits('185', 'gwei'),
      }
    );
    console.log("https://ropsten.etherscan.io/tx/" + tx.hash);
    const receipt = await tx.wait(); 
    console.log('Transaction receipt');
    console.log(receipt);
}

async function ParaSwap() {
    const usdtAmount = ethers.utils.parseUnits("10", 18);
    const expAmount = ethers.utils.parseUnits('9', 18);
    await usdtToken.approve('0xDb28dc14E5Eb60559844F6f900d23Dce35FcaE33', ethers.constants.MaxUint256);

    const tx = await auguSwapper.simpleSwap(
        '0x0Fcb7A59C1Af082ED077a972173cF49430EfD0dC',
        '0xe767f958a81Df36e76F96b03019eDfE3aAFd1CcD',
        usdtAmount,
        expAmount,
        usdtAmount,
        [addresses.swapper, addresses.router],
        "0x1234",
        [0, 100, 296],
        [0,0],
        addresses.recipient,
        "",
        false,
        {
            'gasLimit': 300000,
            'gasPrice': ethers.utils.parseUnits('185', 'gwei'),
        }
    );

    console.log("https://ropsten.etherscan.io/tx/" + tx.hash);
    const receipt = await tx.wait(); 
    console.log('Transaction receipt');
    console.log(receipt);
}

async function directSwap() {
    const usdtAmount = ethers.utils.parseUnits("100", 18);
    const btcAmount = ethers.utils.parseUnits("0.001", 8);
    // console.log(usdtAmount, expAmount);
    // '000000000000000000'
    await usdtToken.approve('0xDb28dc14E5Eb60559844F6f900d23Dce35FcaE33', ethers.constants.MaxUint256);
    console.log("approved");
    const tx = await auguSwapper.swapOnUniswap(
        '100', 1,
        ['0x0Fcb7A59C1Af082ED077a972173cF49430EfD0dC', '0xe767f958a81Df36e76F96b03019eDfE3aAFd1CcD'],
        1,
        {
            'gasLimit': 300000,
            'gasPrice': 385000000000,
        }
    );
    console.log("https://ropsten.etherscan.io/tx/" + tx.hash);
    const receipt = await tx.wait(); 
    console.log('Transaction receipt');
    console.log(receipt);
}
describe("===== Paraswap Test =====", function () {
    
    before(async function () {
        console.log("wallet address is ", wallet.address)
    })

    // it("Uniswap", async () => {
    //     await UniSwap();
    // })

    it("DirectSwap", async () => {
        await directSwap();
        // await directSwap();
    })

})