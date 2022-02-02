// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Context.sol";
import "../util/Address.sol";
import "../util/IERC20.sol";

contract tCake is Context{
    using Address for address;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;
    uint256 cappedSupply;

    address admin;

    bool isReentrant = false;
    bool isPaused = false;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    event PauseState(address indexed _pauser, bool isPaused);

    constructor(address admin_) {
        name = "CAKE";
        symbol = "CAKE.t";
        decimals = 18;
        totalSupply = 2600000000000000000000000000;
        admin = admin_;
        cappedSupply = 50000000000000000000000000;

        mint(admin, 10000000000000000000000000);
    }

    receive() external payable {
        payable(admin).transfer(_msgValue());
    }

    fallback() external payable {
        payable(admin).transfer(_msgValue());
    }


    function transferAnyERC20(address token_,address recipient_,uint256 _value_) external auth() nonReentrant() returns(bool)   {
        IERC20(token_).transfer(recipient_, _value_);

        return true;
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return _balances[_addr];
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining)    {
        return _allowances[_owner][_spender];
    }

    function pauseState() public view returns (string memory) {
        if (isPaused == true) {
            return "Contract is paused. Token transfers are temporarily disabled.";
        }
        return "Contract is not paused";
    }

    function pause() external auth() nonReentrant() {
        _pause();
    }

    function unpause() external auth() nonReentrant() {
        _unpause();
    }

    function transfer(address _to, uint256 _value) external nonReentrant() returns (bool) {
        _checkPauseState();
        _transfer(_msgSender(), _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external nonReentrant() returns (bool) {
        _checkPauseState();
        _approve(_spender, _value);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _value) external nonReentrant() returns (bool) {
        _checkPauseState();
        require (_allowances[_from][_msgSender()] >= _value && _balances[_from] >= _value, "Insufficient balance, or allowance");
        
        _allowances[_from][_msgSender()] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _value) external nonReentrant() returns(bool) {
        _checkPauseState();
        if (_allowances[_msgSender()][_spender] == 0)   {
            _approve(_spender, _value);
        }
        _allowances[_msgSender()][_spender] += _value;
        
        emit Approval(_msgSender(), _spender, _value);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _value) external nonReentrant() returns(bool) {
        _checkPauseState();
        require(_allowances[_msgSender()][_spender]>=0, "Decrease value > allowance");

        _allowances[_msgSender()][_spender] -= _value;
        
        emit Approval(_msgSender(), _spender, _value);

        return true;
    }

    // This works too
    function mint(address _to, uint256 _value) public auth() nonReentrant() {
        _checkPauseState();
        require(totalSupply <= cappedSupply && _value != 0 && _to != address(0),"Token mint is not possible");
        _balances[_to] += _value;
        totalSupply += _value;

        emit Transfer(address(0), _to, _value);
    }

    function burn(address _addr, uint256 _value) public auth() nonReentrant()    {
        _checkPauseState();
        require(_addr != address(0),"You can not burn tokens from this address");

        _balances[_addr] -= _value;
        totalSupply -= _value;
        
        emit Transfer(_addr, address(0), _value);
    }

    function _checkPauseState() internal view {
        require(isPaused == false,"The contract is paused. Transfer functions are temporarily disabled");
    }

    function _pause() internal auth() {
        require(isPaused == false, "This contract is already paused");
        isPaused = true;

        emit PauseState(_msgSender(), true);
    }

    function _unpause() internal auth() {
        require(isPaused == true, "This contract is already paused");
        isPaused = false;

        emit PauseState(_msgSender(), false);
    }
    
    function _transfer(address sender, address recipient, uint256 _value) private {
        require(recipient != address(0) && _balances[sender] >= _value, "You can not send funds to zero address; Or, insufficient balance");

        _balances[sender] -= _value;
        _balances[recipient] += _value;

        emit Transfer(sender, recipient, _value);
    }

    function _approve(address _spender, uint256 _value) private {
        
        _allowances[_msgSender()][_spender] = 0;
        
        require(_balances[_msgSender()] >= _value && _spender != address(0), "Zero address can not be used in a transfer; or, Insufficient balance");
        _allowances[_msgSender()][_spender] = _value;

        emit Approval(_msgSender(), _spender, _value);        
    }

    modifier nonReentrant() {
        require(isReentrant == false, "Re-entrant alert!");
        isReentrant = true;
        _;
        isReentrant = false;
    }

    modifier auth() {
        require(_msgSender() == admin, "Inadequate permission");
        _;
    }
}