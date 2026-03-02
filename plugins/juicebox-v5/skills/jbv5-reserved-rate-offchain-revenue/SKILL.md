---
name: jbv5-reserved-rate-offchain-revenue
description: |
  Juicebox V5 reserved rate configuration for off-chain vs on-chain revenue sharing.
  Use when: (1) user wants to share off-chain revenue (merchandise, services, sales)
  and AI sets reservedPercent based on "what percentage will you share" answer,
  (2) reservedPercent is set to match a revenue sharing commitment (wrong),
  (3) building ownership/revenue-sharing projects. Key insight: for off-chain revenue,
  reserved rate should be 0 - owner controls what goes in anyway. Reserved rate only
  matters for on-chain revenue that automatically flows to the project.
author: Claude Code
version: 1.0.0
date: 2026-02-14
---

# Reserved Rate for Off-Chain vs On-Chain Revenue

## Problem

When building Juicebox V5 projects with revenue sharing, the AI incorrectly sets
`reservedPercent` based on the user's answer to "what percentage of revenue will
you share?" This conflates two unrelated concepts:

- **Revenue sharing commitment**: A social/business promise to share X% of earnings
- **Reserved rate**: Token distribution when someone pays (X% to owner, rest to payer)

## Context / Trigger Conditions

- User selects "ownership" or "revenue sharing" project type
- User says they'll share X% of revenue from off-chain sources (merchandise, services, sales)
- AI asks "What percentage of revenue do you commit to sharing?" then sets `reservedPercent`
- Configuration shows `reservedPercent: 2000` when user said "20% revenue share"

## Solution

**Off-chain revenue** (e-bike sales, merchandise, consulting, services):
- Owner controls what money enters the Juicebox project
- Owner adds the portion they want to share via `addToBalance`
- Owner keeps the rest in their own bank accounts
- **Reserved rate = 0** is correct - owner doesn't need reserved tokens
- The "20% revenue share" is a commitment fulfilled by what owner adds, not by token distribution

**On-chain revenue** (royalties, protocol fees, automatic flows):
- Revenue automatically goes to the project treasury - owner can't intercept it
- Reserved tokens give owner their share via cash out, like everyone else
- **Reserved rate = owner's percentage** of the automatic revenue
- If owner should get 70% of on-chain revenue: `reservedPercent: 7000`

**Key rule**: Don't ask "what percentage will you share" then set reserved rate. These are different things.

## Verification

For off-chain revenue sharing projects, verify:
- `reservedPercent: 0` (or very low)
- Explanation clarifies owner will add funds when they earn revenue
- No implication that contract enforces the revenue sharing percentage

## Example

**Wrong approach:**
```
User: "I'll share 20% of my e-bike sales with supporters"
AI sets: reservedPercent: 2000 (WRONG - conflates commitment with token distribution)
```

**Correct approach:**
```
User: "I'll share 20% of my e-bike sales with supporters"
AI sets: reservedPercent: 0
AI explains: "When you sell e-bikes, you'll add the revenue you want to share to your
project. Supporters can then claim their portion. You control how much goes in."
```

## Notes

- Reserved rate matters when revenue flows automatically (on-chain royalties, protocol fees)
- For most "ownership" projects where revenue is off-chain, reserved rate is irrelevant
- The user's revenue sharing commitment is social, not contract-enforced
- Don't let users think the contract automatically sends X% of their sales to supporters
