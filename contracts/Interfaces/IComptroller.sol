// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;
interface IComptroller {
    function getAPR(bytes32 commitment_) external view returns (uint);
    function getAPR(bytes32 commitment_, uint index_) external view returns (uint);
    function getAPY(bytes32 commitment_) external view returns (uint);
    function getAPY(bytes32 commitment_, uint index_) external view returns (uint);
    function getApytime(bytes32 commitment_, uint index_) external view returns (uint);
    function getAprtime(bytes32 commitment_, uint index_) external view returns (uint);
    function getApyTimeLength(bytes32 commitment_) external view returns (uint);
    function getAprTimeLength(bytes32 commitment_) external view returns (uint);
    function getApyLastTime(bytes32 commitment_) external view returns (uint);
    function getAprLastTime(bytes32 commitment_) external view returns (uint);
    function getCommitment(uint index_) external view returns (bytes32);
    function liquidationTrigger() external;
    function updateAPY(bytes32 commitment_, uint apy_) external returns (bool);
    function updateAPR(bytes32 commitment_, uint apr_) external returns (bool );
    function updateLoanIssuanceFees() external;
    function updateLoanClosureFees() external;
    function updateLoanpreClosureFees() external;
    function updateDepositPreclosureFees() external;
    function updateSwitchDepositTypeFee() external;
    function updateReserveFactor() external;
    function updateMaxWithdrawal() external;
    function calcAPY(bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) external view;
    function calcAPR(bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) external view;
    function getReserveFactor() external view returns (uint256);
    function setCommitment(bytes32 _commitment) external;
}