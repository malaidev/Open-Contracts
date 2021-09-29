// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
interface IDeposit {
    function createDeposit(bytes32 market_,bytes32 commitment_,uint256 amount_) external    returns (bool);
    function savingsBalance() external;
	function withdrawFunds() external;
	function convertDeposit() external;
	function convertYield() external;
}