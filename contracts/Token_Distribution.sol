// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1 <0.9.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    uint256 constant public tokenAmount1 = 10000000000000000000000;
    // sends 10,000 tokens t.USDT
    uint256 constant public tokenAmount2 = 10000000000000000000000;
    // sends 10,000 tokens t.USDC
    uint256 constant public tokenAmount3 =  5000000000000000000;
    // sends 5 tokens t.BTC
    
    // uint256 constant public tokenAmount4 = 10000000000000000000000;
    // // sends 10,000 tokens t.USDT
    // uint256 constant public tokenAmount5 = 10000000000000000000000;
    // // sends 10,000 tokens t.USDT
    uint256 constant public waitTime = 4320 minutes;
    // can access only after 3 days 

    ERC20 public tokenInstance1;
    ERC20 public tokenInstance2;
    ERC20 public tokenInstance3;
    // ERC20 public tokenInstance4;
    // ERC20 public tokenInstance5;
    
    mapping(address => uint256) lastAccessTime;

    constructor (address  _tokenInstance1,address _tokenInstance2,address _tokenInstance3/*,address _tokenInstance4,address _tokenInstance5*/) {
        require(_tokenInstance1 != address(0));
        require(_tokenInstance2 != address(0));
        require(_tokenInstance3 != address(0));
        // require(_tokenInstance4 != address(0));
        // require(_tokenInstance5 != address(0));


        tokenInstance1 = ERC20(_tokenInstance1);
        tokenInstance2 = ERC20(_tokenInstance2);
        tokenInstance3 = ERC20(_tokenInstance3);
        // tokenInstance4 = ERC20(_tokenInstance4);
        // tokenInstance5 = ERC20(_tokenInstance5);

    }

    function requestTokens1() public {
        require(allowedToWithdraw(msg.sender));
        tokenInstance1.transfer(msg.sender, tokenAmount1);
        // tokenInstance2.transfer(msg.sender, tokenAmount2);
        // tokenInstance3.transfer(msg.sender, tokenAmount3);
        // tokenInstance4.transfer(msg.sender, tokenAmount4);
        // tokenInstance5.transfer(msg.sender, tokenAmount5);

        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

     function requestTokens2() public {
        require(allowedToWithdraw(msg.sender));
        // tokenInstance1.transfer(msg.sender, tokenAmount1);
        tokenInstance2.transfer(msg.sender, tokenAmount2);
        // tokenInstance3.transfer(msg.sender, tokenAmount3);
        // tokenInstance4.transfer(msg.sender, tokenAmount4);
        // tokenInstance5.transfer(msg.sender, tokenAmount5);

        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }
     function requestTokens3() public {
        require(allowedToWithdraw(msg.sender));
        // tokenInstance1.transfer(msg.sender, tokenAmount1);
        // tokenInstance2.transfer(msg.sender, tokenAmount2);
        tokenInstance3.transfer(msg.sender, tokenAmount3);
        // tokenInstance4.transfer(msg.sender, tokenAmount4);
        // tokenInstance5.transfer(msg.sender, tokenAmount5);

        lastAccessTime[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }
}
