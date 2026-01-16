# Juicebox V5 Deployed Addresses

> **Important**: V5 is the current recommended version. Use these addresses for new projects.

## Ethereum Mainnet

### Core Contracts

| Contract | Address |
|----------|---------|
| JBProjects | `0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4` |
| JBDirectory | `0x0061e516886a0540f63157f112c0588ee0651dcf` |
| JBController | `0x27da30646502e2f642be5281322ae8c394f7668a` |
| JBMultiTerminal | `0x2db6d704058e552defe415753465df8df0361846` |
| JBTokens | `0x4d0edd347fb1fa21589c1e109b3474924be87636` |
| JBSplits | `0x7160a322fea44945a6ef9adfd65c322258df3c5e` |
| JBRulesets | `0x6292281d69c3593fcf6ea074e5797341476ab428` |
| JBPermissions | `0x04fd6913d6c32d8c216e153a43c04b1857a7793d` |
| JBPrices | `0x9b90e507cf6b7eb681a506b111f6f50245e614c4` |
| JBTerminalStore | `0xfe33b439ec53748c87dcedacb83f05add5014744` |

### 721 Hook Contracts

| Contract | Address |
|----------|---------|
| JB721TiersHookDeployer | `0xef60878d00378ac5f93d209f4616450ee8d41ca7` |
| JB721TiersHookProjectDeployer | `0x048626e715a194fc38dd9be12f516b54b10e725a` |
| JB721TiersHookStore | `0x2bc696b0af74042b30b2687ab5817cc824eba8ee` |

## Quick Copy Reference (Mainnet)

```solidity
// Core V5 Mainnet Addresses
address constant JB_CONTROLLER = 0x27da30646502e2f642be5281322ae8c394f7668a;
address constant JB_MULTI_TERMINAL = 0x2db6d704058e552defe415753465df8df0361846;
address constant JB_PROJECTS = 0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4;
address constant JB_DIRECTORY = 0x0061e516886a0540f63157f112c0588ee0651dcf;
address constant JB_TOKENS = 0x4d0edd347fb1fa21589c1e109b3474924be87636;
address constant JB_SPLITS = 0x7160a322fea44945a6ef9adfd65c322258df3c5e;
address constant JB_PERMISSIONS = 0x04fd6913d6c32d8c216e153a43c04b1857a7793d;

// 721 Hook V5 Mainnet
address constant JB_721_HOOK_DEPLOYER = 0xef60878d00378ac5f93d209f4616450ee8d41ca7;
address constant JB_721_HOOK_PROJECT_DEPLOYER = 0x048626e715a194fc38dd9be12f516b54b10e725a;
```

## Sepolia Testnet

| Contract | Address |
|----------|---------|
| JBProjects | *Check docs.juicebox.money/dev/v5/addresses/* |
| JBDirectory | *Check docs.juicebox.money/dev/v5/addresses/* |
| JBController | *Check docs.juicebox.money/dev/v5/addresses/* |
| JBMultiTerminal | *Check docs.juicebox.money/dev/v5/addresses/* |

## Optimism Mainnet

| Contract | Address |
|----------|---------|
| JBProjects | *Same addresses as Ethereum mainnet (deterministic deployment)* |
| JBDirectory | *Same addresses as Ethereum mainnet* |
| JBController | *Same addresses as Ethereum mainnet* |
| JBMultiTerminal | *Same addresses as Ethereum mainnet* |

## Arbitrum Mainnet

| Contract | Address |
|----------|---------|
| JBProjects | *Same addresses as Ethereum mainnet (deterministic deployment)* |
| JBDirectory | *Same addresses as Ethereum mainnet* |
| JBController | *Same addresses as Ethereum mainnet* |
| JBMultiTerminal | *Same addresses as Ethereum mainnet* |

## Base Mainnet

| Contract | Address |
|----------|---------|
| JBProjects | *Same addresses as Ethereum mainnet (deterministic deployment)* |
| JBDirectory | *Same addresses as Ethereum mainnet* |
| JBController | *Same addresses as Ethereum mainnet* |
| JBMultiTerminal | *Same addresses as Ethereum mainnet* |

## Off-the-Shelf Hooks

### Buyback Hook (nana-buyback-hook-v5)

| Network | Address |
|---------|---------|
| Ethereum | *Check nana-buyback-hook-v5 deployments* |
| Optimism | *Same as Ethereum (deterministic)* |

### 721 Tiered Hook (nana-721-hook-v5)

| Network | Deployer Address |
|---------|-----------------|
| Ethereum | `0xef60878d00378ac5f93d209f4616450ee8d41ca7` |
| Optimism | *Same as Ethereum (deterministic)* |

## Revnet Deployers (revnet-core-v5)

| Deployer | Ethereum |
|----------|----------|
| BasicRevnetDeployer | *Check revnet-core-v5 deployments* |
| PayHookRevnetDeployer | *Check revnet-core-v5 deployments* |
| Tiered721RevnetDeployer | *Check revnet-core-v5 deployments* |
| CroptopRevnetDeployer | *Check revnet-core-v5 deployments* |

---

## Version History

| Version | Status | Notes |
|---------|--------|-------|
| V5 | **Current** | Use for new projects. Fixes buyback hook bug from V4 |
| V4 | Deprecated | Do not use for new projects |
| V3 | Legacy | Do not use |

---

## Official Sources

For the most current addresses:
- **V5 Docs**: https://docs.juicebox.money/dev/v5/addresses/
- **nana-core-v5**: https://github.com/Bananapus/nana-core-v5/tree/main/deployments
- **nana-721-hook-v5**: https://github.com/Bananapus/nana-721-hook-v5/tree/main/deployments
- **revnet-core-v5**: https://github.com/rev-net/revnet-core-v5/tree/main/deployments
