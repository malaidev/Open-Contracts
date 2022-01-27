// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1 <0.9.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    
    ERC20 public usdtInstance;
    ERC20 public usdcInstance;
    ERC20 public btcInstance;
    ERC20 public wBnbInstance;

    uint256 constant public usdtAmount = 10000000000000000000000; // sends 10,000 tokens USDT. 18 decimals.
    uint256 constant public usdcAmount = 10000000000000000000000; // sends 10,000 tokens USDC. 18 decimals.
    uint256 constant public btcAmount =               500000000; // sends 5 tokens BTC, 8 decimals.
    uint256 constant public wBnbAmount =   100000000000000000000; // sends 100 tokens wBNB. 18 decimals.

    bool isReentrant = false;


    struct TokenData    {
        uint amount;
        uint unlockTime;
    }

    ERC20[] tokens;
    uint public waitTime = 4320 minutes;

    mapping(ERC20 => TokenData) _mapper;
    event TokensIssued(ERC20 token, address indexed sender);
    
    // ERC20 public token5;

    constructor(address tUSDT, address tUSDC, address tBTC, address tBNB) {
        _updateTokens(usdtInstance, tUSDT, usdtAmount);
        _updateTokens(usdcInstance, tUSDC, usdcAmount);
        _updateTokens(btcInstance, tBTC, btcAmount);
        _updateTokens(wBnbInstance, tBNB, wBnbAmount);   
    }

    function _updateTokens(ERC20 _tokenInstance, address _token,uint _amount) private {
        require(_token != address(0), "ERROR: Zero address");

        _tokenInstance = ERC20(_token);
        _mapper[_tokenInstance].amount = _amount;
        _mapper[_tokenInstance].unlockTime = 0;

        tokens.push(_tokenInstance);
        // return this;
    }

    // [0,1,2,3] => [usdt, udsc, btc, bnb]
    function getTokens(uint _index) public nonReentrant() returns(bool success){

        ERC20 tokenInstance = tokens[_index];
        uint unlockTime = _mapper[tokenInstance].unlockTime;
        uint amount = _mapper[tokenInstance].amount;
        // uint unlockTime = _mapper[tokenInstance].unlockTime;
        require (unlockTime <= block.timestamp, "ERROR: You can get airdrop only once in 3 days");

        tokenInstance.transfer(msg.sender, amount);
        unlockTime = block.timestamp + waitTime;

        emit TokensIssued(tokenInstance, msg.sender);
        return success;
    }

    modifier nonReentrant() {
		require(isReentrant == false, "Re-entrant alert!");
		isReentrant = true;
		_;
		isReentrant = false;
	}
}
