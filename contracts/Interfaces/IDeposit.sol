// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "./ITokenList.sol";
// import "./IComptroller.sol";
// import "./IReserve.sol";

interface IDeposit {
	enum SAVINGSTYPE{DEPOSIT, YIELD, BOTH}
	function hasAccount(address account_) external view returns (bool);
    function savingsBalance(bytes32 _market, bytes32 _commitment) external returns (uint);
	function convertYield(bytes32 _market, bytes32 _commitment) external returns (bool success);
	function hasYield(bytes32 _market, bytes32 _commitment) external view returns (bool);
	function avblReserves(bytes32 _market) external view returns (uint);
	function utilisedReserves(bytes32 _market) external view returns(uint);
	function hasDeposit(bytes32 _market, bytes32 _commitment) external view;
	function createDeposit(bytes32 _market, bytes32 _commitment, uint256 _amount) external;
	function withdrawDeposit (bytes32 _market, bytes32 _commitment, uint _amount, SAVINGSTYPE _request) external returns (bool success);
	function addToDeposit(bytes32 _market, bytes32 _commitment, uint _amount) external returns(bool success);
	function pause() external;
	function unpause() external;
}