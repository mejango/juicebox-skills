---
name: jb-v5-percent-scales
description: |
  Fix uint16 overflow errors in Juicebox V5 percentage fields. Use when: (1) error
  "Number is not in safe 16-bit unsigned integer range (0 to 65535)", (2) configuring
  reservedPercent or cashOutTaxRate in launchProject, (3) percentage values causing
  transaction failures. Covers the different scales between launchProject (uint16,
  10000=100%) and deployRevnet (uint32, 10^9=100%).
author: Claude Code
version: 1.0.0
date: 2026-01-31
---

# Juicebox V5 Percentage Field Scales

## Problem
Juicebox V5 uses different scales for percentage fields depending on which contract/action
you're using. Using the wrong scale causes uint16 overflow errors or incorrect percentages.

## Context / Trigger Conditions
- Error: `"Number 'X' is not in safe 16-bit unsigned integer range (0 to 65535)"`
- Configuring `reservedPercent` or `cashOutTaxRate` in `launchProject` action
- Configuring `splitPercent`, `cashOutTaxRate`, or `issuanceDecayPercent` in `deployRevnet` action
- Percentages not behaving as expected after deployment

## Solution

### launchProject metadata fields (uint16, scale 10000 = 100%)

| Field | Type | Scale | 30% Example |
|-------|------|-------|-------------|
| `reservedPercent` | uint16 | 10000 = 100% | 3000 |
| `cashOutTaxRate` | uint16 | 10000 = 100% | 3000 |

```json
"metadata": {
  "reservedPercent": 3000,
  "cashOutTaxRate": 2000
}
```

### deployRevnet stageConfiguration fields (uint32, scale 10^9 = 100%)

| Field | Type | Scale | 30% Example |
|-------|------|-------|-------------|
| `splitPercent` | uint32 | 10^9 = 100% | 300000000 |
| `cashOutTaxRate` | uint32 | 10^9 = 100% | 300000000 |
| `issuanceDecayPercent` | uint32 | 10^9 = 100% | 300000000 |

```json
"stageConfigurations": [{
  "splitPercent": 300000000,
  "cashOutTaxRate": 200000000,
  "issuanceDecayPercent": 50000000
}]
```

### Quick Reference

**launchProject (uint16):**
- 10% = 1000
- 20% = 2000
- 30% = 3000
- 50% = 5000
- 100% = 10000

**deployRevnet (uint32):**
- 5% = 50000000
- 10% = 100000000
- 20% = 200000000
- 30% = 300000000
- 70% = 700000000

## Verification
- No uint16 overflow error when launching project
- Percentages display correctly in UI after deployment
- Token distribution matches expected percentages

## Example

**Wrong (causes overflow):**
```json
"metadata": {
  "reservedPercent": 300000000
}
```

**Correct:**
```json
"metadata": {
  "reservedPercent": 3000
}
```

## Notes
- The field name `cashOutTaxRate` appears in BOTH contexts but uses different scales
- Split percentages in `splitGroups` (payout splits) use 10^9 scale even in launchProject
- When in doubt, check if the field is inside `metadata` (uint16) or `stageConfigurations` (uint32)
- uint16 max value is 65535, so any value above that indicates wrong scale
