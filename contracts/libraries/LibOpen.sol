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
	address internal constant PANCAKESWAP_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E ; // pancakeswap bsc testnet router address

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

// =========== Liquidator events ===============
// =========== OracleOpen events ===============
	event FairPriceCall(uint requestId, bytes32 market, uint amount);

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

	function setReserveAddress(address _reserve) internal {
		AppStorageOpen storage ds = diamondStorage();
		ds.reserveAddress = _reserve;
	}

	function diamondStorage() internal pure returns (AppStorageOpen storage ds) {
		assembly {
				ds.slot := 0
		}
	}

	function _isMarketSupported(bytes32  _loanMarket) internal view {
		AppStorageOpen storage ds = diamondStorage(); 
		require(ds.tokenSupportCheck[_loanMarket] == true, "ERROR: Unsupported market");
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
		require(marketData.minAmount <= _amount, "ERROR: Less than minimum deposit");
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

	function _connectMarket(bytes32 _loanMarket) internal view returns (address) {
		
		AppStorageOpen storage ds = diamondStorage(); 
		MarketData memory marketData = ds.indMarketData[_loanMarket];

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
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _loanMarket
	) internal authContract(LOAN_ID) returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
		_hasLoanAccount(_account);
		_isMarketSupported(_loanMarket);
		_isMarket2Supported(_swapMarket);

		LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_loanMarket][_commitment];
		// CollateralRecords storage collateral = ds.indCollateralRecords[_account][_loanMarket][_commitment];
		// CollateralYield storage cYield = ds.indAccruedAPY[_account][_loanMarket][_commitment];

		require(loan.id != 0, "ERROR: No loan");
		require(loan.isSwapped == true && loanState.currentMarket == _swapMarket, "ERROR: Swapped market does not exist");
		// require(loan.isSwapped == true, "Swapped market does not exist");

		uint swappedAmount = _swap(_account, _swapMarket,_loanMarket,loanState.currentAmount, 1);

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
// =========== Liquidator Functions ===========
	function _swap(address sender, bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 _mode) internal returns (uint256) {
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
		// IBEP20(addrFromMarket).approveFrom(msg.sender, address(this), _fromAmount);
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
		require(loanState.state == ILoan.STATE.REPAID, "ERROR: Active loan");
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

		require(ds.indLoanState[_account][_loanMarket][_commitment].state == ILoan.STATE.ACTIVE, "ERROR: Inactive Loan");
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
		AppStorageOpen storage ds = diamondStorage();
		require(ds.pairAddresses[_market] != address(0), "ERROR: Invalid pair address");
		( , int price, , , ) = AggregatorV3Interface(ds.pairAddresses[_market]).latestRoundData();
		return uint256(price);
	}

	function _getFairPrice(uint _requestId) internal view returns (uint retPrice) {
		AppStorageOpen storage ds = diamondStorage();
		require(ds.priceData[_requestId].price != 0, "ERROR: Price fetch failure");
		
		retPrice = ds.priceData[_requestId].price;
		return retPrice;
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
			diamondStorage().facetIndex[msg.sig] == 0, "Not permitted function call");
		_;
	}
}