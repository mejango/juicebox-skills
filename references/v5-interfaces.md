# Juicebox V5 Interface Reference

## Hook Interfaces

### IJBPayHook

Called after a terminal's `pay(...)` logic completes.

```solidity
interface IJBPayHook is IERC165 {
    /// @notice Hook called after a terminal's `pay(...)` logic completes.
    /// @dev Critical business logic should be protected by appropriate access control.
    /// @param context The context passed by the terminal after payment recording.
    function afterPayRecordedWith(JBAfterPayRecordedContext calldata context) external payable;
}
```

### IJBCashOutHook

Called after a terminal's `cashOutTokensOf(...)` logic completes.

```solidity
interface IJBCashOutHook is IERC165 {
    /// @notice Hook called after a terminal's cash out logic completes.
    /// @dev Critical business logic should be protected by appropriate access control.
    /// @param context The context passed by the terminal after cash out recording.
    function afterCashOutRecordedWith(JBAfterCashOutRecordedContext calldata context) external payable;
}
```

### IJBSplitHook

Allows processing a single split with custom logic.

```solidity
interface IJBSplitHook is IERC165 {
    /// @notice Process a single split with custom logic.
    /// @dev Tokens and native currency are optimistically transferred to the hook.
    /// @param context The context passed by the terminal or controller.
    function processSplitWith(JBSplitHookContext calldata context) external payable;
}
```

### IJBRulesetDataHook

Data hooks receive information about payments/cash outs and return payloads for execution hooks.

```solidity
interface IJBRulesetDataHook is IERC165 {
    /// @notice Called before a payment is recorded.
    /// @param context The payment context.
    /// @return weight The weight to use for token minting.
    /// @return hookSpecifications Specifications for pay hooks to call.
    function beforePayRecordedWith(JBBeforePayRecordedContext calldata context)
        external
        view
        returns (uint256 weight, JBPayHookSpecification[] memory hookSpecifications);

    /// @notice Called before a cash out is recorded.
    /// @param context The cash out context.
    /// @return cashOutTaxRate The tax rate to apply (0-10000, where 10000 = 100%).
    /// @return cashOutCount The number of tokens to cash out.
    /// @return totalSupply The total supply for ratio calculations.
    /// @return hookSpecifications Specifications for cash out hooks to call.
    function beforeCashOutRecordedWith(JBBeforeCashOutRecordedContext calldata context)
        external
        view
        returns (
            uint256 cashOutTaxRate,
            uint256 cashOutCount,
            uint256 totalSupply,
            JBCashOutHookSpecification[] memory hookSpecifications
        );

    /// @notice Whether this contract has mint permission for a project.
    /// @param projectId The project ID.
    /// @return hasMintPermission True if this contract can mint tokens.
    function hasMintPermissionFor(uint256 projectId) external view returns (bool hasMintPermission);
}
```

## Core Contract Interfaces

### IJBController

Manages project rulesets and token operations.

```solidity
interface IJBController {
    /// @notice Launch a project with the first ruleset.
    function launchProjectFor(
        address owner,
        string calldata projectUri,
        JBRulesetConfig[] calldata rulesetConfigurations,
        JBTerminalConfig[] calldata terminalConfigurations,
        string calldata memo
    ) external returns (uint256 projectId);

    /// @notice Queue rulesets for a project.
    function queueRulesetsOf(
        uint256 projectId,
        JBRulesetConfig[] calldata rulesetConfigurations,
        string calldata memo
    ) external returns (uint256 rulesetId);

    /// @notice Mint tokens to a beneficiary.
    function mintTokensOf(
        uint256 projectId,
        uint256 tokenCount,
        address beneficiary,
        string calldata memo,
        bool useReservedRate
    ) external returns (uint256 beneficiaryTokenCount);

    /// @notice Burn tokens from a holder.
    function burnTokensOf(
        address holder,
        uint256 projectId,
        uint256 tokenCount,
        string calldata memo
    ) external;
}
```

### IJBMultiTerminal

Handles payments, cash outs, and fund distribution.

```solidity
interface IJBMultiTerminal {
    /// @notice Pay a project.
    function pay(
        uint256 projectId,
        address token,
        uint256 amount,
        address beneficiary,
        uint256 minReturnedTokens,
        string calldata memo,
        bytes calldata metadata
    ) external payable returns (uint256 beneficiaryTokenCount);

    /// @notice Cash out tokens for funds.
    function cashOutTokensOf(
        address holder,
        uint256 projectId,
        uint256 cashOutCount,
        address tokenToReclaim,
        uint256 minTokensReclaimed,
        address payable beneficiary,
        bytes calldata metadata
    ) external returns (uint256 reclaimAmount);

    /// @notice Distribute payouts to splits.
    function sendPayoutsOf(
        uint256 projectId,
        address token,
        uint256 amount,
        uint256 currency,
        uint256 minTokensPaidOut
    ) external returns (uint256 amountPaidOut);

    /// @notice Use surplus allowance.
    function useAllowanceOf(
        uint256 projectId,
        address token,
        uint256 amount,
        uint256 currency,
        uint256 minTokensPaidOut,
        address payable beneficiary,
        address payable feeBeneficiary,
        string calldata memo
    ) external returns (uint256 amountPaidOut);
}
```

### IJBDirectory

Maps projects to their terminals and controllers.

```solidity
interface IJBDirectory {
    /// @notice Get the controller for a project.
    function controllerOf(uint256 projectId) external view returns (IERC165 controller);

    /// @notice Get all terminals for a project.
    function terminalsOf(uint256 projectId) external view returns (IJBTerminal[] memory terminals);

    /// @notice Get the primary terminal for a project and token.
    function primaryTerminalOf(uint256 projectId, address token)
        external
        view
        returns (IJBTerminal terminal);

    /// @notice Check if a terminal is valid for a project.
    function isTerminalOf(uint256 projectId, IJBTerminal terminal) external view returns (bool);
}
```

### IJBProjects

ERC-721 representing project ownership.

```solidity
interface IJBProjects is IERC721 {
    /// @notice The number of projects created.
    function count() external view returns (uint256);

    /// @notice Create a new project.
    function createFor(address owner) external returns (uint256 projectId);
}
```

## Source

- nana-core-v5: https://github.com/Bananapus/nana-core-v5
