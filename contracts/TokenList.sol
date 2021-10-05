// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./AccessRegistry.sol";
import "./util/IBEP20.sol";
import "./util/Address.sol";

contract TokenList {

  IBEP20 token;

  bytes32 adminTokenList;
  address adminTokenListAddress;

  bool isReentrant = false;
  
  struct MarketData {
    bytes32 market;
    address tokenAddress;
    uint256 decimals;
    uint256 chainId;
  }

  bytes32[] markets;
  mapping (bytes32 => bool) public tokenSupportCheck;
  mapping (bytes32=>uint256) marketIndex;
  mapping (bytes32 => MarketData) public indMarketData;

//   MarketData internal rmMarketData;

  event TokenSupportAdded(bytes32 indexed market_,uint256 decimals_,address indexed tokenAddress_,uint256 indexed _timestamp);
  event TokenSupportUpdated(bytes32 indexed market_,uint256 decimals_,address indexed tokenAddress_,uint256 indexed _timestamp);
  event TokenSupportRemoved(bytes32 indexed market_, uint256 indexed _timestamp);


  function isTokenSupported(bytes32  market_) external view returns (bool)	{
		_isTokenSupported(market_);
		return true;
	}

	function _isTokenSupported(bytes32  market_) internal view {
		require(tokenSupportCheck[market_] == true, "Hey, Token is not supported");
	}
  
  // ADD A NEW TOKEN SUPPORT
  function addTokenSupport(bytes32 market_,uint256 decimals_,address tokenAddress_) external authTokenList() returns (bool) {
    _addTokenSupport(market_, decimals_, tokenAddress_);

    emit TokenSupportAdded(market_,decimals_,tokenAddress_,block.timestamp);
    return bool(true);
  }
  function _addTokenSupport( bytes32 market_,uint256 decimals_,address tokenAddress_) internal {
    MarketData storage marketData = indMarketData[market_];
    
    marketData.market = market_;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = decimals_;
    
    markets.push(market_);
    tokenSupportCheck[market_] = true;
    marketIndex[market_] = markets.length-1;
  }

  function removeTokenSupport(bytes32 market_) external authTokenList() returns(bool) {
    _removeTokenSupport(market_);
    emit TokenSupportRemoved(market_, block.timestamp);
    return bool(true);
  }

  function _removeTokenSupport(bytes32 market_) internal {


    tokenSupportCheck[market_] = false;

    delete indMarketData[market_];
    
    if (marketIndex[market_] >= markets.length) return;

    bytes32 lastmarket = markets[markets.length - 1];

    if (marketIndex[lastmarket] != marketIndex[market_]) {
      marketIndex[lastmarket] = marketIndex[market_];
      markets[marketIndex[market_]] = lastmarket;
    }
    markets.pop();
    delete marketIndex[market_];
  }
  
  function updateTokenSupport(bytes32 market_, uint256 decimals_,address tokenAddress_) external authTokenList()  returns(bool){
    _updateTokenSupport(market_, decimals_, tokenAddress_);
    emit TokenSupportUpdated(market_,decimals_,tokenAddress_,block.timestamp);
    return bool(true);
  }

  function _connectMarket(bytes32 market_, uint256 amount_) internal returns(uint, IBEP20) {
		MarketData storage marketData = indMarketData[market_];
		address marketAddress = marketData.tokenAddress;
		token = IBEP20(marketAddress);
		amount_ *= marketData.decimals;

    return (amount_, token); 
	}

  function _updateTokenSupport(
    bytes32 market_,
    uint256 decimals_,
    address tokenAddress_
  ) internal {
    MarketData storage marketData = indMarketData[market_];

    marketData.market = market_;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = decimals_;

    tokenSupportCheck[market_] = true;
  }


	modifier nonReentrant() {
		require(isReentrant == false, "Re-entrant alert!");
		isReentrant = true;
		_;
		isReentrant = false;
	}

	modifier authTokenList() {
		require(msg.sender == adminTokenListAddress,"Only an admin can call this function");
		_;
	}
}