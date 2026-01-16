---
name: jb-explorer-ui
description: Etherscan-like contract explorer for Juicebox projects. Read contract state, write transactions, decode events, and inspect any JB contract.
---

# Juicebox V5 Contract Explorer UI

Build Etherscan-like interfaces for reading contract state, executing transactions, and exploring Juicebox project data.

## Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Contract Explorer                      │
├─────────────────────────────────────────────────────────┤
│  [Read]     [Write]     [Events]     [Code]             │
├─────────────────────────────────────────────────────────┤
│  Contract: JBController                                  │
│  Address: 0x...                                         │
│                                                          │
│  ┌─ Read Functions ─────────────────────────────────┐   │
│  │ currentRulesetOf(projectId)                      │   │
│  │ totalTokenSupplyWithReservedTokensOf(projectId)  │   │
│  │ ...                                               │   │
│  └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Complete Explorer UI Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Juicebox Contract Explorer</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; --success: #4caf50; --error: #ef5350; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 1200px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 1.5rem; }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    h2 { font-size: 1.1rem; color: var(--text-muted); margin-bottom: 1rem; }
    label { display: block; font-size: 0.875rem; color: var(--text-muted); margin-bottom: 0.25rem; }
    input, select { width: 100%; padding: 0.625rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--text); font-size: 0.875rem; margin-bottom: 0.75rem; }
    button { background: var(--accent); color: white; border: none; padding: 0.5rem 1rem; border-radius: 4px; font-size: 0.875rem; cursor: pointer; }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .btn-secondary { background: transparent; border: 1px solid var(--border); }
    .tabs { display: flex; border-bottom: 1px solid var(--border); margin-bottom: 1rem; }
    .tab { padding: 0.75rem 1.5rem; cursor: pointer; border-bottom: 2px solid transparent; color: var(--text-muted); }
    .tab:hover { color: var(--text); }
    .tab.active { color: var(--accent); border-bottom-color: var(--accent); }
    .function-card { background: var(--bg); border: 1px solid var(--border); border-radius: 4px; margin-bottom: 0.75rem; overflow: hidden; }
    .function-header { padding: 0.75rem 1rem; display: flex; justify-content: space-between; align-items: center; cursor: pointer; }
    .function-header:hover { background: rgba(255,255,255,0.02); }
    .function-name { font-family: monospace; font-weight: 500; }
    .function-type { font-size: 0.75rem; padding: 0.25rem 0.5rem; border-radius: 4px; background: var(--surface); }
    .function-type.view { color: var(--success); }
    .function-type.write { color: var(--accent); }
    .function-body { padding: 1rem; border-top: 1px solid var(--border); display: none; }
    .function-body.open { display: block; }
    .input-row { display: flex; gap: 0.5rem; align-items: flex-end; margin-bottom: 0.5rem; }
    .input-row input { margin-bottom: 0; flex: 1; }
    .input-row button { flex-shrink: 0; }
    .output { background: var(--surface); border: 1px solid var(--border); border-radius: 4px; padding: 0.75rem; font-family: monospace; font-size: 0.8rem; white-space: pre-wrap; word-break: break-all; margin-top: 0.75rem; max-height: 300px; overflow-y: auto; }
    .output.success { border-color: var(--success); }
    .output.error { border-color: var(--error); color: var(--error); }
    .contract-select { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem; }
    .contract-chip { padding: 0.5rem 1rem; border: 1px solid var(--border); border-radius: 4px; cursor: pointer; font-size: 0.875rem; }
    .contract-chip.selected { background: var(--accent); border-color: var(--accent); }
    .search-box { position: relative; margin-bottom: 1rem; }
    .search-box input { padding-left: 2.5rem; }
    .search-icon { position: absolute; left: 0.75rem; top: 50%; transform: translateY(-50%); color: var(--text-muted); }
    .event-row { padding: 0.75rem; border-bottom: 1px solid var(--border); font-size: 0.875rem; }
    .event-row:last-child { border-bottom: none; }
    .event-name { font-weight: 500; color: var(--accent); }
    .event-args { font-family: monospace; font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem; }
    .hidden { display: none !important; }
    .grid { display: grid; grid-template-columns: 300px 1fr; gap: 1rem; }
    @media (max-width: 900px) { .grid { grid-template-columns: 1fr; } }
  </style>
</head>
<body>
  <h1>Juicebox Contract Explorer</h1>
  <p class="subtitle">Read state, write transactions, and explore events</p>

  <!-- Connection -->
  <div class="card">
    <div style="display: flex; gap: 1rem; align-items: center; flex-wrap: wrap;">
      <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
      <span id="wallet-info" style="color: var(--text-muted); font-size: 0.875rem;"></span>

      <div style="margin-left: auto;">
        <select id="chain-select" onchange="switchChain()" style="width: auto;">
          <option value="1">Ethereum</option>
          <option value="11155111">Sepolia</option>
          <option value="10">Optimism</option>
          <option value="8453">Base</option>
          <option value="42161">Arbitrum</option>
        </select>
      </div>
    </div>
  </div>

  <div class="grid">
    <!-- Left: Contract Selection -->
    <div>
      <div class="card">
        <h2>Contracts</h2>

        <div class="search-box">
          <span class="search-icon">🔍</span>
          <input type="text" id="contract-search" placeholder="Search contracts..." oninput="filterContracts()">
        </div>

        <div id="contract-list">
          <div class="contract-chip selected" data-contract="controller" onclick="selectContract(this)">JBController</div>
          <div class="contract-chip" data-contract="terminal" onclick="selectContract(this)">JBMultiTerminal</div>
          <div class="contract-chip" data-contract="directory" onclick="selectContract(this)">JBDirectory</div>
          <div class="contract-chip" data-contract="projects" onclick="selectContract(this)">JBProjects</div>
          <div class="contract-chip" data-contract="tokens" onclick="selectContract(this)">JBTokens</div>
          <div class="contract-chip" data-contract="permissions" onclick="selectContract(this)">JBPermissions</div>
          <div class="contract-chip" data-contract="splits" onclick="selectContract(this)">JBSplits</div>
          <div class="contract-chip" data-contract="prices" onclick="selectContract(this)">JBPrices</div>
        </div>

        <div style="margin-top: 1rem; padding-top: 1rem; border-top: 1px solid var(--border);">
          <label>Custom Contract</label>
          <input type="text" id="custom-address" placeholder="0x...">
          <button class="btn-secondary" onclick="loadCustomContract()" style="width: 100%; margin-top: 0.5rem;">Load ABI</button>
        </div>
      </div>

      <div class="card">
        <h2>Quick Actions</h2>
        <div style="display: flex; flex-direction: column; gap: 0.5rem;">
          <button class="btn-secondary" onclick="loadProjectOverview()">Project Overview</button>
          <button class="btn-secondary" onclick="loadCurrentRuleset()">Current Ruleset</button>
          <button class="btn-secondary" onclick="loadSplits()">View Splits</button>
          <button class="btn-secondary" onclick="loadTokenHolders()">Token Holders</button>
        </div>
      </div>
    </div>

    <!-- Right: Contract Interface -->
    <div>
      <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
          <h2 id="contract-title" style="margin-bottom: 0;">JBController</h2>
          <span id="contract-address" style="font-family: monospace; font-size: 0.8rem; color: var(--text-muted);"></span>
        </div>

        <div class="tabs">
          <div class="tab active" data-tab="read" onclick="showTab('read')">Read</div>
          <div class="tab" data-tab="write" onclick="showTab('write')">Write</div>
          <div class="tab" data-tab="events" onclick="showTab('events')">Events</div>
        </div>

        <!-- Read Functions -->
        <div id="tab-read">
          <div class="search-box">
            <span class="search-icon">🔍</span>
            <input type="text" id="function-search" placeholder="Search functions..." oninput="filterFunctions()">
          </div>

          <div id="read-functions"></div>
        </div>

        <!-- Write Functions -->
        <div id="tab-write" class="hidden">
          <div class="search-box">
            <span class="search-icon">🔍</span>
            <input type="text" id="write-search" placeholder="Search functions..." oninput="filterFunctions()">
          </div>

          <div id="write-functions"></div>
        </div>

        <!-- Events -->
        <div id="tab-events" class="hidden">
          <div style="display: flex; gap: 0.5rem; margin-bottom: 1rem;">
            <input type="number" id="event-project" placeholder="Project ID" style="width: 120px;">
            <input type="number" id="event-blocks" placeholder="Last N blocks" value="1000" style="width: 120px;">
            <button onclick="loadEvents()">Load Events</button>
          </div>

          <div id="events-list"></div>
        </div>
      </div>
    </div>
  </div>

  <script>
    // State
    let provider, signer, address;
    let selectedChainId = 1;
    let currentContract = null;
    let currentAbi = [];

    // Contract addresses per chain
    const ADDRESSES = {
      1: {
        controller: '0x...',
        terminal: '0x...',
        directory: '0x...',
        projects: '0x...',
        tokens: '0x...',
        permissions: '0x...',
        splits: '0x...',
        prices: '0x...'
      },
      // ... other chains
    };

    // ABIs (simplified - in production, import full ABIs)
    const ABIS = {
      controller: [
        'function currentRulesetOf(uint256 projectId) view returns (tuple, tuple)',
        'function upcomingRulesetOf(uint256 projectId) view returns (tuple, tuple)',
        'function latestQueuedRulesetOf(uint256 projectId) view returns (tuple, tuple, uint8)',
        'function totalTokenSupplyWithReservedTokensOf(uint256 projectId) view returns (uint256)',
        'function pendingReservedTokenBalanceOf(uint256 projectId) view returns (uint256)',
        'function PROJECTS() view returns (address)',
        'function DIRECTORY() view returns (address)',
        'function launchProjectFor(address owner, string projectUri, tuple[] rulesetConfigurations, tuple[] terminalConfigurations, string memo) returns (uint256)',
        'function queueRulesetsOf(uint256 projectId, tuple[] rulesetConfigurations, string memo) returns (uint256)',
        'function mintTokensOf(uint256 projectId, uint256 tokenCount, address beneficiary, string memo, bool useReservedPercent) returns (uint256)',
        'function burnTokensOf(address holder, uint256 projectId, uint256 tokenCount, string memo)',
        'function sendReservedTokensToSplitsOf(uint256 projectId) returns (uint256)',
        'event LaunchProject(uint256 rulesetId, uint256 projectId, string memo, address caller)',
        'event MintTokens(address indexed beneficiary, uint256 indexed projectId, uint256 tokenCount, uint256 beneficiaryTokenCount, string memo, uint256 reservedPercent, address caller)'
      ],
      terminal: [
        'function pay(uint256 projectId, address token, uint256 amount, address beneficiary, uint256 minReturnedTokens, string memo, bytes metadata) payable returns (uint256)',
        'function addToBalanceOf(uint256 projectId, address token, uint256 amount, bool shouldReturnHeldFees, string memo, bytes metadata) payable',
        'function cashOutTokensOf(address holder, uint256 projectId, uint256 cashOutCount, address tokenToReclaim, uint256 minTokensReclaimed, address beneficiary, bytes metadata) returns (uint256)',
        'function sendPayoutsOf(uint256 projectId, address token, uint256 amount, uint256 currency, uint256 minTokensPaidOut) returns (uint256)',
        'function useAllowanceOf(uint256 projectId, address token, uint256 amount, uint256 currency, uint256 minTokensPaidOut, address beneficiary, address feeBeneficiary, string memo) returns (uint256)',
        'function currentSurplusOf(uint256 projectId, tuple[] accountingContexts, uint256 decimals, uint256 currency) view returns (uint256)',
        'function accountingContextsOf(uint256 projectId) view returns (tuple[])',
        'event Pay(uint256 indexed rulesetId, uint256 indexed rulesetCycleNumber, uint256 indexed projectId, address payer, address beneficiary, uint256 amount, uint256 newlyIssuedTokenCount, string memo, bytes metadata, address caller)',
        'event CashOutTokens(uint256 indexed rulesetId, uint256 indexed rulesetCycleNumber, uint256 indexed projectId, address holder, address beneficiary, uint256 cashOutCount, uint256 reclaimAmount, bytes metadata, address caller)'
      ],
      directory: [
        'function controllerOf(uint256 projectId) view returns (address)',
        'function terminalsOf(uint256 projectId) view returns (address[])',
        'function primaryTerminalOf(uint256 projectId, address token) view returns (address)',
        'function isTerminalOf(uint256 projectId, address terminal) view returns (bool)',
        'function setControllerOf(uint256 projectId, address controller)',
        'function setTerminalsOf(uint256 projectId, address[] terminals)',
        'function setPrimaryTerminalOf(uint256 projectId, address token, address terminal)'
      ],
      projects: [
        'function count() view returns (uint256)',
        'function ownerOf(uint256 projectId) view returns (address)',
        'function metadataContentOf(uint256 projectId) view returns (string)',
        'event Create(uint256 indexed projectId, address indexed owner, address caller)'
      ],
      tokens: [
        'function tokenOf(uint256 projectId) view returns (address)',
        'function totalSupplyOf(uint256 projectId) view returns (uint256)',
        'function balanceOf(address holder, uint256 projectId) view returns (uint256)',
        'function totalCreditSupplyOf(uint256 projectId) view returns (uint256)',
        'function creditBalanceOf(address holder, uint256 projectId) view returns (uint256)'
      ],
      permissions: [
        'function hasPermission(address operator, address account, uint256 projectId, uint256 permissionId, bool includeRoot, bool includeWildcardProjectId) view returns (bool)',
        'function permissionsOf(address operator, address account, uint256 projectId) view returns (uint256)',
        'function setPermissionsFor(address account, tuple permissionsData)'
      ],
      splits: [
        'function splitsOf(uint256 projectId, uint256 rulesetId, uint256 groupId) view returns (tuple[])',
        'function FALLBACK_RULESET_ID() view returns (uint256)'
      ],
      prices: [
        'function pricePerUnitOf(uint256 projectId, uint256 pricingCurrency, uint256 unitCurrency, uint256 decimals) view returns (uint256)'
      ]
    };

    // Initialize
    document.addEventListener('DOMContentLoaded', () => {
      selectContract(document.querySelector('.contract-chip.selected'));
    });

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
      selectedChainId = Number(network.chainId);

      document.getElementById('chain-select').value = selectedChainId;
      document.getElementById('wallet-info').textContent = `${address.slice(0,6)}...${address.slice(-4)}`;
      document.getElementById('connect-btn').textContent = 'Connected';

      // Refresh current contract
      if (currentContract) {
        renderFunctions();
      }
    }

    // Switch chain
    async function switchChain() {
      const chainId = document.getElementById('chain-select').value;
      selectedChainId = parseInt(chainId);

      if (window.ethereum) {
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x' + selectedChainId.toString(16) }]
          });
          provider = new ethers.BrowserProvider(window.ethereum);
          signer = await provider.getSigner();
        } catch (e) {
          console.error('Chain switch failed:', e);
        }
      }

      renderFunctions();
    }

    // Select contract
    function selectContract(el) {
      document.querySelectorAll('.contract-chip').forEach(c => c.classList.remove('selected'));
      el.classList.add('selected');

      currentContract = el.dataset.contract;
      currentAbi = ABIS[currentContract] || [];

      document.getElementById('contract-title').textContent = el.textContent;
      document.getElementById('contract-address').textContent = ADDRESSES[selectedChainId]?.[currentContract] || '0x...';

      renderFunctions();
    }

    // Render functions
    function renderFunctions() {
      const readContainer = document.getElementById('read-functions');
      const writeContainer = document.getElementById('write-functions');

      readContainer.innerHTML = '';
      writeContainer.innerHTML = '';

      const iface = new ethers.Interface(currentAbi);

      // Read functions (view/pure)
      iface.forEachFunction((func) => {
        const isView = func.stateMutability === 'view' || func.stateMutability === 'pure';
        const container = isView ? readContainer : writeContainer;

        const card = document.createElement('div');
        card.className = 'function-card';
        card.innerHTML = `
          <div class="function-header" onclick="toggleFunction(this)">
            <span class="function-name">${func.name}(${func.inputs.map(i => i.type).join(', ')})</span>
            <span class="function-type ${isView ? 'view' : 'write'}">${isView ? 'view' : 'write'}</span>
          </div>
          <div class="function-body" id="func-${func.name}">
            ${func.inputs.map((input, i) => `
              <div class="input-row">
                <div style="flex: 1;">
                  <label>${input.name || `arg${i}`} (${input.type})</label>
                  <input type="text" id="input-${func.name}-${i}" placeholder="${input.type}">
                </div>
              </div>
            `).join('')}
            <button onclick="callFunction('${func.name}', ${isView})" style="margin-top: 0.5rem;">
              ${isView ? 'Query' : 'Write'}
            </button>
            <div class="output hidden" id="output-${func.name}"></div>
          </div>
        `;

        container.appendChild(card);
      });

      if (readContainer.children.length === 0) {
        readContainer.innerHTML = '<p style="color: var(--text-muted);">No read functions</p>';
      }
      if (writeContainer.children.length === 0) {
        writeContainer.innerHTML = '<p style="color: var(--text-muted);">No write functions</p>';
      }
    }

    // Toggle function expansion
    function toggleFunction(header) {
      const body = header.nextElementSibling;
      body.classList.toggle('open');
    }

    // Call function
    async function callFunction(funcName, isView) {
      const outputEl = document.getElementById(`output-${funcName}`);
      outputEl.classList.remove('hidden', 'success', 'error');

      try {
        const iface = new ethers.Interface(currentAbi);
        const func = iface.getFunction(funcName);

        // Get inputs
        const args = func.inputs.map((input, i) => {
          const value = document.getElementById(`input-${funcName}-${i}`).value;
          return parseInput(value, input.type);
        });

        const contractAddress = ADDRESSES[selectedChainId]?.[currentContract];
        if (!contractAddress) {
          throw new Error('Contract address not found for this chain');
        }

        const contract = new ethers.Contract(
          contractAddress,
          currentAbi,
          isView ? provider : signer
        );

        let result;
        if (isView) {
          result = await contract[funcName](...args);
          outputEl.classList.add('success');
          outputEl.textContent = formatOutput(result);
        } else {
          outputEl.textContent = 'Sending transaction...';
          const tx = await contract[funcName](...args);
          outputEl.textContent = `Tx: ${tx.hash}\nWaiting for confirmation...`;

          const receipt = await tx.wait();
          outputEl.classList.add('success');
          outputEl.textContent = `Success!\nTx: ${tx.hash}\nBlock: ${receipt.blockNumber}\nGas used: ${receipt.gasUsed}`;
        }

      } catch (error) {
        outputEl.classList.add('error');
        outputEl.textContent = `Error: ${error.message}`;
      }
    }

    // Parse input value
    function parseInput(value, type) {
      if (!value) return value;

      if (type.startsWith('uint') || type.startsWith('int')) {
        return BigInt(value);
      }
      if (type === 'bool') {
        return value.toLowerCase() === 'true';
      }
      if (type.endsWith('[]')) {
        return JSON.parse(value);
      }
      if (type === 'tuple' || type.startsWith('tuple')) {
        return JSON.parse(value);
      }
      return value;
    }

    // Format output
    function formatOutput(result) {
      if (result === null || result === undefined) return 'null';

      if (typeof result === 'bigint') {
        return result.toString();
      }

      if (Array.isArray(result)) {
        return JSON.stringify(result.map(formatOutput), null, 2);
      }

      if (typeof result === 'object') {
        const obj = {};
        for (const key of Object.keys(result)) {
          if (isNaN(key)) {
            obj[key] = formatOutput(result[key]);
          }
        }
        return JSON.stringify(obj, null, 2);
      }

      return String(result);
    }

    // Tab switching
    function showTab(tab) {
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      document.querySelector(`.tab[data-tab="${tab}"]`).classList.add('active');

      document.getElementById('tab-read').classList.add('hidden');
      document.getElementById('tab-write').classList.add('hidden');
      document.getElementById('tab-events').classList.add('hidden');
      document.getElementById(`tab-${tab}`).classList.remove('hidden');
    }

    // Filter functions
    function filterFunctions() {
      const search = document.getElementById('function-search').value.toLowerCase();
      document.querySelectorAll('.function-card').forEach(card => {
        const name = card.querySelector('.function-name').textContent.toLowerCase();
        card.style.display = name.includes(search) ? 'block' : 'none';
      });
    }

    // Filter contracts
    function filterContracts() {
      const search = document.getElementById('contract-search').value.toLowerCase();
      document.querySelectorAll('.contract-chip').forEach(chip => {
        chip.style.display = chip.textContent.toLowerCase().includes(search) ? 'inline-block' : 'none';
      });
    }

    // Load events
    async function loadEvents() {
      const projectId = document.getElementById('event-project').value;
      const blocks = parseInt(document.getElementById('event-blocks').value) || 1000;

      const container = document.getElementById('events-list');
      container.innerHTML = '<p style="color: var(--text-muted);">Loading events...</p>';

      try {
        const contractAddress = ADDRESSES[selectedChainId]?.[currentContract];
        const contract = new ethers.Contract(contractAddress, currentAbi, provider);

        const currentBlock = await provider.getBlockNumber();
        const fromBlock = currentBlock - blocks;

        // Get all events
        const filter = { address: contractAddress, fromBlock };
        const logs = await provider.getLogs(filter);

        const iface = new ethers.Interface(currentAbi);

        container.innerHTML = '';

        if (logs.length === 0) {
          container.innerHTML = '<p style="color: var(--text-muted);">No events found</p>';
          return;
        }

        logs.reverse().forEach(log => {
          try {
            const parsed = iface.parseLog(log);
            if (!parsed) return;

            // Filter by project if specified
            if (projectId && parsed.args.projectId) {
              if (parsed.args.projectId.toString() !== projectId) return;
            }

            const row = document.createElement('div');
            row.className = 'event-row';
            row.innerHTML = `
              <div class="event-name">${parsed.name}</div>
              <div class="event-args">${JSON.stringify(Object.fromEntries(
                parsed.fragment.inputs.map((input, i) => [input.name, formatOutput(parsed.args[i])])
              ), null, 2)}</div>
              <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 0.25rem;">
                Block ${log.blockNumber} · <a href="#" onclick="viewTx('${log.transactionHash}')" style="color: var(--accent);">View Tx</a>
              </div>
            `;
            container.appendChild(row);
          } catch (e) {
            // Skip unparseable logs
          }
        });

        if (container.children.length === 0) {
          container.innerHTML = '<p style="color: var(--text-muted);">No matching events found</p>';
        }

      } catch (error) {
        container.innerHTML = `<p style="color: var(--error);">Error: ${error.message}</p>`;
      }
    }

    // Quick actions
    async function loadProjectOverview() {
      const projectId = prompt('Enter Project ID:');
      if (!projectId) return;

      // Switch to controller and query
      selectContract(document.querySelector('[data-contract="controller"]'));

      // Auto-fill and query currentRulesetOf
      setTimeout(() => {
        const input = document.getElementById('input-currentRulesetOf-0');
        if (input) {
          input.value = projectId;
          callFunction('currentRulesetOf', true);
        }
      }, 100);
    }

    async function loadCurrentRuleset() {
      loadProjectOverview();
    }

    async function loadSplits() {
      const projectId = prompt('Enter Project ID:');
      if (!projectId) return;

      selectContract(document.querySelector('[data-contract="splits"]'));
    }

    async function loadTokenHolders() {
      alert('Use /jb-bendystraw to query token holders');
    }

    // Load custom contract
    async function loadCustomContract() {
      const address = document.getElementById('custom-address').value;
      if (!address) return;

      // Try to fetch ABI from explorer
      // In production, implement ABI fetching from Etherscan API

      alert('Custom contract loading requires ABI. Paste ABI in console or use verified contracts.');
    }

    // View transaction
    function viewTx(hash) {
      const explorers = {
        1: 'https://etherscan.io',
        11155111: 'https://sepolia.etherscan.io',
        10: 'https://optimistic.etherscan.io',
        8453: 'https://basescan.org',
        42161: 'https://arbiscan.io'
      };
      window.open(`${explorers[selectedChainId]}/tx/${hash}`, '_blank');
    }
  </script>
</body>
</html>
```

---

## Features

### Read Functions
- Query any view/pure function
- Auto-parse return values
- Support for complex tuple returns

### Write Functions
- Execute state-changing transactions
- Track transaction status
- Show gas usage

### Events
- Filter by project ID
- Browse historical events
- Decode event arguments
- Link to block explorer

### Quick Actions
- Project overview
- Current ruleset
- Token holders
- Splits configuration

---

## Related Skills

- `/jb-bendystraw` - Query indexed data
- `/jb-event-explorer-ui` - Dedicated event browser
- `/jb-ruleset-timeline-ui` - Ruleset history visualization
- `/jb-v5-api` - Function signatures reference
