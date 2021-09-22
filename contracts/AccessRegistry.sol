// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <0.9.0;

import "./util/Context.sol";
import "./util/Address.sol";

contract AccessRegistry is Context {
    using Address for address;

    address public adminAddress;
    bytes32 private adminAccess;

    struct RoleData {
        mapping(bytes32 => address) _roleRegistry; //mapping of all roles & addresses
        mapping(bytes32 => uint256) _indexes;
        bytes32[] _roleList;
    }

    struct AdminRegistry {
        mapping(bytes32 => address) _adminRegistry;
        mapping(bytes32 => uint256) _adminIndex;
        bytes32[] _adminRoleList;
    }

    mapping(address => RoleData) private _roles;
    mapping(address => AdminRegistry) private _adminRoles;

    event AdminRoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event AdminRoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    constructor(address account_) {
        adminAddress = account_;
        _addAdmin(adminAccess, adminAddress);
    }
    receive() external payable {
        payable(adminAddress).transfer(_msgValue());
    }
    fallback() external payable {
        payable(adminAddress).transfer(_msgValue());
    }

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return _hasRole(role, account);
    }

    function addRole(bytes32 role, address account)
        external
        onlyAdmin(adminAccess, adminAddress)
    {
        require(
            !_hasRole(role, account),
            "Role already exists. Please create a different role"
        );
        _addRole(role, account);
    }

    function removeRole(bytes32 role, address account)
        external
        onlyAdmin(adminAccess, adminAddress)
    {
        require(_hasRole(role, account), "Role does not exist.");

        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) external {
        require(_hasRole(role, account), "Role does not exist.");
        require(_msgSender() == account, "Inadequate permissions");

        _revokeRole(role, account);
    }

    function transferRole(
        bytes32 role,
        address oldAccount,
        address newAccount
    ) external {
        require(
            _hasRole(role, oldAccount) && _msgSender() == oldAccount,
            "Role does not exist."
        );

        _revokeRole(role, oldAccount);
        _addRole(role, newAccount);
    }

    function hasAdminRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return _hasAdminRole(role, account);
    }

    function addAdmin(bytes32 role, address account)
        external
        onlyAdmin(adminAccess, adminAddress)
    {
        require(
            !_hasAdminRole(role, account),
            "Role already exists. Please create a different role"
        );
        _addAdmin(role, account);
    }

    function removeAdmin(bytes32 role, address account)
        external
        onlyAdmin(adminAccess, adminAddress)
    {
        require(_hasAdminRole(role, account), "Role does not exist.");

        _revokeAdmin(role, account);
    }

    function adminRoleTransfer(
        bytes32 role,
        address oldAccount,
        address newAccount
    ) external onlyAdmin(adminAccess, adminAddress) {
        require(
            _hasAdminRole(role, oldAccount),
            "Role already exists. Please create a different role"
        );

        _revokeAdmin(role, oldAccount);
        _addAdmin(role, newAccount);
    }

    function _hasRole(bytes32 role, address account)
        private
        view
        returns (bool)
    {
        if (_roles[account]._indexes[role] != 0) {
            return true;
        }
        return false;
    }

    function _addRole(bytes32 role, address account) private {
        _roles[account]._roleRegistry[role] = account;
        _roles[account]._roleList.push(role);
        _roles[account]._indexes[role] = _roles[account]._roleList.length;

        emit RoleGranted(role, account, _msgSender());
    }

    function _revokeRole(bytes32 role, address account) private {
        delete _roles[account]._roleRegistry[role];

        uint256 _value = _roles[account]._indexes[role];
        uint256 _toDeleteIndex = _value - 1;

        uint256 _lastValue = _roles[account]._roleList.length;
        uint256 _lastValueIndex = _lastValue - 1;

        bytes32 lastRole = _roles[account]._roleList[_lastValueIndex];

        _roles[account]._roleList[_toDeleteIndex] = lastRole; // Index assignment
        _roles[account]._indexes[lastRole] = _toDeleteIndex + 1;

        _roles[account]._roleList.pop();
        delete _roles[account]._indexes[role];

        emit RoleRevoked(role, account, _msgSender());
    }

    function _hasAdminRole(bytes32 role, address account)
        private
        view
        returns (bool)
    {
        if (_adminRoles[account]._adminIndex[role] != 0) {
            // if (_adminRoles[account]._adminIndex[role]!=0)  {
            return true;
        }
        return false;
    }

    function _addAdmin(bytes32 role, address account) internal {
        _adminRoles[account]._adminRegistry[role] = account;
        _adminRoles[account]._adminRoleList.push(role);

        _adminRoles[account]._adminIndex[role] = _adminRoles[account]
            ._adminRoleList
            .length;

        emit AdminRoleGranted(role, account, _msgSender());
    }

    function _revokeAdmin(bytes32 role, address account) private {
        delete _adminRoles[account]._adminRegistry[role];

        uint256 _value = _adminRoles[account]._adminIndex[role];
        uint256 _toDeleteIndex = _value - 1;

        uint256 _lastValue = _adminRoles[account]._adminRoleList.length;
        uint256 _lastValueIndex = _lastValue - 1;

        bytes32 lastRole = _adminRoles[account]._adminRoleList[_lastValueIndex];

        _adminRoles[account]._adminRoleList[_toDeleteIndex] = lastRole; // Index assignment

        _adminRoles[account]._adminIndex[lastRole] = _toDeleteIndex + 1;

        _adminRoles[account]._adminRoleList.pop();
        delete _adminRoles[account]._adminIndex[role];

        emit AdminRoleRevoked(role, account, _msgSender());
    }

    modifier onlyAdmin(bytes32 role, address account) {
        require(_hasAdminRole(role, account), "Role does not exist.");
        _;
    }
}
