// SPDX-License-Identifier: MIT
pragma solidity 0.8.1; 

interface BEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    
    BEP20 public usdtInstance;
    BEP20 public usdcInstance;
    BEP20 public btcInstance;
    BEP20 public wBnbInstance;

    BEP20[] public tokens;

    bool isReentrant = false;
    uint public waitTime = 4320 minutes;

    struct TokenData    {
        uint amount;
        uint unlockTime;
    }

    mapping(BEP20 => TokenData) _mapper;
    event TokensIssued(BEP20 token, address indexed account);

    constructor(address tUSDT, address tUSDC, address tBTC, address tBNB) {
        _updateTokens(usdtInstance, tUSDT, 1000000000000000000000);
        _updateTokens(usdcInstance, tUSDC, 1000000000000000000000);
        _updateTokens(btcInstance, tBTC, 100000000);
        _updateTokens(wBnbInstance, tBNB, 10000000000000000000);   
    }

    function _updateTokens(BEP20 _tokenInstance, address _token,uint _amount) private {
        require(_token != address(0), "ERROR: Zero address");

        _tokenInstance = BEP20(_token);
        _mapper[_tokenInstance].amount = _amount;
        _mapper[_tokenInstance].unlockTime = 0;

        tokens.push(_tokenInstance);
        // return this;
    }

    // [0,1,2,3] => [usdt, udsc, btc, bnb]
    function getTokens(uint _index) public nonReentrant() returns(bool success){

        BEP20 tokenInstance = tokens[_index];
        TokenData storage td = _mapper[tokenInstance];

        require (td.unlockTime <= block.timestamp, "ERROR: Wait time is applicabel");

        tokenInstance.transfer(msg.sender, td.amount);
        td.unlockTime = block.timestamp + waitTime;

        emit TokensIssued(tokenInstance, msg.sender);
        return success = true;
    }

    modifier nonReentrant() {
        require(isReentrant == false, "ERROR: Re-entrant");
        isReentrant = true;
        _;
        isReentrant = false;
    }
}
