# Juicebox V6 Skills — Authoring Conventions

Skills in this folder teach AI agents how to work with Juicebox V6. Keep the instructions portable across agents; Claude plugin metadata is an optional distribution wrapper. Optimize for parseability and lookup speed.

## Hard rules

1. **V6 only.** Every project identity is `{ version: 6, chainId, projectId }`. Use explicit V6 SDK entry points and address tables; pass `6` to versioned helpers and filter indexed queries by `6`. Reject explicitly unsupported versions instead of rewriting their IDs. Do not offer version discovery, migration, or fallback to another deployment. See `skills/jb-project-identity/SKILL.md` for name and URL resolution.
2. **Ground truth is code.** Every contract fact (function signature, struct field order, permission ID, constant, fee value, event shape, address) must be verified against the `nana-*-v6` / `revnet-core-v6` / `croptop-core-v6` / `bendystraw-v6` repos or `shared/chain-config.json`. Never carry a fact over from a V5 skill without re-verifying it in V6 source.
3. **Addresses come from `shared/chain-config.json`** (generated from `deploy-all-v6/deployments`). Do not hand-type addresses from anywhere else. Core contracts share one address across all chains — say so once instead of repeating per-chain tables.
4. **No hedging, no marketing.** State facts. If something is unknown, omit it.
5. **Generated transaction UIs fail closed.** Pin `viem` to an exact version (`https://esm.sh/viem@2.55.19`). Quote from the protocol's own views (`previewPayFor`, `previewCashOutFrom`, `feeFreeSurplusOf`, limit reads) and derive a nonzero `min*` floor from that quote (pay 99%, cash-out net of fee; see `jb-tx-safety`); then `publicClient.simulateContract` the exact call immediately before the wallet prompt. If the quote or the simulation fails, disable the action instead of submitting with a zero floor. A quote that returns 0 is a real zero; a quote that reverts is unavailable. Require `receipt.status === 'success'` (`waitForSuccess` in `shared/wallet-utils.js`) plus the operation's own evidence (event, new address, state change) before reporting success. Load addresses only from `shared/chain-config.json`; never fall back to inline addresses.

## Format

- Follow the open [Agent Skills format](https://agentskills.io/specification): `name`, `description` (trigger conditions: "Use when: (1)…, (2)…"), and optional string metadata such as `metadata.version: "6.0.0"`. Put version metadata inside `metadata`, not in a custom top-level field.
- Refer to another skill by name. Invocation syntax and discovery paths belong in client-specific setup examples. Lead MCP instructions with the shared URL and Streamable HTTP transport, then label any client-specific command or configuration.
- Tables over prose for enumerable facts (addresses, IDs, fields, enums).
- Fenced code blocks for every calldata/encoding/query example, tagged with language.
- Struct/field tables MUST show fields in ABI order with types.
- One `## Common mistakes` section at the end if the domain has known traps.
- Keep each skill scoped to its V6 capability; do not carry forward unsupported controller sets or version detection.

## Shared resources

- `shared/chain-config.json` — per-chain contract addresses (8 chains: ETH/OP/Base/Arb mainnet + sepolias).
- `shared/abis/*.json` — verified ABIs from deployment artifacts.
- `shared/styles.css`, `shared/wallet-utils.js` — UI skill helpers.
- Reference a shared file with a relative `shared/...` path; `build-skills.sh` bundles it into the zip.
