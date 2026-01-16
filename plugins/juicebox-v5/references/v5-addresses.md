# Juicebox V5 Deployed Addresses

> **V5.1 Update (Dec 2025)**: V5.1 fixes an approval hook bug in JBRulesets.

## What Changed in V5.1?

**Only JBRulesets has a code change** (one-line approval hook fix). Other contracts were redeployed because they depend on JBRulesets (directly or transitively):

| Contract | Dependency |
|----------|------------|
| JBRulesets5_1 | **Actual code fix** |
| JBController5_1 | Depends on JBRulesets |
| JBTerminalStore5_1 | Depends on JBRulesets |
| JBMultiTerminal5_1 | Depends on JBTerminalStore |
| JB721TiersHook5_1 | Depends on JBRulesets |
| JB721TiersHookStore5_1 | Redeployed for consistency |
| JB721TiersHookDeployer5_1 | Depends on JB721TiersHook |
| JB721TiersHookProjectDeployer5_1 | Depends on JB721TiersHookDeployer |
| JBOmnichainDeployer5_1 | Depends on JB721TiersHookDeployer |

## Which Version to Use?

| Use Case | Version | Why |
|----------|---------|-----|
| **New projects & integrations** | V5.1 | Has approval hook fix |
| **Revnets** | V5.0 | REVDeployer uses V5.0 JBController |

**Do not mix V5.0 and V5.1 contracts** - use one complete set or the other.

---

## V5.1 Contracts (New Projects)

All addresses are deterministic across all networks (Ethereum, Optimism, Arbitrum, Base, Sepolia).

### Core Contracts (V5.1)

| Contract | Address |
|----------|---------|
| **JBController5_1** | `0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1` |
| **JBMultiTerminal5_1** | `0x52869db3d61dde1e391967f2ce5039ad0ecd371c` |
| **JBRulesets5_1** | `0xd4257005ca8d27bbe11f356453b0e4692414b056` |
| **JBTerminalStore5_1** | `0x5cdfcf7f5f25da0dcb0eccd027e5feebada1d964` |

### 721 Hook Contracts (V5.1)

| Contract | Address |
|----------|---------|
| **JB721TiersHookDeployer5_1** | `0x792bdd4dd1e52fcf8fb3e80278a2b4e4396d2732` |
| **JB721TiersHookProjectDeployer5_1** | `0xeb15c1df0f5ae36f525f5f9a03f5c5190ac9a7f8` |
| **JB721TiersHookStore5_1** | `0x749ac9c5ef5ef41f402c70a5bc460c5a1d8eb25b` |

### Omnichain Deployer (V5.1)

| Contract | Address |
|----------|---------|
| **JBOmnichainDeployer5_1** | `0x587bf86677ec0d1b766d9ba0d7ac2a51c6c2fc71` |

---

## Shared Contracts (Same for V5.0 & V5.1)

| Contract | Address |
|----------|---------|
| JBProjects | `0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4` |
| JBDirectory | `0x0061e516886a0540f63157f112c0588ee0651dcf` |
| JBTokens | `0x4d0edd347fb1fa21589c1e109b3474924be87636` |
| JBSplits | `0x7160a322fea44945a6ef9adfd65c322258df3c5e` |
| JBPermissions | `0x04fd6913d6c32d8c216e153a43c04b1857a7793d` |
| JBPrices | `0x9b90e507cf6b7eb681a506b111f6f50245e614c4` |
| JBFundAccessLimits | `0x3a46b21720c8b70184b0434a2293b2fdcc497ce7` |
| JBFeelessAddresses | `0xfc702a0190f3edbc369208dfe77bf273add91d53` |
| JBERC20 | `0xaeac450c8522e40244bdfb8120ee398207be5d31` |

---

## V5.0 Contracts (Revnets Only)

**IMPORTANT: Only use these for Revnets. New projects should use V5.1.**

### Core Contracts (V5.0)

| Contract | Address |
|----------|---------|
| **JBController** | `0x27da30646502e2f642be5281322ae8c394f7668a` |
| **JBMultiTerminal** | `0x2db6d704058e552defe415753465df8df0361846` |
| **JBRulesets** | `0x6292281d69c3593fcf6ea074e5797341476ab428` |
| **JBTerminalStore** | `0xfe33b439ec53748c87dcedacb83f05add5014744` |

### 721 Hook Contracts (V5.0)

| Contract | Address |
|----------|---------|
| **JB721TiersHookDeployer** | `0xef60878d00378ac5f93d209f4616450ee8d41ca7` |
| **JB721TiersHookProjectDeployer** | `0x048626e715a194fc38dd9be12f516b54b10e725a` |
| **JB721TiersHookStore** | `0x2bc696b0af74042b30b2687ab5817cc824eba8ee` |

### Omnichain Deployer (V5.0)

| Contract | Address |
|----------|---------|
| **JBOmnichainDeployer** | `0x8f5ded85c40b50d223269c1f922a056e72101590` |

---

## Revnet & Croptop Contracts

These use V5.0 core contracts internally.

| Contract | Address |
|----------|---------|
| REVDeployer | `0x2ca27bde7e7d33e353b44c27acfcf6c78dde251d` |
| REVLoans | `0x1880d832aa283d05b8eab68877717e25fbd550bb` |
| CTPublisher | `0x03ef9ea1467df70d4b1e1d619aa9a2a2f820ee24` |
| CTDeployer | `0xc3c26682ef39a4a5f4a1dc2459a6fbcba4e5d8ea` |
| CTProjectOwner | `0x127fa6d4d0a4e791c6c4adaa4c9ad97127690883` |

---

## Buyback & Swap Contracts

| Contract | Network | Address |
|----------|---------|---------|
| JBBuybackHook | Ethereum | `0xd342490ec41d5982c23951253a74a1c940fe0f9b` |
| JBBuybackHook | Optimism | `0x318f8aa6a95cb83419985c0d797c762f5a7824f3` |
| JBBuybackHook | Arbitrum | `0x4ac3e20edd1d398def0dfb44d3adb9fc244f0320` |
| JBBuybackHook | Base | `0xb6133a222315f8e9d25e7c77bac5ddeb3451d088` |
| JBBuybackHookRegistry | All | `0x9e1e0fb70bc4661f2cc2d5eddd87a9d582a12b1a` |
| JBSwapTerminal | Ethereum | `0x259385b97dfbd5576bd717dc7b25967ec8b145dd` |
| JBSwapTerminal | Optimism | `0x73d04584bde126242c36c2c7b219cbdec7aad774` |
| JBSwapTerminal | Arbitrum | `0x483c9b12c5bd2da73133aae30642ce0008c752ad` |
| JBSwapTerminal | Base | `0x4fd73d8b285e82471f08a4ef9861d6248b832edd` |
| JBSwapTerminalRegistry | All | `0x60b4f5595ee509c4c22921c7b7999f1616e6a4f6` |

---

## Sucker Registry

| Contract | Address |
|----------|---------|
| JBSuckerRegistry | `0x07c8c5bf08f0361883728a8a5f8824ba5724ece3` |

---

## Quick Copy Reference (V5.1 Mainnet)

```solidity
// V5.1 Core Contracts (use for new projects)
address constant JB_CONTROLLER = 0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1;
address constant JB_MULTI_TERMINAL = 0x52869db3d61dde1e391967f2ce5039ad0ecd371c;
address constant JB_RULESETS = 0xd4257005ca8d27bbe11f356453b0e4692414b056;
address constant JB_TERMINAL_STORE = 0x5cdfcf7f5f25da0dcb0eccd027e5feebada1d964;

// Shared Contracts
address constant JB_PROJECTS = 0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4;
address constant JB_DIRECTORY = 0x0061e516886a0540f63157f112c0588ee0651dcf;
address constant JB_TOKENS = 0x4d0edd347fb1fa21589c1e109b3474924be87636;
address constant JB_SPLITS = 0x7160a322fea44945a6ef9adfd65c322258df3c5e;
address constant JB_PERMISSIONS = 0x04fd6913d6c32d8c216e153a43c04b1857a7793d;

// 721 Hook V5.1
address constant JB_721_HOOK_DEPLOYER = 0x792bdd4dd1e52fcf8fb3e80278a2b4e4396d2732;
address constant JB_721_HOOK_PROJECT_DEPLOYER = 0xeb15c1df0f5ae36f525f5f9a03f5c5190ac9a7f8;
```

---

## Quick Copy Reference (V5.0 - Revnets Only)

```solidity
// V5.0 Core Contracts (ONLY for revnets)
address constant JB_CONTROLLER_V5 = 0x27da30646502e2f642be5281322ae8c394f7668a;
address constant JB_MULTI_TERMINAL_V5 = 0x2db6d704058e552defe415753465df8df0361846;
address constant JB_RULESETS_V5 = 0x6292281d69c3593fcf6ea074e5797341476ab428;
address constant JB_TERMINAL_STORE_V5 = 0xfe33b439ec53748c87dcedacb83f05add5014744;

// Revnet Deployer
address constant REV_DEPLOYER = 0x2ca27bde7e7d33e353b44c27acfcf6c78dde251d;
```

---

## Version History

| Version | Status | Notes |
|---------|--------|-------|
| V5.1 | **Current** | Use for new projects. Fixes approval hook bug |
| V5.0 | Revnets only | Use ONLY for revnets (don't use approval hooks) |
| V4 | Deprecated | Do not use for new projects |

---

## Official Sources

- **V5 Docs**: https://docs.juicebox.money/dev/v5/addresses/
- **Changelog**: https://docs.juicebox.money/dev/v5/change-log/
- **nana-core-v5**: https://github.com/Bananapus/nana-core-v5
- **revnet-core-v5**: https://github.com/rev-net/revnet-core-v5
