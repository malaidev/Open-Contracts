// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./ITokenList.sol";
import "./IComptroller.sol";
import "./IDeposit.sol";
import "./IReserve.sol";
import "./IOracleOpen.sol";
import "./ILiquidator.sol";
import "../util/IBEP20.sol";

interface ILoan {
    enum CONSIDER {YES, NO}
    function loanRequest(bytes32 market_,bytes32 commitment_,uint256 loanAmount_,bytes32 collateralMarket_,uint256 collateralAmount_) external returns(bool success);
    function addCollateral(bytes32 loanMarket_, bytes32 loanCommitment_, bytes32 collateralMarket_, bytes32 collateralAmount_) external returns (bool);
    function swapLoan(bytes32 loanMarket_, bytes32 commitment_, bytes32 swapMarket_) external returns (bool success);
    function permissibleWithdrawal() external returns (bool);
    function switchLoanType() external;
    function repayLoan(CONSIDER repayMarket, CONSIDER swapMarket, bytes32 loanMarket_, bytes32 commitment_ ,  uint amount_) external returns (bool success);
    function liquidation(
    bytes32 market_,
    bytes32 commitment_,
    bytes32 amount_
  ) external returns (bool);
   function collateralRelease(uint256 loanId, uint256 amount_) external;
}