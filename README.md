# Juicebox V5 Skills

A comprehensive Claude Code skills library for Juicebox V5 protocol development.

## Installation

Install as a Claude Code plugin:

```bash
claude /plugin install https://github.com/YOUR_USERNAME/juicebox-skills
```

Or clone locally:

```bash
git clone https://github.com/YOUR_USERNAME/juicebox-skills
claude /plugin install ./juicebox-skills
```

## Available Skills

### Hook Development

| Skill | Command | Description |
|-------|---------|-------------|
| Pay Hook | `/jb-pay-hook` | Generate custom pay hooks from natural language specs |
| Cash Out Hook | `/jb-cash-out-hook` | Generate custom cash out hooks |
| Split Hook | `/jb-split-hook` | Generate custom split hooks for payout routing |

### Project Management

| Skill | Command | Description |
|-------|---------|-------------|
| Project | `/jb-project` | Create and configure Juicebox projects |
| Ruleset | `/jb-ruleset` | Design and queue ruleset configurations |

### Operations

| Skill | Command | Description |
|-------|---------|-------------|
| Query | `/jb-query` | Query project state from the blockchain |
| Decode | `/jb-decode` | Decode Juicebox transaction calldata |
| Docs | `/jb-docs` | Query Juicebox documentation via MCP |

## Usage Examples

### Generate a Pay Hook

```
/jb-pay-hook

Create a pay hook that mints a custom ERC20 token proportional to payments
```

### Query Project State

```
/jb-query

What's the current ruleset for project 123 on mainnet?
```

### Create a New Project

```
/jb-project

Create a project that mints 1000 tokens per ETH with 10% reserved to a team multisig
```

## Off-the-Shelf Solutions

Before generating custom code, the skills evaluate if existing solutions fit:

| Need | Solution |
|------|----------|
| Token buybacks via Uniswap | Deploy **nana-buyback-hook-v5** |
| Tiered NFT rewards | Deploy **nana-721-hook-v5** |
| Autonomous tokenized treasury | Deploy a **Revnet** |

## V5 Terminology

This library uses correct Juicebox V5 terminology:

| V5 Term | Not |
|---------|-----|
| Ruleset | Funding cycle |
| Cash out | Redemption |
| Weight | Issuance rate |
| Reserved rate | Reserved percentage |
| Cash out tax rate | Redemption rate |

## Reference Implementations

Skills reference these canonical V5 examples:

- [nana-buyback-hook-v5](https://github.com/Bananapus/nana-buyback-hook-v5) - Data hook + pay hook for Uniswap buybacks
- [nana-721-hook-v5](https://github.com/Bananapus/nana-721-hook-v5) - Full hook suite for tiered NFTs
- [revnet-core-v5](https://github.com/rev-net/revnet-core-v5) - Contract-as-owner pattern for autonomous projects

## Project Structure

```
juicebox-skills/
├── .claude-plugin/
│   └── config.json
├── skills/
│   ├── jb-pay-hook/
│   ├── jb-cash-out-hook/
│   ├── jb-split-hook/
│   ├── jb-project/
│   ├── jb-ruleset/
│   ├── jb-query/
│   ├── jb-decode/
│   └── jb-docs/
├── references/
│   ├── v5-interfaces.md
│   ├── v5-structs.md
│   └── v5-addresses.md
├── README.md
└── LICENSE
```

## Resources

- [Juicebox Docs](https://docs.juicebox.money)
- [nana-core-v5](https://github.com/Bananapus/nana-core-v5)
- [Juicebox GitHub](https://github.com/jbx-protocol)

## License

MIT License - see [LICENSE](LICENSE)
