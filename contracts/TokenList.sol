// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// import "./mockup/IMockBep20.sol";
import "./util/Pausable.sol";
import "./libraries/LibDiamond.sol";

contract TokenList is Pausable, ITokenList {  

  constructor() {
  }

  function isMarketSupported(bytes32  _market) external view override returns (bool)	{
		LibDiamond._isMarketSupported(_market);
		return true;
	}
  
  function getMarketAddress(bytes32 _market) external view override returns (address) {
    return LibDiamond._getMarketAddress(_market);
  }

  function getMarketDecimal(bytes32 _market) external view override returns (uint) { 
    return LibDiamond._getMarketDecimal(_market);
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addMarketSupport(bytes32 _market,uint256 _decimals,address tokenAddress_, uint _amount) external override authTokenList() returns (bool) {
    LibDiamond._addMarketSupport(_market, _decimals, tokenAddress_, _amount);
    return true;
  }

  function minAmountCheck(bytes32 _market, uint _amount) external override view {
    LibDiamond._minAmountCheck(_market, _amount);
  }

  function removeMarketSupport(bytes32 _market) external override authTokenList() returns(bool) {
    LibDiamond._removeMarketSupport(_market);
    return true;
  }
  
  function updateMarketSupport(bytes32 _market, uint256 _decimals,address tokenAddress_) external override authTokenList()  returns(bool){
    LibDiamond._updateMarketSupport(_market, _decimals, tokenAddress_);
    return true;
  }

  // function quantifyAmount(bytes32 _market, uint _amount) external override view returns (uint amount) {
  //   // return LibDiamond._quantifyAmount(_market, _amount);
  // }

  //SecondaryToken
  function isMarket2Supported(bytes32  _market) external view override returns (bool)	{
		LibDiamond._isMarket2Supported(_market);
		return true;
	}

  function getMarket2Address(bytes32 _market) external view override returns (address) {
    return LibDiamond._getMarket2Address(_market);
  }

  function getMarket2Decimal(bytes32 _market) external view override returns (uint) {
    return LibDiamond._getMarket2Decimal(_market);
  }
  
  // ADD A NEW TOKEN SUPPORT
  function addMarket2Support(bytes32 _market,uint256 _decimals,address tokenAddress_) 
    external override authTokenList returns (bool) 
  {
    LibDiamond._addMarket2Support(_market, _decimals, tokenAddress_);
    return true;
  }

  function removeMarket2Support(bytes32 _market) external override authTokenList returns(bool) {
    LibDiamond._removeMarket2Support(_market);
    return true;
  }
  
  function updateMarket2Support(bytes32 _market, uint256 _decimals,address tokenAddress_) 
    external override authTokenList returns(bool)
  { 
    LibDiamond._updateMarket2Support(_market, _decimals, tokenAddress_);
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
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage(); 
		require(LibDiamond._hasAdminRole(ds.superAdmin, ds.contractOwner) || LibDiamond._hasAdminRole(ds.adminTokenList, ds.adminTokenListAddress), "Admin role does not exist.");	
	  _;
	}

}
