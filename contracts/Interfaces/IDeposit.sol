// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./ITokenList.sol";
import "./IComptroller.sol";
import "./IReserve.sol";

interface IDeposit {
	enum BALANCETYPE{DEPOSIT, YIELD, BOTH}
	function hasAccount(address account_) external view returns (bool);
    function savingsBalance(bytes32 market_, bytes32 commitment_, BALANCETYPE request_) external;
	function convertYield(bytes32 market_, bytes32 oldCommitment_, bytes32 newCommitment_) external;
    function createDeposit(bytes32 market_,bytes32 commitment_,uint256 amount_) external    returns (bool);
	function withdrawFunds(bytes32 market_, bytes32 commitment_, uint amount_, BALANCETYPE request_) external returns (bool);
	function convertDeposit() external;
	function hasYield(address account_, bytes32 market_, bytes32 commitment_) external view returns (bool);

}