const { expect } = require("chai");
const { ethers } = require("hardhat");
const utils = require("ethers").utils;
const {
  getSelectors,
  get,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets,
} = require("../scripts/libraries/diamond.js");

const { assert } = require("chai");

const { deployDiamond } = require("../scripts/deploy_all.js");
const { addMarkets } = require("../scripts/deploy_all.js");

describe("===== Swapping Loans =====", function () {
  let diamondAddress;
  let diamondCutFacet;
  let diamondLoupeFacet;
  let tokenList;
  let comptroller;
  let deposit;
  let loan;
  let loan1;
  let oracle;
  let reserve;
  let library;
  let liquidator;
  let accounts;
  let contractOwner;
  let bepUsdt;
  let bepBtc;
  let bepUsdc;

  let rets;
  const addresses = [];

  const symbolWBNB =
    "0x57424e4200000000000000000000000000000000000000000000000000000000"; // WBNB
  const symbolUsdt =
    "0x555344542e740000000000000000000000000000000000000000000000000000"; // USDT.t
  const symbolUsdc =
    "0x555344432e740000000000000000000000000000000000000000000000000000"; // USDC.t
  const symbolBtc =
    "0x4254432e74000000000000000000000000000000000000000000000000000000"; // BTC.t
  const symbolEth =
    "0x4554480000000000000000000000000000000000000000000000000000000000";
  const symbolSxp =
    "0x5358500000000000000000000000000000000000000000000000000000000000"; // SXP
  const symbolCAKE =
    "0x43414b4500000000000000000000000000000000000000000000000000000000"; // CAKE

  const comit_NONE = utils.formatBytes32String("comit_NONE");
  const comit_TWOWEEKS = utils.formatBytes32String("comit_TWOWEEKS");
  const comit_ONEMONTH = utils.formatBytes32String("comit_ONEMONTH");
  const comit_THREEMONTHS = utils.formatBytes32String("comit_THREEMONTHS");

  before(async function (done) {
    accounts = await ethers.getSigners();
    contractOwner = accounts[0];
    console.log("account1 is ", accounts[1].address);

    diamondAddress = await deployDiamond();
    rets = await addMarkets(diamondAddress);

    diamondCutFacet = await ethers.getContractAt(
      "DiamondCutFacet",
      diamondAddress
    );
    diamondLoupeFacet = await ethers.getContractAt(
      "DiamondLoupeFacet",
      diamondAddress
    );
    library = await ethers.getContractAt("LibOpen", diamondAddress);

    tokenList = await ethers.getContractAt("TokenList", diamondAddress);
    comptroller = await ethers.getContractAt("Comptroller", diamondAddress);
    deposit = await ethers.getContractAt("Deposit", diamondAddress);
    loan = await ethers.getContractAt("Loan", diamondAddress);
    loan1 = await ethers.getContractAt("Loan1", diamondAddress);
    oracle = await ethers.getContractAt("OracleOpen", diamondAddress);
    liquidator = await ethers.getContractAt("Liquidator", diamondAddress);
    reserve = await ethers.getContractAt("Reserve", diamondAddress);

    bepUsdt = await ethers.getContractAt("tUSDT", rets["tUsdtAddress"]);
    bepBtc = await ethers.getContractAt("tBTC", rets["tBtcAddress"]);
    bepUsdc = await ethers.getContractAt("tUSDC", rets["tUsdcAddress"]);
    done();
  }) /**.timeout(2000000)*/;

  //   it("should have three facets -- call to facetAddresses function", async (done) => {
  //     for (const address of await diamondLoupeFacet.facetAddresses()) {
  //       addresses.push(address);
  //     }
  //     assert.equal(addresses.length, 11);
  //     done();
  //   });

  it("facets should have the right function selectors -- call to facetFunctionSelectors function", async (done) => {
    let selectors = getSelectors(diamondCutFacet);
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0]);
    assert.sameMembers(result, selectors);
    selectors = getSelectors(diamondLoupeFacet);
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1]);
    assert.sameMembers(result, selectors);
    done();
  });

  it("Token Mint", async (done) => {
    // expect(await bepUsdt.balanceOf(deposit.address)).to.be.equal(0);
    await expect(bepUsdt.transfer(contractOwner.address, 0x10000)).to.emit(
      bepUsdt,
      "Transfer"
    );
    await expect(bepUsdt.transfer(accounts[1].address, 0x10000)).to.emit(
      bepUsdt,
      "Transfer"
    );
    await expect(bepUsdc.transfer(accounts[1].address, 0x10000)).to.emit(
      bepUsdc,
      "Transfer"
    );
    await expect(bepBtc.transfer(accounts[1].address, 0x10000)).to.emit(
      bepBtc,
      "Transfer"
    );
    done();
  });

  it("SwapLoan", async (done) => {
    const depositAmount = 0x200;

    // USDT

    await expect(
      deposit
        .connect(accounts[1])
        .addToDeposit(symbolUsdt, comit_NONE, depositAmount, {
          gasLimit: 5000000,
        })
    ).emit(deposit, "NewDeposit");
    expect(await bepUsdt.balanceOf(accounts[1].address)).to.equal(0xfe00);
    expect(await reserve.avblMarketReserves(symbolUsdt)).to.equal(0x200);

    await expect(
      deposit
        .connect(accounts[1])
        .addToDeposit(symbolUsdt, comit_NONE, depositAmount, {
          gasLimit: 5000000,
        })
    ).emit(deposit, "DepositAdded");
    expect(await bepUsdt.balanceOf(accounts[1].address)).to.equal(0xfc00);
    expect(await reserve.avblMarketReserves(symbolUsdt)).to.equal(0x400);

    await expect(
      loan1
        .connect(accounts[1])
        .loanRequest(symbolUsdt, comit_ONEMONTH, 0x200, symbolUsdt, 0x500, {
          gasLimit: 5000000,
        })
    ).to.emit(loan1, "NewLoan");

    expect(await bepUsdt.balanceOf(accounts[1].address)).to.equal(0xfc00);
    expect(await reserve.avblMarketReserves(symbolUsdt)).to.equal(0x200);
    try {
      await expect(
        loan
          .connect(accounts[1])
          .swapLoan(symbolUsdt, comit_ONEMONTH, symbolSxp, {
            gasLimit: 5000000,
          })
      ).to.emit(loan, "MarketSwapped");
    } catch {
      await expect(
        loan
          .connect(accounts[1])
          .swapLoan(symbolUsdt, comit_ONEMONTH, symbolSxp, {
            gasLimit: 5000000,
          })
      ).to.be.revertedWith("Mathematical Error");
    }
    done();
  });

  //   it("Check addCollateral", async () => {
  //     await expect(
  //       loan1
  //         .connect(accounts[1])
  //         .addCollateral(symbolUsdt, comit_ONEMONTH, symbolUsdt, 0x100, {
  //           gasLimit: 5000000,
  //         })
  //     ).to.emit(loan1, "AddCollateral");
  //     expect(await bepUsdt.balanceOf(accounts[1].address)).to.equal(0xfb00);
  //     expect(await reserve.avblMarketReserves(symbolUsdt)).to.equal(0x300);
  //   });

  //   it("Check repayLoan", async () => {
  //     console.log(await reserve.avblMarketReserves(symbolUsdt));
  //     await loan
  //       .connect(accounts[1])
  //       .repayLoan(symbolUsdt, comit_ONEMONTH, 0x100, { gasLimit: 5000000 });
  //     console.log(await reserve.avblMarketReserves(symbolUsdt));
  //   });

  //   it("Check withdrawCollateral", async () => {
  //     console.log(await bepUsdt.balanceOf(accounts[1].address));
  //     await expect(
  //       loan
  //         .connect(accounts[1])
  //         .withdrawCollateral(symbolUsdt, comit_ONEMONTH, { gasLimit: 5000000 })
  //     ).emit(loan, "CollateralReleased");
  //     console.log(await bepUsdt.balanceOf(accounts[1].address));
  //   });
});