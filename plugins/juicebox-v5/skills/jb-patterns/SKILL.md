---
name: jb-patterns
description: Common Juicebox V5 design patterns for vesting, NFT treasuries, and governance-minimal configurations. Prefer native mechanics over custom code.
---

# Juicebox V5 Design Patterns

Proven patterns for common use cases using native Juicebox mechanics. **Always prefer configuration over custom contracts.**

## Golden Rule

> Before writing custom code, ask: "Can this be achieved with payout limits, surplus allowance, splits, and cycling rulesets?"

---

## Pattern 1: Vesting via Native Mechanics

**Use case**: Release funds to a beneficiary over time (e.g., team vesting, milestone-based releases)

**Solution**: Use cycling rulesets with payout limits

### How It Works

| Mechanism | Behavior | Use For |
|-----------|----------|---------|
| **Payout Limit** | Resets each cycle | Recurring distributions (vesting) |
| **Surplus Allowance** | One-time per ruleset | Discretionary treasury access |
| **Cycle Duration** | Determines distribution frequency | Monthly = 30 days |

### Configuration

```solidity
JBRulesetConfig({
    duration: 30 days,                    // Monthly cycles
    // ... other config
    fundAccessLimitGroups: [
        JBFundAccessLimitGroup({
            terminal: address(TERMINAL),
            token: JBConstants.NATIVE_TOKEN,
            payoutLimits: [
                JBCurrencyAmount({
                    amount: 6.67 ether,   // Monthly vesting amount
                    currency: nativeCurrency
                })
            ],
            surplusAllowances: [
                JBCurrencyAmount({
                    amount: 20 ether,     // One-time treasury (doesn't reset)
                    currency: nativeCurrency
                })
            ]
        })
    ]
});
```

### Capital Flow

```
Month 0: Balance = 100 ETH
         Surplus = Balance - Payout Limit = 93.33 ETH (redeemable)

Month 1: Team calls sendPayoutsOf() → receives 6.67 ETH
         Balance = 93.33 ETH
         Surplus = 86.67 ETH

Month 12: All vested, Balance = 20 ETH (treasury allowance)
```

### Key Insight

- **Payout limits protect vesting funds** from redemption
- **Surplus = unvested funds** available for token holder cash outs
- **No custom contracts needed**

---

## Pattern 2: NFT-Gated Treasury

**Use case**: Sell NFTs, allow holders to redeem against treasury surplus

**Solution**: Use nana-721-hook-v5 with native cash outs

### Configuration

1. Deploy project with `JB721TiersHookProjectDeployer`
2. Configure 721 hook as data hook for pay AND cash out
3. Set `cashOutTaxRate: 0` for full redemption value

```solidity
JBRulesetMetadata({
    cashOutTaxRate: 0,              // Full redemption
    useDataHookForPay: true,        // 721 hook mints NFTs
    useDataHookForCashOut: true,    // 721 hook handles burns
    dataHook: address(0),           // Set by deployer
    // ...
});
```

### How Cash Outs Work

1. User calls `cashOutTokensOf()` on terminal
2. 721 hook intercepts, calculates: `(NFT price / total prices) × surplus`
3. NFT is burned, ETH sent to user

**No custom cash out hook needed** - the 721 hook handles everything.

---

## Pattern 3: Governance-Minimal Treasury

**Use case**: Immutable treasury with no admin controls

**Solution**: Transfer ownership to burn address after setup

### Configuration

```solidity
// 1. Deploy project with restrictive metadata
JBRulesetMetadata({
    allowOwnerMinting: false,
    allowTerminalMigration: false,
    allowSetTerminals: false,
    allowSetController: false,
    allowAddAccountingContext: false,
    allowAddPriceFeed: false,
    // ...
});

// 2. After deployment, burn ownership
PROJECTS.transferFrom(deployer, 0x000000000000000000000000000000000000dEaD, projectId);
```

### What This Achieves

- No one can change rulesets
- No one can add/remove terminals
- No one can mint tokens arbitrarily
- Payouts/cash outs work as configured forever

---

## Pattern 4: Split Recipients Without Custom Hooks

**Use case**: Distribute payouts to multiple addresses

**Solution**: Use native splits with direct beneficiaries

### Configuration

```solidity
JBSplit[] memory splits = new JBSplit[](3);

splits[0] = JBSplit({
    percent: 500_000_000,           // 50%
    beneficiary: payable(team1),
    projectId: 0,
    hook: IJBSplitHook(address(0)), // No hook needed!
    // ...
});

splits[1] = JBSplit({
    percent: 300_000_000,           // 30%
    beneficiary: payable(team2),
    // ...
});

splits[2] = JBSplit({
    percent: 200_000_000,           // 20%
    beneficiary: payable(treasury),
    // ...
});
```

**Only use split hooks when you need custom logic** (e.g., swapping tokens, adding to LP).

---

## Pattern 5: NFT + Vesting Combined

**Use case**: Sell NFTs with funds vesting to team over time, holders can exit by burning

**Solution**: Combine patterns 1 + 2

### Architecture

```
┌─────────────────────────────────────────────────┐
│  JB Project with 721 Hook                       │
│                                                 │
│  • NFT tier: 100 supply, 1 ETH each            │
│  • Payout limit: 6.67 ETH/month (vesting)      │
│  • Surplus allowance: 20 ETH (treasury)        │
│  • Cash out tax: 0%                            │
│  • Owner: burn address                         │
│                                                 │
│  Treasury Flow:                                │
│  ├── Month 0: 80 ETH surplus (all unvested)   │
│  ├── Month 6: 40 ETH surplus                  │
│  └── Month 12: 0 ETH surplus (fully vested)   │
│                                                 │
│  NFT Holder: Can burn anytime for pro-rata    │
│              share of current surplus          │
└─────────────────────────────────────────────────┘
```

### Complete Example

See the Drip x Juicebox deployment script for a full implementation:
- 100 NFTs at 1 ETH each
- 20 ETH immediate treasury (surplus allowance)
- 80 ETH vests over 12 months (payout limits)
- NFT holders can burn to exit at any time
- Zero custom contracts

---

## Pattern 6: Custom NFT Content via Resolver

**Use case**: NFT project with custom artwork, composable assets, or dynamic metadata while using 721-hook off-the-shelf

**Solution**: Implement `IJB721TokenUriResolver` for custom content, use standard 721-hook for treasury mechanics

### Why This Pattern?

The 721-hook handles all the hard stuff:
- Payment processing and tier selection
- Token minting and supply tracking
- Cash out weight calculations
- Reserved token mechanics

You only need custom code for **content generation** (artwork, metadata, composability).

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Standard 721-Hook (off-the-shelf)                          │
│  ├── Handles payments, minting, cash outs                   │
│  ├── Manages tier supply and pricing                        │
│  └── Calls tokenUriResolver.tokenUriOf() for metadata       │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Custom TokenUriResolver (your code)                │   │
│  │  ├── Implements IJB721TokenUriResolver              │   │
│  │  ├── tokenUriOf() → dynamic SVG/metadata            │   │
│  │  └── Custom behaviors (composability, decoration)   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Interface

```solidity
interface IJB721TokenUriResolver {
    /// @notice Get the token URI for a given token.
    /// @param hook The 721 hook address.
    /// @param tokenId The token ID.
    /// @return The token URI (typically base64-encoded JSON with SVG).
    function tokenUriOf(address hook, uint256 tokenId)
        external view returns (string memory);
}
```

### Basic Resolver Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJB721TokenUriResolver} from "@bananapus/721-hook/src/interfaces/IJB721TokenUriResolver.sol";
import {IJB721TiersHook} from "@bananapus/721-hook/src/interfaces/IJB721TiersHook.sol";

contract CustomTokenUriResolver is IJB721TokenUriResolver {
    /// @notice Generate token URI with custom artwork/metadata.
    function tokenUriOf(address hook, uint256 tokenId)
        external view override returns (string memory)
    {
        // Get tier info from the hook
        IJB721TiersHook tiersHook = IJB721TiersHook(hook);
        uint256 tierId = tiersHook.tierIdOfToken(tokenId);

        // Generate your custom metadata/artwork
        string memory name = _getNameForTier(tierId);
        string memory svg = _generateSvgForToken(tokenId, tierId);

        // Return base64-encoded JSON
        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(abi.encodePacked(
                '{"name":"', name, '",',
                '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
            )))
        ));
    }

    function _getNameForTier(uint256 tierId) internal view returns (string memory) {
        // Your tier naming logic
    }

    function _generateSvgForToken(uint256 tokenId, uint256 tierId) internal view returns (string memory) {
        // Your SVG generation logic
    }
}
```

### Advanced: Composable NFTs (Banny Pattern)

For composable NFTs where items can be attached to base tokens:

```solidity
contract ComposableTokenUriResolver is IJB721TokenUriResolver {
    // Track which items are attached to which base tokens
    mapping(address hook => mapping(uint256 baseTokenId => uint256[])) public attachedItems;

    // Prevent changes for a duration (e.g., 7 days)
    mapping(address hook => mapping(uint256 tokenId => uint256)) public lockedUntil;

    /// @notice Attach items to a base token.
    function decorateWith(
        address hook,
        uint256 baseTokenId,
        uint256[] calldata itemIds
    ) external {
        // Verify caller owns both base token and items
        require(IJB721TiersHook(hook).ownerOf(baseTokenId) == msg.sender);
        require(lockedUntil[hook][baseTokenId] < block.timestamp, "LOCKED");

        for (uint256 i; i < itemIds.length; i++) {
            require(IJB721TiersHook(hook).ownerOf(itemIds[i]) == msg.sender);
            // Transfer item to this contract (escrow while attached)
            IJB721TiersHook(hook).transferFrom(msg.sender, address(this), itemIds[i]);
        }

        attachedItems[hook][baseTokenId] = itemIds;
    }

    /// @notice Lock outfit changes for 7 days.
    function lockChangesFor(address hook, uint256 baseTokenId) external {
        require(IJB721TiersHook(hook).ownerOf(baseTokenId) == msg.sender);
        lockedUntil[hook][baseTokenId] = block.timestamp + 7 days;
    }

    /// @notice Generate composite SVG from base + attached items.
    function tokenUriOf(address hook, uint256 tokenId) external view override returns (string memory) {
        uint256[] memory items = attachedItems[hook][tokenId];

        // Generate layered SVG combining base + all attached items
        string memory svg = _generateCompositeSvg(hook, tokenId, items);

        return _encodeAsDataUri(svg);
    }
}
```

### Deployment Integration

```solidity
// 1. Deploy your custom resolver
CustomTokenUriResolver resolver = new CustomTokenUriResolver();

// 2. Configure 721 hook with resolver
REVDeploy721TiersHookConfig memory hookConfig = REVDeploy721TiersHookConfig({
    baseline721HookConfiguration: JBDeploy721TiersHookConfig({
        // ... tier configs
        tokenUriResolver: IJB721TokenUriResolver(address(resolver)),
        // ...
    }),
    // ...
});

// 3. Deploy project/revnet with hook config
deployer.deployWith721sFor(projectId, hookConfig, ...);
```

### When to Use This Pattern

| Requirement | Use Resolver? |
|-------------|---------------|
| Static tier images (IPFS) | No - use `encodedIPFSUri` in tier config |
| Dynamic/generative art | **Yes** |
| Composable/layered NFTs | **Yes** |
| On-chain SVG storage | **Yes** |
| Token-specific metadata | **Yes** |
| Standard ERC-721 metadata | No - use default |

### Reference Implementation

**banny-retail-v5**: https://github.com/mejango/banny-retail-v5
- `Banny721TokenUriResolver.sol` - Composable SVG NFTs with outfit decoration
- `Deploy.s.sol` - Deployment with custom resolver
- `Drop1.s.sol` - Adding tiers with custom categories

Key features demonstrated:
- On-chain SVG storage with hash verification
- Composable outfits (attach items to base Banny)
- Outfit locking (7-day freeze)
- Category-based slot system
- Multi-chain deployment via Revnet

---

## Pattern 7: Prediction Games with Dynamic Cash Out Weights

**Use case**: Games where outcomes determine payout distribution (prediction markets, fantasy sports, competitions)

**Solution**: Extend 721-hook with custom delegate, use on-chain governance for outcome resolution

### Why This Pattern Requires Extending 721-Hook

Unlike Pattern 6 (resolver-only), prediction games need to change **core treasury mechanics**:

| Requirement | Why Resolver Isn't Enough |
|-------------|---------------------------|
| Dynamic cash out weights | Cash out calculation is in the hook, not resolver |
| First-owner tracking | Rewards original minters, not current holders |
| Phase enforcement | Different rules per game phase |
| Governance integration | Scorecard ratification triggers weight changes |

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Game Lifecycle (via Juicebox Rulesets)                     │
│                                                             │
│  COUNTDOWN → MINT → REFUND → SCORING → COMPLETE             │
│      │         │       │        │          │                │
│      │    Players   Early    Holders    Winners             │
│      │    mint      exit     vote on    cash out            │
│      │    NFTs      OK       scorecard  winnings            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Custom Delegate (extends JB721Hook)                        │
│  ├── Tracks first owners (for fair reward distribution)     │
│  ├── Phase-aware cash out logic                             │
│  ├── Dynamic tier weights (set by governor)                 │
│  └── Enforces phase restrictions                            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Governor Contract                                          │
│  ├── NFT holders propose scorecards                         │
│  ├── Tier-weighted voting (own 25% of tier = 25% of votes)  │
│  ├── 50% quorum required for ratification                   │
│  └── Ratification sets tier cash out weights                │
└─────────────────────────────────────────────────────────────┘
```

### Game Phases

```solidity
enum DefifaGamePhase {
    COUNTDOWN,           // Game announced, no minting yet
    MINT,                // Players can mint NFTs (pick teams)
    REFUND,              // Early exit window (get mint cost back)
    SCORING,             // Game over, holders vote on scorecard
    COMPLETE,            // Scorecard ratified, winners cash out
    NO_CONTEST_INEVITABLE, // Not enough participation
    NO_CONTEST           // Game cancelled, full refunds
}
```

### Dynamic Cash Out Weights

Standard 721-hook: `cashOutWeight = tierPrice` (fixed)

Defifa pattern: `cashOutWeight = scorecardWeight[tierId]` (dynamic)

```solidity
// Total weight is 1e18 (100%), distributed among tiers by scorecard
uint256 constant TOTAL_CASH_OUT_WEIGHT = 1e18;

struct DefifaTierCashOutWeight {
    uint256 id;           // Tier ID
    uint256 cashOutWeight; // Share of total (e.g., 0.5e18 = 50%)
}

// Example: 4-team tournament, Team A wins
// Team A: 1e18 (100% of pot)
// Team B: 0
// Team C: 0
// Team D: 0

// Example: Fantasy league with scoring
// Team A (1st): 0.5e18 (50%)
// Team B (2nd): 0.3e18 (30%)
// Team C (3rd): 0.15e18 (15%)
// Team D (4th): 0.05e18 (5%)
```

### First Owner Tracking

Critical for fair games - rewards go to original minters, not secondary buyers:

```solidity
// Track who first minted each token
mapping(uint256 tokenId => address) public firstOwnerOf;

// In _processPayment():
firstOwnerOf[tokenId] = beneficiary;

// In cash out calculation:
// Only firstOwnerOf[tokenId] receives the full reward
// Current owner can transfer, but original minter gets payout
```

### Governor Voting

```solidity
// Attestation power = share of tier tokens you own
// If you own 25 of 100 tokens in Tier 1, you have 25% of Tier 1's voting power

function attestToScorecardFrom(
    address attester,
    DefifaScorecard calldata scorecard
) external {
    // Verify attester hasn't already voted
    // Add attester's voting power to scorecard
    // If quorum reached, scorecard can be ratified
}

function ratifyScorecard(DefifaScorecard calldata scorecard) external {
    // Verify scorecard has 50% attestation across all minted tiers
    // Set tier cash out weights on delegate
    // Game moves to COMPLETE phase
}
```

### When to Use This Pattern

| Use Case | Fits Pattern? |
|----------|---------------|
| Sports predictions | **Yes** - teams = tiers, outcomes = weights |
| Fantasy leagues | **Yes** - players draft teams, scoring determines payouts |
| Tournament brackets | **Yes** - bracket picks = tiers |
| Election predictions | **Yes** - candidates = tiers |
| Price predictions | **Yes** - price ranges = tiers |
| Art competitions | **Yes** - entries = tiers, votes = weights |
| Standard NFT collection | **No** - use Pattern 6 instead |
| Fixed-price redemptions | **No** - use native 721-hook |

### Key Implementation Considerations

1. **Phase transitions via rulesets**: Use ruleset durations to enforce timing
2. **Refund window**: Allow early exit before outcomes are known
3. **Quorum design**: Too high = deadlock, too low = manipulation
4. **First-owner vs current-owner**: Decide who receives rewards
5. **No-contest handling**: What if not enough participation?

### Reference Implementation

**defifa-collection-deployer-v5**: https://github.com/BallKidz/defifa-collection-deployer-v5

Key contracts:
- `DefifaDelegate.sol` - Extends JB721Hook with phase logic and dynamic weights
- `DefifaGovernor.sol` - On-chain voting for scorecard ratification
- `DefifaDeployer.sol` - Factory for launching games
- `DefifaTokenUriResolver.sol` - Dynamic metadata showing pot share

Features demonstrated:
- Phase-based game lifecycle
- Tier-weighted governance voting
- Dynamic cash out weight redistribution
- First-owner tracking for fair rewards
- No-contest handling for failed games

---

## Decision Tree: When to Write Custom Code

```
Need custom payment logic?
├── Can 721 hook handle it? → Use 721 hook
├── Can buyback hook handle it? → Use buyback hook
└── Neither works? → Write custom pay hook

Need custom redemption logic?
├── Does 721 hook's burn-to-redeem work? → Use 721 hook
├── Is redemption just against surplus? → Use native cash out
└── Need external data source? → Write custom cash out hook

Need custom payout routing?
├── Can direct beneficiary addresses work? → Use native splits
├── Need token swapping? → Write split hook
├── Need LP deposits? → Write split hook
└── Just multi-recipient? → Use native splits

Need vesting/time-locks?
├── Linear over time? → Use cycling rulesets + payout limits
├── Milestone-based? → Queue multiple rulesets
└── Complex conditions? → Consider Revnet or custom

Need custom NFT content?
├── Static images per tier? → Use encodedIPFSUri in tier config
├── Dynamic/generative art? → Write IJB721TokenUriResolver
├── Composable/layered NFTs? → Write IJB721TokenUriResolver
└── On-chain SVG? → Write IJB721TokenUriResolver

Need prediction/game mechanics?
├── Fixed redemption values? → Use standard 721-hook
├── Outcome-based payouts? → Extend 721-hook (Defifa pattern)
├── On-chain outcome voting? → Add Governor contract
└── First-owner rewards? → Track in custom delegate
```

---

## Anti-Patterns to Avoid

### 1. Wrapping the 721 Hook

**Wrong**: Creating a data hook that wraps/delegates to 721 hook
**Right**: Use 721 hook directly, achieve vesting via ruleset configuration

### 2. Custom Vesting Contracts

**Wrong**: Writing a VestingSplitHook to hold and release funds
**Right**: Use payout limits (reset each cycle) for recurring distributions

### 3. Multiple Queued Rulesets for Simple Cycles

**Wrong**: Queueing 12 rulesets for 12-month vesting
**Right**: One ruleset with 30-day duration that cycles automatically

### 4. Split Hooks for Direct Transfers

**Wrong**: Split hook that just forwards to an address
**Right**: Set the address as direct split beneficiary

### 5. Custom Cash Out Hooks for Standard Redemptions

**Wrong**: Writing hook to calculate pro-rata redemption
**Right**: Set `cashOutTaxRate: 0` and let terminal handle it

---

## Reference Implementations

- **Vesting + NFT**: Drip x Juicebox (see `/jb-project` for deployment script)
- **Autonomous Treasury**: Revnet (`revnet-core-v5`)
- **NFT Rewards**: Any project using `JB721TiersHookProjectDeployer`
- **Custom NFT Content**: [banny-retail-v5](https://github.com/mejango/banny-retail-v5) - composable SVG NFTs with outfit decoration
- **Prediction Games**: [defifa-collection-deployer-v5](https://github.com/BallKidz/defifa-collection-deployer-v5) - dynamic cash out weights with on-chain governance

## Related Skills

- `/jb-simplify` - Checklist to reduce custom code
- `/jb-project` - Project deployment and configuration
- `/jb-ruleset` - Ruleset configuration details
- `/jb-v5-impl` - Deep implementation mechanics
