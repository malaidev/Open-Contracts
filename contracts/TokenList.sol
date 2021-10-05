// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./AccessRegistry.sol";
import "./util/Address.sol";
import "./util/IBEP20.sol";
import "./util/Pausable.sol";

contract TokenList is Pausable{

  bytes32 adminTokenList;
  address adminTokenListAddress;
  address superAdminAddress;
  
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

  function isTokenSupported(bytes32  market_) external view returns (bool)	{
		_isTokenSupported(market_);
		return true;
	}

	function _isTokenSupported(bytes32  market_) internal view {
		require(tokenSupportCheck[market_] == true, "Hey, Token is not supported");
	}

  function getMarketTokenAddress(bytes32 market_) external view returns (address) {
    return indMarketData[market_].tokenAddress;
  }

  function getMarketDecimal(bytes32 market_) external view returns (uint) {
    return indMarketData[market_].decimals;
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addTokenSupport(bytes32 market_,uint256 decimals_,address tokenAddress_) external onlyAdmin returns (bool) {
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

  function removeTokenSupport(bytes32 market_) external onlyAdmin returns(bool) {
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
  
  function updateTokenSupport(bytes32 market_, uint256 decimals_,address tokenAddress_) external onlyAdmin returns(bool){
    _updateTokenSupport(market_, decimals_, tokenAddress_);
    emit TokenSupportUpdated(market_,decimals_,tokenAddress_,block.timestamp);
    return bool(true);
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

  modifier onlyAdmin() {
    require(msg.sender == adminTokenListAddress ||
      msg.sender == superAdminAddress,
      "Only the TokenList admin can modify this function"
    );
    _;
  }

  function pause() external onlyAdmin() nonReentrant() {
       _pause();
	}
	
	function unpause() external onlyAdmin() nonReentrant() {
       _unpause();   
	}
}