# Juicebox V5 Shared Components

Common utilities, styles, and configurations for Juicebox V5 UI skills.

## V5.1 Contract Update (Dec 2025)

**Only JBRulesets has a code change** (one-line approval hook fix). Other contracts were redeployed due to dependency chains.

| Use Case | Version |
|----------|---------|
| **New projects** | V5.1 (`contracts` in chain-config.json) |
| **Revnets** | V5.0 (`contractsV5` in chain-config.json) |

**Do not mix V5.0 and V5.1 contracts.**

### Dependency Chain (why contracts were redeployed)

```
JBRulesets5_1 ← Actual code fix
    ↓
JBController5_1 ← depends on JBRulesets
JBTerminalStore5_1 ← depends on JBRulesets
    ↓
JBMultiTerminal5_1 ← depends on JBTerminalStore
JB721TiersHook5_1 ← depends on JBRulesets
    ↓
JB721TiersHookDeployer5_1 ← depends on JB721TiersHook
    ↓
JBOmnichainDeployer5_1 ← depends on JB721TiersHookDeployer
```

---

## Files

| File | Purpose |
|------|---------|
| `styles.css` | Dark theme CSS with JB brand colors |
| `wallet-utils.js` | Wallet connection using viem |
| `chain-config.json` | RPC URLs, explorers, V5.0 & V5.1 addresses |
| `abis/*.json` | Complete ABIs for all V5 ecosystem contracts |

---

## Available ABIs

Complete ABIs extracted from all V5 ecosystem repositories:

### nana-core-v5 (Core Protocol)
- `JBController.json`, `JBController5_1.json` - Project management
- `JBMultiTerminal.json`, `JBMultiTerminal5_1.json` - Payments and distributions
- `JBTerminalStore.json`, `JBTerminalStore5_1.json` - Terminal accounting
- `JBDirectory.json` - Terminal/controller registry
- `JBProjects.json` - Project NFTs (ERC-721)
- `JBTokens.json` - Token accounting
- `JBRulesets.json`, `JBRulesets5_1.json` - Ruleset management
- `JBSplits.json` - Split configuration
- `JBPermissions.json` - Access control
- `JBFundAccessLimits.json` - Payout/allowance limits
- `JBPrices.json` - Price feed registry
- `JBFeelessAddresses.json` - Fee exemptions
- `JBERC20.json` - Standard project token
- `JBDeadline1Day.json`, `JBDeadline3Days.json`, `JBDeadline3Hours.json`, `JBDeadline7Days.json` - Approval hooks
- `JBChainlinkV3PriceFeed.json`, `JBMatchingPriceFeed.json` - Price feeds
- `ERC2771Forwarder.json` - Meta-transactions

### nana-721-hook-v5 (NFT Tiers)
- `JB721TiersHook.json`, `JB721TiersHook5_1.json` - Tiered NFT hook
- `JB721TiersHookStore.json` - NFT tier storage
- `JB721TiersHookDeployer.json`, `JB721TiersHookDeployer5_1.json` - Hook deployment
- `JB721TiersHookProjectDeployer.json`, `JB721TiersHookProjectDeployer5_1.json` - Project + hook deployment

### nana-buyback-hook-v5 (Token Buybacks)
- `JBBuybackHook.json` - Uniswap V3 buyback hook
- `JBBuybackHookRegistry.json` - Hook registry

### nana-swap-terminal-v5 (Multi-Token Payments)
- `JBSwapTerminal.json` - Accept any token, swap to ETH
- `JBSwapTerminalRegistry.json` - Pool registry
- `JBSwapTerminalUSDCRegistry.json` - USDC pool registry

### nana-suckers-v5 (Cross-Chain Bridging)
- `JBSuckerRegistry.json` - Sucker registry
- `JBOptimismSucker.json`, `JBOptimismSuckerDeployer.json` - Optimism bridge
- `JBBaseSucker.json`, `JBBaseSuckerDeployer.json` - Base bridge
- `JBArbitrumSucker.json`, `JBArbitrumSuckerDeployer.json` - Arbitrum bridge
- `JBCCIPSucker.json`, `JBCCIPSuckerDeployer.json` - CCIP bridge

### nana-omnichain-deployers-v5 (Multi-Chain Deploy)
- `JBOmnichainDeployer.json`, `JBOmnichainDeployer5_1.json` - Deploy across chains

### nana-address-registry-v5 (Address Mapping)
- `JBAddressRegistry.json` - Cross-chain address registry

### revnet-core-v5 (Autonomous Treasuries)
- `REVDeployer.json` - Revnet deployment
- `REVLoans.json` - Token-backed loans

### croptop-core-v5 (Public NFT Posting)
- `CTPublisher.json` - NFT publishing
- `CTDeployer.json` - Croptop deployment
- `CTProjectOwner.json` - Project ownership

---

## Quick Start

Complete example: connect wallet, read project data, send payment.

```html
<script type="module">
import { createPublicClient, createWalletClient, http, custom, parseEther } from 'https://esm.sh/viem';
import { mainnet } from 'https://esm.sh/viem/chains';
import { loadABI, getContractAddress, truncateAddress } from '/shared/wallet-utils.js';

const CHAIN_ID = 1;
const PROJECT_ID = 1n;

// 1. Setup clients
const publicClient = createPublicClient({ chain: mainnet, transport: http() });
const [address] = await window.ethereum.request({ method: 'eth_requestAccounts' });
const walletClient = createWalletClient({ chain: mainnet, transport: custom(window.ethereum), account: address });

// 2. Load ABI and get contract address
const terminalABI = await loadABI('JBMultiTerminal');
const terminal = getContractAddress(CHAIN_ID, 'JBMultiTerminal');

// 3. Read: get project's primary terminal
const directoryABI = await loadABI('JBDirectory');
const directory = getContractAddress(CHAIN_ID, 'JBDirectory');
const primaryTerminal = await publicClient.readContract({
  address: directory, abi: directoryABI,
  functionName: 'primaryTerminalOf', args: [PROJECT_ID, '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE']
});

// 4. Write: pay the project
const hash = await walletClient.writeContract({
  address: terminal, abi: terminalABI, functionName: 'pay',
  args: [PROJECT_ID, '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', parseEther('0.01'), address, 0n, 'Hello JB!', '0x'],
  value: parseEther('0.01')
});
console.log('Paid! Tx:', hash);
</script>
```

---

## Usage

### In HTML Templates

```html
<!DOCTYPE html>
<html>
<head>
  <!-- Load styles -->
  <link rel="stylesheet" href="/shared/styles.css">
</head>
<body>
  <script type="module">
    // Import viem
    import { createPublicClient, http } from 'https://esm.sh/viem';
    import { mainnet } from 'https://esm.sh/viem/chains';

    // Import wallet utilities
    import {
      JBWallet,
      loadChainConfig,
      formatEth,
      truncateAddress
    } from '/shared/wallet-utils.js';

    // Load chain config
    const config = await loadChainConfig();
    const controllerAddress = config.chains[1].contracts.JBController;

    // Connect wallet
    const wallet = new JBWallet();
    await wallet.connect(1);
    console.log('Connected:', wallet.formatAddress());
  </script>
</body>
</html>
```

### Loading ABIs

```javascript
// Fetch ABI for contract interactions
const res = await fetch('/shared/abis/JBController.json');
const abi = await res.json();

// Use with viem
const contract = getContract({
  address: controllerAddress,
  abi,
  client
});
```

---

## Styles Reference

### CSS Variables

```css
--jb-yellow: #ffcc00;       /* Brand color */
--bg-primary: #0a0a0a;      /* Page background */
--bg-secondary: #141414;    /* Card background */
--text-primary: #e0e0e0;    /* Body text */
--text-muted: #808080;      /* Secondary text */
--success: #4caf50;         /* Green */
--warning: #ffb74d;         /* Orange */
--error: #ef5350;           /* Red */
--accent: #5c6bc0;          /* Purple */
```

### Key Classes

| Class | Purpose |
|-------|---------|
| `.card` | Container with border and padding |
| `.btn` | Primary button (yellow) |
| `.btn-secondary` | Outlined button |
| `.badge-success/warning/error` | Status indicators |
| `.tabs` + `.tab` | Tab navigation |
| `.stats` + `.stat-card` | Statistics grid |
| `.code` | Monospace code block |
| `.loading` / `.empty` | Centered placeholder text |

---

## Chain Config Structure

```json
{
  "_version": "5.1",
  "chains": {
    "1": {
      "name": "Ethereum",
      "rpc": "https://eth.llamarpc.com",
      "explorer": "https://etherscan.io",
      "contracts": {
        "JBController": "0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1",
        "JBMultiTerminal": "0x52869db3d61dde1e391967f2ce5039ad0ecd371c",
        ...
      },
      "contractsV5": {
        "JBController": "0x27da30646502e2f642be5281322ae8c394f7668a",
        "REVDeployer": "0x2ca27bde7e7d33e353b44c27acfcf6c78dde251d",
        ...
      }
    }
  }
}
```

- `contracts`: V5.1 addresses (use for new projects)
- `contractsV5`: V5.0 addresses (use for revnets only)

---

## Wallet Utils API

### JBWallet Class

```javascript
const wallet = new JBWallet();

// Connect and switch to Ethereum mainnet
await wallet.connect(1);

// Check connection
wallet.isConnected();     // true/false
wallet.address;           // "0x..."
wallet.chainId;           // 1

// Format for display
wallet.formatAddress();   // "0x1234...5678"

// Switch chains
await wallet.switchChain(10);  // Switch to Optimism

// Disconnect
wallet.disconnect();
```

### Formatting Helpers

```javascript
truncateAddress("0x1234567890abcdef...");  // "0x1234...cdef"
formatEth(1000000000000000000n);           // "1.0000"
formatNumber(1234567);                      // "1,234,567"
formatTimeAgo(timestamp);                   // "5m ago"
formatDate(timestamp);                      // "1/15/2025, 3:30:00 PM"
```

### Explorer URLs

```javascript
getTxUrl(1, "0x...");      // "https://etherscan.io/tx/0x..."
getAddressUrl(1, "0x...");  // "https://etherscan.io/address/0x..."
```

### ABI & Address Helpers

```javascript
// Load any ecosystem ABI by name
const abi = await loadABI('JBController');
const revABI = await loadABI('REVDeployer');

// Get contract address (V5.1 by default)
const controller = getContractAddress(1, 'JBController');

// Use V5.0 addresses for revnets
const revController = getContractAddress(1, 'JBController', true);
```

---

## React / Wagmi

For React apps, use wagmi instead of the vanilla JS utilities:

```bash
npm install wagmi viem @tanstack/react-query
```

The `chain-config.json` addresses are still useful:

```typescript
import config from '/shared/chain-config.json';
const controllerAddress = config.chains[1].contracts.JBController;
```
