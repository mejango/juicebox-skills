---
name: jbv5-omnichain-tier-quantity-per-chain
description: |
  Juicebox V5 omnichain 721 tier quantities are PER-CHAIN, not total. Use when:
  (1) user sets limited quantity for physical goods (signed books, merch) on omnichain
  project, (2) "limited to 10" actually means 40 total (10 per chain × 4 chains),
  (3) user has true limited inventory but tier deploys to all chains. Solution:
  for physical goods, deploy limited tier to ONE chain only, or divide quantity
  by number of chains. initialSupply is per-chain not global.
author: Claude Code
version: 1.0.0
date: 2026-02-14
---

# Omnichain Tier Quantities Are Per-Chain

## Problem

When deploying 721 tier projects (launch721Project) via JBOmnichainDeployer, the
`initialSupply` for each tier is set identically on ALL chains. This means:

- "Limited to 10" = 10 on Ethereum + 10 on Optimism + 10 on Base + 10 on Arbitrum
- **Actual total: 40 possible mints**, not 10

For physical goods with true limited inventory (signed books, limited merch), this
creates a mismatch between what the user thinks they're offering and what's actually
available.

## Context / Trigger Conditions

- User creates 721 tier project with limited quantity
- User has physical goods with true limited inventory
- Tier configuration shows same `initialSupply` across all `chainConfigs`
- User says things like "only 10 signed copies" or "limited edition of 25"

## Solution

**When user selects limited quantity, ALWAYS ask:**

"Since your project will be available on multiple chains, do you want this tier to be:
- Limited to [X] per chain (so [X × 4] total across all chains), or
- Only available on one chain (truly limited to [X] total)?"

**For physical goods with true limited inventory:**

Option 1: Deploy that tier to ONE chain only
- Use `chainConfigs` overrides to exclude the tier from other chains
- User picks which chain hosts the limited tier

Option 2: Divide quantity by number of chains
- If 10 total across 4 chains: set `initialSupply: 3` (rounding up gives ~3 per chain)
- Note: this creates uneven distribution and "race" dynamics

**For digital exclusivity (no physical fulfillment):**
- Per-chain limits are fine
- "First 10 on each chain" creates multiple exclusive collector groups
- Explain this is per-chain, let user decide if that's acceptable

## Verification

For physical limited inventory:
- Tier only appears in ONE chain's configuration, OR
- `initialSupply` is divided by number of chains
- User understands the actual total available

## Example

**Wrong approach:**
```json
// User: "Only 10 signed copies available"
// Deploys to 4 chains with:
"initialSupply": 10  // on ALL chains = 40 total possible
```

**Correct approach (single chain):**
```json
// Tier only in Ethereum config, excluded from other chainConfigs
"chainConfigs": [
  {
    "chainId": "1",
    "label": "Ethereum",
    // tier included here with initialSupply: 10
  },
  {
    "chainId": "10",
    "label": "Optimism",
    // tier EXCLUDED from this chain's tier config
  }
  // ... etc
]
```

**Correct approach (divided):**
```json
// User has 10 books, 4 chains
// Set initialSupply: 3 on each chain (12 total slots, 10 real books)
// User must track fulfillment manually
"initialSupply": 3
```

## Notes

- This applies to ALL omnichain 721 projects, not just physical goods
- For unlimited tiers (`initialSupply: 4294967295`), per-chain is fine
- Cash outs are also per-chain (different balances/supplies per chain)
- The user experience should clarify which chain they're minting on
