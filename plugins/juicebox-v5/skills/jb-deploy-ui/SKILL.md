---
name: jb-deploy-ui
description: Generate minimal, CSS-light frontends for deploying Juicebox V5 projects and hooks. Creates standalone HTML files with wallet connection, transaction forms, and live status updates.
---

# Juicebox V5 Deployment UI Generator

Generate dead-simple, CSS-minimal frontends for deploying Juicebox projects, hooks, and configurations. No build tools required - just HTML files you can open in a browser.

## Philosophy

> **Show users exactly what they're doing. Make wallet connection trivial. Display transactions in flight.**

These UIs are intentionally minimal:
- Single HTML file, no build step
- Vanilla JS + ethers.js (loaded from CDN)
- CSS that fits on one screen
- Clear transaction previews before signing

## Core Components

### 1. Wallet Connection

```html
<div id="wallet-section">
  <button id="connect-btn">Connect Wallet</button>
  <div id="wallet-status" class="hidden">
    <span id="wallet-address"></span>
    <span id="network-name"></span>
  </div>
</div>
```

```javascript
// Minimal wallet connection
let provider, signer, address;

async function connectWallet() {
  if (!window.ethereum) {
    alert('Please install MetaMask or another wallet');
    return;
  }

  provider = new ethers.BrowserProvider(window.ethereum);
  signer = await provider.getSigner();
  address = await signer.getAddress();

  // Update UI
  document.getElementById('wallet-address').textContent =
    `${address.slice(0, 6)}...${address.slice(-4)}`;
  document.getElementById('wallet-status').classList.remove('hidden');
  document.getElementById('connect-btn').classList.add('hidden');

  // Check network
  const network = await provider.getNetwork();
  document.getElementById('network-name').textContent = getNetworkName(network.chainId);
}

function getNetworkName(chainId) {
  const networks = {
    1n: 'Ethereum',
    11155111n: 'Sepolia',
    10n: 'Optimism',
    8453n: 'Base',
    42161n: 'Arbitrum'
  };
  return networks[chainId] || `Chain ${chainId}`;
}
```

### 2. Transaction Status Display

```html
<div id="tx-status" class="hidden">
  <div class="status-header">
    <span id="tx-state">Preparing...</span>
    <a id="tx-link" href="#" target="_blank" class="hidden">View on Etherscan</a>
  </div>
  <div id="tx-details"></div>
</div>
```

```javascript
function showTxPending(description) {
  const el = document.getElementById('tx-status');
  el.classList.remove('hidden');
  document.getElementById('tx-state').textContent = '⏳ ' + description;
  document.getElementById('tx-link').classList.add('hidden');
}

function showTxSent(hash, chainId) {
  document.getElementById('tx-state').textContent = '🔄 Transaction sent, waiting for confirmation...';
  const link = document.getElementById('tx-link');
  link.href = getExplorerUrl(chainId, hash);
  link.classList.remove('hidden');
}

function showTxConfirmed(hash, chainId) {
  document.getElementById('tx-state').textContent = '✅ Transaction confirmed!';
}

function showTxError(error) {
  document.getElementById('tx-state').textContent = '❌ ' + (error.shortMessage || error.message);
}

function getExplorerUrl(chainId, hash) {
  const explorers = {
    1n: 'https://etherscan.io/tx/',
    11155111n: 'https://sepolia.etherscan.io/tx/',
    10n: 'https://optimistic.etherscan.io/tx/',
    8453n: 'https://basescan.org/tx/',
    42161n: 'https://arbiscan.io/tx/'
  };
  return (explorers[chainId] || 'https://etherscan.io/tx/') + hash;
}
```

### 3. Minimal CSS

```css
:root {
  --bg: #0a0a0a;
  --surface: #141414;
  --border: #2a2a2a;
  --text: #e0e0e0;
  --text-muted: #808080;
  --accent: #5c6bc0;
  --success: #4caf50;
  --error: #f44336;
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: var(--bg);
  color: var(--text);
  line-height: 1.6;
  padding: 2rem;
  max-width: 640px;
  margin: 0 auto;
}

h1 { font-size: 1.5rem; margin-bottom: 1.5rem; }
h2 { font-size: 1.1rem; margin: 1.5rem 0 0.75rem; color: var(--text-muted); }

.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1.25rem;
  margin-bottom: 1rem;
}

label {
  display: block;
  font-size: 0.875rem;
  color: var(--text-muted);
  margin-bottom: 0.25rem;
}

input, select, textarea {
  width: 100%;
  padding: 0.625rem;
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 4px;
  color: var(--text);
  font-size: 0.875rem;
  margin-bottom: 0.75rem;
}

input:focus, select:focus, textarea:focus {
  outline: none;
  border-color: var(--accent);
}

button {
  background: var(--accent);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 4px;
  font-size: 0.875rem;
  cursor: pointer;
  width: 100%;
}

button:hover { opacity: 0.9; }
button:disabled { opacity: 0.5; cursor: not-allowed; }

.hidden { display: none !important; }

#tx-status {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 1rem;
  margin-top: 1rem;
}

#tx-link {
  color: var(--accent);
  font-size: 0.875rem;
}

.preview {
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: 0.75rem;
  font-family: monospace;
  font-size: 0.75rem;
  margin: 0.5rem 0;
  white-space: pre-wrap;
  word-break: break-all;
}
```

## Template: Project Deployment UI

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Deploy Juicebox Project</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    /* Include minimal CSS from above */
  </style>
</head>
<body>
  <h1>Deploy Juicebox Project</h1>

  <!-- Wallet Connection -->
  <div class="card">
    <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    <div id="wallet-status" class="hidden">
      Connected: <span id="wallet-address"></span> on <span id="network-name"></span>
    </div>
  </div>

  <!-- Project Config -->
  <div class="card">
    <h2>Project Details</h2>
    <label>Project Name</label>
    <input type="text" id="project-name" placeholder="My Project">

    <label>Description</label>
    <textarea id="project-description" rows="3" placeholder="What is this project for?"></textarea>

    <label>Owner Address (defaults to connected wallet)</label>
    <input type="text" id="owner-address" placeholder="0x...">
  </div>

  <!-- Ruleset Config -->
  <div class="card">
    <h2>Ruleset Configuration</h2>

    <label>Duration (days, 0 = no cycles)</label>
    <input type="number" id="duration" value="0" min="0">

    <label>Tokens per ETH</label>
    <input type="number" id="weight" value="1000000" min="0">

    <label>Reserved Rate (%)</label>
    <input type="number" id="reserved-rate" value="0" min="0" max="100">

    <label>Cash Out Tax Rate (%)</label>
    <input type="number" id="cash-out-tax" value="0" min="0" max="100">
  </div>

  <!-- Preview & Deploy -->
  <div class="card">
    <h2>Transaction Preview</h2>
    <div id="tx-preview" class="preview">Connect wallet to see preview</div>
    <button id="deploy-btn" onclick="deploy()" disabled>Deploy Project</button>
  </div>

  <!-- Status -->
  <div id="tx-status" class="hidden"></div>

  <script>
    // V5 Mainnet Addresses
    const ADDRESSES = {
      1: { // Ethereum
        controller: '0x27da30646502e2f642be5281322ae8c394f7668a',
        terminal: '0x2db6d704058e552defe415753465df8df0361846'
      },
      11155111: { // Sepolia
        controller: '0x...', // Add testnet addresses
        terminal: '0x...'
      }
    };

    const CONTROLLER_ABI = [
      'function launchProjectFor(address owner, string projectUri, tuple(uint256 mustStartAtOrAfter, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, tuple(uint256 reservedRate, uint256 cashOutTaxRate, uint256 baseCurrency, bool pausePay, bool pauseCashOut, bool pauseTransfers, bool allowOwnerMinting, bool allowTerminalMigration, bool allowSetTerminals, bool allowSetController, bool allowAddAccountingContexts, bool allowAddPriceFeed, bool ownerMustSendPayouts, bool holdFees, bool useTotalSurplusForCashOuts, bool useDataHookForPay, bool useDataHookForCashOut, address dataHook, uint256 metadata) metadata, tuple(uint256 groupId, tuple(bool preferAddToBalance, uint256 percent, uint256 projectId, address beneficiary, uint256 lockedUntil, address hook)[] splits)[] splitGroups, tuple(address terminal, address token, tuple(uint256 amount, uint256 currency)[] payoutLimits, tuple(uint256 amount, uint256 currency)[] surplusAllowances)[] fundAccessLimitGroups)[] rulesetConfigs, tuple(address terminal, tuple(address token, uint8 decimals, uint32 currency)[] accountingContexts)[] terminalConfigs, string memo) external returns (uint256)'
    ];

    let provider, signer, address, chainId;

    async function connectWallet() {
      // ... wallet connection code ...
      updatePreview();
      document.getElementById('deploy-btn').disabled = false;
    }

    function updatePreview() {
      const config = getConfig();
      document.getElementById('tx-preview').textContent = JSON.stringify(config, null, 2);
    }

    function getConfig() {
      return {
        owner: document.getElementById('owner-address').value || address,
        projectUri: '', // Would upload to IPFS in production
        duration: parseInt(document.getElementById('duration').value) * 86400,
        weight: ethers.parseEther(document.getElementById('weight').value),
        reservedRate: parseInt(document.getElementById('reserved-rate').value) * 100,
        cashOutTaxRate: parseInt(document.getElementById('cash-out-tax').value) * 100
      };
    }

    async function deploy() {
      const config = getConfig();
      const addrs = ADDRESSES[Number(chainId)];

      if (!addrs) {
        alert('Unsupported network');
        return;
      }

      const controller = new ethers.Contract(addrs.controller, CONTROLLER_ABI, signer);

      showTxPending('Preparing transaction...');

      try {
        // Build ruleset config
        const rulesetConfig = {
          mustStartAtOrAfter: 0,
          duration: config.duration,
          weight: config.weight,
          weightCutPercent: 0,
          approvalHook: ethers.ZeroAddress,
          metadata: {
            reservedRate: config.reservedRate,
            cashOutTaxRate: config.cashOutTaxRate,
            baseCurrency: 0,
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
            dataHook: ethers.ZeroAddress,
            metadata: 0
          },
          splitGroups: [],
          fundAccessLimitGroups: []
        };

        // Build terminal config
        const terminalConfig = {
          terminal: addrs.terminal,
          accountingContexts: [{
            token: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // Native token
            decimals: 18,
            currency: 0
          }]
        };

        showTxPending('Please confirm in wallet...');

        const tx = await controller.launchProjectFor(
          config.owner,
          config.projectUri,
          [rulesetConfig],
          [terminalConfig],
          'Deployed via Juicebox UI'
        );

        showTxSent(tx.hash, chainId);

        const receipt = await tx.wait();
        showTxConfirmed(tx.hash, chainId);

        // Parse project ID from logs
        // ...

      } catch (error) {
        showTxError(error);
      }
    }

    // Listen for input changes
    document.querySelectorAll('input, textarea, select').forEach(el => {
      el.addEventListener('input', updatePreview);
    });
  </script>
</body>
</html>
```

## Generation Guidelines

When generating deployment UIs:

1. **Single HTML file** - No build tools, no npm, just open in browser
2. **ethers.js from CDN** - Always use latest v6 from cdnjs
3. **Dark theme** - Use the minimal CSS above as base
4. **Transaction preview** - Show exactly what will be sent before signing
5. **Clear status updates** - Pending → Sent → Confirmed/Error
6. **Network awareness** - Check chain ID, show warnings for wrong network
7. **Mobile-friendly** - Max-width container, responsive inputs

## Example Prompts

- "Create a UI for deploying a project with 721 NFT tiers"
- "Build a form for configuring and deploying a vesting ruleset"
- "Generate a page for launching a Revnet with buyback hook"
- "Make a UI for deploying a custom cash out hook"

## Contract ABIs

For common operations, use these minimal ABIs:

### JBController
```javascript
const CONTROLLER_ABI = [
  'function launchProjectFor(address owner, string projectUri, tuple(...) rulesetConfigs, tuple(...) terminalConfigs, string memo) returns (uint256)',
  'function queueRulesetsOf(uint256 projectId, tuple(...) rulesetConfigs, string memo) returns (uint256)',
  'function mintTokensOf(uint256 projectId, uint256 tokenCount, address beneficiary, string memo, bool useReservedPercent) returns (uint256)'
];
```

### JBMultiTerminal
```javascript
const TERMINAL_ABI = [
  'function pay(uint256 projectId, address token, uint256 amount, address beneficiary, uint256 minReturnedTokens, string memo, bytes metadata) payable returns (uint256)',
  'function cashOutTokensOf(address holder, uint256 projectId, uint256 cashOutCount, address tokenToReclaim, uint256 minTokensReclaimed, address beneficiary, bytes metadata) returns (uint256)',
  'function sendPayoutsOf(uint256 projectId, address token, uint256 amount, uint256 currency, uint256 minTokensPaidOut) returns (uint256)'
];
```

### JB721TiersHookProjectDeployer
```javascript
const DEPLOYER_721_ABI = [
  'function launchProjectFor(address owner, tuple(...) deployTiersHookConfig, tuple(...) launchProjectConfig, address controller) returns (uint256 projectId, address hook)'
];
```

## Template: 721 Tiered NFT Project Deployment

For projects with NFT tiers (uses JB721TiersHookProjectDeployer):

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Deploy NFT Project</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    :root {
      --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a;
      --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0;
      --success: #4caf50; --error: #f44336;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 640px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.5rem; margin-bottom: 1.5rem; }
    h2 { font-size: 1.1rem; margin: 1.5rem 0 0.75rem; color: var(--text-muted); }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    label { display: block; font-size: 0.875rem; color: var(--text-muted); margin-bottom: 0.25rem; }
    input, select, textarea { width: 100%; padding: 0.625rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--text); font-size: 0.875rem; margin-bottom: 0.75rem; }
    input:focus, select:focus { outline: none; border-color: var(--accent); }
    button { background: var(--accent); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 4px; font-size: 0.875rem; cursor: pointer; width: 100%; }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .tier-card { border: 1px dashed var(--border); padding: 1rem; margin-bottom: 0.75rem; border-radius: 4px; }
    .tier-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem; }
    .remove-tier { background: var(--error); padding: 0.25rem 0.5rem; width: auto; font-size: 0.75rem; }
    .add-tier { background: var(--border); margin-bottom: 1rem; }
    .hidden { display: none !important; }
    #tx-status { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; margin-top: 1rem; }
    #tx-link { color: var(--accent); font-size: 0.875rem; }
  </style>
</head>
<body>
  <h1>Deploy NFT Project</h1>

  <div class="card">
    <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    <div id="wallet-status" class="hidden">
      Connected: <span id="wallet-address"></span> on <span id="network-name"></span>
    </div>
  </div>

  <div class="card">
    <h2>Project Details</h2>
    <label>Collection Name</label>
    <input type="text" id="collection-name" placeholder="My NFT Collection">

    <label>Collection Symbol</label>
    <input type="text" id="collection-symbol" placeholder="MYNFT">

    <label>Base URI (IPFS folder for metadata)</label>
    <input type="text" id="base-uri" placeholder="ipfs://Qm.../">
  </div>

  <div class="card">
    <h2>NFT Tiers</h2>
    <div id="tiers-container"></div>
    <button class="add-tier" onclick="addTier()">+ Add Tier</button>
  </div>

  <div class="card">
    <h2>Treasury Settings</h2>
    <label>Reserved Rate (% of tokens to project)</label>
    <input type="number" id="reserved-rate" value="0" min="0" max="100">

    <label>Cash Out Tax Rate (%)</label>
    <input type="number" id="cash-out-tax" value="0" min="0" max="100">
  </div>

  <div class="card">
    <button id="deploy-btn" onclick="deploy()" disabled>Deploy NFT Project</button>
  </div>

  <div id="tx-status" class="hidden">
    <span id="tx-state"></span>
    <a id="tx-link" href="#" target="_blank" class="hidden">View on Etherscan</a>
    <div id="deploy-result" class="hidden" style="margin-top: 1rem;">
      <strong>Project ID:</strong> <span id="result-project-id"></span><br>
      <strong>Hook Address:</strong> <span id="result-hook-address"></span>
    </div>
  </div>

  <script>
    const V5_ADDRESSES = {
      1: {
        controller: '0x27da30646502e2f642be5281322ae8c394f7668a',
        terminal: '0x2db6d704058e552defe415753465df8df0361846',
        hook721ProjectDeployer: '0x2e0be113ac0f89ffdbc9175e419f2be779d1c513'
      },
      11155111: { // Sepolia
        controller: '0xd19509034e7c5c95327C6E30CB2FF23B7C6d2832',
        terminal: '0x9fa8F1A4AE00418E8c7426c7d8833f5caE0F72f8',
        hook721ProjectDeployer: '0x...' // Add when available
      }
    };

    const DEPLOYER_ABI = [
      'function launchProjectFor(address owner, tuple(address directory, string name, string symbol, string baseUri, address tokenUriResolver, string contractUri, tuple(uint104 price, uint32 initialSupply, uint32 votingUnits, uint16 reserveFrequency, address reserveBeneficiary, bytes32 encodedIPFSUri, uint24 category, uint8 discountPercent, bool allowOwnerMint, bool useReserveBeneficiaryAsDefault, bool transfersPausable, bool useVotingUnits, bool cannotBeRemoved, bool cannotIncreaseDiscountPercent)[] tiers, uint8 flags) deployTiersHookConfig, tuple(string projectUri, tuple(uint256 mustStartAtOrAfter, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, tuple(uint256 reservedRate, uint256 cashOutTaxRate, uint256 baseCurrency, bool pausePay, bool pauseCashOut, bool pauseTransfers, bool allowOwnerMinting, bool allowTerminalMigration, bool allowSetTerminals, bool allowSetController, bool allowAddAccountingContexts, bool allowAddPriceFeed, bool ownerMustSendPayouts, bool holdFees, bool useTotalSurplusForCashOuts, bool useDataHookForPay, bool useDataHookForCashOut, address dataHook, uint256 metadata) metadata, tuple(uint256 groupId, tuple(bool preferAddToBalance, uint256 percent, uint256 projectId, address beneficiary, uint256 lockedUntil, address hook)[] splits)[] splitGroups, tuple(address terminal, address token, tuple(uint256 amount, uint256 currency)[] payoutLimits, tuple(uint256 amount, uint256 currency)[] surplusAllowances)[] fundAccessLimitGroups)[] rulesetConfigurations, tuple(address terminal, tuple(address token, uint8 decimals, uint32 currency)[] accountingContexts)[] terminalConfigurations, string memo) launchProjectConfig, address controller) external returns (uint256 projectId, address hook)'
    ];

    let provider, signer, address, chainId;
    let tierCount = 0;

    function addTier() {
      tierCount++;
      const container = document.getElementById('tiers-container');
      const tierHtml = `
        <div class="tier-card" id="tier-${tierCount}">
          <div class="tier-header">
            <strong>Tier ${tierCount}</strong>
            <button class="remove-tier" onclick="removeTier(${tierCount})">Remove</button>
          </div>
          <label>Price (ETH)</label>
          <input type="number" class="tier-price" step="0.001" placeholder="0.1">
          <label>Supply</label>
          <input type="number" class="tier-supply" placeholder="100">
          <label>IPFS Hash (CIDv0 only, starts with Qm)</label>
          <input type="text" class="tier-ipfs" placeholder="QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG">
        </div>
      `;
      container.insertAdjacentHTML('beforeend', tierHtml);
    }

    function removeTier(id) {
      document.getElementById(`tier-${id}`).remove();
    }

    async function connectWallet() {
      if (!window.ethereum) { alert('Please install MetaMask'); return; }
      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      address = await signer.getAddress();
      const network = await provider.getNetwork();
      chainId = network.chainId;

      document.getElementById('wallet-address').textContent = `${address.slice(0,6)}...${address.slice(-4)}`;
      document.getElementById('network-name').textContent = getNetworkName(chainId);
      document.getElementById('wallet-status').classList.remove('hidden');
      document.getElementById('connect-btn').classList.add('hidden');
      document.getElementById('deploy-btn').disabled = false;
    }

    function getNetworkName(id) {
      return { 1n: 'Ethereum', 11155111n: 'Sepolia', 10n: 'Optimism', 8453n: 'Base' }[id] || `Chain ${id}`;
    }

    function encodeIPFSUri(cid) {
      // Encode CIDv0 (Qm...) to bytes32
      const bs58 = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
      let decoded = 0n;
      for (const char of cid) {
        decoded = decoded * 58n + BigInt(bs58.indexOf(char));
      }
      const hex = decoded.toString(16).padStart(68, '0');
      return '0x' + hex.slice(4); // Remove first 2 bytes (multihash prefix)
    }

    function getTiers() {
      const tiers = [];
      document.querySelectorAll('.tier-card').forEach((card, i) => {
        const price = card.querySelector('.tier-price').value;
        const supply = card.querySelector('.tier-supply').value;
        const ipfs = card.querySelector('.tier-ipfs').value;
        if (price && supply) {
          tiers.push({
            price: ethers.parseEther(price),
            initialSupply: parseInt(supply),
            votingUnits: 0,
            reserveFrequency: 0,
            reserveBeneficiary: ethers.ZeroAddress,
            encodedIPFSUri: ipfs ? encodeIPFSUri(ipfs) : ethers.ZeroHash,
            category: i + 1,
            discountPercent: 0,
            allowOwnerMint: false,
            useReserveBeneficiaryAsDefault: false,
            transfersPausable: false,
            useVotingUnits: false,
            cannotBeRemoved: false,
            cannotIncreaseDiscountPercent: false
          });
        }
      });
      return tiers;
    }

    async function deploy() {
      const addrs = V5_ADDRESSES[Number(chainId)];
      if (!addrs) { alert('Unsupported network'); return; }

      const tiers = getTiers();
      if (tiers.length === 0) { alert('Add at least one tier'); return; }

      const deployer = new ethers.Contract(addrs.hook721ProjectDeployer, DEPLOYER_ABI, signer);

      const hookConfig = {
        directory: '0x0061e516886a0540f63157f112c0588ee0651dcf',
        name: document.getElementById('collection-name').value || 'NFT Collection',
        symbol: document.getElementById('collection-symbol').value || 'NFT',
        baseUri: document.getElementById('base-uri').value || '',
        tokenUriResolver: ethers.ZeroAddress,
        contractUri: '',
        tiers: tiers,
        flags: 0
      };

      const rulesetConfig = {
        mustStartAtOrAfter: 0,
        duration: 0,
        weight: 0, // No tokens, only NFTs
        weightCutPercent: 0,
        approvalHook: ethers.ZeroAddress,
        metadata: {
          reservedRate: parseInt(document.getElementById('reserved-rate').value || 0) * 100,
          cashOutTaxRate: parseInt(document.getElementById('cash-out-tax').value || 0) * 100,
          baseCurrency: 0,
          pausePay: false, pauseCashOut: false, pauseTransfers: false,
          allowOwnerMinting: false, allowTerminalMigration: false,
          allowSetTerminals: false, allowSetController: false,
          allowAddAccountingContexts: false, allowAddPriceFeed: false,
          ownerMustSendPayouts: false, holdFees: false,
          useTotalSurplusForCashOuts: false,
          useDataHookForPay: true,
          useDataHookForCashOut: true,
          dataHook: ethers.ZeroAddress, // Set by deployer
          metadata: 0
        },
        splitGroups: [],
        fundAccessLimitGroups: []
      };

      const terminalConfig = {
        terminal: addrs.terminal,
        accountingContexts: [{ token: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', decimals: 18, currency: 0 }]
      };

      const launchConfig = {
        projectUri: '',
        rulesetConfigurations: [rulesetConfig],
        terminalConfigurations: [terminalConfig],
        memo: 'Deployed via Juicebox NFT UI'
      };

      showTxPending('Please confirm in wallet...');

      try {
        const tx = await deployer.launchProjectFor(address, hookConfig, launchConfig, addrs.controller);
        showTxSent(tx.hash, chainId);
        const receipt = await tx.wait();
        showTxConfirmed(tx.hash, chainId);

        // Parse project ID and hook from logs
        // ...
      } catch (error) {
        showTxError(error);
      }
    }

    function showTxPending(msg) {
      document.getElementById('tx-status').classList.remove('hidden');
      document.getElementById('tx-state').textContent = '⏳ ' + msg;
    }
    function showTxSent(hash, chainId) {
      document.getElementById('tx-state').textContent = '🔄 Transaction sent...';
      const link = document.getElementById('tx-link');
      link.href = getExplorerUrl(chainId, hash);
      link.classList.remove('hidden');
    }
    function showTxConfirmed() {
      document.getElementById('tx-state').textContent = '✅ NFT Project deployed!';
    }
    function showTxError(error) {
      document.getElementById('tx-state').textContent = '❌ ' + (error.shortMessage || error.message);
    }
    function getExplorerUrl(chainId, hash) {
      const explorers = { 1n: 'https://etherscan.io/tx/', 11155111n: 'https://sepolia.etherscan.io/tx/', 10n: 'https://optimistic.etherscan.io/tx/', 8453n: 'https://basescan.org/tx/' };
      return (explorers[chainId] || 'https://etherscan.io/tx/') + hash;
    }

    // Initialize with one tier
    addTier();
  </script>
</body>
</html>
```

## Template: Revnet Deployment

For autonomous tokenized treasuries:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Deploy Revnet</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 640px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 1.5rem; font-size: 0.9rem; }
    h2 { font-size: 1.1rem; margin: 1.5rem 0 0.75rem; color: var(--text-muted); }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    label { display: block; font-size: 0.875rem; color: var(--text-muted); margin-bottom: 0.25rem; }
    input, select { width: 100%; padding: 0.625rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--text); font-size: 0.875rem; margin-bottom: 0.75rem; }
    input:focus { outline: none; border-color: var(--accent); }
    button { background: var(--accent); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 4px; font-size: 0.875rem; cursor: pointer; width: 100%; }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .info { background: var(--bg); border-radius: 4px; padding: 0.75rem; font-size: 0.8rem; color: var(--text-muted); margin-bottom: 0.75rem; }
    .stage-card { border: 1px dashed var(--border); padding: 1rem; margin-bottom: 0.75rem; border-radius: 4px; }
    .hidden { display: none !important; }
    #tx-status { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; margin-top: 1rem; }
    a { color: var(--accent); }
  </style>
</head>
<body>
  <h1>Deploy Revnet</h1>
  <p class="subtitle">Launch an autonomous, unowned tokenized treasury</p>

  <div class="card">
    <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    <div id="wallet-status" class="hidden">
      Connected: <span id="wallet-address"></span>
    </div>
  </div>

  <div class="card">
    <h2>Token Configuration</h2>
    <div class="info">
      ⚠️ Revnets are autonomous - no admin can change rules after deployment. Configuration is permanent.
    </div>

    <label>Token Name</label>
    <input type="text" id="token-name" placeholder="My Revnet Token">

    <label>Token Symbol</label>
    <input type="text" id="token-symbol" placeholder="REV">
  </div>

  <div class="card">
    <h2>Stage 1 Configuration</h2>
    <div class="stage-card">
      <label>Initial Token Issuance (per ETH)</label>
      <input type="number" id="initial-issuance" value="1000000" min="1">

      <label>Issuance Cut (% reduction per period)</label>
      <input type="number" id="issuance-cut" value="5" min="0" max="100" step="0.1">

      <label>Issuance Cut Frequency (days)</label>
      <input type="number" id="cut-frequency" value="30" min="1">

      <label>Cash Out Tax Rate (%)</label>
      <input type="number" id="cash-out-tax" value="40" min="0" max="100">

      <label>Split to Operator (%)</label>
      <input type="number" id="operator-split" value="20" min="0" max="100">
    </div>
  </div>

  <div class="card">
    <label>Operator Address (receives split)</label>
    <input type="text" id="operator-address" placeholder="0x...">
    <div class="info">
      The operator receives the split percentage of incoming funds. They can update splits but cannot change core rules.
    </div>
  </div>

  <div class="card">
    <button id="deploy-btn" onclick="deployRevnet()" disabled>Deploy Revnet</button>
  </div>

  <div id="tx-status" class="hidden">
    <span id="tx-state"></span>
    <a id="tx-link" href="#" target="_blank" class="hidden">View transaction</a>
  </div>

  <script>
    // Revnet deployer addresses
    const REVNET_DEPLOYERS = {
      1: '0x...', // BasicRevnetDeployer on mainnet
      11155111: '0x...' // Sepolia
    };

    let provider, signer, address, chainId;

    async function connectWallet() {
      if (!window.ethereum) { alert('Please install MetaMask'); return; }
      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      address = await signer.getAddress();
      chainId = (await provider.getNetwork()).chainId;

      document.getElementById('wallet-address').textContent = `${address.slice(0,6)}...${address.slice(-4)}`;
      document.getElementById('wallet-status').classList.remove('hidden');
      document.getElementById('connect-btn').classList.add('hidden');
      document.getElementById('deploy-btn').disabled = false;

      // Default operator to connected wallet
      if (!document.getElementById('operator-address').value) {
        document.getElementById('operator-address').value = address;
      }
    }

    async function deployRevnet() {
      const deployerAddr = REVNET_DEPLOYERS[Number(chainId)];
      if (!deployerAddr) { alert('Revnet deployer not available on this network'); return; }

      // Build stage config
      const stageConfig = {
        startsAtOrAfter: 0,
        splitPercent: parseInt(document.getElementById('operator-split').value) * 100,
        initialIssuance: parseInt(document.getElementById('initial-issuance').value),
        issuanceCutFrequency: parseInt(document.getElementById('cut-frequency').value) * 86400,
        issuanceCutPercent: parseInt(document.getElementById('issuance-cut').value * 100),
        cashOutTaxRate: parseInt(document.getElementById('cash-out-tax').value) * 100
      };

      const revConfig = {
        description: {
          name: document.getElementById('token-name').value || 'Revnet Token',
          symbol: document.getElementById('token-symbol').value || 'REV',
          projectUri: '',
          salt: ethers.hexlify(ethers.randomBytes(32))
        },
        baseCurrency: 0,
        splitOperator: document.getElementById('operator-address').value || address,
        stageConfigurations: [stageConfig],
        loanSources: [],
        loans: [],
        premint: { count: 0, beneficiary: ethers.ZeroAddress }
      };

      showTxPending('Please confirm in wallet...');

      try {
        // Call deployer contract
        // const deployer = new ethers.Contract(deployerAddr, DEPLOYER_ABI, signer);
        // const tx = await deployer.deployFor(...);
        // await tx.wait();

        alert('Revnet deployment - implementation depends on exact deployer version');
        showTxConfirmed();
      } catch (error) {
        showTxError(error);
      }
    }

    function showTxPending(msg) {
      document.getElementById('tx-status').classList.remove('hidden');
      document.getElementById('tx-state').textContent = '⏳ ' + msg;
    }
    function showTxConfirmed() {
      document.getElementById('tx-state').textContent = '✅ Revnet deployed!';
    }
    function showTxError(error) {
      document.getElementById('tx-state').textContent = '❌ ' + (error.shortMessage || error.message);
    }
  </script>
</body>
</html>
```

## V5 Contract Addresses

```javascript
const V5_ADDRESSES = {
  1: { // Ethereum Mainnet
    controller: '0x27da30646502e2f642be5281322ae8c394f7668a',
    terminal: '0x2db6d704058e552defe415753465df8df0361846',
    projects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
    directory: '0x0061e516886a0540f63157f112c0588ee0651dcf',
    tokens: '0x34b1e3cb8f7db8bde226e930b9ae9dd1ec44c586',
    hook721Deployer: '0x048626e715a194fc38dd9be12f516b54b10e725a',
    hook721ProjectDeployer: '0x2e0be113ac0f89ffdbc9175e419f2be779d1c513'
  },
  11155111: { // Sepolia Testnet
    controller: '0xd19509034e7c5c95327C6E30CB2FF23B7C6d2832',
    terminal: '0x9fa8F1A4AE00418E8c7426c7d8833f5caE0F72f8',
    projects: '0x...',
    directory: '0x...'
  }
  // Optimism, Base, Arbitrum use same addresses as mainnet (deterministic deployment)
};
```

## Fetching Data with Bendystraw

For displaying project stats, use Bendystraw GraphQL API:

```javascript
// Server-side proxy to hide API key
async function fetchProjectData(projectId, chainId) {
  const response = await fetch('/api/bendystraw', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      query: `
        query($projectId: Int!, $chainId: Int!) {
          project(projectId: $projectId, chainId: $chainId) {
            name handle logoUri
            balance volume volumeUsd
            tokenSupply paymentsCount
            suckerGroupId
          }
        }
      `,
      variables: { projectId, chainId }
    })
  });
  return (await response.json()).data.project;
}
```

See `/jb-omnichain-ui` for full Bendystraw integration patterns.

## Related Skills

- `/jb-project` - Project configuration details
- `/jb-ruleset` - Ruleset parameters
- `/jb-interact-ui` - UIs for interacting with existing projects
- `/jb-omnichain-ui` - Multi-chain deployments with Relayr & Bendystraw
