// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

contract Comptroller {


struct Passbook {
  address customerAddress;
  uint timestamp;
  mapping(KIND => mapping(CATEGORY => bytes32)) newEntry; // mapping(DEPOSIT => mapping(FLEXILBE => validity[0]));
}

struct NewEntry {
  address customerAddress;
  uint timestamp;
}

struct Collateral	{	
  address address_;
  uint timestamp;
  // mapping(uint => bool) collateral check; entryRegistry.amount => false/true;
  mapping(uint => mapping(bool => uint)) collateralUpdated;  //if bool true, add timestamp.
}

NewEntry[] entries;

enum KIND {DEPOSIT, LOAN}
enum CATEGORY { FLEXIBLE, FIXED}

bytes32[] validity; // ZERO, TWOWEEKS, ONEMONTH, THREEMONTHS.

  constructor() public {
  }
}
