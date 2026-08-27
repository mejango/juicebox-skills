# Juicebox V6 Skills

AI skills for working with Juicebox V6 — consumed by Claude Console (upload zips from
`dist/`) and Claude Code (this folder is symlinked as the `juicebox-v6` plugin in
consuming projects, e.g. `juicy-vision/.claude/plugins/juicebox-v6`).

Every skill was written against V6 source in this workspace (`nana-*-v6`,
`revnet-core-v6`, `croptop-core-v6`, `bendystraw-v6`, `deploy-all-v6`) — no facts
carried over from earlier protocol versions. Authoring rules: [`CONVENTIONS.md`](./CONVENTIONS.md).

## Layout

- `skills/<name>/SKILL.md` — one skill per directory (46 skills)
- `shared/chain-config.json` — canonical per-chain V6 addresses, generated from `deploy-all-v6/deployments`
- `shared/abis/*.json` — verified ABIs from deployment artifacts
- `shared/wallet-utils.js`, `shared/styles.css` — helpers bundled into UI skills
- `build-skills.sh` — packages each skill (+ referenced shared files) into `dist/*.zip` for Claude Console
- `dist/` — generated; do not edit

## Regenerating

- Addresses changed? Run `python3 scripts/gen-chain-config.py <path/to/deploy-all-v6/deployments>`, then re-check skills that inline core addresses (`jb-decode`, `jb-contracts`, `shared/wallet-utils.js`).
- Then run `./build-skills.sh`.

## Start here

Read `jb-contracts` (addresses, which contract does what) and `jb-v6-api` (signatures, structs, permission IDs) first. Then pick a lane:

| Building | Read, in order |
|----------|----------------|
| A pay / cash-out / mint button for an existing project | jb-terminal-selection → jb-protocol-fees → jb-cash-out-curve → jb-permit2-metadata → jb-interact-ui. Revnets: add revnet-economics. 721: add jb-721-tier-content. |
| A webclient that reads project state | jb-query → jb-bendystraw → jb-omnichain-per-chain-projectids → jb-explorer-ui / jb-event-explorer-ui / jb-ruleset-timeline-ui |
| A pay, cash-out, or split hook | jb-v6-impl → jb-pay-hook / jb-cash-out-hook / jb-split-hook → jb-fee-flows → jb-hook-deploy-ui |
| A new project or revnet, multi-chain | jb-project → jb-ruleset → jb-fund-access-limits → jb-multi-currency → jb-suckers → jb-relayr → revnet-omnichain-default → jb-deploy-ui / jb-omnichain-ui |
| A 721 collection | jb-721-tier-content → jb-721-per-chain-config → jb-omnichain-tier-quantity-per-chain → jb-nft-gallery-ui |
| Loans against revnet tokens | jb-revloans → jb-loan-queries |

Every transaction UI follows CONVENTIONS rule 5: simulate first, nonzero floors, `receipt.status` checked.

**Not deployed** (source exists, no addresses; do not target): `JBDistributor*`, `JBSwapSplitHook`, `JBRouterTerminalGateway`, `JBPayRouteResolver`, `JBRatioPriceFeed`, everything under `extensions/`.

## Skill index

| Domain | Skills |
|--------|--------|
| Core API / reference | jb-v6-api, jb-v6-impl, jb-contracts, jb-currency-types, jb-project, jb-ruleset, jb-multi-currency, jb-query, jb-decode, jb-patterns, jb-simplify, jb-docs |
| Terminals / fees | jb-terminal-selection, jb-terminal-wrapper, jb-protocol-fees, jb-fee-flows, jb-fund-access-limits, jb-cash-out-curve, jb-permit2-metadata |
| Hooks / 721 | jb-pay-hook, jb-cash-out-hook, jb-split-hook, jb-721-per-chain-config, jb-721-tier-content |
| Omnichain / suckers | jb-suckers, jb-relayr, jb-omnichain-erc20-config, jb-omnichain-payout-limits, jb-omnichain-per-chain-projectids, jb-omnichain-tier-quantity-per-chain |
| Revnets / loans / croptop | revnet-economics, revnet-modeler, revnet-omnichain-default, jb-reserved-rate-offchain-revenue, jb-revloans, jb-loan-queries, jb-croptop |
| Data | jb-bendystraw |
| UI generators | jb-deploy-ui, jb-explorer-ui, jb-event-explorer-ui, jb-ruleset-timeline-ui, jb-interact-ui, jb-hook-deploy-ui, jb-nft-gallery-ui, jb-omnichain-ui |
