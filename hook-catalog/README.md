# Juicebox V5 Hook Catalog

A curated collection of reusable hook patterns for Juicebox V5 projects. These hooks can be deployed directly or used as starting points for custom implementations.

## Quick Start

```bash
# Clone the catalog
git clone https://github.com/jbx-protocol/hook-catalog.git
cd hook-catalog

# Install dependencies
forge install

# Deploy a hook
forge script script/DeployPaymentCap.s.sol --rpc-url $RPC_URL --broadcast
```

## Catalog Structure

```
hook-catalog/
├── src/
│   ├── pay-hooks/           # Payment processing hooks
│   ├── cash-out-hooks/      # Cash out (redemption) hooks
│   ├── split-hooks/         # Split distribution hooks
│   └── data-hooks/          # Data hooks (weight/rate modification)
├── test/                    # Foundry tests
├── script/                  # Deployment scripts
└── docs/                    # Extended documentation
```

## Available Hooks

### Pay Hooks

| Hook | Description | Use Case |
|------|-------------|----------|
| `PaymentCapHook` | Limits maximum payment per transaction | Prevent whale domination |
| `FundraisingCapHook` | Limits total amount a project can raise | Capped fundraising rounds |
| `AllowlistPayHook` | Restricts payments to allowlisted addresses | Private sales, KYC |
| `TimelockedPayHook` | Only accepts payments during specific windows | Scheduled fundraising |
| `ReferralPayHook` | Tracks and rewards referrers | Affiliate programs |
| `MilestonePayHook` | Unlocks features at funding milestones | Gamified fundraising |

### Cash Out Hooks

| Hook | Description | Use Case |
|------|-------------|----------|
| `VestingCashOutHook` | Time-based vesting for cash outs | Team token lockups |
| `NFTGatedCashOutHook` | Requires NFT ownership to cash out | Exclusive communities |
| `FeeCashOutHook` | Extracts fee on cash outs | Revenue generation |
| `TieredCashOutHook` | Different rates based on holding duration | Reward long-term holders |

### Split Hooks

| Hook | Description | Use Case |
|------|-------------|----------|
| `LidoSplitHook` | Deposits ETH to Lido, sends stETH | Yield generation |
| `UniswapLPSplitHook` | Adds to Uniswap V3 liquidity | LP management |
| `MultiRecipientSplitHook` | Further splits among recipients | Complex distributions |
| `SwapSplitHook` | Swaps tokens before forwarding | Diversification |
| `VestingSplitHook` | Routes to vesting contract | Team compensation |

### Data Hooks

| Hook | Description | Use Case |
|------|-------------|----------|
| `DynamicWeightHook` | Adjusts token weight based on conditions | Dynamic pricing |
| `BondingCurveHook` | Implements custom bonding curve | Token economics |
| `OracleWeightHook` | Uses Chainlink oracle for pricing | Stablecoin-pegged rates |

## Usage

### 1. Direct Deployment

Each hook includes a deployment script:

```bash
forge script script/Deploy<HookName>.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### 2. As Template

Copy the hook source and modify for your needs:

```solidity
// Start from PaymentCapHook
contract MyCustomPayHook is PaymentCapHook {
    // Add custom logic
}
```

### 3. Via Claude Code

Ask Claude to generate a custom hook:
```
Create a pay hook based on PaymentCapHook that:
- Caps payments at 10 ETH
- Only allows payments from ENS holders
- Emits a custom event
```

## Hook Development Guide

### Pay Hook Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBPayHook} from "@bananapus/core/src/interfaces/IJBPayHook.sol";
import {JBAfterPayRecordedContext} from "@bananapus/core/src/structs/JBAfterPayRecordedContext.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract MyPayHook is IJBPayHook, ERC165 {
    function afterPayRecordedWith(JBAfterPayRecordedContext calldata context) external payable override {
        // Your logic here
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IJBPayHook).interfaceId || super.supportsInterface(interfaceId);
    }
}
```

### Cash Out Hook Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBCashOutHook} from "@bananapus/core/src/interfaces/IJBCashOutHook.sol";
import {JBAfterCashOutRecordedContext} from "@bananapus/core/src/structs/JBAfterCashOutRecordedContext.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract MyCashOutHook is IJBCashOutHook, ERC165 {
    function afterCashOutRecordedWith(JBAfterCashOutRecordedContext calldata context) external payable override {
        // Your logic here
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IJBCashOutHook).interfaceId || super.supportsInterface(interfaceId);
    }
}
```

### Split Hook Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBSplitHook} from "@bananapus/core/src/interfaces/IJBSplitHook.sol";
import {JBSplitHookContext} from "@bananapus/core/src/structs/JBSplitHookContext.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract MySplitHook is IJBSplitHook, ERC165 {
    function processSplitWith(JBSplitHookContext calldata context) external payable override {
        // Your logic here
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IJBSplitHook).interfaceId || super.supportsInterface(interfaceId);
    }
}
```

## Testing

All hooks include comprehensive tests:

```bash
# Run all tests
forge test

# Run specific hook tests
forge test --match-contract PaymentCapHook

# Run with gas reporting
forge test --gas-report
```

## Security Considerations

1. **Terminal Validation**: Always verify `msg.sender` is an authorized terminal
2. **Reentrancy**: Use ReentrancyGuard for hooks that transfer funds
3. **Access Control**: Implement proper ownership/permission checks
4. **Fund Handling**: Never leave funds stuck in hooks

## Contributing

1. Fork the repository
2. Create your hook in the appropriate category
3. Add comprehensive tests
4. Submit a pull request

## License

MIT License - feel free to use these hooks in your projects.

## Resources

- [Juicebox V5 Documentation](https://docs.juicebox.money)
- [Hook Development Guide](https://docs.juicebox.money/dev/build/hooks)
- [Nana Core V5](https://github.com/Bananapus/nana-core-v5)
