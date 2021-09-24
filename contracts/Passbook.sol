// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import './Comptroller.sol';
import './TokenList.sol';


contract Passbook   {

    bytes32[] commitment;
    bytes32[] markets;
    struct Savings  {
        uint accountCreationTime; // time at which the account is opened.
        DepositRecords[] deposits; // An array of deposit structs.
    }

    struct DepositRecords   {
        uint firstDeposit; //block.timestamp at the time of deposit.
        bytes32 market; // token deposited
        bytes32 _commitment; // commitment period.
        uint lastDeposit; //block.timestamp at the time of deposit.
        bool depositExists; //block.timestamp at the time of deposit.
    }
    mapping(address => Savings) savingsPassbook;    
    mapping(bytes32 => mapping(bytes32 => DepositRecords)) indDepositRecords; // this mapping allows to pull deposits of individual commitment kind.

    event NewDeposit(address indexed account, bytes32 indexed market, uint indexed amount, bytes32 commitment);
    
    

}