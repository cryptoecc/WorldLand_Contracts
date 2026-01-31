// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VestingWalletStair} from "./VestingWalletStair.sol";
import {VestingWallet} from "./VestingWallet.sol";

/**
 * @title WorldLandStairVesting
 * @dev Vesting wallet for WorldLand token distribution with cliff + step/stair unlocking.
 *
 * - Cliff period: Tokens are locked (e.g., 1 year lockup)
 * - After cliff: First step unlocks immediately, then remaining steps at regular intervals
 *
 * Example: 1 year cliff + 4 quarterly unlocks (25% each)
 * - Year 1: 0% (lockup)
 * - Year 1 (cliff ends): 25% unlocks immediately
 * - Year 1 + 3 months: 50% unlocks
 * - Year 1 + 6 months: 75% unlocks
 * - Year 1 + 9 months: 100% unlocks
 *
 * Each beneficiary gets their own vesting contract instance.
 */
contract WorldLandVesting is VestingWalletStair {
    /**
     * @dev Creates a cliff + stair vesting wallet.
     *
     * @param beneficiary The address that will receive the vested tokens
     * @param startTimestamp Unix timestamp when vesting begins
     * @param durationSeconds Total vesting duration in seconds (must accommodate cliff + all steps)
     * @param cliffSeconds Duration of cliff/lockup period in seconds (e.g., 1 year = 31536000)
     * @param stepDuration Duration of each step in seconds (e.g., 90 days = 7776000)
     * @param numberOfSteps Total number of steps after cliff (e.g., 4 steps = 25% per step)
     *
     * Requirements:
     * - cliffSeconds + (stepDuration * numberOfSteps) must be <= durationSeconds
     * - numberOfSteps must be > 0
     *
     * Example for "1 year cliff + 4 quarterly unlocks":
     * - cliffSeconds: 31536000 (1 year)
     * - stepDuration: 7776000 (90 days)
     * - numberOfSteps: 4
     * - durationSeconds: 62640000 (~2 years)
     */
    constructor(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffSeconds,
        uint64 stepDuration,
        uint64 numberOfSteps
    )
        VestingWallet(beneficiary, startTimestamp, durationSeconds)
        VestingWalletStair(cliffSeconds, stepDuration, numberOfSteps)
        payable
    {}
}
