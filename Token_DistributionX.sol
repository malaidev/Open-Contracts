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

    bool isReentrant = false;
    ERC20[] tokens;
    uint public waitTime = 4320 minutes;
    struct TokenData    {
        uint amount;
        uint unlockTime;
    }

    mapping(ERC20 => TokenData) _mapper;
    event TokensIssued(ERC20 token, address indexed sender);

    constructor(address tUSDT, address tUSDC, address tBTC, address tBNB) {
        _updateTokens(usdtInstance, tUSDT, 1000000000000000000000);
        _updateTokens(usdcInstance, tUSDC, 1000000000000000000000);
        _updateTokens(btcInstance, tBTC, 100000000);
        _updateTokens(wBnbInstance, tBNB, 10000000000000000000);   
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
        TokenData storage td = _mapper[tokenInstance];

        require (td.unlockTime <= block.timestamp, "ERROR: Wait time is applicabel");

        tokenInstance.transfer(msg.sender, td.amount);
        td.unlockTime = block.timestamp + waitTime;

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
