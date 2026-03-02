---
name: jb-split-beneficiary-zero-address
description: |
  Fix JBSplit beneficiary address(0) causing tokens to mint to wrong recipient in Juicebox V5.
  Use when: (1) split payout mints project tokens to msg.sender instead of intended recipient,
  (2) JBSplit has beneficiary=address(0) with projectId!=0, (3) fee tokens appear on deployer
  contract instead of hook. JBMultiTerminal.executePayout defaults to msg.sender when
  split.beneficiary is address(0).
author: Claude Code
version: 1.0.0
date: 2026-03-01
---

# JBSplit Beneficiary address(0) Token Minting Gotcha

## Problem
When a `JBSplit` has `beneficiary: payable(address(0))` and `projectId != 0`, the
JBMultiTerminal's `executePayout` function defaults to using `msg.sender` as the
beneficiary for the `pay()` call to the target project's terminal. This causes project
tokens to be minted to the caller (e.g., a deployer contract) instead of the intended
recipient (e.g., a hook contract that distributes tokens during cash-outs).

## Context / Trigger Conditions
- A `JBSplit` is configured with `beneficiary: payable(address(0))` and a non-zero `projectId`
- The split is processed during `sendPayoutsOf` (directly or via a function like `fulfillCommitmentsOf`)
- The target project has an ERC20 token deployed with non-zero issuance weight
- Symptom: project tokens appear on the contract that called `sendPayoutsOf` instead of the expected recipient
- Assertion failures like `assertEq(token.balanceOf(deployer), 0)` failing with a non-zero value

## Solution
Always set an explicit `beneficiary` on JBSplits that target a project:

```solidity
// BAD: address(0) causes tokens to go to msg.sender
JBSplit({
    preferAddToBalance: false,
    percent: uint32(splitPercent),
    projectId: uint64(targetProjectId),
    beneficiary: payable(address(0)),  // tokens go to msg.sender!
    lockedUntil: 0,
    hook: IJBSplitHook(address(0))
});

// GOOD: explicit beneficiary receives the project tokens
JBSplit({
    preferAddToBalance: false,
    percent: uint32(splitPercent),
    projectId: uint64(targetProjectId),
    beneficiary: payable(address(hookOrRecipient)),  // tokens go here
    lockedUntil: 0,
    hook: IJBSplitHook(address(0))
});
```

## Verification
After fixing, verify with:
```solidity
// The unintended recipient should have 0 tokens
assertEq(IERC20(projectToken).balanceOf(address(deployer)), 0);
// The intended recipient should have the tokens
assertGt(IERC20(projectToken).balanceOf(address(hook)), 0);
```

## Example
In Defifa's `_buildSplits`, the NANA protocol fee split initially had `beneficiary: address(0)`.
When `fulfillCommitmentsOf` called `sendPayoutsOf`, the terminal processed the NANA split
by calling `pay()` on the NANA project's terminal. With `beneficiary: address(0)`, the
terminal used `msg.sender` (DefifaDeployer) as the beneficiary, minting NANA tokens to
the deployer instead of the DefifaHook.

Fix: Set `beneficiary: payable(address(_dataHook))` so the hook receives NANA tokens
and can distribute them proportionally during cash-outs.

## Notes
- This behavior is by design in JBMultiTerminal — address(0) is not a valid beneficiary
  for `pay()`, so the terminal substitutes the caller
- The issue is especially subtle when `sendPayoutsOf` is called indirectly (e.g., via
  governance ratification calling `fulfillCommitmentsOf`)
- If the split uses `preferAddToBalance: true`, the beneficiary field is less relevant
  since `addToBalance` doesn't mint tokens
- Same-terminal splits (where the target project uses the same JBMultiTerminal) are
  feeless, but the beneficiary issue still applies
