---
name: jb-721-per-chain-config
description: |
  Omnichain Juicebox V5 projects with 721 hooks deploy separate NFT collections on each chain.
  Supply is per-chain, not aggregate. Use when: (1) user asks about total supply across chains,
  (2) building UI that displays aggregate NFT supply, (3) explaining why supply "multiplies" on
  multi-chain projects, (4) helping users decide between single-chain and multi-chain for NFTs.
  Covers the limitation, UI patterns for clarity, and user communication guidelines.
---

# Per-Chain 721 Tier Configuration

## The Problem

**NFT tier supply in Juicebox V5 is per-chain, not aggregate.**

When you deploy an omnichain project with 721 hooks (NFT rewards), each chain gets its own independent NFT collection with its own supply. Setting 100 copies of a tier and deploying to 3 networks means 300 total NFTs exist (100 on each chain).

```
┌─────────────────────────────────────────────────────────────────────┐
│  Omnichain Project with 100-copy NFT Tier                           │
│                                                                     │
│  Ethereum:  100 copies  →  Can mint 100 NFTs                       │
│  Optimism:  100 copies  →  Can mint 100 NFTs                       │
│  Base:      100 copies  →  Can mint 100 NFTs                       │
│                             ─────────────                           │
│                             TOTAL: 300 NFTs possible                │
│                                                                     │
│  User expectation: 100 total                                        │
│  Reality: 300 total                                                 │
└─────────────────────────────────────────────────────────────────────┘
```

## Why This Happens

Each chain has its own `JB721TiersHook` contract with its own `JB721TiersStore`. These are independent deployments - there is no cross-chain state sharing for NFT supply.

This is different from tokens (ERC20), which can be bridged via Suckers to maintain unified balances. NFTs are non-fungible and cannot be bridged the same way.

## User Communication Guidelines

When explaining this to users, avoid blockchain jargon. Use "locations" or "networks" instead of "chains".

**Good explanation:**
> "Your reward supply is set per location. If you set 100 copies and deploy to 3 networks, there will be 100 available at each - 300 total.
>
> If you want exactly 100 copies total, you can either:
> 1. Enable NFT rewards on just one network, or
> 2. Split the supply across networks (e.g., 33 on each)"

**Avoid:**
> "The 721 tier hook is deployed independently on each chain with its own store contract..."

## UI Patterns for Multi-Chain Supply Display

### Pattern 1: Show Current Chain + Total on Click

Display the current chain's remaining supply by default. On click, show a popover with per-chain breakdown and aggregate total.

```tsx
// Supply badge in NFT tier card
<SupplyBadge
  tierId={tier.tierId}
  currentRemaining={tier.remainingSupply}  // Current chain only
  connectedChains={connectedChains}         // For fetching other chains
  isDark={isDark}
/>

// Popover shows:
// ┌─────────────────────┐
// │ Supply by network   │
// │ Ethereum:    45     │
// │ Optimism:    67     │
// │ Base:        82     │
// │ ───────────────     │
// │ Total:      194     │
// └─────────────────────┘
```

### Pattern 2: Fetch Aggregate Supply

```typescript
import { fetchMultiChainTierSupply } from '@/services/nft/multichain'

const supply = await fetchMultiChainTierSupply(tierId, connectedChains)
// Returns:
// {
//   totalRemaining: 194,
//   totalInitial: 300,
//   perChain: [
//     { chainId: 1, chainName: 'Ethereum', remaining: 45, initial: 100 },
//     { chainId: 10, chainName: 'Optimism', remaining: 67, initial: 100 },
//     { chainId: 8453, chainName: 'Base', remaining: 82, initial: 100 }
//   ]
// }
```

### Pattern 3: Technical Details Per-Chain View

In transaction previews for `launch721Project`, show tier configuration with a chain selector to clarify that the same config applies to each chain independently.

```tsx
<TiersHookConfigSection
  allChainIds={[1, 10, 8453]}
  baseConfig={deployTiersHookConfig}
  chainConfigs={chainConfigs}  // Optional per-chain overrides
  isDark={isDark}
/>
```

Display includes:
- Chain dropdown selector
- "per-network" badge to highlight chain-specific nature
- Tier summary with supply note: "3 networks × 100 supply = separate supplies on each"

## Recommendations by Use Case

### "I want exactly 100 NFTs total"

**Option A: Single-chain NFT deployment**
- Deploy the project to multiple chains
- Only enable NFT rewards on one chain
- Other chains have the project but no NFT hook

**Option B: Split supply**
- Divide your target supply across chains
- Example: 33 on Ethereum, 33 on Optimism, 34 on Base = 100 total
- Downside: Uneven distribution if one chain sells out first

### "I want maximum distribution"

Accept the per-chain supply model:
- Set supply high on each chain
- Users on each network have full access to all tiers
- Supply effectively multiplies by number of chains

### "I want scarcity across all chains"

This is fundamentally hard. Options:
1. **Off-chain coordination**: Monitor aggregate mints via Bendystraw, pause minting when approaching target
2. **Manual management**: Reduce supply on chains that are selling faster
3. **Single-chain**: Only enable NFTs on one chain

## Technical Details: How 721 Hooks are Deployed Per-Chain

When using `launch721Project` or `launch721RulesetsFor` via the JBOmnichainDeployer:

1. The deployer is called on each chain in the `chainIds` array
2. Each chain deploys its own `JB721TiersHook` instance
3. Each hook has its own `JB721TiersStore` with independent tier data
4. Tier IDs, prices, and supplies are identical but completely independent

```solidity
// Simplified view of what happens on each chain
function launch721RulesetsFor(
    uint56 projectId,
    JBDeployTiersHookConfig calldata deployTiersHookConfig,
    JBLaunchRulesetsConfig calldata launchRulesetsConfig,
    ...
) external {
    // 1. Deploy a new 721 hook on THIS chain
    IJB721TiersHook hook = deployer.deploy721TiersHook(
        projectId,
        deployTiersHookConfig
    );

    // 2. Configure ruleset with this hook
    controller.launchRulesetsFor(
        projectId,
        launchRulesetsConfig,
        hook
    );
}
```

## Querying Supply Across Chains

Use Bendystraw for aggregate queries or direct RPC calls for real-time data.

### Via Bendystraw (Recommended for UIs)

```graphql
query GetMultiChainTiers($projectId: String!) {
  suckerGroup(id: $projectId) {
    projects_rel {
      chainId
      projectId
      nftTiers {
        tierId
        remainingSupply
        initialSupply
      }
    }
  }
}
```

### Via Direct RPC (Real-time)

```typescript
import { getProjectDataHook, fetchNFTTier } from '@/services/nft'

async function getTierSupplyOnChain(projectId: number, tierId: number, chainId: number) {
  const hookAddress = await getProjectDataHook(String(projectId), chainId)
  if (!hookAddress) return null

  const tier = await fetchNFTTier(hookAddress, tierId, chainId)
  return tier?.remainingSupply || 0
}
```

## Related Skills

- `/jb-omnichain-per-chain-projectids` - Each chain has different projectIds
- `/jb-omnichain-payout-limits` - Similar per-chain constraint for payouts
- `/jb-omnichain-ui` - Building omnichain frontends
- `/jb-query` - Querying project state from blockchain
- `/jb-bendystraw` - GraphQL API for aggregate data
