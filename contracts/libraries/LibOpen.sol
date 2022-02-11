// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "./AppStorageOpen.sol";
import "../util/Address.sol";
import "../util/IBEP20.sol";
import "../interfaces/ITokenList.sol";
import "../interfaces/IComptroller.sol";
import "../interfaces/ILiquidator.sol";
import "../interfaces/IDeposit.sol";
import "../interfaces/IReserve.sol";
import "../interfaces/ILoan.sol";
import "../interfaces/ILoanExt.sol";
import "../interfaces/IOracleOpen.sol";
import "../interfaces/IAccessRegistry.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IAugustusSwapper.sol";
import "../interfaces/IPancakeRouter01.sol";

import "hardhat/console.sol";

library LibOpen {
	using Address for address;

	uint8 constant TOKENLIST_ID = 10;
	uint8 constant COMPTROLLER_ID = 11;
	// uint8 constant LIQUIDATOR_ID = 12;
	uint8 constant RESERVE_ID = 13;
	// uint8 constant ORACLEOPEN_ID = 14;
	uint8 constant LOAN_ID = 15;
	uint8 constant LOANEXT_ID = 16;
	uint8 constant DEPOSIT_ID = 17; 
	// address internal constant PANCAKESWAP_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 ; // pancakeswap bsc testnet router address
	address internal constant PANCAKESWAP_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 ; // pancakeswap bsc testnet router address

	// enum STATE {ACTIVE,REPAID}
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

// =========== Liquidator events ===============
// =========== OracleOpen events ===============
	event FairPriceCall(uint requestId, bytes32 market, uint amount);

	event LoanRepaid(
		address indexed account,
		uint256 indexed id,
		bytes32 indexed market,
		uint256 timestamp
	);

	event CollateralReleased(
		address indexed account,
		uint256 indexed amount,
		bytes32 indexed market,
		uint256 timestamp
	);

	event MarketSwapped(
		address indexed account,
		uint256 indexed loanid,
		bytes32 marketFrom,
		bytes32 marketTo,
		uint256 amount
	);


	function upgradeAdmin() internal view returns (address upgradeAdmin_) {
		upgradeAdmin_ = diamondStorage().upgradeAdmin;
	}

	function _addFairPriceAddress(bytes32 _loanMarket, address _address) internal {
		AppStorageOpen storage ds = diamondStorage();
		ds.pairAddresses[_loanMarket] = _address;
	}

	function _getFairPriceAddress(bytes32 _loanMarket) internal view returns (address){
		AppStorageOpen storage ds = diamondStorage();
		return ds.pairAddresses[_loanMarket];
	}

	// function setReserveAddress(address _reserve) internal {
	// 	AppStorageOpen storage ds = diamondStorage();
	// 	ds.reserveAddress = _reserve;
	// }

	function diamondStorage() internal pure returns (AppStorageOpen storage ds) {
		assembly {
				ds.slot := 0
		}
	}

	function _isMarketSupported(bytes32  _market) internal view {
		AppStorageOpen storage ds = diamondStorage(); 
		require(ds.tokenSupportCheck[_market] == true, "ERROR: Unsupported market");
	}

	function _getMarketAddress(bytes32 _loanMarket) internal view returns (address) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indMarketData[_loanMarket].tokenAddress;
	}

	function _getMarketDecimal(bytes32 _loanMarket) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indMarketData[_loanMarket].decimals;
	}

	function _minAmountCheck(bytes32 _loanMarket, uint _amount) internal view {
		
		AppStorageOpen storage ds = diamondStorage(); 
		MarketData memory marketData = ds.indMarketData[_loanMarket];
		
		require(marketData.minAmount <= _amount, "ERROR: Less than minimum amount");
	}

	// function _quantifyAmount(bytes32 _loanMarket, uint _amount) internal view returns (uint amount) {
	// 	AppStorageOpen storage ds = diamondStorage(); 
	//     MarketData memory marketData = ds.indMarketData[_loanMarket];
    // 	amount = _amount * marketData.decimals;
	// }

	function _isMarket2Supported(bytes32  _loanMarket) internal view {
		require(diamondStorage().token2SupportCheck[_loanMarket] == true, "Secondary Token is not supported");
	}

	function _getMarket2Address(bytes32 _loanMarket) internal view returns (address) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indMarket2Data[_loanMarket].tokenAddress;
	}

	function _getMarket2Decimal(bytes32 _loanMarket) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage();
		return ds.indMarket2Data[_loanMarket].decimals;
	}

	function _connectMarket(bytes32 _market) internal view returns (address) {
		
		AppStorageOpen storage ds = diamondStorage(); 
		MarketData memory marketData = ds.indMarketData[_market];
		return marketData.tokenAddress;
	}
	
// =========== Comptroller Functions ===========

	function _getAPR(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].aprChanges[ds.indAPRRecords[_commitment].aprChanges.length - 1];
	}

	function _getAPRInd(bytes32 _commitment, uint _index) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].aprChanges[_index];
	}

	function _getAPY(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].apyChanges[ds.indAPYRecords[_commitment].apyChanges.length - 1];
	}

	function _getAPYInd(bytes32 _commitment, uint _index) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].apyChanges[_index];
	}

	function _getApytime(bytes32 _commitment, uint _index) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].time[_index];
	}

	function _getAprtime(bytes32 _commitment, uint _index) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].time[_index];
	}

	function _getApyLastTime(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].time[ds.indAPYRecords[_commitment].time.length - 1];
	}

	function _getAprLastTime(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].time[ds.indAPRRecords[_commitment].time.length - 1];
	}

	function _getApyTimeLength(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPYRecords[_commitment].time.length;
	}

	function _getAprTimeLength(bytes32 _commitment) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.indAPRRecords[_commitment].time.length;
	}

	function _getCommitment(uint _index) internal view returns (bytes32) {
		AppStorageOpen storage ds = diamondStorage(); 
		require(_index < ds.commitment.length, "Commitment Index out of range");
		return ds.commitment[_index];
	}

	function _setCommitment(bytes32 _commitment) internal authContract(COMPTROLLER_ID) {
		AppStorageOpen storage ds = diamondStorage();
		ds.commitment.push(_commitment);
	}

	function _calcAPR(bytes32 _commitment, uint oldLengthAccruedInterest, uint oldTime, uint aggregateInterest) internal view returns (uint, uint, uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		
		APR storage apr = ds.indAPRRecords[_commitment];

		require(oldLengthAccruedInterest > 0, "oldLengthAccruedInterest is 0");

		uint256 index = oldLengthAccruedInterest - 1;
		uint256 time = oldTime;

		// // 1. apr.time.length > oldLengthAccruedInterest => there is some change.

		if (apr.time.length > oldLengthAccruedInterest)  {

			if (apr.time[index] < time) {
				uint256 newIndex = index + 1;
				// Convert the aprChanges to the lowest unit value.
				aggregateInterest = (((apr.time[newIndex] - time) *apr.aprChanges[index])/10000)*365/(100*1000);
			
				for (uint256 i = newIndex; i < apr.aprChanges.length; i++) {
					uint256 timeDiff = apr.time[i + 1] - apr.time[i];
					aggregateInterest += (timeDiff*apr.aprChanges[newIndex] / 10000)*365/(100*1000);
				}
			}
			else if (apr.time[index] == time) {
				for (uint256 i = index; i < apr.aprChanges.length; i++) {
					uint256 timeDiff = apr.time[i + 1] - apr.time[i];
					aggregateInterest += (timeDiff*apr.aprChanges[index] / 10000)*365/(100*1000);
				}
			}
		} else if (apr.time.length == oldLengthAccruedInterest && block.timestamp > oldLengthAccruedInterest) {
			if (apr.time[index] < time || apr.time[index] == time) {
				aggregateInterest += (block.timestamp - time)*apr.aprChanges[index]/10000;
				// Convert the aprChanges to the lowest unit value.
				// aggregateYield = (((apr.time[newIndex] - time) *apr.aprChanges[index])/10000)*365/(100*1000);
			}
		}
		oldLengthAccruedInterest = apr.time.length;
		oldTime = block.timestamp;
		return (oldLengthAccruedInterest, oldTime, aggregateInterest);
	}

	function _calcAPY(bytes32 _commitment, uint oldLengthAccruedYield, uint oldTime, uint aggregateYield) internal view returns (uint, uint, uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		APY storage apy = ds.indAPYRecords[_commitment];

		require(oldLengthAccruedYield>0, "ERROR : oldLengthAccruedYield < 1");
		
		uint256 index = oldLengthAccruedYield - 1;
		uint256 time = oldTime;
		
		// 1. apr.time.length > oldLengthAccruedInterest => there is some change.
		if (apy.time.length > oldLengthAccruedYield)  {

			if (apy.time[index] < time) {
				uint256 newIndex = index + 1;
				// Convert the aprChanges to the lowest unit value.
				aggregateYield = (((apy.time[newIndex] - time) *apy.apyChanges[index])/10000)*365/(100*1000);
			
				for (uint256 i = newIndex; i < apy.apyChanges.length; i++) {
					uint256 timeDiff = apy.time[i + 1] - apy.time[i];
					aggregateYield += (timeDiff*apy.apyChanges[newIndex] / 10000)*365/(100*1000);
				}
			}
			else if (apy.time[index] == time) {
				for (uint256 i = index; i < apy.apyChanges.length; i++) {
					uint256 timeDiff = apy.time[i + 1] - apy.time[i];
					aggregateYield += (timeDiff*apy.apyChanges[index] / 10000)*365/(100*1000);
				}
			}
		} else if (apy.time.length == oldLengthAccruedYield && block.timestamp > oldLengthAccruedYield) {
			if (apy.time[index] < time || apy.time[index] == time) {
				aggregateYield += (block.timestamp - time)*apy.apyChanges[index]/10000;
				// Convert the aprChanges to the lowest unit value.
				// aggregateYield = (((apr.time[newIndex] - time) *apr.aprChanges[index])/10000)*365/(100*1000);
			}
		}
		oldLengthAccruedYield = apy.time.length;
		oldTime = block.timestamp;

		return (oldLengthAccruedYield, oldTime, aggregateYield);
	}

	function _getReserveFactor() internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.reserveFactor;
	}

// =========== Loan functions ==============
	function _swapLoan(address _sender,bytes32 _loanMarket,bytes32 _commitment,bytes32 _swapMarket) internal authContract(LOAN_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
        _hasLoanAccount(_sender);
		
		_isMarketSupported(_loanMarket);
		_isMarket2Supported(_swapMarket);

		LoanAccount storage loanAccount = ds.loanPassbook[_sender];
		LoanRecords storage loan = ds.indLoanRecords[_sender][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[_sender][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_loanMarket][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[_sender][_loanMarket][_commitment];

		require(loan.id != 0, "ERROR: No loan");
		require(loan.isSwapped == false && loanState.currentMarket == _loanMarket, "ERROR: Already swapped");

		uint256 _swappedAmount;
		uint256 num = loan.id - 1;

		_swappedAmount = _swap(_sender, _loanMarket, _swapMarket, loan.amount, 0);

		/// Updating LoanRecord
		loan.isSwapped = true;
		loan.lastUpdate = block.timestamp;
		/// Updating LoanState
		loanState.currentMarket = _swapMarket;
		loanState.currentAmount = _swappedAmount;

		/// Updating LoanAccount
		loanAccount.loans[num].isSwapped = true;
		loanAccount.loans[num].lastUpdate = block.timestamp;
		loanAccount.loanState[num].currentMarket = _swapMarket;
		loanAccount.loanState[num].currentAmount = _swappedAmount;

		_accruedInterest(_sender, _loanMarket, _commitment);
		if (collateral.isCollateralisedDeposit) _accruedYield(loanAccount, collateral, cYield);
    }

	function _swapToLoan(
		address _account,
		bytes32 _commitment,
		bytes32 _loanMarket
	) internal authContract(LOAN_ID) returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		
		_hasLoanAccount(_account);
		
		LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_loanMarket][_commitment];

		_isMarketSupported(_loanMarket);
		_isMarket2Supported(loanState.currentMarket);

		// CollateralRecords storage collateral = ds.indCollateralRecords[_account][_loanMarket][_commitment];
		// CollateralYield storage cYield = ds.indAccruedAPY[_account][_loanMarket][_commitment];

		require(loan.id != 0, "ERROR: No loan");
		require(loan.isSwapped == true && loanState.currentMarket != _loanMarket, "ERROR: Swapped market does not exist");
		// require(loan.isSwapped == true, "Swapped market does not exist");

		uint swappedAmount = _swap(_account, loanState.currentMarket,_loanMarket,loanState.currentAmount, 1);

		/// Updating LoanRecord
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;

		/// updating the LoanState
		loanState.currentMarket = _loanMarket;
		loanState.currentAmount = swappedAmount;

		/// Updating LoanAccount
		ds.loanPassbook[_account].loans[loan.id - 1].isSwapped = false;
		ds.loanPassbook[_account].loans[loan.id - 1].lastUpdate = block.timestamp;
		ds.loanPassbook[_account].loanState[loan.id - 1].currentMarket = _loanMarket;
		ds.loanPassbook[_account].loanState[loan.id - 1].currentAmount = swappedAmount;

		_accruedInterest(_account, _loanMarket, _commitment);
		_accruedYield(ds.loanPassbook[_account], ds.indCollateralRecords[_account][_loanMarket][_commitment], ds.indAccruedAPY[_account][_loanMarket][_commitment]);
		return swappedAmount;
	}
	// function _swapToLoan(
	// 	address _account,
	// 	bytes32 _swapMarket,
	// 	bytes32 _commitment,
	// 	bytes32 _loanMarket
	// ) internal authContract(LOAN_ID) returns (uint) {
	// 	AppStorageOpen storage ds = diamondStorage(); 
	// 	_hasLoanAccount(_account);
	// 	_isMarketSupported(_loanMarket);
	// 	_isMarket2Supported(_swapMarket);

	// 	LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
	// 	LoanState storage loanState = ds.indLoanState[_account][_loanMarket][_commitment];
	// 	// CollateralRecords storage collateral = ds.indCollateralRecords[_account][_loanMarket][_commitment];
	// 	// CollateralYield storage cYield = ds.indAccruedAPY[_account][_loanMarket][_commitment];

	// 	require(loan.id != 0, "ERROR: No loan");
	// 	require(loan.isSwapped == true && loanState.currentMarket == _swapMarket, "ERROR: Swapped market does not exist");
	// 	// require(loan.isSwapped == true, "Swapped market does not exist");

	// 	uint swappedAmount = _swap(_account, _swapMarket,_loanMarket,loanState.currentAmount, 1);

	// 	/// Updating LoanRecord
	// 	loan.isSwapped = false;
	// 	loan.lastUpdate = block.timestamp;

	// 	/// updating the LoanState
	// 	loanState.currentMarket = _loanMarket;
	// 	loanState.currentAmount = swappedAmount;

	// 	/// Updating LoanAccount
	// 	ds.loanPassbook[_account].loans[loan.id - 1].isSwapped = false;
	// 	ds.loanPassbook[_account].loans[loan.id - 1].lastUpdate = block.timestamp;
	// 	ds.loanPassbook[_account].loanState[loan.id - 1].currentMarket = _loanMarket;
	// 	ds.loanPassbook[_account].loanState[loan.id - 1].currentAmount = swappedAmount;

	// 	_accruedInterest(_account, _loanMarket, _commitment);
	// 	_accruedYield(ds.loanPassbook[_account], ds.indCollateralRecords[_account][_loanMarket][_commitment], ds.indAccruedAPY[_account][_loanMarket][_commitment]);
	// 	return swappedAmount;
	// }
// =========== Liquidator Functions ===========
	function _swap(address sender, bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 _mode) internal returns (uint256) {

		if(_fromMarket == _toMarket) return 0;
		address addrFromMarket;
		address addrToMarket;

		if(_mode == 0){
			addrFromMarket = _getMarketAddress(_fromMarket);
			addrToMarket = _getMarket2Address(_toMarket);
		} else if(_mode == 1) {
			addrFromMarket = _getMarket2Address(_fromMarket);
			addrToMarket = _getMarketAddress(_toMarket);
		} else if(_mode == 2) {
			addrFromMarket = _getMarketAddress(_toMarket);
			addrToMarket = _getMarketAddress(_fromMarket);
		}

		require(addrFromMarket != address(0) && addrToMarket != address(0), "Swap Address can not be zero.");

		//paraswap
		// address[] memory callee = new address[](2);
		// if(_fromMarket == MARKET_WBNB) callee[0] = WBNB;
		// if(_toMarket == MARKET_WBNB) callee[1] = WBNB;
		// IBEP20(addrFromMarket).approve(0xDb28dc14E5Eb60559844F6f900d23Dce35FcaE33, _fromAmount);
		// receivedAmount = IAugustusSwapper(0x3D0Fc2b7A17d61915bcCA984B9eAA087C5486d18).swapOnUniswap(
		// 	_fromAmount, 1,
		// 	callee,
		// 	1
		// );

		

		//PancakeSwap
		IBEP20(addrFromMarket).transferFrom(sender, address(this), _fromAmount);
		IBEP20(addrFromMarket).approve(PANCAKESWAP_ROUTER_ADDRESS, _fromAmount);

		//WBNB as other test tokens
		address[] memory path;
		// if (addrFromMarket == WBNB || addrToMarket == WBNB) {
			path = new address[](2);
			path[0] = addrFromMarket;
			path[1] = addrToMarket;
		// } else {
		//     path = new address[](3);
		//     path[0] = addrFromMarket;
		//     path[1] = WBNB;
		//     path[2] = addrToMarket;
		// }

// https://github.com/pancakeswap/pancake-document/blob/c3531149a4b752a0cfdf94f2d276ac119f89774b/code/smart-contracts/pancakeswap-exchange/router-v2.md#swapexacttokensfortokens
		uint[] memory ret;
		ret = IPancakeRouter01(PANCAKESWAP_ROUTER_ADDRESS).swapExactTokensForTokens(_fromAmount,_getAmountOutMin(addrFromMarket, addrToMarket, _fromAmount),path,address(this),block.timestamp+15);
		return ret[ret.length-1];
	}

	function _getAmountOutMin(
		address _tokenIn,
		address _tokenOut,
		uint _amountIn
	) private view returns (uint) {
		address[] memory path;
		//if (_tokenIn == WBNB || _tokenOut == WBNB) {
			path = new address[](2);
			path[0] = _tokenIn;
			path[1] = _tokenOut;
		// } else {
		//     path = new address[](3);
		//     path[0] = _tokenIn;
		//     path[1] = WBNB;
		//     path[2] = _tokenOut;
		// }

		// same length as path
		uint[] memory amountOutMins = IPancakeRouter01(PANCAKESWAP_ROUTER_ADDRESS).getAmountsOut(
				_amountIn,
				path
		);	

		return amountOutMins[path.length - 1];
  }

// =========== Deposit Functions ===========
	function _hasDeposit(address _account, bytes32 _loanMarket, bytes32 _commitment) internal view returns(bool ret) {
		AppStorageOpen storage ds = diamondStorage();
		ret = ds.indDepositRecord[_account][_loanMarket][_commitment].id != 0;
		// require (ds.indDepositRecord[_account][_loanMarket][_commitment].id != 0, "ERROR: No deposit");
		// return true;
	}

	function _avblReservesDeposit(bytes32 _loanMarket) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketReservesDeposit[_loanMarket];
	}

	function _utilisedReservesDeposit(bytes32 _loanMarket) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketUtilisationDeposit[_loanMarket];
	}

	function _hasAccount(address _account) internal view {
		AppStorageOpen storage ds = diamondStorage(); 
		require(ds.savingsPassbook[_account].accOpenTime!=0, "ERROR: No savings account");
	}

	function _hasYield(YieldLedger memory yield) internal pure {
		require(yield.id !=0, "ERROR: No Yield");
	}

	function _updateReservesDeposit(bytes32 _loanMarket, uint _amount, uint _num) internal authContract(DEPOSIT_ID) {
		AppStorageOpen storage ds = diamondStorage();
		if (_num == 0)	{
			ds.marketReservesDeposit[_loanMarket] += _amount;
		} else if (_num == 1)	{
			ds.marketReservesDeposit[_loanMarket] -= _amount;
		}
	}

	function _ensureSavingsAccount(address _account, SavingsAccount storage savingsAccount) internal {

		if (savingsAccount.accOpenTime == 0) {

			savingsAccount.accOpenTime = block.timestamp;
			savingsAccount.account = _account;
		}
	}

// =========== Loan Functions ===========

	/// WITHDRAW COLLATERAL
	function _withdrawCollateral(address _account, bytes32 _market, bytes32 _commitment) internal authContract(LOAN_ID) {
        
		_hasLoanAccount(_account);
		_isMarketSupported(_market);

		AppStorageOpen storage ds = diamondStorage(); 

        LoanAccount storage loanAccount = ds.loanPassbook[_account];
		LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
		
		/// REQUIRE STATEMENTS - CHECKING FOR LOAN, REPAYMENT & COLLATERAL TIMELOCK.
		require(loan.id != 0, "ERROR: Loan does not exist");
		require(loanState.state == STATE.REPAID, "ERROR: Active loan");
		require((collateral.timelockValidity + collateral.activationTime) >= block.timestamp, "ERROR: Active Timelock");

		ds.collateralToken = IBEP20(_connectMarket(collateral.market));
        ds.collateralToken.transfer(_account, collateral.amount);

		bytes32 collateralMarket = collateral.market;
		uint256 collateralAmount = collateral.amount;
		
		/// UPDATING STORAGE RECORDS FOR LOAN
		/// COLLATERAL RECORDS
		delete collateral.id;
		delete collateral.market;
		delete collateral.commitment;
		delete collateral.amount;
		delete collateral.isCollateralisedDeposit;
		delete collateral.timelockValidity;
		delete collateral.isTimelockActivated;
		delete collateral.activationTime;

		/// LOAN RECORDS
		delete loan.id;
		delete loan.isSwapped;
		delete loan.lastUpdate;
		
		/// LOAN STATE
		delete loanState.id;
		delete loanState.state;

		/// LOAN ACCOUNT
		delete loanAccount.loans[loan.id - 1];
		delete loanAccount.collaterals[loan.id - 1];
		delete loanAccount.loanState[loan.id - 1];


		emit CollateralReleased(_account, collateralAmount, collateralMarket, block.timestamp);
        _updateReservesLoan(collateralMarket, collateralAmount, 1);
	}

	// function _collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) internal authContract(LOAN_ID) {
    //     AppStorageOpen storage ds = diamondStorage(); 

	// 	bytes32 collateralMarket;
    //     uint collateralAmount;

	// 	_collateralPointer(_account,_market,_commitment, collateralMarket, collateralAmount);
	// 	ds.token = IBEP20(_connectMarket(collateralMarket));
    //     ds.token.transfer(_account, collateralAmount);
	// }

	// function _collateralPointer(address _account, bytes32 _market, bytes32 _commitment, bytes32 collateralMarket, uint collateralAmount) internal view {
	// 	AppStorageOpen storage ds = diamondStorage(); 
		
	// 	_hasLoanAccount(_account);

	// 	// LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
	// 	LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
	// 	CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];

	// 	//}		
	// 	collateralMarket = collateral.market;
	// 	collateralAmount = collateral.amount;
	// }

/// CHECKING PERMISSIBLE WITHDRAWAL
	function _checkPermissibleWithdrawal(address account, uint256 amount, LoanAccount storage loanAccount, LoanRecords storage loan, LoanState storage loanState,CollateralRecords storage collateral, CollateralYield storage cYield) internal authContract(LOAN_ID) {
		AppStorageOpen storage ds = diamondStorage();

		require(amount <= loanState.currentAmount, "ERROR: Amount > Loan value");
		require(loanState.currentMarket == loan.market, "ERROR: Can not withdraw secondary markets");

		_accruedInterest(account, loan.market, loan.commitment);

		uint256 collateralAvbl;
		uint256 usdCollateral;
		uint256 usdLoan;
		uint256 usdLoanCurrent;


		/// UPDATE collateralAvbl
		collateralAvbl = collateral.amount - ds.indAccruedAPR[account][loan.market][loan.commitment].accruedInterest;
		if (loan.commitment == _getCommitment(2)) {
			_accruedYield(loanAccount, collateral, cYield);
			collateralAvbl += cYield.accruedYield;
		}

		/// FETCH USDT PRICES
		usdCollateral = LibOpen._getLatestPrice(collateral.market);
		usdLoan = LibOpen._getLatestPrice(loan.market);
		usdLoanCurrent = LibOpen._getLatestPrice(loanState.currentMarket);

		/// Permissible withdrawal amount calculation in the loanMarket.
		// permissibleAmount = ((usdCollateral*collateralAvbl - (30*usdCollateral*collateral.amount/100))/usdLoanCurrent);
		require(((usdCollateral*collateralAvbl - (30*usdCollateral*collateral.amount/100))/usdLoanCurrent) >= (amount), "ERROR: Request exceeds funds");
		require(((usdCollateral*collateralAvbl) + (usdLoanCurrent*loanState.currentAmount) - (amount*usdLoanCurrent)) >= (15*(usdLoan*ds.indLoanRecords[account][loan.market][loan.commitment].amount)/10), "ERROR: Liquidation risk");
	}


	function _updateDebtRecords(LoanAccount storage loanAccount,LoanRecords storage loan, LoanState storage loanState, CollateralRecords storage collateral/*, DeductibleInterest storage deductibleInterest, CollateralYield storage cYield*/) private {
        AppStorageOpen storage ds = diamondStorage(); 
		uint256 num = loan.id - 1;
		bytes32 _market = loan.market;

		loan.amount = 0;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		
		loanState.currentMarket = _market;
		loanState.currentAmount = 0;
		loanState.actualLoanAmount = 0;
		loanState.state = STATE.REPAID;

		collateral.isCollateralisedDeposit = false;
		collateral.isTimelockActivated = true;
		collateral.activationTime = block.timestamp;

		// delete cYield;
		// delete deductibleInterest;
		delete ds.indAccruedAPY[loanAccount.account][loan.market][loan.commitment];
		delete ds.indAccruedAPR[loanAccount.account][loan.market][loan.commitment];

		// Updating LoanPassbook
		loanAccount.loans[num].amount = 0;
		loanAccount.loans[num].isSwapped = false;
		loanAccount.loans[num].lastUpdate = block.timestamp;

		loanAccount.loanState[num].currentMarket = _market;
		loanAccount.loanState[num].currentAmount = 0;
		loanAccount.loanState[num].actualLoanAmount = 0;
		loanAccount.loanState[num].state = STATE.REPAID;
		
		loanAccount.collaterals[num].isCollateralisedDeposit = false;
		loanAccount.collaterals[num].isTimelockActivated = true;
		loanAccount.collaterals[num].activationTime = block.timestamp;

		
		delete loanAccount.accruedAPY[num];
		delete loanAccount.accruedAPR[num];
	}

	function _repaymentProcess(
		uint256 num,
		uint256 _repayAmount,
		LoanAccount storage loanAccount,
		LoanRecords storage loan,
		LoanState storage loanState,
		CollateralRecords storage collateral,
		DeductibleInterest storage deductibleInterest,
		CollateralYield storage cYield
	) internal authContract(LOANEXT_ID) returns(uint256) {
        // AppStorageOpen storage ds = diamondStorage(); 
		
		bytes32 _commitment = loan.commitment;
		uint256 _remnantAmount = 0;
		uint256 _collateralAmount = 0;
		
		/// convert collateral into loan market to add to the repayAmount
		_collateralAmount = collateral.amount - deductibleInterest.accruedInterest;
		if (_commitment == _getCommitment(2)) _collateralAmount += cYield.accruedYield;

		_repayAmount += _swap(address(this), collateral.market, loan.market, _collateralAmount, 2);
		console.log("repay amount is %s, loanAmount is %s", _repayAmount, loan.amount);
		
		if(_repayAmount >= loan.amount) _remnantAmount += (_repayAmount - loan.amount);
		else {
			if (loanState.currentMarket == loanState.loanMarket)	_repayAmount += loanState.currentAmount;
			else if (loanState.currentMarket != loanState.loanMarket)	_repayAmount += _swap(address(this), loanState.currentMarket, loanState.loanMarket, loanState.currentAmount, 2);
			
			_remnantAmount += (_repayAmount - loan.amount);
		}


		// delete diamondStorage().indAccruedAPR[_account][loan.market][loan.commitment];
		// delete diamondStorage().indAccruedAPY[_account][loan.market][loan.commitment];
		/// STACK DEEP ERRRO [Above 2 lines]
		
		/// DELETING DeductibleInterest
		delete deductibleInterest.id;
		delete deductibleInterest.market;
		delete deductibleInterest.oldLengthAccruedInterest;
		delete deductibleInterest.oldTime;
		delete deductibleInterest.accruedInterest;


		/// DELETING CollateralYield
		delete cYield.id;
		delete cYield.market;
		delete cYield.commitment;
		delete cYield.oldLengthAccruedYield;
		delete cYield.oldTime;
		delete cYield.accruedYield;


		// /// UPDATING CollateralRecords
		// collateral.isCollateralisedDeposit = false;
		// collateral.isTimelockActivated = true;
		// collateral.activationTime = block.timestamp;

		
		/// UPDATING RECORDS IN LOANACCOUNT
		delete loanAccount.accruedAPR[num];
		delete loanAccount.accruedAPY[num];

		// loanAccount.collaterals[num].isCollateralisedDeposit = false;
		// loanAccount.collaterals[num].activationTime = block.timestamp;
		// loanAccount.collaterals[num].isTimelockActivated = true;
		
		return _remnantAmount;
	}

	// function _repaymentProcess(
	// 	address _account,
	// 	uint256 _repayAmount,
	// 	LoanAccount storage loanAccount,
	// 	LoanRecords storage loan,
	// 	LoanState storage loanState,
	// 	CollateralRecords storage collateral,
	// 	DeductibleInterest storage deductibleInterest,
	// 	CollateralYield storage cYield
	// ) private {
    //     AppStorageOpen storage ds = diamondStorage(); 
		
	// 	bytes32 _commitment = loan.commitment;
	// 	uint256 num = loan.id - 1;
		
	// 	// convert collateral into loan market to add to the repayAmount
	// 	uint256 collateralAmount = collateral.amount - (deductibleInterest.accruedInterest + cYield.accruedYield);
	// 	_repayAmount += _swap(_account, collateral.market,loan.market,collateralAmount,2);
	// 	console.log("repay amount is %s, loanAmount is %s", _repayAmount, loan.amount);

	// 	require(_repayAmount >= loan.amount, "Repay Amount is smaller than loan Amount");

	// 	// Excess amount is tranferred back to the collateral record
	// 	uint256 _remnantAmount = _repayAmount - loan.amount;
	// 	collateral.amount = _swap(_account, loan.market,collateral.market,_remnantAmount,2);

	// 	/// updating LoanRecords
	// 	loan.amount = 0;
	// 	loan.isSwapped = false;
	// 	loan.lastUpdate = block.timestamp;
		
	// 	/// updating LoanState
	// 	loanState.actualLoanAmount = 0;
	// 	loanState.currentAmount = 0;
	// 	loanState.state = uint(STATE.REPAID);

	// 	delete ds.indAccruedAPR[_account][loan.market][loan.commitment];
	// 	delete ds.indAccruedAPY[_account][loan.market][loan.commitment];

	// 	delete loanAccount.accruedAPR[num];
	// 	delete loanAccount.accruedAPY[num];
		
	// 	emit LoanRepaid(_account, loan.id, loan.market, block.timestamp);

	// 	if (_commitment == _getCommitment(2)) {
	// 		/// updating CollateralRecords
	// 		collateral.isCollateralisedDeposit = false;
	// 		collateral.isTimelockActivated = true;
	// 		collateral.activationTime = block.timestamp;

	// 	} else if (_commitment == _getCommitment(0)) {
	// 		/// transfer collateral.amount from the Diamond contract to the _sender
	// 		ds.collateralToken = IBEP20(_connectMarket(collateral.market));
	// 		ds.collateralToken.transfer(loanAccount.account, collateral.amount);
			
	// 		delete ds.indCollateralRecords[_account][loan.market][loan.commitment];
	// 		delete ds.indLoanState[_account][loan.market][loan.commitment];
	// 		delete ds.indLoanRecords[_account][loan.market][loan.commitment];

	// 		delete loanAccount.collaterals[num];
	// 		delete loanAccount.loanState[num];
	// 		delete loanAccount.loans[num];

	// 		_updateReservesLoan(collateral.market, collateral.amount, 1);
	// 		emit CollateralReleased(_account,collateral.amount,collateral.market,block.timestamp);
	// 	}
	// }

	// function _repayLoan(address _sender, bytes32 _market,bytes32 _commitment,uint256 _repayAmount) internal authContract(LOAN_ID) {
    //     _hasLoanAccount(_sender);
		
	// 	// LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
	// 	// LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
	// 	// CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
	// 	// DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_sender][_market][_commitment];
	// 	// CollateralYield storage cYield = ds.indAccruedAPY[_sender][_market][_commitment];		
		
	// 	require(diamondStorage().indLoanRecords[_sender][_market][_commitment].id != 0,"ERROR: No Loan");
		
	// 	_isMarketSupported(_market);
	// 	_accruedInterest(_sender, _market, _commitment);
	// 	_accruedYield(diamondStorage().loanPassbook[_sender], diamondStorage().indCollateralRecords[_sender][_market][_commitment], diamondStorage().indAccruedAPY[_sender][_market][_commitment]);

	// 	if (_repayAmount == 0) {
			
	// 		/// converting the current market into loanMarket for repayment.
	// 		if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market)	_repayAmount = diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
	// 		else if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket != _market)	_repayAmount = _swap(_sender, diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _market,diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount, 1);
			
	// 		_repaymentProcess(
	// 			_sender,
	// 			_repayAmount, 
	// 			diamondStorage().loanPassbook[_sender],
	// 			diamondStorage().indLoanRecords[_sender][_market][_commitment],
	// 			diamondStorage().indLoanState[_sender][_market][_commitment],
	// 			diamondStorage().indCollateralRecords[_sender][_market][_commitment],
	// 			diamondStorage().indAccruedAPR[_sender][_market][_commitment], 
	// 			diamondStorage().indAccruedAPY[_sender][_market][_commitment]);
	// 	}
	// 	else if (_repayAmount > 0) {
	// 		/// transfering the repayAmount to the reserve contract.
	// 		diamondStorage().loanToken = IBEP20(_connectMarket(_market));
	// 		diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount += (diamondStorage().indAccruedAPY[_sender][_market][_commitment].accruedYield - diamondStorage().indAccruedAPR[_sender][_market][_commitment].accruedInterest);
			
	// 		uint256 _swappedAmount;
	// 		uint256 _remnantAmount;

	// 		if (_repayAmount >= diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
	// 			_remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;

	// 			if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market){
	// 				_remnantAmount += diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
	// 			}
	// 			else {
	// 				_swapToLoanProcess(_sender, diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _commitment, _market, _swappedAmount);
	// 				_repayAmount += _swappedAmount;
	// 			}

	// 			_updateDebtRecords(diamondStorage().loanPassbook[_sender],diamondStorage().indLoanRecords[_sender][_market][_commitment],diamondStorage().indLoanState[_sender][_market][_commitment],diamondStorage().indCollateralRecords[_sender][_market][_commitment]/*, deductibleInterest, cYield*/);
	// 			diamondStorage().loanToken.transfer(diamondStorage().loanPassbook[_sender].account, _remnantAmount);

	// 			emit LoanRepaid(_sender, diamondStorage().indLoanRecords[_sender][_market][_commitment].id, diamondStorage().indLoanRecords[_sender][_market][_commitment].market, block.timestamp);
				
	// 			if (_commitment == _getCommitment(0)) {
	// 				/// transfer collateral.amount from reserve contract to the _sender
	// 				// collateralToken = IBEP20(markets.connectMarket(collateral.market));
	// 				_transferAnyBEP20(_connectMarket(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market), _sender, diamondStorage().loanPassbook[_sender].account,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount);

	// 				delete diamondStorage().indLoanRecords[_sender][_market][_commitment];
	// 				delete diamondStorage().indLoanState[_sender][_market][_commitment];
	// 				delete diamondStorage().indCollateralRecords[_sender][_market][_commitment];


	// 				delete diamondStorage().loanPassbook[_sender].loanState[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
	// 				delete diamondStorage().loanPassbook[_sender].loans[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
	// 				delete diamondStorage().loanPassbook[_sender].collaterals[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
					
	// 				_updateReservesLoan(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
	// 				emit CollateralReleased(_sender,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,block.timestamp);
	// 			}
	// 		} else if (_repayAmount < diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {

	// 			if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market)	_repayAmount += diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
	// 			else if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket != _market) {
	// 				_swapToLoanProcess(_sender, diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _commitment, _market, _swappedAmount);
	// 				_repayAmount += _swappedAmount;
	// 			}
				
	// 			if (_repayAmount > diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
	// 				_remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;
	// 				diamondStorage().loanToken.transfer(diamondStorage().loanPassbook[_sender].account, _remnantAmount);
	// 			} else if (_repayAmount <= diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
					
	// 				_repayAmount += _swap(_sender, diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,_market,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
	// 				// _repayAmount += _swapToLoanProcess(loanState.currentMarket, _commitment, _market);
	// 				_remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;
	// 				diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount += _swap(_sender, diamondStorage().indLoanRecords[_sender][_market][_commitment].market,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,_remnantAmount, 2);
	// 			}
	// 			_updateDebtRecords(diamondStorage().loanPassbook[_sender],diamondStorage().indLoanRecords[_sender][_market][_commitment],diamondStorage().indLoanState[_sender][_market][_commitment],diamondStorage().indCollateralRecords[_sender][_market][_commitment]/*, deductibleInterest, cYield*/);
				
	// 			if (_commitment == _getCommitment(0)) {
					
	// 				// collateralToken = IBEP20(markets.connectMarket(collateral.market));
	// 				_transferAnyBEP20(_connectMarket(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market), _sender, diamondStorage().loanPassbook[_sender].account, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount);

	// 				delete diamondStorage().indLoanRecords[_sender][_market][_commitment];
	// 				delete diamondStorage().indLoanState[_sender][_market][_commitment];
	// 				delete diamondStorage().indCollateralRecords[_sender][_market][_commitment];

	// 				delete diamondStorage().loanPassbook[_sender].loanState[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
	// 				delete diamondStorage().loanPassbook[_sender].loans[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
	// 				delete diamondStorage().loanPassbook[_sender].collaterals[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
					
	// 				_updateReservesLoan(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
	// 				emit CollateralReleased(_sender,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,block.timestamp);
	// 			}
	// 		}
	// 	}
		
	// 	_updateUtilisationLoan(diamondStorage().indLoanRecords[_sender][_market][_commitment].market, diamondStorage().indLoanRecords[_sender][_market][_commitment].amount, 1);
    // }
	function _repayLoan(address _sender, bytes32 _market, bytes32 _commitment,uint256 _repayAmount) internal authContract(LOAN_ID) {
		
		require(diamondStorage().indLoanRecords[_sender][_market][_commitment].id != 0,"ERROR: No Loan");
		_accruedInterest(_sender, _market, _commitment);

		AppStorageOpen storage ds = diamondStorage();
		
		LoanAccount storage loanAccount = ds.loanPassbook[_sender];
		LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
		LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
		DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_sender][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[_sender][_market][_commitment];

		uint256 remnantAmount= _repaymentProcess(
			loan.id - 1,
			_repayAmount, 
			loanAccount,
			loan,
			loanState,
			collateral,
			deductibleInterest,
			cYield
		);
		/// CONVERT remnantAmount into collateralAmount
		collateral.amount = _swap(address(this), loan.market, collateral.market, remnantAmount, 2);
		
		/// RESETTING STORAGE VALUES COMMON FOR commitment(0) & commitment(2)

		/// UPDATING LoanRecords
			delete loan.market;
			delete loan.commitment;
			delete loan.amount;

		/// UPDATING LoanState
			delete loanState.loanMarket;
			delete loanState.actualLoanAmount;
			delete loanState.currentMarket;
			delete loanState.currentAmount;

		/// UPDATING RECORDS IN LOANACCOUNT
			delete loanAccount.loans[loan.id-1].market;
			delete loanAccount.loans[loan.id-1].commitment;
			delete loanAccount.loans[loan.id-1].amount;

			delete loanAccount.loanState[loan.id-1].loanMarket;
			delete loanAccount.loanState[loan.id-1].actualLoanAmount;
			delete loanAccount.loanState[loan.id-1].currentMarket;
			delete loanAccount.loanState[loan.id-1].currentAmount;

		if (_commitment == _getCommitment(2)) {
			
			/// UPDATING COLLATERAL AMOUNT IN STORAGE
			loanAccount.collaterals[loan.id-1].amount = collateral.amount;

			collateral.isCollateralisedDeposit = false;
			collateral.isTimelockActivated = true;
			collateral.activationTime = block.timestamp;
			
			/// UPDATING LoanRecords
			loan.isSwapped = false;
			loan.lastUpdate = block.timestamp;
			
			/// UPDATING LoanState
			loanState.state = STATE.REPAID;

			/// UPDATING RECORDS IN LOANACCOUNT
			loanAccount.loans[loan.id-1].isSwapped = false;
			loanAccount.loans[loan.id-1].lastUpdate = block.timestamp;

			loanAccount.loanState[loan.id-1].state = STATE.REPAID;

			loanAccount.collaterals[loan.id-1].isCollateralisedDeposit = false;
			loanAccount.collaterals[loan.id-1].activationTime = block.timestamp;
			loanAccount.collaterals[loan.id-1].isTimelockActivated = true;

			emit LoanRepaid(_sender, loan.id, loan.market, block.timestamp);
			_updateUtilisationLoan(loan.market, loan.amount, 1);
		}

		else {
			/// Transfer remnant collateral to the user if _commitment != _getCommitment(2)
			ds.collateralToken = IBEP20(_connectMarket(collateral.market));
			ds.collateralToken.transfer(_sender, collateral.amount);
			
			emit LoanRepaid(_sender, loan.id, loan.market, block.timestamp);
			_updateUtilisationLoan(loan.market, loan.amount, 1);
			
			/// COLLATERAL RECORDS
			delete collateral.id;
			delete collateral.market;
			delete collateral.commitment;
			delete collateral.amount;
			delete collateral.isCollateralisedDeposit;
			delete collateral.timelockValidity;
			delete collateral.isTimelockActivated;
			delete collateral.activationTime;

			/// LOAN RECORDS
			delete loan.id;
			delete loan.isSwapped;
			delete loan.lastUpdate;
			
			/// LOAN STATE
			delete loanState.id;
			delete loanState.state;

			/// LOAN ACCOUNT
			delete loanAccount.loans[loan.id - 1];
			delete loanAccount.collaterals[loan.id - 1];
			delete loanAccount.loanState[loan.id - 1];
		}
    }

	function _swapToLoan(
  		address _account,
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _market,
		uint256 _swappedAmount
    ) internal authContract(LOAN_ID) returns (bool)
    {
        AppStorageOpen storage ds = diamondStorage(); 
		_hasLoanAccount(_account);
		
		_isMarketSupported(_market);
		_isMarket2Supported(_swapMarket);

		LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[_account][_market][_commitment];

		require(loan.id != 0, "ERROR: No loan");
		require(loan.isSwapped == true && loanState.currentMarket == _swapMarket, "ERROR: Swapped market does not exist");
		// require(loan.isSwapped == true, "Swapped market does not exist");

		uint256 num = loan.id - 1;

		_swappedAmount = _swap(_account, _swapMarket,_market,loanState.currentAmount, 1);

		/// Updating LoanRecord
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;

		/// updating the LoanState
		loanState.currentMarket = _market;
		loanState.currentAmount = _swappedAmount;

		/// Updating LoanAccount
		ds.loanPassbook[_account].loans[num].isSwapped = false;
		ds.loanPassbook[_account].loans[num].lastUpdate = block.timestamp;
		ds.loanPassbook[_account].loanState[num].currentMarket = _market;
		ds.loanPassbook[_account].loanState[num].currentAmount = _swappedAmount;

		_accruedInterest(_account, _market, _commitment);
		_accruedYield(ds.loanPassbook[_account], collateral, cYield);

		emit MarketSwapped(_account,loan.id,_swapMarket,_market,_swappedAmount);
        return true;
    }
	function _swapToLoanProcess(
		address _account,
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _market,
		uint256 _swappedAmount
	) private returns (bool success){
        AppStorageOpen storage ds = diamondStorage(); 
		_hasLoanAccount(_account);
		
		_isMarketSupported(_market);
		_isMarket2Supported(_swapMarket);

		LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[_account][_market][_commitment];

		require(loan.id != 0, "ERROR: No loan");
		require(loan.isSwapped == true && loanState.currentMarket == _swapMarket, "ERROR: Swapped market does not exist");
		// require(loan.isSwapped == true, "Swapped market does not exist");

		uint256 num = loan.id - 1;

		_swappedAmount = _swap(_account, _swapMarket,_market,loanState.currentAmount, 1);

		/// Updating LoanRecord
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;

		/// updating the LoanState
		loanState.currentMarket = _market;
		loanState.currentAmount = _swappedAmount;

		/// Updating LoanAccount
		ds.loanPassbook[_account].loans[num].isSwapped = false;
		ds.loanPassbook[_account].loans[num].lastUpdate = block.timestamp;
		ds.loanPassbook[_account].loanState[num].currentMarket = _market;
		ds.loanPassbook[_account].loanState[num].currentAmount = _swappedAmount;

		_accruedInterest(_account, _market, _commitment);
		_accruedYield(ds.loanPassbook[_account], collateral, cYield);

		emit MarketSwapped(_account,loan.id,_swapMarket,_market,_swappedAmount);
        success = true;
	}
	
	function _avblReservesLoan(bytes32 _loanMarket) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketReservesLoan[_loanMarket];
	}

	function _utilisedReservesLoan(bytes32 _loanMarket) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketUtilisationLoan[_loanMarket];
	}

	function _updateReservesLoan(bytes32 _loanMarket, uint256 _amount, uint256 _num) internal {
		AppStorageOpen storage ds = diamondStorage(); 
		if (_num == 0) {
			ds.marketReservesLoan[_loanMarket] += _amount;
		} else if (_num == 1) {
			ds.marketReservesLoan[_loanMarket] -= _amount;
		}
	}

	function _updateUtilisationLoan(bytes32 _loanMarket, uint256 _amount, uint256 _num) internal {
		AppStorageOpen storage ds = diamondStorage(); 
		if (_num == 0)	{
			ds.marketUtilisationLoan[_loanMarket] += _amount;
		} else if (_num == 1)	{
			// require(ds.marketUtilisationLoan[_loanMarket] >= _amount, "ERROR: Utilisation is less than amount");
			ds.marketUtilisationLoan[_loanMarket] -= _amount;
		}
	}

	function _collateralPointer(address _account, bytes32 _loanMarket, bytes32 _commitment) internal view returns (bytes32, uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		
		_hasLoanAccount(_account);

		// LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_loanMarket][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_loanMarket][_commitment];

		//require(loan.id !=0, "ERROR: No Loan");
		require(loanState.state == STATE.REPAID, "ERROR: Active loan");
		//if (_commitment != _getCommitment(0)) {
		require((collateral.timelockValidity + collateral.activationTime) >= block.timestamp, "ERROR: Timelock in progress");
		//}		
		bytes32 collateralMarket = collateral.market;
		uint collateralAmount = collateral.amount;

		return (collateralMarket, collateralAmount);
	}

	function _accruedYield(LoanAccount storage loanAccount, CollateralRecords storage collateral, CollateralYield storage cYield) internal {
		bytes32 _commitment = cYield.commitment;
		uint256 aggregateYield;
		uint256 num = collateral.id-1;
		
		(cYield.oldLengthAccruedYield, cYield.oldTime, aggregateYield) = _calcAPY(_commitment, cYield.oldLengthAccruedYield, cYield.oldTime, aggregateYield);

		aggregateYield *= collateral.amount;

		cYield.accruedYield += aggregateYield;
		loanAccount.accruedAPY[num].accruedYield += aggregateYield;
	}

	function _accruedInterest(address _account, bytes32 _loanMarket, bytes32 _commitment) internal /*authContract(LOAN_ID)*/ {
        AppStorageOpen storage ds = diamondStorage(); 

		// emit FairPriceCall(ds.requestEventId++, _loanMarket, ds.indLoanRecords[_account][_loanMarket][_commitment].amount);
		// emit FairPriceCall(ds.requestEventId++, ds.indCollateralRecords[_account][_loanMarket][_commitment].market, ds.indCollateralRecords[_account][_loanMarket][_commitment].amount);

		// LoanAccount storage loanAccount = ds.loanPassbook[_account];
		// LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
		// DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_loanMarket][_commitment];

		require(ds.indLoanState[_account][_loanMarket][_commitment].state == STATE.ACTIVE, "ERROR: Inactive Loan");
		// require(ds.indAccruedAPR[_account][_loanMarket][_commitment].id != 0, "ERROR: APR does not exist");

		uint256 aggregateYield;
		uint256 deductibleUSDValue;
		uint256 oldLengthAccruedInterest;
		uint256 oldTime;

		(oldLengthAccruedInterest, oldTime, aggregateYield) = _calcAPR(
			ds.indLoanRecords[_account][_loanMarket][_commitment].commitment, 
			ds.indAccruedAPR[_account][_loanMarket][_commitment].oldLengthAccruedInterest,
			ds.indAccruedAPR[_account][_loanMarket][_commitment].oldTime, 
			aggregateYield);

		deductibleUSDValue = ((ds.indLoanRecords[_account][_loanMarket][_commitment].amount) * _getLatestPrice(_loanMarket)) * aggregateYield;
		ds.indAccruedAPR[_account][_loanMarket][_commitment].accruedInterest += deductibleUSDValue / _getLatestPrice(ds.indCollateralRecords[_account][_loanMarket][_commitment].market);
		ds.indAccruedAPR[_account][_loanMarket][_commitment].oldLengthAccruedInterest = oldLengthAccruedInterest;
		ds.indAccruedAPR[_account][_loanMarket][_commitment].oldTime = oldTime;

		ds.loanPassbook[_account].accruedAPR[ds.indLoanRecords[_account][_loanMarket][_commitment].id - 1].accruedInterest = ds.indAccruedAPR[_account][_loanMarket][_commitment].accruedInterest;
		ds.loanPassbook[_account].accruedAPR[ds.indLoanRecords[_account][_loanMarket][_commitment].id - 1].oldLengthAccruedInterest = oldLengthAccruedInterest;
		ds.loanPassbook[_account].accruedAPR[ds.indLoanRecords[_account][_loanMarket][_commitment].id - 1].oldTime = oldTime;
	}

  function _hasLoanAccount(address _account) internal view returns (bool) {
    
	AppStorageOpen storage ds = diamondStorage(); 

	require(ds.loanPassbook[_account].accOpenTime !=0, "ERROR: No Loan Account");
	return true;
  }

// =========== Reserve Functions =====================

	function _transferAnyBEP20(address _token, address _sender, address _recipient, uint256 _value) internal authContract(RESERVE_ID) {
		// IBEP20(_token).approveFrom(_sender, address(this), _value);
	    IBEP20(_token).transferFrom(_sender, _recipient, _value);
	}

	function _avblMarketReserves(bytes32 _market) internal view returns (uint) {
		// require((_loanMarketReserves(_loanMarket) - _loanMarketUtilisation(_loanMarket)) >=0, "Mathematical error");
		// return _loanMarketReserves(_loanMarket) - _loanMarketUtilisation(_loanMarket);
		IBEP20 token = IBEP20(_connectMarket(_market));
		uint balance = token.balanceOf(address(this));

		require(balance >= (_marketReserves(_market) - _marketUtilisation(_market)), "ERROR: Reserve imbalance");
		require((_marketReserves(_market) - _marketUtilisation(_market)) >=0, "ERROR: Mathematical error");

		if (balance > (_marketReserves(_market) - _marketUtilisation(_market))) {
			return balance;
		}
		return (_marketReserves(_market) - _marketUtilisation(_market));
  }

	// function _loanMarketReserves(bytes32 _loanMarket) internal view returns (uint) {
	// 	return _avblReservesDeposit(_loanMarket) + _avblReservesLoan(_loanMarket);
	// }

	// function _loanMarketUtilisation(bytes32 _loanMarket) internal view returns (uint) {
	// 	return _utilisedReservesDeposit(_loanMarket) + _utilisedReservesLoan(_loanMarket);
	// }

	function _marketReserves(bytes32 _market) internal view returns (uint) {
        return _avblReservesDeposit(_market) + _avblReservesLoan(_market);
	}

	function _marketUtilisation(bytes32 _market) internal view returns (uint) {
		return _utilisedReservesDeposit(_market) + _utilisedReservesLoan(_market);
	}

// =========== OracleOpen Functions =================
	function _getLatestPrice(bytes32 _market) internal view returns (uint) {
		// Chainlink price
		AppStorageOpen storage ds = diamondStorage();

		require(ds.pairAddresses[_market] != address(0), "ERROR: Invalid pair address");
		( , int price, , , ) = AggregatorV3Interface(ds.pairAddresses[_market]).latestRoundData();
		return uint256(price);

		// Get price from pool with USDC
		// AppStorageOpen storage ds = diamondStorage(); 
		// address[] memory path;
		// path = new address[](2);
		// path[0] = ds.pairAddresses[_market];
		// path[1] = ds.pairAddresses[0x555344432e740000000000000000000000000000000000000000000000000000];
		// require(ds.pairAddresses[_market] != address(0), "ERROR: Invalid pair address");
		// require(path[1] != address(0), "ERROR: Invalid USDT address");

		// uint[] memory amountOut = IPancakeRouter01(PANCAKESWAP_ROUTER_ADDRESS).getAmountsOut(1, path);
		// return amountOut[1];
	}

	function _getFairPrice(uint _requestId) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage();
		require(ds.priceData[_requestId].price != 0, "ERROR: Price fetch failure");
		
		return ds.priceData[_requestId].price;
	}

	function _fairPrice(uint _requestId, uint _fPrice, bytes32 _loanMarket, uint _amount) internal {
		AppStorageOpen storage ds = diamondStorage();
		PriceData storage newPrice = ds.priceData[_requestId];
		newPrice.market = _loanMarket;
		newPrice.amount = _amount;
		newPrice.price = _fPrice;
	}

	modifier authContract(uint _facetId) {
		require(_facetId == diamondStorage().facetIndex[msg.sig] || 
			diamondStorage().facetIndex[msg.sig] == 0, "ERROR: Unauthorised access");
		_;
	}
}