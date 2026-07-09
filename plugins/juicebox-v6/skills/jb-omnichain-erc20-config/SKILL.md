---
name: jb-omnichain-erc20-config
description: |
  Configure omnichain Juicebox V6 deployments with ERC-20 tokens (e.g. USDC) whose addresses
  differ per chain. Use when: (1) a USDC-based project sends the same token address to every
  chain, (2) sucker token mappings use the native-token sentinel instead of the per-chain ERC-20
  address, (3) a deploy reverts at JBSuckerRegistry.deploySuckersFor / mapTokens with
  JBSuckerRegistry_TokenMappingNotAllowed, (4) terminal accounting contexts don't reflect
  per-chain token addresses, (5) choosing CCIP vs native-bridge suckers for USDC. Covers
  JBOmnichainDeployer configs, JBTokenMapping, the registry mapping allowlist, and per-chain
  terminal configuration overrides.
version: 6.0.0
---

# Omnichain ERC-20 Token Configuration

An omnichain project that accepts an ERC-20 (USDC is the common case) needs THREE things to differ per chain, because the token contract lives at a different address on each chain:

1. **Terminal accounting contexts** — each chain's `JBTerminalConfig` must list that chain's token address.
2. **Sucker token mappings** — each chain's `JBTokenMapping` must pair its local address with the peer chain's address.
3. **Currency IDs** — the accounting context `currency` is derived from the token address, so it differs per chain too.

## Canonical USDC addresses

These are the canonical (Circle-native) USDC addresses the protocol deployment allowlists for sucker bridging:

| Chain | USDC |
|-------|------|
| Ethereum (1) | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| Optimism (10) | `0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85` |
| Base (8453) | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` |
| Arbitrum (42161) | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` |
| Sepolia (11155111) | `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238` |
| OP Sepolia (11155420) | `0x5fd84259d66Cd46123540766Be93DFE6D43130D7` |
| Base Sepolia (84532) | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` |
| Arb Sepolia (421614) | `0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d` |

## Structs (ABI order)

```solidity
struct JBAccountingContext {
    address token;     // per-chain ERC-20 address, or 0xEeee…EEeE for native
    uint8 decimals;    // 6 for USDC
    uint32 currency;   // uint32(uint160(tokenAddress)) — DIFFERS PER CHAIN for the same asset
}

struct JBTerminalConfig {
    IJBTerminal terminal;                          // JBMultiTerminal (same address on all chains)
    JBAccountingContext[] accountingContextsToAccept;
}

struct JBTokenMapping {
    address localToken;   // this chain's token address
    uint32 minGas;        // >= 200_000 for ERC-20s (MESSENGER_ERC20_MIN_GAS_LIMIT)
    bytes32 remoteToken;  // bytes32(uint256(uint160(peerChainTokenAddress)))
}

struct JBSuckerDeployerConfig {
    IJBSuckerDeployer deployer;   // the lane deployer for this local↔remote pair
    bytes32 peer;                 // bytes32(0) = default same-address deterministic peer
    JBTokenMapping[] mappings;
}

struct JBSuckerDeploymentConfig {
    JBSuckerDeployerConfig[] deployerConfigurations;  // one per peer chain
    bytes32 salt;                                     // same value on every chain, same sender
}
```

There is no `minBridgeAmount` field. Currency by convention is `uint32(uint160(tokenAddress))` — do not reuse one chain's currency number on another chain.

## The registry mapping allowlist

`JBSucker.mapTokens` (called during `deploySuckersFor`) enforces `JBSuckerRegistry.requireTokenMappingAllowed`:

- `remoteToken == bytes32(0)` (disable): always allowed.
- Non-native token → **same address** on the remote chain: allowed without approval.
- Native↔native and **differing-address** mappings (all real USDC pairs): must be pre-allowlisted by the registry owner via `allowTokenMapping(localToken, remoteChainId, remoteToken)`. The protocol deployment allowlists native↔native and the canonical USDC pairs above.

So a revert at `deploySuckersFor` with `JBSuckerRegistry_TokenMappingNotAllowed` means either (a) a wrong/non-canonical token address on one side, or (b) a pair that hasn't been allowlisted. Check `tokenMappingIsAllowed(localToken, remoteChainId, remoteToken)` first.

Other mapping reverts to check: `JBSucker_BelowMinGas` (ERC-20 `minGas < 200_000`) and `JBSucker_InvalidNativeRemoteAddress` (native mapped to a non-native remote).

## Per-chain configuration pattern

Build one launch transaction per chain, overriding terminal configs and mappings per chain:

```typescript
const USDC: Record<number, `0x${string}`> = { 1: '0xA0b8…', 10: '0x0b2C…', 8453: '0x8335…', 42161: '0xaf88…' };
const toBytes32 = (a: string) => `0x${a.slice(2).toLowerCase().padStart(64, '0')}`;
const currencyOf = (a: string) => Number(BigInt(a) & 0xffffffffn);  // uint32(uint160(token))

function terminalConfigsFor(chainId: number) {
  return [{
    terminal: JB_MULTI_TERMINAL,   // same address on every chain
    accountingContextsToAccept: [{
      token: USDC[chainId],
      decimals: 6,
      currency: currencyOf(USDC[chainId]),
    }],
  }];
}

function suckerConfigFor(chainId: number, remoteChainIds: number[]) {
  return {
    deployerConfigurations: remoteChainIds.map((remote) => ({
      deployer: laneDeployerFor(chainId, remote),  // see below
      peer: '0x' + '0'.repeat(64),
      mappings: [{
        localToken: USDC[chainId],
        minGas: 200_000,
        remoteToken: toBytes32(USDC[remote]),
      }],
    })),
    salt: SHARED_SALT,  // identical on every chain; deploy from the same sender everywhere
  };
}
```

Every chain's transaction gets ITS OWN config — never reuse chain A's config (its terminal token, currency, and mappings are wrong everywhere else).

## Choosing the lane deployer — USDC goes over CCIP

Deployer addresses come from `shared/chain-config.json` and are **chain-specific per lane**:

- Ethereum↔L2 native-bridge deployers: `JBOptimismSuckerDeployer`, `JBBaseSuckerDeployer`, `JBArbitrumSuckerDeployer`.
- CCIP lane deployers: `JBCCIPSuckerDeployer__{PEER}` (e.g. on Base: `__ETH`, `__OP`, `__ARB`). Each lane's deployer has the same address on both ends of its pair, but different lanes have different addresses.

**USDC trap**: L2 native bridges deliver the bridged variant (USDC.e), not canonical USDC — the delivered token would not match the mapped remote token. Bridge canonical USDC over CCIP suckers (CCIP lanes transfer canonical USDC). Native ETH between Ethereum and an OP-stack/Arbitrum L2 can use the native-bridge deployers.

## Preview vs launch data separation

If a UI generates a sucker config for one chain to preview, do NOT pass that single-chain config into the launch path — it would be applied verbatim to every chain. Let the launch builder derive each chain's config from the per-chain token table.

## Extracting project IDs after deployment

Project IDs differ per chain. Read them from each chain's receipt (the project-created event's first indexed topic) or query Bendystraw after indexing — see `jb-omnichain-per-chain-projectids`.

## Common mistakes

- **Same token address on every chain.** Each chain's terminal context and mapping must use that chain's address; the wrong address reverts at the mapping allowlist or silently configures an unusable terminal token.
- **Same `currency` value on every chain.** `currency = uint32(uint160(token))` differs per chain for the same asset.
- **`minBridgeAmount` in the mapping.** The field does not exist; `JBTokenMapping` is `{localToken, minGas, remoteToken}`.
- **`remoteToken` as `address`.** It's `bytes32` (left-padded).
- **USDC over a native-bridge sucker.** Delivers USDC.e, not canonical USDC. Use the CCIP lane deployer.
- **Different senders or salts per chain.** `deploySuckersFor` hashes `(sender, salt)` into the CREATE2 salt; mismatches break the same-address peer assumption.
- **Fixing a wrong mapping in place.** Once a token's outbox has entries, the mapping can only be disabled, never remapped — a misconfigured lane requires a new sucker.

## Related skills

- `jb-suckers` — bridging mechanics, mapping rules, registry API
- `jb-omnichain-per-chain-projectids` — per-chain project IDs
- `jb-relayr` — executing the per-chain launch transactions from one payment
