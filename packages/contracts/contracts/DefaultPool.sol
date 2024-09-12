// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import './Interfaces/IDefaultPool.sol';
import './Interfaces/IActivePool.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/console.sol";

/*
 * The Default Pool holds the ETH and LUSD debt (but not LUSD tokens) from liquidations that have been redistributed
 * to active troves but not yet "applied", i.e. not yet recorded on a recipient active trove's struct.
 *
 * When a trove makes an operation that applies its pending ETH and LUSD debt, its pending ETH and LUSD debt is moved
 * from the Default Pool to the Active Pool.
 */
contract DefaultPool is Ownable, CheckContract, IDefaultPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string constant public NAME = "DefaultPool";

    address public troveManagerAddress;
    address public activePoolAddress;
    IERC20 public collateralToken;
    uint256 internal collateral;  // deposited collateral tracker
    uint256 internal LUSDDebt;  // debt

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event CollateralTokenAddressChanged(address _newCollateralTokenAddress);
    event DefaultPoolLUSDDebtUpdated(uint _LUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint _ETH);

    // --- Dependency setters ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _collateralTokenAddress
    )
        external
        onlyOwner
    {
        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        checkContract(_collateralTokenAddress);

        troveManagerAddress = _troveManagerAddress;
        activePoolAddress = _activePoolAddress;
        collateralToken = IERC20(_collateralTokenAddress);

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit CollateralTokenAddressChanged(_collateralTokenAddress);

        _renounceOwnership();
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the ETH state variable.
    *
    * Not necessarily equal to the the contract's raw ETH balance - ether can be forcibly sent to contracts.
    */
    function getETH() external view override returns (uint) {
        return collateral;
    }

    function getLUSDDebt() external view override returns (uint) {
        return LUSDDebt;
    }

    // --- Pool functionality ---

    function sendETHToActivePool(uint _amount) external override {
        _requireCallerIsTroveManager();
        address activePool = activePoolAddress; // cache to save an SLOAD
        collateral = collateral.sub(_amount);
        emit DefaultPoolETHBalanceUpdated(collateral);
        emit EtherSent(activePool, _amount);
        IActivePool(activePool).addCollateral(_amount);

        collateralToken.safeTransfer(activePool, _amount);
    }

    function increaseLUSDDebt(uint _amount) external override {
        _requireCallerIsTroveManager();
        LUSDDebt = LUSDDebt.add(_amount);
        emit DefaultPoolLUSDDebtUpdated(LUSDDebt);
    }

    function decreaseLUSDDebt(uint _amount) external override {
        _requireCallerIsTroveManager();
        LUSDDebt = LUSDDebt.sub(_amount);
        emit DefaultPoolLUSDDebtUpdated(LUSDDebt);
    }

    function addCollateral(uint _amount) external override {
        _requireCallerIsActivePool();
        collateral = collateral.add(_amount);
        emit DefaultPoolETHBalanceUpdated(collateral);
    }

    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require(msg.sender == activePoolAddress, "DefaultPool: Caller is not the ActivePool");
    }

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == troveManagerAddress, "DefaultPool: Caller is not the TroveManager");
    }
}
