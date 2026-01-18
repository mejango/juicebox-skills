# Juicebox V5 Struct Reference

## Hook Context Structs

### JBAfterPayRecordedContext

Passed to pay hooks after payment recording.

```solidity
struct JBAfterPayRecordedContext {
    address payer;              // Address the payment originated from
    uint256 projectId;          // The project being paid
    uint256 rulesetId;          // The ruleset the payment is made during
    JBTokenAmount amount;       // The payment amount details
    JBTokenAmount forwardedAmount;  // Amount forwarded to the pay hook
    uint256 weight;             // Ruleset weight for token minting calculations
    uint256 newlyIssuedTokenCount;  // Tokens minted for the beneficiary
    address beneficiary;        // Receives minted tokens
    bytes hookMetadata;         // Extra data from the data hook
    bytes payerMetadata;        // Extra data from the payer
}
```

### JBAfterCashOutRecordedContext

Passed to cash out hooks after cash out recording.

```solidity
struct JBAfterCashOutRecordedContext {
    address holder;             // Token holder cashing out
    uint256 projectId;          // The project ID
    uint256 rulesetId;          // Active ruleset during cash out
    uint256 cashOutCount;       // Number of tokens being cashed out
    JBTokenAmount reclaimedAmount;   // Token details for reclaimed funds
    JBTokenAmount forwardedAmount;   // Token details for forwarded amount to hook
    uint256 cashOutTaxRate;     // Tax rate applied (0-10000)
    address payable beneficiary;     // Receives reclaimed funds
    bytes hookMetadata;         // Extra data from the data hook
    bytes cashOutMetadata;      // Extra data from the cash out initiator
}
```

### JBSplitHookContext

Passed to split hooks during split processing.

```solidity
struct JBSplitHookContext {
    address token;              // Token being distributed
    uint256 amount;             // Amount being sent to this split
    uint256 decimals;           // Token decimals
    uint256 projectId;          // Project distributing funds
    uint256 groupId;            // Split group ID
    JBSplit split;              // The split configuration
}
```

### JBBeforePayRecordedContext

Passed to data hooks before payment recording.

```solidity
struct JBBeforePayRecordedContext {
    address terminal;           // The terminal receiving payment
    address payer;              // The address paying
    JBTokenAmount amount;       // Payment amount details
    uint256 projectId;          // The project being paid
    uint256 rulesetId;          // Current ruleset ID
    address beneficiary;        // Token recipient
    uint256 weight;             // Ruleset weight
    uint256 reservedRate;       // Ruleset reserved rate
    bytes metadata;             // Payer-provided metadata
}
```

### JBBeforeCashOutRecordedContext

Passed to data hooks before cash out recording.

```solidity
struct JBBeforeCashOutRecordedContext {
    address terminal;           // The terminal processing cash out
    address holder;             // Token holder
    uint256 projectId;          // The project ID
    uint256 rulesetId;          // Current ruleset ID
    uint256 cashOutCount;       // Tokens to cash out
    uint256 totalSupply;        // Total token supply
    JBRuleset ruleset;          // Current ruleset configuration
    JBTokenAmount surplus;      // Project surplus
    bytes metadata;             // Cash out metadata
}
```

## Configuration Structs

### JBRuleset

A time-bounded configuration for project behavior.

```solidity
struct JBRuleset {
    uint256 cycleNumber;        // The ruleset cycle number
    uint256 id;                 // Unique ruleset ID
    uint256 basedOnId;          // ID of the ruleset this is based on
    uint256 start;              // Start timestamp
    uint256 duration;           // Duration in seconds (0 = indefinite)
    uint256 weight;             // Token minting weight (fixed-point 18 decimals)
    uint256 weightCutPercent;   // Percent weight decreases each cycle (0-1000000000)
    IJBRulesetApprovalHook approvalHook;  // Approval hook address
    JBRulesetMetadata metadata; // Ruleset metadata
}
```

### JBRulesetMetadata

Metadata packed into a ruleset.

```solidity
struct JBRulesetMetadata {
    uint256 reservedRate;       // Reserved token percentage (0-10000)
    uint256 cashOutTaxRate;     // Tax on cash outs (0-10000)
    uint256 baseCurrency;       // Base currency for accounting
    bool pausePay;              // Whether payments are paused
    bool pauseCashOut;          // Whether cash outs are paused
    bool pauseTransfers;        // Whether token transfers are paused
    bool allowOwnerMinting;     // Allow project owner to mint
    bool allowTerminalMigration;    // Allow terminal migration
    bool allowSetTerminals;     // Allow setting terminals
    bool allowSetController;    // Allow setting controller
    bool allowAddAccountingContexts; // Allow adding accounting contexts
    bool allowAddPriceFeed;     // Allow adding price feeds
    bool ownerMustSendPayouts;  // Owner must trigger payouts
    bool holdFees;              // Hold fees instead of processing
    bool useTotalSurplusForCashOuts; // Use total surplus for cash out calculations
    bool useDataHookForPay;     // Use data hook for payments
    bool useDataHookForCashOut; // Use data hook for cash outs
    address dataHook;           // Data hook address
    uint256 metadata;           // Additional custom metadata
}
```

### JBSplit

Configuration for a single split recipient.

```solidity
struct JBSplit {
    bool preferAddToBalance;    // Add to project balance instead of paying
    uint256 percent;            // Percent of distribution (out of 1000000000)
    uint256 projectId;          // Project to pay (0 for wallet)
    address payable beneficiary;     // Wallet to pay if projectId is 0
    uint256 lockedUntil;        // Timestamp until which split is locked
    IJBSplitHook hook;          // Split hook to process payment
}
```

### JBTokenAmount

Token amount with metadata.

```solidity
struct JBTokenAmount {
    address token;              // Token address (address(0) for native)
    uint256 value;              // Amount value
    uint256 decimals;           // Token decimals
    uint256 currency;           // Currency ID for pricing
}
```

### JBRulesetConfig

Configuration for queuing a new ruleset.

```solidity
struct JBRulesetConfig {
    uint256 mustStartAtOrAfter; // Earliest start time
    uint256 duration;           // Duration in seconds
    uint256 weight;             // Initial weight
    uint256 weightCutPercent;   // Weight cut per cycle
    IJBRulesetApprovalHook approvalHook;  // Approval hook
    JBRulesetMetadata metadata; // Ruleset metadata
    JBSplitGroup[] splitGroups; // Split configurations
    JBFundAccessLimitGroup[] fundAccessLimitGroups; // Fund access limits
}
```

### JBPayHookSpecification

Specification returned by data hooks for pay hooks.

```solidity
struct JBPayHookSpecification {
    IJBPayHook hook;            // The pay hook to call
    uint256 amount;             // Amount to forward to the hook
    bytes metadata;             // Metadata for the hook
}
```

### JBCashOutHookSpecification

Specification returned by data hooks for cash out hooks.

```solidity
struct JBCashOutHookSpecification {
    IJBCashOutHook hook;        // The cash out hook to call
    uint256 amount;             // Amount to forward to the hook
    bytes metadata;             // Metadata for the hook
}
```

## Source

- nana-core-v5: https://github.com/Bananapus/nana-core-v5
