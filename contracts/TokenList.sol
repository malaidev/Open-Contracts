// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./AccessRegistry.sol";
import "./util/Address.sol";

contract TokenList {

  bytes32 adminTokenList;
  
  bytes32[] markets; // collection of token markets. Provides a list of easy to retrieve token list.
  
  struct MarketData {
    bytes32 market;
    address tokenAddress;
    uint256 decimals;
    uint256 chainId;
  }

  mapping(bytes32 => bool) public tokenSupportCheck;
  mapping(bytes32 => uint256) marketIndex;
  mapping(bytes32 => MarketData) public indTokenDetails;

  event TokenSupportAdded(
    bytes32 indexed _market,
    uint256 _decimals,
    address indexed _tokenAddress,
    uint256 indexed _timestamp
  );
  event MarketRemoved(
    bytes32 indexed _market,
    uint256 _decimals,
    address indexed _tokenAddress,
    uint256 indexed _timestamp
  );

  function isTokenSupported(bytes32 _market) external view returns (bool) {
    _isTokenSupported(_market);
    return true;
  }

  function _isTokenSupported(bytes32 _market) internal view {
    require(tokenSupportCheck[_market] == true, "Token is not supported");
  }

  // ADD A NEW TOKEN SUPPORT
  function addTokenSupport(
    bytes32 _market,
    uint256 _decimals,
    address _tokenAddress
  ) external returns (bool) {
    _isTokenSupported(_market);
    _addTokenSupport(_market, _decimals, _tokenAddress);

    emit TokenSupportAdded(_market, _decimals, _tokenAddress, block.timestamp);

    return bool(true);
  }

  function _addTokenSupport(
    bytes32 _market,
    uint256 _decimals,
    address _tokenAddress
  ) internal {
    TokenDetails memory TokenDetails = indTokenDetails[_market];

    TokenDetails.market = _market;
    TokenDetails.tokenAddress = _tokenAddress;
    TokenDetails.decimals = _decimals;

    markets.push(_market);
    tokenSupportCheck[_market] = true;
    marketIndex[_market] = markets.length - 1;
  }

  function removeTokenSupport(bytes32 market_) external returns (bool) {
    _removeTokenSupport(market_);
    return bool(true);
  }

  function _removeTokenSupport(bytes32 _market) internal {
    TokenDetails memory TokenDetails = indTokenDetails[_market];
    tokenSupportCheck[_market] = false;

    delete TokenDetails;

    if (marketIndex[_market] >= markets.length) return;

    bytes32 lastmarket = markets[markets.length - 1];

    if (marketIndex[lastmarket] != marketIndex[_market]) {
      marketIndex[lastmarket] = marketIndex[_market];
      markets[marketIndex[_market]] = lastmarket;
    }
    markets.pop();
    delete marketIndex[_market];
  }

  function updateTokenSupport(
    bytes32 _market,
    uint256 _decimals,
    address _tokenAddress
  ) external returns (bool) {
    _updateTokenSupport(_market, _decimals, _tokenAddress);
    return bool(true);
  }

  function _updateTokenSupport(
    bytes32 _market,
    uint256 _decimals,
    address _tokenAddress
  ) internal {
    TokenDetails storage TokenDetails = indTokenDetails[_market];

    TokenDetails.market = _market;
    TokenDetails.tokenAddress = _tokenAddress;
    TokenDetails.decimals = _decimals;

    tokenSupportCheck[_market] = true;
  }
}
