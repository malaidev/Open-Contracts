// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// import "../util/IBEP20.sol";
// import "./ITokenList.sol";
// import "./ILoan.sol";

interface IOracleOpen {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
    function getLatestPrice(address _addrMarket) external view returns (uint);
    function liquidationTrigger(address account, uint loanId) external;
    function setLoanAddress(address _loanAddress) external;
    function pause() external;
    function unpause() external;
}