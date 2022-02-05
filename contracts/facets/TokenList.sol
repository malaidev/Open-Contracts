// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "./mockup/IMockBep20.sol";
import "../util/Pausable.sol";
import "../libraries/LibOpen.sol";
import "../libraries/AppStorageOpen.sol";

contract TokenList is Pausable, ITokenList {  

 	event MarketSupportAdded(bytes32 indexed _market,uint256 _decimals,address indexed MarketAddress_,uint256 indexed _timestamp);
	event MarketSupportUpdated(bytes32 indexed _market,uint256 _decimals,address indexed MarketAddress_,uint256 indexed _timestamp);
	event MarketSupportRemoved(bytes32 indexed _market, uint256 indexed _timestamp);
	event Market2Added(
		bytes32 indexed _market,
		uint256 _decimals,
		address indexed _marketAddress,
		uint256 indexed _timestamp
	);
  event Market2Updated(
  bytes32 indexed _market,
      uint256 _decimals,
      address indexed _tokenAddress,
      uint256 indexed _timestamp
  );
  event Market2Removed(bytes32 indexed _market, uint256 indexed _timestamp);

  constructor() {
  }

  receive() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}
    
	fallback() external payable {
    payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}

  function isMarketSupported(bytes32  _market) external view override returns (bool)	{
		LibOpen._isMarketSupported(_market);
		return true;
	}
  
  function getMarketAddress(bytes32 _market) external view override returns (address) {
    return LibOpen._getMarketAddress(_market);
  }

  function getMarketDecimal(bytes32 _market) external view override returns (uint) { 
    return LibOpen._getMarketDecimal(_market);
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addMarketSupport(bytes32 _market,uint256 _decimals,address tokenAddress_, uint _amount) external override authTokenList() returns (bool) {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
    MarketData storage marketData = ds.indMarketData[_market];
    
    marketData.market = _market;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = _decimals;
    marketData.minAmount = _amount; // not multiply decmial for amount < 1
    
    ds.pMarkets.push(_market);
    ds.tokenSupportCheck[_market] = true;
    ds.marketIndex[_market] = ds.pMarkets.length-1;
    emit MarketSupportAdded(_market,_decimals,tokenAddress_,block.timestamp);
    return true;
  }

  function minAmountCheck(bytes32 _market, uint _amount) external override view {
    LibOpen._minAmountCheck(_market, _amount);
  }

  function removeMarketSupport(bytes32 _market) external override authTokenList() returns(bool) {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 

    ds.tokenSupportCheck[_market] = false;
    delete ds.indMarketData[_market];
    
    if (ds.marketIndex[_market] >= ds.pMarkets.length) return false;

    bytes32 lastmarket = ds.pMarkets[ds.pMarkets.length - 1];

    if (ds.marketIndex[lastmarket] != ds.marketIndex[_market]) {
        ds.marketIndex[lastmarket] = ds.marketIndex[_market];
        ds.pMarkets[ds.marketIndex[_market]] = lastmarket;
    }
    ds.pMarkets.pop();
    delete ds.marketIndex[_market];

    emit MarketSupportRemoved(_market, block.timestamp);
    return true;
  }
  
  function updateMarketSupport(bytes32 _market, uint256 _decimals,address tokenAddress_) external override authTokenList()  returns(bool){
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 

    MarketData storage marketData = ds.indMarketData[_market];

    marketData.market = _market;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = _decimals;

    ds.tokenSupportCheck[_market] = true;
	  emit MarketSupportUpdated(_market,_decimals,tokenAddress_,block.timestamp);
    return true;
  }

  // function quantifyAmount(bytes32 _market, uint _amount) external override view returns (uint amount) {
  //   // return LibOpen._quantifyAmount(_market, _amount);
  // }

  //SecondaryToken
  function isMarket2Supported(bytes32  _market) external view override returns (bool)	{
		LibOpen._isMarket2Supported(_market);
		return true;
	}

  function getMarket2Address(bytes32 _market) external view override returns (address) {
    return LibOpen._getMarket2Address(_market);
  }

  function getMarket2Decimal(bytes32 _market) external view override returns (uint) {
    return LibOpen._getMarket2Decimal(_market);
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addMarket2Support(bytes32 _market,uint256 _decimals,address tokenAddress_) 
    external override authTokenList returns (bool) 
  {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
    MarketData storage marketData = ds.indMarket2Data[_market];
    
    marketData.market = _market;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = _decimals;
    
    ds.sMarkets.push(_market);
    ds.token2SupportCheck[_market] = true;
    ds.market2Index[_market] = ds.sMarkets.length-1;
    emit Market2Added(_market,_decimals,tokenAddress_,block.timestamp);
    return true;
  }

  function removeMarket2Support(bytes32 _market) external override authTokenList returns(bool) {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
    ds.token2SupportCheck[_market] = false;
    delete ds.indMarket2Data[_market];

    if (ds.market2Index[_market] >= ds.sMarkets.length) return false;

    bytes32 lastmarket = ds.sMarkets[ds.sMarkets.length - 1];

    if (ds.market2Index[lastmarket] != ds.market2Index[_market]) {
        ds.market2Index[lastmarket] = ds.market2Index[_market];
        ds.sMarkets[ds.market2Index[_market]] = lastmarket;
    }
    ds.sMarkets.pop();
    delete ds.market2Index[_market];
    emit Market2Removed(_market, block.timestamp);
    return true;
  }
  
  function updateMarket2Support(bytes32 _market, uint256 _decimals,address tokenAddress_) 
    external override authTokenList returns(bool)
  { 
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
    MarketData storage marketData = ds.indMarket2Data[_market];

    marketData.market = _market;
    marketData.tokenAddress = tokenAddress_;
    marketData.decimals = _decimals;

    ds.token2SupportCheck[_market] = true;
    emit Market2Updated(_market,_decimals,tokenAddress_,block.timestamp);
    return true;
  }

  function pauseTokenList() external override authTokenList() nonReentrant() {
       _pause();
	}
	
	function unpauseTokenList() external override authTokenList() nonReentrant() {
       _unpause();   
	}

  function isPausedTokenList() public view virtual override returns (bool) {
    return _paused(); 
  }

	modifier authTokenList() {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminTokenList, msg.sender), "ERROR: Not an admin");		  _;
	}

}
