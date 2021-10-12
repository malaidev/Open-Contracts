// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./TokenList.sol";
import "./util/IBEP20.sol";
import "./Comptroller.sol";
import "./Reserve.sol";

contract Deposit {
	bytes32 adminDeposit;
	address adminDepositAddress;

	bool isReentrant = false;

	TokenList markets = TokenList(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
	Comptroller comptroller = Comptroller(0x3E2884D9F6013Ac28b0323b81460f49FE8E5f401);
	Reserve reserve = Reserve(payable(0xeAc61D9e3224B20104e7F0BAD6a6DB7CaF76659B));
	IBEP20 token;

	struct SavingsAccount {
        uint accOpenTime;
        address account; 
        DepositRecords[] deposits;
        Yield[] accruedYieldLedger;
    }

    struct DepositRecords   {
        uint id;
        uint firstDeposit;
        bytes32 market;
        bytes32 commitment;
        uint amount; // Non fractional amount
        uint lastUpdate;
    }

    struct Yield    {
        uint id;
        uint oldLengthAccruedYield; // length of the APY time array.
        uint oldTime; // last recorded block num. This is when this struct is lastly updated.
        bytes32 market; // market_ this yield is calculated for
        uint accruedYield; // accruedYield in 
        bool timelockApplicable; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        bool isTimelockActivated; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        uint timelockValidity; // timelock duration
        uint releaseAfter; // block.number(isTimelockActivated) + timelockValidity.
    }

	enum BALANCETYPE{DEPOSIT, YIELD, BOTH}
	
	mapping(address => SavingsAccount) savingsPassbook;  // Maps an account to its savings Passbook
    mapping(address => mapping(bytes32 => mapping(bytes32 => DepositRecords))) indDepositRecord; // address => market_ => commitment_ => depositRecord
    mapping(address => mapping(bytes32 => mapping(bytes32 => Yield))) indYieldRecord; // address => market_ => commitment_ => depositRecord

	event NewDeposit(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event YieldDeposited(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event Withdrawal(address indexed account, bytes32 indexed market, uint indexed amount, bytes32 commitment, uint timestamp);


	constructor() {
		adminDepositAddress = msg.sender;
	}

	function hasAccount(address account_) external view returns (bool)	{
		_hasAccount(account_);
		return true;
	}

	function savingsBalance(bytes32 market_, bytes32 commitment_, BALANCETYPE request_) external returns (uint) {
		uint savingsBalance_;

		_savingsBalance(msg.sender, market_, commitment_, request_);
		return savingsBalance_;
	}

	function convertYield(bytes32 market_, bytes32 oldCommitment_, bytes32 newCommitment_) external nonReentrant() returns (bool){
		_convertYield(market_,oldCommitment_, newCommitment_) ;

		uint amount_;

		emit YieldDeposited(msg.sender, market_, newCommitment_, amount_);
		return true;
	}

	function hasYield(address account_, bytes32 market_, bytes32 commitment_) external view returns (bool)	{
		_hasYield(account_, market_, commitment_);
		return true;
	}


	function createDeposit(
		bytes32 market_,
		bytes32 commitment_,
		uint256 amount_
	) external nonReentrant() returns (bool) {
		
		_createDeposit(market_,commitment_, amount_);

		emit NewDeposit(msg.sender, market_, commitment_, amount_);
		return true;
	}

	function withdrawFunds(bytes32 market_, bytes32 commitment_, uint amount_, BALANCETYPE request_) external nonReentrant() returns (bool){

		_withdrawFunds(msg.sender, market_, commitment_, amount_, request_);

		emit Withdrawal(msg.sender,market_, amount_, commitment_, block.timestamp);
		return true;
		
	}


	function _withdrawFunds(address account_, bytes32 market_, bytes32 commitment_, uint amount_, BALANCETYPE request_) internal{
		require(_isMarketSupported(market_) && _hasAccount(msg.sender), "Account does not exist, or Unsupportd market");
		
		// if withdrawal permitted? else ActivateTimelock.
		//  if withdrawn funds, convertYield to deposit of the sameKind.
		// withdrawYield can be another function with similar functionality.
		uint savingsBalance_;
		_savingsBalance(account_, market_, commitment_, request_);

		require(amount_ >= savingsBalance_, "Insufficient balance");
		_updateSavingsBalance(account_, commitment_, amount_, request_);
		markets._connectMarket(market_, amount_);
		token.transfer(reserve.address, amount_);
		// token.transfer(address(reserve), amount_);

	}

	// function convertDeposit() external nonReentrant() {}

	function _preDepositProcess(
		address account_,
		bytes32 market_,
		uint256 amount_
	) internal {
		_isMarketSupported(market_);
		_createSavingsAccount(account_);
		
		markets._connectMarket(market_, amount_, token);
		return this;
	}

	function _createSavingsAccount(address account_) internal {
		SavingsAccount storage savingsAccount = savingsPassbook[account_];

		if (savingsAccount.accOpenTime == 0) {
			savingsAccount.accOpenTime = block.timestamp;
			savingsAccount.account = account_;
		}
	}

	function _isMarketSupported(bytes32 market_) internal {
		require(markets.tokenSupportCheck[market_] != false, "Unsupported market");
	}

	function _updateYield(address account_,bytes32 market_,bytes32 commitment_) internal {
		
		Yield storage yield = indYieldRecord[account_][market_][commitment_];
		DepositRecords storage deposit = indDepositRecord[account_][market_][commitment_];
		APY storage apy = comptroller.indAPYRecords[commitment_];

		uint256 index = yield.oldLengthAccruedYield - 1;
		uint256 blockNum = yield.oldTime;
		uint256 aggregateYield = yield.accruedYield;

    if (apy.apyChangeRecords.length > yield.oldLengthAccruedYield)  {
      if (apy.time[index] < blockNum) {
        uint256 newIndex = index + 1;
        aggregateYield +=
          ((apy.time[newIndex] - blockNum) *apy.apyChangeRecords[index])/100;

        for (uint256 i = newIndex; i < apy.apyChangeRecords.length; i++) {
          uint256 blockDiff = apy.time[i + 1] - apy.time[i];
          aggregateYield += blockDiff*apy.apyChangeRecords[newIndex] / 100;
        }
      } else if (apy.time[index] == blockNum) {
        for (uint256 i = index; i < apy.apyChangeRecords.length; i++) {
          uint256 blockDiff = apy.time[i + 1] - apy.time[i];
          aggregateYield += blockDiff*apy.apyChangeRecords[index] / 100;
        }
      }
      
      if (block.number >= apy.time[apy.time.length - 1]) {
        	aggregateYield += ((block.Number - apy.time[apy.time.length - 1]) *apy.apyChangeRecords[apy.time.length - 1]) /100;
		}

    }  else if (apy.apyChangeRecords.length == yield.oldLengthAccruedYield)  {
          aggregateYield += (block.number - blockNum)*apy.apyChangeRecords[index]/100;
    }

	// need to add a condition that accounts for multiple deposits of the same kind? Meaning, if 
	// there is an add-on deposit, 
	/// Update: 12th October. 2021
	// trigger updateYield for newDeposit, add-onDeposit as well.
		yield.accruedYield += deposit.amount * aggregatedYield;
		yield.oldLengthAccruedYield = apy.time.length;
		yield.oldTime = block.number;
	}

	function _processDeposit(
		address account_,
		bytes32 market_,
		bytes32 commitment_,
		uint256 amount_
	) internal {
		DepositRecords storage deposit = indDepositRecord[account_][market_][commitment_];
		SavingsAccount storage savingsAccount = savingsPassbook[account_];
		Yield storage yield = indYieldRecord[account_][market_][commitment_];
		APY storage apy = comptroller.indAPYRecords[commitment_];
		uint256 id;

		if (savingsAccount.deposits.length == 0) {
				id = 1;
			} else {
				id = savingsAccount.deposits.length + 1;
		}

		if (deposit.firstDeposit == 0 && commitment_ != comptroller.commitment[0]) {

			deposit = DepositRecords({
				id: id,
				firstDeposit: block.number,
				market_: market_,
				commitment_: commitment_,
				amount_: amount_,
				lastUpdate: block.number
			});

			yield = Yield({
				id: id,
				oldLengthAccruedYield: apy.time.length,
				oldTime: block.number,
				market: market_,
				accruedYield: 0,
				timelockApplicable: true,
				timelockValidity: 86400,
				activationBlock: _withdrawFunds(msg.sender)
			});
			
			savingsAccount.deposits.push(deposit);
			savingsAccount.accruedYieldLedger.push(yield);
		} else if (
			deposit.firstDeposit == 0 && commitment_ == comptroller.commitment[0]) {
			
			// id = savingsAccount.deposits.length;
			deposit = DepositRecords({
				id: id,
				firstDeposit: block.number,
				market_: market_,
				commitment_: commitment_,
				amount_: amount_,
				lastUpdate: block.number
			});
			savingsAccount.deposits.push(deposit);
			yield = Yield({
				id: id,
				oldLengthAccruedYield: apy.time.length,
				oldTime: block.number,
				market: market_,
				accruedYield: 0,
				timelockApplicable: false,
				timelockValidity: 0,
				activationBlock: 0
			});

			savingsAccount.deposits.push(deposit);
			savingsAccount.accruedYieldLedger.push(yield);

			} else if (deposit.firstDeposit != 0) {
				deposit.amount_ += amount_;
				deposit.lastUpdate = block.number;

				savingsAccount.deposits[deposit.id-1].amount += amount_;
				savingsAccount.deposits[deposit.id-1].lastUpdate += block.number;

				// _updateYield(account_, market_, commitment_);
			}
	}

	function _hasAccount(address account_) internal {
		require(savings.savingsPassbook[account_].accOpenTime!=0, "Savings account does not exist");
	}

	function _hasYield(address account_, bytes32 market_, bytes32 commitment_) internal 	{
		Yield storage yield = indYieldRecord[account_][market_][commitment_];
		require(yield.id !=0, "Yield does not exist");
		return this;
	}

	function _createDeposit(bytes32 market_,bytes32 commitment_,uint256 amount_) private	{
		address marketAddress;
		_preDepositProcess(msg.sender, market_, amount_);
		token.transfer(address(reserve), amount_);
		_updateYield(msg.sender, market_, commitment_);
		_processDeposit(msg.sender, market_, commitment_, amount_);
	}

	function _convertYield(bytes32 market_, bytes32 oldCommitment_, bytes32 newCommitment_) private {
		_hasAccount(msg.sender);
		_hasYield(msg.sender, market_, oldCommitment_);
		_isMarketSupported(market_);
		_updateYield(msg.sender, market_, oldCommitment_);

		amount_ = yield.accruedYield(1-(5/10000)); // 0.05% conversion fees applied.
		// // transfer 0.05% fees deducted from the accrued yield to the reserveAccount.
		_createDeposit(market_, newCommitment_, amount_);
	}


		function _savingsBalance(address account_, bytes32 market_, bytes32 commitment_, BALANCETYPE request_) internal	{
		
		DepositRecords storage deposit = indDepositRecord[account_][market_][commitment_];
		Yield storage yield = indYieldRecord[account_][market_][commitment_];

		if (request_ == BALANCETYPE.DEPOSIT)	{
			savingsBalance_ = deposit.amount;

		}	else if (request_ == BALANCETYPE.YIELD)	{
			_updateYield(msg.sender,market_,commitment_);
			savingsBalance_ =  yield.accruedYield;

		}	else if (request_ == BALANCETYPE.BOTH)	{
			_updateYield(msg.sender,market_,commitment_);
			savingsBalance_ = deposit.amount + yield.accruedYield;
		}
	}

	function _updateSavingsBalance(address account_, bytes32 commitment_, uint amount_, BALANCETYPE request_) internal {

		DepositRecords storage deposit = indDepositRecord[account_][market_][commitment_];
		Yield storage yield = indYieldRecord[account_][market_][commitment_];

		if (request_ == BALANCETYPE.DEPOSIT)	{
			deposit.amount -= amount_;
			deposit.lastUpdate =  block.number;

		}	else if (request_ == BALANCETYPE.YIELD)	{

			if (yield.timelockApplicable == false || block.number >= yield.activationBlock+yield.timelockValidity)	{
				_updateYield(msg.sender,market_,commitment_);
				yield.accruedYield -= amount_;
				yield.oldTime = block.number;
			}	else if (yield.timelockApplicable != false || block.number < yield.activationBlock+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}

		}	else if (request_ == BALANCETYPE.BOTH)	{

			require (deposit.id == yield.id, "mapping error");

			if (yield.timelockApplicable == false || block.number >= yield.activationBlock+yield.timelockValidity)	{
				_updateYield(msg.sender,market_,commitment_);
				yield.accruedYield -= amount_;
				yield.oldTime = block.number;

			}	else if (yield.timelockApplicable != false || block.number < yield.activationBlock+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}
			
			deposit.amount -= amount_;
			deposit.lastUpdate =  block.number;
		}
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