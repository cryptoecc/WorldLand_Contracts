// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeCast} from "../utils/math/SafeCast.sol";
import {VestingWallet} from "./VestingWallet.sol";

/**
 * @dev Extension of {VestingWallet} that adds cliff + step/stair vesting.
 *
 * - Cliff period: No tokens vest during this time (e.g., 1 year lockup)
 * - After cliff: First step unlocks immediately, then remaining steps at regular intervals
 *
 * Example: 1 year cliff + 10 steps of 30 days each
 * - Year 1: 0% (cliff/lockup)
 * - Year 1 (cliff ends): 10% unlocks immediately
 * - Year 1 + 30 days: 20% unlocks
 * - Year 1 + 60 days: 30% unlocks
 * - etc.
 */
abstract contract VestingWalletStair is VestingWallet {
    using SafeCast for *;

    uint64 private immutable _cliff;
    uint64 private immutable _stepDuration;  // Duration of each step
    uint64 private immutable _numberOfSteps; // Total number of steps

    error InvalidCliffDuration(uint64 cliffSeconds, uint64 durationSeconds);
    /// @dev The total duration doesn't accommodate all steps
    error InvalidStepConfiguration(uint64 stepDuration, uint64 numberOfSteps, uint64 durationSeconds);

    /**
     * @dev Set up cliff and step vesting parameters.
     *
     * @param cliffSeconds Duration of cliff/lockup period in seconds (e.g., 1 year = 31536000 seconds)
     * @param stepDuration Duration of each step in seconds (e.g., 30 days = 2592000 seconds)
     * @param numberOfSteps Total number of steps after cliff (e.g., 10 steps = 10% per step)
     *
     * Requirements:
     * - cliffSeconds must be <= total vesting duration
     * - cliffSeconds + (stepDuration * numberOfSteps) must be <= total vesting duration
     * - numberOfSteps must be > 0
     * - stepDuration must be > 0
     *
     * Example: 1 year cliff + 4 quarterly steps
     * - cliffSeconds: 31536000 (1 year)
     * - stepDuration: 7776000 (90 days / ~3 months)
     * - numberOfSteps: 4
     * - durationSeconds: 62640000 (1 year + ~1 year)
     */
    constructor(uint64 cliffSeconds, uint64 stepDuration, uint64 numberOfSteps) {
        uint64 durationSec = duration().toUint64();

        if (cliffSeconds > durationSec) {
            revert InvalidCliffDuration(cliffSeconds, durationSec);
        }

        if (numberOfSteps == 0) {
            revert InvalidStepConfiguration(stepDuration, numberOfSteps, durationSec);
        }

        if (stepDuration == 0) {
            revert InvalidStepConfiguration(stepDuration, numberOfSteps, durationSec);
        }

        // Cliff + all steps must fit within total duration
        if (cliffSeconds + (stepDuration * numberOfSteps) > durationSec) {
            revert InvalidStepConfiguration(stepDuration, numberOfSteps, durationSec);
        }

        _cliff = start().toUint64() + cliffSeconds;
        _stepDuration = stepDuration;
        _numberOfSteps = numberOfSteps;
    }

    /**
     * @dev Getter for the cliff timestamp.
     */
    function cliff() public view virtual returns (uint256) {
        return _cliff;
    }

    /**
     * @dev Getter for the step duration.
     */
    function stepDuration() public view virtual returns (uint256) {
        return _stepDuration;
    }

    /**
     * @dev Getter for the number of steps.
     */
    function numberOfSteps() public view virtual returns (uint256) {
        return _numberOfSteps;
    }

    /**
     * @dev Virtual implementation combining cliff and stair vesting.
     *
     * Before cliff: 0% vested (lockup period)
     * After cliff: First step vests immediately, then remaining steps at intervals
     *
     * Example with 1 year cliff + 4 quarterly steps (25% each):
     * - Month 0-11: 0% (cliff/lockup)
     * - Month 12: 25% (cliff ends, first step vests immediately)
     * - Month 15: 50% (second quarterly step complete)
     * - Month 18: 75% (third step complete)
     * - Month 21: 100% (all steps complete)
     */
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 timestamp
    ) internal view virtual override returns (uint256) {
        // Before cliff: nothing vests (lockup period)
        if (timestamp < cliff()) {
            return 0;
        }

        // Calculate time elapsed since cliff ended
        uint64 timeSinceCliff = timestamp - cliff().toUint64();

        // Calculate how many complete steps have passed since cliff
        // Add 1 so the first step vests immediately when cliff ends
        uint64 stepsCompleted = (timeSinceCliff / _stepDuration) + 1;

        // Cap at maximum number of steps
        if (stepsCompleted >= _numberOfSteps) {
            // All steps complete - 100% vested
            return totalAllocation;
        }

        // Return proportional amount based on completed steps
        // stepsCompleted / numberOfSteps * totalAllocation
        return (totalAllocation * stepsCompleted) / _numberOfSteps;
    }
}
