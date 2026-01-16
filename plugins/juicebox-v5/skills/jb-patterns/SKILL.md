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

## Related Skills

- `/jb-simplify` - Checklist to reduce custom code
- `/jb-project` - Project deployment and configuration
- `/jb-ruleset` - Ruleset configuration details
- `/jb-v5-impl` - Deep implementation mechanics
