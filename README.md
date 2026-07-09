# Juicebox V6 Skills

A Claude Code / Claude Console skills library for Juicebox V6 protocol development.

Every skill is written against V6 source (`nana-*-v6`, `revnet-core-v6`,
`croptop-core-v6`, `bendystraw-v6`) with addresses generated from
`deploy-all-v6` deployment artifacts. One contract set, one address per contract
on every supported chain (Ethereum, Optimism, Base, Arbitrum + Sepolia testnets).

## Quick Start

### Installation

```bash
# Add the Juicebox marketplace
/plugin marketplace add mejango/juicebox-skills

# Install the plugin
/plugin install juicebox-v6@juicebox
```

For Claude Console: upload any zip from `plugins/juicebox-v6/dist/`.

### Common Workflows

| I want to... | Use this skill |
|--------------|----------------|
| Create a new project | `/jb-project` |
| Build a custom pay hook | `/jb-pay-hook` |
| Query project state | `/jb-query` |
| Query indexed data (GraphQL) | `/jb-bendystraw` |
| Decode a transaction | `/jb-decode` |
| Build a project explorer UI | `/jb-explorer-ui` |
| Calculate cash out amounts | `/jb-cash-out-curve` |
| Handle multi-currency payments | `/jb-multi-currency` |
| Work with revnet loans | `/jb-revloans` |
| Bridge tokens cross-chain | `/jb-suckers` |
| Post content via Croptop | `/jb-croptop` |

---

## Skills by Category

### 📚 Core API / Reference

| Skill | Command | Description |
|-------|---------|-------------|
| V6 API | `/jb-v6-api` | Function signatures across core + ecosystem contracts |
| V6 Implementation | `/jb-v6-impl` | Internal mechanics, fee math, packing, edge cases |
| Contracts | `/jb-contracts` | Contract inventory and addresses |
| Currency Types | `/jb-currency-types` | Price-feed IDs vs token-derived accounting currencies |
| Project | `/jb-project` | Create projects with rulesets and terminals |
| Ruleset | `/jb-ruleset` | Design and queue ruleset configurations |
| Multi-Currency | `/jb-multi-currency` | ETH vs USDC accounting and currency codes |
| Query | `/jb-query` | Query project state from the blockchain |
| Decode | `/jb-decode` | Decode Juicebox transaction calldata |
| Patterns | `/jb-patterns` | Common integration patterns |
| Simplify | `/jb-simplify` | Simplify complex JB concepts |
| Docs | `/jb-docs` | Query Juicebox documentation |

### 🔧 Hook Development

| Skill | Command | Description |
|-------|---------|-------------|
| Pay Hook | `/jb-pay-hook` | Generate pay hooks for custom payment processing |
| Cash Out Hook | `/jb-cash-out-hook` | Generate cash out hooks for reclaim logic |
| Split Hook | `/jb-split-hook` | Generate split hooks for payout routing |
| 721 Per-Chain Config | `/jb-721-per-chain-config` | Per-chain NFT tier configuration |
| 721 Tier Content | `/jb-721-tier-content` | Tier metadata, IPFS encoding, resolvers |

### 💰 Terminals, Fees & Economics

| Skill | Command | Description |
|-------|---------|-------------|
| Terminal Selection | `/jb-terminal-selection` | Terminal resolution and the router terminal |
| Terminal Wrapper | `/jb-terminal-wrapper` | Extend terminal functionality |
| Protocol Fees | `/jb-protocol-fees` | Standard 2.5% fee, held fees, feeless addresses |
| Fee Flows | `/jb-fee-flows` | How fees route to the NANA fee project |
| Fund Access Limits | `/jb-fund-access-limits` | Payout limits and surplus allowances |
| Cash Out Curve | `/jb-cash-out-curve` | Bonding curve reclaim calculations |
| Permit2 Metadata | `/jb-permit2-metadata` | Gasless ERC20 payments and metadata encoding |

### 🌐 Multi-Chain / Omnichain

| Skill | Command | Description |
|-------|---------|-------------|
| Suckers | `/jb-suckers` | Cross-chain token bridging |
| Relayr | `/jb-relayr` | Multi-chain transaction relay API |
| Omnichain ERC20 Config | `/jb-omnichain-erc20-config` | Per-chain token addresses in sucker configs |
| Omnichain Payout Limits | `/jb-omnichain-payout-limits` | Per-chain vs aggregate limit constraints |
| Per-Chain Project IDs | `/jb-omnichain-per-chain-projectids` | Resolving a project's IDs across chains |
| Tier Quantity Per Chain | `/jb-omnichain-tier-quantity-per-chain` | NFT supply is per-chain |

### 🔄 Revnets, Loans & Croptop

| Skill | Command | Description |
|-------|---------|-------------|
| Revnet Economics | `/revnet-economics` | Economic thresholds and stage design |
| Revnet Modeler | `/revnet-modeler` | Simulation and parameter planning |
| Revnet Omnichain Default | `/revnet-omnichain-default` | Deploying revnets across chains |
| Reserved Rate Off-Chain Revenue | `/jb-reserved-rate-offchain-revenue` | Splitting off-chain revenue on-chain |
| REVLoans | `/jb-revloans` | Loan borrow/repay/reallocate mechanics |
| Loan Queries | `/jb-loan-queries` | Query REVLoans data via Bendystraw |
| Croptop | `/jb-croptop` | Permissioned posting and minting |

### 📊 Data

| Skill | Command | Description |
|-------|---------|-------------|
| Bendystraw | `/jb-bendystraw` | GraphQL indexer — all queries use `version: 6` |

### 🖥️ UI Templates

| Skill | Command | Description |
|-------|---------|-------------|
| Deploy UI | `/jb-deploy-ui` | Project deployment interfaces |
| Explorer UI | `/jb-explorer-ui` | Etherscan-like contract explorer |
| Event Explorer UI | `/jb-event-explorer-ui` | Browse and filter contract events |
| Ruleset Timeline UI | `/jb-ruleset-timeline-ui` | Visual ruleset history |
| NFT Gallery UI | `/jb-nft-gallery-ui` | Browse 721 hook NFT collections |
| Hook Deploy UI | `/jb-hook-deploy-ui` | Compile and deploy custom hooks |
| Interact UI | `/jb-interact-ui` | Pay, cash out, and manage projects |
| Omnichain UI | `/jb-omnichain-ui` | Multi-chain deployment interfaces |

---

## Shared Components

- `plugins/juicebox-v6/shared/chain-config.json` — canonical per-chain V6 addresses (generated from `deploy-all-v6/deployments`)
- `plugins/juicebox-v6/shared/abis/*.json` — verified ABIs from deployment artifacts
- `plugins/juicebox-v6/shared/wallet-utils.js`, `styles.css` — helpers bundled into UI skills

## Authoring

See `plugins/juicebox-v6/CONVENTIONS.md`. Ground every claim in V6 source; addresses
come only from `chain-config.json`; rebuild Console zips with
`plugins/juicebox-v6/build-skills.sh`.
