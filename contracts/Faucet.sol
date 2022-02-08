// SPDX-License-Identifier: MIT
pragma solidity 0.8.1; 
interface BEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    
    // BEP20 public usdtInstance;
    // BEP20 public usdcInstance;
    // BEP20 public btcInstance;
    // BEP20 public wBnbInstance;

    uint num = 0;

    bool isReentrant = false;
    uint public waitTime = 4320 minutes;

    struct TokenLedger    {
        BEP20 token;
        uint amount;
        uint balance;
    }

    mapping(uint => TokenLedger) tokens; // token id => token ledger.
    
    mapping(address => mapping(BEP20 => uint)) airdropRecords; // Address to token to amount of tokens to drip.
    event TokensIssued(BEP20 indexed token, address indexed account, uint indexed amount, uint  time);

    constructor(address tUSDT, address tUSDC, address tBTC, address tBNB) {
        _updateTokens(tUSDT, 10000000000000000000000); // 10000 USDT
        _updateTokens(tUSDC, 10000000000000000000000); // 10000 USDC
        _updateTokens(tBTC, 500000000); // 5 BTC
        _updateTokens(tBNB, 100000000000000000000);   // 100 BNB
    }

    /// UPDATE TOKENS
    function _updateTokens(address _token,uint _amount) private {
        require(_token != address(0), "ERROR: Zero address");

        TokenLedger storage td = tokens[num];
        td.token = BEP20(_token); // token pointer
        td.amount = _amount; // drip amount
        td.balance = BEP20(_token).balanceOf(address(this)); // Faucet balance

        num++;
    }

    /// GET TOKENS
    function getTokens(address _account, uint _index) public nonReentrant() returns(bool success)   {
        require(_account != address(0), "ERROR: Zero address");
        
        TokenLedger storage td = tokens[_index];

        require(td.token.balanceOf(address(this)) >= td.amount, "ERROR: Insufficient balance");
        require(airdropRecords[_account][td.token] <= block.timestamp, "ERROR: Active timelock");

        td.token.transfer(msg.sender, td.amount);
        td.balance -= td.amount;

        airdropRecords[_account][td.token] = block.timestamp + waitTime;

        emit TokensIssued(td.token, _account, td.amount, block.timestamp);
        return success = true;
    }


    modifier nonReentrant() {
        require(isReentrant == false, "ERROR: Re-entrant");
        isReentrant = true;
        _;
        isReentrant = false;
    }
}
