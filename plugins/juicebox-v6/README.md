# Juicebox V6 Skills

Portable Agent Skills for working with Juicebox V6. Extract packaged skill directories
from `dist/` for an agent that supports `SKILL.md`, or provide the relevant
instructions and bundled files as task context. The existing Claude plugin and ZIP upload integration are
optional packaging for the same content.

Every skill was written against V6 source in this workspace (`nana-*-v6`,
`revnet-core-v6`, `croptop-core-v6`, `bendystraw-v6`, `deploy-all-v6`) — no facts
carried over from earlier protocol versions. Authoring rules: [`CONVENTIONS.md`](./CONVENTIONS.md).

## Layout

- `skills/<name>/SKILL.md` — one skill per directory (55 skills)
- `shared/chain-config.json` — canonical per-chain V6 addresses, generated from `deploy-all-v6/deployments`
- `shared/abis/*.json` — verified ABIs from deployment artifacts
- `shared/wallet-utils.js`, `shared/styles.css` — helpers bundled into UI skills
- `build-skills.sh` — packages each skill (+ referenced shared files) into portable `dist/*.zip` archives
- `dist/` — generated; do not edit

## Regenerating

- Addresses changed? Run `python3 scripts/gen-chain-config.py <deploy-all-v6/deployments>` to regenerate `shared/chain-config.json` and the versioned router, gateway, buyback, and ratio-feed ABIs; `--check` verifies parity. The generator reads flat executed deployment records and retains `_deprecated*` generations. It never reads proposals. Resolve project registry selections at runtime; see `shared/references/router-gateway-rollout.md`.
- Run `node scripts/test-project-identity.mjs` after changing identity guidance or the NFT/omnichain examples. It executes the examples with mocked contract/indexer responses, including wrong-deployment, wrong-chain, and missing-project cases.
- Then run `./build-skills.sh`.

## Hosted MCP

Any agent supporting MCP over Streamable HTTP can connect to **https://juicebox.center/mcp** using the
[repository setup instructions](../../README.md#connect-the-hosted-mcp). Installing
or uploading a skill alone does not connect the server. When connected, call
`jb_list_capabilities` to discover supported V6 workflows and their limits.

Use `jb-query` and `jb-bendystraw` for live/indexed reads, `jb-tx-safety` for the
unsigned-plan handoff, and the [MCP development guidance in `jb-sdk`](skills/jb-sdk/SKILL.md#develop-with-the-hosted-mcp)
for SDK, contract, and webclient references. Skills remain usable with the relevant
V6 SDK/source workflow when an MCP connection is unavailable.

Skill names below identify folders, not universal slash commands. Load or invoke
them through the host agent's own mechanism. Extracted ZIPs preserve skill-local
references to addresses, ABIs, and other bundled resources.

## Start here

For existing projects, start with `jb-project-identity`: every selection is `{ version: 6, chainId, projectId }`, never a bare ID or the first name match. For launch metadata, `jb-project-metadata` describes the reviewed IPFS publishing workflow at `https://juicebox.center/mcp`. Read `jb-contracts` (addresses, which contract does what) and `jb-v6-api` (signatures, structs, permission IDs) as needed. Then pick a lane:

| Building | Read, in order |
|----------|----------------|
| A pay / cash-out / mint button for an existing project | jb-sdk → jb-tx-safety → jb-terminal-selection → jb-data-hook-resolution → jb-protocol-fees → jb-cash-out-curve → jb-permit2-metadata → jb-interact-ui. Revnets: add revnet-economics. 721: add jb-721-tier-content. |
| A webclient that reads project state | jb-query → jb-bendystraw → jb-omnichain-per-chain-projectids → jb-explorer-ui / jb-event-explorer-ui / jb-ruleset-timeline-ui |
| A pay, cash-out, or split hook | jb-v6-impl → jb-buyback-hook / jb-lp-split-hook (reference implementations) → jb-pay-hook / jb-cash-out-hook / jb-split-hook → jb-fee-flows → jb-hook-deploy-ui |
| A new project or revnet, multi-chain | jb-project → jb-revnet-deploy → jb-ruleset → jb-fund-access-limits → jb-multi-currency → jb-suckers → jb-relayr → jb-safe-and-relayr-execution → revnet-omnichain-default → jb-deploy-ui / jb-omnichain-ui |
| A 721 collection | jb-721-tier-content → jb-721-per-chain-config → jb-omnichain-tier-quantity-per-chain → jb-nft-gallery-ui |
| Loans against revnet tokens | jb-revloans → jb-loan-queries |

Every transaction UI follows CONVENTIONS rule 5: simulate first, nonzero floors, `receipt.status` checked.

**Not deployed** (source exists, no addresses; do not target): `JBDistributor*`, `JBSwapSplitHook`, `JBRouterTerminalGateway`, `JBPayRouteResolver`, `JBRatioPriceFeed`, everything under `extensions/`.

## Skill index

| Domain | Skills |
|--------|--------|
| Core API / reference | jb-project-identity, jb-project-metadata, jb-sdk, jb-v6-api, jb-v6-impl, jb-contracts, jb-currency-types, jb-project, jb-ruleset, jb-multi-currency, jb-query, jb-decode, jb-patterns, jb-simplify, jb-docs |
| Terminals / fees | jb-tx-safety, jb-terminal-selection, jb-data-hook-resolution, jb-terminal-wrapper, jb-protocol-fees, jb-fee-flows, jb-fund-access-limits, jb-cash-out-curve, jb-permit2-metadata |
| Hooks / 721 | jb-pay-hook, jb-cash-out-hook, jb-split-hook, jb-buyback-hook, jb-lp-split-hook, jb-721-per-chain-config, jb-721-tier-content |
| Omnichain / suckers | jb-suckers, jb-relayr, jb-safe-and-relayr-execution, jb-omnichain-erc20-config, jb-omnichain-payout-limits, jb-omnichain-per-chain-projectids, jb-omnichain-tier-quantity-per-chain |
| Revnets / loans / croptop | jb-revnet-deploy, revnet-economics, revnet-modeler, revnet-omnichain-default, jb-reserved-rate-offchain-revenue, jb-revloans, jb-loan-queries, jb-croptop |
| Data | jb-bendystraw |
| UI generators | jb-deploy-ui, jb-explorer-ui, jb-event-explorer-ui, jb-ruleset-timeline-ui, jb-interact-ui, jb-hook-deploy-ui, jb-nft-gallery-ui, jb-omnichain-ui |
