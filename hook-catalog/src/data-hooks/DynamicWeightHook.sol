// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBRulesetDataHook} from "@bananapus/core/src/interfaces/IJBRulesetDataHook.sol";
import {JBBeforePayRecordedContext} from "@bananapus/core/src/structs/JBBeforePayRecordedContext.sol";
import {JBBeforeCashOutRecordedContext} from "@bananapus/core/src/structs/JBBeforeCashOutRecordedContext.sol";
import {JBPayHookSpecification} from "@bananapus/core/src/structs/JBPayHookSpecification.sol";
import {JBCashOutHookSpecification} from "@bananapus/core/src/structs/JBCashOutHookSpecification.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title DynamicWeightHook
/// @notice Adjusts token minting weight based on configurable conditions
/// @dev Useful for time-based pricing, funding milestones, or early bird bonuses
contract DynamicWeightHook is IJBRulesetDataHook, ERC165, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidTier();
    error TierNotActive();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TierAdded(uint256 indexed tierId, uint256 startTime, uint256 endTime, uint256 weightMultiplier);
    event TierUpdated(uint256 indexed tierId, uint256 weightMultiplier);
    event TierRemoved(uint256 indexed tierId);
    event WeightAdjusted(uint256 indexed projectId, uint256 baseWeight, uint256 adjustedWeight, uint256 tierId);

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Defines a pricing tier with time bounds and weight adjustment
    struct WeightTier {
        uint256 startTime;         // When this tier becomes active (0 = always)
        uint256 endTime;           // When this tier ends (0 = never)
        uint256 weightMultiplier;  // Multiplier in basis points (10000 = 1x, 20000 = 2x)
        uint256 maxAmount;         // Max total payment amount for this tier (0 = unlimited)
        uint256 amountUsed;        // Amount already used in this tier
        bool active;               // Whether tier is active
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MULTIPLIER_BASE = 10000; // 100% = 10000

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Weight tiers for each project
    mapping(uint256 projectId => WeightTier[]) public tiersOf;

    /// @notice Default multiplier for projects without tiers (10000 = 1x)
    uint256 public defaultMultiplier = MULTIPLIER_BASE;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) Ownable(_owner) {}

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a new weight tier for a project
    /// @param projectId The project ID
    /// @param startTime When the tier becomes active
    /// @param endTime When the tier ends
    /// @param weightMultiplier Multiplier in basis points
    /// @param maxAmount Maximum payment amount for this tier
    function addTier(
        uint256 projectId,
        uint256 startTime,
        uint256 endTime,
        uint256 weightMultiplier,
        uint256 maxAmount
    ) external onlyOwner returns (uint256 tierId) {
        tierId = tiersOf[projectId].length;

        tiersOf[projectId].push(
            WeightTier({
                startTime: startTime,
                endTime: endTime,
                weightMultiplier: weightMultiplier,
                maxAmount: maxAmount,
                amountUsed: 0,
                active: true
            })
        );

        emit TierAdded(tierId, startTime, endTime, weightMultiplier);
    }

    /// @notice Update a tier's multiplier
    function updateTierMultiplier(uint256 projectId, uint256 tierId, uint256 newMultiplier) external onlyOwner {
        if (tierId >= tiersOf[projectId].length) revert InvalidTier();

        tiersOf[projectId][tierId].weightMultiplier = newMultiplier;

        emit TierUpdated(tierId, newMultiplier);
    }

    /// @notice Deactivate a tier
    function deactivateTier(uint256 projectId, uint256 tierId) external onlyOwner {
        if (tierId >= tiersOf[projectId].length) revert InvalidTier();

        tiersOf[projectId][tierId].active = false;

        emit TierRemoved(tierId);
    }

    /// @notice Set default multiplier for projects without tiers
    function setDefaultMultiplier(uint256 multiplier) external onlyOwner {
        defaultMultiplier = multiplier;
    }

    /*//////////////////////////////////////////////////////////////
                             DATA HOOK
    //////////////////////////////////////////////////////////////*/

    /// @notice Adjusts weight based on active tier
    function beforePayRecordedWith(JBBeforePayRecordedContext calldata context)
        external
        override
        returns (uint256 weight, JBPayHookSpecification[] memory hookSpecifications)
    {
        uint256 multiplier = defaultMultiplier;
        uint256 activeTierId = type(uint256).max;

        // Find active tier with best multiplier
        WeightTier[] storage tiers = tiersOf[context.projectId];
        for (uint256 i; i < tiers.length; i++) {
            WeightTier storage tier = tiers[i];

            if (!tier.active) continue;

            // Check time bounds
            if (tier.startTime > 0 && block.timestamp < tier.startTime) continue;
            if (tier.endTime > 0 && block.timestamp > tier.endTime) continue;

            // Check amount limit
            if (tier.maxAmount > 0 && tier.amountUsed + context.amount.value > tier.maxAmount) continue;

            // Use this tier if it has better multiplier
            if (tier.weightMultiplier > multiplier) {
                multiplier = tier.weightMultiplier;
                activeTierId = i;
            }
        }

        // Update amount used for active tier
        if (activeTierId != type(uint256).max) {
            tiers[activeTierId].amountUsed += context.amount.value;
        }

        // Calculate adjusted weight
        uint256 adjustedWeight = (context.weight * multiplier) / MULTIPLIER_BASE;

        emit WeightAdjusted(context.projectId, context.weight, adjustedWeight, activeTierId);

        return (adjustedWeight, new JBPayHookSpecification[](0));
    }

    /// @notice Pass through for cash outs
    function beforeCashOutRecordedWith(JBBeforeCashOutRecordedContext calldata context)
        external
        pure
        override
        returns (
            uint256 cashOutTaxRate,
            uint256 cashOutCount,
            uint256 totalSupply,
            JBCashOutHookSpecification[] memory hookSpecifications
        )
    {
        return (
            context.cashOutTaxRate,
            context.cashOutCount,
            context.totalSupply,
            new JBCashOutHookSpecification[](0)
        );
    }

    function hasMintPermissionFor(uint256) external pure override returns (bool) {
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                               VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get all tiers for a project
    function getTiers(uint256 projectId) external view returns (WeightTier[] memory) {
        return tiersOf[projectId];
    }

    /// @notice Get the current active multiplier for a project
    function getCurrentMultiplier(uint256 projectId) external view returns (uint256) {
        uint256 multiplier = defaultMultiplier;

        WeightTier[] storage tiers = tiersOf[projectId];
        for (uint256 i; i < tiers.length; i++) {
            WeightTier storage tier = tiers[i];

            if (!tier.active) continue;
            if (tier.startTime > 0 && block.timestamp < tier.startTime) continue;
            if (tier.endTime > 0 && block.timestamp > tier.endTime) continue;
            if (tier.maxAmount > 0 && tier.amountUsed >= tier.maxAmount) continue;

            if (tier.weightMultiplier > multiplier) {
                multiplier = tier.weightMultiplier;
            }
        }

        return multiplier;
    }

    /// @notice Preview adjusted weight for a payment amount
    function previewWeight(uint256 projectId, uint256 baseWeight) external view returns (uint256) {
        uint256 multiplier = this.getCurrentMultiplier(projectId);
        return (baseWeight * multiplier) / MULTIPLIER_BASE;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IJBRulesetDataHook).interfaceId || super.supportsInterface(interfaceId);
    }
}
