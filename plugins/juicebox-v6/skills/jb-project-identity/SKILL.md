---
name: jb-project-identity
description: |
  Resolve a Juicebox V6 project from its name, URL, handle, or chain and project ID.
  Use when: (1) finding an existing project before reads or transactions,
  (2) building project search or URL routing, (3) matching a project across chains.
  Keeps the identity fixed to V6 and preserves ambiguous search results.
metadata:
  version: 6.0.0
---

# Juicebox V6 Project Identity

Every project reference is `{ version: 6, chainId, projectId }`. Keep `projectId` as
a decimal string at JSON boundaries and a `bigint` in contract calls. Project IDs
are independent counters on each chain and each protocol deployment; a name,
logo, ticker, or numeric ID alone does not identify a V6 project.

## Resolve before reading or preparing a transaction

When connected to `https://juicebox.center/mcp`, use `jb_resolve_project` first.
The example below parses an identifier; it does not prove that the project exists:

```json
{ "input": "v6:base:42" }
```

- Explicit V6 chain/ID or a supported Juicebox Money / Revnet Money URL returns a
  project reference with `existenceVerified: false`. Call `jb_get_project` with
  that reference to check live state before using it.
- A bare numeric ID is ambiguous. Obtain its chain from the user's context or
  ask for the chain; never assume Ethereum or reuse the connected wallet's chain.
- A name or handle returns candidates with `selectionRequired: true`. Search in
  the intended mainnet/testnet network; `jb_search_projects` can also filter a
  specific `chainId`. Keep candidates' chain IDs, project IDs, and owners visible.
  Select using an explicit user choice or an already supplied independent anchor
  such as the exact project URL or owner and chain. A matching name alone is not
  enough for a transaction.
- An undeployed JB Center intent is a signed configuration, not an existing
  project. Do not turn its name or proposed ID into a deployed project reference.
- An explicit unsupported protocol version is outside this plugin's scope.
  Reject it; do not rewrite it to V6, look up another deployment, or substitute
  the same ID in V6. If no V6 match is verified, report that result.

For a direct integration, read `JBProjects.ownerOf(projectId)` and
`JBDirectory.controllerOf(projectId)` using the V6 addresses from
`shared/chain-config.json` on the selected chain. An owner read proves existence
in that V6 `JBProjects` contract; it does not authenticate the project's name or
prove the user's intended target. Read the live directory before choosing
controller and terminal semantics. A custom controller must be handled explicitly.

## SDK and URL boundaries

Use `@bananapus/nana-sdk-core/v6` for builders and reads, and
`jbContractAddress['6']` for address lookup. The root SDK also contains APIs for
other deployments. Its URN helpers' omitted-version defaults are not V6.
Always parse an explicit `v6:` prefix and pass `6` to `toJbUrn`:

```typescript
import { jbUrn, toJbUrn } from '@bananapus/nana-sdk-core'

const parsed = jbUrn('v6:base:42')
if (!parsed || parsed.version !== 6) throw new Error('A V6 project is required')
const project = {
  version: 6 as const,
  chainId: parsed.chainId,
  projectId: parsed.projectId.toString(),
}
const identifier = toJbUrn(parsed.chainId, parsed.projectId, 6)
```

For versionless user input, apply this plugin's explicit V6 scope before calling
the SDK; retain the original input in the UI. Never remove an explicit version
marker and reinterpret the rest. Parse URLs structurally, validate the host and
project route, and reject conflicting chain or version indicators. Do not fetch
arbitrary user URLs to discover a project. A versionless URL handled by this
plugin is a V6 lookup only, pending the same live verification as any parsed ID.

Source: SDK `packages/core/src/utils/urn.ts`; MCP `src/services/identity.ts`;
V6 `nana-core-v6/src/JBProjects.sol` and `JBDirectory.sol`.

## Indexed discovery

Every supported Bendystraw query must use the literal `version: 6` wherever its
schema exposes a version argument or filter. Include `version` in selected rows
and reject a row whose value is not `6`; apply the same check to nested project
relations. Repeat the filter inside each `OR` branch. See `/jb-bendystraw` for
the exact schema and pagination; do not add nonexistent version arguments to
queries keyed only by an opaque ID.

```graphql
query V6Project {
  project(chainId: 8453, projectId: 42, version: 6) {
    chainId
    projectId
    version
    name
    owner
  }
}
```

Partition cache keys, persisted selections, and routes by all three identity
fields. An omnichain sibling must come from the V6 sucker relation and be
verified on its own chain; matching numeric project IDs are not a bridge link.

## Common mistakes

- Calling `jbUrn('base:42')` or omitting the version in `toJbUrn`.
- Treating a parsed identifier, indexed name, or successful generic search as
  live V6 identity verification.
- Replacing an unsupported explicit version with `6`.
- Reusing a project ID on another chain or selecting the first name match.
- Falling back to unfiltered data after a V6 lookup is empty or unavailable.
