---
name: jb-splitgroup-groupid-vs-currency
description: |
  JBSplitGroup.groupId (uint256) is NOT the same as currency (uint32) for most tokens.
  Use when: (1) configuring splitGroups for payouts, (2) seeing unexpected split behavior,
  (3) working with USDC or other ERC20 tokens. Only NATIVE_TOKEN has matching values by
  coincidence because 0x...EEEe fits in 32 bits.
author: Claude Code
version: 1.0.0
date: 2026-02-16
---

# Juicebox V5: groupId vs currency - Critical Distinction

## Problem
Split groups use the wrong groupId, causing payouts to fail or go to wrong recipients.
The common mistake is using the uint32 currency code as the groupId.

## Context / Trigger Conditions
- Configuring `JBSplitGroup` for payout splits
- Using USDC or other ERC20 tokens (not native ETH)
- Splits not executing as expected
- Copying currency values into groupId field

## Solution
**groupId and currency are calculated differently:**

| Field | Type | Formula | Purpose |
|-------|------|---------|---------|
| currency | uint32 | `uint32(uint160(token))` | JBAccountingContext, JBCurrencyAmount |
| groupId | uint256 | `uint256(uint160(token))` | JBSplitGroup identifier |

**For NATIVE_TOKEN (0x...EEEe):** Both equal 61166 (coincidence - address fits in 32 bits)

**For USDC and other tokens:** They are DIFFERENT values!

| Chain | Token | currency (uint32) | groupId (uint256) |
|-------|-------|-------------------|-------------------|
| Ethereum | USDC | 909516616 | 918893084697899778867092505822379350428204718920 |
| Optimism | USDC | 3530704773 | 63677651975084090027219091430485431588927 |
| Base | USDC | 3169378579 | 750055151264976176895681429887502848627 |
| Arbitrum | USDC | 1156540465 | 1002219449704601020763871664628665988657 |
| Any | Native ETH | 61166 | 61166 |

## Verification
- Calculate: `uint256(uint160(tokenAddress))` for groupId
- Calculate: `uint32(uint160(tokenAddress))` for currency (lower 32 bits only)
- Verify splits execute to correct recipients

## Example
```javascript
// WRONG - using currency as groupId
const badSplitGroup = {
  groupId: "909516616",  // This is the uint32 currency, NOT groupId!
  splits: [...]
};

// CORRECT - using full uint256 groupId
const goodSplitGroup = {
  groupId: "918893084697899778867092505822379350428204718920",
  splits: [...]
};

// For native ETH (special case - same value)
const ethSplitGroup = {
  groupId: "61166",  // Happens to equal currency for NATIVE_TOKEN
  splits: [...]
};
```

## Notes
- **Reserved token splits use groupId = 1** (JBSplitGroupIds.RESERVED_TOKENS), not a token address
- The convention comes from `JBSplitGroup.sol`: "By convention, this ID is `uint256(uint160(tokenAddress))`"
- Native token address: `0x000000000000000000000000000000000000EEEe` (defined in JBConstants.sol)
- When in doubt, compute the full uint256 value from the token address

## References
- Contract: `JBSplitGroup.sol` - groupId convention
- Contract: `JBConstants.sol` - NATIVE_TOKEN address
- Contract: `JBAccountingContext` - currency field (uint32)
