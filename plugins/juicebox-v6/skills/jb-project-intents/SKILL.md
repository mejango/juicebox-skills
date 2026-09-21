---
name: jb-project-intents
description: |
  Create, list, render and deploy Juicebox V6 project intents stored on juicebox.center.
  Use when: (1) building a create flow that should not need a transaction,
  (2) merging undeployed intents into project lists and search,
  (3) rendering a project page for an undeployed intent, (4) inserting the
  deploy-first step before any write against one.
metadata:
  version: "6.0.0"
---

# Juicebox V6 Project Intents

A project intent is a signed, frozen launch: per-chain launch calldata plus the
client's own form data, stored on juicebox.center. Publishing needs one signature
and no transaction. The intent appears in lists and search as an undeployed
project and is deployed on first use — sponsored by Center on a fixed set of
chains, or self-paid by the triggering wallet on every chain. Source: the
`juicebox.center` `/v1` API and `@bananapus/nana-sdk-core/jbcenter` (2.7.0).

## Envelope and signing message

| Field | Type | Notes |
|---|---|---|
| `format` | string | `<app>/<version>`, e.g. `jbm/1` — identifies the publishing client |
| `deploymentVersion` | string | `"6"` |
| `chainIds` | `number[]` | sorted, unique |
| `deploymentCalls` | array | `{ chainId, to, data }`, exactly one entry per `chainIds` member |
| `jb` | object | the publishing client's own form data, opaque to Center |

Content hash = `keccak256` of the envelope's canonical JSON. Get the exact
message to sign from `POST /v1/intents/message`, then `personal_sign` it —
never hand-build the string:

```
Juice Central project intent
Version: 1
Content hash: <hash>
```

Center verifies the signature with ERC-1271/6492 support, so a passkey smart
account that isn't deployed yet can still publish. The creation fee is **not**
part of the signed envelope — the deployer reads `JBProjects.creationFee()`
live (0.0001 ETH today; see `jb-project` for the address) and must send that
exact value at deploy time, whatever it is then.

## Lifecycle

| Status | Meaning |
|---|---|
| `undeployed` | Published, no chain has a recorded deployment yet |
| `deployed` | At least one chain has a recorded deployment |

A published intent is firm: there is no edit, replace, or withdraw endpoint.
Once `deployed`, the intent leaves default search and its `/intent/<id>` URL
redirects to the deployed project.

Stage timestamps are absolute and are honored exactly as signed — a late
deploy does not shift them. Stage 1 must carry an absolute `mustStartAtOrAfter`
set to the time the intent was made (or an explicitly chosen future time),
never `0`. A `0` is read as "start now," which is deploy time, not the time
the signer intended, and desyncs every later stage's boundary from the
schedule the signer actually saw and signed.

## One sender per intent

Sucker, ERC-20, and 721-hook salts on each chain hash `_msgSender()`. Every
chain of one intent must be deployed by the same sender, or the deployments
never link into one omnichain project — they land as unrelated same-named
projects on separate chains.

There are exactly two valid senders for a whole intent, never mixed:

- Center's sponsor key deploys every chain (sponsored path).
- The triggering wallet deploys every chain (self-paid path).

Center refuses `POST /v1/intents/:id/deploy` for an intent that already has
any recorded deployment — sponsoring on top of a partial self-paid deployment
would introduce a second sender.

## Sponsored chains and the deploy route

| Family | Chain IDs |
|---|---|
| Mainnet | `8453` (Base), `10` (Optimism), `42161` (Arbitrum) |
| Testnet | `11155111` (Sepolia), `84532` (Base Sepolia), `11155420` (Optimism Sepolia), `421614` (Arbitrum Sepolia) |

One family per intent — `isSponsorable(chainIds)` requires every chain in the
intent to fall in the mainnet family or every chain to fall in the testnet
family, never a mix of the two. Ethereum mainnet (`1`) is never sponsored — an
intent that includes it is self-paid only. Sponsored deploys run through
Relayr with Center's sponsor key as the sender on every chain (see
`jb-relayr` for bundle/polling mechanics); Center itself queues and tracks
the per-chain sends.

## Center routes (`/v1`, origin-gated)

| Route | Purpose |
|---|---|
| `POST /v1/intents/message` | Get the exact signing message for a prepared envelope |
| `POST /v1/intents` | Publish. Rate-limited 20/publisher/day, 60/IP/hour → 429 `publish_limit` |
| `GET /v1/intents/:id` | Fetch the intent, including `deploys[]` |
| `GET /v1/search` | Search, includes undeployed intents |
| `POST /v1/intents/:id/deployments` | Record a self-paid deployment: `{ chainId, projectId, transactionHash }`. Verified from the receipt when the top-level tx matches the call, else by trace |
| `POST /v1/intents/:id/deploy` | Request a sponsored deploy. `202 { deploys }`; `200` if already queued; `400` unsponsorable or not `undeployed`; `429 sponsor_quota` (5/requester/day) or `sponsor_budget` (0.05 ETH/day); `503` paused |

`deploys[]` entries: `{ chainId, status: queued|sent|confirmed|failed, transactionHash, bundleUuid, error, createdAt, updatedAt }`.

## The intent project page

`intentPath(id)` = `/intent/<id>`. Render the page from `decodeDeploymentCall`
on one of the intent's `deploymentCalls` (the launch is the same logical
configuration on every chain), with a "Deploys on first use" badge. Once
`isFullyDeployed(intent)` (or the relevant chain in `deployedChains(intent)`),
redirect to the real project page — do not keep serving the intent page for a
project that already exists.

## `decodeDeploymentCall` shells

```js
const decoded = decodeDeploymentCall(call) // one { chainId, to, data } entry
```

| `flavor` | Typed fields |
|---|---|
| `project` | `owner`, `projectUri`, `rulesetConfigurations`, `terminalConfigurations` |
| `project-721` | `owner`, `projectUri`, `rulesetConfigurations`, `terminalConfigurations` |
| `omnichain` | `owner`, `projectUri`, `rulesetConfigurations`, `terminalConfigurations` |
| `revnet` | `operator`, `stages`, `description` |
| `unknown` | none — render generically, do not guess a shape |

## Lists and search: `mergeSearch`

```js
const rows = mergeSearch(bendystrawRows, centerIntentItems)
```

`mergeSearch(rows, items)` merges deployed projects (Bendystraw) with
undeployed intents (Center search), newest first; intent rows carry
`undeployed: true`. Use it wherever a client renders project lists or search
results. Trending and Top stay volume-based and are computed from Bendystraw
alone — an intent has no volume, so it does not belong in either.

## `ensureDeployed` at the write chokepoint

```js
const projectIds = await ensureDeployed({ client, intent, selfPaid, onStep, pollMs, timeoutMs, signal })
// => Record<chainId, projectId>
```

Every on-chain write against an undeployed intent runs `ensureDeployed` first,
at the client's single write chokepoint, before anything in `jb-tx-safety`'s
review/simulate/send pipeline — there is no `projectId` to write against
until it resolves. After it resolves, re-resolve project ids from the result
and continue the write normally.

Behavior: sponsors when the intent is sponsorable and nothing is deployed yet,
polling `GET /v1/intents/:id` until every chain is `confirmed`; falls back to
the caller's `selfPaid(calls)` on a `400`/`429`/`503` from the deploy request
and records each resulting deployment; never mixes senders across a fallback
(a fallback restarts the whole intent as self-paid, it does not patch in the
self-paid wallet for the chains sponsorship failed on). Throws
`EnsureDeployedError` (carrying `chainId` for the row that failed) on
irrecoverable failure.

Client norm: the create flow's primary action is **Publish** — there is no
separate save step and no later edit action to build UI for.

## Common mistakes

- Baking `mustStartAtOrAfter: 0` into stage 1 of an intent — the signer's
  intended absolute start is lost; the ruleset starts at deploy time instead.
- Deploying some chains yourself and asking Center to sponsor the rest —
  breaks the one-sender rule; the sucker/ERC-20/721-hook salts stop matching
  and the chains never link into one omnichain project.
- Showing undeployed intents in Trending or Top — those rankings are
  volume-based and an intent has zero volume.
- Calling them "intents" in user-facing copy — that language implies
  something still negotiable and invites edit/withdraw requests the system
  does not support. Say "project" with a "Deploys on first use" badge instead.
- Treating the intent signature as transaction approval — it authorizes
  Center to store and publish the frozen calldata, not to spend funds.
  Deployment still needs a real funded transaction, sponsored or self-paid,
  through `ensureDeployed`.
