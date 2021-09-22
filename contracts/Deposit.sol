// SPDX-License-Identifier: MIT
<<<<<<< HEAD
pragma solidity >=0.4.22 <0.9.0;

contract Deposit {
  constructor() public {
  }
}
=======

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Library/GlobalLibrary.sol";

contract Deposit is Ownable{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     modifier acceptable(address token) {
        require(
            supportedAsset[token] > 1, 
            "no acceptable token"
        );
        _;
    }
    // Info of each user.
    struct UserPassBook {
        uint256 depositAmount;     
        address depositAssetType; 
        GlobalLibrary.DepositType depositType;
        uint256 minimumCommitment; 
    }

    
    mapping (address => UserPassBook) public userInfo;

    // Address of the ERC20 Token contract.
    ERC20 public depositAsset;


    // Info of supported asset
     mapping (address => uint256) public supportedAsset;

   

    constructor () {
        supportedAsset[GlobalLibrary.BNB] = 1;
        supportedAsset[GlobalLibrary.USDC] = 100;
        supportedAsset[GlobalLibrary.STACK] = 100;

    }

    function deposit(address _assetType, uint256 _amount, GlobalLibrary.DepositType _depositType) public acceptable(_assetType) {
        depositAsset = ERC20(_assetType);
        uint256 assetDecimal = depositAsset.decimals();
        require(_amount.div(assetDecimal) > supportedAsset[_assetType] * 10, "User should deposit more that minimum deposit amount" );
        UserPassBook storage user = userInfo[msg.sender];
        
        if(user.depositAmount > 0)
        {
            user.depositAmount  = user.depositAmount.add(_amount);
        }
        user.depositAssetType = _assetType;
        user.depositType = _depositType;
        if(_depositType == GlobalLibrary.DepositType.FIXED)
            user.minimumCommitment = 6;
        else
            user.minimumCommitment = 0;


    }
    function updateUserPassBook() public {

    }
    function calculateYield(address _user) external view returns (uint256) {

    } 
    function updateYield() public {

    }
    function calimDividend() public {

    }
    function Pause() public {

    }


}
>>>>>>> staging
