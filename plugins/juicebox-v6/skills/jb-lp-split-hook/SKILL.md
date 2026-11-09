---
name: jb-lp-split-hook
description: |
  Juicebox V6 Uniswap V4 LP split hook (univ4-lp-split-hook-v6, 1.5.0). Use when: (1) wiring a reserved-token or
  payout split to `JBUniswapV4LPSplitHook` / `JBP6FeeLPSplitHook`, (2) encoding `deployHookFor`, `deployPool`,
  `addLiquidity`, `collectAndRouteLPFees`, `claimFeeTokensFor`, (3) reading hook ledgers (`accumulatedProjectTokens`,
  `accumulatedTerminalTokens`, `askTokenIdOf`, `bidTokenIdOf`, `poolKeyOf`, `claimableFeeTokens`), (4) debugging
  `EmptyCorridor`, `NoDeployableLiquidityAtSpot`, `PriceDeviationTooHigh`, `TwapUnavailable`, `InvalidSplitGroup`,
  `LiquidityAutomationFailed`, (5) reasoning about the floor/ceiling tick corridor, the ask and bid positions,
  recycles, the fee-project cut, or Permit2 approvals, (6) telling a 1.5.0 instance from an older one before encoding,
  (7) indexing LP positions via bendystraw `buybackPoolPositions`.
metadata:
  version: "6.0.0"
---

# Uniswap V4 LP Split Hook

`JBUniswapV4LPSplitHook` (1.5.0) is an `IJBSplitHook`. On a project's **reserved-token split** (`groupId == 1`) it accumulates reserved project tokens; on a **payout split** it accumulates terminal tokens. It seeds one Uniswap V4 pool per project (project token and one terminal token) and holds at most **two single-sided positions** there: an **ask** of project tokens from just past the spot up to the issuance ceiling (`askTokenIdOf`) and a **bid** of terminal tokens from just past the spot down to the cash-out floor (`bidTokenIdOf`). Every recycle routes both positions' LP fees, burns both, and re-mints both from everything the hook holds for the project. The hook never cashes out and never burns reserved tokens; it burns only the project-token side of collected LP fees.

## Contracts and addresses

All addresses from `shared/chain-config.json` (deploy-all `deployments/<chain>/`). Same address on every chain that has a deployment, except `JBUniswapV4Hook`.

| Key | Role | Address |
|-----|------|---------|
| `JBUniswapV4LPSplitHook` | 1.5.0 implementation (clones delegate to it). Never wire splits to it | `0x5b54156b4a68ba5f9fa7706b913045e597e45e74` |
| `JBUniswapV4LPSplitHookDeployer` | Clone factory (`deployHookFor`) around the 1.5.0 impl, configured with the 2.0.0 `JBUniswapV4Hook` as oracle; registers clones in `JBAddressRegistry` | `0xad2ed0024647ccc2eda4e42dc616d6fe886ed028` |
| `JBUniswapV4LPSplitHookMath` | Linked external library: corridor/tick math, rate lookups, per-tick liquidity cap | `0x03fa7fbf4bacc4495f44fec35fbcc00e63f790ad` |
| `JBP6FeeLPSplitHook` | The shared clone projects wire into splits. `feeProjectId = 1`, `feePercent = 1000` (10%), `buybackHook = JBBuybackHookRegistry`, salt `"_BAN_LP_SPLIT_HOOK_V6_"` deployed by the Safe `0x4dc161eF837fF1C4485b08DDFcDB182F2157bE18` | `0xef8993f50363461007bed2f54e98bbef9854148a` |
| `Permit2` | Canonical Uniswap Permit2 | `0x000000000022d473030f116ddee9f6b43ac78ba3` |
| `JBUniswapV4Hook` | The oracle hook (`IGeomeanOracle`) the instance keys every pool with; chain-specific (2.0.0) | per chain |

Superseded clones (still live, still hold their projects' inventory):

| Address | Version | Notes |
|---------|---------|-------|
| `0xaadf5369dd199794074b3f701ad2fe9bdbaf733d` | 1.5.0 | Same impl, via the first 1.5.0 deployer `0x41d276821a62f6be2de2a9f675de3fd430bfe18e`, keyed on the outgoing `JBUniswapV4Hook`. Same ABI and fee config as `0xef89...` |
| `0xe9493bc776699714a89aa982cf828d843f040d2a` | 1.3.0 | `feePercent = 2000` |
| `0xae6705c33c8b46f56878a1d4f1ce4d75fcfb6f62` | 1.1.1 | |
| `0x22988374af49507fec1ee78811fbc47d10d5e639` | 1.0.0 | BAN's reserved split still points here |

Clones older than 1.5.0 keep their own ABI: `deployPool(uint256,uint256)` (`0x74a2fa6d`), `addLiquidity(uint256,address,uint256)` (`0x9aa5d462`), `tokenIdOf`, `rebalanceLiquidity`, no `askTokenIdOf`/`bidTokenIdOf`. Do not encode 1.5.0 calls against them.

Chains with the hook, deployer, and `JBP6FeeLPSplitHook`: 1, 10, 8453, 42161, 11155111, 84532, 421614. **OP Sepolia (11155420) has only the 1.0.0-era `JBUniswapV4LPSplitHookMath` (`0xef2242dc7e8a082ce00c943548e414598896c4f4`)**. A reserved split pointing at `0xef89...` there hits an address with no code and the controller's split-hook call fails (caught per split by `JBController`; the split's tokens are burned as unconsumed allowance).

Constructor immutables (identical on all chains): `DIRECTORY = JBDirectory`, `PERMISSIONS = JBPermissions`, `TOKENS = JBTokens`, `PERMIT2`, `SUCKER_REGISTRY = JBSuckerRegistry`. `PROJECTS = DIRECTORY.PROJECTS()`. `poolManager`, `positionManager`, `oracleHook`, `buybackHook`, `feeProjectId`, `feePercent` are per-clone storage set once by `initialize`.

## Selectors (1.5.0)

| Function | Selector |
|----------|----------|
| `deployPool(uint256 projectId)` | `0x9af2297c` |
| `addLiquidity(uint256 projectId, address terminalToken)` | `0xc95f9d0e` |
| `collectAndRouteLPFees(uint256 projectId, address terminalToken)` | `0x978db958` |
| `claimFeeTokensFor(uint256 projectId, address beneficiary)` | `0xcd0802e5` |
| `askTokenIdOf(uint256,address)` / `bidTokenIdOf(uint256,address)` | `0x1777af12` / `0xc7686cc5` |

`executeAutomationFor(uint256)`, `sendToTerminal(address,uint256,address,uint256,bool)` and `burnFeeRemainder(uint256,address,uint256)` are self-call targets: any caller other than the hook reverts `JBUniswapV4LPSplitHook_Unauthorized`.

## processSplitWith (intake)

First check: `context.split.hook == this`, else `NotHookSpecifiedInContext`. Then by group:

**Reserved tokens (`groupId == 1`).** `msg.value == 0` else `UnexpectedMsgValue`; `DIRECTORY.controllerOf(projectId)` must exist (`InvalidProjectId`) and equal `msg.sender` (`SplitSenderNotValidControllerOrTerminal`). `context.token` is ignored; the project token is `JBTokens.tokenOf(projectId)`.
- No ERC-20 yet: Core already moved the credits to the hook. The hook requires `TOKENS.creditBalanceOf(hook)` to cover `accumulatedProjectCredits + amount + owed fee credits` (`InsufficientBalance`), adds to `accumulatedProjectCredits`, and returns. Credits are claimed into the ERC-20 at the next deploy or recycle.
- ERC-20: `safeTransferFrom(controller, hook, amount)`, `accumulatedProjectTokens += balanceDelta`. Then, if `accumulatedProjectTokens >= 1e15`, the inline automation attempt runs.

**Payout (`groupId != 1`).** Requires `groupId == uint256(uint160(context.token))` (`InvalidSplitGroup(groupId, token)`), `msg.sender` a terminal of the project (`isTerminalOf`), the pool already deployed (`InvalidStageForAction`), and `context.token == deployedTerminalTokenOf[projectId]` (`InvalidTerminalToken`). Native: `msg.value == amount`. ERC-20: `msg.value == 0`, pulled with `safeTransferFrom`. `accumulatedTerminalTokens[projectId][token] += received`, emits `PayoutAccepted(projectId, terminalToken, amount, caller)`, then the automation attempt runs at any size. Any rejection reverts and Core returns the payout to the project's balance. Core charges its normal fee on the payout unless the LP split hook address is feeless for that project (`JBFeelessAddresses`).

**Inline automation.** Runs only with `gasleft() >= 2_000_000 + 64_000`; the self-call `executeAutomationFor(projectId)` is forwarded at most 2,000,000 gas and deploys the pool if none exists, else recycles. Failure emits `LiquidityAutomationFailed(projectId, bytes4 reasonSelector, caller)`; the intake stays ledgered and anyone can retry with `deployPool`/`addLiquidity` (not gas-capped). A full recycle costs about 1.28M gas with one terminal plus about 30k per extra terminal.

## deployHookFor

```solidity
function deployHookFor(uint256 feeProjectId, uint256 feePercent, IJBBuybackHookRegistry buybackHook, bytes32 salt)
    external returns (IJBUniswapV4LPSplitHook hook);
```

- `salt == bytes32(0)`: `LibClone.clone` (plain CREATE, address depends on the deployer's nonce). Otherwise `cloneDeterministic` with effective salt `keccak256(abi.encode(msg.sender, salt))`. The same `(impl, deployer, msg.sender, salt)` gives the same address on every chain; a different sender gives a different address.
- The clone is initialized atomically: `initialize(feeProjectId, feePercent, poolManager, positionManager, oracleHook, buybackHook)`. Reverts: `feePercent > 10_000` (`InvalidFeePercent`); `feePercent > 0 && feeProjectId == 0` (`FeePercentWithoutFeeProject`); `feeProjectId != 0` with no controller (`InvalidProjectId`); deployer not yet configured (`JBUniswapV4LPSplitHookDeployer_NotConfigured`).
- Emits `HookDeployed(feeProjectId indexed, feePercent, hook, caller)` and registers the clone in `JBAddressRegistry`.
- Clone config is write-once and clones are immutable: a new implementation or a new oracle hook means a fresh clone and re-pointed splits (this is why `JBP6FeeLPSplitHook` moved from `0xaadf...` to `0xef89...`).

Predict the address: `LibClone.predictDeterministicAddress(impl, keccak256(abi.encode(sender, salt)), deployer)`.

## deployPool and addLiquidity

`deployPool(projectId)`: permissionless, `nonReentrant`. Picks the terminal token with `JBUniswapV4LPSplitHookMath.findHighestValueTerminalTokenOf` (highest ETH-denominated balance across terminals; terminals without `STORE()` are skipped) and locks it in `deployedTerminalTokenOf`. Reverts: second call on the same token `PoolAlreadyDeployed`, on a different token `OnlyOneTerminalTokenSupported`; no ERC-20 `InvalidProjectId`; nothing accumulated (tokens and credits both 0) `NoTokensAccumulated`; no primary terminal for the token `InvalidTerminalToken`; empty corridor `EmptyCorridor`. A hook-initialized pool seeds one spacing inside the floor bound (clamped one spacing short of the ceiling) and skips the TWAP check. An already-initialized pool (e.g. the buyback pool) keeps its price; a spot at or beyond the cash-out floor side reverts `ExistingPoolPriceOutOfBounds` (the ceiling side is accepted), and the TWAP check runs. Emits `ProjectDeployed(projectId, terminalToken, poolId, caller)`.

`addLiquidity(projectId, terminalToken)`: permissionless, `nonReentrant`, any time, with or without new tokens. Requires `isPoolDeployed(projectId, terminalToken)` (`InvalidStageForAction`) and the TWAP check, then recycles. Emits `LiquidityAdded(projectId indexed, terminalToken indexed, askTokenId, bidTokenId, caller)`.

`initialWeightOf[projectId]` records the first nonzero ruleset weight a deploy or recycle sees. It gates nothing.

## Recycle

1. Retire the ask and bid: route each position's fees, burn it (95% principal floor at the live price, contract-derived), credit recovered principal to the ledgers.
2. Claim every hook-held credit for the project (except owed fee credits) into the ERC-20 and `accumulatedProjectTokens`.
3. Price the corridor (after fee routing, so the raised floor counts).
4. Empty corridor: keep everything ledgered. Succeeds if something was retired, else reverts `EmptyCorridor`.
5. Mint the token0 range from `max(spotCeil, corridorLower)` to `corridorUpper` and the token1 range from `corridorLower` to `min(spotFloor, corridorUpper)`, both single-sided. `spotCeil`/`spotFloor` are widened to also clear the aligned TWAP tick, so the ask never sells below the TWAP and the bid never buys above it. Each mint is capped by `cappedSingleSidedLiquidity` (pool per-tick capacity). A side with an empty range or zero liquidity is skipped and stays ledgered.
6. Neither side minted: revert `NoDeployableLiquidityAtSpot(spotTick, ceilingTick, projectAmount, terminalAmount)` and keep the old positions.
7. Unconsumed amounts return to the ledgers, measured from balances (`TransferNotExact` if a mint debited more than offered).

## Pool and corridor geometry

Pool key: `currency0/1` = sorted (project token, terminal currency), `fee = 10_000` (1%), `tickSpacing = 200`, `hooks = oracleHook`. Native terminal token `0x...EEEe` maps to `Currency(address(0))`.

Corridor (`calculateTickBounds`), returns sorted `(lower, upper)`; `(0, 0)` means empty:

| Case | Bounds |
|------|--------|
| Cash-out preview `> 0` | Floor = upper bound on the 1-token cash-out value (preview + 2), ceiling = net issuance rate rounded toward a lower project price. Both rounded **inward** to spacing. Empty when cash-out value reaches the issuance price or no aligned spacing fits |
| Preview `== 0`, issuance on | Ceiling on the aligned issuance tick, other bound 2 spacings away, then the floor side lifted to the cash-out bound (can empty it) |
| Preview `== 0`, no issuance (weight 0 or 100% reserved) | Usable full range, floor side lifted to the cash-out bound |

Cash-out preview: surplus summed across all local terminals (`JBSurplus.currentSurplusOf`) over `totalTokenSupplyWithReservedTokensOf`, plus sucker remote surplus/supply unless `scopeCashOutsToLocalBalances`. Failing surplus or price reads revert the recycle (no zero-floor fallback).

TWAP guard (`_requireSpotNearTwap`): `oracleHook.observe(key, [1800, 0])`; `|spotTick - twapTick| > 200` reverts `PriceDeviationTooHigh(spot, twap, 200)`; oracle revert or short array reverts `TwapUnavailable`. Runs on `addLiquidity` and on `deployPool` against a pre-initialized pool. There is no swap anywhere in the hook.

## Permit2

Minting goes through `IPositionManager.modifyLiquidities` (`MINT_POSITION, SETTLE, SETTLE, SWEEP, SWEEP`). For each ERC-20 side the hook does `forceApprove(PERMIT2, amount)` then `PERMIT2.approve(token, positionManager, uint160(amount), uint48(block.timestamp + 60))`; amounts above `uint160` revert `Permit2AmountOverflow`. Approvals are cleared after the mint. Native ETH is passed as `msg.value`. Nothing external needs to approve the hook.

## Fees

`collectAndRouteLPFees(projectId, terminalToken)`: permissionless. Reverts `InvalidStageForAction` when neither position exists. For each live position: `DECREASE_LIQUIDITY(tokenId, 0, 0, 0)` + `TAKE_PAIR`, measured by balance delta. Positions are not moved. Per side:

- **Fee-project cut**: `cut = amount * feePercent / 10_000`, paid via `sendToTerminal(..., shouldPay: true)` = `pay(feeProjectId, token, cut, beneficiary = hook, minReturnedTokens = 0, memo "LP Fee")` on `DIRECTORY.primaryTerminalOf(feeProjectId, token)`. No terminal or a revert forgives the cut. Minted fee-project tokens go to `claimableFeeTokens[projectId]` (`claimableFeeTokenOf` records the ERC-20) or `claimableFeeCredits[projectId]`.
- **Terminal-token remainder**: `addToBalanceOf(projectId, ..., shouldReturnHeldFees: false)` on the project's primary terminal. Raises surplus.
- **Project-token remainder**: burned through the controller (`burnFeeRemainder`). Lowers supply. Reverts `FeeBurnNotExact` (forgiven) unless exactly `count` ERC-20 left and credits are unchanged.
- A failed add or burn folds that remainder into `accumulatedTerminalTokens` / `accumulatedProjectTokens` (next recycle's liquidity). Sends that debit more than `amount` revert `TransferNotExact` and fall back the same way.
- Emits `LPFeesRouted(projectId, token, totalAmount, feeAmount, remainingAmount, feeTokensMinted, caller)` per side.

`claimFeeTokensFor(projectId, beneficiary)`: requires `SET_BUYBACK_POOL` from the project owner; transfers the ERC-20 claim (`TransferNotExact` if over-debited), then best-effort credit claim. Emits `FeeTokensClaimed`.

Reading unclaimed fees off-chain, per position (ask and bid): Uniswap `StateView.getPositionInfo(poolId, positionKey)` with `positionKey = keccak256(abi.encodePacked(positionManager, tickLower, tickUpper, bytes32(tokenId)))` and `owed = ((feeGrowthInsideNow - last) mod 2^256) * liquidity >> 128`. Lifetime fees are only in the indexer (`feesClaimed0/1`).

## Reads

| View | Meaning |
|------|---------|
| `accumulatedProjectTokens(projectId)` | Project tokens held outside positions, next ask |
| `accumulatedTerminalTokens(projectId, terminalToken)` | Terminal tokens held outside positions, next bid |
| `accumulatedProjectCredits(projectId)` | Credits accepted before the project had an ERC-20 |
| `hasDeployedPool(projectId)`, `deployedTerminalTokenOf(projectId)`, `isPoolDeployed(projectId, terminalToken)` | Stage and locked pairing |
| `askTokenIdOf(projectId, terminalToken)`, `bidTokenIdOf(projectId, terminalToken)` | Live position NFT ids, `0` when none |
| `poolKeyOf(projectId, terminalToken)` | `PoolKey` (all-zero before deploy) |
| `claimableFeeTokens(projectId)`, `claimableFeeCredits(projectId)`, `claimableFeeTokenOf(projectId)` | Fee-project proceeds claimable by the project owner |
| `feeProjectId()`, `feePercent()`, `buybackHook()`, `oracleHook()`, `poolManager()`, `positionManager()` | Clone config |
| `initialWeightOf(projectId)` | First nonzero weight seen at deploy or recycle (informational) |

Position ranges come from `positionManager.getPoolAndPositionInfo(tokenId)`; the hook stores no range.

Detect the hook by behavior, not address: read the reserved splits (`JBSplits.splitsOf(projectId, rulesetId, 1)`) and treat any `hook` that answers `accumulatedProjectTokens` and `hasDeployedPool` as an LP split hook. Tell 1.5.0 from older with a successful `askTokenIdOf(projectId, terminalToken)` call (selector `0x1777af12`). Clones are minimal proxies, so their own bytecode holds no implementation selectors.

## Production call patterns

```ts
// Pick the generation by probing a 1.5.0-only view (clones are proxies), then simulate before sending.
const isV150 = await client.readContract({ address: hook, abi: lpSplitHookAbi, functionName: "askTokenIdOf", args: [projectId, terminalToken] })
  .then(() => true, () => false);
const { request } = await client.simulateContract(isV150
  ? { address: hook, abi: lpSplitHookAbi, functionName: "deployPool", args: [projectId] }
  : { address: hook, abi: legacyAbi, functionName: "deployPool", args: [projectId, 0n] });

// Recycle or collect fees (anyone):
await client.simulateContract({ address: hook, abi: lpSplitHookAbi,
  functionName: "addLiquidity", args: [projectId, terminalToken] });
await client.simulateContract({ address: hook, abi: lpSplitHookAbi,
  functionName: "collectAndRouteLPFees", args: [projectId, terminalToken] });
```

Wiring the split, reserved group (`groupId = 1`):

```solidity
JBSplit({ percent: 200_000_000, projectId: 0, beneficiary: payable(address(0)),
          preferAddToBalance: false, lockedUntil: 0, hook: IJBSplitHook(0xef8993f50363461007bed2f54e98bbef9854148a) })
```

Funding the bid from payouts: the same split in the payout group for the pool's terminal token (`groupId = uint256(uint160(token))`, e.g. `uint256(uint160(0x000000000000000000000000000000000000EEEe))` for native), only after `deployPool`.

Gate a deploy button on `!hasDeployedPool(projectId)`, a project ERC-20, and `accumulatedProjectTokens + accumulatedProjectCredits > 0`; no permission is needed.

## Indexing (bendystraw)

```graphql
buybackPools(where: { chainId, projectId, version: 6 }) { items { poolId } }
buybackPoolPositions(where: { chainId, poolId, burned: false }) {
  items { tokenId owner tickLower tickUpper liquidity feesClaimed0 feesClaimed1 updatedAt }
}
```

Positions are recorded only for pools registered as buyback pools (the hook's pool is the project's buyback pool when it shares the `JBUniswapV4Hook`). A 1.5.0 hook owns up to two live positions (`owner == hook`); every recycle burns both and mints new ids, so match against `askTokenIdOf`/`bidTokenIdOf`. Arg types are `Float!`/`BigInt!` per the bendystraw skill.

## Common mistakes

- **Encoding 1.5.0 calls against an older clone (or vice versa).** `deployPool(uint256)` vs `deployPool(uint256,uint256)` and `addLiquidity(uint256,address)` vs `addLiquidity(uint256,address,uint256)` are different selectors; the call reverts with no data. Sniff the bytecode first.
- **Wiring the impl `0x5b54...`, or `0xaadf...`, into a new split.** Use `JBP6FeeLPSplitHook` `0xef89...`; `0xaadf...` keys pools on the outgoing V4 hook.
- **Pointing a split at the hook on OP Sepolia.** No deployment there; the split fails and its tokens are burned.
- **Sending a payout before `deployPool`, or in another token.** Reverts `InvalidStageForAction` / `InvalidTerminalToken`; Core returns the payout to the project's balance.
- **Using a payout group other than the token's.** `groupId != uint256(uint160(token))` reverts `InvalidSplitGroup`.
- **Reading `tokenIdOf`, `activeTickLowerOf`/`UpperOf`, or calling `rebalanceLiquidity` on 1.5.0.** Removed. Use `askTokenIdOf`/`bidTokenIdOf` and `addLiquidity`.
- **Expecting fee remainders to stay in the hook.** Terminal-token remainders go to the project's balance and project-token remainders are burned; only failed routes fall back to the ledgers. The fee project's tokens sit in `claimableFeeTokens` until the owner calls `claimFeeTokensFor`.
- **Reading `context.token` to find the project token.** The hook resolves `JBTokens.tokenOf(projectId)`.
- **Assuming `addLiquidity` always mints.** An empty corridor holds (reverts `EmptyCorridor` if nothing was live); spot past both corridor ends with the wrong inventory reverts `NoDeployableLiquidityAtSpot`; a cold oracle reverts `TwapUnavailable`; spot more than 200 ticks off the 30-minute TWAP reverts `PriceDeviationTooHigh`.
- **Treating `LiquidityAutomationFailed` as lost funds.** The intake is ledgered; call `deployPool` or `addLiquidity` with enough gas.
- **Deriving `deployHookFor`'s address from the raw salt.** The clone salt is `keccak256(abi.encode(msg.sender, salt))`; a different caller lands on a different address.
