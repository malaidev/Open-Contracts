// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;
interface IComptroller {
    function getAPR() external view returns (uint);
    function getAPR(bytes32 commitment_) external view returns (uint);
    function getAPR(bytes32 commitment_, uint index_) external view returns (uint);
    function getAPY() external view returns (uint);
    function getAPY(bytes32 commitment_) external view returns (uint);
    function getAPY(bytes32 commitment_, uint index_) external view returns (uint);
    function getApyBlockNumber(bytes32 commitment_, uint index_) external view returns (uint);
    function getAprBlockNumber(bytes32 commitment_, uint index_) external view returns (uint);
    function getApyRecordCount(bytes32 commitment_) external view returns (uint);
    function getAprRecordCount(bytes32 commitment_) external view returns (uint);
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
}