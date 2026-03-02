---
name: jb-always-launch721project
description: |
  Always use launch721Project even for projects without NFT tiers. Use when: (1) launching
  any new Juicebox V5 project, (2) user chooses "ownership", "donation", or "loan" project
  types. An empty tiers array enables future tier additions without redeploying the project.
author: Claude Code
version: 1.0.0
date: 2026-02-16
---

# Juicebox V5: Always Use launch721Project

## Problem
Projects launched with `launchProject` (without 721 hook) cannot easily add NFT tiers later.
The project owner would need to redeploy or use complex migration paths.

## Context / Trigger Conditions
- Launching ANY new Juicebox V5 project
- User says they don't need tiers/rewards right now
- User chooses "ownership stake", "donation", or "loan" project types
- Temptation to use simpler `launchProject` action

## Solution
**Always use `launch721Project` with an empty tiers array.**

This deploys the 721 hook infrastructure even if no tiers are configured initially.
The project owner can add tiers later via `adjustTiers` without any migration.

```json
{
  "action": "launch721Project",
  "contract": "JBOmnichainDeployer5_1",
  "parameters": {
    "deployTiersHookConfig": {
      "name": "Project Collection",
      "symbol": "PROJ",
      "baseUri": "",
      "tokenUriResolver": "0x0000000000000000000000000000000000000000",
      "contractUri": "ipfs://PROJECT_METADATA_CID",
      "tiersConfig": {
        "tiers": [],
        "currency": 2,
        "decimals": 6,
        "prices": "0x0000000000000000000000000000000000000000"
      },
      "reserveBeneficiary": "0x0000000000000000000000000000000000000000",
      "flags": {
        "noNewTiersWithReserves": false,
        "noNewTiersWithVotes": false,
        "noNewTiersWithOwnerMinting": false,
        "preventOverspending": false
      }
    },
    "launchProjectConfig": { ... },
    "salt": "0x0000000000000000000000000000000000000000000000000000000000000001",
    "suckerDeploymentConfiguration": { ... }
  }
}
```

## Verification
- Action is `launch721Project`, not `launchProject`
- `deployTiersHookConfig.tiersConfig.tiers` is an empty array `[]`
- Project deploys successfully with 721 hook attached
- Owner can later call `adjustTiers` to add products/rewards

## Example

**All project types use launch721Project:**

| User Chose | Action | Tiers |
|------------|--------|-------|
| "Nothing - donation" | launch721Project | `[]` (empty) |
| "Pay them back later" | launch721Project | `[]` (empty) |
| "Stake in the project" | launch721Project | `[]` (empty) |
| "Perks or rewards" | launch721Project | `[{...}, {...}]` |

## Notes
- **Every project is a potential storefront** - even donation/ownership projects may want to sell merch later
- The 721 hook adds minimal overhead when tiers are empty
- `useDataHookForPay: true` in ruleset metadata enables the hook
- Future tier additions use `adjustTiers(tiersToAdd, tierIdsToRemove)`
- This applies to revnets too - use `deploy721Revnet` instead of `deployRevnet`

## References
- Contract: `JBOmnichainDeployer5_1` - `launch721Project` function
- Contract: `JB721TiersHook` - `adjustTiers` for adding tiers later
- Action: `deploy721Revnet` for autonomous projects with 721 capability
