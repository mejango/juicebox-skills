// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBRulesetDataHook} from "@bananapus/core/src/interfaces/IJBRulesetDataHook.sol";
import {JBBeforePayRecordedContext} from "@bananapus/core/src/structs/JBBeforePayRecordedContext.sol";
import {JBBeforeCashOutRecordedContext} from "@bananapus/core/src/structs/JBBeforeCashOutRecordedContext.sol";
import {JBPayHookSpecification} from "@bananapus/core/src/structs/JBPayHookSpecification.sol";
import {JBCashOutHookSpecification} from "@bananapus/core/src/structs/JBCashOutHookSpecification.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title FundraisingCapHook
/// @notice Limits the total amount a project can raise
/// @dev Tracks cumulative payments and rejects payments that would exceed the cap
contract FundraisingCapHook is IJBRulesetDataHook, ERC165, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error FundraisingCapExceeded(uint256 currentTotal, uint256 paymentAmount, uint256 cap);
    error FundraisingCapReached(uint256 cap);
    error InvalidCap();
    error CapAlreadySet();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event CapSet(uint256 indexed projectId, uint256 cap);
    event CapIncreased(uint256 indexed projectId, uint256 oldCap, uint256 newCap);
    event PaymentRecorded(uint256 indexed projectId, address indexed payer, uint256 amount, uint256 newTotal);
    event CapReached(uint256 indexed projectId, uint256 totalRaised);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Fundraising cap for each project
    mapping(uint256 projectId => uint256) public capOf;

    /// @notice Total amount raised by each project
    mapping(uint256 projectId => uint256) public totalRaisedOf;

    /// @notice Whether the cap is immutable for a project
    mapping(uint256 projectId => bool) public capLockedOf;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) Ownable(_owner) {}

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Set fundraising cap for a project
    /// @param projectId The project ID
    /// @param cap Maximum total amount that can be raised
    /// @param lockCap If true, cap cannot be changed later
    function setCap(uint256 projectId, uint256 cap, bool lockCap) external onlyOwner {
        if (cap == 0) revert InvalidCap();
        if (capLockedOf[projectId]) revert CapAlreadySet();

        capOf[projectId] = cap;
        capLockedOf[projectId] = lockCap;

        emit CapSet(projectId, cap);
    }

    /// @notice Increase the cap for a project (only if not locked)
    /// @param projectId The project ID
    /// @param newCap New cap (must be higher than current)
    function increaseCap(uint256 projectId, uint256 newCap) external onlyOwner {
        if (capLockedOf[projectId]) revert CapAlreadySet();

        uint256 oldCap = capOf[projectId];
        if (newCap <= oldCap) revert InvalidCap();

        capOf[projectId] = newCap;

        emit CapIncreased(projectId, oldCap, newCap);
    }

    /*//////////////////////////////////////////////////////////////
                             DATA HOOK
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates payment doesn't exceed fundraising cap
    /// @param context Payment context from terminal
    /// @return weight Token minting weight (unchanged)
    /// @return hookSpecifications Empty (no pay hooks needed)
    function beforePayRecordedWith(JBBeforePayRecordedContext calldata context)
        external
        override
        returns (uint256 weight, JBPayHookSpecification[] memory hookSpecifications)
    {
        uint256 cap = capOf[context.projectId];

        // If no cap set, allow all payments
        if (cap == 0) {
            return (context.weight, new JBPayHookSpecification[](0));
        }

        uint256 currentTotal = totalRaisedOf[context.projectId];

        // Check if cap already reached
        if (currentTotal >= cap) {
            revert FundraisingCapReached(cap);
        }

        // Check if this payment would exceed cap
        uint256 newTotal = currentTotal + context.amount.value;
        if (newTotal > cap) {
            revert FundraisingCapExceeded(currentTotal, context.amount.value, cap);
        }

        // Update total raised
        totalRaisedOf[context.projectId] = newTotal;

        emit PaymentRecorded(context.projectId, context.payer, context.amount.value, newTotal);

        // Check if cap is now reached
        if (newTotal == cap) {
            emit CapReached(context.projectId, newTotal);
        }

        return (context.weight, new JBPayHookSpecification[](0));
    }

    /// @notice Pass through for cash outs (no modification)
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

    /// @notice This hook doesn't need mint permission
    function hasMintPermissionFor(uint256) external pure override returns (bool) {
        return false;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IJBRulesetDataHook).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                               VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get remaining capacity before cap is reached
    /// @param projectId The project ID
    /// @return Remaining amount that can be raised (0 if no cap or cap reached)
    function remainingCapacity(uint256 projectId) external view returns (uint256) {
        uint256 cap = capOf[projectId];
        if (cap == 0) return type(uint256).max; // No cap

        uint256 raised = totalRaisedOf[projectId];
        return cap > raised ? cap - raised : 0;
    }

    /// @notice Get fundraising progress as percentage (basis points)
    /// @param projectId The project ID
    /// @return Progress in basis points (0-10000, where 10000 = 100%)
    function progressOf(uint256 projectId) external view returns (uint256) {
        uint256 cap = capOf[projectId];
        if (cap == 0) return 0;

        uint256 raised = totalRaisedOf[projectId];
        if (raised >= cap) return 10000;

        return (raised * 10000) / cap;
    }

    /// @notice Check if a payment amount would be accepted
    /// @param projectId The project ID
    /// @param amount Payment amount to check
    /// @return Whether the payment would be accepted
    function wouldAccept(uint256 projectId, uint256 amount) external view returns (bool) {
        uint256 cap = capOf[projectId];
        if (cap == 0) return true; // No cap

        uint256 currentTotal = totalRaisedOf[projectId];
        return currentTotal + amount <= cap;
    }

    /// @notice Get full fundraising status for a project
    /// @param projectId The project ID
    /// @return cap The fundraising cap
    /// @return raised Total amount raised
    /// @return remaining Remaining capacity
    /// @return progress Progress in basis points
    /// @return isLocked Whether the cap is locked
    function getStatus(uint256 projectId)
        external
        view
        returns (uint256 cap, uint256 raised, uint256 remaining, uint256 progress, bool isLocked)
    {
        cap = capOf[projectId];
        raised = totalRaisedOf[projectId];
        remaining = cap > raised ? cap - raised : 0;
        progress = cap > 0 ? (raised * 10000) / cap : 0;
        isLocked = capLockedOf[projectId];
    }
}
