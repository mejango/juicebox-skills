// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBCashOutHook} from "@bananapus/core/src/interfaces/IJBCashOutHook.sol";
import {IJBRulesetDataHook} from "@bananapus/core/src/interfaces/IJBRulesetDataHook.sol";
import {JBAfterCashOutRecordedContext} from "@bananapus/core/src/structs/JBAfterCashOutRecordedContext.sol";
import {JBBeforePayRecordedContext} from "@bananapus/core/src/structs/JBBeforePayRecordedContext.sol";
import {JBBeforeCashOutRecordedContext} from "@bananapus/core/src/structs/JBBeforeCashOutRecordedContext.sol";
import {JBPayHookSpecification} from "@bananapus/core/src/structs/JBPayHookSpecification.sol";
import {JBCashOutHookSpecification} from "@bananapus/core/src/structs/JBCashOutHookSpecification.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title VestingCashOutHook
/// @notice Enforces time-based vesting for cash outs
/// @dev Tokens acquired must vest before they can be cashed out
contract VestingCashOutHook is IJBRulesetDataHook, IJBCashOutHook, ERC165, Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error TokensNotVested(address holder, uint256 vestedAmount, uint256 requestedAmount);
    error NoVestingSchedule(uint256 projectId);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event VestingScheduleSet(uint256 indexed projectId, uint256 vestingDuration, uint256 cliffDuration);
    event TokensVested(uint256 indexed projectId, address indexed holder, uint256 amount, uint256 vestingStart);
    event CashOutProcessed(uint256 indexed projectId, address indexed holder, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct VestingSchedule {
        uint256 vestingDuration;  // Total vesting period in seconds
        uint256 cliffDuration;    // Cliff period before any vesting
    }

    struct VestingPosition {
        uint256 totalAmount;      // Total tokens subject to vesting
        uint256 vestingStart;     // When vesting started
        uint256 claimedAmount;    // Already claimed/cashed out
    }

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Vesting schedule for each project
    mapping(uint256 projectId => VestingSchedule) public vestingScheduleOf;

    /// @notice Vesting positions per holder per project
    mapping(uint256 projectId => mapping(address holder => VestingPosition)) public vestingPositionOf;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) Ownable(_owner) {}

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Set vesting schedule for a project
    /// @param projectId The project ID
    /// @param vestingDuration Total vesting period in seconds
    /// @param cliffDuration Cliff period in seconds
    function setVestingSchedule(uint256 projectId, uint256 vestingDuration, uint256 cliffDuration) external onlyOwner {
        require(cliffDuration <= vestingDuration, "Cliff exceeds vesting");

        vestingScheduleOf[projectId] = VestingSchedule({
            vestingDuration: vestingDuration,
            cliffDuration: cliffDuration
        });

        emit VestingScheduleSet(projectId, vestingDuration, cliffDuration);
    }

    /*//////////////////////////////////////////////////////////////
                             DATA HOOK
    //////////////////////////////////////////////////////////////*/

    /// @notice Records token acquisition for vesting tracking
    function beforePayRecordedWith(JBBeforePayRecordedContext calldata context)
        external
        override
        returns (uint256 weight, JBPayHookSpecification[] memory hookSpecifications)
    {
        // Calculate tokens to be minted
        uint256 tokenCount = (context.amount.value * context.weight) / 1e18;

        // Update vesting position
        VestingPosition storage position = vestingPositionOf[context.projectId][context.beneficiary];

        if (position.totalAmount == 0) {
            // New position
            position.vestingStart = block.timestamp;
        }
        position.totalAmount += tokenCount;

        emit TokensVested(context.projectId, context.beneficiary, tokenCount, position.vestingStart);

        return (context.weight, new JBPayHookSpecification[](0));
    }

    /// @notice Validates vested amount before cash out
    function beforeCashOutRecordedWith(JBBeforeCashOutRecordedContext calldata context)
        external
        view
        override
        returns (
            uint256 cashOutTaxRate,
            uint256 cashOutCount,
            uint256 totalSupply,
            JBCashOutHookSpecification[] memory hookSpecifications
        )
    {
        // Get vested amount
        uint256 vestedAmount = getVestedAmount(context.projectId, context.holder);
        VestingPosition memory position = vestingPositionOf[context.projectId][context.holder];

        // Calculate how much can still be cashed out
        uint256 availableForCashOut = vestedAmount > position.claimedAmount
            ? vestedAmount - position.claimedAmount
            : 0;

        if (context.cashOutCount > availableForCashOut) {
            revert TokensNotVested(context.holder, availableForCashOut, context.cashOutCount);
        }

        // Set up cash out hook to track claimed amount
        hookSpecifications = new JBCashOutHookSpecification[](1);
        hookSpecifications[0] = JBCashOutHookSpecification({
            hook: IJBCashOutHook(address(this)),
            amount: 0,  // No funds forwarded
            metadata: ""
        });

        return (context.cashOutTaxRate, context.cashOutCount, context.totalSupply, hookSpecifications);
    }

    /// @notice Track claimed amounts after cash out
    function afterCashOutRecordedWith(JBAfterCashOutRecordedContext calldata context)
        external
        payable
        override
        nonReentrant
    {
        // Update claimed amount
        vestingPositionOf[context.projectId][context.holder].claimedAmount += context.cashOutCount;

        emit CashOutProcessed(context.projectId, context.holder, context.cashOutCount);
    }

    function hasMintPermissionFor(uint256) external pure override returns (bool) {
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                               VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate vested amount for a holder
    /// @param projectId The project ID
    /// @param holder The token holder
    /// @return The amount of tokens currently vested
    function getVestedAmount(uint256 projectId, address holder) public view returns (uint256) {
        VestingSchedule memory schedule = vestingScheduleOf[projectId];
        VestingPosition memory position = vestingPositionOf[projectId][holder];

        if (position.totalAmount == 0) return 0;
        if (schedule.vestingDuration == 0) return position.totalAmount; // No vesting = fully vested

        uint256 elapsed = block.timestamp - position.vestingStart;

        // Check cliff
        if (elapsed < schedule.cliffDuration) return 0;

        // Calculate vested amount
        if (elapsed >= schedule.vestingDuration) {
            return position.totalAmount;
        }

        return (position.totalAmount * elapsed) / schedule.vestingDuration;
    }

    /// @notice Get available tokens for cash out (vested minus already claimed)
    function getAvailableForCashOut(uint256 projectId, address holder) external view returns (uint256) {
        uint256 vested = getVestedAmount(projectId, holder);
        uint256 claimed = vestingPositionOf[projectId][holder].claimedAmount;
        return vested > claimed ? vested - claimed : 0;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IJBRulesetDataHook).interfaceId ||
            interfaceId == type(IJBCashOutHook).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
