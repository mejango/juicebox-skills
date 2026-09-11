# Risks

This repository supplies protocol guidance, generated deployment data, and packaged skills. Consumers remain responsible for resolving live contracts and validating the transactions they prepare.

## Priority risks

- **Deployment provenance and chain differences.** `plugins/juicebox-v6/scripts/gen-chain-config.py` trusts the reviewed, pinned `deploy-all-v6/deployments` checkout supplied to it. Successful receipts in those artifacts gate rollout records; they are not independently verified against RPC by this generator. The generated snapshot includes executed production hook/router/gateway/feed records; OP Sepolia remains feed-only. A future proposal does not establish availability. Canonical names, retired generations, and their ABI mappings must remain consistent on each chain.
- **Live routes and retained custody.** A skill or recorded address cannot establish a project's current registry selection, the router behind a selected gateway, or whether a queued call settled. Consumers must resolve the live project path and reconcile gateway commitments and queue, retry, settlement, and refund events. A successful outer transaction or an issued pending-call count alone is not proof of destination settlement.
- **Installed SDK support.** Skills can describe APIs before an application's lockfile includes their release. Verify the installed exports and generated addresses before using gateway resolution or three-word buyback metadata builders.
- **History and downstream copies.** Disallowed hook/router generations can still serve existing project selections and historical transactions. Preserve their addresses and ABIs. Packaged ZIPs and copied MCP references can lag the source; archived Juicy Vision prompts are not updated by this rollout and need a parity review before reuse.

## Trust assumptions

Protocol facts are checked against the corresponding V6 source and deployment artifacts. Artifact package versions select generation-specific ABIs; an unversioned ABI alias represents the newest included package and does not identify every chain's deployed generation. RPC providers and indexers supply current state and event history, while registry/project operators can change selections subject to on-chain permissions and locks. Documentation and previews do not grant authority or guarantee execution.

## Invariants to verify

- Regeneration reads executed flat deployment records and retains current, previous, and v1 generations; proposed transactions never supply an active contract address, and production availability does not imply that existing projects migrated.
- `gen-chain-config.py --check` passes for the reviewed deployment checkout, including generated ABIs. Every rollout artifact has successful deployment evidence and the ABI matches its recorded package generation.
- Resolve the directly called terminal, project registry selection, and gateway `ROUTER()` separately. Permit2 targets the directly called contract; router and buyback quote IDs target their actual consumers.
- Keep gateway pending custody distinct from settled or forgiven fees. Use the committed event payload for retry/finalization, and verify the resulting state and events.
- Rebuild skill archives after their source or bundled resources change; verify source, ZIP, and downstream MCP reference parity. Keep retired history when refreshing data.
