// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IAccessRegistry{
    function transferAnyBEP20(address token_,address recipient_,uint256 value_) external returns(bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function addRole(bytes32 role, address account) external;
    function removeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function transferRole(bytes32 role, address oldAccount, address newAccount) external;
    function hasAdminRole(bytes32 role, address account) external view returns (bool);
    function addAdminRole(bytes32 role, address account) external;
    function removeAdminRole(bytes32 role, address account) external;
    function adminRoleTransfer(bytes32 role, address oldAccount, address newAccount) external;
    function adminRoleRenounce(bytes32 role, address account) external;
    function pause() external;
    function unpause() external;
}