// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VestingWallet} from "./VestingWallet.sol";
import {VestingWalletStair} from "./VestingWalletStair.sol";
import {IERC20} from "../token/ERC20/IERC20.sol";
import {SafeERC20} from "../token/ERC20/utils/SafeERC20.sol";
import {Address} from "../utils/Address.sol";

/**
 * @title RevocableStairVesting
 * @dev Extension of VestingWalletStair that allows a designated revoker to revoke unvested tokens.
 *
 * Key features:
 * - Step/stair vesting (tokens unlock in discrete steps)
 * - Separate revoker role can revoke unvested tokens (sent to treasury)
 * - Beneficiary is the owner and keeps any already-vested tokens
 * - Revoked amounts are tracked and treated as "released" for future vesting calculations
 *
 * Use case: Employee vesting with step unlocks where company needs ability to revoke if employee leaves
 */
contract RevocableStairVesting is VestingWalletStair {
    address private immutable _revoker;
    address private immutable _treasury;

    uint256 private _ethRevocationTimestamp;
    mapping(address => uint256) private _revocationTimestamps;

    uint256 private _returned;
    mapping(address => uint256) private _erc20Returned;

    event Revoked(uint256 amount);
    event RevokedERC20(address indexed token, uint256 amount);

    error OnlyRevoker(address caller);

    /**
     * @dev Creates a revocable stair vesting wallet.
     *
     * @param beneficiaryAddress The address that will receive vested tokens (becomes owner)
     * @param revokerAddress The address that can revoke unvested tokens (separate from owner)
     * @param treasuryAddress The address that receives revoked tokens
     * @param startTimestamp Unix timestamp when vesting begins
     * @param durationSeconds Total vesting duration in seconds (must accommodate all steps)
     * @param cliffSeconds Duration of cliff period before steps begin
     * @param stepDuration Duration of each step in seconds (e.g., 10 days = 864000 seconds)
     * @param numberOfSteps Total number of steps (e.g., 10 steps means 10% per step)
     *
     * Requirements:
     * - stepDuration * numberOfSteps must be <= durationSeconds
     * - numberOfSteps must be > 0
     *
     * Note: The beneficiary is the owner and can release vested tokens.
     * Only the revoker can revoke unvested tokens (sent to treasury).
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
    )
        VestingWallet(beneficiaryAddress, startTimestamp, durationSeconds)
        VestingWalletStair(cliffSeconds, stepDuration, numberOfSteps)
        payable
    {
        _revoker = revokerAddress;
        _treasury = treasuryAddress;
    }

    /**
     * @dev Modifier to restrict function access to the revoker only.
     */
    modifier onlyRevoker() {
        if (msg.sender != _revoker) {
            revert OnlyRevoker(msg.sender);
        }
        _;
    }

    /**
     * @dev Get the revoker address.
     */
    function revoker() public view returns (address) {
        return _revoker;
    }

    /**
     * @dev Get the treasury address.
     */
    function treasury() public view returns (address) {
        return _treasury;
    }

    /**
     * @dev Revoke unvested ETH and send it to the treasury.
     * Only the revoker can call this function.
     *
     * The beneficiary keeps any already vested ETH (they can still call release()).
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

    /**
     * @dev Override vestedAmount to include revoked amounts in total allocation.
     * This ensures the vesting schedule continues based on original allocation,
     * but beneficiary can only claim what wasn't revoked.
     */
    function vestedAmount(uint64 timestamp) public view override returns (uint256) {
        
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
    function vestedAmount(address token, uint64 timestamp) public view override returns (uint256) {

        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + super.released(token) + _erc20Returned[token];

        uint64 timeCap = timestamp;
        if (_revocationTimestamps[token] != 0 && _revocationTimestamps[token] < timestamp) {
            timeCap = uint64(_revocationTimestamps[token]);
        }

        return _vestingSchedule(totalAllocation, timeCap);
    }

    /**
     * @dev Get the amount of ETH that has been revoked.
     */
    function revoked() public view returns (uint256) {
        return _returned;
    }

    /**
     * @dev Get the amount of ERC20 tokens that have been revoked.
     */
    function revoked(address token) public view returns (uint256) {
        return _erc20Returned[token];
    }
}
