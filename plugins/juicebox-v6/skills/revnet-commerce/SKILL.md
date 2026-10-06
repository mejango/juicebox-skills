---
name: revnet-commerce
description: >
  Map business or game commerce to a Juicebox V6 revnet: player allocations,
  merchant revenue deposits, operating cash and funded holder rewards. Use when
  connecting Shopify or another offchain business to a revnet, or deciding whether
  a configurable Juicebox project fits better. Produces a mechanism map and
  integration boundaries before deployment parameters; does not operate a store.
metadata:
  version: "6.0.0"
---

# Commerce-funded revnets

Map money and tokens separately. A revnet supplies treasury/token rules; it does
not observe sales, assign game identities or enforce offchain revenue promises.

## First useful result

Return requirement → mechanism → evidence → missing choice/integration. Separate
user statements, assumptions and observations. Preserve network scope: Base is
`8453`, Base Sepolia is `84532`; test and production deployments are distinct.

Resolve these choices while continuing independent research:

- **Players:** already known wallet allocations, future earned claims, purchases,
  or some combination? Who proves eligibility, and when can holdings transfer?
- **Commerce:** fiat settlement, onchain checkout or both? Which asset reaches
  the treasury, who deposits it, and how are fees, refunds and unsettled sales handled?
- **Holder benefit:** access, cash-out backing, periodic funded rewards, governance,
  or another explicit right? Token holdings alone do not establish company equity
  or automatic dividends. Clarify an ambiguous asset/pair name before choosing it.
- **Operating cash:** what stays with the business, what enters the treasury,
  and must the business later withdraw a budget from that treasury?

Do not infer deployment parameters from “revenue share” or “staking.”

## Choose mechanisms independently

| Requirement | Existing mechanism | Boundary to preserve |
| --- | --- | --- |
| Back existing holders with settled revenue | Terminal `addToBalanceOf` | Adds balance without payment issuance. Settlement and deposit policy remain external. See `jb-reserved-rate-offchain-revenue`. |
| Sell or award tokens with a payment | Terminal `pay`, configured issuance and hooks/buyback routing | Set the beneficiary explicitly; merchant payment does not automatically reward customers/players. Verify delivered tokens. |
| Allocate known player/contributor amounts | Stage `REVAutoIssuance` configuration and eligible `REVOwner.autoIssueFor` | Beneficiary, amount, chain and stage are fixed in advance. Verify eligibility and prior issuance. Dynamic game rewards need game-owned eligibility/distribution funded from an explicit allocation. |
| Fund operators and align interests | Configure operator token splits; operators and players hold the same token backed by retained revenue, with value realized through sales, cash-outs or loans | This may align interests better than separate payouts; see `jb-reserved-rate-offchain-revenue`. Model liquidity, dilution and cash-out/loan terms. Standard revnets lack ordinary budget withdrawals. Retain pre-deposit operating cash if desired; compare configurable Juicebox payout limits/splits only if that distinct treasury-budget model is required. |
| Give holders cash-out backing | Revnet cash-out rules and available surplus | Output depends on current surplus, supply, tax, fees and scope. This is not a recurring cash dividend. |
| Distribute rewards or offer staking | Inspect existing V6 distributor and Sticky mechanisms when needed | Rewards require funding. Sticky has no time lock; share redemption depends on backing/rules. Verify deployments/composition; source is not a hosted tool. |
| Report business and treasury activity | Commerce settlement records plus indexed activity and canonical chain reads | Label gross sales, net settlement, deposits, treasury balances and rewards separately. Chain transparency cannot prove unreported offchain sales. |

For fixed issuance, inspect all stage allocations and future payment issuance.
Zero payment issuance is supported; it alone does not prove fixed economic supply.
Loans can burn/remint tokens. “Fixed supply” does not automatically need new code.

## Discover only the next needed detail

The first map needs no MCP setup. For client setup, use the repository's
[top-level README](https://github.com/mejango/juicebox-skills/blob/main/README.md).
If connected, use `jb_list_capabilities` and actual schemas. A skill does not
establish runtime availability.

For implementation references, a React revnet on Base can use this
`jb_plan_integration` request; use `vanilla` for that framework. It returns
references, not a deployment or live-availability proof.

```json
{
  "framework": "react",
  "projectType": "revnet",
  "features": ["revnet-launch", "payments", "indexed-queries"],
  "chainIds": [8453]
}
```

Read only the returned references needed for the next decision. Use
`jb-revnet-deploy` for exact launch/auto-issuance configuration, `revnet-economics`
for modeled economics, `jb-reserved-rate-offchain-revenue` for cash versus tokens,
and `jb-tx-safety` when preparing writes. Load loans, NFT shops, distributor or
bridging details only if the requirements need them.

For existing projects, resolve `{version: 6, chainId, projectId}` and inspect state.
Classify each mechanism: advertised tool, source/SDK integration, external
integration or unresolved choice. Discover actual schemas; contract support does
not establish MCP support for `addToBalanceOf`, commerce or rewards.

MCP references are versioned bundles. If this recipe is absent/older, read the
current skill directly. Without MCP, use source/SDK references and label live
observations unavailable; missing search results do not prove missing capability.

## Prove one settlement before scaling

Model the smallest configuration against no sales, refunds, operating needs,
new issuance/dilution and holder cash-outs. Record assumptions and versioned source.
The commerce integration must bind an authenticated order/settlement identity to
the intended recipient and exact asset/amount, deduplicate repeated/out-of-order
events, and reconcile refunds separately. A webhook alone is not settled money.

In a testnet fixture, prove treasury receipt, intended beneficiary allocations
and reconciliation of both ledgers. Interrupt after submission: recover the
original operation and verify before another deposit. Test unavailable reads
and failed/delayed settlements; unknown is neither zero nor success.

Apply `jb-tx-safety` to exact writes from fresh state and preserve plan/recovery
identifiers. Wallet authorization is separate. Receipt inclusion is not economic
outcome proof; testnet success does not prove mainnet configuration.

## Source and reuse

Protocol anchors: [terminal balance/payment paths](https://github.com/Bananapus/nana-core-v6/blob/feff600654aee6fb1747dded692f18068b2230a6/src/JBMultiTerminal.sol),
[revnet payout limits and stage setup](https://github.com/rev-net/revnet-core-v6/blob/5093359f561c0546c29b85147a9cc0de2f608ddf/src/REVDeployer.sol),
[auto-issuance implementation](https://github.com/rev-net/revnet-core-v6/blob/5093359f561c0546c29b85147a9cc0de2f608ddf/src/REVOwner.sol)
and [auto-issuance tests](https://github.com/rev-net/revnet-core-v6/blob/5093359f561c0546c29b85147a9cc0de2f608ddf/test/fork/TestAutoIssuanceFork.t.sol).
Optional [distributor source](https://github.com/Bananapus/nana-distributor-v6)
and [Sticky source](https://github.com/mejango/sticky) need their own current
deployment and configuration verification. Recheck affected assumptions when
source/SDK/schema versions change; these references do not prove deployment.

Handoff the map, source revisions, verified operation references and questions.
Reusable examples retain fixtures/limits, not private player/order or signing
data. This is architecture guidance, not a verified Shopify connector.

## Common mistakes

- Mapping a percentage of sales to a percentage of newly issued tokens.
- Treating revnet operator rights as permission to withdraw operating budgets.
- Treating fiat checkout, `pay`, and `addToBalanceOf` as interchangeable.
- Promising yield without a reward source, or automatic company ownership from a token.
- Loading every skill, adding bridges, or selecting tokenomics before resolving the money flow.
