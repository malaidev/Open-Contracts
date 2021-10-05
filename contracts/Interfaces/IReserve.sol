// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
interface IReserve {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
}