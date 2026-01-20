---
name: jb-fund-access-limits
description: |
  Query and display Juicebox V5 fund access limits (payout limits, surplus allowances).
  Use when: (1) surplusAllowancesOf or payoutLimitsOf returns empty but values exist,
  (2) need to detect "unlimited" values which can be various max integers not just uint256,
  (3) fund access limits show as zero for USDC-based projects when querying with ETH token,
  (4) REVDeployer stageOf or configurationOf reverts. Covers JBFundAccessLimits querying,
  multi-token support (ETH/USDC), ruleset chain walking, and unlimited value detection.
---

# Juicebox V5 Fund Access Limits

## Problem

When querying JBFundAccessLimits for payout limits or surplus allowances, the queries may
return empty results even when values are set in the contract. Additionally, detecting
"unlimited" values is tricky because the protocol uses various max integers, not just
max uint256.

## Context / Trigger Conditions

- `surplusAllowancesOf` or `payoutLimitsOf` returns empty array
- Fund access shows "None" when it should show "Unlimited"
- Project uses USDC instead of ETH as base currency
- REVDeployer's `stageOf` or `configurationOf` functions revert
- Large numbers displayed instead of "Unlimited" label

## Solution

### 1. Query with Multiple Tokens

Fund access limits are keyed by (projectId, rulesetId, terminal, token). USDC-based
projects won't have results when querying with ETH token:

```typescript
const NATIVE_TOKEN = '0x000000000000000000000000000000000000EEEe'

// USDC addresses per chain
const USDC_ADDRESSES: Record<number, string> = {
  1: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',    // Ethereum
  10: '0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85',   // Optimism
  8453: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913', // Base
  42161: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831', // Arbitrum
}

// Try ETH first, then USDC
let limits = await fetchLimitsForToken(rulesetId, NATIVE_TOKEN)
if (!limits) {
  const usdcToken = USDC_ADDRESSES[chainId]
  if (usdcToken) {
    limits = await fetchLimitsForToken(rulesetId, usdcToken)
  }
}
```

### 2. Walk Back Ruleset Chain

If no limits found for current rulesetId, walk back through `basedOnId`:

```typescript
let currentRsId = BigInt(rulesetId)
while (attempts < maxAttempts) {
  const ruleset = await publicClient.readContract({
    address: JB_CONTRACTS.JBRulesets,
    abi: JB_RULESETS_ABI,
    functionName: 'getRulesetOf',
    args: [BigInt(projectId), currentRsId],
  })

  const basedOnId = BigInt(ruleset.basedOnId)
  if (basedOnId === 0n || basedOnId === currentRsId) break

  const limits = await fetchLimitsForRuleset(basedOnId)
  if (limits) return limits

  currentRsId = basedOnId
}
```

### 3. Detect "Unlimited" with Threshold

The protocol uses various max values (uint256, uint224, uint128, etc.). Use threshold:

```typescript
const isUnlimited = (amount: string | undefined): boolean => {
  if (!amount) return false
  try {
    // Any value > 10^30 is effectively unlimited
    return amount.length > 30 || BigInt(amount) > BigInt('1000000000000000000000000000000')
  } catch {
    return false
  }
}
```

### 4. Handle REVDeployer Version Differences

`stageOf` doesn't exist on all REVDeployer versions. Calculate current stage from timestamps:

```typescript
// Instead of calling stageOf (may not exist)
try {
  const config = await publicClient.readContract({
    address: REV_DEPLOYER,
    abi: REV_DEPLOYER_ABI,
    functionName: 'configurationOf',
    args: [BigInt(projectId)],
  })

  // Calculate current stage from timestamps
  const now = Math.floor(Date.now() / 1000)
  let currentStage = 1
  for (let i = 0; i < stageConfigs.length; i++) {
    if (Number(stageConfigs[i].startsAtOrAfter) <= now) {
      currentStage = i + 1
    }
  }
} catch {
  // configurationOf may revert on older deployments - handle gracefully
}
```

## Verification

- Surplus allowance displays "Unlimited" for Revnets instead of raw large number
- USDC-based projects show correct fund access values
- No console errors for REVDeployer function calls on older projects

## Example

For Artizen (project 6 on Base chain 8453):
- Uses USDC, not ETH - must query with USDC token address
- Surplus allowance returns `26959946667150640000000000000000000000000` which is "unlimited"
- REVDeployer configurationOf may revert - handle gracefully

## Notes

- USDC addresses are chain-specific (see table above)
- JBMultiTerminal5_1 address (`0x52869db3d61dde1e391967f2ce5039ad0ecd371c`) is same on all chains
- Currency field in results may be non-standard - don't rely on it for display
- For Revnets: payout limit is always 0, surplus allowance is always unlimited (for loans)

## Contract Functions

```solidity
// JBFundAccessLimits
function payoutLimitsOf(
  uint256 projectId,
  uint256 rulesetId,
  address terminal,
  address token
) external view returns (JBCurrencyAmount[] memory);

function surplusAllowancesOf(
  uint256 projectId,
  uint256 rulesetId,
  address terminal,
  address token
) external view returns (JBCurrencyAmount[] memory);
```

## References

- JBFundAccessLimits contract
- JBMultiTerminal5_1: `0x52869db3d61dde1e391967f2ce5039ad0ecd371c`
