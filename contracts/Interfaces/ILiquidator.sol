// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "./IAugustusSwapper.sol";
// import "./ITokenList.sol";

interface ILiquidator {
    function transferAnyBEP20(address _token,address _recipient, uint256 _value) external returns(bool);
    function swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 mode) external payable returns (uint256 receivedAmount);
    function pause() external;
    function unpause() external;
}