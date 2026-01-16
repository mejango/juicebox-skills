// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBPayHook} from "@bananapus/core/src/interfaces/IJBPayHook.sol";
import {IJBRulesetDataHook} from "@bananapus/core/src/interfaces/IJBRulesetDataHook.sol";
import {JBAfterPayRecordedContext} from "@bananapus/core/src/structs/JBAfterPayRecordedContext.sol";
import {JBBeforePayRecordedContext} from "@bananapus/core/src/structs/JBBeforePayRecordedContext.sol";
import {JBBeforeCashOutRecordedContext} from "@bananapus/core/src/structs/JBBeforeCashOutRecordedContext.sol";
import {JBPayHookSpecification} from "@bananapus/core/src/structs/JBPayHookSpecification.sol";
import {JBCashOutHookSpecification} from "@bananapus/core/src/structs/JBCashOutHookSpecification.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title PaymentCapHook
/// @notice Limits maximum payment amount per transaction to prevent whale domination
/// @dev Implements IJBRulesetDataHook to validate payments before they're recorded
contract PaymentCapHook is IJBRulesetDataHook, ERC165, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error PaymentExceedsCap(uint256 amount, uint256 cap);
    error InvalidCap();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event CapUpdated(uint256 indexed projectId, uint256 oldCap, uint256 newCap);
    event PaymentValidated(uint256 indexed projectId, address indexed payer, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum payment amount per transaction for each project
    mapping(uint256 projectId => uint256 cap) public capOf;

    /// @notice Default cap if project-specific cap not set
    uint256 public defaultCap;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param _defaultCap Default maximum payment in wei
    /// @param _owner Owner address for configuration
    constructor(uint256 _defaultCap, address _owner) Ownable(_owner) {
        if (_defaultCap == 0) revert InvalidCap();
        defaultCap = _defaultCap;
    }

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Set payment cap for a specific project
    /// @param projectId The project ID
    /// @param cap Maximum payment amount in wei (0 to use default)
    function setCapFor(uint256 projectId, uint256 cap) external onlyOwner {
        uint256 oldCap = capOf[projectId];
        capOf[projectId] = cap;
        emit CapUpdated(projectId, oldCap, cap);
    }

    /// @notice Update the default cap
    /// @param _defaultCap New default cap in wei
    function setDefaultCap(uint256 _defaultCap) external onlyOwner {
        if (_defaultCap == 0) revert InvalidCap();
        defaultCap = _defaultCap;
    }

    /*//////////////////////////////////////////////////////////////
                             DATA HOOK
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates payment amount before recording
    /// @param context Payment context from terminal
    /// @return weight Token minting weight (unchanged)
    /// @return hookSpecifications Empty (no pay hooks needed)
    function beforePayRecordedWith(JBBeforePayRecordedContext calldata context)
        external
        view
        override
        returns (uint256 weight, JBPayHookSpecification[] memory hookSpecifications)
    {
        // Get effective cap for this project
        uint256 cap = capOf[context.projectId];
        if (cap == 0) cap = defaultCap;

        // Validate payment amount
        if (context.amount.value > cap) {
            revert PaymentExceedsCap(context.amount.value, cap);
        }

        // Return original weight, no additional hooks
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

    /// @notice Get effective cap for a project
    /// @param projectId The project ID
    /// @return The cap amount in wei
    function getEffectiveCap(uint256 projectId) external view returns (uint256) {
        uint256 cap = capOf[projectId];
        return cap == 0 ? defaultCap : cap;
    }
}
