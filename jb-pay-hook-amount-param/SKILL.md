---
name: jb-pay-hook-amount-param
description: |
  Juicebox V5 hook development: JBPayHookSpecification.amount controls how much payment gets
  forwarded to the hook. Set to context.amount.value to forward funds, or 0 if funds should
  stay in Juicebox terminal. Use when: (1) implementing beforePayRecordedWith, (2) debugging
  why hook isn't receiving expected funds, (3) deciding whether hook needs forwarded funds.
author: Claude Code
version: 1.0.0
date: 2026-01-30
---

# JBPayHookSpecification Amount Parameter

## Problem

When implementing a Juicebox V5 data hook's `beforePayRecordedWith` function, developers need
to understand that `amount` in `JBPayHookSpecification` explicitly controls how much of the
payment gets forwarded to the hook:
- `amount: 0` = funds stay in Juicebox terminal, hook called but receives nothing
- `amount: context.amount.value` = all funds forwarded to hook

Both are valid use cases depending on what the hook needs to do.

## Context / Trigger Conditions

- Implementing `IJBRulesetDataHook.beforePayRecordedWith()`
- Creating `JBPayHookSpecification[]` to route payments
- Hook's `afterPayRecordedWith` receives unexpected `forwardedAmount.value`
- Deciding whether hook needs to handle funds or just react to payments

## Solution

**When hook needs to receive and handle funds (e.g., Aave deposit):**

```solidity
function beforePayRecordedWith(
    JBBeforePayRecordedContext calldata context
) external view override returns (
    uint256 weight,
    JBPayHookSpecification[] memory hookSpecifications
) {
    weight = context.weight;

    hookSpecifications = new JBPayHookSpecification[](1);
    hookSpecifications[0] = JBPayHookSpecification({
        hook: IJBPayHook(address(this)),
        amount: context.amount.value,  // Forward funds to hook
        metadata: ""
    });
}
```

**When hook just needs notification (funds stay in Juicebox):**

```solidity
// Many hooks work this way - they react to payments but don't need the funds
hookSpecifications[0] = JBPayHookSpecification({
    hook: IJBPayHook(address(this)),
    amount: 0,  // Funds stay in terminal, hook just gets called
    metadata: ""
});
```

## Verification

After payment:
1. Check `afterPayRecordedWith` is called
2. Verify `context.forwardedAmount.value` equals the payment amount
3. Confirm hook contract receives the expected tokens/ETH

## Example

Full data hook implementation that forwards all payments:

```solidity
contract MyDataHook is IJBRulesetDataHook, IJBPayHook {
    function beforePayRecordedWith(
        JBBeforePayRecordedContext calldata context
    ) external view override returns (
        uint256 weight,
        JBPayHookSpecification[] memory hookSpecifications
    ) {
        weight = context.weight;

        hookSpecifications = new JBPayHookSpecification[](1);
        hookSpecifications[0] = JBPayHookSpecification({
            hook: IJBPayHook(address(this)),
            amount: context.amount.value,  // Forward entire payment
            metadata: ""
        });
    }

    function afterPayRecordedWith(
        JBAfterPayRecordedContext calldata context
    ) external payable override {
        // context.forwardedAmount.value now contains the payment
        uint256 received = context.forwardedAmount.value;
        // ... process payment
    }
}
```

## Notes

- This behavior is consistent across JB V5 - explicit amounts are always required
- For partial forwarding, calculate the exact amount to send to each hook
- Multiple hooks can receive portions of the payment (amounts should sum correctly)
- The ruleset's `useDataHookForPay` must be true for this to work

## Related

- `JBCashOutHookSpecification` follows the same pattern for cash-outs
- See jb-v5-api skill for full hook interface documentation
