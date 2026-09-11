# Router gateway and buyback rollout

Use `shared/chain-config.json` as generated deployment data, then resolve each project's runtime selections. `contracts` preserves canonical names and all `_deprecated*` records; `deploymentInfo` supplies the deployed package version, generation label, ABI path, block, and transaction. A canonical artifact is the latest recorded deployment on that chain, not proof that every project selected it. Use executed records rather than proposal-derived addresses, and keep each chain's deployment evidence separate. Regenerate after each executed chain using `scripts/gen-chain-config.py <deploy-all-v6/deployments>`; `--check` verifies data and rollout ABIs.

## Rollout state

Production deployment records now include buyback 1.4.0, router/gateway 1.3.0, and the ratio feed on Ethereum, Optimism, Base, and Arbitrum. The same stack is recorded on Sepolia, Base Sepolia, and Arbitrum Sepolia. OP Sepolia has the ratio feed but no buyback hook, router, or gateway, and its registry default remains zero. Read `deploymentInfo` to distinguish these deployments from the retained 1.1.1 and v1 generations; an available canonical contract does not change an existing project selection. Verify current `JBPrices` registration and feed liveness before relying on a conversion.

On upgraded chains the registry default and project #1 moved to the gateway/new hook. Projects #2–7 keep their previous selections until operators migrate them; disallowing a generation prevents new selections but does not erase existing ones. The new router itself is not registry-selectable; choose its gateway. `_deprecated.json` keeps v1 (1.0.x); `_deprecated1.json` keeps the previous 1.1.1 generation once a chain upgrades. Before that, the 1.1.1 generation remains under the canonical filename. Keep every generation in transaction decoders, labels, and activity queries.

## Resolve payments and quotes

1. Read `JBDirectory.primaryTerminalOf(projectId, token)` for the directly called terminal. A zero address is no registered route.
2. If calling the router registry, read `terminalOf(projectId)`, including cohort defaults and explicit overrides. A zero resolution is unavailable.
3. If the resolved terminal is a deployed gateway, read `ROUTER()` for the downstream router. Existing project overrides may resolve directly to a retired router.
4. Compute router `pay`/`cashOut` quote IDs from that router. Permit2 spender and metadata IDs use the contract called directly, usually the registry. Resolve `JBBuybackHookRegistry.hookOf(projectId)` for buyback metadata IDs and pool views.

Never infer a project's route from `defaultTerminal()` alone or replace an existing retired selection with the newest artifact. A disallowed router/hook can still resolve for its already-bound projects.

## Buyback quotes and TWAP

Always encode the pay quote as `abi.encode(uint256 amountToSwapWith, uint256 minimumSwapAmountOut, bool skipSplits)`, keyed by `getId("pay", resolvedHook)`. The 1.4.0 hook decodes all three words and reverts on two; older two-word decoders tolerate the trailing word. `skipSplits = false` preserves reserved-token participation for purchased tokens; `true` opts out where supported. An explicit nonzero minimum remains a hard settlement guarantee. A TWAP-derived floor is a routing hint: if the swap misses it, 1.4.0 unwinds the swap and mints instead.

Project #1's upgraded pool window is 1,800 seconds. Pool registration on 1.4.0 maps the maximum-window placeholder to 30 minutes; `setTwapWindowOf` honors an explicitly chosen 2-day window. Read `twapWindowOf(projectId, token)` instead of assuming a global window.

To migrate an existing project, check its locks and operator permissions, call `setHookFor(projectId, newHook)` and `setTerminalFor(projectId, gateway)`, and configure/verify the pool on the selected hook. Present and simulate concrete operator transactions; no automatic migration or unlocking is implied.

## Retained calls and custody

`JBRouterTerminalGateway` takes custody of the original input before calling its immutable router. Eligible failed fee/protocol calls remain in the gateway instead of letting core catch and forgive a failed fee payment. A successful outer transaction and a zero returned token count can mean pending custody, not destination settlement.

Retention requires metadata of exactly 32 bytes encoding a nonzero source project ID; a `pay` additionally requires `minReturnedTokens == 0`. Framed `JBMetadataResolver` metadata is not this opt-in. Memos above 4,096 bytes do not retain. Source-project token payouts are excluded because that project cannot account for its own token; non-fee payout splits from a registered source terminal also fail synchronously so core can restore them. Preserve ordinary user minimums rather than making payments eligible for delayed settlement.

Use `shared/abis/JBRouterTerminalGateway.json` (or the generation-specific ABI from `deploymentInfo`). The complete pending-call tuple, in ABI order, is:

```solidity
struct JBPendingRouterTerminalCall {
    uint256 amount;
    bool preferAddToBalance;
    bool shouldReturnHeldFees;
    address beneficiary;
    uint256 projectId;
    address refundTo;
    uint256 sourceProjectId;
    address token;
}
```

- `pendingCallCount()` is the total number of issued IDs, not the open backlog.
- `pendingCallCommitmentOf(id)` is `keccak256(abi.encode(call, memo, metadata))`; zero means no pending custody under the ID.
- `pendingCallFailureOf(id)` returns `(bytes32 errorHash, uint32 count, uint48 lastFailureAt, uint64 highestGasLimit)`.
- `JBRouterTerminalGateway_QueuePendingCall` supplies the exact tuple, memo, metadata, and initial failure fingerprint. Store these event fields because the contract stores only the commitment.
- `processPendingCall(id, call, memo, metadata)` retries permissionlessly. `processPendingCallWithGas(id, call, gasLimit, memo, metadata)` supplies an expanded budget. After enough qualified matching failures, use `finalizePendingCall` or `finalizePendingCallWithGas` with the same argument order.
- The initial queue event does not count as a qualified failure. The first qualified retry can run immediately; later counted failures and finalization wait `RETRY_DELAY()` (one day). `FINALIZATION_FAILURE_COUNT()` is three. Gas-exhaustion retries must escalate their qualified budget; consult `QUALIFIED_CALL_GAS()`, `maximumQualifiedCallGas()`, and the failure state rather than hardcoding retry gas.
- Finalization makes one last qualified attempt. Success settles; the same failure class refunds to the source project's current accounting terminal; a changed failure class restarts the streak and keeps custody pending. Refunds do not go to an arbitrary retry caller.
- Index `JBRouterTerminalGateway_ProcessPendingCall`, `JBRouterTerminalGateway_RefundPendingCall`, and `JBRouterTerminalGateway_RecordTerminalCallFailure`. Track chain, gateway, ID, original token/amount, source/destination projects, qualified failure state, and settlement/refund transaction. Report queued, retried, settled, and refunded separately.

## Ratio feeds

`DeployBuybackFloorFix._usdcPerNativeFeedCtorArgs` constructs `JBRatioPriceFeed(ethUsdFeed, usdcUsdFeed)`: USD per native token divided by USD per USDC, producing USDC per native token/ETH. `_ensureUsdcPerNativeDefaultFeeds` registers it at project 0 with the token-derived USDC currency as `pricingCurrency`, and native (61166) or ETH (1) as `unitCurrency`. This is the direct lookup used by USDC payments; using the reciprocal registration would lose precision when a six-decimal quote is rounded before inversion. `JBPrices` derives the opposite directions by inversion. This completes the conversion needed for USDC payments into ETH-based projects and mixed-balance cash outs. The feed's address differs per chain. Its legs enforce staleness and sequencer checks, which propagate through the ratio; `JBPrices` still needs a live feed and does not perform arbitrary two-hop routing.

Look up `chains[chainId].contracts.JBRatioPriceFeed`; absence means no recorded rollout feed. Probe `JBPrices.pricePerUnitOf` for each needed pair before launch or payment, even when an artifact exists, to verify registration and liveness.
