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
import "../interfaces/ILoan1.sol";
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
	uint8 constant LOAN1_ID = 16;
	uint8 constant DEPOSIT_ID = 17; 
	uint8 constant ACCESSREGISTRY_ID = 18;
	address internal constant PANCAKESWAP_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 ; // pancakeswap bsc testnet router address

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	
// =========== Loan events ===============
	/// EVENTS
	event NewLoan(
		address indexed account,
		bytes32 loanMarket,
		bytes32 commitment,
		uint256 loanAmount,
		bytes32 collateralMarket,
		uint256 collateralAmount,
		uint256 indexed loanId
	);
	event LoanRepaid(
		address indexed account,
		uint256 indexed id,
		bytes32 indexed market,
		uint256 timestamp
	);
	event WithdrawalProcessed(
		address indexed account,
		uint256 indexed id,
		uint256 indexed amount,
		bytes32 market,
		uint256 timestamp
	);
	event MarketSwapped(
		address indexed account,
		uint256 indexed loanid,
		bytes32 marketFrom,
		bytes32 marketTo,
		uint256 amount
	);
	event CollateralReleased(
		address indexed account,
		uint256 indexed amount,
		bytes32 indexed market,
		uint256 timestamp
	);

	event AddCollateral(
		address indexed account,
		uint256 indexed id,
		uint256 amount,
		uint256 timestamp
	);

	event Liquidation(
		address indexed account,
		bytes32 indexed market,
		bytes32 indexed commitment,
		uint256 amount,
		uint256 time
	);

// =========== Liquidator events ===============
// =========== OracleOpen events ===============
	event FairPriceCall(uint requestId, bytes32 market, uint amount);

// =========== AccessRegistry events ===============
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
    
	function _addFairPriceAddress(bytes32 _market, address _address) internal {
        AppStorageOpen storage ds = diamondStorage();
		ds.pairAddresses[_market] = _address;
	}

	function _getFairPriceAddress(bytes32 _market) internal view returns (address){
        AppStorageOpen storage ds = diamondStorage();
		return ds.pairAddresses[_market];
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

    function _isMarketSupported(bytes32  _market) internal view {
        AppStorageOpen storage ds = diamondStorage(); 
		require(ds.tokenSupportCheck[_market] == true, "ERROR: Unsupported market");
	}

	function _getMarketAddress(bytes32 _market) internal view returns (address) {
		AppStorageOpen storage ds = diamondStorage(); 
    	return ds.indMarketData[_market].tokenAddress;
	}

	function _getMarketDecimal(bytes32 _market) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage(); 
    	return ds.indMarketData[_market].decimals;
	}

	function _minAmountCheck(bytes32 _market, uint _amount) internal view {
		AppStorageOpen storage ds = diamondStorage(); 
		MarketData memory marketData = ds.indMarketData[_market];
		require(marketData.minAmount <= _amount, "ERROR: Less than minimum deposit");
	}

	// function _quantifyAmount(bytes32 _market, uint _amount) internal view returns (uint amount) {
	// 	AppStorageOpen storage ds = diamondStorage(); 
	//     MarketData memory marketData = ds.indMarketData[_market];
    // 	amount = _amount * marketData.decimals;
	// }

    function _isMarket2Supported(bytes32  _market) internal view {
		require(diamondStorage().token2SupportCheck[_market] == true, "Secondary Token is not supported");
	}

	function _getMarket2Address(bytes32 _market) internal view returns (address) {
		AppStorageOpen storage ds = diamondStorage(); 
    	return ds.indMarket2Data[_market].tokenAddress;
	}

	function _getMarket2Decimal(bytes32 _market) internal view returns (uint) {
		AppStorageOpen storage ds = diamondStorage();
	    return ds.indMarket2Data[_market].decimals;
	}

    function _connectMarket(bytes32 _market) internal view returns (address addr) {
        AppStorageOpen storage ds = diamondStorage(); 
        MarketData memory marketData = ds.indMarketData[_market];
		addr = marketData.tokenAddress;
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
// =========== Liquidator Functions ===========
    function _swap(bytes32 _fromMarket, bytes32 _toMarket, uint256 _fromAmount, uint8 _mode) internal returns (uint256 receivedAmount) {
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
		IBEP20(addrFromMarket).approveFrom(msg.sender, address(this), _fromAmount);
		IBEP20(addrFromMarket).transferFrom(msg.sender, address(this), _fromAmount);
        IBEP20(addrFromMarket).approve(PANCAKESWAP_ROUTER_ADDRESS, _fromAmount);

		//WBNB as other test tokens
        address[] memory path;
//        if (addrFromMarket == WBNB || addrToMarket == WBNB) {
            path = new address[](2);
            path[0] = addrFromMarket;
            path[1] = addrToMarket;
        // } else {
        //     path = new address[](3);
        //     path[0] = addrFromMarket;
        //     path[1] = WBNB;
        //     path[2] = addrToMarket;
        // }

        IPancakeRouter01(PANCAKESWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
            _fromAmount,
            _getAmountOutMin(addrFromMarket, addrToMarket, _fromAmount),
            path,
            address(this),
            block.timestamp
        );
		return receivedAmount;
    }

	function _getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn
    ) private view returns (uint) {
        address[] memory path;
//        if (_tokenIn == WBNB || _tokenOut == WBNB) {
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
    function _hasDeposit(address _account, bytes32 _market, bytes32 _commitment) internal view returns(bool ret) {
        AppStorageOpen storage ds = diamondStorage();
		ret = ds.indDepositRecord[_account][_market][_commitment].id != 0;
		// require (ds.indDepositRecord[_account][_market][_commitment].id != 0, "ERROR: No deposit");
		// return true;
	}

    function _avblReservesDeposit(bytes32 _market) internal view returns (uint) {
        AppStorageOpen storage ds = diamondStorage(); 
        return ds.marketReservesDeposit[_market];
    }

    function _utilisedReservesDeposit(bytes32 _market) internal view returns (uint) {
        AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketUtilisationDeposit[_market];
    }

    function _avblReservesLoan(bytes32 _market) internal view returns (uint) {
        AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketReservesLoan[_market];
    }

    function _utilisedReservesLoan(bytes32 _market) internal view returns (uint) {
        AppStorageOpen storage ds = diamondStorage(); 
		return ds.marketUtilisationLoan[_market];
    }

    function _accruedYield(address _account,bytes32 _market,bytes32 _commitment) internal authContract(DEPOSIT_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
		
		_hasDeposit(_account, _market, _commitment);

		uint256 aggregateYield;

		SavingsAccount storage savingsAccount = ds.savingsPassbook[_account];
		DepositRecords storage deposit = ds.indDepositRecord[_account][_market][_commitment];
		YieldLedger storage yield = ds.indYieldRecord[_account][_market][_commitment];

		(yield.oldLengthAccruedYield, yield.oldTime, aggregateYield) = _calcAPY(_commitment, yield.oldLengthAccruedYield, yield.oldTime, aggregateYield);

		aggregateYield *= deposit.amount;

		yield.accruedYield += aggregateYield;
		savingsAccount.yield[deposit.id-1].accruedYield += aggregateYield;

	}

    function _preDepositProcess(
		bytes32 _market,
		uint256 _amount
		// SavingsAccount memory savingsAccount
	) internal {
    	AppStorageOpen storage ds = diamondStorage(); 

		_isMarketSupported(_market);
		ds.token = IBEP20(_connectMarket(_market));
		// _quantifyAmount(_market, _amount);
		_minAmountCheck(_market, _amount);
	}


	function _hasAccount(address _account) internal view {
        AppStorageOpen storage ds = diamondStorage(); 
		require(ds.savingsPassbook[_account].accOpenTime!=0, "ERROR: No savings account");
	}

	function _hasYield(YieldLedger memory yield) internal pure {
		require(yield.id !=0, "ERROR: No Yield");
	}

    function _updateReservesDeposit(bytes32 _market, uint _amount, uint _num) internal authContract(DEPOSIT_ID) {
        AppStorageOpen storage ds = diamondStorage();
		if (_num == 0)	{
			ds.marketReservesDeposit[_market] += _amount;
		} else if (_num == 1)	{
			ds.marketReservesDeposit[_market] -= _amount;
		}
	}

    function _ensureSavingsAccount(address _account, SavingsAccount storage savingsAccount) internal {

		if (savingsAccount.accOpenTime == 0) {

			savingsAccount.accOpenTime = block.timestamp;
			savingsAccount.account = _account;
		}
	}

// =========== Loan Functions ===========
    function _updateReservesLoan(bytes32 _market, uint256 _amount, uint256 _num) private {
        AppStorageOpen storage ds = diamondStorage(); 
		if (_num == 0) {
			ds.marketReservesLoan[_market] += _amount;
		} else if (_num == 1) {
			ds.marketReservesLoan[_market] -= _amount;
		}
	}

	function _updateUtilisationLoan(bytes32 _market, uint256 _amount, uint256 _num) private {
        AppStorageOpen storage ds = diamondStorage(); 
		if (_num == 0)	{
			ds.marketUtilisationLoan[_market] += _amount;
		} else if (_num == 1)	{
			ds.marketUtilisationLoan[_market] -= _amount;
		}
	}

    function _swapToLoan(
  		address _account,
		bytes32 _swapMarket,
		bytes32 _commitment,
		bytes32 _market,
		uint256 _swappedAmount
    ) internal authContract(LOAN_ID) returns (bool success)
    {
        return _swapToLoanProcess(_account, _swapMarket, _commitment, _market, _swappedAmount);
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

		_swappedAmount = _swap(_swapMarket,_market,loanState.currentAmount, 1);

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

    function _withdrawCollateral(address _account, bytes32 _market, bytes32 _commitment) internal authContract(LOAN_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
        LoanAccount storage loanAccount = ds.loanPassbook[_account];
		LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
		// LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];

		_isMarketSupported(_market);
		require(ds.marketReservesLoan[collateral.market] >= collateral.amount, "Not enough fund in reserve");
		//Below are checked in _collateralPointer

		// _hasLoanAccount(_account);
		// require(loan.id !=0, "ERROR: No Loan");
		// require(loanState.state == ILoan.STATE.REPAID, "ERROR: Active loan");
		// if (_commitment != _getCommitment(0)) {
		// 	require((collateral.timelockValidity + collateral.activationTime) >= block.timestamp, "ERROR: Timelock in progress");
		// }

//		_collateralTransfer(_account, loan.market, loan.commitment);

        uint collateralAmount;

		(, collateralAmount) = _collateralPointer(_account,_market,_commitment);
		ds.token = IBEP20(_connectMarket(collateral.market));
		ds.token.approveFrom(ds.reserveAddress, address(this), collateralAmount);
        ds.token.transferFrom(ds.reserveAddress, _account, collateralAmount);

		delete ds.indCollateralRecords[_account][loan.market][loan.commitment];
		delete ds.indLoanState[_account][loan.market][loan.commitment];
		delete ds.indLoanRecords[_account][loan.market][loan.commitment];

		// delete loanAccount.loanState[loan.id-1];
		// delete loanAccount.loans[loan.id-1];
		// delete loanAccount.collaterals[loan.id-1];
        _updateReservesLoan(collateral.market, collateral.amount, 1);

		emit CollateralReleased(_account, collateral.amount, collateral.market, block.timestamp);
	}

	function _collateralPointer(address _account, bytes32 _market, bytes32 _commitment) internal view returns (bytes32 collateralMarket, uint collateralAmount) {
		AppStorageOpen storage ds = diamondStorage(); 
		
		_hasLoanAccount(_account);

		// LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];

		//require(loan.id !=0, "ERROR: No Loan");
		require(loanState.state == ILoan.STATE.REPAID, "ERROR: Active loan");
		//if (_commitment != _getCommitment(0)) {
			require((collateral.timelockValidity + collateral.activationTime) >= block.timestamp, "ERROR: Timelock in progress");
		//}		
		collateralMarket = collateral.market;
		collateralAmount = collateral.amount;
	}

    function _accruedYield(LoanAccount storage loanAccount, CollateralRecords storage collateral, CollateralYield storage cYield) private {
		bytes32 _commitment = cYield.commitment;
		uint256 aggregateYield;
		uint256 num = collateral.id-1;
		
		(cYield.oldLengthAccruedYield, cYield.oldTime, aggregateYield) = _calcAPY(_commitment, cYield.oldLengthAccruedYield, cYield.oldTime, aggregateYield);

		aggregateYield *= collateral.amount;

		cYield.accruedYield += aggregateYield;
		loanAccount.accruedAPY[num].accruedYield += aggregateYield;
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
		loanState.state = ILoan.STATE.REPAID;

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
		loanAccount.loanState[num].state = ILoan.STATE.REPAID;
		
		loanAccount.collaterals[num].isCollateralisedDeposit = false;
		loanAccount.collaterals[num].isTimelockActivated = true;
		loanAccount.collaterals[num].activationTime = block.timestamp;

		
		delete loanAccount.accruedAPY[num];
		delete loanAccount.accruedAPR[num];
	}

	function _accruedInterest(address _account, bytes32 _loanMarket, bytes32 _commitment) private /*authContract(LOAN_ID)*/ {
        AppStorageOpen storage ds = diamondStorage(); 

		// emit FairPriceCall(ds.requestEventId++, _loanMarket, ds.indLoanRecords[_account][_loanMarket][_commitment].amount);
		// emit FairPriceCall(ds.requestEventId++, ds.indCollateralRecords[_account][_loanMarket][_commitment].market, ds.indCollateralRecords[_account][_loanMarket][_commitment].amount);

		// LoanAccount storage loanAccount = ds.loanPassbook[_account];
		// LoanRecords storage loan = ds.indLoanRecords[_account][_loanMarket][_commitment];
		// DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_loanMarket][_commitment];

		require(ds.indLoanState[_account][_loanMarket][_commitment].state == ILoan.STATE.ACTIVE, "ERROR: INACTIVE LOAN");
		require(ds.indAccruedAPR[_account][_loanMarket][_commitment].id != 0, "ERROR: APR does not exist");

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

    function _checkPermissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount, address _sender) private /*authContract(LOAN_ID)*/ {

		
        AppStorageOpen storage ds = diamondStorage(); 
		// LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
		// DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_sender][_market][_commitment];
		// emit FairPriceCall(ds.requestEventId++, _collateralMarket, _amount);
		// emit FairPriceCall(ds.requestEventId++, _market, _amount);
		// emit FairPriceCall(ds.requestEventId++, loanState.currentMarket, loanState.currentAmount);		
		// _quantifyAmount(loanState.currentMarket, _amount);
		require(_amount <= loanState.currentAmount, "ERROR: Exceeds available loan");
		
		_accruedInterest(_sender, _market, _commitment);
		uint256 collateralAvbl = collateral.amount - ds.indAccruedAPR[_sender][_market][_commitment].accruedInterest;

		// fetch usdPrices
		uint256 usdCollateral = _getLatestPrice(_collateralMarket);
		uint256 usdLoan = _getLatestPrice(_market);
		uint256 usdLoanCurrent = _getLatestPrice(loanState.currentMarket);

		// Quantification of the assets
		// uint256 cAmount = usdCollateral*collateral.amount;
		// uint256 cAmountAvbl = usdCollateral*collateralAvbl;

		// uint256 lAmountCurrent = usdLoanCurrent*loanState.currentAmount;
		uint256 permissibleAmount = ((usdCollateral*collateralAvbl - (30*usdCollateral*collateral.amount/100))/usdLoanCurrent);

		require(permissibleAmount > 0, "ERROR: Can not withdraw zero funds");
		require(permissibleAmount > (_amount), "ERROR:Request exceeds funds");
		
		// calcualted in usdterms
		require((usdCollateral*collateralAvbl + usdLoanCurrent*loanState.currentAmount - (_amount*usdLoanCurrent)) >= (11*(usdLoan*ds.indLoanRecords[_sender][_market][_commitment].amount)/10), "ERROR: Risks liquidation");
	}

	function _repaymentProcess(
		address _account,
		uint256 _repayAmount,
		LoanAccount storage loanAccount,
		LoanRecords storage loan,
		LoanState storage loanState,
		CollateralRecords storage collateral,
		DeductibleInterest storage deductibleInterest,
		CollateralYield storage cYield
	) private {
        AppStorageOpen storage ds = diamondStorage(); 
		
		bytes32 _commitment = loan.commitment;
		uint256 num = loan.id - 1;
		
		// convert collateral into loan market to add to the repayAmount
		uint256 collateralAmount = collateral.amount - (deductibleInterest.accruedInterest + cYield.accruedYield);
		_repayAmount += _swap(collateral.market,loan.market,collateralAmount,2);

		require(_repayAmount > loan.amount, "Repay Amount is smaller than loan Amount");

		// Excess amount is tranferred back to the collateral record
		uint256 _remnantAmount = _repayAmount - loan.amount;
		collateral.amount = _swap(loan.market,collateral.market,_remnantAmount,2);

		/// updating LoanRecords
		loan.amount = 0;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		/// updating LoanState
		loanState.actualLoanAmount = 0;
		loanState.currentAmount = 0;
		loanState.state = ILoan.STATE.REPAID;

		delete ds.indAccruedAPR[_account][loan.market][loan.commitment];
		delete ds.indAccruedAPY[_account][loan.market][loan.commitment];

		delete loanAccount.accruedAPR[num];
		delete loanAccount.accruedAPY[num];
		
		emit LoanRepaid(_account, loan.id, loan.market, block.timestamp);

		if (_commitment == _getCommitment(2)) {
			/// updating CollateralRecords
			collateral.isCollateralisedDeposit = false;
			collateral.isTimelockActivated = true;
			collateral.activationTime = block.timestamp;

		} else if (_commitment == _getCommitment(0)) {
			/// transfer collateral.amount from reserve contract to the _sender
			ds.collateralToken = IBEP20(_connectMarket(collateral.market));
			// reserveAddress.transferAnyBEP20(collateralToken, loanAccount.account, collateral.amount);

			/// delete loan Entries, loanRecord, loanstate, collateralrecords
			// delete loanState;
			// delete loan;
			// delete collateral;
			delete ds.indCollateralRecords[_account][loan.market][loan.commitment];
			delete ds.indLoanState[_account][loan.market][loan.commitment];
			delete ds.indLoanRecords[_account][loan.market][loan.commitment];

			delete loanAccount.collaterals[num];
			delete loanAccount.loanState[num];
			delete loanAccount.loans[num];

			_updateReservesLoan(collateral.market, collateral.amount, 1);
			emit CollateralReleased(_account,collateral.amount,collateral.market,block.timestamp);
		}
	}

    function _preLoanRequestProcess(
		bytes32 _market,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) private {
        AppStorageOpen storage ds = diamondStorage(); 
		require(
			_loanAmount != 0 && _collateralAmount != 0,
			"Loan or collateral cannot be zero"
		);

		_permissibleCDR(_market,_collateralMarket,_loanAmount,_collateralAmount);

		// Check for amrket support
		_isMarketSupported(_market);
		_isMarketSupported(_collateralMarket);

		// _quantifyAmount(_market, _loanAmount);
		// _quantifyAmount(_collateralMarket, _collateralAmount);

		// check for minimum permissible amount
		_minAmountCheck(_market, _loanAmount);
		_minAmountCheck(_collateralMarket, _collateralAmount);

		// Connect
		ds.loanToken = IBEP20(_connectMarket(_market));
		ds.collateralToken = IBEP20(_connectMarket(_collateralMarket));	
	}

	function _processNewLoan(
		address _account,
		bytes32 _market,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount
	) private {
        AppStorageOpen storage ds = diamondStorage();
		// uint256 id;

		LoanAccount storage loanAccount = ds.loanPassbook[_account];
		LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
		DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[_account][_market][_commitment];

		// if (loanAccount.loans.length == 0) {
		// 	id = 1;
		// } else if (loanAccount.loans.length != 0) {
			// id = loanAccount.loans.length + 1;
		// }

		
		// Updating loanRecords
		loan.id = loanAccount.loans.length + 1;
		loan.market = _market;
		loan.commitment = _commitment;
		loan.amount = _loanAmount;
		loan.isSwapped = false;
		loan.lastUpdate = block.timestamp;
		
		// Updating deductibleInterest
		deductibleInterest.id = loanAccount.loans.length + 1;
		deductibleInterest.market = _collateralMarket;
		deductibleInterest.oldTime= block.timestamp;
		deductibleInterest.accruedInterest = 0;

		// Updating loanState
		loanState.id = loanAccount.loans.length + 1;
		loanState.loanMarket = _market;
		loanState.actualLoanAmount = _loanAmount;
		loanState.currentMarket = _market;
		loanState.currentAmount = _loanAmount;
		loanState.state = ILoan.STATE.ACTIVE;

		collateral.id= loanAccount.loans.length + 1;
		collateral.market= _collateralMarket;
		collateral.commitment= _commitment;
		collateral.amount = _collateralAmount;

		loanAccount.loans.push(loan);
		loanAccount.loanState.push(loanState);

		if (_commitment == _getCommitment(0)) {
			
			collateral.isCollateralisedDeposit = false;
			collateral.timelockValidity = 0;
			collateral.isTimelockActivated = true;
			collateral.activationTime = 0;

			// pays 18% APR
			deductibleInterest.oldLengthAccruedInterest = _getAprTimeLength(_commitment);

			loanAccount.collaterals.push(collateral);
			loanAccount.accruedAPR.push(deductibleInterest);
			// loanAccount.accruedAPY.push(accruedYield); - no yield because it is
			// a flexible loan
		} else if (_commitment == _getCommitment(2)) {
			
			collateral.isCollateralisedDeposit = true;
			collateral.timelockValidity = 86400;
			collateral.isTimelockActivated = false;
			collateral.activationTime = 0;

			// 15% APR
			deductibleInterest.oldLengthAccruedInterest = _getAprTimeLength(_commitment);
			
			cYield.id = loanAccount.loans.length + 1;
			cYield.market = _collateralMarket;
			cYield.commitment = _getCommitment(1);
			cYield.oldLengthAccruedYield = _getApyTimeLength(_commitment);
			cYield.oldTime = block.timestamp;
			cYield.accruedYield =0;

			loanAccount.collaterals.push(collateral);
			loanAccount.accruedAPY.push(cYield);
			loanAccount.accruedAPR.push(deductibleInterest);
		}
		_updateUtilisationLoan(_market, _loanAmount, 0);
	}

	function _preAddCollateralProcess(
		bytes32 _collateralMarket,
		uint256 _collateralAmount,
		LoanAccount storage loanAccount,
		LoanRecords storage loan,
		LoanState storage loanState,
		CollateralRecords storage collateral
	) internal view {
		require(loanAccount.accOpenTime != 0, "ERROR: No Loan account");
		require(loan.id != 0, "ERROR: No loan");
		require(loanState.state == ILoan.STATE.ACTIVE, "ERROR: Inactive loan");
		require(collateral.market == _collateralMarket, "ERROR: Mismatch collateral market");

		_isMarketSupported(_collateralMarket);
		_minAmountCheck(_collateralMarket, _collateralAmount);
	}

	function _ensureLoanAccount(address _account) private {
        AppStorageOpen storage ds = diamondStorage();
		LoanAccount storage loanAccount = ds.loanPassbook[_account];
		if (loanAccount.accOpenTime == 0) {
			loanAccount.accOpenTime = block.timestamp;
			loanAccount.account = _account;
		}
	}

	function _permissibleCDR (
        bytes32 _market,
        bytes32 _collateralMarket,
        uint256 _loanAmount,
        uint256 _collateralAmount
    ) internal view{
		// emit FairPriceCall(ds.requestEventId++, _market, _loanAmount);
		// emit FairPriceCall(ds.requestEventId++, _collateralMarket, _collateralAmount);

        uint256 loanByCollateral;
        uint256 amount = _avblMarketReserves(_market) - _loanAmount ;
        uint rF = _getReserveFactor()* _marketReserves(_market);

        uint256 usdLoan = (_getLatestPrice(_market)) * _loanAmount;
        uint256 usdCollateral = (_getLatestPrice(_collateralMarket)) * _collateralAmount;

        require(amount > 0, "ERROR: Loan exceeds reserves");
        require(_marketReserves(_market) >= rF + amount, "ERROR: Minimum reserve exeception");
        require (usdLoan/usdCollateral <=3, "ERROR: Exceeds permissible CDR");

        // calculating cdrPermissible.
        if (_marketReserves(_market) >= amount + 3*_marketReserves(_market)/4)    {
            loanByCollateral = 3;
        } else     {
            loanByCollateral = 2;
        }
        require (usdLoan/usdCollateral <= loanByCollateral, "ERROR: Exceeds permissible CDR");
    }

    function _addCollateral(
        bytes32 _market,
		bytes32 _commitment,
		bytes32 _collateralMarket,
		uint256 _collateralAmount,
		address _sender
    ) internal authContract(LOAN1_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
        LoanAccount storage loanAccount = ds.loanPassbook[_sender];
		LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[_sender][_market][_commitment];

		_preAddCollateralProcess(_collateralMarket, _collateralAmount, loanAccount, loan,loanState, collateral);

		ds.collateralToken = IBEP20(_connectMarket(_collateralMarket));
		// _quantifyAmount(_collateralMarket, _collateralAmount);
		ds.collateralToken.approveFrom(_sender, address(this), _collateralAmount);
		ds.collateralToken.transferFrom(_sender, ds.reserveAddress, _collateralAmount);
		_updateReservesLoan(_collateralMarket, _collateralAmount, 0);
		
		_addCollateralAmount(loanAccount, collateral, _collateralAmount, loan.id-1);
		_accruedInterest(_sender, _market, _commitment);

		if (collateral.isCollateralisedDeposit) _accruedYield(loanAccount, collateral, cYield);

		emit AddCollateral(_sender, loan.id, _collateralAmount, block.timestamp);
    }

	function _addCollateralAmount(
		LoanAccount storage loanAccount,
		CollateralRecords storage collateral,
		uint256 _collateralAmount,
		uint256 num
	) private {
		collateral.amount += _collateralAmount;
		loanAccount.collaterals[num].amount = _collateralAmount;
	}

    function _swapLoan(
		address _sender,
        bytes32 _market,
		bytes32 _commitment,
		bytes32 _swapMarket
    ) internal authContract(LOAN_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
        _hasLoanAccount(_sender);
		
		_isMarketSupported(_market);
		_isMarket2Supported(_swapMarket);

		LoanAccount storage loanAccount = ds.loanPassbook[_sender];
		LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
		CollateralYield storage cYield = ds.indAccruedAPY[_sender][_market][_commitment];

		require(loan.id != 0, "ERROR: No loan");
		require(loan.isSwapped == false && loanState.currentMarket == _market, "ERROR: Already swapped");

		uint256 _swappedAmount;
		uint256 num = loan.id - 1;

		_swappedAmount = _swap(_market, _swapMarket, loan.amount, 0);

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

		_accruedInterest(_sender, _market, _commitment);
		if (collateral.isCollateralisedDeposit) _accruedYield(loanAccount, collateral, cYield);

		emit MarketSwapped(_sender,loan.id,_market,_swapMarket, loan.amount);
    }

    function _loanRequest(
        bytes32 _market,
		bytes32 _commitment,
		uint256 _loanAmount,
		bytes32 _collateralMarket,
		uint256 _collateralAmount,
		address _sender
    ) internal authContract(LOAN1_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
		console.log("avblReserve is %s loanAmount is %s", _avblMarketReserves(_market), _loanAmount);	
		require(_avblMarketReserves(_market) >= _loanAmount, "ERROR: Borrow amount exceeds reserves");
        _preLoanRequestProcess(_market,_loanAmount,_collateralMarket,_collateralAmount);

		// LoanAccount storage loanAccount = ds.loanPassbook[_sender];
		LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];

		require(loan.id == 0, "ERROR: Active loan");
		ds.collateralToken.approveFrom(_sender, address(this), _collateralAmount);
		ds.collateralToken.transferFrom(_sender, ds.reserveAddress, _collateralAmount);

		_updateReservesLoan(_collateralMarket,_collateralAmount, 0);
		_ensureLoanAccount(_sender);

		_processNewLoan(_sender,_market,_commitment,_loanAmount,_collateralMarket,_collateralAmount);

		emit NewLoan(_sender, _market, _commitment, _loanAmount, _collateralMarket, _collateralAmount, ds.loanPassbook[_sender].loans.length+1);
    }

    function _repayLoan(bytes32 _market,bytes32 _commitment,uint256 _repayAmount, address _sender) internal authContract(LOAN_ID) {
        // AppStorageOpen storage ds = diamondStorage(); 
        _hasLoanAccount(_sender);
		// LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
		// LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
		// CollateralRecords storage collateral = ds.indCollateralRecords[_sender][_market][_commitment];
		// DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_sender][_market][_commitment];
		// CollateralYield storage cYield = ds.indAccruedAPY[_sender][_market][_commitment];		
		
		require(diamondStorage().indLoanRecords[_sender][_market][_commitment].id != 0,"ERROR: No Loan");
		_isMarketSupported(_market);
		
		_accruedInterest(_sender, _market, _commitment);
		_accruedYield(diamondStorage().loanPassbook[_sender], diamondStorage().indCollateralRecords[_sender][_market][_commitment], diamondStorage().indAccruedAPY[_sender][_market][_commitment]);

		if (_repayAmount == 0) {
			// converting the current market into loanMarket for repayment.
			if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market)	_repayAmount = diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
			else if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket != _market)	_repayAmount = _swap(diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _market,diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount, 1);
			
			_repaymentProcess(
				_sender,
				_repayAmount, 
				diamondStorage().loanPassbook[_sender],
				diamondStorage().indLoanRecords[_sender][_market][_commitment],
				diamondStorage().indLoanState[_sender][_market][_commitment],
				diamondStorage().indCollateralRecords[_sender][_market][_commitment],
				diamondStorage().indAccruedAPR[_sender][_market][_commitment], 
				diamondStorage().indAccruedAPY[_sender][_market][_commitment]);
			
			// if (loanState.currentMarket == _market) {
			// 	_repayAmount = loanState.currentAmount;
			// 	_repaymentProcess(_sender,_repayAmount,loanPassbook[_sender],loan,loanState,collateral,deductibleInterest,cYield);
				
			// } else if (loanState.currentMarket != _market) {
			// 	_repayAmount = liquidator.swap(loanState.currentMarket,_market,loanState.currentAmount, 1);
			// 	_repaymentProcess(_sender,_repayAmount,loanPassbook[_sender],loan,loanState,collateral,deductibleInterest,cYield);
			// }
		}
		else if (_repayAmount > 0) {
			/// transfering the repayAmount to the reserve contract.
			diamondStorage().loanToken = IBEP20(_connectMarket(_market));
			// _quantifyAmount(_market, _repayAmount);

			diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount += (diamondStorage().indAccruedAPY[_sender][_market][_commitment].accruedYield - diamondStorage().indAccruedAPR[_sender][_market][_commitment].accruedInterest);
			
			uint256 _swappedAmount;
			uint256 _remnantAmount;

			if (_repayAmount >= diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
				_remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;
				if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market){
					_remnantAmount += diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
				}
				else {
					_swapToLoanProcess(_sender, diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _commitment, _market, _swappedAmount);
					_repayAmount += _swappedAmount;
				}

				_updateDebtRecords(diamondStorage().loanPassbook[_sender],diamondStorage().indLoanRecords[_sender][_market][_commitment],diamondStorage().indLoanState[_sender][_market][_commitment],diamondStorage().indCollateralRecords[_sender][_market][_commitment]/*, deductibleInterest, cYield*/);
				diamondStorage().loanToken.approveFrom(diamondStorage().reserveAddress, address(this), _remnantAmount);
				diamondStorage().loanToken.transferFrom(diamondStorage().reserveAddress, diamondStorage().loanPassbook[_sender].account, _remnantAmount);

				emit LoanRepaid(_sender, diamondStorage().indLoanRecords[_sender][_market][_commitment].id, diamondStorage().indLoanRecords[_sender][_market][_commitment].market, block.timestamp);
				
				if (_commitment == _getCommitment(0)) {
					/// transfer collateral.amount from reserve contract to the _sender
					// collateralToken = IBEP20(markets.connectMarket(collateral.market));
					_transferAnyBEP20(_connectMarket(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market), _sender, diamondStorage().loanPassbook[_sender].account,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount);

			/// delete loan Entries, loanRecord, loanstate, collateralrecords
					// delete loanState;
					// delete loan;
					// delete collateral;

					delete diamondStorage().indLoanRecords[_sender][_market][_commitment];
					delete diamondStorage().indLoanState[_sender][_market][_commitment];
					delete diamondStorage().indCollateralRecords[_sender][_market][_commitment];


					delete diamondStorage().loanPassbook[_sender].loanState[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
					delete diamondStorage().loanPassbook[_sender].loans[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
					delete diamondStorage().loanPassbook[_sender].collaterals[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
					
					_updateReservesLoan(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
					emit CollateralReleased(_sender,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,block.timestamp);
				}
			} else if (_repayAmount < diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {

				if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket == _market)	_repayAmount += diamondStorage().indLoanState[_sender][_market][_commitment].currentAmount;
				else if (diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket != _market) {
					_swapToLoanProcess(_sender, diamondStorage().indLoanState[_sender][_market][_commitment].currentMarket, _commitment, _market, _swappedAmount);
					_repayAmount += _swappedAmount;
				}
				
				if (_repayAmount > diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
					_remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;
					diamondStorage().loanToken.approveFrom(diamondStorage().reserveAddress, address(this), _remnantAmount);
					diamondStorage().loanToken.transferFrom(diamondStorage().reserveAddress, diamondStorage().loanPassbook[_sender].account, _remnantAmount);
				} else if (_repayAmount <= diamondStorage().indLoanRecords[_sender][_market][_commitment].amount) {
					
					_repayAmount += _swap(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,_market,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
					// _repayAmount += _swapToLoanProcess(loanState.currentMarket, _commitment, _market);
					_remnantAmount = _repayAmount - diamondStorage().indLoanRecords[_sender][_market][_commitment].amount;
					diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount += _swap(diamondStorage().indLoanRecords[_sender][_market][_commitment].market,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,_remnantAmount, 2);
				}
				_updateDebtRecords(diamondStorage().loanPassbook[_sender],diamondStorage().indLoanRecords[_sender][_market][_commitment],diamondStorage().indLoanState[_sender][_market][_commitment],diamondStorage().indCollateralRecords[_sender][_market][_commitment]/*, deductibleInterest, cYield*/);
				
				if (_commitment == _getCommitment(0)) {
					
					// collateralToken = IBEP20(markets.connectMarket(collateral.market));
					_transferAnyBEP20(_connectMarket(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market), _sender, diamondStorage().loanPassbook[_sender].account, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount);


				/// delete loan Entries, loanRecord, loanstate, collateralrecords
					// delete loanState;
					// delete loan;
					// delete collateral;
					delete diamondStorage().indLoanRecords[_sender][_market][_commitment];
					delete diamondStorage().indLoanState[_sender][_market][_commitment];
					delete diamondStorage().indCollateralRecords[_sender][_market][_commitment];

					delete diamondStorage().loanPassbook[_sender].loanState[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
					delete diamondStorage().loanPassbook[_sender].loans[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
					delete diamondStorage().loanPassbook[_sender].collaterals[diamondStorage().indLoanRecords[_sender][_market][_commitment].id - 1];
					
					_updateReservesLoan(diamondStorage().indCollateralRecords[_sender][_market][_commitment].market, diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount, 1);
					emit CollateralReleased(_sender,diamondStorage().indCollateralRecords[_sender][_market][_commitment].amount,diamondStorage().indCollateralRecords[_sender][_market][_commitment].market,block.timestamp);
				}
			}
		}
		
		_updateUtilisationLoan(diamondStorage().indLoanRecords[_sender][_market][_commitment].market, diamondStorage().indLoanRecords[_sender][_market][_commitment].amount, 1);
    }

    function _hasLoanAccount(address _account) internal view returns (bool) {
        AppStorageOpen storage ds = diamondStorage(); 
        require(ds.loanPassbook[_account].accOpenTime !=0, "ERROR: No Loan Account");
		return true;
    }

    function _permissibleWithdrawal(bytes32 _market,bytes32 _commitment, bytes32 _collateralMarket, uint256 _amount, address _sender) internal authContract(LOAN1_ID) returns (bool success) {
        AppStorageOpen storage ds = diamondStorage(); 
        _hasLoanAccount(_sender);

		LoanRecords storage loan = ds.indLoanRecords[_sender][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_sender][_market][_commitment];
		
		_checkPermissibleWithdrawal(_market, _commitment, _collateralMarket, _amount, _sender);
		
		ds.withdrawToken = IBEP20(_connectMarket(loanState.currentMarket));
		ds.withdrawToken.transfer(_sender,_amount);

		emit WithdrawalProcessed(_sender, loan.id, _amount, loanState.currentMarket, block.timestamp);

		success = true;
    }

    function _liquidation(address _account, uint256 _id) internal authContract(LOAN1_ID){
        AppStorageOpen storage ds = diamondStorage(); 
        bytes32 _commitment = ds.loanPassbook[_account].loans[_id-1].commitment;
		bytes32 _market = ds.loanPassbook[_account].loans[_id-1].market;

		LoanRecords storage loan = ds.indLoanRecords[_account][_market][_commitment];
		LoanState storage loanState = ds.indLoanState[_account][_market][_commitment];
		CollateralRecords storage collateral = ds.indCollateralRecords[_account][_market][_commitment];
		DeductibleInterest storage deductibleInterest = ds.indAccruedAPR[_account][_market][_commitment];
		// CollateralYield storage cYield = ds.indAccruedAPY[_account][_market][_commitment];

		// emit FairPriceCall(ds.requestEventId++, collateral.market, collateral.amount);
		// emit FairPriceCall(ds.requestEventId++, loanState.currentMarket, loanState.currentAmount);

		require(loan.id == _id, "ERROR: id mismatch");

		_accruedInterest(_account, _market, _commitment);
		
		if (loan.commitment == _getCommitment(2))
			collateral.amount += ds.indAccruedAPY[_account][_market][_commitment].accruedYield - deductibleInterest.accruedInterest;
		else if (loan.commitment == _getCommitment(2))
			collateral.amount -= deductibleInterest.accruedInterest;

		delete ds.indAccruedAPY[_account][_market][_commitment];
		delete ds.indAccruedAPR[_account][_market][_commitment];
		delete ds.loanPassbook[_account].accruedAPR[loan.id - 1];
		delete ds.loanPassbook[_account].accruedAPY[loan.id - 1];

		uint256 cAmount = _getLatestPrice(collateral.market)*collateral.amount;
		uint256 lAmountCurrent = _getLatestPrice(loanState.currentMarket)*loanState.currentAmount;
		// convert collateral & loanCurrent into loanActual
		uint256 _repaymentAmount = _swap(collateral.market, loan.market, cAmount, 2);
		_repaymentAmount += _swap(loanState.currentMarket, loan.market, lAmountCurrent, 1);

		delete ds.indLoanState[_account][_market][_commitment];
		delete ds.indLoanRecords[_account][_market][_commitment];
		delete ds.indCollateralRecords[_account][_market][_commitment];

		delete ds.loanPassbook[_account].loanState[_id - 1];
		delete ds.loanPassbook[_account].loans[_id - 1];
		delete ds.loanPassbook[_account].collaterals[_id - 1];
		_updateUtilisationLoan(loan.market, loan.amount, 1);

		emit LoanRepaid(_account, _id, loan.market, block.timestamp);
		emit Liquidation(_account,_market, _commitment, loan.amount, block.timestamp);
		
    }

// =========== Reserve Functions =====================
	function _collateralTransfer(address _account, bytes32 _market, bytes32 _commitment) internal authContract(RESERVE_ID) {
        AppStorageOpen storage ds = diamondStorage(); 

		bytes32 collateralMarket;
        uint collateralAmount;

		(collateralMarket, collateralAmount) = _collateralPointer(_account,_market,_commitment);
		ds.token = IBEP20(_connectMarket(collateralMarket));
		ds.token.approveFrom(ds.reserveAddress, address(this), collateralAmount);
        ds.token.transferFrom(ds.reserveAddress, _account, collateralAmount);
	}

	function _transferAnyBEP20(address _token, address _sender, address _recipient, uint256 _value) internal authContract(RESERVE_ID) {
		IBEP20(_token).approveFrom(_sender, address(this), _value);
        IBEP20(_token).transferFrom(_sender, _recipient, _value);
	}

	function _avblMarketReserves(bytes32 _market) internal view returns (uint) {
        require((_marketReserves(_market) - _marketUtilisation(_market)) >=0, "Mathematical error");
        return _marketReserves(_market) - _marketUtilisation(_market);
    }

	function _marketReserves(bytes32 _market) internal view returns (uint) {
        return _avblReservesDeposit(_market) + _avblReservesLoan(_market);
	}

	function _marketUtilisation(bytes32 _market) internal view returns (uint) {
		return _utilisedReservesDeposit(_market) + _utilisedReservesLoan(_market);
	}

// =========== OracleOpen Functions =================
	function _getLatestPrice(bytes32 _market) internal view returns (uint) {
        // AppStorageOpen storage ds = diamondStorage();
		// require(ds.pairAddresses[_market] != address(0), "Invalid pair address given");
		// ( , int price, , , ) = AggregatorV3Interface(ds.pairAddresses[_market]).latestRoundData();
        // return uint256(price);
		return 1;
	}

	function _getFairPrice(uint _requestId) internal view returns (uint retPrice) {
		AppStorageOpen storage ds = diamondStorage();
		require(ds.priceData[_requestId].price != 0, "No fetched price");
		retPrice = ds.priceData[_requestId].price;
	}

	function _fairPrice(uint _requestId, uint _fPrice, bytes32 _market, uint _amount) internal {
		AppStorageOpen storage ds = diamondStorage();
		PriceData storage newPrice = ds.priceData[_requestId];
		newPrice.market = _market;
		newPrice.amount = _amount;
		newPrice.price = _fPrice;
	}

// =========== AccessRegistry Functions =================
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        AppStorageOpen storage ds = diamondStorage(); 
        return ds._roles[role]._members[account];
    }

    function _addRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
        ds._roles[role]._members[account] = true;
        emit RoleGranted(role, account, msg.sender);
    }
    
    function _revokeRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
        ds._roles[role]._members[account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    function _hasAdminRole(bytes32 role, address account) internal view returns (bool) {
        AppStorageOpen storage ds = diamondStorage(); 
        return ds._adminRoles[role]._adminMembers[account];
    }

    function _addAdminRole(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
        ds._adminRoles[role]._adminMembers[account] = true;
        emit AdminRoleDataGranted(role, account, msg.sender);
    }

    function _revokeAdmin(bytes32 role, address account) internal authContract(ACCESSREGISTRY_ID) {
        AppStorageOpen storage ds = diamondStorage(); 
        ds._adminRoles[role]._adminMembers[account] = false;
        emit AdminRoleDataRevoked(role, account, msg.sender);
    }

	modifier authContract(uint _facetId) {
		require(_facetId == diamondStorage().facetIndex[msg.sig] || 
				diamondStorage().facetIndex[msg.sig] == 0, "Not permitted function call");
		_;
	}

}
