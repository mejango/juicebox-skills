# Juicebox V6 Skills

Portable skills for AI agents working with Juicebox V6. The hosted MCP works with any agent or client that supports MCP over Streamable HTTP.

Every skill is written against V6 source (`nana-*-v6`, `revnet-core-v6`,
`croptop-core-v6`, `bendystraw-v6`) with addresses generated from
`deploy-all-v6` deployment artifacts. One contract set, one address per contract
on every supported chain (Ethereum, Optimism, Base, Arbitrum + Sepolia testnets).

## Quick Start

### Use the skills in your agent

Each skill is a directory with a `SKILL.md` entry point using the open
[Agent Skills format](https://agentskills.io/specification). Extract the desired
archive from `plugins/juicebox-v6/dist/` into your agent's skill directory, keeping
the inner skill folder and its bundled files together. Each archive contains the
shared addresses, ABIs, and helpers referenced by that skill.

Agents without native skill discovery can read `SKILL.md` and its referenced
files as task context. Skill names in the tables below identify directories;
invocation syntax and installation locations depend on the agent. The MCP can
also be used independently of the skills.

**Optional Claude packaging:** Claude Code users can install the existing plugin
with `/plugin marketplace add mejango/juicebox-skills` followed by
`/plugin install juicebox-v6@juicebox`. Claude Console users can upload a ZIP.
These are client-specific packaging options for the same skill content.

### V6 identity and hosted MCP

These skills operate on V6 only. Keep `{ version: 6, chainId, projectId }` together; reject explicit unsupported versions and never use a name or ID alone as a transaction target. The hosted MCP at `https://juicebox.center/mcp` provides project resolution, live reads, unsigned plans, and reviewed project metadata publishing. Wallet signatures remain external.

### Connect the hosted MCP

The skills provide instructions and examples; the MCP provides callable V6 tools.
Add a remote MCP server in your agent's settings:

| Setting | Value |
|---------|-------|
| Suggested server name | `juicebox` |
| URL | **https://juicebox.center/mcp** |
| Transport | **Streamable HTTP** |

Any agent with this MCP transport can use the same endpoint and tool schemas.
Custom agents can connect through a compatible MCP client or adapter. Installing
skill files alone does not establish an MCP connection. No private Bendystraw or
pinning-provider key belongs in the client configuration.

#### Client-specific examples

These examples configure the same endpoint; each client has its own configuration
format. They are examples, not an exhaustive compatibility list.

**Codex CLI** ([setup documentation](https://developers.openai.com/codex/mcp)):

```bash
codex mcp add juicebox --url https://juicebox.center/mcp
```

**Claude Code**, local scope for the current project ([setup documentation](https://code.claude.com/docs/en/mcp)):

```bash
claude mcp add --transport http juicebox https://juicebox.center/mcp
```

**Cursor**, `.cursor/mcp.json` ([setup documentation](https://cursor.com/help/customization/mcp)):

```json
{
  "mcpServers": {
    "juicebox": { "url": "https://juicebox.center/mcp" }
  }
}
```

**VS Code**, `.vscode/mcp.json` ([setup documentation](https://code.visualstudio.com/docs/agent-customization/mcp-servers)):

```json
{
  "servers": {
    "juicebox": { "type": "http", "url": "https://juicebox.center/mcp" }
  }
}
```

For another agent, enter the URL and Streamable HTTP transport using its own MCP
settings rather than assuming one of these configuration formats applies.

#### Discover workflows

Once connected, start with `jb_list_capabilities` and the client's tool discovery.
Use the returned tool names and input schemas; clients may prefix server tool names.

| Work | MCP starting points |
|------|---------------------|
| Resolve and inspect a V6 project | `jb_resolve_project`, `jb_search_projects`, `jb_get_project` |
| Inspect buyback/router, 721, or revnet state | `jb_get_routing`, `jb_get_721_shop`, `jb_get_revnet` |
| Review a prepared transaction | `jb_inspect_plan`, `jb_simulate_plan`, `jb_verify_plan` |
| Prepare and publish project metadata | `jb_prepare_project_metadata`, then authorized `jb_pin_project_metadata` |
| Build against the SDK and webclients | `jb_plan_integration`, `jb_list_webclient_references`, `jb_get_webclient_reference` |
| Investigate V6 source and skills | `jb_search_reference`, `jb_get_reference` |

Read the MCP's [user journeys](https://github.com/mejango/jbcenter/blob/main/mcp/docs/USER_JOURNEYS.md)
for complete workflows and coverage. Transaction plans stay unsigned until an
external wallet executes them. Metadata pinning is a separate public upload that
requires authorization for the exact document. If the MCP is unavailable, continue
with the applicable V6 SDK/source workflow; do not claim a tool ran or substitute
another protocol version. An unconfigured network remains unavailable.

### Common Workflows

| I want to... | Use this skill |
|--------------|----------------|
| Find the correct V6 project from a name, URL, or ID | `jb-project-identity` |
| Prepare and pin project metadata JSON to IPFS | `jb-project-metadata` |
| Create a new project | `jb-project` |
| Build a custom pay hook | `jb-pay-hook` |
| Query project state | `jb-query` |
| Query indexed data (GraphQL) | `jb-bendystraw` |
| Decode a transaction | `jb-decode` |
| Build a project explorer UI | `jb-explorer-ui` |
| Calculate cash out amounts | `jb-cash-out-curve` |
| Handle multi-currency payments | `jb-multi-currency` |
| Work with revnet loans | `jb-revloans` |
| Bridge tokens cross-chain | `jb-suckers` |
| Post content via Croptop | `jb-croptop` |

---

## Skills by Category

### 📚 Core API / Reference

| Skill | Identifier | Description |
|-------|---------|-------------|
| V6 API | `jb-v6-api` | Function signatures across core + ecosystem contracts |
| V6 Implementation | `jb-v6-impl` | Internal mechanics, fee math, packing, edge cases |
| Contracts | `jb-contracts` | Contract inventory and addresses |
| Currency Types | `jb-currency-types` | Price-feed IDs vs token-derived accounting currencies |
| Project Identity | `jb-project-identity` | Resolve and verify V6 names, URLs, chain IDs, and project IDs |
| Project Metadata | `jb-project-metadata` | Review and pin metadata JSON; obtain the real project URI |
| Project | `jb-project` | Create projects with rulesets and terminals |
| Ruleset | `jb-ruleset` | Design and queue ruleset configurations |
| Multi-Currency | `jb-multi-currency` | ETH vs USDC accounting and currency codes |
| Query | `jb-query` | Query project state from the blockchain |
| Decode | `jb-decode` | Decode Juicebox transaction calldata |
| Patterns | `jb-patterns` | Common integration patterns |
| Simplify | `jb-simplify` | Simplify complex JB concepts |
| Docs | `jb-docs` | Query Juicebox documentation |

### 🔧 Hook Development

| Skill | Identifier | Description |
|-------|---------|-------------|
| Pay Hook | `jb-pay-hook` | Generate pay hooks for custom payment processing |
| Cash Out Hook | `jb-cash-out-hook` | Generate cash out hooks for reclaim logic |
| Split Hook | `jb-split-hook` | Generate split hooks for payout routing |
| 721 Per-Chain Config | `jb-721-per-chain-config` | Per-chain NFT tier configuration |
| 721 Tier Content | `jb-721-tier-content` | Tier metadata, IPFS encoding, resolvers |

### 💰 Terminals, Fees & Economics

| Skill | Identifier | Description |
|-------|---------|-------------|
| Terminal Selection | `jb-terminal-selection` | Terminal resolution and the router terminal |
| Terminal Wrapper | `jb-terminal-wrapper` | Extend terminal functionality |
| Protocol Fees | `jb-protocol-fees` | Standard 2.5% fee, held fees, feeless addresses |
| Fee Flows | `jb-fee-flows` | How fees route to the NANA fee project |
| Fund Access Limits | `jb-fund-access-limits` | Payout limits and surplus allowances |
| Cash Out Curve | `jb-cash-out-curve` | Bonding curve reclaim calculations |
| Permit2 Metadata | `jb-permit2-metadata` | Gasless ERC20 payments and metadata encoding |

### 🌐 Multi-Chain / Omnichain

| Skill | Identifier | Description |
|-------|---------|-------------|
| Suckers | `jb-suckers` | Cross-chain token bridging |
| Relayr | `jb-relayr` | Multi-chain transaction relay API |
| Omnichain ERC20 Config | `jb-omnichain-erc20-config` | Per-chain token addresses in sucker configs |
| Omnichain Payout Limits | `jb-omnichain-payout-limits` | Per-chain vs aggregate limit constraints |
| Per-Chain Project IDs | `jb-omnichain-per-chain-projectids` | Resolving a project's IDs across chains |
| Tier Quantity Per Chain | `jb-omnichain-tier-quantity-per-chain` | NFT supply is per-chain |

### 🔄 Revnets, Loans & Croptop

| Skill | Identifier | Description |
|-------|---------|-------------|
| Revnet Economics | `revnet-economics` | Economic thresholds and stage design |
| Revnet Modeler | `revnet-modeler` | Simulation and parameter planning |
| Revnet Omnichain Default | `revnet-omnichain-default` | Deploying revnets across chains |
| Reserved Rate Off-Chain Revenue | `jb-reserved-rate-offchain-revenue` | Splitting off-chain revenue on-chain |
| REVLoans | `jb-revloans` | Loan borrow/repay/reallocate mechanics |
| Loan Queries | `jb-loan-queries` | Query REVLoans data via Bendystraw |
| Croptop | `jb-croptop` | Permissioned posting and minting |

### 📊 Data

| Skill | Identifier | Description |
|-------|---------|-------------|
| Bendystraw | `jb-bendystraw` | GraphQL indexer — all queries use `version: 6` |

### 🖥️ UI Templates

| Skill | Identifier | Description |
|-------|---------|-------------|
| Deploy UI | `jb-deploy-ui` | Project deployment interfaces |
| Explorer UI | `jb-explorer-ui` | Etherscan-like contract explorer |
| Event Explorer UI | `jb-event-explorer-ui` | Browse and filter contract events |
| Ruleset Timeline UI | `jb-ruleset-timeline-ui` | Visual ruleset history |
| NFT Gallery UI | `jb-nft-gallery-ui` | Browse 721 hook NFT collections |
| Hook Deploy UI | `jb-hook-deploy-ui` | Compile and deploy custom hooks |
| Interact UI | `jb-interact-ui` | Pay, cash out, and manage projects |
| Omnichain UI | `jb-omnichain-ui` | Multi-chain deployment interfaces |

---

## Shared Components

- `plugins/juicebox-v6/shared/chain-config.json` — canonical per-chain V6 addresses (generated from `deploy-all-v6/deployments`)
- `plugins/juicebox-v6/shared/abis/*.json` — verified ABIs from deployment artifacts
- `plugins/juicebox-v6/shared/wallet-utils.js`, `styles.css` — helpers bundled into UI skills

## Authoring

See `plugins/juicebox-v6/CONVENTIONS.md`. Ground every claim in V6 source; addresses
come only from `chain-config.json`; rebuild portable skill archives with
`plugins/juicebox-v6/build-skills.sh`.
