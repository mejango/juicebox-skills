---
name: jbv5-revnet-omnichain-default
description: |
  Juicebox V5 revnets should default to omnichain deployment for maximum reach.
  Use when: (1) revnet transaction shows single chainId without chainConfigs,
  (2) user creates a revnet but AI deploys single-chain only, (3) creator or
  community revnet that would benefit from multi-chain accessibility. Revnets
  are designed for network effects - omnichain is the natural default.
author: Claude Code
version: 1.0.0
date: 2026-02-14
---

# Revnets Should Default to Omnichain

## Problem

When deploying revnets, the AI may deploy to a single chain when omnichain
would be better for the user's goals. Revnets are designed for maximum network
effects and reach.

## Context / Trigger Conditions

- User chooses "autonomous operation" or explicitly asks for a revnet
- Revnet transaction shows `chainId="X"` without `chainConfigs` for multi-chain
- Creator or community revnet where supporters could be on any chain
- User mentions wanting wide reach or accessibility

## Solution

Unless user explicitly asks for single-chain deployment:
- Include `chainConfigs` with all supported chains
- Each chain gets proper terminal configurations
- Suckers are auto-generated for cross-chain token bridging
- Supporters can participate from any chain they prefer

**Check:** Does the deployRevnet transaction have `chainConfigs` with multiple chains?

## Verification

For revnet deployments, verify:
- [ ] `chainConfigs` present with multiple chains (unless single-chain explicitly requested)
- [ ] Terminal configurations correct for each chain (USDC addresses differ per chain)

## Example

**Wrong approach:**
```json
{
  "action": "deployRevnet",
  "chainId": "11155111",
  // No chainConfigs - single chain only
}
```

**Correct approach:**
```json
{
  "action": "deployRevnet",
  "chainId": "11155111",
  "chainConfigs": [
    {"chainId": "11155111", "label": "Sepolia", ...},
    {"chainId": "11155420", "label": "OP Sepolia", ...},
    {"chainId": "84532", "label": "Base Sepolia", ...},
    {"chainId": "421614", "label": "Arb Sepolia", ...}
  ]
}
```

## Notes

- Omnichain revnets let supporters participate from any chain they prefer
- Suckers enable cross-chain token bridging automatically
- Per-chain terminal configs handle different token addresses (e.g., USDC)
- Single-chain only makes sense if user explicitly requests it
