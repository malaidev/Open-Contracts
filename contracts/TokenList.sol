// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./AccessRegistry.sol";
import "./util/Address.sol";

contract TokenList {
  bytes32 internal adminTokenList;

  struct TokenRegistry {
    mapping(bytes32 => address) tokenAddress; // maps a symbol to its address
    mapping(bytes32 => uint256) decimals; // maps a symbol to its decimals
    mapping(bytes32 => uint256) tokenIndex; // index helps you verify if this token exists or not
    bytes32[] symbols;
  }
  
  mapping(bytes32 => TokenRegistry) supportedTokens;

  event TokenSupportAdded(bytes32 indexed _symbol,uint256 _decimals,address indexed _tokenAddress,uint256 indexed _timestamp);
  event TokenSupportRemoved(bytes32 indexed _symbol,uint256 _decimals,address indexed _tokenAddress,uint256 indexed _timestamp);
  constructor() {
    // address  constant BNB = 0x02822e968856186a20fEc2C824D4B174D0b70502;
    // address  constant STACK = 0x04DF6e4121c27713ED22341E7c7Df330F56f289B;
    // address  constant USDC = 0x9780881Bf45B83Ee028c4c1De7e0C168dF8e9eEF;

    // implement the default token support to some of the tokens.
  }


// ADD A NEW TOKEN SUPPORT
  function addTokenSupport(bytes32 _symbol,uint256 _decimals,address _tokenAddress) external returns (bool success) {
    
    _isTokenSupported(_symbol);
    _addTokenSupport(_symbol, _decimals, _tokenAddress);

    emit TokenSupportAdded(_symbol,_decimals,_tokenAddress,block.timestamp
    );

    return bool(success);
  }

  function _isTokenSupported(bytes32 _symbol) internal view {
    require(supportedTokens[_symbol].tokenIndex[_symbol] != 0,"This token is already supported");
    this;
  }

  function _addTokenSupport( bytes32 _symbol,uint256 _decimals,address _tokenAddress) internal {
    TokenRegistry storage tokenRegistry = supportedTokens[_symbol];

    tokenRegistry.tokenAddress[_symbol] = _tokenAddress;
    tokenRegistry.decimals[_symbol] = _decimals;
    tokenRegistry.symbols.push(_symbol); // adds the token symbol to the tokenregistry
    tokenRegistry.tokenIndex[_symbol] = tokenRegistry.symbols.length; 
  }

  function removeTokenSupport(bytes32 _symbol) external returns(bool success) {}
  function _removeTokenSupport(bytes32 _symbol) internal {}


// temporary disabling a token support could come in hand during the events a
// token is exploited or somethnig like that
  // function tempDisableTokenSupport(bytes32 _symbol) external returns(bool success)  {}
}

// Tokenlist contract holds the list of suppported tokens, base and
// non-base.All the other contracts - deposit, lender, comptroller inherit from
// the tokenlist contract.


// Instead of a single public function, I will create an external and internal
// function for free flow of interactions