// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
interface IComptroller {
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
    function getAPR(bytes32 commitment_) external view returns (uint);
    function getAPRInd(bytes32 _commitment, uint index) external view returns (uint);
    function getAPY(bytes32 _commitment) external view returns (uint);
    function getAPYInd(bytes32 _commitment, uint _index) external view returns (uint);
    function getApytimeber(bytes32 _commitment, uint _index) external view returns (uint);
    function getAprtimeber(bytes32 _commitment, uint _index) external view returns (uint);
    function getApyLastTime(bytes32 commitment_) external view returns (uint);
    function getAprLastTime(bytes32 commitment_) external view returns (uint);
    function getApyTimeLength(bytes32 commitment_) external view returns (uint);
    function getAprTimeLength(bytes32 commitment_) external view returns (uint);
    function getCommitment(uint index_) external view returns (bytes32);
    function setCommitment(bytes32 _commitment) external;
    function liquidationTrigger(uint loanID) external;
    function updateAPY(bytes32 _commitment, uint _apy) external returns (bool);
    function updateAPR(bytes32 _commitment, uint _apr) external returns (bool);
    function calcAPR(bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) external view;
    function calcAPY(bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) external view;
    function updateLoanIssuanceFees(uint fees) external returns(bool success);
    function updateLoanClosureFees(uint fees) external returns (bool success);
    function updateLoanPreClosureFees(uint fees) external returns (bool success);
    function updateDepositPreclosureFees(uint fees) external returns(bool success);
    function updateWithdrawalFees(uint fees) external returns(bool success);
    function updateCollateralReleaseFees(uint fees) external returns(bool success);
    function updateYieldConversion(uint fees) external returns (bool success);
    function updateMarketSwapFees(uint fees) external returns (bool success);
    function updateReserveFactor(uint _reserveFactor) external returns (bool success);
    function updateMaxWithdrawal(uint factor, uint blockLimit) external returns (bool success);
    function getReserveFactor() external view returns (uint256);
    function pause() external;
    function unpause() external;
}