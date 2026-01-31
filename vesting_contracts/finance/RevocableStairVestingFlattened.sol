// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";
import {SafeERC20} from "../token/ERC20/utils/SafeERC20.sol";
import {Address} from "../utils/Address.sol";
import {Context} from "../utils/Context.sol";
import {Ownable} from "../access/Ownable.sol";

/**
 * @title RevocableStairVestingFlattened
 * @dev A complete vesting contract with cliff, stair/step vesting, and revoke functionality.
 * All logic from VestingWallet + VestingWalletStair + RevocableStairVesting combined into one file.
 *
 * Features:
 * - Cliff period: No tokens vest during this time
 * - Step vesting: After cliff, tokens unlock in discrete steps (e.g., 10% per month)
 * - Revocable: A designated revoker can claw back unvested tokens to treasury
 * - Beneficiary (owner) can release vested tokens at any time
 */
contract RevocableStairVestingFlattened is Context, Ownable {
    // ============================================
    // EVENTS
    // ============================================
    event EtherReleased(uint256 amount);
    event ERC20Released(address indexed token, uint256 amount);
    event Revoked(uint256 amount);
    event RevokedERC20(address indexed token, uint256 amount);

    // ============================================
    // ERRORS
    // ============================================
    error OnlyRevoker(address caller);
    error InvalidCliffDuration(uint64 cliffSeconds, uint64 durationSeconds);
    error InvalidStepConfiguration(uint64 stepDuration, uint64 numberOfSteps, uint64 durationSeconds);

    // ============================================
    // STATE VARIABLES
    // ============================================

    // From VestingWallet
    uint256 private _released;
    mapping(address token => uint256) private _erc20Released;
    uint64 private immutable _start;
    uint64 private immutable _duration;

    // From VestingWalletStair
    uint64 private immutable _cliff;
    uint64 private immutable _stepDuration;
    uint64 private immutable _numberOfSteps;

    // From RevocableStairVesting
    address private immutable _revoker;
    address private immutable _treasury;
    uint256 private _returned;
    mapping(address => uint256) private _erc20Returned;

    mapping(address => uint256) private _revocationTimestamps;
    uint256 private _ethRevocationTimestamp;

    // ============================================
    // CONSTRUCTOR
    // ============================================

    /**
     * @dev Creates a revocable stair vesting wallet with all parameters.
     *
     * @param beneficiaryAddress The address that will receive vested tokens (becomes owner)
     * @param revokerAddress The address that can revoke unvested tokens
     * @param treasuryAddress The address that receives revoked tokens
     * @param startTimestamp Unix timestamp when vesting begins
     * @param durationSeconds Total vesting duration in seconds
     * @param cliffSeconds Duration of cliff period before steps begin
     * @param stepDuration Duration of each step in seconds
     * @param numberOfSteps Total number of steps (e.g., 10 steps = 10% per step)
     */
    constructor(
        address beneficiaryAddress,
        address revokerAddress,
        address treasuryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds,
        uint64 stepDuration,
        uint64 numberOfSteps
    ) payable Ownable(beneficiaryAddress) {
        // Initialize VestingWallet variables
        _start = startTimestamp;
        _duration = durationSeconds;

        // Validate and initialize VestingWalletStair variables
        if (cliffSeconds > durationSeconds) {
            revert InvalidCliffDuration(cliffSeconds, durationSeconds);
        }

        if (numberOfSteps == 0) {
            revert InvalidStepConfiguration(stepDuration, numberOfSteps, durationSeconds);
        }

        if (stepDuration == 0) {
            revert InvalidStepConfiguration(stepDuration, numberOfSteps, durationSeconds);
        }

        if (cliffSeconds + (stepDuration * numberOfSteps) > durationSeconds) {
            revert InvalidStepConfiguration(stepDuration, numberOfSteps, durationSeconds);
        }

        _cliff = startTimestamp + cliffSeconds;
        _stepDuration = stepDuration;
        _numberOfSteps = numberOfSteps;

        // Initialize RevocableStairVesting variables
        _revoker = revokerAddress;
        _treasury = treasuryAddress;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}

    // ============================================
    // MODIFIERS
    // ============================================

    modifier onlyRevoker() {
        if (msg.sender != _revoker) {
            revert OnlyRevoker(msg.sender);
        }
        _;
    }

    // ============================================
    // VIEW FUNCTIONS - Basic Getters
    // ============================================

    function start() public view virtual returns (uint256) {
        return _start;
    }

    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    function end() public view virtual returns (uint256) {
        return start() + duration();
    }

    function cliff() public view virtual returns (uint256) {
        return _cliff;
    }

    function stepDuration() public view virtual returns (uint256) {
        return _stepDuration;
    }

    function numberOfSteps() public view virtual returns (uint256) {
        return _numberOfSteps;
    }

    function revoker() public view returns (address) {
        return _revoker;
    }

    function treasury() public view returns (address) {
        return _treasury;
    }

    // ============================================
    // VIEW FUNCTIONS - Released & Revoked Tracking
    // ============================================

    function released() public view virtual returns (uint256) {
        return _released;
    }

    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    function revoked() public view returns (uint256) {
        return _returned;
    }

    function revoked(address token) public view returns (uint256) {
        return _erc20Returned[token];
    }

    // ============================================
    // VIEW FUNCTIONS - Releasable Amounts
    // ============================================

    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    function releasable(address token) public view virtual returns (uint256) {
        return vestedAmount(token, uint64(block.timestamp)) - released(token);
    }

    // ============================================
    // VIEW FUNCTIONS - Vested Amounts
    // ============================================

    /**
     * @dev Override vestedAmount to include revoked amounts in total allocation.
     * This ensures the vesting schedule continues based on original allocation,
     * but beneficiary can only claim what wasn't revoked.
     */
    function vestedAmount(uint64 timestamp) public view returns (uint256) {
        
        uint256 totalAllocation = address(this).balance + released() + _returned;
            
        // If revoked, cap the vesting time at the moment of revocation
        uint64 timeCap = timestamp;
        if (_ethRevocationTimestamp != 0 && _ethRevocationTimestamp < timestamp) {
            timeCap = uint64(_ethRevocationTimestamp);
        }
        
        return _vestingSchedule(totalAllocation, timeCap);
    }

    /**
     * @dev Override vestedAmount for tokens to include revoked amounts in total allocation.
     * This ensures the vesting schedule continues based on original allocation,
     * but beneficiary can only claim what wasn't revoked.
     */
    function vestedAmount(address token, uint64 timestamp) public view returns (uint256) {

        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + released(token) + _erc20Returned[token];

        uint64 timeCap = timestamp;
        if (_revocationTimestamps[token] != 0 && _revocationTimestamps[token] < timestamp) {
            timeCap = uint64(_revocationTimestamps[token]);
        }

        return _vestingSchedule(totalAllocation, timeCap);
    }

    // ============================================
    // INTERNAL - Vesting Schedule Logic
    // ============================================

    /**
     * @dev Vesting formula combining cliff and stair/step vesting.
     *
     * Before cliff: 0% vested (lockup period)
     * After cliff: First step vests immediately, then remaining steps at intervals
     *
     * Example with 1 year cliff + 10 monthly steps (10% each):
     * - Month 0-11: 0% (cliff/lockup)
     * - Month 12: 10% (cliff ends, first step vests)
     * - Month 13: 20% (second step)
     * - Month 14: 30% (third step)
     * - ... etc ...
     * - Month 21: 100% (all 10 steps complete)
     */
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view virtual returns (uint256) {
        // Before cliff: nothing vests (lockup period)
        if (timestamp < cliff()) {
            return 0;
        }

        // Calculate time elapsed since cliff ended
        uint64 timeSinceCliff = timestamp - uint64(cliff());

        // Calculate how many complete steps have passed since cliff
        // Add 1 so the first step vests immediately when cliff ends
        uint64 stepsCompleted = (timeSinceCliff / _stepDuration) + 1;

        // Cap at maximum number of steps
        if (stepsCompleted >= _numberOfSteps) {
            // All steps complete - 100% vested
            return totalAllocation;
        }

        // Return proportional amount based on completed steps
        return (totalAllocation * stepsCompleted) / _numberOfSteps;
    }

    // ============================================
    // RELEASE FUNCTIONS (Beneficiary)
    // ============================================

    /**
     * @dev Release the native tokens (ether) that have already vested.
     * Sends to the owner (beneficiary).
     */
    function release() public virtual {
        uint256 amount = releasable();
        _released += amount;
        emit EtherReleased(amount);
        Address.sendValue(payable(owner()), amount);
    }

    /**
     * @dev Release the tokens that have already vested.
     * Sends to the owner (beneficiary).
     */
    function release(address token) public virtual {
        uint256 amount = releasable(token);
        _erc20Released[token] += amount;
        emit ERC20Released(token, amount);
        SafeERC20.safeTransfer(IERC20(token), owner(), amount);
    }

    // ============================================
    // REVOKE FUNCTIONS (Revoker)
    // ============================================

    /**
     * @dev Revoke unvested ETH and send it to the treasury.
     * Only the revoker can call this function.
     *
     * The beneficiary keeps any already vested ETH.
     * Revoked amount is tracked to prevent it from vesting in the future.
     */
    function revoke() public onlyRevoker {

        if (_ethRevocationTimestamp == 0) {
          _ethRevocationTimestamp = block.timestamp;
        }

        uint256 balance = address(this).balance;
        uint256 returnable = balance - releasable();
        Address.sendValue(payable(_treasury), returnable);
        _returned += returnable;
        emit Revoked(returnable);
    }

    /**
     * @dev Revoke unvested ERC20 tokens and send them to the treasury.
     * Only the revoker can call this function.
     *
     * @param token The ERC20 token address to revoke
     *
     * The beneficiary keeps any already vested tokens (they can still call release()).
     * Revoked amount is tracked to prevent it from vesting in the future.
     */
    function revoke(address token) public onlyRevoker {

        if (_revocationTimestamps[token] == 0) {
          _revocationTimestamps[token] = block.timestamp;
        }

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 returnable = balance - releasable(token);
        SafeERC20.safeTransfer(IERC20(token), _treasury, returnable);
        _erc20Returned[token] += returnable;
        emit RevokedERC20(token, returnable);
    }

    
}
