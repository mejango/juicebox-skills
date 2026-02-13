---
name: jb-721-tier-category-sorting
description: |
  JB721TiersHook requires tiers sorted by CATEGORY, not price. Use when: (1) calling
  adjustTiers or launch721Project with multiple tiers, (2) getting InvalidCategorySortOrder
  revert, (3) building tier arrays for Juicebox V5 NFT hooks. The contract enforces
  category ascending order - each tier's category must be >= the previous tier's category.
author: Claude Code
version: 1.0.0
date: 2026-02-10
---

# Juicebox V5 NFT Tier Sorting: Category, Not Price

## Problem
When adding NFT tiers to a Juicebox V5 project via `adjustTiers` or `launch721Project`,
the transaction reverts with `JB721TiersHookStore_InvalidCategorySortOrder` if tiers
aren't properly sorted.

## Context / Trigger Conditions
- Calling `adjustTiers(JB721TierConfig[] tiersToAdd, uint256[] tierIdsToRemove)`
- Calling `launch721Project` with `JB721InitTiersConfig.tiers`
- Error: `JB721TiersHookStore_InvalidCategorySortOrder(tierToAdd.category, previousTier.category)`
- Transaction reverts when submitting new tiers

## Solution
**Sort tiers by category in ascending order (lowest category first).**

The contract validation:
```solidity
// Make sure the tier's category is greater than or equal to the previously added tier's category.
if (i != 0) {
    previousTier = tiersToAdd[i - 1];
    if (tierToAdd.category < previousTier.category) {
        revert JB721TiersHookStore_InvalidCategorySortOrder(tierToAdd.category, previousTier.category);
    }
}
```

**Correct ordering example:**
```javascript
const tiers = [
  { name: "Basic", category: 1, price: 100 },    // category 1 first
  { name: "Premium", category: 1, price: 50 },   // same category OK (price doesn't matter)
  { name: "VIP", category: 2, price: 200 },      // category 2 after 1
  { name: "Exclusive", category: 3, price: 150 } // category 3 after 2
];
```

**Sort before submitting:**
```javascript
tiersToAdd.sort((a, b) => a.category - b.category);
```

## Verification
- Transaction succeeds without `InvalidCategorySortOrder` revert
- Tiers appear in the shop grouped by their categories

## Example
```javascript
// WRONG - will revert (category 2 before category 1)
const badTiers = [
  { name: "VIP", category: 2, price: 200 },
  { name: "Basic", category: 1, price: 100 }
];

// CORRECT - sorted by category ascending
const goodTiers = [
  { name: "Basic", category: 1, price: 100 },
  { name: "VIP", category: 2, price: 200 }
];
```

## Notes
- **Price does NOT affect sort order** - only category matters for validation
- Tiers within the same category can be in any order relative to each other
- Category 0 is valid and would come first
- This applies to both `launch721Project` (new projects) and `adjustTiers` (existing projects)
- The UI typically displays tiers grouped by category, so this sorting aligns with display order

## References
- Contract: `JB721TiersHookStore.sol` - `recordAddTiers()` function
- Error: `JB721TiersHookStore_InvalidCategorySortOrder(uint256 tierCategory, uint256 previousTierCategory)`
