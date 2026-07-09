# Juicebox V6 Skills — Authoring Conventions

Skills in this folder teach AI agents (Claude Console skills + Claude Code) how to work with Juicebox V6. They are consumed by machines: optimize for parseability and lookup speed, not narrative.

## Hard rules

1. **V6 only.** Never mention V5, V5.1, V4, or version detection. V6 is the only Juicebox. No "migration from" framing, no "unlike previous versions".
2. **Ground truth is code.** Every contract fact (function signature, struct field order, permission ID, constant, fee value, event shape, address) must be verified against the `nana-*-v6` / `revnet-core-v6` / `croptop-core-v6` / `bendystraw-v6` repos or `shared/chain-config.json`. Never carry a fact over from a V5 skill without re-verifying it in V6 source.
3. **Addresses come from `shared/chain-config.json`** (generated from `deploy-all-v6/deployments`). Do not hand-type addresses from anywhere else. Core contracts share one address across all chains — say so once instead of repeating per-chain tables.
4. **No hedging, no marketing.** State facts. If something is unknown, omit it.

## Format

- YAML frontmatter: `name`, `description` (trigger conditions: "Use when: (1)…, (2)…"), `version: 6.0.0`.
- Tables over prose for enumerable facts (addresses, IDs, fields, enums).
- Fenced code blocks for every calldata/encoding/query example, tagged with language.
- Struct/field tables MUST show fields in ABI order with types.
- One `## Common mistakes` section at the end if the domain has known traps.
- Target the V5 skill's scope but cut anything V6 made obsolete (e.g. version detection, dual controller sets).

## Shared resources

- `shared/chain-config.json` — per-chain contract addresses (8 chains: ETH/OP/Base/Arb mainnet + sepolias).
- `shared/abis/*.json` — verified ABIs from deployment artifacts.
- `shared/styles.css`, `shared/wallet-utils.js` — UI skill helpers.
- Reference a shared file with a relative `shared/...` path; `build-skills.sh` bundles it into the zip.
