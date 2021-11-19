// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "./mockup/IMockBep20.sol";
import "./util/Pausable.sol";
import "./libraries/LibDiamond.sol";
import "hardhat/console.sol";
contract TokenList is Pausable, ITokenList {
  
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

  constructor() {
    // LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
    // ds.tokenList = ITokenList(msg.sender);
  }

  function isMarketSupported(bytes32  _market) external view returns (bool)	{
		LibDiamond._isMarketSupported(_market);
		return true;
	}
  
  function getMarketAddress(bytes32 _market) external view returns (address) {
    return LibDiamond._getMarketAddress(_market);
  }

  function getMarketDecimal(bytes32 _market) external view returns (uint) {
    return LibDiamond._getMarketDecimal(_market);
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addMarketSupport(bytes32 _market,uint256 _decimals,address tokenAddress_, uint _amount) external authTokenList() returns (bool) {
    LibDiamond._addMarketSupport(_market, _decimals, tokenAddress_, _amount);

    emit MarketSupportAdded(_market,_decimals,tokenAddress_,block.timestamp);
    return true;
  }

  function minAmountCheck(bytes32 _market, uint _amount) external view {
    LibDiamond._minAmountCheck(_market, _amount);
  }

  function removeMarketSupport(bytes32 _market) external authTokenList() returns(bool) {
    LibDiamond._removeMarketSupport(_market);
    emit MarketSupportRemoved(_market, block.timestamp);
    return true;
  }
  
  function updateMarketSupport(bytes32 _market, uint256 _decimals,address tokenAddress_) external authTokenList()  returns(bool){
    LibDiamond._updateMarketSupport(_market, _decimals, tokenAddress_);
    emit MarketSupportUpdated(_market,_decimals,tokenAddress_,block.timestamp);
    return true;
  }

  function quantifyAmount(bytes32 _market, uint _amount) external view returns (uint amount) {
    // return LibDiamond._quantifyAmount(_market, _amount);
  }

  //SecondaryToken
  function isMarket2Supported(bytes32  _market) external view returns (bool)	{
		LibDiamond._isMarket2Supported(_market);
		return true;
	}

  function getMarket2Address(bytes32 _market) external view returns (address) {
    return LibDiamond._getMarket2Address(_market);
  }

  function getMarket2Decimal(bytes32 _market) external view returns (uint) {
    return LibDiamond._getMarket2Decimal(_market);
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addMarket2Support(bytes32 _market,uint256 _decimals,address tokenAddress_) 
    external authTokenList returns (bool) 
  {
    LibDiamond._addMarket2Support(_market, _decimals, tokenAddress_);
    emit Market2Added(_market,_decimals,tokenAddress_,block.timestamp);
    return bool(true);
  }

  function removeMarket2Support(bytes32 _market) external authTokenList returns(bool) {
    LibDiamond._removeMarket2Support(_market);
    emit Market2Removed(_market, block.timestamp);
    return bool(true);
  }
  
  function updateMarket2Support(bytes32 _market, uint256 _decimals,address tokenAddress_) 
    external authTokenList returns(bool)
  {
    LibDiamond._updateMarket2Support(_market, _decimals, tokenAddress_);
    emit Market2Updated(_market,_decimals,tokenAddress_,block.timestamp);
    return bool(true);
  }

  function pauseTokenList() external authTokenList() nonReentrant() {
       _pause();
	}
	
	function unpauseTokenList() external authTokenList() nonReentrant() {
       _unpause();   
	}

  function isPausedTokenList() public view virtual returns (bool) {
    return _paused();
  }

	modifier authTokenList() {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		require(msg.sender == ds.contractOwner, "Only an admin can call this function");
		_;
	}
}
