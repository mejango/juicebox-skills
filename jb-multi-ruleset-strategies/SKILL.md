---
name: jb-multi-ruleset-strategies
description: |
  Launch projects with multiple rulesets queued upfront, or queue multiple rulesets at once.
  Use when: (1) designing timed fundraisers with automatic end dates, (2) implementing early
  bird pricing, (3) scheduling graduated fund access, (4) any project lifecycle that should
  change rules automatically over time without manual intervention.
author: Claude Code
version: 1.0.0
date: 2026-02-16
---

# Juicebox V5: Multi-Ruleset Strategies

## Problem
Users think they need to manually queue ruleset changes at specific times, or don't realize
they can design entire project lifecycles upfront.

## Context / Trigger Conditions
- User wants a fundraiser with a hard end date
- User wants early bird pricing that decreases over time
- User wants to release funds only after a milestone/date
- User mentions "schedule", "timed raise", "stop payments", "phases"
- Any project that should change behavior automatically

## Solution
**rulesetConfigurations is an ARRAY** - include multiple rulesets that execute in sequence.

When one ruleset's duration ends, the next one begins automatically. No manual intervention needed.

### At Launch
```json
{
  "rulesetConfigurations": [
    { "duration": 2592000, "metadata": { "pausePay": false, ... } },
    { "duration": 0, "metadata": { "pausePay": true, ... } }
  ]
}
```
Ruleset 1 runs for 30 days with payments open, then Ruleset 2 takes over permanently with payments closed.

### Queue Multiple Later
Same pattern works with `queueRulesets`:
```json
{
  "rulesetConfigurations": [
    { "duration": 604800, ... },
    { "duration": 604800, ... },
    { "duration": 0, ... }
  ]
}
```

## Common Patterns

| Pattern | Ruleset Sequence | Use Case |
|---------|------------------|----------|
| **Timed raise** | Open (30d) → Closed | Fundraiser with hard end date |
| **Early bird** | High issuance → Lower issuance | Reward early supporters |
| **Graduated access** | No payouts → Payouts enabled | Release funds after milestone |
| **Seasonal** | Active → Paused → Active | Recurring campaign cycles |
| **Vesting schedule** | Locked → Partial → Full | Gradual fund release |

## Example: 30-Day Fundraiser with Automatic Close

```json
{
  "rulesetConfigurations": [
    {
      "mustStartAtOrAfter": 0,
      "duration": 2592000,
      "weight": "1000000000000000000000000",
      "weightCutPercent": 0,
      "approvalHook": "0x0000000000000000000000000000000000000000",
      "metadata": {
        "pausePay": false,
        "reservedPercent": 0,
        "cashOutTaxRate": 0,
        "baseCurrency": 2
      },
      "splitGroups": [{ "groupId": "...", "splits": [...] }],
      "fundAccessLimitGroups": [{ ... }]
    },
    {
      "mustStartAtOrAfter": 0,
      "duration": 0,
      "weight": "1000000000000000000000000",
      "weightCutPercent": 0,
      "approvalHook": "0x0000000000000000000000000000000000000000",
      "metadata": {
        "pausePay": true,
        "reservedPercent": 0,
        "cashOutTaxRate": 0,
        "baseCurrency": 2
      },
      "splitGroups": [],
      "fundAccessLimitGroups": []
    }
  ]
}
```

## Verification
- First ruleset is active immediately after launch
- After duration expires, next ruleset automatically becomes active
- Check `currentRuleset` via Bendystraw to confirm transitions

## Notes
- **duration = 0** means the ruleset runs indefinitely (until manually changed)
- **duration > 0** means automatic transition to next queued ruleset
- Each ruleset can have completely different settings (issuance, splits, access limits, etc.)
- **Design lifecycles upfront** - users can schedule all rule changes at launch
- Works for both `launchProject`/`launch721Project` AND `queueRulesets`
- Omnichain projects: same rulesets apply across all chains

## References
- Contract: `JBRulesets.sol` - ruleset duration and cycling logic
- Struct: `JBRulesetConfig` - configuration for each ruleset
