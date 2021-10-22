// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./mockup/IMockBep20.sol";
import "./util/Address.sol";
import "./util/Pausable.sol";

contract TokenList is Pausable {

  bytes32 adminTokenList;
  address adminTokenListAddress;
  address superAdminAddress;

  struct MarketData {
    bytes32 market;
    address tokenAddress;
    uint256 decimals;
    uint256 chainId;
    uint minAmount;
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

  event MarketSupportAdded(bytes32 indexed _market,uint256 _decimals,address indexed MarketAddress_,uint256 indexed _timestamp);
  event MarketSupportUpdated(bytes32 indexed _market,uint256 _decimals,address indexed MarketAddress_,uint256 indexed _timestamp);
  event MarketSupportRemoved(bytes32 indexed _market, uint256 indexed _timestamp);
  
  event Market2Added(
    bytes32 indexed _market,
    uint256 _decimals,
    address indexed MarketAddress_,
    uint256 indexed _timestamp
  );
  
  event Market2Updated(
    bytes32 indexed _market,
    uint256 _decimals,
    address indexed tokenAddress_,
    uint256 indexed _timestamp
  );
  
  event Market2Removed(bytes32 indexed _market, uint256 indexed _timestamp);

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
    IMockBep20(token_).transfer(recipient_, value_);
    return true;
  }
  function isMarketSupported(bytes32  _market) external view returns (bool)	{
		_isMarketSupported(_market);
		return true;
	}

	function _isMarketSupported(bytes32  _market) internal view {
		require(tokenSupportCheck[_market] == true, "ERROR: Unsupported market");
	}

  function getMarketAddress(bytes32 _market) external view returns (address) {
    return indMarketData[_market].tokenAddress;
  }

  function getMarketDecimal(bytes32 _market) external view returns (uint) {
    return indMarketData[_market].decimals;
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addMarketSupport(bytes32 _market,uint256 _decimals,address tokenAddress_, uint _amount) external authTokenList() returns (bool) {
    _addMarketSupport(_market, _decimals, tokenAddress_, _amount);

    emit MarketSupportAdded(_market,_decimals,tokenAddress_,block.timestamp);
    return bool(true);
  }
  function _addMarketSupport( bytes32 _market,uint256 _decimals,address tokenAddress_, uint _amount) internal {
    MarketData storage marketData = indMarketData[_market];
    
    marketData.market = _market;
    marketData.tokenAddress = tokenAddress_;
    marketData.minAmount = _amount*_decimals;
    marketData.decimals = _decimals;
    
    markets.push(_market);
    tokenSupportCheck[_market] = true;
    marketIndex[_market] = markets.length-1;
  }

  function minAmountCheck(bytes32 _market, uint _amount) external view {
    
    MarketData memory marketData = indMarketData[_market];
    require(marketData.minAmount <= _amount, "ERROR: Less than minimum deposit");
  }

  function removeMarketSupport(bytes32 _market) external authTokenList() returns(bool) {
    _removeMarketSupport(_market);
    emit MarketSupportRemoved(_market, block.timestamp);
    return bool(true);
  }

  function _removeMarketSupport(bytes32 _market) internal {

    tokenSupportCheck[_market] = false;
    delete indMarketData[_market];
    
    if (marketIndex[_market] >= markets.length) return;

    bytes32 lastmarket = markets[markets.length - 1];

    if (marketIndex[lastmarket] != marketIndex[_market]) {
      marketIndex[lastmarket] = marketIndex[_market];
      markets[marketIndex[_market]] = lastmarket;
    }
    markets.pop();
    delete marketIndex[_market];
  }
  
  function updateMarketSupport(bytes32 _market, uint256 _decimals,address tokenAddress_) external authTokenList()  returns(bool){
    _updateMarketSupport(_market, _decimals, tokenAddress_);
    emit MarketSupportUpdated(_market,_decimals,tokenAddress_,block.timestamp);
    return bool(true);
  }

  function connectMarket(bytes32 _market) external view returns (address addr){
		
    MarketData memory marketData = indMarketData[_market];

		address marketAddress = marketData.tokenAddress;
		addr = marketAddress;
		// amount_ *= marketData.decimals;
	}

  function quantifyAmount(bytes32 _market, uint _amount) external view  {
    
    MarketData memory marketData = indMarketData[_market];
    _amount *= marketData.decimals;
    
  }

  function _updateMarketSupport(
    bytes32 _market,
    uint256 _decimals,
    address tokenAddress_
  ) internal
  {
    MarketData storage marketData = indMarketData[_market];

    marketData.market = _market;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = _decimals;

    tokenSupportCheck[_market] = true;
  }

  //SecondaryToken
  function isMarket2Supported(bytes32  _market) external view returns (bool)	{
		_isMarket2Supported(_market);
		return true;
	}

	function _isMarket2Supported(bytes32  _market) internal view {
		require(token2SupportCheck[_market] == true, "Secondary Token is not supported");
	}

  function getMarket2Address(bytes32 _market) external view returns (address) {
    return indMarket2Data[_market].tokenAddress;
  }

  function getMarket2Decimal(bytes32 _market) external view returns (uint) {
    return indMarket2Data[_market].decimals;
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addMarket2Support(bytes32 _market,uint256 _decimals,address tokenAddress_) 
    external authTokenList returns (bool) 
  {
    _addMarket2Support(_market, _decimals, tokenAddress_);

    emit Market2Added(_market,_decimals,tokenAddress_,block.timestamp);
    return bool(true);
  }

  function _addMarket2Support( bytes32 _market,uint256 _decimals,address tokenAddress_) internal {
    MarketData storage marketData = indMarket2Data[_market];
    
    marketData.market = _market;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = _decimals;
    
    markets2.push(_market);
    token2SupportCheck[_market] = true;
    market2Index[_market] = markets2.length-1;
  }

  function removeMarket2Support(bytes32 _market) external authTokenList returns(bool) {
    _removeMarket2Support(_market);
    emit Market2Removed(_market, block.timestamp);
    return bool(true);
  }

  function _removeMarket2Support(bytes32 _market) internal {
    token2SupportCheck[_market] = false;
    delete indMarket2Data[_market];

    if (market2Index[_market] >= markets2.length) return;

    bytes32 lastmarket = markets2[markets2.length - 1];

    if (market2Index[lastmarket] != market2Index[_market]) {
      market2Index[lastmarket] = market2Index[_market];
      markets2[market2Index[_market]] = lastmarket;
    }
    markets2.pop();
    delete market2Index[_market];
  }
  
  function updateMarket2Support(bytes32 _market, uint256 _decimals,address tokenAddress_) 
    external authTokenList returns(bool)
  {
    _updateMarket2Support(_market, _decimals, tokenAddress_);
    emit Market2Updated(_market,_decimals,tokenAddress_,block.timestamp);
    return bool(true);
  }

  function _updateMarket2Support(
    bytes32 _market,
    uint256 _decimals,
    address tokenAddress_
  ) internal {
    MarketData storage marketData = indMarket2Data[_market];

    marketData.market = _market;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = _decimals;

    token2SupportCheck[_market] = true;
  }

  function pause() external authTokenList() nonReentrant() {
       _pause();
	}
	
	function unpause() external authTokenList() nonReentrant() {
       _unpause();   
	}

	modifier authTokenList() {
		require(msg.sender == adminTokenListAddress,"Only an admin can call this function");
		_;
	}
}