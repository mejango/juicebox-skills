---
name: jb-reserved-rate-offchain-revenue
description: |
  Separate revenue contributions from reserved token issuance when configuring
  commerce or revenue-sharing projects. Use when choosing addToBalanceOf versus pay,
  or interpreting reservedPercent / revnet splitPercent as a share of business revenue.
metadata:
  version: "6.0.0"
---

# Revenue Contributions and Reserved Token Issuance

## Independent decisions

Specify these separately for both offchain and onchain revenue:

- **Revenue contribution** — which receipts fund the project, their accounting basis (gross sales, net settlement or profit), amount, timing and accountable depositor/router. A contract cannot verify an offchain revenue promise by itself; automatic onchain routing requires an actual configured payment path.
- **Reserved token issuance** — `JBRulesetMetadata.reservedPercent`, out of `10_000`, allocates newly minted project tokens between the payment beneficiary and reserved-token splits. Revnet `REVStageConfig.splitPercent` maps to the same field. It does not allocate that percentage of cash or maintain that percentage of total token supply.

Do not infer either percentage from the other or set a zero/nonzero reserved percentage merely because revenue originates offchain/onchain. Choose reserved issuance from the intended token allocation policy.

Reserved-token splits can compensate operators with the same token players and supporters hold. Revenue retained in the treasury backs those holdings under shared cash-out rules. Operators can realize token value through sales, cash-outs or supported loans. This may align interests better than separate operating payouts because operators and participants depend on the same token's economics.

Model that shared-token funding approach before treating missing ordinary payouts as a reason to reject a revnet. Realizable amounts and timing still depend on allocation, issuance/dilution, treasury surplus, market liquidity and the chosen cash-out/loan terms; token splits do not guarantee a fixed cash budget.

## Choose the contribution operation

| Operation | Consequence |
| --- | --- |
| `JBMultiTerminal.addToBalanceOf` | Adds treasury backing without issuing project tokens or applying reserved issuance. Use when the contribution should support existing holders without awarding tokens to the depositor. |
| `JBMultiTerminal.pay` | Runs the project's payment rules and hooks. Newly issued tokens use the reserved percentage; a buyback hook may instead deliver existing tokens and route funds to a pool. Inspect the configured path and preview it before describing token delivery or treasury retention. |

Cash-outs burn project tokens to reclaim surplus under the configured curve; they are not recurring dividends. If periodic holder payments are intended, specify their funding and distribution mechanism separately. Company ownership is also a separate requirement.

## Numerical example

Suppose a business independently chooses to contribute 20% of a defined $1,000 settlement: $200. Calling `addToBalanceOf` with that $200 issues no tokens, whether `reservedPercent` is 0 or 7000.

Separately, suppose a `pay` takes the issuance path and produces 100 total new tokens with `reservedPercent: 7000`: 30 go to the payment beneficiary and 70 accrue for reserved splits. If 900 tokens already exist, no other reserves are pending, and an operator with no previous tokens receives all 70 reserved tokens, that allocation is 70/1,000 = 7% of the resulting supply. It is not 70% of the business's revenue or treasury, nor a fixed ownership percentage. Cash-out value also depends on available surplus and the configured tax and fees.

## Verification and sources

- Record the contribution policy, token allocation policy and chosen operation independently; preserve unknown business terms instead of inventing defaults.
- Verify the actual payment hooks and beneficiary. Do not assume every `pay` mints tokens or retains the full payment in the treasury.
- For nonzero reserved issuance, inspect the reserved-token splits. Tokens accrue unminted in `JBController.pendingReservedTokenBalanceOf` until `sendReservedTokensToSplitsOf`; any portion not covered by splits is minted to the project owner at distribution time. A revnet's owner is `REVOwner`, not its operator.

Mechanics verified against [JBMultiTerminal](https://github.com/Bananapus/nana-core-v6/blob/feff600654aee6fb1747dded692f18068b2230a6/src/JBMultiTerminal.sol) (`addToBalanceOf`, `_pay`), [JBController](https://github.com/Bananapus/nana-core-v6/blob/feff600654aee6fb1747dded692f18068b2230a6/src/JBController.sol) (`mintTokensOf`, `_splitTokenCount`, `sendReservedTokensToSplitsOf`), and [REVDeployer](https://github.com/rev-net/revnet-core-v6/blob/5093359f561c0546c29b85147a9cc0de2f608ddf/src/REVDeployer.sol) (`_makeRulesetConfiguration`). These source references establish mechanics, not a selected project's deployed configuration.
