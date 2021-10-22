// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./util/Pausable.sol";
import "./interfaces/ITokenList.sol";
import "./mockup/IMockBep20.sol";
import "./interfaces/IComptroller.sol";


contract Deposit is Pausable{
	
	bytes32 adminDeposit;
	address adminDepositAddress;
	address superAdminAddress;
	address reserveAddress;

	ITokenList markets;
	IComptroller comptroller;

	IMockBep20 public 	token;

	struct SavingsAccount {
        uint accOpenTime;
        address account; 
        DepositRecords[] deposits;
        YieldLedger[] yield;
    }

    struct DepositRecords   {
        uint id;
        bytes32 market;
        bytes32 commitment;
        uint amount;
        uint lastUpdate;
    }

    struct YieldLedger    {
        uint id;
        bytes32 market; //_market this yield is calculated for
        uint oldLengthAccruedYield; // length of the APY time array.
        uint oldTime; // last recorded block num. This is when this struct is lastly updated.
        uint accruedYield; // accruedYield in 
        bool isTimelockApplicable; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        uint timelockValidity; // timelock duration
        uint activationTime; // block.timestamp(isTimelockActivated) + timelockValidity.
    }

	enum SAVINGSTYPE{DEPOSIT, YIELD, BOTH}
	
	mapping(address => SavingsAccount) savingsPassbook;  // Maps an account to its savings Passbook
    mapping(address => mapping(bytes32 => mapping(bytes32 => DepositRecords))) indDepositRecord; // address =>_market => _commitment => depositRecord
    mapping(address => mapping(bytes32 => mapping(bytes32 => YieldLedger))) indYieldRecord; // address =>_market => _commitment => depositRecord

	///  Balance monitoring  - Deposits
	mapping(bytes32 => uint) marketReserves; // mapping(market => marketBalance)
	mapping(bytes32 => uint) marketUtilisation; // mapping(market => marketBalance)

	event NewDeposit(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event DepositAdded(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event YieldDeposited(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event Withdrawal(address indexed account, bytes32 indexed market, uint indexed amount, bytes32 commitment, uint timestamp);


	constructor(
		address _superAdminAddr,
		address _tokenListAddr,
		address _comptrollerAddr
	) 
	{
		superAdminAddress = _superAdminAddr;
		adminDepositAddress = msg.sender;
		markets = ITokenList(_tokenListAddr);
		comptroller = IComptroller(_comptrollerAddr);
	}

	function hasAccount(address _account) external view returns (bool)	{
		_hasAccount(_account);
		return true;
	}

	function savingsBalance(bytes32 _market, bytes32 _commitment) external returns (uint) {
		return _accountBalance(msg.sender, _market, _commitment, SAVINGSTYPE.BOTH);
	}

	function convertYield(bytes32 _market, bytes32 _commitment) external nonReentrant() returns (bool success){
		
		uint _amount;
		_convertYield(msg.sender, _market,_commitment, _amount);

		emit YieldDeposited(msg.sender, _market, _commitment, _amount);
		return success;
	}

	function hasYield(bytes32 _market, bytes32 _commitment) external view returns (bool)	{
		YieldLedger storage yield = indYieldRecord[msg.sender][_market][_commitment];
		
		_hasYield(yield);
		return true;
	}


	function avblReserves(bytes32 _market) external view returns(uint){
		return marketReserves[_market];
	}

	// function _avblReserves(bytes32 _market) internal view returns(uint)	{
	// 	return marketReserves[_market];
	// }

	function utilisedReserves(bytes32 _market) external view returns(uint)	{
		return _utilisedReserves(_market);
	}
	function _utilisedReserves(bytes32 _market) internal view returns(uint)	{
		return marketUtilisation[_market];
	}


	function _updateReserves(bytes32 _market, uint _amount, uint _num) private
	{
		if (_num == 0)	{
			marketReserves[_market] += _amount;
		} else if (_num == 1)	{
			marketReserves[_market] -= _amount;
		}
	}

	function _updateUtilisation(bytes32 _market, uint _amount, uint _num) private 
	{
		if (_num == 0)	{
			marketUtilisation[_market] += _amount;
		} else if (_num == 1)	{
			marketUtilisation[_market] -= _amount;
		}
	}

	function hasDeposit(bytes32 _market, bytes32 _commitment) external view {
		_hasDeposit(msg.sender,_market, _commitment);
	}
	function _hasDeposit(address _account, bytes32 _market, bytes32 _commitment) internal view returns(bool) {
		require (indDepositRecord[_account][_market][_commitment].id != 0, "ERROR: No deposit");
		return true;
	}

	
	function createDeposit(
		bytes32 _market,
		bytes32 _commitment,
		uint256 _amount
	) external nonReentrant(){
		
		_createNewDeposit(_market,_commitment, _amount);

		emit NewDeposit(msg.sender, _market, _commitment, _amount);
	}


	function withdrawDeposit (bytes32 _market, bytes32 _commitment, uint _amount, SAVINGSTYPE _request) external nonReentrant() returns (bool success){

		_withdrawDeposit (msg.sender, _market, _commitment, _amount, _request);

		emit Withdrawal(msg.sender,_market, _amount, _commitment, block.timestamp);
		return success;
		
	}


	function _withdrawDeposit (address _account, bytes32 _market, bytes32 _commitment, uint _amount, SAVINGSTYPE _request) internal{
		
		_hasAccount(_account);
		markets.isMarketSupported(_market);

		// DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		// YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		_accruedYield(msg.sender,_market,_commitment);

		uint _savingsBalance = _accountBalance(_account, _market, _commitment, _request);

		require(_amount >= _savingsBalance, "Insufficient balance");
		if (_commitment == comptroller.getCommitment(0))	{
			_updateSavingsBalance(_account, _market, _commitment, _amount, _request);
		}
		/// Transfer funds to the user's wallet.
		address retAddr = markets.connectMarket(_market);
		token = IMockBep20(retAddr);
		token.transfer(reserveAddress, _amount);

		_updateReserves(_market, _amount, 1);

	}

	// function convertDeposit() external nonReentrant() {}

	function _preDepositProcess(
		bytes32 _market,
		uint256 _amount
		// SavingsAccount memory savingsAccount
	) private {

		markets.isMarketSupported(_market);
		
		address retAddr = markets.connectMarket(_market);
		token = IMockBep20(retAddr);
		markets.quantifyAmount(_market, _amount);
		markets.minAmountCheck(_market, _amount);
	}

	function _ensureSavingsAccount(address _account, SavingsAccount storage savingsAccount) private {

		if (savingsAccount.accOpenTime == 0) {

			savingsAccount.accOpenTime = block.timestamp;
			savingsAccount.account = _account;
		}
	}

	function _accruedYield(address _account,bytes32 _market,bytes32 _commitment) internal {
		
		_hasDeposit(_account, _market, _commitment);

		uint256 aggregateYield;

		SavingsAccount storage savingsAccount = savingsPassbook[_account];
		DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		comptroller.calcAPY(_commitment, yield.oldLengthAccruedYield, yield.oldTime, aggregateYield);

		aggregateYield *= deposit.amount;

		yield.accruedYield += aggregateYield;
		savingsAccount.yield[deposit.id-1].accruedYield += aggregateYield;

	}

	function _processNewDeposit(
		// address _account,
		bytes32 _market,
		bytes32 _commitment,
		uint256 _amount,
		SavingsAccount storage savingsAccount,
		DepositRecords storage deposit,
		YieldLedger storage yield
	) internal {
		// SavingsAccount storage savingsAccount = savingsPassbook[_account];
		// DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		// YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		uint256 id;

		if (savingsAccount.deposits.length == 0) {
				id = 1;
			} else {
				id = savingsAccount.deposits.length + 1;
		}

		deposit.id = id;	
		deposit.market =_market;
		deposit.commitment = _commitment;
		deposit.amount = _amount;
		deposit.lastUpdate =  block.timestamp;

		if (_commitment != comptroller.getCommitment(0)) {

			yield.id=  id;
			yield.market=_market;
			yield.oldLengthAccruedYield = comptroller.getApyTimeLength(_commitment);
			yield.oldTime = block.timestamp;
			yield.accruedYield = 0;
			yield.isTimelockApplicable = true;
			yield.isTimelockActivated=  false;
			yield.timelockValidity = 86400;
			yield.activationTime = 0;

		} else if (
			_commitment == comptroller.getCommitment(0)) {


			yield.id=  id;
			yield.market=_market;
			yield.oldLengthAccruedYield = comptroller.getApyTimeLength(_commitment);
			yield.oldTime = block.timestamp;
			yield.accruedYield = 0;
			yield.isTimelockApplicable = false;
			yield.isTimelockActivated=  true;
			yield.timelockValidity = 0;
			yield.activationTime = 0;

		}
		savingsAccount.deposits.push(deposit);
		savingsAccount.yield.push(yield);
	}
	function _processDeposit(
		address _account,
		bytes32 _market,
		bytes32 _commitment,
		uint256 _amount
	) internal {
		SavingsAccount storage savingsAccount = savingsPassbook[_account];
		DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		uint num = deposit.id - 1;

		_accruedYield(_account, _market, _commitment);
		
		deposit.amount += _amount;
		deposit.lastUpdate =  block.timestamp;


		savingsAccount.deposits[num].amount += _amount;
		savingsAccount.deposits[num].lastUpdate =  block.timestamp;

		savingsAccount.yield[num].oldLengthAccruedYield = yield.oldLengthAccruedYield;
		savingsAccount.yield[num].oldTime = yield.oldTime;
		savingsAccount.yield[num].accruedYield = yield.accruedYield;
	}

	function _hasAccount(address _account) internal view {
		require(savingsPassbook[_account].accOpenTime!=0, "ERROR: No savings account");
	}

	function _hasYield(YieldLedger memory yield) internal pure {
		require(yield.id !=0, "ERROR: No Yield");
	}

	function addToDeposit(bytes32 _market, bytes32 _commitment, uint _amount) external nonReentrant() returns(bool success){

		if (!_hasDeposit(msg.sender, _market, _commitment))	{
			_createNewDeposit(_market, _commitment, _amount);
		}
		
		_processDeposit(msg.sender, _market, _commitment, _amount);
		_updateReserves(_market, _amount, 0);

		emit DepositAdded(msg.sender, _market, _commitment, _amount);
		return success;
	}

	function _createNewDeposit(bytes32 _market,bytes32 _commitment,uint256 _amount) private {

		SavingsAccount storage savingsAccount = savingsPassbook[msg.sender];
		DepositRecords storage deposit = indDepositRecord[msg.sender][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[msg.sender][_market][_commitment];

		_preDepositProcess(_market, _amount);
		_ensureSavingsAccount(msg.sender,savingsAccount);
		token.transfer(reserveAddress, 1);
		_processNewDeposit(_market, _commitment, _amount, savingsAccount,deposit, yield);
		_updateReserves(_market, _amount, 0);
	}

	function _convertYield(address _account, bytes32 _market, bytes32 _commitment, uint _amount) private {

		_hasAccount(_account);

		SavingsAccount storage savingsAccount = savingsPassbook[msg.sender];
		DepositRecords storage deposit = indDepositRecord[msg.sender][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[msg.sender][_market][_commitment];

		_hasYield(yield);
		_accruedYield(_account,_market,_commitment);

		_amount = yield.accruedYield;

		// updating yield
		yield.accruedYield = 0;

		deposit.amount += _amount;
		deposit.lastUpdate = block.timestamp;

		savingsAccount.deposits[deposit.id -1].amount += _amount;
		savingsAccount.deposits[deposit.id -1].lastUpdate = block.timestamp;
		savingsAccount.yield[deposit.id-1].accruedYield = 0;
	}

	function _accountBalance(address _account, bytes32 _market, bytes32 _commitment, SAVINGSTYPE _request) internal returns (uint) {

		uint _savingsBalance;
		
		DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		if (_request == SAVINGSTYPE.DEPOSIT)	{
			_savingsBalance = deposit.amount;

		}	else if (_request == SAVINGSTYPE.YIELD)	{
			_accruedYield(msg.sender,_market,_commitment);
			_savingsBalance =  yield.accruedYield;

		}	else if (_request == SAVINGSTYPE.BOTH)	{
			_accruedYield(msg.sender,_market,_commitment);
			_savingsBalance = deposit.amount + yield.accruedYield;
		}
		return _savingsBalance;
	}

	function _updateSavingsBalance(address _account, bytes32 _market, bytes32 _commitment, uint _amount, SAVINGSTYPE _request) internal {

		DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		if (_request == SAVINGSTYPE.DEPOSIT)	{
			deposit.amount -= _amount;
			deposit.lastUpdate =  block.timestamp;

		}	else if (_request == SAVINGSTYPE.YIELD)	{

			if (yield.isTimelockApplicable == false || block.timestamp >= yield.activationTime+yield.timelockValidity)	{
				
				// _accruedYield(msg.sender,_market,_commitment);
				yield.accruedYield -= _amount;
				yield.oldTime = block.timestamp;
			}	else if (yield.isTimelockApplicable != false || block.timestamp < yield.activationTime+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}

		}	else if (_request == SAVINGSTYPE.BOTH)	{

			// require (deposit.id == yield.id, "mapping error");

			if (yield.isTimelockApplicable == false || block.timestamp >= yield.activationTime+yield.timelockValidity)	{
				// _accruedYield(msg.sender,_market,_commitment);
				yield.accruedYield -= _amount;
				yield.oldTime = block.timestamp;

			}	else if (yield.isTimelockApplicable != false || block.timestamp < yield.activationTime+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}
			
			deposit.amount -= _amount;
			deposit.lastUpdate =  block.timestamp;
		}
	}

	function setReserveAddress(address reserveAddr_) public authDeposit() {
		reserveAddress = reserveAddr_;
	}

	function pause() external authDeposit() nonReentrant() {
		_pause();
	}
	
	function unpause() external authDeposit() nonReentrant() {
		_unpause();   
	}

	modifier authDeposit() {
		require(
			msg.sender == adminDepositAddress,
			"Only an admin can call this function"
		);
		_;
	}
}