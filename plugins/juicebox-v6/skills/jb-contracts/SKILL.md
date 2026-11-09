---
name: jb-contracts
description: |
  Juicebox V6 contract inventory — every deployed contract, its role, and its address on
  the 8 supported chains. Use when: (1) resolving a contract address on any chain,
  (2) deciding which contract handles a task (payments, rulesets, tokens, splits, NFTs,
  cross-chain bridging, loans, publishing), (3) building cast/viem calls against Juicebox,
  (4) checking whether a contract exists on a given chain.
metadata:
  version: "6.0.0"
---

# Juicebox V6 Contract Inventory

Juicebox V6 has a single contract set: one `JBController`, one `JBMultiTerminal`, one `JBRulesets`. Every project uses the same set — no per-project contract resolution beyond `JBDirectory` terminal lookups.

**Address rules:**
- Core contracts are deployed via CREATE2 and share **one address on every chain**. Tables below marked "chain-same" list that single address once.
- Chain-specific contracts (CCIP suckers, Chainlink price feeds, `JBUniswapV4Hook`, testnet project instances) differ per chain — per-chain tables or a pointer to the config are given below.
- The only address source is `shared/chain-config.json`. Never hand-type addresses from docs, explorers, or memory.

## Chains

| Chain | ID | Testnet |
|---|---|---|
| Ethereum | 1 | no |
| Optimism | 10 | no |
| Base | 8453 | no |
| Arbitrum | 42161 | no |
| Sepolia | 11155111 | yes |
| Optimism Sepolia | 11155420 | yes |
| Base Sepolia | 84532 | yes |
| Arbitrum Sepolia | 421614 | yes |

## Core protocol (chain-same, all 8 chains)

| Contract | Address | Role |
|---|---|---|
| JBController | `0x3fcec3572e84b624477bcff4e2cf1f7deab648f1` | Project lifecycle orchestrator: launch projects, queue rulesets, mint/burn tokens, deploy ERC-20s, send reserved tokens |
| JBDirectory | `0x5aff29060e023e6fb87be5596652b33c65af535b` | Routing table: which terminals accept a project's payments, which controller manages it |
| JBProjects | `0x6017d1fba9dc279bfa0b03fd931c22e242ab3691` | Project ERC-721s; `createFor` mints, token ID = project ID protocol-wide |
| JBRulesets | `0x26f2228a4e8b0079ed1c2a3d22f12ff7f83cdfba` | Stores and queues rulesets (weight, cash-out tax, reserved rate); weight decays via `weightCutPercent` |
| JBTokens | `0x1f80d8f057ee36b4c2656d107e4e4558b71ba7d9` | Dual-token accounting per project: internal credits plus claimable ERC-20; `totalSupplyOf` = credits + ERC-20 supply |
| JBERC20 | `0x6db9cf17222d8de2012fe13b9fa5bb7981fa0b17` | Project ERC-20 implementation (ERC20Votes + Permit); cloned via `JBController.deployERC20For` |
| JBSplits | `0x28b3d11fcb8d2ad0a143c5b193cd9f2e4d43f4c3` | Payout/reserved-token split groups; shares are fractions of 1,000,000,000; splits lockable until a timestamp |
| JBPermissions | `0xf92ac1ab5a00033e35a3975739124f61928c36b0` | Operator permissions as packed uint256 bitmaps; project 0 = wildcard; ROOT (ID 1) grants all |
| JBPrices | `0xad45e4627f068d1e6b21e5301870d807543a8401` | Currency conversion from append-only project + default price feeds; inverse prices derived at read time |
| JBFundAccessLimits | `0xc93360158f187fc8fc8f1062a1b31d06f185dbab` | Payout limits + surplus allowances per ruleset; empty groups = zero access, not unlimited |
| JBFeelessAddresses | `0x657d0e588fca6f8c49394c9ca8a1cf6505b10314` | Registry of addresses exempt from the 2.5% protocol fee; project 0 = feeless everywhere |
| JBTerminalStore | `0x7497ae014a60561925b51c0a3b4ade7460b9927c` | Accounting engine behind terminals: balances, limits, tokens-per-payment, cash-out bonding curve |
| JBMultiTerminal | `0x130f5dd2bd8805443cf41755253d778a75a67f53` | Main money terminal: pay, cash out, payouts, surplus allowance; 2.5% fee held 28 days; Permit2 support |
| JBHeldFees | `0x62e77076b6e902e7aec8b2925acc9b46058e3d38` | External library (DELEGATECALL from JBMultiTerminal) for held-fee storage; not a standalone contract |
| ERC2771Forwarder | `0x3ba60b60933916a7c87d0860dcee62a0ce34e3e2` | OpenZeppelin trusted forwarder for meta-transactions across the protocol |
| Permit2 | `0x000000000022d473030f116ddee9f6b43ac78ba3` | Canonical Uniswap Permit2; `JBMultiTerminal` pulls ERC-20 payments through it when `pay` metadata carries a Permit2 allowance |
| JBOmnichainDeployer | `0xb853758a70a6b4216c09f1d071ea2344aba0a34f` | One-transaction deployer for omnichain projects (project + 721 hook + suckers); inserts itself as ruleset data hook to coordinate cross-chain supply/surplus |

## Terminals, registries, periphery (chain-same)

| Contract | Address | Role |
|---|---|---|
| JBRouterTerminal | `0xa0b7b55e87c781f47bda8d40f8381cb746eb0e37` | Universal terminal: accepts any token and converts to the destination project's accepted token via direct forwarding, Uniswap V3/V4 swaps (V4: hookless pools and pools on this chain's JBUniswapV4Hook 2.0.0 only), or recursive cash-outs; bound to buyback hook `0x80717f…`. Absent on OP Sepolia |
| JBRouterTerminalGateway | `0xe2c259b2fcfd2d57ebcda9b3d2d10bdb1b2cd977` | The registry's default router terminal for projects created after the 2026-11 rollout (older cohorts resolve to the 1.3.0 gateway `0x4a56aef5b6a5b9742abb02ca67c5a85ba183d901` in front of router `0x62e2fe718ca3008a6a322deec9903286463f1add`; call `registry.terminalOf`): forwards each call atomically into JBRouterTerminal; when the route fails and the caller opted in, it keeps the input token for a permissionless retry or refund. Absent on OP Sepolia |
| JBRouterTerminalRegistry | `0xe0427f250fdb0379c8e98e884ee4570521208cbc` | Per-project router-terminal selection with owner-managed default; choices lockable |
| JBAddressRegistry | `0x581bfd1ead279e0a27b736e49494db3a7d85993c` | Records who deployed a contract (create or create2); used to verify hooks come from trusted deployers |
| JBProjectHandles | `0x726f4a3dfd2fb8297f8ab98d215b42a92d8eefe8` | Bidirectionally-verified ENS handles for projects (ENS text record `juicebox` = `chainId:projectId`) |
| JBProjectPayer | `0x0de147532f522fe9f4559bd7f34774786424176e` | Payment-relay implementation: forwards received ETH/ERC-20 to a project treasury; cloned per use |
| JBProjectPayerDeployer | `0x7321740fd0dcf73dd3e2aa8fc060454abfce9517` | Deploys JBProjectPayer EIP-1167 clones |
| JBProjectPayer__ProjectCreationFeeReceiver | `0xe6d6819374c43085caa26cec5cbd19aff5d5f19f` | The JBProjectPayer clone that `JBProjects` forwards creation fees to; routes them via `pay` into project #1 |

## Hooks

### 721 tiers hook (chain-same)

| Contract | Address | Role |
|---|---|---|
| JB721TiersHook | `0xf4a5887170e4d7efb1c874ad88fc82ebf076b5ab` | Tiered NFT pay/cash-out hook implementation; mints tier NFTs on payment; cloned per project |
| JB721TiersHookDeployer | `0xb7b8ec35e2dd84afff04ee769c6189e7a4d44a78` | Deploys JB721TiersHook clones for existing projects; registers them in JBAddressRegistry |
| JB721TiersHookProjectDeployer | `0x3ffdc94e7f1de4b74c52158ec9dd3b965585f451` | Creates project + 721 hook + rulesets in one transaction |
| JB721TiersHookStore | `0x69913acf79dbba170d9efafe605ee62b42164f9c` | Shared data store for all 721 hooks: tiers, mint counts, reserves, voting units; keyed by hook address |
| JB721Checkpoints | `0x91ff7f888ffe0f7d71f98dcd8f4a70ccaf51d59b` | IVotes-compatible checkpointed voting power for a 721 hook; implementation cloned per hook |
| JB721CheckpointsDeployer | `0x76a97eeb5602a51ac2067d925269e0f9a0bd296b` | Deploys JB721Checkpoints clones |
| Banny721TokenUriResolver | `0x70d28338226e61a442ef516c731d371d13c9c6df` | On-chain SVG composition for Banny NFTs: bodies, backgrounds, lockable outfits |

### Buyback hook (chain-same)

| Contract | Address | Role |
|---|---|---|
| JBBuybackHook | `0x80717f09461a3fb08364fe8c5259220f7d06e0af` | Buys project tokens from a Uniswap V4 pool when cheaper than minting; sells on cash-out when the pool beats the bonding curve; TWAP-guarded; trades only pools keyed to this chain's JBUniswapV4Hook 2.0.0. The 1.4.0 hook `0xb222da5a71e8fb89a5a38b7c920eab5dfbc74b91` still serves unmigrated older projects (no longer allowed for new pins). Absent on OP Sepolia |
| JBBuybackHookRegistry | `0x72f55a54cd53410a5ff175508a5a384227081788` | Maps projects to their buyback hook; terminal data hook that forwards pay/cash-out calls; default-hook cohorts by project creation time |

### Uniswap V4 (JBUniswapV4Hook is per-chain; rest chain-same)

`JBUniswapV4Hook` 2.0.0 — fills buys from the pool while it beats issuance and mints the rest through the project's terminal; sells through the best of pool, cash-out, or a split, each quoted exactly; also the TWAP oracle the buyback hook reads. Quote through Uniswap's V4 Quoter (`estimateUniswapOutput` is gone). Its address differs on every chain (Uniswap V4 hook addresses encode permission flags, so each chain gets its own mined address):

| Chain | JBUniswapV4Hook |
|---|---|
| Ethereum | `0x41a50be8b4b63e968ab83227bc73330c5d1215c8` |
| Optimism | `0x850ec1a2adcb2126d823632e60441de2926fd5c8` |
| Base | `0xb436cedbee8f191a3860719b4b0f474434f315c8` |
| Arbitrum | `0xa7477af9d209daf3e34d376d500ec82539b755c8` |
| Sepolia | `0x3f365e7c021c957747b870d8800547140d04d5c8` |
| Base Sepolia | `0x2ca71b1ce365b571ce24cb57577a4a645dcc15c8` |
| Arbitrum Sepolia | `0x23d9ab653d95aa60e660015d80c9a112374ed5c8` |
| Optimism Sepolia | not deployed |

Pools created before the 2026-11 rollout live on the 1.1.2 hook (`JBUniswapV4Hook_deprecated1` in deploy-all). A V4 pool's hook is fixed for life, and the current router and buyback hook do not see these pools:

| Chain | Old 1.1.2 JBUniswapV4Hook |
|---|---|
| Ethereum | `0xd81ece6cf73b18a1b109e48c86ffdbd284f6d5c8` |
| Optimism | `0xae18f78eadfa5addda9026e1ab835381cfdf55c8` |
| Base | `0xf70b71605f1c0a8ff7580557645bb7e29fe495c8` |
| Arbitrum | `0xd21ba44c9c833ccaf70795af7bf00719aa7455c8` |
| Sepolia | `0x7494930fbfa2fdd06549526c805d48b4f22a15c8` |
| Base Sepolia | `0xf7ce556c8c10cff2c8da6ea521c6232598f7d5c8` |
| Arbitrum Sepolia | `0xd27bd395dfb5741a7cc66df836e3039c563955c8` |

| Contract | Address | Role |
|---|---|---|
| JBUniswapV4LPSplitHook | `0x5b54156b4a68ba5f9fa7706b913045e597e45e74` | Split-hook implementation that turns reserved-token distributions into a Uniswap V4 LP position; cloned per project. Absent on OP Sepolia |
| JBUniswapV4LPSplitHookDeployer | `0xad2ed0024647ccc2eda4e42dc616d6fe886ed028` | Deploys LP split hook clones (optional CREATE2 salt). Absent on OP Sepolia |
| JBUniswapV4LPSplitHookMath | `0x03fa7fbf4bacc4495f44fec35fbcc00e63f790ad` | Linked library: Juicebox-price → Uniswap-tick math kept outside the hook's bytecode; not standalone. On OP Sepolia (the only LP artifact there) it is `0xef2242dc7e8a082ce00c943548e414598896c4f4` |
| JBP6FeeLPSplitHook | `0xef8993f50363461007bed2f54e98bbef9854148a` | The shared LP split hook clone projects point reserved splits at (1.5.0 clone of the implementation above; `feeProjectId` 1, `feePercent` 1000 bps = 10%). Older instances keep their own ABI: 1.3.0 `0xe9493bc776699714a89aa982cf828d843f040d2a` (20%), and 1.0.0 `0x22988374af49507fec1ee78811fbc47d10d5e639` that BAN's reserved split uses; see jb-lp-split-hook. Absent on OP Sepolia |

## Suckers (cross-chain bridging)

| Contract | Address | Role |
|---|---|---|
| JBSuckerRegistry | `0x7903a854ae91eaf635430d120a1a434085cef297` | Deploys/tracks/governs suckers; deployer allowlist; `toRemoteFee`; aggregate remote balance/surplus/supply views. All 8 chains |
| CCIPHelper | `0x8f1a249e79030d4fac2102aa33e36e6676e048e4` | Library of CCIP chain constants; not standalone. All 8 chains |

**Native bridge suckers** — chain-same address, deployed only on the chains they connect:

| Contract | Address | Chains |
|---|---|---|
| JBOptimismSucker | `0x8c3b3d0fe56b31850a000333ef16195dbcd5a806` | Ethereum, Optimism, Sepolia, OP Sepolia |
| JBOptimismSuckerDeployer | `0x298a775c030adcedb641a89d9047ec9972674e1a` | same as above |
| JBBaseSucker | `0x2fc1f6e8010e7a6198da9465931cce8d0c52e788` | Ethereum, Base, Sepolia, Base Sepolia |
| JBBaseSuckerDeployer | `0x54140331902de5c3445eb0c26e15099a5a9d59e6` | same as above |
| JBArbitrumSucker | `0xf044d9f16c4bce21bd75227561bb3d1838ce8651` | Ethereum, Arbitrum, Sepolia, Arbitrum Sepolia |
| JBArbitrumSuckerDeployer | `0xa12ebfca3d4e0810e4ed174e4c08277c26917acb` | same as above |

Roles: `JBOptimismSucker` bridges project tokens + terminal funds over an OP Stack bridge (`JBBaseSucker` is the same code pointed at Base's bridge); `JBArbitrumSucker` uses Arbitrum's native Inbox/Outbox + Gateway Router.

**CCIP suckers** — `JBCCIPSucker__<REMOTE>` / `JBCCIPSuckerDeployer__<REMOTE>` bridge to the chain named in the suffix (`ETH`, `OP`, `BASE`, `ARB`, plus `_SEP` variants on testnets) via Chainlink CCIP. Each chain carries one pair per peer chain (e.g. Optimism has `__ETH`, `__BASE`, `__ARB`). **Addresses vary per local chain** — read them from `shared/chain-config.json`.

## Revnet (chain-same, all 8 chains)

| Contract | Address | Role |
|---|---|---|
| REVDeployer | `0xb552eb94284f94b833837d4b2cbb237128415d4e` | Deploys revnets (autonomous projects with immutable staged tokenomics); holds the project NFT so nobody can change the rules |
| REVLoans | `0x056265c31157748818f0910d1859acd2f7d427de` | Borrow against revnet tokens instead of cashing out; collateral burned on borrow, re-minted on repay; loans are ERC-721s; prepaid-fee model |
| REVOwner | `0x2ba4705ad0332cdfb299b452068438bcba3faaf3` | Runtime data hook for every revnet: coordinates 721 + buyback hooks at pay time, aggregates cross-chain supply/surplus (incl. loans) at cash-out time |

## Croptop (chain-same, all 8 chains)

| Contract | Address | Role |
|---|---|---|
| CTDeployer | `0xf21b8717cb50e497e90f375ec532557dd9022655` | Deploys projects pre-configured for Croptop permissionless NFT publishing |
| CTProjectOwner | `0x327a411a797ebdfba2ac7bf3cb3ee53143df812a` | Dead-end project owner: locks project ownership forever while keeping Croptop posting alive |
| CTPublisher | `0xcbc84cf9b0293efe3ac7dd1bea128a404f2e6a1c` | Publishing engine: anyone posts NFTs to a project's 721 hook subject to owner-set criteria; 5% fee to the fee project |

## Defifa (2.0, chain-same, all 8 chains)

Two game types side by side: ERC-721 (`DefifaHook`, one NFT per position) and ERC-1155 (`Defifa1155Hook`, one balance per tier). Each type has its own deployer and governor; both share one tiers store, one token URI resolver and one voting referee. Phases: COUNTDOWN → MINT → REFUND → SCORING → COMPLETE, or NO_CONTEST (min participation not met or no scorecard ratified within `scorecardTimeout`; refunds at mint price).

| Contract | Address | Role |
|---|---|---|
| DefifaDeployer | `0x32cd7d0c378a45a27cd7e361bce0ba882efe87a9` | Launches ERC-721 games (`launchGameWith`), clones `DefifaHook`, names each game's referee in the governor, fulfills post-game fee commitments |
| DefifaHook | `0x65aa6c2105060515259a460a4fad2b3eb3577db8` | ERC-721 game-piece hook implementation, cloned per game: phases, delegation, `firstOwnerOf`, cash-out weights |
| DefifaGovernor | `0xd8debb4e66c11cd72643e450b3beaced73ff7b78` | ERC-721 games: accepts scorecards only from each game's referee, holds the pending one through the timelock, then anyone ratifies. Counts no votes |
| Defifa1155Deployer | `0x7a62383b50aaa8b212bd965c426490625068ba80` | Same `DefifaDeployer` code wired to `Defifa1155Hook` and `Defifa1155Governor` |
| Defifa1155Hook | `0x9214c2a673c6fc1a82a6ccc8d0b9f5dc2d11d4c3` | ERC-1155 game-piece hook implementation, cloned per game: one token ID per tier, so large entries mint in one transfer |
| Defifa1155Governor | `0x53eede0488861cb6c7c643cd77d7f92f4ede2879` | Same `DefifaGovernor` code for ERC-1155 games |
| DefifaVotingReferee | `0xf6552cc178042e9ed13c768929983e7d93254640` | Sample referee for both game types: anyone submits, holders attest with BWA power (`attestToScorecardFrom`), once a scorecard reaches its submission-time quorum (`quorumOf`, 50% to 75%) after the grace period, anyone forwards it to the governor (`forwardScorecardFor`); the first forwarded wins |
| DefifaTiersHookStore | `0xf65dd3adbac3d776cfa025458cac730aa52adb7d` | `JB721TiersHookStore` plus count-based records (`recordMintCounts`, `recordBurnCounts`, count `recordTransferForTier`); shared, required by the ERC-1155 hook |
| DefifaTokenUriResolver | `0xe876dfd954f827fde02d7211717a350478b3861e` | Onchain SVG game-card metadata, shared by both game types |
| DefifaHookLib | `0x71590c5e91b4bbed7c6996fdf446b817d2f3c82f` | Linked library: validation and weight rules shared by both hooks |
| Defifa1155HookLib | `0xd4b4fd661538c235a0935d8135487ede98d52728` | Linked library: ERC-1155 ID and amount logic; calls `DefifaHookLib` |

A game's referee is any address (person, multisig or contract); a game is as safe as its referee. Scorecard state: governor QUEUED → SUCCEEDED → RATIFIED (or DEFEATED if replaced); voting referee PENDING → ACTIVE → SUCCEEDED → RATIFIED | DEFEATED.

Defifa 1 games keep their own contracts and ABI (`*_deprecated` in deploy-all): DefifaDeployer `0x375afb2a4b1cadae99f8863f96fc1aebcbaf8bde` (mainnets) / `0xbfa54a97099485c134f06c9a08a4909c26fd7318` (testnets), DefifaHook `0xe2229dd6a7da99ebb8f7d749612edd1b2addafe1` (mainnets) / `0x3184783d0e3cbf5a821794b246c71a3d1a0cf312` (testnets), and chain-same DefifaGovernor `0xa0cefa58fd913c1838c39b2c3d0b08eb7f5d6d53`, DefifaTokenUriResolver `0x3c2263d4237f584506bba1b775d11a69555845de`, DefifaHookLib `0xa095f42fb3ba805a7ac899988fc6d77afed09df5`.

## Price feeds and deadlines

Chain-same on all 8 chains:

| Contract | Address | Role |
|---|---|---|
| JBMatchingPriceFeed | `0xa37213cbc60cdc9111849d31536471a0f084ece0` | Trivial 1:1 feed for same-currency payout limits |
| JBDeadline3Hours | `0xd25264015483caa5c34643942d41f94bed5f1e92` | Ruleset approval hook: rejects rulesets queued <3h before the current one ends |
| JBDeadline1Day | `0x3a15ac0bcf4f7dd48359a36b3e293254cf26d4ca` | Same, 1-day notice |
| JBDeadline3Days | `0xcda708c98fbdd15a7ff7f0c5c50f9371ca52c78f` | Same, 3-day notice |
| JBDeadline7Days | `0x540923f7b6166bf9713490719a2210aeebc9fca2` | Same, 7-day notice |

Chainlink feeds are per-chain. Two families: `JBChainlinkV3PriceFeed__*` (staleness/negative/incomplete-round checks — Ethereum + all testnets) and `JBChainlinkV3SequencerPriceFeed__*` (adds L2 sequencer-uptime grace period — L2 mainnets only):

| Chain | ETH_USD | USDC_USD |
|---|---|---|
| Ethereum | `0xc60d1f83e6e116f2621c331885634e13e5e8e008` | `0x58be5fc7076e405ed7f10b15a636be576a1cc341` |
| Optimism (sequencer) | `0xb5dacddc67b7c36dae9166cdf5fcf61388d76f47` | `0xf4318bbcbdb98516f4e133e5f5d17764cce98d5d` |
| Base (sequencer) | `0x79ab3a63920a47bc9e0f0e4aec201663ffe83102` | `0x5896aaf909cf6829704dfc1ddb14ac5d9f755592` |
| Arbitrum (sequencer) | `0x2467973afef252612c602dad3d4a03cb9a8368ea` | `0xe61f419e86530c5e626382578302295932450801` |
| Sepolia | `0xa5f6f2a2abc1d4712d3c3eb2b46cccc974095f6f` | `0x24c73c0be8130eff157cdb8cfc0bd33fc33a76ca` |
| Optimism Sepolia | `0xe66f4648bae4b43225f64ed0af1c94eaad776e52` | `0x974a8cf0ce0443c59b662b4087459e1c9b184280` |
| Base Sepolia | `0xeeb6784193659320ec5361821217fcf9bb53fb28` | `0x5696a3785b721757a3343dbfcf6e2433837512c4` |
| Arbitrum Sepolia | `0x68b4e18b141553801b2632f244ae7e64e9f11d56` | `0x77c8b5431764499f64f281ebbccf5f7e7604548f` |

`JBRatioPriceFeed` (USDC per native: the ETH/USD feed over the USDC/USD feed) is per-chain and is the project-0 default for USDC priced per native token and per ETH:

| Chain | JBRatioPriceFeed |
|---|---|
| Ethereum | `0x3fa39399bbc752418ee7e16addeb0b95d6386943` |
| Optimism | `0xedb20e9963b22bcd3b0652b246aac2c222510d36` |
| Base | `0x3c2f3742785b0dec9bbb401de6615b70f740e4ca` |
| Arbitrum | `0xa588449291852a49962276d75a25d51d8e285469` |
| Sepolia | `0xbfcd029ee4e8a550409e65b5e2eca4f21de30c94` |
| Optimism Sepolia | `0x866aea0a4dba3d191790b68d564e96f1dd4d1f49` |
| Base Sepolia | `0x552da193c58a71d8ad9f354f7d09b29f79c12422` |
| Arbitrum Sepolia | `0xda4bbf677ba6f1f70054bd2bd6240d839141027d` |

## Project-instance contracts

Live clone instances for well-known projects. Each has one address across all mainnets and a different address across all testnets:

| Contract | Mainnets | Testnets | What it is |
|---|---|---|---|
| JBERC20__ProjectNANA | `0x6b50843c88290c180df24c445e37b296d9760fa8` | `0x9c0948f4d1aebd02737a942607c7e4b44cb5312d` | NANA token (project #1, the protocol fee beneficiary) |
| JBERC20__ProjectREV | `0x3dd82a891c80db068e95708e83583d626e2c1fac` | `0x47e77032858c6b0201b2d53f19715a7a1372d400` | REV token |
| JBERC20__ProjectBAN | `0xdb34ab144007b0a2a2a78a5af30d750407c68778` | `0x7b65cff06ff28bf6383a25375bb81500441cf93a` | BAN token |
| JBERC20__ProjectCPN | `0x8a062be5d7fbb645c8cec216b2210c7b1bfeb3ed` | `0x8b122b7dd707f83b639a578bc0c81e75c55d34bd` | CPN token |
| JBERC20__ProjectDEFIFA | `0x13925909b15ac8e4b2768b5180cc766826556869` | `0xa2da5473b7db14eeb73f7d01aaee826ed053b3f1` | DEFIFA token |
| JBERC20__ProjectMARKEE | `0xf6627cf19317c33b457f77452876e6e297c4942f` | `0x74a84087a523313d5e1dd5fad415c2dab2f83fa6` | MARKEE token |
| JBERC20__ProjectART | `0x44c4516768e47cd97cff2561b81a74699f23f8ec` (Base only) | `0xc48a486da5257ae506ee4cddeb4bcd2a44e6a9e0` (Base Sepolia only) | ART token — Base + Base Sepolia only |
| JB721TiersHook__ProjectBAN | `0x37e35937ecf949d7a44a9fe878107de264618b8f` | `0xe2193b4375a4a1e77fbf120699742ef0107f6084` | BAN project's 721 hook clone |
| JB721TiersHook__ProjectCPN | `0x779957e5376571adaf544e63ffc8404e98f30d30` | `0x2b70edc0b7db710f7d8708c6240d6fa9e62b71f5` | CPN project's 721 hook clone |

## Chain gaps

- **Optimism Sepolia** lacks all Uniswap V4-dependent contracts: `JBUniswapV4Hook`, `JBUniswapV4LPSplitHook`, `JBUniswapV4LPSplitHookDeployer`, `JBP6FeeLPSplitHook`, `JBBuybackHook`, and also `JBRouterTerminal` and `JBRouterTerminalGateway`. It still has `JBBuybackHookRegistry`, `JBRouterTerminalRegistry`, and `JBUniswapV4LPSplitHookMath`.
- **JBERC20__ProjectART** exists only on Base and Base Sepolia.
- Native suckers exist only on the chain pairs they bridge (see table above). CCIP suckers exist on each chain only for its actual peers.

## Constants

| Constant | Value |
|---|---|
| `JBConstants.NATIVE_TOKEN` | `0x000000000000000000000000000000000000EEEe` |
| Protocol fee | 25/1000 = 2.5%, paid to project #1 (NANA) |
| Split share denominator | 1,000,000,000 |
| `JBProjects.MAX_CREATION_FEE` | 0.001 ether; `createFor` is payable and `msg.value` must equal `creationFee()` exactly |
| Permission IDs | `JBPermissionIds` library (nana-permission-ids), `uint8` values 1–39; ROOT = 1 grants everything for the scoped project |

## Common mistakes

- **Hand-typing addresses.** `shared/chain-config.json` is the only source. Docs pages, explorers, and remembered addresses drift.
- **Assuming `JBUniswapV4Hook` is chain-same.** It is the only member of the shared suite with a different address on every chain (Uniswap V4 hook addresses encode permission flags). Always look it up per chain.
- **Using a mainnet address on a testnet** for `JBERC20__Project*`, `JB721TiersHook__Project*`, or the Defifa 1 `DefifaDeployer`/`DefifaHook`. These have separate mainnet/testnet addresses. Defifa 2.0 contracts are the same on every chain.
- **Expecting Uniswap-dependent contracts on OP Sepolia.** `JBUniswapV4Hook`, LP split hooks, `JBBuybackHook`, and `JBRouterTerminal` are not deployed there.
- **Misreading CCIP sucker names.** The suffix names the *remote* chain: `JBCCIPSucker__ETH` on Optimism bridges Optimism↔Ethereum. Its address differs on each local chain.
- **Calling implementations instead of instances.** `JBERC20`, `JB721TiersHook`, `JB721Checkpoints`, `JBProjectPayer`, `JBUniswapV4LPSplitHook`, `DefifaHook`, and `Defifa1155Hook` at the addresses above are implementations that get cloned. A live project's token is at `JBTokens.tokenOf(projectId)`, not at the `JBERC20` implementation address.
- **Calling libraries as contracts.** `JBHeldFees`, `JBUniswapV4LPSplitHookMath`, `CCIPHelper`, `JBPayoutSplitGroupLib`, `JBSuckerLib`, `JBCCIPLib`, `JB721TiersHookLib`, `DefifaHookLib`, and `Defifa1155HookLib` are DELEGATECALL-linked libraries, not standalone entry points.
- **Paying `JBMultiTerminal` without checking the directory.** Resolve `JBDirectory.primaryTerminalOf(projectId, token)` first — a project may route through `JBRouterTerminalRegistry` or accept different tokens per terminal.
- **Using `address(0)` for native ETH.** The protocol's native-token sentinel is `0x…EEEe` (`JBConstants.NATIVE_TOKEN`).
- **Sending the wrong creation fee.** `JBProjects.createFor` reverts unless `msg.value` equals `creationFee()` exactly — query it first.
