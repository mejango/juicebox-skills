---
name: jb-omnichain-per-chain-projectids
description: |
  Omnichain Juicebox V5 projects have DIFFERENT projectIds on each chain. Use when:
  (1) "ERC2771UntrustfulTarget" or "simulation reverted" errors on cross-chain operations,
  (2) implementing setUriOf, queueRulesets, setSplits, distribute, or any project operation
  across multiple chains, (3) building UI that calls contracts on multiple chains for the
  same "project". Each chain mints its own project NFT with an incrementing ID - you must
  query per-chain projectIds from suckerGroups or bendystraw before any omnichain operation.
---

# Omnichain Juicebox Projects Have Different ProjectIds Per Chain

## Problem

When performing operations on omnichain Juicebox projects (setUriOf, queueRulesets, setSplits,
distribute payouts, deploy ERC20, etc.), using the same projectId for all chains causes
"simulation reverted" errors like `ERC2771UntrustfulTarget(request.to, address(this))`.

## Context / Trigger Conditions

- "ERC2771UntrustfulTarget" error when calling setUriOf or other project functions
- "simulation reverted" from Relayr on multi-chain operations
- `controllerOf(projectId)` returns zero address on some chains
- Building any UI or backend that operates on projects across multiple chains
- Implementing omnichain project modifications (metadata, rulesets, splits, etc.)

## Root Cause

**Omnichain Juicebox projects have DIFFERENT projectIds on each chain.**

When a project is deployed via `JBOmnichainDeployer`, each chain mints its own JBProjects
NFT with an incrementing ID. The projects are linked via "suckers" (cross-chain bridges),
but the projectIds are completely different:

```
Same omnichain project:
- Ethereum Mainnet: projectId = 123
- Optimism: projectId = 456
- Base: projectId = 789
- Arbitrum: projectId = 101
```

If you call `JBController.setUriOf(123, uri)` on Optimism, it will fail because project
123 on Optimism is a completely different project (or doesn't exist).

## Solution

### 1. Query Per-Chain ProjectIds Before Any Operation

Use bendystraw GraphQL to get the suckerGroup which contains all chain/projectId mappings:

```graphql
query GetSuckerGroup($projectId: Int!, $chainId: Int!) {
  suckerGroups(where: { projectId: $projectId, chainId: $chainId }) {
    id
    projects {
      chainId
      projectId
    }
  }
}
```

### 2. Use chainProjectMappings Format

For omnichain operations, always use an array of per-chain mappings:

```typescript
// CORRECT: Different projectId for each chain
const chainProjectMappings = [
  { chainId: 1, projectId: 123 },     // Ethereum
  { chainId: 10, projectId: 456 },    // Optimism
  { chainId: 8453, projectId: 789 },  // Base
];

// WRONG: Same projectId for all chains (will fail!)
const wrongMappings = [
  { chainId: 1, projectId: 123 },
  { chainId: 10, projectId: 123 },  // ❌ Wrong ID!
  { chainId: 8453, projectId: 123 }, // ❌ Wrong ID!
];
```

### 3. For Hooks, Use Record<chainId, projectId>

```typescript
interface OmnichainParams {
  chainIds: number[]
  projectIds: Record<number, number>  // chainId -> projectId
}

// Usage:
await queueRulesets({
  chainIds: [1, 10, 8453],
  projectIds: {
    1: 123,      // Ethereum project ID
    10: 456,     // Optimism project ID (different!)
    8453: 789    // Base project ID (different!)
  },
  rulesetConfigurations: [...],
});
```

### 4. Handle Zero Controller (Project Not Deployed Yet)

After omnichain deploy, cross-chain messages take time to arrive. If you query
`JBDirectory.controllerOf(projectId)` and get zero address, the project doesn't
exist on that chain yet:

```typescript
const controller = await getProjectController(client, projectId);

if (controller === zeroAddress) {
  console.warn(`Project ${projectId} not deployed on chain ${chainId} yet`);
  // Skip this chain or show "waiting for deployment" message
}
```

## Verification

1. Query suckerGroup to get all chain/projectId mappings
2. Verify each chain has a non-zero controller address
3. Use the correct projectId for each chain in the operation
4. Check transaction simulation passes before submitting

## Example: Fixing setUriOf for Omnichain Project

```typescript
// BEFORE (broken): Using same projectId for all chains
await setUri({
  chainProjectMappings: chainConfigs.map(c => ({
    chainId: c.chainId,
    projectId: 123,  // ❌ Same ID won't work!
  })),
  uri: 'ipfs://QmNew...',
});

// AFTER (fixed): Query per-chain projectIds first
const suckerGroup = await querySuckerGroup(123, 1);  // Get linked projects
await setUri({
  chainProjectMappings: suckerGroup.projects.map(p => ({
    chainId: p.chainId,
    projectId: p.projectId,  // ✓ Correct per-chain ID
  })),
  uri: 'ipfs://QmNew...',
});
```

## Notes

- This applies to ALL project operations, not just setUriOf
- Single-chain projects (not deployed via omnichain deployer) only have one projectId
- The suckerGroup is created during omnichain deployment and links all per-chain projects
- Cross-chain deployment via LayerZero can take 1-5 minutes - project may not exist on
  all chains immediately after deployment

## References

- Juicebox V5 omnichain architecture uses "suckers" for cross-chain bridging
- JBProjects is an ERC-721 contract - each chain has its own with incrementing IDs
- JBDirectory.controllerOf(projectId) returns zero if project doesn't exist on that chain
