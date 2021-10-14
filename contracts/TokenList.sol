// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./AccessRegistry.sol";
import "./util/IBEP20.sol";
import "./util/Address.sol";
// import "./util/Pausable.sol";

contract TokenList /* is Pausable */{

  bytes32 adminTokenList;
  address adminTokenListAddress;
  address superAdminAddress;

  bool isReentrant = false;
  
  struct MarketData {
    bytes32 market;
    address tokenAddress;
    uint256 decimals;
    uint256 chainId;
  }

  bytes32[] markets;
  bytes32[] markets2;

  mapping (bytes32 => bool) public tokenSupportCheck;
  mapping (bytes32=>uint256) marketIndex;
  mapping (bytes32 => MarketData) public indMarketData;

  mapping (bytes32 => bool) public token2SupportCheck;
  mapping (bytes32=>uint256) market2Index;
  mapping (bytes32 => MarketData) public indMarket2Data;

//   MarketData internal rmMarketData;

  event TokenSupportAdded(bytes32 indexed market_,uint256 decimals_,address indexed tokenAddress_,uint256 indexed _timestamp);
  event TokenSupportUpdated(bytes32 indexed market_,uint256 decimals_,address indexed tokenAddress_,uint256 indexed _timestamp);
  event TokenSupportRemoved(bytes32 indexed market_, uint256 indexed _timestamp);
  
  event Token2Added(
    bytes32 indexed market_,
    uint256 decimals_,
    address indexed tokenAddress_,
    uint256 indexed _timestamp
  );
  
  event Token2Updated(
    bytes32 indexed market_,
    uint256 decimals_,
    address indexed tokenAddress_,
    uint256 indexed _timestamp
  );
  
  event Token2Removed(bytes32 indexed market_, uint256 indexed _timestamp);

  constructor(address superAdminAddr_) {
    superAdminAddress = superAdminAddr_;
    adminTokenListAddress = msg.sender;
  }
  receive() external payable {
    payable(adminTokenListAddress).transfer(msg.value);
  }
  
  fallback() external payable {
    payable(adminTokenListAddress).transfer(msg.value);
  }
  
  function transferAnyERC20(address token_,address recipient_,uint256 value_) external returns(bool) {
    IBEP20(token_).transfer(recipient_, value_);
    return true;
  }
  function isMarketSupported(bytes32  market_) external view returns (bool)	{
		_isMarketSupported(market_);
		return true;
	}

	function _isMarketSupported(bytes32  market_) internal view {
		require(tokenSupportCheck[market_] == true, "Hey, Token is not supported");
	}

  function getMarketTokenAddress(bytes32 market_) external view returns (address) {
    return indMarketData[market_].tokenAddress;
  }

  function getMarketDecimal(bytes32 market_) external view returns (uint) {
    return indMarketData[market_].decimals;
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

  function _connectMarket(bytes32 market_, /* uint256 amount_, */ IBEP20 token) internal view {
		MarketData storage marketData = indMarketData[market_];
		address marketAddress = marketData.tokenAddress;
		token = IBEP20(marketAddress);
		// amount_ *= marketData.decimals;
	}

  function _quantifyAmount(bytes32 _market, uint _amount) internal view {
    MarketData storage marketData = indMarketData[_market];
    _amount *= marketData.decimals;
  }

  function _updateTokenSupport(
    bytes32 market_,
    uint256 decimals_,
    address tokenAddress_
  ) internal
  {
    MarketData storage marketData = indMarketData[market_];

    marketData.market = market_;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = decimals_;

    tokenSupportCheck[market_] = true;
  }

  //SecondaryToken
  function isToken2Supported(bytes32  market_) external view returns (bool)	{
		_isToken2Supported(market_);
		return true;
	}

	function _isToken2Supported(bytes32  market_) internal view {
		require(token2SupportCheck[market_] == true, "Secondary Token is not supported");
	}

  function getMarketToken2Address(bytes32 market_) external view returns (address) {
    return indMarket2Data[market_].tokenAddress;
  }

  function getMarket2Decimal(bytes32 market_) external view returns (uint) {
    return indMarket2Data[market_].decimals;
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addToken2Support(bytes32 market_,uint256 decimals_,address tokenAddress_) 
    external authTokenList returns (bool) 
  {
    _addToken2Support(market_, decimals_, tokenAddress_);

    emit Token2Added(market_,decimals_,tokenAddress_,block.timestamp);
    return bool(true);
  }

  function _addToken2Support( bytes32 market_,uint256 decimals_,address tokenAddress_) internal {
    MarketData storage marketData = indMarket2Data[market_];
    
    marketData.market = market_;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = decimals_;
    
    markets2.push(market_);
    token2SupportCheck[market_] = true;
    market2Index[market_] = markets2.length-1;
  }

  function removeToken2Support(bytes32 market_) external authTokenList returns(bool) {
    _removeToken2Support(market_);
    emit Token2Removed(market_, block.timestamp);
    return bool(true);
  }

  function _removeToken2Support(bytes32 market_) internal {
    token2SupportCheck[market_] = false;
    delete indMarket2Data[market_];

    if (market2Index[market_] >= markets2.length) return;

    bytes32 lastmarket = markets2[markets2.length - 1];

    if (market2Index[lastmarket] != market2Index[market_]) {
      market2Index[lastmarket] = market2Index[market_];
      markets2[market2Index[market_]] = lastmarket;
    }
    markets2.pop();
    delete market2Index[market_];
  }
  
  function updateToken2Support(bytes32 market_, uint256 decimals_,address tokenAddress_) 
    external authTokenList returns(bool)
  {
    _updateToken2Support(market_, decimals_, tokenAddress_);
    emit Token2Updated(market_,decimals_,tokenAddress_,block.timestamp);
    return bool(true);
  }

  function _updateToken2Support(
    bytes32 market_,
    uint256 decimals_,
    address tokenAddress_
  ) internal {
    MarketData storage marketData = indMarket2Data[market_];

    marketData.market = market_;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = decimals_;

    token2SupportCheck[market_] = true;
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