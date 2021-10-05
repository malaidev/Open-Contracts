// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "./interfaces/ITokenList.sol";
import "./util/IBEP20.sol";
import "./interfaces/IComptroller.sol";
import "./interfaces/IReserve.sol";
import "./util/Pausable.sol";
contract Deposit is Pausable {

	bytes32 adminDeposit;
	address adminDepositAddress;
	address superAdminAddress;

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
        uint oldLengthAccruedYield; // length of the APY blockNumbers array.
        uint oldBlockNum; // last recorded block num
        bytes32 market; // market_ this yield is calculated for
        uint accruedYield; // accruedYield in 
        bool timelockApplicable; // is timelockApplicalbe or not. Except the flexible deposits, the timelock is applicabel on all the deposits.
        uint timelockValidity; // timelock duration
        uint activationBlock; // blocknumber when yield withdrawal request was placed.
    }


	uint aggregatedYield;

	ITokenList markets;
	IComptroller comptroller;
	IReserve reserve;
	IBEP20 token;

    mapping(address => SavingsAccount) savingsPassbook;  // Maps an account to its savings Passbook
    mapping(address => mapping(bytes32 => mapping(bytes32 => DepositRecords))) indDepositRecord; // address => market_ => commitment_ => depositRecord
    mapping(address => mapping(bytes32 => mapping(bytes32 => Yield))) indYieldRecord; // address => market_ => commitment_ => depositRecord

	enum BALANCETYPE{DEPOSIT, YIELD, BOTH}

	event NewDeposit(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event YieldDeposited(address indexed account,bytes32 indexed market,bytes32 commmitment,uint256 indexed amount);
	event Withdrawal(address indexed account, bytes32 indexed market, uint indexed amount, bytes32 commitment, uint timestamp);

	constructor(
		address superAdminAddr_,
		address tokenListAddr_,
		address comptrollerAddr_,
		address reserveAddr_
	)
	{
		superAdminAddress = superAdminAddr_;
		comptroller = IComptroller(comptrollerAddr_);
		markets = ITokenList(tokenListAddr_);
		reserve = IReserve(reserveAddr_);
		adminDepositAddress = msg.sender;
	}

	receive() external payable {
        payable(adminDepositAddress).transfer(_msgValue());
    }
    
    fallback() external payable {
        payable(adminDepositAddress).transfer(_msgValue());
    }
    
    function transferAnyERC20(address token_,address recipient_,uint256 value_) external returns(bool) {
        IBEP20(token_).transfer(recipient_, value_);
        return true;
    }

	function hasAccount(address account_) public returns (bool) {
		_hasAccount(account_);
		return true;
	}

	function hasYield(address account_, bytes32 market_, bytes32 commitment_) public returns (bool)	{
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

	function savingsBalance(bytes32 market_, bytes32 commitment_, BALANCETYPE request_) external returns (uint) {
		uint savingsBalance_;

		_savingsBalance(msg.sender, market_, commitment_, request_);
		return savingsBalance_;
	}


	function withdrawFunds(bytes32 market_, bytes32 commitment_, uint amount_, BALANCETYPE request_) external nonReentrant() returns (bool){
		_isMarketSupported(market_);
		_hasAccount(msg.sender);

		uint savingsBalance_;
		_savingsBalance(msg.sender, market_, commitment_, request_);

		require(amount_ >= savingsBalance_, "Insufficient balance");
		_updateSavingsBalance(msg.sender, commitment_, amount_, request_);
		_connectMarket(market_, amount_);
		token.transfer(msg.sender, amount_);

		emit Withdrawal(msg.sender,market_, amount_, commitment_, block.timestamp);
		return true;
		
	}

	// function convertDeposit() external nonReentrant() {}

	function convertYield(bytes32 market_, bytes32 oldCommitment_, bytes32 newCommitment_) external nonReentrant() returns (bool){
		_convertYield(market_,oldCommitment_, newCommitment_) ;

		uint amount_;

		emit YieldDeposited(msg.sender, market_, newCommitment_, amount_);
		return true;
	}

	function _preDepositProcess(
		address account_,
		bytes32 market_,
		uint256 amount_
	) internal {
		_isMarketSupported(market_);
		_createSavingsAccount(account_);
		_connectMarket(market_, amount_);
		// return this;
	}

	function _createSavingsAccount(address account_) internal {
		SavingsAccount storage savingsAccount = savingsPassbook[account_];

		if (savingsAccount.accOpenTime == 0) {
			savingsAccount.accOpenTime = block.timestamp;
			savingsAccount.account = account_;
		}
	}

	function _isMarketSupported(bytes32 market_) internal {
		require(markets.isTokenSupported(market_) != false, "Unsupported market");
	}

	function _connectMarket(bytes32 market_, uint256 amount_) internal {
		address marketAddress = markets.getMarketTokenAddress(market_);
		token = IBEP20(marketAddress);
		amount_ *= markets.getMarketDecimal(market_);
	}

	function _updateYield(
		address account_,
		bytes32 market_,
		bytes32 commitment_
	) internal {
		Yield storage yield = indYieldRecord[account_][market_][commitment_];
		DepositRecords storage deposit = indDepositRecord[account_][market_][commitment_];

		uint256 index = yield.oldLengthAccruedYield - 1;
		uint256 blockNum = yield.oldBlockNum;
		uint256 aggregateYield = yield.accruedYield;

		if (comptroller.getApyBlockNumber(commitment_, index) < blockNum) {
			uint256 newIndex = index + 1;
			aggregateYield +=
				((comptroller.getApyBlockNumber(commitment_, newIndex) - blockNum) *
					comptroller.getAPY(commitment_, index)) /
				100;

			for (uint256 i = newIndex; i < comptroller.getApyRecordCount(commitment_); i++) {
				uint256 blockDiff = comptroller.getApyBlockNumber(commitment_, i + 1) - comptroller.getApyBlockNumber(commitment_, i);
				aggregateYield += blockDiff*comptroller.getAPY(commitment_, newIndex) / 100;
			}
		} else if (comptroller.getApyBlockNumber(commitment_, index) == blockNum) {
			for (uint256 i = index; i < comptroller.getApyRecordCount(commitment_); i++) {
				uint256 blockDiff = comptroller.getApyBlockNumber(commitment_, i + 1) - comptroller.getApyBlockNumber(commitment_, i);
				aggregateYield += blockDiff*comptroller.getAPY(commitment_, index) / 100;
			}
		}
		if (block.number > comptroller.getApyBlockNumber(commitment_, comptroller.getApyRecordCount(commitment_) - 1)) {
			aggregateYield += ((block.number - comptroller.getApyBlockNumber(commitment_, comptroller.getApyRecordCount(commitment_) - 1))
				 *comptroller.getAPY(commitment_, comptroller.getApyRecordCount(commitment_) - 1)) /100;
		}

		yield.accruedYield += deposit.amount * aggregatedYield;
		yield.oldLengthAccruedYield = comptroller.getApyRecordCount(commitment_);
		yield.oldBlockNum = block.number;
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
		uint256 id;

		if (deposit.firstDeposit == 0 && commitment_ != comptroller.commitment[0]) {
			if (savingsAccount.deposits.length == 0) {
				id = 1;
			} else {
				id = savingsAccount.deposits.length + 1;
			}

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
				oldLengthAccruedYield: comptroller.getApyRecordCount(commitment_),
				oldBlockNum: block.number,
				market: market_,
				accruedYield: 0,
				timelockApplicable: true,
				timelockValidity: 86400,
				activationBlock: 0
			});
		} else if (
			deposit.firstDeposit == 0 && commitment_ == comptroller.commitment[0]
		) {
			if (savingsAccount.deposits.length == 0) {
				id = 1;
			} else {
				id = savingsAccount.deposits.length + 1;
			}
			id = savingsAccount.deposits.length;
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
				oldLengthAccruedYield: comptroller.getApyRecordCount(commitment_),
				oldBlockNum: block.number,
				market: market_,
				accruedYield: 0,
				timelockApplicable: false,
				timelockValidity: 0,
				activationBlock: 0
			});
		} else if (!deposit.firstDeposit = 0) {
			deposit.amount_ += amount_;
			deposit.lastUpdate = block.number;
			savingsAccount.deposits[deposit.id].amount += amount_;
			savingsAccount.deposits[deposit.id].lastUpdate += block.number;
		}
	}

	function _hasAccount(address account_) internal 	{
		require(savingsPassbook[account_].accOpenTime!=0, "Savings account does not exist");
	}

	function _hasYield(address account_, bytes32 market_, bytes32 commitment_) internal {
		Yield storage yield = indYieldRecord[account_][market_][commitment_];
		require(yield.id !=0, "Yield does not exist");
		// return this;
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

		amount_ = accruedYield(1-(5/10000)); // 0.05% conversion fees applied.
		// // transfer 0.05% fees deducted from the accrued yield to the reserveAccount.
		_createDeposit(market_, newCommitment_, amount_);
	}
	
	function _savingsBalance(address account_, bytes32 market_, bytes32 commitment_, BALANCETYPE request_) internal	{
		
		DepositRecords storage deposit = indDepositRecord[account_][market_][commitment_];
		Yield storage yield = indYieldRecord[account_][market_][commitment_];

		if (request_ == BALANCETYPE.DEPOSIT) {
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
				yield.oldBlockNum = block.number;
			}	else if (yield.timelockApplicable != false || block.number < yield.activationBlock+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}

		}	else if (request_ == BALANCETYPE.BOTH)	{

			require (deposit.id == yield.id, "mapping error");

			if (yield.timelockApplicable == false || block.number >= yield.activationBlock+yield.timelockValidity)	{
				_updateYield(msg.sender,market_,commitment_);
				yield.accruedYield -= amount_;
				yield.oldBlockNum = block.number;

			}	else if (yield.timelockApplicable != false || block.number < yield.activationBlock+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}
			
			deposit.amount -= amount_;
			deposit.lastUpdate =  block.number;
		}
	}
	
	function pause() external authDeposit() nonReentrant() {
       _pause();
	}
	
	function unpause() external authDeposit() nonReentrant() {
       _unpause();   
	}

	modifier authDeposit() {
		require(
			msg.sender == adminDepositAddress || 
			msg.sender == superAdminAddress,
			"Only Deposit admin can call this function"
		);
		_;
	}
}