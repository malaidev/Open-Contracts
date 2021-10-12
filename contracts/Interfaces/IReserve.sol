// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "../util/IBEP20.sol";

interface IReserve {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
}