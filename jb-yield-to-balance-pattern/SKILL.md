---
name: jb-yield-to-balance-pattern
description: |
  Pattern for routing external yield/revenue into Juicebox project balance via addToBalanceOf.
  Use when: (1) building hooks that generate yield from external protocols (Aave, staking),
  (2) separating principal tracking from yield for different withdrawal flows,
  (3) integrating external DeFi protocols with Juicebox treasury management.
author: Claude Code
version: 1.0.0
date: 2026-01-30
---

# Yield to Balance Pattern for Juicebox Hooks

## Problem

When building Juicebox hooks that generate yield from external protocols (e.g., Aave), you need to:
1. Track principal separately from yield for proper accounting
2. Route yield into the project's Juicebox balance for standard withdrawal flows
3. Allow different handling for principal cash-outs vs yield withdrawals

The cleanest approach is routing yield through `addToBalanceOf` so it becomes part of the
project's official balance and can be managed through standard Juicebox tooling.

## Context / Trigger Conditions

- Building a hook that deposits funds into yield-generating protocols (Aave, Compound, staking)
- Need to separate "investor principal" (fee-free cash-out) from "team yield" (fee-bearing)
- Want team withdrawals to appear in standard Juicebox UI and incur protocol fees
- Integrating external DeFi yield with Juicebox treasury management

## Solution

Route yield to the project balance using `IJBTerminal.addToBalanceOf()`:

```solidity
import {IJBTerminal} from "@juicebox/interfaces/IJBTerminal.sol";

contract YieldHook {
    IJBTerminal public immutable TERMINAL;

    function _transferYieldToJuicebox(
        uint256 projectId,
        uint256 yieldAmount,
        address token
    ) internal {
        // 1. Withdraw yield from DeFi protocol to this contract
        uint256 withdrawn = AAVE_POOL.withdraw(token, yieldAmount, address(this));

        // 2. Approve terminal to spend the yield
        IERC20(token).forceApprove(address(TERMINAL), withdrawn);

        // 3. Add yield to project balance
        TERMINAL.addToBalanceOf(
            projectId,
            token,
            withdrawn,
            false,  // shouldReturnHeldFees
            "",     // memo
            ""      // metadata
        );

        // 4. Track yield for accounting
        yieldWithdrawn[projectId] += withdrawn;
    }
}
```

**Team then withdraws via standard payouts:**
```solidity
// Called by team to withdraw (2.5% fee automatically applied)
terminal.sendPayoutsOf(
    projectId,
    token,
    amount,
    currency,
    minTokensPaidOut
);
```

## Complete Flow

```
1. Investor pays → Hook deposits to Aave (principal tracked)
2. Yield accumulates in Aave
3. When threshold reached → Withdraw yield → addToBalanceOf()
4. Yield appears in project balance
5. Team uses sendPayoutsOf() → 2.5% fee applied automatically
6. Investor cashes out → Direct from Aave principal → 0% fee
```

## Architecture

```solidity
contract YieldIntegrationHook is IJBPayHook, IJBCashOutHook, IJBRulesetDataHook {
    // Tracking
    mapping(uint256 => uint256) public principalDeposited;
    mapping(uint256 => uint256) public principalWithdrawn;
    mapping(uint256 => uint256) public yieldWithdrawn;

    // Pay hook: deposits to yield protocol
    function afterPayRecordedWith(JBAfterPayRecordedContext calldata context) external payable {
        // Deposit to Aave
        AAVE_POOL.supply(token, amount, address(this), 0);
        principalDeposited[context.projectId] += amount;

        // Check if yield should be transferred
        _maybeTransferYield(context.projectId);
    }

    // Cash-out hook: fee-free principal withdrawal
    function beforeCashOutRecordedWith(...) external view returns (...) {
        // Set 0% tax rate for principal cash-outs
        cashOutTaxRate = 0;

        // Calculate user's share of principal
        uint256 userShare = (availablePrincipal * cashOutCount) / totalSupply;

        // Specify cash-out hook to handle withdrawal
        hookSpecifications[0] = JBCashOutHookSpecification({
            hook: IJBCashOutHook(address(this)),
            amount: userShare,
            metadata: ""
        });
    }

    function afterCashOutRecordedWith(...) external payable {
        // Withdraw principal directly from Aave to beneficiary
        AAVE_POOL.withdraw(token, amount, context.beneficiary);
        principalWithdrawn[context.projectId] += amount;
    }

    // Yield calculation
    function _calculateAvailableYield(uint256 projectId) internal view returns (uint256) {
        uint256 totalBalance = IERC20(aToken).balanceOf(address(this));
        uint256 principalRemaining = principalDeposited[projectId] - principalWithdrawn[projectId];

        if (totalBalance > principalRemaining + yieldWithdrawn[projectId]) {
            return totalBalance - principalRemaining - yieldWithdrawn[projectId];
        }
        return 0;
    }
}
```

## Verification

1. Yield transfers appear in project's terminal balance
2. Team payouts incur 2.5% JBX fee
3. Investor cash-outs bypass terminal (no fee)
4. Principal + yield accounting stays accurate

## Notes

- Always include emergency direct-transfer function in case `addToBalanceOf` fails
- Consider yield threshold to batch transfers (save gas)
- Track yield separately from principal for accurate accounting
- Ensure ruleset has `useDataHookForPay: true` and `useDataHookForCashOut: true`

## Emergency Fallback

```solidity
function emergencyYieldTransfer(uint256 projectId) external {
    require(msg.sender == config.teamWallet, "Only team");
    // Direct transfer bypassing Juicebox (no fees)
    AAVE_POOL.withdraw(token, availableYield, config.teamWallet);
}
```

## Related

- jb-pay-hook-amount-param - Correct way to specify hook payment amounts
- jb-cash-out-hook - Cash-out hook implementation details
- jb-terminal-wrapper - Alternative approach using terminal wrappers
