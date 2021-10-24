// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "../util/IBEP20.sol";

interface IReserve {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
    function avblMarketReserves(bytes32 _market) external view returns (uint);
    function marketReserves(bytes32 _market) external view returns(uint);
    function marketUtilisation(bytes32 _market) external view returns(uint);
    function setLoanAddress(address loanAddr_) external;
    function collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) external;
    function pause() external;
    function unpause() external;
}
