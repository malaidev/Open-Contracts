// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./util/Pausable.sol";
import "./interfaces/IAccessRegistry.sol";
struct RoleData {
    mapping(address => bool) _members;
    bytes32 _role;
}
struct AdminRoleData {
    mapping(address => bool) _adminMembers;
    bytes32 _adminRole;
}
contract AccessRegistry is Pausable, IAccessRegistry {
	mapping(bytes32 => RoleData) roles;
	mapping(bytes32 => AdminRoleData) adminRoles;
	bytes32 superAdmin;

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
	constructor(address upgradeAdmin) {
		// AppStorageOpen storage ds = LibOpen.diamondStorage();
		superAdmin = 0x72b5b8ca10202b2492d7537bf1f6abcda23a980f7acf51a1ec8a0ce96c7d7ca8;
		adminRoles[superAdmin]._adminMembers[upgradeAdmin] = true;

		addAdminRole(superAdmin, address(this));
	}

	// receive() external payable {
	// 	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
	//     payable(ds.upgradeAdmin).transfer(msg.value);
	// }
	// fallback() external payable {
	// 	AppStorageOpen storage ds = LibOpen.diamondStorage(); 
	//     payable(ds.upgradeAdmin).transfer(msg.value);
	// }
	function hasRole(bytes32 role, address account) public view override returns (bool) {
		return roles[role]._members[account];
	}
	function addRole(bytes32 role, address account) public override onlyAdmin {
		require(!hasRole(role, account), "Role already exists. Please create a different role");
		roles[role]._members[account] = true;
		emit RoleGranted(role, account, msg.sender);
	}
	function removeRole(bytes32 role, address account) external override onlyAdmin {
		require(hasRole(role, account), "Role does not exist.");
		revokeRole(role, account);
	}
	function renounceRole(bytes32 role, address account) external override nonReentrant() {
		require(hasRole(role, account), "Role does not exist.");
		require(_msgSender() == account, "Inadequate permissions");
		revokeRole(role, account);
	}
	function revokeRole(bytes32 role, address account) private {
		roles[role]._members[account] = false;
		emit RoleRevoked(role, account, msg.sender);
	}
	function transferRole(
		bytes32 role,
		address oldAccount,
		address newAccount
	) external override nonReentrant() {
		require(
				hasRole(role, oldAccount) && _msgSender() == oldAccount,
				"Role does not exist."
		);
		revokeRole(role, oldAccount);
		addRole(role, newAccount);
	}
	function hasAdminRole(bytes32 role, address account) public view override returns (bool) {
		return adminRoles[role]._adminMembers[account];
	}
	function addAdminRole(bytes32 role, address account) public override onlyAdmin {
		require(
				!hasAdminRole(role, account),
				"Role already exists. Please create a different role"
		);
		adminRoles[role]._adminMembers[account] = true;
		emit AdminRoleDataGranted(role, account, msg.sender);
	}
	function removeAdminRole(bytes32 role, address account) external override onlyAdmin {
		require(hasAdminRole(role, account), "Role does not exist.");
		revokeAdmin(role, account);
	}
	function revokeAdmin(bytes32 role, address account) private {
		adminRoles[role]._adminMembers[account] = false;
		emit AdminRoleDataRevoked(role, account, msg.sender);
	}
	function adminRoleTransfer(
		bytes32 role,
		address oldAccount,
		address newAccount 
	) external override onlyAdmin
	{
		require(
				hasAdminRole(role, oldAccount),
				"Role already exists. Please create a different role"
		);
		revokeAdmin(role, oldAccount);
		addAdminRole(role, newAccount);
	}
	function adminRoleRenounce(bytes32 role, address account) external override onlyAdmin {
		require(hasAdminRole(role, account), "Role does not exist.");
		require(_msgSender() == account, "Inadequate permissions");
		revokeAdmin(role, account);
	}
	
	modifier onlyAdmin {
		require(hasAdminRole(superAdmin, msg.sender), "ERROR: Not an admin");
		_;
	}
	function pauseAccessRegistry() external override onlyAdmin() nonReentrant() {                                                                                                  
		_pause();
	}
	
	function unpauseAccessRegistry() external override onlyAdmin() nonReentrant() {
		_unpause();   
	}
	function isPausedAccessRegistry() external view override virtual returns (bool) {                                                                                                                                                                                                                                                               
		return _paused();
	}
}