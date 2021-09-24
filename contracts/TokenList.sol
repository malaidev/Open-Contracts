// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./AccessRegistry.sol";
import "./util/Address.sol";

contract TokenList {

	bytes32 internal adminTokenList;
	bytes32[] allSymbols;
	struct TokenData {
		bytes32 symbol;
		address tokenAddress;
		uint decimals;
		uint chainId;	
		bool isSupported;
	}

	TokenData[] allMarkets;
	
	mapping(bytes32 => TokenData) tokenPointer; // 
	// mapping(bytes32 => bool) isTokenSupported; 

	function isTokenSupported(bytes32  symbol_) external view returns (bool)	{
		_isTokenSupported(symbol_);
		return true;
	}

	function _isTokenSupported(bytes32  symbol_) internal view {
		TokenData storage tokenData  = tokenPointer[symbol_];
		require(tokenData.isSupported == true, "Token is not supported");
	}

}