// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "./IAccessRegistry.sol";
import "../mockup/IMockBep20.sol";

interface ITokenList {
    function isMarketSupported(bytes32  market_) external view returns (bool);
    function getMarketAddress(bytes32 market_) external view returns (address);
    function getMarketDecimal(bytes32 market_) external view returns (uint);
    function addMarketSupport(bytes32 _market,uint256 _decimals,address marketAddress_, uint _amount) external returns (bool);
    function removeMarketSupport(bytes32 market_) external returns(bool);
    function updateMarketSupport(bytes32 market_, uint256 decimals_,address tokenAddress_) external returns(bool);
    function connectMarket(bytes32 _market) external view returns (address addr);
    function quantifyAmount(bytes32 _market, uint _amount) external view;
    function minAmountCheck(bytes32 _market, uint _amount) external view;

    function isMarket2Supported(bytes32  market_) external view returns (bool);
    function getMarket2Address(bytes32 market_) external view returns (address);
    function getMarket2Decimal(bytes32 market_) external view returns (uint);
    function addMarket2Support(bytes32 market_,uint256 decimals_,address tokenAddress_) external returns (bool);
    function removeMarket2Support(bytes32 market_) external returns(bool);
    function updateMarket2Support(bytes32 market_, uint256 decimals_,address tokenAddress_) external returns(bool);
    
}