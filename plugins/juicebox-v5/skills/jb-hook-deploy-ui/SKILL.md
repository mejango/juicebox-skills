---
name: jb-hook-deploy-ui
description: Deploy custom Juicebox hooks from browser. Compile Solidity, deploy contracts, verify on explorers, and attach to projects. Works with Claude-generated hooks.
---

# Juicebox V5 Hook Deployment UI

Deploy custom hooks directly from the browser. Compile Solidity code, deploy to any chain, verify on block explorers, and attach to your Juicebox project.

## Overview

```
1. Paste or load Solidity source code
2. Compile in browser using solc.js
3. Deploy via connected wallet
4. Optionally verify on Etherscan/Basescan/etc.
5. Attach hook to project ruleset
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Hook Deploy UI                        │
├─────────────────────────────────────────────────────────┤
│  Source Input    │  Compiler Output  │  Deployment      │
│  ┌────────────┐  │  ┌─────────────┐  │  ┌────────────┐  │
│  │ Paste code │  │  │ ABI         │  │  │ Deploy tx  │  │
│  │ Load file  │  │  │ Bytecode    │  │  │ Verify     │  │
│  │ From catalog│  │  │ Errors     │  │  │ Attach     │  │
│  └────────────┘  │  └─────────────┘  │  └────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Complete Hook Deploy UI Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Deploy Custom Hook</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <script src="https://binaries.soliditylang.org/bin/soljson-v0.8.23+commit.f704f362.js"></script>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; --success: #4caf50; --error: #ef5350; --warning: #ffb74d; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 1200px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 1.5rem; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    @media (max-width: 900px) { .grid { grid-template-columns: 1fr; } }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    h2 { font-size: 1.1rem; color: var(--text-muted); margin-bottom: 1rem; }
    label { display: block; font-size: 0.875rem; color: var(--text-muted); margin-bottom: 0.25rem; }
    input, select, textarea { width: 100%; padding: 0.625rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--text); font-size: 0.875rem; margin-bottom: 0.75rem; font-family: inherit; }
    textarea { font-family: 'Monaco', 'Menlo', monospace; font-size: 0.8rem; resize: vertical; }
    button { background: var(--accent); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 4px; font-size: 0.875rem; cursor: pointer; width: 100%; }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .btn-secondary { background: var(--surface); border: 1px solid var(--border); }
    .btn-success { background: var(--success); }
    .btn-row { display: flex; gap: 0.5rem; margin-bottom: 0.75rem; }
    .btn-row button { flex: 1; }
    .status { padding: 0.75rem; border-radius: 4px; margin-bottom: 0.75rem; font-size: 0.875rem; }
    .status.success { background: rgba(76, 175, 80, 0.1); border: 1px solid var(--success); color: var(--success); }
    .status.error { background: rgba(239, 83, 80, 0.1); border: 1px solid var(--error); color: var(--error); }
    .status.warning { background: rgba(255, 183, 77, 0.1); border: 1px solid var(--warning); color: var(--warning); }
    .status.info { background: rgba(92, 107, 192, 0.1); border: 1px solid var(--accent); color: var(--accent); }
    .output { background: var(--bg); border: 1px solid var(--border); border-radius: 4px; padding: 0.75rem; font-family: monospace; font-size: 0.8rem; overflow-x: auto; white-space: pre-wrap; word-break: break-all; max-height: 200px; overflow-y: auto; }
    .step { display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem 0; border-bottom: 1px solid var(--border); }
    .step:last-child { border-bottom: none; }
    .step-number { width: 28px; height: 28px; border-radius: 50%; background: var(--border); display: flex; align-items: center; justify-content: center; font-size: 0.875rem; font-weight: 600; flex-shrink: 0; }
    .step-number.active { background: var(--accent); }
    .step-number.complete { background: var(--success); }
    .step-content { flex: 1; }
    .step-title { font-weight: 500; }
    .step-desc { font-size: 0.75rem; color: var(--text-muted); }
    .tabs { display: flex; gap: 0.25rem; margin-bottom: 1rem; }
    .tab { padding: 0.5rem 1rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px 4px 0 0; cursor: pointer; font-size: 0.875rem; }
    .tab.active { background: var(--surface); border-bottom-color: var(--surface); }
    .hidden { display: none !important; }
    .constructor-args { margin-top: 1rem; padding-top: 1rem; border-top: 1px solid var(--border); }
    .arg-input { margin-bottom: 0.5rem; }
    .arg-input label { font-size: 0.75rem; }
    .chain-select { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem; }
    .chain-chip { padding: 0.5rem 1rem; border: 1px solid var(--border); border-radius: 4px; cursor: pointer; font-size: 0.875rem; }
    .chain-chip.selected { background: var(--accent); border-color: var(--accent); }
  </style>
</head>
<body>
  <h1>Deploy Custom Hook</h1>
  <p class="subtitle">Compile, deploy, and attach hooks to your Juicebox project</p>

  <!-- Wallet Connection -->
  <div class="card">
    <div class="btn-row">
      <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    </div>
    <div id="wallet-info" class="hidden">
      <div class="status info">
        Connected: <span id="wallet-address"></span> on <span id="wallet-chain"></span>
      </div>
    </div>
  </div>

  <!-- Progress Steps -->
  <div class="card">
    <div class="step">
      <div class="step-number" id="step1-num">1</div>
      <div class="step-content">
        <div class="step-title">Source Code</div>
        <div class="step-desc">Paste or load Solidity code</div>
      </div>
    </div>
    <div class="step">
      <div class="step-number" id="step2-num">2</div>
      <div class="step-content">
        <div class="step-title">Compile</div>
        <div class="step-desc">Generate ABI and bytecode</div>
      </div>
    </div>
    <div class="step">
      <div class="step-number" id="step3-num">3</div>
      <div class="step-content">
        <div class="step-title">Deploy</div>
        <div class="step-desc">Deploy contract to chain</div>
      </div>
    </div>
    <div class="step">
      <div class="step-number" id="step4-num">4</div>
      <div class="step-content">
        <div class="step-title">Attach</div>
        <div class="step-desc">Set as project hook</div>
      </div>
    </div>
  </div>

  <div class="grid">
    <!-- Left Column: Source & Compile -->
    <div>
      <!-- Source Input -->
      <div class="card">
        <h2>Source Code</h2>

        <div class="tabs">
          <div class="tab active" onclick="showTab('paste')">Paste</div>
          <div class="tab" onclick="showTab('catalog')">From Catalog</div>
          <div class="tab" onclick="showTab('file')">Upload</div>
        </div>

        <div id="tab-paste">
          <textarea id="source-code" rows="20" placeholder="// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBPayHook} from '@bananapus/core/src/interfaces/IJBPayHook.sol';
// ... your hook code"></textarea>
        </div>

        <div id="tab-catalog" class="hidden">
          <label>Select Hook Template</label>
          <select id="catalog-select" onchange="loadFromCatalog()">
            <option value="">-- Select a template --</option>
            <optgroup label="Pay Hooks">
              <option value="pay-cap">Payment Cap Hook</option>
              <option value="pay-allowlist">Allowlist Pay Hook</option>
              <option value="pay-timelock">Timelock Pay Hook</option>
            </optgroup>
            <optgroup label="Cash Out Hooks">
              <option value="cashout-fee">Fee Extraction Hook</option>
              <option value="cashout-vesting">Vesting Cash Out Hook</option>
            </optgroup>
            <optgroup label="Split Hooks">
              <option value="split-swap">Token Swap Split Hook</option>
              <option value="split-lp">LP Deposit Split Hook</option>
            </optgroup>
          </select>
          <div id="catalog-preview" class="output" style="margin-top: 0.5rem; min-height: 100px;"></div>
        </div>

        <div id="tab-file" class="hidden">
          <input type="file" id="file-input" accept=".sol" onchange="loadFromFile()">
        </div>

        <div class="btn-row" style="margin-top: 1rem;">
          <button onclick="compileSource()">Compile</button>
        </div>
      </div>

      <!-- Compiler Output -->
      <div class="card">
        <h2>Compiler Output</h2>
        <div id="compile-status"></div>
        <div id="compile-errors" class="output hidden" style="color: var(--error);"></div>

        <div id="compile-success" class="hidden">
          <label>Select Contract</label>
          <select id="contract-select" onchange="selectContract()">
            <option value="">-- Select contract to deploy --</option>
          </select>

          <div id="constructor-args" class="constructor-args hidden">
            <label style="font-weight: 600;">Constructor Arguments</label>
            <div id="args-container"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Column: Deploy & Attach -->
    <div>
      <!-- Chain Selection -->
      <div class="card">
        <h2>Target Chain</h2>
        <div class="chain-select" id="chain-select">
          <div class="chain-chip selected" data-chain="1" onclick="selectChain(this)">Ethereum</div>
          <div class="chain-chip" data-chain="11155111" onclick="selectChain(this)">Sepolia</div>
          <div class="chain-chip" data-chain="10" onclick="selectChain(this)">Optimism</div>
          <div class="chain-chip" data-chain="8453" onclick="selectChain(this)">Base</div>
          <div class="chain-chip" data-chain="42161" onclick="selectChain(this)">Arbitrum</div>
        </div>
      </div>

      <!-- Deploy -->
      <div class="card">
        <h2>Deploy Contract</h2>
        <div id="deploy-status"></div>

        <button id="deploy-btn" onclick="deployContract()" disabled>Deploy Hook</button>

        <div id="deploy-result" class="hidden" style="margin-top: 1rem;">
          <label>Contract Address</label>
          <div class="output" id="deployed-address"></div>

          <div class="btn-row" style="margin-top: 0.75rem;">
            <button class="btn-secondary" onclick="copyAddress()">Copy Address</button>
            <button class="btn-secondary" onclick="viewOnExplorer()">View on Explorer</button>
          </div>
        </div>
      </div>

      <!-- Verify -->
      <div class="card">
        <h2>Verify Contract (Optional)</h2>
        <p style="font-size: 0.875rem; color: var(--text-muted); margin-bottom: 1rem;">
          Verify source code on block explorer for transparency.
        </p>

        <label>Etherscan API Key</label>
        <input type="text" id="etherscan-key" placeholder="Your API key (optional)">

        <button id="verify-btn" class="btn-secondary" onclick="verifyContract()" disabled>Verify on Explorer</button>
        <div id="verify-status" style="margin-top: 0.5rem;"></div>
      </div>

      <!-- Attach to Project -->
      <div class="card">
        <h2>Attach to Project</h2>
        <p style="font-size: 0.875rem; color: var(--text-muted); margin-bottom: 1rem;">
          Queue a new ruleset with this hook attached.
        </p>

        <label>Project ID</label>
        <input type="number" id="project-id" placeholder="e.g., 1">

        <label>Hook Type</label>
        <select id="hook-type">
          <option value="pay">Pay Hook (useDataHookForPay)</option>
          <option value="cashout">Cash Out Hook (useDataHookForCashOut)</option>
          <option value="both">Both Pay & Cash Out</option>
        </select>

        <button id="attach-btn" class="btn-success" onclick="attachToProject()" disabled>
          Queue Ruleset with Hook
        </button>
        <div id="attach-status" style="margin-top: 0.5rem;"></div>
      </div>
    </div>
  </div>

  <script>
    // State
    let provider, signer, address;
    let compiledContracts = {};
    let selectedContract = null;
    let deployedAddress = null;
    let selectedChainId = 1;
    let sourceCode = '';

    const CHAINS = {
      1: { name: 'Ethereum', explorer: 'https://etherscan.io', apiUrl: 'https://api.etherscan.io' },
      11155111: { name: 'Sepolia', explorer: 'https://sepolia.etherscan.io', apiUrl: 'https://api-sepolia.etherscan.io' },
      10: { name: 'Optimism', explorer: 'https://optimistic.etherscan.io', apiUrl: 'https://api-optimistic.etherscan.io' },
      8453: { name: 'Base', explorer: 'https://basescan.org', apiUrl: 'https://api.basescan.org' },
      42161: { name: 'Arbitrum', explorer: 'https://arbiscan.io', apiUrl: 'https://api.arbiscan.io' }
    };

    // V5 Controller addresses
    const CONTROLLER = {
      1: '0x...', // Mainnet
      11155111: '0x...', // Sepolia
      10: '0x...', // Optimism
      8453: '0x...', // Base
      42161: '0x...' // Arbitrum
    };

    // Catalog of common hooks
    const HOOK_CATALOG = {
      'pay-cap': {
        name: 'Payment Cap Hook',
        description: 'Limits maximum payment amount per transaction',
        source: `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBPayHook} from "@bananapus/core/src/interfaces/IJBPayHook.sol";
import {JBAfterPayRecordedContext} from "@bananapus/core/src/structs/JBAfterPayRecordedContext.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract PaymentCapHook is IJBPayHook {
    uint256 public immutable MAX_PAYMENT;

    error PaymentExceedsCap(uint256 amount, uint256 cap);

    constructor(uint256 _maxPayment) {
        MAX_PAYMENT = _maxPayment;
    }

    function afterPayRecordedWith(JBAfterPayRecordedContext calldata context) external payable override {
        if (context.amount.value > MAX_PAYMENT) {
            revert PaymentExceedsCap(context.amount.value, MAX_PAYMENT);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IJBPayHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}`
      },
      'pay-allowlist': {
        name: 'Allowlist Pay Hook',
        description: 'Only allows payments from whitelisted addresses',
        source: `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IJBPayHook} from "@bananapus/core/src/interfaces/IJBPayHook.sol";
import {JBAfterPayRecordedContext} from "@bananapus/core/src/structs/JBAfterPayRecordedContext.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AllowlistPayHook is IJBPayHook, Ownable {
    mapping(address => bool) public allowed;

    error NotAllowed(address payer);

    constructor(address[] memory _allowed) Ownable(msg.sender) {
        for (uint256 i; i < _allowed.length; i++) {
            allowed[_allowed[i]] = true;
        }
    }

    function setAllowed(address addr, bool status) external onlyOwner {
        allowed[addr] = status;
    }

    function afterPayRecordedWith(JBAfterPayRecordedContext calldata context) external payable override {
        if (!allowed[context.payer]) {
            revert NotAllowed(context.payer);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IJBPayHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}`
      },
      // Add more templates...
    };

    // Tab switching
    function showTab(tab) {
      document.querySelectorAll('.tabs .tab').forEach(t => t.classList.remove('active'));
      document.querySelector(`.tab[onclick="showTab('${tab}')"]`).classList.add('active');

      document.getElementById('tab-paste').classList.add('hidden');
      document.getElementById('tab-catalog').classList.add('hidden');
      document.getElementById('tab-file').classList.add('hidden');
      document.getElementById(`tab-${tab}`).classList.remove('hidden');
    }

    // Load from catalog
    function loadFromCatalog() {
      const select = document.getElementById('catalog-select');
      const template = HOOK_CATALOG[select.value];

      if (template) {
        document.getElementById('catalog-preview').textContent = template.source;
        document.getElementById('source-code').value = template.source;
        sourceCode = template.source;
      }
    }

    // Load from file
    function loadFromFile() {
      const file = document.getElementById('file-input').files[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (e) => {
        document.getElementById('source-code').value = e.target.result;
        sourceCode = e.target.result;
      };
      reader.readAsText(file);
    }

    // Chain selection
    function selectChain(el) {
      document.querySelectorAll('.chain-chip').forEach(c => c.classList.remove('selected'));
      el.classList.add('selected');
      selectedChainId = parseInt(el.dataset.chain);
    }

    // Wallet connection
    async function connectWallet() {
      if (!window.ethereum) {
        alert('Please install MetaMask');
        return;
      }

      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      address = await signer.getAddress();

      const network = await provider.getNetwork();

      document.getElementById('wallet-address').textContent = `${address.slice(0,6)}...${address.slice(-4)}`;
      document.getElementById('wallet-chain').textContent = CHAINS[Number(network.chainId)]?.name || `Chain ${network.chainId}`;
      document.getElementById('wallet-info').classList.remove('hidden');
      document.getElementById('connect-btn').textContent = 'Connected';
      document.getElementById('connect-btn').disabled = true;

      updateStepStatus(1, 'active');
    }

    // Compile source code
    async function compileSource() {
      sourceCode = document.getElementById('source-code').value;

      if (!sourceCode.trim()) {
        showStatus('compile-status', 'error', 'Please enter source code');
        return;
      }

      showStatus('compile-status', 'info', 'Compiling...');
      document.getElementById('compile-errors').classList.add('hidden');
      document.getElementById('compile-success').classList.add('hidden');

      try {
        // Use solc.js for browser compilation
        const result = await compileSolidity(sourceCode);

        if (result.errors && result.errors.some(e => e.severity === 'error')) {
          const errors = result.errors.filter(e => e.severity === 'error');
          document.getElementById('compile-errors').textContent = errors.map(e => e.formattedMessage).join('\n');
          document.getElementById('compile-errors').classList.remove('hidden');
          showStatus('compile-status', 'error', `Compilation failed with ${errors.length} error(s)`);
          return;
        }

        // Extract contracts
        compiledContracts = {};
        for (const [fileName, file] of Object.entries(result.contracts || {})) {
          for (const [contractName, contract] of Object.entries(file)) {
            compiledContracts[contractName] = {
              abi: contract.abi,
              bytecode: contract.evm.bytecode.object
            };
          }
        }

        if (Object.keys(compiledContracts).length === 0) {
          showStatus('compile-status', 'error', 'No contracts found in source');
          return;
        }

        // Populate contract selector
        const select = document.getElementById('contract-select');
        select.innerHTML = '<option value="">-- Select contract to deploy --</option>';
        for (const name of Object.keys(compiledContracts)) {
          select.innerHTML += `<option value="${name}">${name}</option>`;
        }

        document.getElementById('compile-success').classList.remove('hidden');
        showStatus('compile-status', 'success', `Compiled ${Object.keys(compiledContracts).length} contract(s)`);
        updateStepStatus(2, 'complete');

      } catch (error) {
        console.error(error);
        showStatus('compile-status', 'error', `Compilation error: ${error.message}`);
      }
    }

    // Solidity compilation using solc.js
    async function compileSolidity(source) {
      // For production, use a proper solc wrapper or API
      // This is a simplified example - in practice you'd use:
      // - https://github.com/nicolo-ribaudo/solc-js
      // - Or a compilation API endpoint

      const input = {
        language: 'Solidity',
        sources: {
          'contract.sol': { content: source }
        },
        settings: {
          outputSelection: {
            '*': {
              '*': ['abi', 'evm.bytecode']
            }
          },
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      };

      // In production, call your compilation API or use solc-js properly
      const response = await fetch('/api/compile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ source, settings: input.settings })
      });

      if (!response.ok) {
        throw new Error('Compilation service unavailable');
      }

      return await response.json();
    }

    // Select contract and show constructor args
    function selectContract() {
      const name = document.getElementById('contract-select').value;
      if (!name) {
        selectedContract = null;
        document.getElementById('constructor-args').classList.add('hidden');
        document.getElementById('deploy-btn').disabled = true;
        return;
      }

      selectedContract = compiledContracts[name];

      // Find constructor in ABI
      const constructor = selectedContract.abi.find(item => item.type === 'constructor');

      const argsContainer = document.getElementById('args-container');
      argsContainer.innerHTML = '';

      if (constructor && constructor.inputs.length > 0) {
        document.getElementById('constructor-args').classList.remove('hidden');

        constructor.inputs.forEach((input, i) => {
          argsContainer.innerHTML += `
            <div class="arg-input">
              <label>${input.name} (${input.type})</label>
              <input type="text" id="arg-${i}" placeholder="${input.type}" data-type="${input.type}">
            </div>
          `;
        });
      } else {
        document.getElementById('constructor-args').classList.add('hidden');
      }

      document.getElementById('deploy-btn').disabled = false;
    }

    // Deploy contract
    async function deployContract() {
      if (!selectedContract || !signer) {
        showStatus('deploy-status', 'error', 'Please compile and select a contract first');
        return;
      }

      // Check chain
      const network = await provider.getNetwork();
      if (Number(network.chainId) !== selectedChainId) {
        showStatus('deploy-status', 'warning', `Please switch to ${CHAINS[selectedChainId].name}`);
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x' + selectedChainId.toString(16) }]
          });
          provider = new ethers.BrowserProvider(window.ethereum);
          signer = await provider.getSigner();
        } catch (e) {
          return;
        }
      }

      showStatus('deploy-status', 'info', 'Deploying...');
      document.getElementById('deploy-btn').disabled = true;

      try {
        // Get constructor args
        const constructor = selectedContract.abi.find(item => item.type === 'constructor');
        const args = [];

        if (constructor) {
          constructor.inputs.forEach((input, i) => {
            const value = document.getElementById(`arg-${i}`).value;
            args.push(parseArgument(value, input.type));
          });
        }

        // Create contract factory
        const factory = new ethers.ContractFactory(
          selectedContract.abi,
          '0x' + selectedContract.bytecode,
          signer
        );

        // Deploy
        const contract = await factory.deploy(...args);
        showStatus('deploy-status', 'info', 'Waiting for confirmation...');

        await contract.waitForDeployment();
        deployedAddress = await contract.getAddress();

        document.getElementById('deployed-address').textContent = deployedAddress;
        document.getElementById('deploy-result').classList.remove('hidden');

        showStatus('deploy-status', 'success', 'Contract deployed successfully!');
        updateStepStatus(3, 'complete');

        document.getElementById('verify-btn').disabled = false;
        document.getElementById('attach-btn').disabled = false;

      } catch (error) {
        console.error(error);
        showStatus('deploy-status', 'error', `Deploy failed: ${error.message}`);
        document.getElementById('deploy-btn').disabled = false;
      }
    }

    // Parse constructor argument based on type
    function parseArgument(value, type) {
      if (type.startsWith('uint') || type.startsWith('int')) {
        return BigInt(value);
      }
      if (type === 'bool') {
        return value.toLowerCase() === 'true';
      }
      if (type.endsWith('[]')) {
        return JSON.parse(value);
      }
      return value;
    }

    // Copy deployed address
    function copyAddress() {
      navigator.clipboard.writeText(deployedAddress);
      showStatus('deploy-status', 'success', 'Address copied!');
    }

    // View on explorer
    function viewOnExplorer() {
      const chain = CHAINS[selectedChainId];
      window.open(`${chain.explorer}/address/${deployedAddress}`, '_blank');
    }

    // Verify contract
    async function verifyContract() {
      const apiKey = document.getElementById('etherscan-key').value;
      if (!apiKey) {
        showStatus('verify-status', 'warning', 'API key required for verification');
        return;
      }

      showStatus('verify-status', 'info', 'Submitting for verification...');

      // Get constructor args encoded
      const constructor = selectedContract.abi.find(item => item.type === 'constructor');
      let constructorArgs = '';

      if (constructor && constructor.inputs.length > 0) {
        const args = [];
        constructor.inputs.forEach((input, i) => {
          const value = document.getElementById(`arg-${i}`).value;
          args.push(parseArgument(value, input.type));
        });

        const abiCoder = new ethers.AbiCoder();
        constructorArgs = abiCoder.encode(
          constructor.inputs.map(i => i.type),
          args
        ).slice(2);
      }

      try {
        const chain = CHAINS[selectedChainId];
        const response = await fetch(`${chain.apiUrl}/api`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: new URLSearchParams({
            apikey: apiKey,
            module: 'contract',
            action: 'verifysourcecode',
            contractaddress: deployedAddress,
            sourceCode: sourceCode,
            codeformat: 'solidity-single-file',
            contractname: document.getElementById('contract-select').value,
            compilerversion: 'v0.8.23+commit.f704f362',
            optimizationUsed: '1',
            runs: '200',
            constructorArguements: constructorArgs
          })
        });

        const result = await response.json();

        if (result.status === '1') {
          showStatus('verify-status', 'success', 'Verification submitted! Check explorer in a few minutes.');
        } else {
          showStatus('verify-status', 'error', `Verification failed: ${result.result}`);
        }
      } catch (error) {
        showStatus('verify-status', 'error', `Verification error: ${error.message}`);
      }
    }

    // Attach to project
    async function attachToProject() {
      const projectId = document.getElementById('project-id').value;
      const hookType = document.getElementById('hook-type').value;

      if (!projectId) {
        showStatus('attach-status', 'error', 'Please enter project ID');
        return;
      }

      showStatus('attach-status', 'info', 'This would queue a new ruleset...');

      // In production, this would:
      // 1. Fetch current ruleset via JBController
      // 2. Build new ruleset config with hook attached
      // 3. Call queueRulesetsOf()

      // For now, show instructions
      const instructions = `
To attach this hook to project ${projectId}:

1. Call JBController.queueRulesetsOf() with:
   - metadata.useDataHookForPay: ${hookType === 'pay' || hookType === 'both'}
   - metadata.useDataHookForCashOut: ${hookType === 'cashout' || hookType === 'both'}
   - metadata.dataHook: ${deployedAddress}

Or use the /jb-interact-ui Queue Ruleset template.
      `;

      showStatus('attach-status', 'info', instructions);
      updateStepStatus(4, 'complete');
    }

    // Helper functions
    function showStatus(elementId, type, message) {
      const el = document.getElementById(elementId);
      el.className = `status ${type}`;
      el.textContent = message;
      el.classList.remove('hidden');
    }

    function updateStepStatus(step, status) {
      const el = document.getElementById(`step${step}-num`);
      el.className = 'step-number ' + status;
    }
  </script>
</body>
</html>
```

---

## Compilation API Endpoint

For browser compilation, you'll need a server-side endpoint. Here's a Next.js example:

```typescript
// pages/api/compile.ts
import solc from 'solc';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { source, settings } = req.body;

  const input = {
    language: 'Solidity',
    sources: {
      'contract.sol': { content: source }
    },
    settings: settings || {
      outputSelection: {
        '*': { '*': ['abi', 'evm.bytecode'] }
      },
      optimizer: { enabled: true, runs: 200 }
    }
  };

  // Handle imports by fetching from npm/github
  function findImports(path) {
    // In production, resolve imports from:
    // - @bananapus/* -> GitHub raw or npm
    // - @openzeppelin/* -> npm
    return { error: 'Import not found: ' + path };
  }

  const output = JSON.parse(
    solc.compile(JSON.stringify(input), { import: findImports })
  );

  res.json(output);
}
```

---

## Import Resolution

For Juicebox imports, resolve from GitHub or npm:

```javascript
const IMPORT_MAPPINGS = {
  '@bananapus/core/': 'https://raw.githubusercontent.com/Bananapus/nana-core-v5/main/',
  '@bananapus/721-hook/': 'https://raw.githubusercontent.com/Bananapus/nana-721-hook-v5/main/',
  '@openzeppelin/contracts/': 'https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.0/contracts/'
};

async function resolveImport(path) {
  for (const [prefix, baseUrl] of Object.entries(IMPORT_MAPPINGS)) {
    if (path.startsWith(prefix)) {
      const url = baseUrl + path.slice(prefix.length);
      const response = await fetch(url);
      if (response.ok) {
        return { contents: await response.text() };
      }
    }
  }
  return { error: 'Import not found: ' + path };
}
```

---

## Related Skills

- `/jb-pay-hook` - Generate pay hook Solidity code
- `/jb-cash-out-hook` - Generate cash out hook Solidity code
- `/jb-split-hook` - Generate split hook Solidity code
- `/jb-explorer-ui` - Contract read/write interface
- `/jb-interact-ui` - Queue rulesets with hooks
