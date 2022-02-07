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

    uint num = 0;

    bool isReentrant = false;
    uint public waitTime = 4320 minutes;

    struct TokenData    {
        BEP20 token;
        uint amount;
    }

    mapping(address => mapping(BEP20 => uint)) indFaucetMonitor; // Airdrop timelock monitor.r
    mapping(uint => TokenData) tokenMapper; //maps a token's number identifier to its struct.

    event TokensIssued(BEP20 indexed token, address indexed account, uint indexed time);

    constructor(address tUSDT, address tUSDC, address tBTC, address tBNB) {
        _updateTokens(usdtInstance, tUSDT, 10000000000000000000000); // 10,000 USDT
        _updateTokens(usdcInstance, tUSDC, 10000000000000000000000); // 10,000 USDC
        _updateTokens(btcInstance, tBTC, 500000000); // 5 btc
        _updateTokens(wBnbInstance, tBNB, 100000000000000000000);  // 100 BNB
    }

    
    /// CREATES THE TOKEN MAPPING
    function _updateTokens(BEP20 _tokenInstance, address _token,uint _amount) private {
        require(_token != address(0), "ERROR: Zero address");

        _tokenInstance = BEP20(_token);

        TokenData storage td = tokenMapper[num];
        td.token = _tokenInstance;
        td.amount = _amount;

        num++;
    }

    /// AIRDROP FAUCET FUNCTION
    // [0,1,2,3] => [usdt, udsc, btc, bnb]
    function getTokens(uint _index) external nonReentrant() returns(bool success){

        require(msg.sender != address(0), "ERROR: Zero address");

        BEP20 token = tokenMapper[_index].token;

        require(indFaucetMonitor[msg.sender][token] <= block.timestamp, "ERROR: Timelock in efect");
        token.transfer(msg.sender, tokenMapper[_index].amount);

        indFaucetMonitor[msg.sender][token] = block.timestamp + waitTime;

        emit TokensIssued(token, msg.sender, block.timestamp);
        return success = true;

    }

    /// NON-REENTRANT MODIFIER
    modifier nonReentrant() {
        require(isReentrant == false, "ERROR: Re-entrant");
        isReentrant = true;
        _;
        isReentrant = false;
    }
}

// pragma solidity 0.8.1; 

// interface BEP20 {
//     function transfer(address to, uint256 value) external returns (bool);
//     event Transfer(address indexed from, address indexed to, uint256 value);
// }

// contract Faucet {
    
//     BEP20 public usdtInstance;
//     BEP20 public usdcInstance;
//     BEP20 public btcInstance;
//     BEP20 public wBnbInstance;

//     BEP20[] public tokens;

//     bool isReentrant = false;
//     uint public waitTime = 4320 minutes;

//     struct TokenData    {
//         uint amount;
//         uint unlockTime;
//     }

//     mapping(BEP20 => TokenData) tokenMapper;
//     mapping(address => TokenData) _accounts;
//     event TokensIssued(BEP20 token, address indexed account);

//     constructor(address tUSDT, address tUSDC, address tBTC, address tBNB) {
//         _updateTokens(usdtInstance, tUSDT, 1000000000000000000000);
//         _updateTokens(usdcInstance, tUSDC, 1000000000000000000000);
//         _updateTokens(btcInstance, tBTC, 100000000);
//         _updateTokens(wBnbInstance, tBNB, 10000000000000000000);   
//     }

//     function _updateTokens(BEP20 _tokenInstance, address _token,uint _amount) private {
//         require(_token != address(0), "ERROR: Zero address");

//         _tokenInstance = BEP20(_token);
//         tokenMapper[_tokenInstance].amount = _amount;
//         tokenMapper[_tokenInstance].unlockTime = 0;

//         tokens.push(_tokenInstance);
//         // return this;
//     }

//     // [0,1,2,3] => [usdt, udsc, btc, bnb]
//     function getTokens(address _account, uint _index) public nonReentrant() returns(bool success){

//         BEP20 tokenInstance = tokens[_index];
//         TokenData storage td = tokenMapper[tokenInstance];

//         require (td.unlockTime <= block.timestamp, "ERROR: Wait time is applicabel");

//         tokenInstance.transfer(msg.sender, td.amount);
//         td.unlockTime = block.timestamp + waitTime;

//         emit TokensIssued(tokenInstance, msg.sender);
//         return success = true;
//     }

//     modifier nonReentrant() {
//         require(isReentrant == false, "ERROR: Re-entrant");
//         isReentrant = true;
//         _;
//         isReentrant = false;
//     }
// }
