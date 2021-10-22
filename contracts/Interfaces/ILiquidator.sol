// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "./IAugustusSwapper.sol";
// import "./ITokenList.sol";

interface ILiquidator {
    function swap(bytes32 _fromToken, bytes32 _toToken, uint256 _fromAmount, uint8 sType) external payable returns (uint256 receivedAmount);
}