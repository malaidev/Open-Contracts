// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

import "./AccessRegistry.sol";
import "./util/Address.sol";

contract TokenList{
  struct TokenData{
    bytes32 symbol;
    address tokenAddress;
    uint decimals;
    uint chainId;
  }

  bytes32[] allSymbols;

  mapping (bytes32 => bool) public isSymbolExist;
  mapping (bytes32=>uint256) symbolIndex;
  mapping (bytes32 => TokenData) public tokenPointer;

  event TokenSupportAdded(bytes32 indexed _symbol,uint256 _decimals,address indexed _tokenAddress,uint256 indexed _timestamp);
  event TokenSupportRemoved(bytes32 indexed _symbol,uint256 _decimals,address indexed _tokenAddress,uint256 indexed _timestamp);
 
  function isTokenSupported(bytes32  _symbol) external view returns (bool)	{
		_isTokenSupported(_symbol);
		return true;
	}

	function _isTokenSupported(bytes32  _symbol) internal view {
	
		require(isSymbolExist[_symbol] == true, "Token is not supported");
	}

// ADD A NEW TOKEN SUPPORT
  function addTokenSupport(bytes32 _symbol,uint256 _decimals,address _tokenAddress) external returns (bool) {
    
    _isTokenSupported(_symbol);
    _addTokenSupport(_symbol, _decimals, _tokenAddress);

    emit TokenSupportAdded(_symbol,_decimals,_tokenAddress,block.timestamp
    );

    return bool(true);
  }
  function _addTokenSupport( bytes32 _symbol,uint256 _decimals,address _tokenAddress) internal {
    TokenData storage tokenData = tokenPointer[_symbol];
    
    tokenData.symbol = _symbol;
    tokenData.tokenAddress = _tokenAddress;
    tokenData.decimals = _decimals;
    
    allSymbols.push(_symbol);
    isSymbolExist[_symbol] = true;
    symbolIndex[_symbol] = allSymbols.length-1;

  }

  function removeTokenSupport(bytes32 _symbol) external returns(bool) {
    _removeTokenSupport(_symbol);
    return bool(true);
  }
  function _removeTokenSupport(bytes32 _symbol) internal {

    TokenData memory tokenData = tokenPointer[_symbol];
    isSymbolExist[_symbol] = false;

    delete tokenData;
    
    if (symbolIndex[_symbol] >= allSymbols.length) return;

    bytes32 lastSymbol  = allSymbols[allSymbols.length-1];

    if(symbolIndex[lastSymbol] != symbolIndex[_symbol]){
      symbolIndex[lastSymbol] = symbolIndex[_symbol];
      allSymbols[symbolIndex[_symbol]] = lastSymbol;
    }
    allSymbols.pop();
    delete symbolIndex[_symbol];
  }
  
  function updateTokenSupport(bytes32 _symbol, uint256 _decimals,address _tokenAddress) external returns(bool){
    _updateTokenSupport(_symbol, _decimals, _tokenAddress);
    return bool(true);
  }
  function _updateTokenSupport(bytes32 _symbol, uint256 _decimals,address _tokenAddress) internal{

    TokenData storage tokenData = tokenPointer[_symbol];
    
    tokenData.symbol = _symbol;
    tokenData.tokenAddress = _tokenAddress;
    tokenData.decimals = _decimals;

    isSymbolExist[_symbol] = true;
  }
}