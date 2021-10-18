// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./interfaces/ITokenList.sol";
import "./util/IBEP20.sol";
import "./interfaces/IComptroller.sol";

contract Deposit {
	
	bytes32 adminDeposit;
	address adminDepositAddress;
	address superAdminAddress;
	address reserveAddress;

	ITokenList markets;
	IComptroller comptroller;

	// address superAdminAddress;
	// address reserveAddress;

	// ITokenList markets;
	// IComptroller comptroller;

	bool isReentrant = false;

	// TokenList markets = TokenList(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
	// Comptroller comptroller = Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
	// Reserve reserve = Reserve(payable(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B));
	IBEP20 token;

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

	enum BALANCETYPE{DEPOSIT, YIELD, BOTH}
	
	mapping(address => SavingsAccount) savingsPassbook;  // Maps an account to its savings Passbook
    mapping(address => mapping(bytes32 => mapping(bytes32 => DepositRecords))) indDepositRecord; // address =>_market => _commitment => depositRecord
    mapping(address => mapping(bytes32 => mapping(bytes32 => YieldLedger))) indYieldRecord; // address =>_market => _commitment => depositRecord

	///  Balance monitoring  - Deposits
	mapping(bytes32 => uint) marketReserves; // mapping(market => marketBalance)
	mapping(bytes32 => uint) marketUtilisation; // mapping(market => marketBalance)

	event NewDeposit(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event YieldDeposited(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event Withdrawal(address indexed account, bytes32 indexed market, uint indexed amount, bytes32 commitment, uint timestamp);


	constructor(
		address superAdminAddr_,
		address tokenListAddr_,
		address comptrollerAddr_
	) 
	{
		superAdminAddress = superAdminAddr_;
		adminDepositAddress = msg.sender;
		markets = ITokenList(tokenListAddr_);
		comptroller = IComptroller(comptrollerAddr_);
	}

	function hasAccount(address _account) external view returns (bool)	{
		_hasAccount(_account);
		return true;
	}

	function savingsBalance(bytes32 _market, bytes32 _commitment) external returns (uint) {
		return _accountBalance(msg.sender, _market, _commitment, BALANCETYPE.BOTH);
	}

	function convertYield(bytes32 _market, bytes32 _commitment) external nonReentrant() returns (bool success){

		uint _amount;
		_amount = _convertYield(msg.sender, _market,_commitment);

		emit YieldDeposited(msg.sender, _market, _commitment, _amount);
		return success;
	}

	function hasYield(bytes32 _market, bytes32 _commitment) external view returns (bool)	{
		DepositRecords storage deposit = indDepositRecord[msg.sender][_market][_commitment];
		_hasYield(/*_account, _market, _commitment, */deposit);
		return true;
	}

	function avblReserves(bytes32 _market) external view returns (uint) {
		return _avblReserves(_market);
	}

	function _avblReserves(bytes32 _market) internal view returns(uint)	{
		return marketReserves[_market];
	}

	function utilisedReserves(bytes32 _market) external view returns (uint) {
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
		// return this;
	}

	function _updateUtilisation(bytes32 _market, uint _amount, uint _num) private
	{
		if (_num == 0)	{
			marketUtilisation[_market] += _amount;
		} else if (_num == 1)	{
			marketUtilisation[_market] -= _amount;
		}
		// return this;
	}

	
	function createDeposit(
		bytes32 _market,
		bytes32 _commitment,
		uint256 _amount
	) external nonReentrant() returns (bool success) {
		
		_createNewDeposit(_market,_commitment, _amount);

		emit NewDeposit(msg.sender, _market, _commitment, _amount);
		return success;
	}


	function withdrawDeposit (bytes32 _market, bytes32 _commitment, uint _amount, BALANCETYPE _request) external nonReentrant() returns (bool){

		_withdrawDeposit (msg.sender, _market, _commitment, _amount, _request);

		emit Withdrawal(msg.sender,_market, _amount, _commitment, block.timestamp);
		return true;
		
	}


	function _withdrawDeposit (address _account, bytes32 _market, bytes32 _commitment, uint _amount, BALANCETYPE _request) internal{
		
		_hasAccount(_account);
		markets.isMarketSupported(_market);

		// DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		// YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		_updateYield(msg.sender,_market,_commitment);

		uint _savingsBalance = _accountBalance(_account, _market, _commitment, _request);

		require(_amount >= _savingsBalance, "Insufficient balance");
		if (_commitment == comptroller.getCommitment(0))	{
			_updateSavingsBalance(_account, _market, _commitment, _amount, _request);
		}
		/// Transfer funds to the user's wallet.
		markets.connectMarket(_market, token);
		token.transfer(reserveAddress, _amount);

		_updateReserves(_market, _amount, 1);

	}

	// function convertDeposit() external nonReentrant() {}

	function _preDepositProcess(
		address _account,
		bytes32 _market,
		uint256 _amount,
		SavingsAccount storage savingsAccount
	) private{

		markets.isMarketSupported(_market);
		_ensureSavingsAccount(_account,savingsAccount);
		
		markets.connectMarket(_market, token);
		markets.quantifyAmount(_market, _amount);
		// return this;
	}

	function _ensureSavingsAccount(address _account, SavingsAccount storage savingsAccount) private {

		if (savingsAccount.accOpenTime == 0) {

			savingsAccount.accOpenTime = block.timestamp;
			savingsAccount.account = _account;
		}
	}

	function _updateYield(address _account,bytes32 _market,bytes32 _commitment) internal {
		
		YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];
		DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		// IComptroller.APY storage apy = comptroller.indAPYRecords[commitment_];

		uint256 index = yield.oldLengthAccruedYield - 1;
		uint256 blockNum = yield.oldTime;
		uint256 aggregateYield = yield.accruedYield;

		if (comptroller.getApyRecordCount(_commitment) > yield.oldLengthAccruedYield)  {
			if (comptroller.getApytime(_commitment, index) < blockNum) {
				uint256 newIndex = index + 1;
				aggregateYield +=
				((comptroller.getApytime(_commitment, newIndex) - blockNum) *comptroller.getAPY(_commitment, index))/100;

				for (uint256 i = newIndex; i < comptroller.getApyRecordCount(_commitment); i++) {
				uint256 blockDiff = comptroller.getApytime(_commitment, i+1) - comptroller.getApytime(_commitment, i);
				aggregateYield += blockDiff*comptroller.getAPY(_commitment, newIndex) / 100;
				}
			} else if (comptroller.getApytime(_commitment, index) == blockNum) {
				for (uint256 i = index; i < comptroller.getApyRecordCount(_commitment); i++) {
				uint256 blockDiff = comptroller.getApytime(_commitment, i+1) - comptroller.getApytime(_commitment, i);
				aggregateYield += blockDiff*comptroller.getAPY(_commitment, index) / 100;
				}
			}
			
			if (block.timestamp >= comptroller.getApyLastTime(_commitment)) {
					aggregateYield += ((block.timestamp - comptroller.getApyLastTime(_commitment)) *comptroller.getAPY(_commitment)) /100;
			}

		}  else if (comptroller.getApyRecordCount(_commitment) == yield.oldLengthAccruedYield)  {
			aggregateYield += (block.timestamp - blockNum)*comptroller.getAPY(_commitment, index)/100;
		}

	// need to add a condition that accounts for multiple deposits of the same kind? Meaning, if 
	// there is an add-on deposit, 
	/// Update: 12th October. 2021
	// trigger updateYield for newDeposit, add-onDeposit as well.
		yield.accruedYield += deposit.amount * aggregateYield;
		yield.oldLengthAccruedYield = comptroller.getApyTimeLength(_commitment);
		yield.oldTime = block.number;
	}


	function _processNewDeposit(
		address _account,
		bytes32 _market,
		bytes32 _commitment,
		uint256 _amount
	) internal {
		SavingsAccount storage savingsAccount = savingsPassbook[_account];
		DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];
		// IComptroller.APY storage apy = comptroller.indAPYRecords[_commitment];

		uint256 id;

		if (savingsAccount.deposits.length == 0) {
				id = 1;
			} else {
				id = savingsAccount.deposits.length + 1;
		}

		// deposit = DepositRecords({
		// 	id: id,
		// 	market:_market,
		// 	commitment: _commitment,
		// 	amount: _amount,
		// 	lastUpdate: block.timestamp
		// });		
		deposit = savingsAccount.deposits[savingsAccount.deposits.length];
		deposit.id = id;
		deposit.market = _market;
		deposit.commitment = _commitment;
		deposit.amount = _amount;
		deposit.lastUpdate = block.timestamp;

		if (_commitment != comptroller.getCommitment(0)) {
			// yield = YieldLedger({
			// 	id: id,
			// 	market:_market,
			// 	oldLengthAccruedYield: comptroller.getApyTimeLength(_commitment),
			// 	oldTime: block.timestamp,
			// 	accruedYield: 0,
			// 	isTimelockApplicable: true,
			// 	isTimelockActivated: false,
			// 	timelockValidity: 86400,
			// 	activationTime: 0
			// });
			yield = savingsAccount.yield[savingsAccount.yield.length];
			yield.id = id;
			yield.market = _market;
			yield.oldLengthAccruedYield = comptroller.getApyTimeLength(_commitment);
			yield.oldTime = block.timestamp;
			yield.accruedYield = 0;
			yield.isTimelockApplicable = true;
			yield.isTimelockActivated = false;
			yield.timelockValidity = 86400;
			yield.activationTime = 0;
		} else if (
			_commitment == comptroller.getCommitment(0)) {
			
			// yield = YieldLedger({
			// 	id: id,
			// 	market:_market,
			// 	oldLengthAccruedYield: comptroller.getApyTimeLength(_commitment),
			// 	oldTime: block.timestamp,
			// 	accruedYield: 0,
			// 	isTimelockApplicable: false,
			// 	isTimelockActivated: true,
			// 	timelockValidity: 0,
			// 	activationTime: 0
			// });
			yield = savingsAccount.yield[savingsAccount.yield.length];
			yield.id = id;
			yield.market = _market;
			yield.oldLengthAccruedYield = comptroller.getApyTimeLength(_commitment);
			yield.oldTime = block.timestamp;
			yield.accruedYield = 0;
			yield.isTimelockApplicable = false;
			yield.isTimelockActivated = true;
			yield.timelockValidity = 0;
			yield.activationTime = 0;
		}
		// savingsAccount.deposits.push(deposit);
		// savingsAccount.yield.push(yield);
	}

	function _hasAccount(address _account) internal view{
		require(savingsPassbook[_account].accOpenTime!=0, "ERROR: No savings account");
	}

	function _hasYield(/*address _account, bytes32 _market, bytes32 _commitment, */DepositRecords storage deposit) internal view{
		require(deposit.id !=0, "ERROR: No Yield");
		// return this;
	}

	function _createNewDeposit(bytes32 _market,bytes32 _commitment,uint256 _amount) private	{
		SavingsAccount storage savingsAccount = savingsPassbook[msg.sender];
		_preDepositProcess(msg.sender, _market, _amount, savingsAccount);
		token.transfer(reserveAddress, _amount);

		_processNewDeposit(msg.sender, _market, _commitment, _amount);
		_updateReserves(_market, _amount, 0);
	}

	function _convertYield(address _account, bytes32 _market, bytes32 _commitment) private returns (uint) {

		_hasAccount(_account);

		uint _amount;

		SavingsAccount storage savingsAccount = savingsPassbook[msg.sender];
		DepositRecords storage deposit = indDepositRecord[msg.sender][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[msg.sender][_market][_commitment];
		// IComptroller.APY storage apy = comptroller.indAPYRecords[_commitment];

		
		_hasYield(/*_account, _market, _commitment, */deposit);
		_updateYield(_account,_market,_commitment);

		_amount = yield.accruedYield;

		// updating yield
		yield.accruedYield = 0;

		deposit.amount += _amount;
		deposit.lastUpdate = block.timestamp;

		savingsAccount.deposits[deposit.id -1].amount += _amount;
		savingsAccount.deposits[deposit.id -1].lastUpdate = block.timestamp;
		savingsAccount.yield[deposit.id-1].accruedYield = 0;

		return _amount;
	}

	function _accountBalance(address _account, bytes32 _market, bytes32 _commitment, BALANCETYPE _request) private returns (uint) {

		uint _savingsBalance;
		
		DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		if (_request == BALANCETYPE.DEPOSIT)	{
			_savingsBalance = deposit.amount;

		}	else if (_request == BALANCETYPE.YIELD)	{
			_updateYield(msg.sender,_market,_commitment);
			_savingsBalance =  yield.accruedYield;

		}	else if (_request == BALANCETYPE.BOTH)	{
			_updateYield(msg.sender,_market,_commitment);
			_savingsBalance = deposit.amount + yield.accruedYield;
		}
		return _savingsBalance;
	}

	function _updateSavingsBalance(address _account, bytes32 _market, bytes32 _commitment, uint _amount, BALANCETYPE _request) internal {

		DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		if (_request == BALANCETYPE.DEPOSIT)	{
			deposit.amount -= _amount;
			deposit.lastUpdate =  block.timestamp;

		}	else if (_request == BALANCETYPE.YIELD)	{

			if (yield.isTimelockApplicable == false || block.timestamp >= yield.activationTime+yield.timelockValidity)	{
				
				// _updateYield(msg.sender,_market,_commitment);
				yield.accruedYield -= _amount;
				yield.oldTime = block.timestamp;
			}	else if (yield.isTimelockApplicable != false || block.timestamp < yield.activationTime+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}

		}	else if (_request == BALANCETYPE.BOTH)	{

			// require (deposit.id == yield.id, "mapping error");

			if (yield.isTimelockApplicable == false || block.timestamp >= yield.activationTime+yield.timelockValidity)	{
				// _updateYield(msg.sender,_market,_commitment);
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

	modifier nonReentrant() {
		require(isReentrant == false, "Re-entrant alert!");
		isReentrant = true;
		_;
		isReentrant = false;
	}

	modifier authDeposit() {
		require(
			msg.sender == adminDepositAddress,
			"Only an admin can call this function"
		);
		_;
	}
}