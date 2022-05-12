// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../util/Pausable.sol";
// import "./mockup/IMockBep20.sol";
import "../libraries/LibOpen.sol";

import "hardhat/console.sol";

contract Deposit is Pausable, IDeposit{
		
	event NewDeposit(address indexed account,bytes32 indexed market,bytes32 commitment,uint256 indexed amount, uint256 depositId);
	event DepositAdded(address indexed account,bytes32 indexed market,bytes32 commitment,uint256 indexed amount, uint256 depositId);
	event YieldDeposited(address indexed account,bytes32 indexed market,bytes32 commitment,uint256 indexed amount);
	event Withdrawal(address indexed account, bytes32 indexed market, uint indexed amount, bytes32 commitment, uint timestamp);
	
	constructor() 
	{
    // AppStorage storage ds = LibOpen.diamondStorage(); 
		// ds.adminDepositAddress = msg.sender;
		// ds.deposit = IDeposit(msg.sender);
	}

	receive() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}
	
	fallback() external payable {
		payable(LibOpen.upgradeAdmin()).transfer(msg.value);
	}

	function hasAccount(address _account) external view override returns (bool)	{
		LibOpen._hasAccount(_account);
		return true;
	}

	function savingsBalance(bytes32 _market, bytes32 _commitment, SAVINGSTYPE _request) private returns (uint) {
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 

		uint _savingsBalance;
		
		DepositRecords storage deposit = ds.indDepositRecord[msg.sender][_market][_commitment];
		YieldLedger storage yield = ds.indYieldRecord[msg.sender][_market][_commitment];

		if (_request == IDeposit.SAVINGSTYPE.DEPOSIT)	{
			_savingsBalance = deposit.amount;

		}	else if (_request == IDeposit.SAVINGSTYPE.YIELD)	{
			accruedYield(msg.sender,_market,_commitment);
			_savingsBalance =  yield.accruedYield;

		}	else if (_request == IDeposit.SAVINGSTYPE.BOTH)	{
			accruedYield(msg.sender,_market,_commitment);
			_savingsBalance = deposit.amount + yield.accruedYield;
		}
		return _savingsBalance;
	}

	function convertYield(bytes32 _market, bytes32 _commitment) external override nonReentrant() returns (bool) {
		uint _amount;
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 

		LibOpen._hasAccount(msg.sender);

		SavingsAccount storage savingsAccount = ds.savingsPassbook[msg.sender];
		DepositRecords storage deposit = ds.indDepositRecord[msg.sender][_market][_commitment];
		YieldLedger storage yield = ds.indYieldRecord[msg.sender][_market][_commitment];

		LibOpen._hasYield(yield);
		accruedYield(msg.sender,_market,_commitment);

		_amount = yield.accruedYield;

		// updating yield
		yield.accruedYield = 0;

		deposit.amount += _amount;
		deposit.lastUpdate = block.timestamp;

		savingsAccount.deposits[deposit.id -1].amount += _amount;
		savingsAccount.deposits[deposit.id -1].lastUpdate = block.timestamp;
		savingsAccount.yield[deposit.id-1].accruedYield = 0;
		emit YieldDeposited(msg.sender, _market, _commitment, _amount);
		return true;
	}

	function hasYield(bytes32 _market, bytes32 _commitment) external view override returns (bool) {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		YieldLedger storage yield = ds.indYieldRecord[msg.sender][_market][_commitment];
		LibOpen._hasYield(yield);
		return true;
	}
 
	function avblReservesDeposit(bytes32 _market) external view override returns (uint) {
		return LibOpen._avblReservesDeposit(_market);
	}

	function utilisedReservesDeposit(bytes32 _market) external view override returns(uint) {
    	return LibOpen._utilisedReservesDeposit(_market);
	}

	function _updateUtilisation(bytes32 _market, uint _amount, uint _num) private 
	{
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		if (_num == 0)	{
			ds.marketUtilisationDeposit[_market] += _amount;
		} else if (_num == 1)	{
			ds.marketUtilisationDeposit[_market] -= _amount;
		}
	}

	function hasDeposit(bytes32 _market, bytes32 _commitment) external view override returns (bool) {
		LibOpen._hasDeposit(msg.sender,_market, _commitment);
		return true;
	}

	function withdrawDeposit (
		bytes32 _market, 
		bytes32 _commitment,
		uint _amount,
		SAVINGSTYPE _request
	) external override nonReentrant() returns (bool) 
	{
		AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		
		LibOpen._hasAccount(msg.sender);// checks if user has savings account 
		LibOpen._isMarketSupported(_market);

		// DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];

		// DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		// YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		accruedYield(msg.sender,_market,_commitment);

		uint _savingsBalance = savingsBalance(_market, _commitment, _request);
		require(_amount <= _savingsBalance, "Insufficient balance"); // Dinh modified
		if (_commitment == LibOpen._getCommitment(0))	{
			updateSavingsBalance(msg.sender, _market, _commitment, _amount, _request);
		}
		/// Transfer funds to the user's wallet.
		ds.token = IBEP20(LibOpen._connectMarket(_market));
		// ds.token.approveFrom(ds.reserveAddress, address(this), _amount);
		// ds.token.transferFrom(ds.reserveAddress, msg.sender, _amount);
		ds.token.transfer(msg.sender, _amount);

		LibOpen._updateReservesDeposit(_market, _amount, 1);
		emit Withdrawal(msg.sender,_market, _amount, _commitment, block.timestamp);
		return true;	
	}

	function depositRequest(bytes32 _market, bytes32 _commitment, uint _amount) external override nonReentrant() returns(bool) {
        AppStorageOpen storage ds = LibOpen.diamondStorage(); 

        preDepositProcess(_market, _amount);

        if (!LibOpen._hasDeposit(msg.sender, _market, _commitment))    {
            createNewDeposit(msg.sender, _market, _commitment, _amount);
            return false;
        }

        // ds.token.approveFrom(msg.sender, address(this), _amount);
        ds.token.transferFrom(msg.sender, address(this), _amount); // change the address(this) to the diamond address.

        processDeposit(msg.sender, _market, _commitment, _amount);
        LibOpen._updateReservesDeposit(_market, _amount, 0);
        emit DepositAdded(msg.sender, _market, _commitment, _amount, ds.indDepositRecord[msg.sender][_market][_commitment].id);

        return true;
    }

    function createNewDeposit(address _sender, bytes32 _market,bytes32 _commitment,uint256 _amount) private {
        AppStorageOpen storage ds = LibOpen.diamondStorage(); 

        SavingsAccount storage savingsAccount = ds.savingsPassbook[_sender];
        DepositRecords storage deposit = ds.indDepositRecord[_sender][_market][_commitment];
        YieldLedger storage yield = ds.indYieldRecord[_sender][_market][_commitment];

        LibOpen._ensureSavingsAccount(_sender,savingsAccount);

		console.log("createNewDeposit/address(this) is %s", address(this));

        ds.token.transferFrom(_sender, address(this), _amount);

        processNewDeposit(_market, _commitment, _amount, savingsAccount, deposit, yield);
        LibOpen._updateReservesDeposit(_market, _amount, 0);
        emit NewDeposit(_sender, _market, _commitment, _amount, deposit.id);
    }
	
	function processDeposit(
		address _account,
		bytes32 _market,
		bytes32 _commitment,
		uint256 _amount
	) private {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		SavingsAccount storage savingsAccount = ds.savingsPassbook[_account];
		DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

		uint num = deposit.id - 1;

		accruedYield(_account, _market, _commitment);
		
		deposit.amount += _amount;
		deposit.lastUpdate =  block.timestamp;


		savingsAccount.deposits[num].amount += _amount;
		savingsAccount.deposits[num].lastUpdate =  block.timestamp;

		savingsAccount.yield[num].oldLengthAccruedYield = yield.oldLengthAccruedYield;
		savingsAccount.yield[num].oldTime = yield.oldTime;
		savingsAccount.yield[num].accruedYield = yield.accruedYield;
	}

	function updateSavingsBalance(address _account, bytes32 _market, bytes32 _commitment, uint _amount, IDeposit.SAVINGSTYPE _request) private {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 

		DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

		if (_request == IDeposit.SAVINGSTYPE.DEPOSIT)	{
			deposit.amount -= _amount;
			deposit.lastUpdate =  block.timestamp;

		}	else if (_request == IDeposit.SAVINGSTYPE.YIELD)	{

			if (yield.isTimelockApplicable == false || block.timestamp >= yield.activationTime+yield.timelockValidity)	{
				
				// _accruedYieldComit(_account,_market,_commitment);
				yield.accruedYield -= _amount;
				yield.oldTime = block.timestamp;
			}	else if (yield.isTimelockApplicable != false || block.timestamp < yield.activationTime+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}

		}	else if (_request == IDeposit.SAVINGSTYPE.BOTH)	{

			// require (deposit.id == yield.id, "mapping error");

			if (yield.isTimelockApplicable == false || block.timestamp >= yield.activationTime+yield.timelockValidity)	{
				// _accruedYieldComit(_account,_market,_commitment);
				yield.accruedYield -= _amount;
				yield.oldTime = block.timestamp;

			}	else if (yield.isTimelockApplicable != false || block.timestamp < yield.activationTime+yield.timelockValidity)	{
				revert ('Withdrawal can not be processed');
			}
			
			deposit.amount -= _amount;
			deposit.lastUpdate =  block.timestamp;
		}
	}


	function processNewDeposit(
		// address _account,
		bytes32 _market,
		bytes32 _commitment,
		uint256 _amount,
		SavingsAccount storage savingsAccount,
		DepositRecords storage deposit,
		YieldLedger storage yield
	) private {
		// SavingsAccount storage savingsAccount = savingsPassbook[_account];
		// DepositRecords storage deposit = indDepositRecord[_account][_market][_commitment];
		// YieldLedger storage yield = indYieldRecord[_account][_market][_commitment];

		uint id;

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

		
		if (_commitment != LibOpen._getCommitment(0)) {
			yield.id = id;
			yield.market = bytes32(_market);
			yield.oldLengthAccruedYield = LibOpen._getApyTimeLength(_commitment);
			yield.oldTime = block.timestamp;
			yield.accruedYield = 0;
			yield.isTimelockApplicable = true;
			yield.isTimelockActivated=  false;
			yield.timelockValidity = 86400;
			yield.activationTime = 0;
		} else if (_commitment == LibOpen._getCommitment(0)) {
			yield.id=  id;
			yield.market=_market;
			yield.oldLengthAccruedYield = LibOpen._getApyTimeLength(_commitment);
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

	function accruedYield(address _account,bytes32 _market,bytes32 _commitment) private {
        AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		
		LibOpen._hasDeposit(_account, _market, _commitment);

		uint256 aggregateYield;

		SavingsAccount storage savingsAccount = ds.savingsPassbook[_account];
		DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

		(yield.oldLengthAccruedYield, yield.oldTime, aggregateYield) = LibOpen._calcAPY(_commitment, yield.oldLengthAccruedYield, yield.oldTime, aggregateYield);

		aggregateYield *= deposit.amount;

		yield.accruedYield += aggregateYield;
		savingsAccount.yield[deposit.id-1].accruedYield += aggregateYield;

	}

	function preDepositProcess(bytes32 _market,uint256 _amount) private {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 

		LibOpen._isMarketSupported(_market);
		ds.token = IBEP20(LibOpen._connectMarket(_market));
		// _quantifyAmount(_market, _amount);
		LibOpen._minAmountCheck(_market, _amount);
	}

    function getFairPriceDeposit(uint _requestId) external view override returns (uint){
		return LibOpen._getFairPrice(_requestId);
	}

	function pauseDeposit() external override authDeposit() nonReentrant() {
		_pause();
	}
	
	function unpauseDeposit() external override authDeposit() nonReentrant() {
		_unpause();   
	}

	function isPausedDeposit() external view override virtual returns (bool) {
		return _paused();
	}

	modifier authDeposit() {
    AppStorageOpen storage ds = LibOpen.diamondStorage(); 
		require(IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.superAdmin, msg.sender) || IAccessRegistry(ds.superAdminAddress).hasAdminRole(ds.adminDeposit, msg.sender), "ERROR: Not an admin");
		_;
	}
}
