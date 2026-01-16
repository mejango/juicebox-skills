---
name: jb-event-explorer-ui
description: Browse and decode Juicebox project events. Filter by type, project, time. Decode Pay, CashOut, DistributePayouts, and all JB events.
---

# Juicebox V5 Event Explorer UI

Browse, filter, and decode all Juicebox protocol events. See payment history, redemptions, distributions, and configuration changes.

## Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Event Explorer                         │
├─────────────────────────────────────────────────────────┤
│  Project: [____] Chain: [▼] Event Type: [▼] [Search]   │
├─────────────────────────────────────────────────────────┤
│  ┌─ Pay ─────────────────────────────── 2 min ago ───┐  │
│  │ 0xabc...def paid 1.5 ETH → Project 42             │  │
│  │ Tokens: 1,500 · Memo: "Supporting the project"    │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌─ CashOut ─────────────────────────── 15 min ago ──┐  │
│  │ 0x123...456 redeemed 500 tokens for 0.4 ETH       │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Complete Event Explorer Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Juicebox Event Explorer</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; --success: #4caf50; --warning: #ffb74d; --error: #ef5350; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 1000px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 1.5rem; }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    .filters { display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: flex-end; }
    .filter-group { display: flex; flex-direction: column; gap: 0.25rem; }
    .filter-group label { font-size: 0.75rem; color: var(--text-muted); }
    input, select { padding: 0.5rem 0.75rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--text); font-size: 0.875rem; }
    input:focus, select:focus { outline: none; border-color: var(--accent); }
    button { background: var(--accent); color: white; border: none; padding: 0.5rem 1rem; border-radius: 4px; font-size: 0.875rem; cursor: pointer; }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .btn-secondary { background: transparent; border: 1px solid var(--border); }

    .event-card { background: var(--bg); border: 1px solid var(--border); border-radius: 8px; margin-bottom: 0.75rem; overflow: hidden; }
    .event-header { display: flex; justify-content: space-between; align-items: center; padding: 0.75rem 1rem; cursor: pointer; }
    .event-header:hover { background: rgba(255,255,255,0.02); }
    .event-type { display: flex; align-items: center; gap: 0.5rem; }
    .event-badge { padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.75rem; font-weight: 500; }
    .event-badge.pay { background: rgba(76, 175, 80, 0.2); color: var(--success); }
    .event-badge.cashout { background: rgba(239, 83, 80, 0.2); color: var(--error); }
    .event-badge.distribute { background: rgba(255, 183, 77, 0.2); color: var(--warning); }
    .event-badge.mint { background: rgba(92, 107, 192, 0.2); color: var(--accent); }
    .event-badge.config { background: rgba(128, 128, 128, 0.2); color: var(--text-muted); }
    .event-time { font-size: 0.75rem; color: var(--text-muted); }
    .event-summary { font-size: 0.875rem; padding: 0 1rem 0.75rem; }
    .event-details { padding: 1rem; border-top: 1px solid var(--border); display: none; }
    .event-details.open { display: block; }
    .detail-row { display: flex; justify-content: space-between; padding: 0.375rem 0; font-size: 0.875rem; }
    .detail-label { color: var(--text-muted); }
    .detail-value { font-family: monospace; text-align: right; word-break: break-all; max-width: 60%; }
    .detail-value a { color: var(--accent); text-decoration: none; }
    .detail-value a:hover { text-decoration: underline; }

    .pagination { display: flex; justify-content: center; gap: 0.5rem; margin-top: 1rem; }
    .page-btn { width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; }
    .page-btn.active { background: var(--accent); }

    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem; margin-bottom: 1rem; }
    .stat-card { background: var(--bg); border-radius: 4px; padding: 1rem; text-align: center; }
    .stat-value { font-size: 1.5rem; font-weight: 600; }
    .stat-label { font-size: 0.75rem; color: var(--text-muted); margin-top: 0.25rem; }

    .loading { text-align: center; padding: 2rem; color: var(--text-muted); }
    .empty { text-align: center; padding: 2rem; color: var(--text-muted); }
    .hidden { display: none !important; }

    .live-indicator { display: flex; align-items: center; gap: 0.5rem; font-size: 0.875rem; }
    .live-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--success); animation: pulse 2s infinite; }
    @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
  </style>
</head>
<body>
  <h1>Event Explorer</h1>
  <p class="subtitle">Browse all Juicebox project events</p>

  <!-- Filters -->
  <div class="card">
    <div class="filters">
      <div class="filter-group">
        <label>Project ID</label>
        <input type="number" id="filter-project" placeholder="All projects" style="width: 120px;">
      </div>

      <div class="filter-group">
        <label>Chain</label>
        <select id="filter-chain" style="width: 130px;">
          <option value="1">Ethereum</option>
          <option value="11155111">Sepolia</option>
          <option value="10">Optimism</option>
          <option value="8453">Base</option>
          <option value="42161">Arbitrum</option>
        </select>
      </div>

      <div class="filter-group">
        <label>Event Type</label>
        <select id="filter-type" style="width: 150px;">
          <option value="">All Events</option>
          <option value="Pay">Payments</option>
          <option value="CashOutTokens">Cash Outs</option>
          <option value="DistributePayouts">Distributions</option>
          <option value="MintTokens">Token Mints</option>
          <option value="LaunchProject">Project Launches</option>
          <option value="QueueRulesets">Ruleset Changes</option>
        </select>
      </div>

      <div class="filter-group">
        <label>Time Range</label>
        <select id="filter-time" style="width: 130px;">
          <option value="1000">Last 1000 blocks</option>
          <option value="5000">Last 5000 blocks</option>
          <option value="10000">Last 10000 blocks</option>
          <option value="50000">Last 50000 blocks</option>
        </select>
      </div>

      <button onclick="loadEvents()">Search</button>

      <div style="margin-left: auto;">
        <label class="live-indicator" style="cursor: pointer;">
          <input type="checkbox" id="live-toggle" onchange="toggleLive()" style="display: none;">
          <span class="live-dot" id="live-dot" style="background: var(--text-muted);"></span>
          Live Updates
        </label>
      </div>
    </div>
  </div>

  <!-- Stats -->
  <div class="card">
    <div class="stats">
      <div class="stat-card">
        <div class="stat-value" id="stat-total">-</div>
        <div class="stat-label">Total Events</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="stat-payments">-</div>
        <div class="stat-label">Payments</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="stat-volume">-</div>
        <div class="stat-label">Volume (ETH)</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="stat-unique">-</div>
        <div class="stat-label">Unique Addresses</div>
      </div>
    </div>
  </div>

  <!-- Events List -->
  <div id="events-container">
    <div class="loading">Connect wallet and search to load events</div>
  </div>

  <!-- Pagination -->
  <div class="pagination hidden" id="pagination"></div>

  <script>
    // State
    let provider;
    let events = [];
    let currentPage = 1;
    let liveUpdateInterval = null;
    const EVENTS_PER_PAGE = 20;

    // Event signatures
    const EVENT_SIGNATURES = {
      'Pay': 'event Pay(uint256 indexed rulesetId, uint256 indexed rulesetCycleNumber, uint256 indexed projectId, address payer, address beneficiary, uint256 amount, uint256 newlyIssuedTokenCount, string memo, bytes metadata, address caller)',
      'CashOutTokens': 'event CashOutTokens(uint256 indexed rulesetId, uint256 indexed rulesetCycleNumber, uint256 indexed projectId, address holder, address beneficiary, uint256 cashOutCount, uint256 reclaimAmount, bytes metadata, address caller)',
      'DistributePayouts': 'event DistributePayouts(uint256 indexed rulesetId, uint256 indexed rulesetCycleNumber, uint256 indexed projectId, address beneficiary, uint256 amount, uint256 amountPaidOut, uint256 fee, uint256 netLeftoverDistributionAmount, address caller)',
      'MintTokens': 'event MintTokens(address indexed beneficiary, uint256 indexed projectId, uint256 tokenCount, uint256 beneficiaryTokenCount, string memo, uint256 reservedPercent, address caller)',
      'LaunchProject': 'event LaunchProject(uint256 rulesetId, uint256 projectId, string memo, address caller)',
      'QueueRulesets': 'event QueueRulesets(uint256 rulesetId, uint256 projectId, string memo, address caller)'
    };

    // Contract addresses
    const CONTRACTS = {
      1: {
        terminal: '0x...',
        controller: '0x...'
      },
      // ... other chains
    };

    // Explorers
    const EXPLORERS = {
      1: 'https://etherscan.io',
      11155111: 'https://sepolia.etherscan.io',
      10: 'https://optimistic.etherscan.io',
      8453: 'https://basescan.org',
      42161: 'https://arbiscan.io'
    };

    // Initialize
    async function init() {
      if (window.ethereum) {
        provider = new ethers.BrowserProvider(window.ethereum);
      } else {
        // Fallback to public RPC
        provider = new ethers.JsonRpcProvider('https://eth.llamarpc.com');
      }
    }

    init();

    // Load events
    async function loadEvents() {
      const projectId = document.getElementById('filter-project').value;
      const chainId = parseInt(document.getElementById('filter-chain').value);
      const eventType = document.getElementById('filter-type').value;
      const blockRange = parseInt(document.getElementById('filter-time').value);

      const container = document.getElementById('events-container');
      container.innerHTML = '<div class="loading">Loading events...</div>';

      try {
        // Get appropriate provider for chain
        const rpcUrls = {
          1: 'https://eth.llamarpc.com',
          11155111: 'https://rpc.sepolia.org',
          10: 'https://mainnet.optimism.io',
          8453: 'https://mainnet.base.org',
          42161: 'https://arb1.arbitrum.io/rpc'
        };

        provider = new ethers.JsonRpcProvider(rpcUrls[chainId]);
        const currentBlock = await provider.getBlockNumber();
        const fromBlock = currentBlock - blockRange;

        // Build filter
        const terminalAddress = CONTRACTS[chainId]?.terminal;
        const controllerAddress = CONTRACTS[chainId]?.controller;

        if (!terminalAddress) {
          container.innerHTML = '<div class="empty">Contract addresses not configured for this chain</div>';
          return;
        }

        // Create interface for parsing
        const iface = new ethers.Interface(Object.values(EVENT_SIGNATURES));

        // Fetch logs from both contracts
        const logs = await provider.getLogs({
          address: [terminalAddress, controllerAddress].filter(Boolean),
          fromBlock,
          toBlock: 'latest'
        });

        // Parse and filter events
        events = [];
        const uniqueAddresses = new Set();
        let totalVolume = 0n;
        let paymentCount = 0;

        for (const log of logs) {
          try {
            const parsed = iface.parseLog(log);
            if (!parsed) continue;

            // Filter by event type
            if (eventType && parsed.name !== eventType) continue;

            // Filter by project ID
            if (projectId && parsed.args.projectId?.toString() !== projectId) continue;

            // Get block timestamp
            const block = await provider.getBlock(log.blockNumber);

            const event = {
              name: parsed.name,
              args: parsed.args,
              txHash: log.transactionHash,
              blockNumber: log.blockNumber,
              timestamp: block?.timestamp || 0,
              chainId
            };

            events.push(event);

            // Stats
            if (parsed.name === 'Pay') {
              paymentCount++;
              totalVolume += parsed.args.amount || 0n;
              uniqueAddresses.add(parsed.args.payer);
            }
            if (parsed.args.beneficiary) {
              uniqueAddresses.add(parsed.args.beneficiary);
            }

          } catch (e) {
            // Skip unparseable
          }
        }

        // Sort by timestamp descending
        events.sort((a, b) => b.timestamp - a.timestamp);

        // Update stats
        document.getElementById('stat-total').textContent = events.length;
        document.getElementById('stat-payments').textContent = paymentCount;
        document.getElementById('stat-volume').textContent = (Number(totalVolume) / 1e18).toFixed(2);
        document.getElementById('stat-unique').textContent = uniqueAddresses.size;

        // Render
        currentPage = 1;
        renderEvents();

      } catch (error) {
        console.error(error);
        container.innerHTML = `<div class="empty">Error loading events: ${error.message}</div>`;
      }
    }

    // Render events
    function renderEvents() {
      const container = document.getElementById('events-container');
      const start = (currentPage - 1) * EVENTS_PER_PAGE;
      const pageEvents = events.slice(start, start + EVENTS_PER_PAGE);

      if (pageEvents.length === 0) {
        container.innerHTML = '<div class="empty">No events found</div>';
        document.getElementById('pagination').classList.add('hidden');
        return;
      }

      container.innerHTML = pageEvents.map((event, i) => renderEvent(event, start + i)).join('');

      // Pagination
      const totalPages = Math.ceil(events.length / EVENTS_PER_PAGE);
      if (totalPages > 1) {
        const pagination = document.getElementById('pagination');
        pagination.classList.remove('hidden');
        pagination.innerHTML = '';

        for (let p = 1; p <= Math.min(totalPages, 10); p++) {
          const btn = document.createElement('button');
          btn.className = `page-btn btn-secondary ${p === currentPage ? 'active' : ''}`;
          btn.textContent = p;
          btn.onclick = () => { currentPage = p; renderEvents(); };
          pagination.appendChild(btn);
        }
      } else {
        document.getElementById('pagination').classList.add('hidden');
      }
    }

    // Render single event
    function renderEvent(event, index) {
      const badge = getEventBadge(event.name);
      const summary = getEventSummary(event);
      const details = getEventDetails(event);
      const timeAgo = formatTimeAgo(event.timestamp);

      return `
        <div class="event-card">
          <div class="event-header" onclick="toggleEvent(${index})">
            <div class="event-type">
              <span class="event-badge ${badge.class}">${badge.label}</span>
              <span>${summary.title}</span>
            </div>
            <span class="event-time">${timeAgo}</span>
          </div>
          <div class="event-summary">${summary.description}</div>
          <div class="event-details" id="event-${index}">
            ${details.map(d => `
              <div class="detail-row">
                <span class="detail-label">${d.label}</span>
                <span class="detail-value">${d.value}</span>
              </div>
            `).join('')}
            <div class="detail-row" style="margin-top: 0.5rem; padding-top: 0.5rem; border-top: 1px solid var(--border);">
              <span class="detail-label">Transaction</span>
              <span class="detail-value">
                <a href="${EXPLORERS[event.chainId]}/tx/${event.txHash}" target="_blank">
                  ${event.txHash.slice(0, 10)}...${event.txHash.slice(-8)}
                </a>
              </span>
            </div>
          </div>
        </div>
      `;
    }

    // Get event badge
    function getEventBadge(name) {
      const badges = {
        'Pay': { label: 'Pay', class: 'pay' },
        'CashOutTokens': { label: 'Cash Out', class: 'cashout' },
        'DistributePayouts': { label: 'Distribute', class: 'distribute' },
        'MintTokens': { label: 'Mint', class: 'mint' },
        'LaunchProject': { label: 'Launch', class: 'config' },
        'QueueRulesets': { label: 'Config', class: 'config' }
      };
      return badges[name] || { label: name, class: 'config' };
    }

    // Get event summary
    function getEventSummary(event) {
      const args = event.args;

      switch (event.name) {
        case 'Pay':
          return {
            title: `Project ${args.projectId}`,
            description: `${truncateAddress(args.payer)} paid ${formatEth(args.amount)} ETH → ${formatNumber(args.newlyIssuedTokenCount)} tokens${args.memo ? ` · "${args.memo}"` : ''}`
          };

        case 'CashOutTokens':
          return {
            title: `Project ${args.projectId}`,
            description: `${truncateAddress(args.holder)} redeemed ${formatNumber(args.cashOutCount)} tokens for ${formatEth(args.reclaimAmount)} ETH`
          };

        case 'DistributePayouts':
          return {
            title: `Project ${args.projectId}`,
            description: `Distributed ${formatEth(args.amountPaidOut)} ETH to ${truncateAddress(args.beneficiary)}`
          };

        case 'MintTokens':
          return {
            title: `Project ${args.projectId}`,
            description: `Minted ${formatNumber(args.tokenCount)} tokens to ${truncateAddress(args.beneficiary)}`
          };

        case 'LaunchProject':
          return {
            title: `Project ${args.projectId}`,
            description: `New project launched${args.memo ? ` · "${args.memo}"` : ''}`
          };

        case 'QueueRulesets':
          return {
            title: `Project ${args.projectId}`,
            description: `Queued new ruleset #${args.rulesetId}`
          };

        default:
          return {
            title: event.name,
            description: JSON.stringify(args)
          };
      }
    }

    // Get event details
    function getEventDetails(event) {
      const args = event.args;
      const details = [];

      // Add all named arguments
      for (const key of Object.keys(args)) {
        if (isNaN(key)) {
          let value = args[key];

          if (typeof value === 'bigint') {
            if (key.toLowerCase().includes('amount') || key.toLowerCase().includes('count') || key.toLowerCase().includes('supply')) {
              value = formatEth(value) + ' ETH / ' + formatNumber(value) + ' wei';
            } else {
              value = value.toString();
            }
          } else if (typeof value === 'string' && value.startsWith('0x') && value.length === 42) {
            value = `<a href="${EXPLORERS[event.chainId]}/address/${value}" target="_blank">${truncateAddress(value)}</a>`;
          }

          details.push({ label: key, value: String(value) });
        }
      }

      details.push({ label: 'Block', value: event.blockNumber.toString() });

      return details;
    }

    // Toggle event details
    function toggleEvent(index) {
      const details = document.getElementById(`event-${index}`);
      details.classList.toggle('open');
    }

    // Live updates
    function toggleLive() {
      const checkbox = document.getElementById('live-toggle');
      const dot = document.getElementById('live-dot');

      if (checkbox.checked) {
        dot.style.background = 'var(--success)';
        liveUpdateInterval = setInterval(loadEvents, 15000);
      } else {
        dot.style.background = 'var(--text-muted)';
        clearInterval(liveUpdateInterval);
      }
    }

    // Helpers
    function truncateAddress(addr) {
      if (!addr) return '';
      return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
    }

    function formatEth(wei) {
      if (!wei) return '0';
      return (Number(wei) / 1e18).toFixed(4);
    }

    function formatNumber(n) {
      if (!n) return '0';
      return Number(n).toLocaleString();
    }

    function formatTimeAgo(timestamp) {
      if (!timestamp) return '';
      const seconds = Math.floor(Date.now() / 1000 - timestamp);

      if (seconds < 60) return `${seconds}s ago`;
      if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
      if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
      return `${Math.floor(seconds / 86400)}d ago`;
    }
  </script>
</body>
</html>
```

---

## Event Types Reference

| Event | Contract | Description |
|-------|----------|-------------|
| `Pay` | Terminal | Payment received |
| `CashOutTokens` | Terminal | Token redemption |
| `DistributePayouts` | Terminal | Payout distribution |
| `UseAllowance` | Terminal | Surplus allowance used |
| `AddToBalance` | Terminal | Balance added without minting |
| `MintTokens` | Controller | Direct token mint |
| `BurnTokens` | Controller | Token burn |
| `LaunchProject` | Controller | New project created |
| `QueueRulesets` | Controller | Ruleset queued |
| `SendReservedTokensToSplits` | Controller | Reserved tokens distributed |

---

## Related Skills

- `/jb-explorer-ui` - Contract read/write interface
- `/jb-ruleset-timeline-ui` - Ruleset history
- `/jb-bendystraw` - Indexed event queries
