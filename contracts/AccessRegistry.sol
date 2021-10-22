// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./util/Address.sol";
import "./util/Pausable.sol";
import "./mockup/IMockBep20.sol";

contract AccessRegistry is Pausable {
    using Address for address;

    address public adminAddress;
    bytes32 internal adminAccess;

    struct RoleData {
        mapping(address => bool) _members;
        bytes32 _role;
    }

    struct AdminRoleData {
        mapping(address => bool) _adminMembers;
        bytes32 _adminRole;
    }

    mapping(bytes32 => RoleData) internal _roles;
    mapping(bytes32 => AdminRoleData) internal _adminRoles;

    event AdminRoleDataGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event AdminRoleDataRevoked(
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

    constructor(
        address account_, 
        address tokenListAddr_,
        address comptrollerAddr_,
        address reserveAddr_,
        address depositAddr_,
        address oracleAddr_,
        address loanAddr_,
        address liquidatorAddr_
    ) 
    {
        adminAddress = account_;
        adminAccess = keccak256("AccessRegistry.adminAccess");
        _addAdminRole(adminAccess, adminAddress);
        _addAdminRole(keccak256("tokenList"), tokenListAddr_);
        _addAdminRole(keccak256("comptroller"), comptrollerAddr_);
        _addAdminRole(keccak256("reserve"), reserveAddr_);
        _addAdminRole(keccak256("deposit"), depositAddr_);
        _addAdminRole(keccak256("oracle"), oracleAddr_);
        _addAdminRole(keccak256("loan"), loanAddr_);
        _addAdminRole(keccak256("liquidator"), liquidatorAddr_);
    }
    
    receive() external payable {
        payable(adminAddress).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminAddress).transfer(_msgValue());
    }
    
    function transferAnyERC20(address token_,address recipient_,uint256 value_) external returns(bool) {
        IMockBep20(token_).transfer(recipient_, value_);
        return true;
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

    function addAdminRole(bytes32 role, address account)
        external
        onlyAdmin(adminAccess, adminAddress)
    {
        require(
            !_hasAdminRole(role, account),
            "Role already exists. Please create a different role"
        );
        _addAdminRole(role, account);
    }

    function removeAdminRole(bytes32 role, address account)
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
    ) 
        external onlyAdmin(adminAccess, adminAddress) 
    {
        require(
            _hasAdminRole(role, oldAccount),
            "Role already exists. Please create a different role"
        );

        _revokeAdmin(role, oldAccount);
        _addAdminRole(role, newAccount);
    }

    function adminRoleRenounce(bytes32 role, address account)
        external 
        onlyAdmin(adminAccess, adminAddress)
    {
        require(_hasAdminRole(role, account), "Role does not exist.");
        require(_msgSender() == account, "Inadequate permissions");

        _revokeAdmin(role, account);
    }
    
    function _hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return _roles[role]._members[account];
    }

    function _addRole(bytes32 role, address account) internal {
        _roles[role]._members[account] = true;
        emit RoleGranted(role, account, _msgSender());
    }
    
    function _revokeRole(bytes32 role, address account) internal {
        _roles[role]._members[account] = false;
        emit RoleRevoked(role, account, _msgSender());
    }

    function _hasAdminRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return _adminRoles[role]._adminMembers[account];
    }

    function _addAdminRole(bytes32 role, address account) internal {
        _adminRoles[role]._adminMembers[account] = true;
        emit AdminRoleDataGranted(role, account, _msgSender());
    }

    function _revokeAdmin(bytes32 role, address account) internal {
        _adminRoles[role]._adminMembers[account] = false;
        emit AdminRoleDataRevoked(role, account, _msgSender());
    }

    modifier onlyAdmin(bytes32 role, address account) {
        require(_hasAdminRole(role, account), "Role does not exist.");
        _;
    }

    function pause() external authAccessRegistry() nonReentrant() {
       _pause();
	}
	
	function unpause() external authAccessRegistry() nonReentrant() {
       _unpause();   
	}

	modifier authAccessRegistry() {
		require(
			msg.sender == adminAddress,
			"Only AccessRegistry admin can call this function"
		);
		_;
	}
}