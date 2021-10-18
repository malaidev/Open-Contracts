// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "./IAccessRegistry.sol";
import "../util/IBEP20.sol";

interface ITokenList {
    function isMarketSupported(bytes32  market_) external view returns (bool);
    function getMarketTokenAddress(bytes32 market_) external view returns (address);
    function getMarketDecimal(bytes32 market_) external view returns (uint);
    function addTokenSupport(bytes32 market_,uint256 decimals_,address tokenAddress_) external returns (bool);
    function removeTokenSupport(bytes32 market_) external returns(bool);
    function updateTokenSupport(bytes32 market_, uint256 decimals_,address tokenAddress_) external returns(bool);

    function isToken2Supported(bytes32  market_) external view returns (bool);
    function getMarketToken2Address(bytes32 market_) external view returns (address);
    function getMarket2Decimal(bytes32 market_) external view returns (uint);
    function addToken2Support(bytes32 market_,uint256 decimals_,address tokenAddress_) external returns (bool);
    function removeToken2Support(bytes32 market_) external returns(bool);
    function updateToken2Support(bytes32 market_, uint256 decimals_,address tokenAddress_) external returns(bool);
    
    function connectMarket(bytes32 market_, IBEP20 token_) external view;
    function quantifyAmount(bytes32 _market, uint _amount) external view;

}