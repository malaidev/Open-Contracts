// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1 <0.9.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    uint256 constant public tokenAmount1 =  1000000000000000000000;
    // sends 10,00 tokens USDT.t
    uint256 constant public tokenAmount2 =  1000000000000000000000;
    // sends 1000 tokens USDC.t
    uint256 constant public tokenAmount3 =     100000000;
    // sends 1 tokens BTC.t, 8 decimals
    uint256 constant public tokenAmount4 =    10000000000000000000;
    // sends 10 tokens wBNB.t
    
    // uint256 constant public tokenAmount1 = 10000000000000000000000;
    // // sends 10,000 tokens USDT.t
    // uint256 constant public tokenAmount2 = 10000000000000000000000;
    // // sends 10,000 tokens USDC.t
    // uint256 constant public tokenAmount3 =     500000000;
    // // sends 5 tokens BTC.t, 8 decimals
    // uint256 constant public tokenAmount4 = 100000000000000000000;
    // // sends 100 tokens wBNB.t
    
    // uint256 constant public tokenAmount5 = 10000000000000000000000;
    // // sends 10,000 tokens t.USDT
    uint256 constant public waitTime = 4320 minutes;
    // can access only after 3 days 

    // Events
    // event ConfirmTransaction1(address indexed _from, address indexed _tokenInstance1, uint _tokenAmount1);
    event ConfirmTransaction1(address indexed account, string message);
    event ConfirmTransaction2(address indexed account, string message);
    event ConfirmTransaction3(address indexed account, string message);
    event ConfirmTransaction4(address indexed account, string message);

    ERC20 public tokenInstance1;
    ERC20 public tokenInstance2;
    ERC20 public tokenInstance3;
    ERC20 public tokenInstance4;
    // ERC20 public tokenInstance5;
    
    mapping(address => uint256) lastAccessTime1;
    mapping(address => uint256) lastAccessTime2;
    mapping(address => uint256) lastAccessTime3;
    mapping(address => uint256) lastAccessTime4;



    constructor (address  _tokenInstance1,address _tokenInstance2,address _tokenInstance3,address _tokenInstance4/*,address _tokenInstance5*/) {
        require(_tokenInstance1 != address(0));
        require(_tokenInstance2 != address(0));
        require(_tokenInstance3 != address(0));
        require(_tokenInstance4 != address(0));
        // require(_tokenInstance5 != address(0));


        tokenInstance1 = ERC20(_tokenInstance1);
        tokenInstance2 = ERC20(_tokenInstance2);
        tokenInstance3 = ERC20(_tokenInstance3);
        tokenInstance4 = ERC20(_tokenInstance4);
        // tokenInstance5 = ERC20(_tokenInstance5);

    }

    function requestTokens1() public {
        require(allowedToWithdraw1(msg.sender),"Action restricted due to Timelock");
        tokenInstance1.transfer(msg.sender, tokenAmount1);
        // tokenInstance2.transfer(msg.sender, tokenAmount2);
        // tokenInstance3.transfer(msg.sender, tokenAmount3);
        // tokenInstance4.transfer(msg.sender, tokenAmount4);
        // tokenInstance5.transfer(msg.sender, tokenAmount5);
        emit ConfirmTransaction1(msg.sender,"User recieved 10,000 USDT.t");
        lastAccessTime1[msg.sender] = block.timestamp + waitTime;
    }

     function requestTokens2() public {
        require(allowedToWithdraw2(msg.sender),"Action restricted due to Timelock");
        // tokenInstance1.transfer(msg.sender, tokenAmount1);
        tokenInstance2.transfer(msg.sender, tokenAmount2);
        // tokenInstance3.transfer(msg.sender, tokenAmount3);
        // tokenInstance4.transfer(msg.sender, tokenAmount4);
        // tokenInstance5.transfer(msg.sender, tokenAmount5);
        emit ConfirmTransaction2(msg.sender,"User recieved 10,000 USDC.t");
        lastAccessTime2[msg.sender] = block.timestamp + waitTime;
    }
     function requestTokens3() public {
        require(allowedToWithdraw3(msg.sender),"Action restricted due to Timelock");
        // tokenInstance1.transfer(msg.sender, tokenAmount1);
        // tokenInstance2.transfer(msg.sender, tokenAmount2);
        tokenInstance3.transfer(msg.sender, tokenAmount3);
        // tokenInstance4.transfer(msg.sender, tokenAmount4);
        // tokenInstance5.transfer(msg.sender, tokenAmount5);
        emit ConfirmTransaction3(msg.sender,"User recieved 5 BTC.t");


        lastAccessTime3[msg.sender] = block.timestamp + waitTime;
    }
     function requestTokens4() public {
        require(allowedToWithdraw4(msg.sender),"Action restricted due to Timelock");
        // tokenInstance1.transfer(msg.sender, tokenAmount1);
        // tokenInstance2.transfer(msg.sender, tokenAmount2);
        // tokenInstance3.transfer(msg.sender, tokenAmount3);
        tokenInstance4.transfer(msg.sender, tokenAmount4);
        // tokenInstance5.transfer(msg.sender, tokenAmount5);
        emit ConfirmTransaction4(msg.sender,"User recieved 100 wBNB.t");

        lastAccessTime4[msg.sender] = block.timestamp + waitTime;
    }

    function allowedToWithdraw1(address _address) public view returns (bool) {
        if(lastAccessTime1[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime1[_address]) {
            return true;
        }
        return false;
    }

    function allowedToWithdraw2(address _address) public view returns (bool) {
        if(lastAccessTime2[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime2[_address]) {
            return true;
        }
        return false;
    }

    function allowedToWithdraw3(address _address) public view returns (bool) {
        if(lastAccessTime3[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime3[_address]) {
            return true;
        }
        return false;
    }

    function allowedToWithdraw4(address _address) public view returns (bool) {
        if(lastAccessTime4[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime4[_address]) {
            return true;
        }
        return false;
    }
}


