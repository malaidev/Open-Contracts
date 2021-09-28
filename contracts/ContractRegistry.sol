// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./TokenList.sol";
import "./Passbook.sol";
import "./Comptroller.sol";
import "./Deposit.sol";
import "./Loan.sol";
import "./Liquidator.sol";
import "./Reserve.sol";

contract ContractRegistry {




  constructor() public {
  }
}


//  token.Address()

struct contractMapping  {
  string contractName;
  address contractAddress;
}

mapping()