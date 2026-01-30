# Juicebox V5 Skills

A comprehensive Claude Code skills library for Juicebox V5 protocol development.

## Quick Start

### Installation

```bash
# Add the Juicebox marketplace
/plugin marketplace add mejango/juicebox-skills

# Install the plugin
/plugin install juicebox-v5@juicebox
```

### Common Workflows

| I want to... | Use this skill |
|--------------|----------------|
| Create a new project | `/jb-project` |
| Build a custom pay hook | `/jb-pay-hook` |
| Query project state | `/jb-query` |
| Decode a transaction | `/jb-decode` |
| Build a project explorer UI | `/jb-explorer-ui` |
| Deploy a custom hook | `/jb-hook-deploy-ui` |
| Calculate cash out amounts | `/jb-cash-out-curve` |
| Handle multi-currency payments | `/jb-multi-currency` |
| Work with revnet loans | `/jb-revloans` |
| Bridge tokens cross-chain | `/jb-suckers` |

---

## Skills by Category

### 🔧 Hook Development

Generate custom hooks from natural language specifications.

| Skill | Command | Description |
|-------|---------|-------------|
| Pay Hook | `/jb-pay-hook` | Generate pay hooks for custom payment processing |
| Cash Out Hook | `/jb-cash-out-hook` | Generate cash out hooks for redemption logic |
| Split Hook | `/jb-split-hook` | Generate split hooks for payout routing |

### 📋 Project Management

Create and configure Juicebox projects.

| Skill | Command | Description |
|-------|---------|-------------|
| Project | `/jb-project` | Create projects with rulesets and terminals |
| Ruleset | `/jb-ruleset` | Design and queue ruleset configurations |

### 🔍 Operations & Querying

Read data and decode transactions.

| Skill | Command | Description |
|-------|---------|-------------|
| Query | `/jb-query` | Query project state from the blockchain |
| Decode | `/jb-decode` | Decode Juicebox transaction calldata |
| Docs | `/jb-docs` | Query Juicebox documentation via MCP |
| Fund Access Limits | `/jb-fund-access-limits` | Query payout limits and surplus allowances |
| Loan Queries | `/jb-loan-queries` | Query REVLoans data via Bendystraw |

### 📚 Reference

Deep protocol knowledge and patterns.

| Skill | Command | Description |
|-------|---------|-------------|
| V5 API | `/jb-v5-api` | Function signatures and parameters |
| V5 Implementation | `/jb-v5-impl` | Internal mechanics and edge cases |
| V5 Currency Types | `/jb-v5-currency-types` | Real-world vs token-derived currencies |
| V5/V5.1 Contracts | `/jb-v5-v51-contracts` | Contract version separation rules |
| Patterns | `/jb-patterns` | Common integration patterns |
| Simplify | `/jb-simplify` | Simplify complex JB concepts |

### 🌐 Multi-Chain / Omnichain

Cross-chain deployment and indexing.

| Skill | Command | Description |
|-------|---------|-------------|
| Relayr | `/jb-relayr` | Multi-chain transaction relay API |
| Bendystraw | `/jb-bendystraw` | GraphQL indexer for JB events |
| Omnichain UI | `/jb-omnichain-ui` | Multi-chain deployment interfaces |
| Suckers | `/jb-suckers` | Cross-chain token bridging |
| Omnichain Payout Limits | `/jb-omnichain-payout-limits` | Per-chain vs aggregate limit constraints |

### 💰 Protocol Economics

Fee structures, bonding curves, and economic calculations.

| Skill | Command | Description |
|-------|---------|-------------|
| Cash Out Curve | `/jb-cash-out-curve` | Bonding curve redemption calculations |
| Protocol Fees | `/jb-protocol-fees` | NANA, Revnet, and loan fee structures |
| JBX Fee Flows | `/jbx-fee-flows` | How fees generate value for JBX holders |

### 💱 Multi-Currency & Terminals

Currency handling and terminal interactions.

| Skill | Command | Description |
|-------|---------|-------------|
| Multi-Currency | `/jb-multi-currency` | ETH vs USDC accounting and currency codes |
| Terminal Selection | `/jb-terminal-selection` | Dynamic terminal selection for payments |
| Terminal Wrapper | `/jb-terminal-wrapper` | Extend terminal functionality |
| Permit2 Metadata | `/jb-permit2-metadata` | Gasless ERC20 payments and metadata encoding |

### 🔄 Revnets

Autonomous treasury mechanics and tooling.

| Skill | Command | Description |
|-------|---------|-------------|
| REVLoans | `/jb-revloans` | Loan borrow/repay/refinance mechanics |
| Revnet Economics | `/revnet-economics` | Academic findings and economic thresholds |
| Revnet Modeler | `/revnet-modeler` | Simulation and parameter planning |

### 🖥️ UI Templates

Generate interactive web interfaces.

| Skill | Command | Description |
|-------|---------|-------------|
| Explorer UI | `/jb-explorer-ui` | Etherscan-like contract explorer |
| Event Explorer UI | `/jb-event-explorer-ui` | Browse and filter contract events |
| Ruleset Timeline UI | `/jb-ruleset-timeline-ui` | Visual ruleset history |
| NFT Gallery UI | `/jb-nft-gallery-ui` | Browse 721 hook NFT collections |
| Hook Deploy UI | `/jb-hook-deploy-ui` | Compile and deploy custom hooks |
| Deploy UI | `/jb-deploy-ui` | Project deployment interfaces |
| Interact UI | `/jb-interact-ui` | Pay, cash out, and manage projects |

---

## Shared Components

UI skills share common components to reduce duplication:

```
shared/
├── chain-config.json    # Chain RPCs, contract addresses
├── styles.css           # Dark theme CSS
├── wallet-utils.js      # Wallet connection utilities
└── abis/                # Contract ABIs
```

See [shared/README.md](shared/README.md) for usage.

---

## Hook Catalog

Pre-built hook patterns ready to deploy:

```
hook-catalog/
├── src/
│   ├── pay-hooks/
│   │   ├── PaymentCapHook.sol      # Max payment per transaction
│   │   ├── FundraisingCapHook.sol  # Total fundraising cap
│   │   └── AllowlistPayHook.sol    # Allowlisted payers only
│   ├── cash-out-hooks/
│   │   └── VestingCashOutHook.sol  # Time-based vesting
│   ├── split-hooks/
│   │   ├── VestingSplitHook.sol    # Route to vesting contract
│   │   └── MultiRecipientSplitHook.sol # Split among recipients
│   └── data-hooks/
│       └── DynamicWeightHook.sol   # Time-based pricing
├── test/                            # Foundry tests
└── script/                          # Deployment scripts
```

See [hook-catalog/README.md](hook-catalog/README.md) for details.

---

## Off-the-Shelf Solutions

Before generating custom code, consider existing solutions:

| Need | Recommended Solution |
|------|---------------------|
| Token buybacks via Uniswap | [nana-buyback-hook-v5](https://github.com/Bananapus/nana-buyback-hook-v5) |
| Tiered NFT rewards | [nana-721-hook-v5](https://github.com/Bananapus/nana-721-hook-v5) |
| Autonomous treasury | [revnet-core-v5](https://github.com/rev-net/revnet-core-v5) |
| Public NFT posting | [croptop-core-v5](https://github.com/mejango/croptop-core-v5) |

---

## V5.1 Update (Dec 2025)

**Only JBRulesets has a code change** (one-line approval hook fix). Other contracts were redeployed due to dependencies:
- JBController, JBTerminalStore → depend on JBRulesets
- JBMultiTerminal → depends on JBTerminalStore
- JB721TiersHook → depends on JBRulesets
- JB721TiersHookDeployer → depends on JB721TiersHook
- JBOmnichainDeployer → depends on JB721TiersHookDeployer

| Use Case | Which Contracts |
|----------|-----------------|
| New projects & integrations | Use **V5.1** contracts (default in chain-config.json) |
| Revnets | Use **V5.0** contracts (REVDeployer uses V5.0 JBController) |

**Do not mix V5.0 and V5.1 contracts** - use one complete set or the other.

The shared `chain-config.json` includes both:
- `contracts` → V5.1 addresses (default for new projects)
- `contractsV5` → V5.0 addresses (for revnets only)

---

## V5 Terminology

| V5 Term | Not |
|---------|-----|
| Ruleset | Funding cycle |
| Cash out | Redemption |
| Weight | Issuance rate |
| Reserved rate | Reserved percentage |
| Cash out tax rate | Redemption rate |

---

## Project Structure

```
juicebox-skills/
├── plugins/
│   └── juicebox-v5/
│       ├── skills/
│       │   ├── jb-bendystraw/
│       │   ├── jb-cash-out-curve/
│       │   ├── jb-cash-out-hook/
│       │   ├── jb-decode/
│       │   ├── jb-deploy-ui/
│       │   ├── jb-docs/
│       │   ├── jb-event-explorer-ui/
│       │   ├── jb-explorer-ui/
│       │   ├── jb-fund-access-limits/
│       │   ├── jb-hook-deploy-ui/
│       │   ├── jb-interact-ui/
│       │   ├── jb-loan-queries/
│       │   ├── jb-multi-currency/
│       │   ├── jb-nft-gallery-ui/
│       │   ├── jb-omnichain-payout-limits/
│       │   ├── jb-omnichain-ui/
│       │   ├── jb-patterns/
│       │   ├── jb-pay-hook/
│       │   ├── jb-permit2-metadata/
│       │   ├── jb-project/
│       │   ├── jb-protocol-fees/
│       │   ├── jb-query/
│       │   ├── jb-relayr/
│       │   ├── jb-revloans/
│       │   ├── jb-ruleset/
│       │   ├── jb-ruleset-timeline-ui/
│       │   ├── jb-simplify/
│       │   ├── jb-split-hook/
│       │   ├── jb-suckers/
│       │   ├── jb-terminal-selection/
│       │   ├── jb-terminal-wrapper/
│       │   ├── jb-v5-api/
│       │   ├── jb-v5-currency-types/
│       │   ├── jb-v5-impl/
│       │   ├── jb-v5-v51-contracts/
│       │   ├── jbx-fee-flows/
│       │   ├── revnet-economics/
│       │   └── revnet-modeler/
│       └── references/
│           ├── v5-interfaces.md
│           ├── v5-structs.md
│           └── v5-addresses.md
├── shared/                 # Shared UI components
├── hook-catalog/           # Pre-built hook patterns
└── README.md
```

---

## Resources

- [Juicebox Documentation](https://docs.juicebox.money)
- [nana-core-v5](https://github.com/Bananapus/nana-core-v5)
- [Juicebox GitHub](https://github.com/jbx-protocol)

## License

MIT License
