---
name: jb-project
description: Create and configure Juicebox V5 projects. Generate deployment scripts for launching projects with rulesets, terminals, and splits using JBController. Also helps with project ownership transfer and metadata updates.
---

# Juicebox V5 Project Management

Create and manage Juicebox V5 projects including deployment, configuration, and ownership.

## Before Writing Custom Code

**Always check if native mechanics can achieve your goal:**

| User Need | Recommended Solution |
|-----------|---------------------|
| Autonomous tokenized treasury | Deploy a **Revnet** via revnet-core-v5 |
| Project with structured rules and no EOA owner | Use contract-as-owner pattern |
| Simple fundraising project | Use this skill to generate deployment |
| Vesting/time-locked distributions | Use **payout limits + cycling rulesets** (no custom contracts) |
| NFT-gated treasury | Use **nana-721-hook-v5** with native cash outs |
| Governance-minimal/immutable | Transfer ownership to **burn address** after setup |
| One-time treasury access | Use **surplus allowance** (doesn't reset each cycle) |

**See `/jb-patterns` for detailed examples of these patterns.**
**See `/jb-simplify` for a checklist to reduce custom code.**

## Project Creation Overview

Projects are created through `JBController.launchProjectFor()` which:
1. Creates a new project NFT via JBProjects
2. Sets the controller for the project
3. Configures the first ruleset
4. Sets up terminal configurations

## Core Functions

### Launch a Project

```solidity
function launchProjectFor(
    address owner,                              // Project owner (receives NFT)
    string calldata projectUri,                 // IPFS metadata URI
    JBRulesetConfig[] calldata rulesetConfigs,  // Initial ruleset(s)
    JBTerminalConfig[] calldata terminalConfigs, // Terminal setup
    string calldata memo                        // Launch memo
) external returns (uint256 projectId);
```

### Project Metadata (projectUri)

The `projectUri` should point to a JSON file (typically on IPFS) with:

```json
{
  "name": "Project Name",
  "description": "Project description",
  "logoUri": "ipfs://...",
  "infoUri": "https://...",
  "twitter": "@handle",
  "discord": "https://discord.gg/...",
  "telegram": "https://t.me/..."
}
```

## Configuration Structs

### JBRulesetConfig

```solidity
struct JBRulesetConfig {
    uint256 mustStartAtOrAfter;     // Earliest start time (0 = now)
    uint256 duration;               // Duration in seconds (0 = indefinite)
    uint256 weight;                 // Token minting weight (18 decimals)
    uint256 weightCutPercent;       // Weight decay per cycle (0-1000000000)
    IJBRulesetApprovalHook approvalHook;  // Approval hook (e.g., JBDeadline)
    JBRulesetMetadata metadata;     // Ruleset settings
    JBSplitGroup[] splitGroups;     // Payout and reserved splits
    JBFundAccessLimitGroup[] fundAccessLimitGroups;  // Payout limits
}
```

### JBTerminalConfig

```solidity
struct JBTerminalConfig {
    IJBTerminal terminal;                   // Terminal contract
    JBAccountingContext[] accountingContexts;  // Accepted tokens
}
```

### JBAccountingContext

```solidity
struct JBAccountingContext {
    address token;          // Token address (address(0) for native)
    uint8 decimals;         // Token decimals
    uint32 currency;        // Currency ID for accounting
}
```

## Deployment Script Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {IJBController} from "@bananapus/core/src/interfaces/IJBController.sol";
import {IJBMultiTerminal} from "@bananapus/core/src/interfaces/IJBMultiTerminal.sol";
import {JBRulesetConfig} from "@bananapus/core/src/structs/JBRulesetConfig.sol";
import {JBRulesetMetadata} from "@bananapus/core/src/structs/JBRulesetMetadata.sol";
import {JBTerminalConfig} from "@bananapus/core/src/structs/JBTerminalConfig.sol";
import {JBAccountingContext} from "@bananapus/core/src/structs/JBAccountingContext.sol";
import {JBSplitGroup} from "@bananapus/core/src/structs/JBSplitGroup.sol";
import {JBSplit} from "@bananapus/core/src/structs/JBSplit.sol";
import {JBFundAccessLimitGroup} from "@bananapus/core/src/structs/JBFundAccessLimitGroup.sol";
import {JBCurrencyAmount} from "@bananapus/core/src/structs/JBCurrencyAmount.sol";
import {JBConstants} from "@bananapus/core/src/libraries/JBConstants.sol";

contract DeployProject is Script {
    // V5 Mainnet Addresses (see /references/v5-addresses.md for all networks)
    IJBController constant CONTROLLER = IJBController(0x27da30646502e2f642be5281322ae8c394f7668a);
    IJBMultiTerminal constant TERMINAL = IJBMultiTerminal(0x2db6d704058e552defe415753465df8df0361846);

    function run() external {
        vm.startBroadcast();

        // Configure ruleset metadata
        JBRulesetMetadata memory metadata = JBRulesetMetadata({
            reservedRate: 0,                    // No reserved tokens
            cashOutTaxRate: 0,                  // No cash out tax
            baseCurrency: uint32(uint160(JBConstants.NATIVE_TOKEN)),
            pausePay: false,
            pauseCashOut: false,
            pauseTransfers: false,
            allowOwnerMinting: false,
            allowTerminalMigration: false,
            allowSetTerminals: false,
            allowSetController: false,
            allowAddAccountingContexts: false,
            allowAddPriceFeed: false,
            ownerMustSendPayouts: false,
            holdFees: false,
            useTotalSurplusForCashOuts: false,
            useDataHookForPay: false,
            useDataHookForCashOut: false,
            dataHook: address(0),
            metadata: 0
        });

        // Configure splits (empty for now)
        JBSplitGroup[] memory splitGroups = new JBSplitGroup[](0);

        // Configure fund access limits
        JBFundAccessLimitGroup[] memory fundAccessLimits = new JBFundAccessLimitGroup[](0);

        // Build ruleset config
        JBRulesetConfig[] memory rulesetConfigs = new JBRulesetConfig[](1);
        rulesetConfigs[0] = JBRulesetConfig({
            mustStartAtOrAfter: 0,
            duration: 0,                        // Indefinite
            weight: 1e18,                       // 1 token per unit paid
            weightCutPercent: 0,                // No decay
            approvalHook: IJBRulesetApprovalHook(address(0)),
            metadata: metadata,
            splitGroups: splitGroups,
            fundAccessLimitGroups: fundAccessLimits
        });

        // Configure terminal to accept ETH
        JBAccountingContext[] memory accountingContexts = new JBAccountingContext[](1);
        accountingContexts[0] = JBAccountingContext({
            token: JBConstants.NATIVE_TOKEN,
            decimals: 18,
            currency: uint32(uint160(JBConstants.NATIVE_TOKEN))
        });

        JBTerminalConfig[] memory terminalConfigs = new JBTerminalConfig[](1);
        terminalConfigs[0] = JBTerminalConfig({
            terminal: TERMINAL,
            accountingContexts: accountingContexts
        });

        // Launch the project
        uint256 projectId = CONTROLLER.launchProjectFor(
            msg.sender,                         // Owner
            "ipfs://...",                       // Project metadata URI
            rulesetConfigs,
            terminalConfigs,
            "Project launch"                    // Memo
        );

        vm.stopBroadcast();
    }
}
```

## Other Project Operations

### Transfer Ownership

Project ownership is an ERC-721 NFT. Transfer using standard ERC-721:

```solidity
IJBProjects(PROJECTS).transferFrom(currentOwner, newOwner, projectId);
```

### Set Project Metadata

```solidity
IJBProjects(PROJECTS).setTokenURI(projectId, "ipfs://newUri");
```

### Add Terminals

```solidity
IJBDirectory(DIRECTORY).setTerminalsOf(projectId, terminals);
```

## Generation Guidelines

1. **Ask about project requirements** - ownership model, token economics, payout structure
2. **Consider Revnets** if autonomous operation is desired
3. **Configure appropriate metadata** - reserved rate, cash out tax, permissions
4. **Set up splits** for payouts and reserved tokens
5. **Generate deployment scripts** using Foundry

## Example Prompts

- "Create a project that mints 1000 tokens per ETH with 10% reserved"
- "Set up a project with weekly payout cycles to 3 addresses"
- "Deploy a project with a 3-day approval delay for ruleset changes"
- "Create a project that accepts both ETH and USDC"

## Reference

- **nana-core-v5**: https://github.com/Bananapus/nana-core-v5
- **revnet-core-v5**: https://github.com/rev-net/revnet-core-v5
