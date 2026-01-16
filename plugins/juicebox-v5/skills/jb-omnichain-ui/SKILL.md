---
name: jb-omnichain-ui
description: Build omnichain UIs for Juicebox projects. Deploy to multiple chains with single payment, display unified cross-chain data.
---

# Juicebox V5 Omnichain UI Development

Build frontends that deploy and interact with Juicebox projects across multiple chains.

## Philosophy

> **Pay once on any chain. Deploy everywhere. Query unified data.**

Omnichain UIs enable:
- Single-payment multi-chain deployments via Relayr
- Unified project data across all chains via Bendystraw
- Cross-chain token bridging visibility via Sucker Groups

## Tool References

For complete API documentation, see:
- `/jb-relayr` - Multi-chain transaction bundling API
- `/jb-bendystraw` - Cross-chain data aggregation API

---

## Quick Start

### Relayr (Transactions)

```javascript
const RELAYR_API = 'https://api.relayr.ba5ed.com';

// 1. Sign forward requests for each chain
// 2. POST /v1/bundle/prepaid to get payment options
// 3. User pays on one chain
// 4. Poll /v1/bundle/{uuid} for completion

// No API key required
```

### Bendystraw (Data)

```javascript
const BENDYSTRAW_API = 'https://bendystraw.xyz/{API_KEY}/graphql';

// API key required - use server-side proxy
// Contact @peripheralist on X for key
```

---

## Omnichain Deploy UI Template

Complete HTML template for deploying projects to multiple chains.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Deploy Omnichain Project</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; --success: #4caf50; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 640px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 1.5rem; }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    label { display: block; font-size: 0.875rem; color: var(--text-muted); margin-bottom: 0.25rem; }
    input, select { width: 100%; padding: 0.625rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--text); font-size: 0.875rem; margin-bottom: 0.75rem; }
    button { background: var(--accent); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 4px; font-size: 0.875rem; cursor: pointer; width: 100%; }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .chain-select { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-bottom: 1rem; }
    .chain-chip { padding: 0.5rem 1rem; border: 1px solid var(--border); border-radius: 4px; cursor: pointer; font-size: 0.875rem; }
    .chain-chip.selected { background: var(--accent); border-color: var(--accent); }
    .chain-chip.payment { background: var(--success); border-color: var(--success); }
    .status-item { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--border); }
    .status-item:last-child { border-bottom: none; }
    .hidden { display: none !important; }
  </style>
</head>
<body>
  <h1>Deploy Omnichain Project</h1>
  <p class="subtitle">Deploy to multiple chains with a single payment</p>

  <div class="card">
    <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    <div id="wallet-status" class="hidden">
      Connected: <span id="wallet-address"></span>
    </div>
  </div>

  <div class="card">
    <h2 style="font-size: 1.1rem; color: var(--text-muted); margin-bottom: 1rem;">Select Target Chains</h2>
    <div class="chain-select" id="target-chains">
      <div class="chain-chip" data-chain="1" onclick="toggleChain(this)">Ethereum</div>
      <div class="chain-chip" data-chain="10" onclick="toggleChain(this)">Optimism</div>
      <div class="chain-chip" data-chain="8453" onclick="toggleChain(this)">Base</div>
      <div class="chain-chip" data-chain="42161" onclick="toggleChain(this)">Arbitrum</div>
    </div>
  </div>

  <div class="card">
    <label>Project Name</label>
    <input type="text" id="project-name" placeholder="My Omnichain Project">

    <label>Token Symbol</label>
    <input type="text" id="token-symbol" placeholder="OMNI">
  </div>

  <div class="card" id="payment-section" class="hidden">
    <h2 style="font-size: 1.1rem; color: var(--text-muted); margin-bottom: 1rem;">Select Payment Chain</h2>
    <p style="font-size: 0.875rem; color: var(--text-muted); margin-bottom: 1rem;">
      Pay gas on one chain. Relayr handles the rest.
    </p>
    <div class="chain-select" id="payment-chains"></div>
    <div id="quote-details" style="background: var(--bg); padding: 0.75rem; border-radius: 4px; margin-bottom: 1rem; font-size: 0.875rem;">
      <div class="status-item">
        <span>Total Gas Cost</span>
        <span id="total-cost">-</span>
      </div>
    </div>
  </div>

  <div class="card">
    <button id="deploy-btn" onclick="startDeploy()" disabled>
      Step 1: Sign for Each Chain
    </button>
  </div>

  <div class="card" id="tx-status" class="hidden">
    <h2 style="font-size: 1.1rem; color: var(--text-muted); margin-bottom: 1rem;">Deployment Status</h2>
    <div id="chain-statuses"></div>
  </div>

  <script>
    const RELAYR_API = 'https://api.relayr.ba5ed.com';

    const CHAINS = {
      1: { name: 'Ethereum', explorer: 'https://etherscan.io' },
      10: { name: 'Optimism', explorer: 'https://optimistic.etherscan.io' },
      8453: { name: 'Base', explorer: 'https://basescan.org' },
      42161: { name: 'Arbitrum', explorer: 'https://arbiscan.io' }
    };

    // V5 addresses (deterministic - same on all chains)
    const V5 = {
      controller: '0x...',
      terminal: '0x...',
      forwarder: '0x...'
    };

    let provider, signer, address;
    let selectedChains = new Set();
    let currentQuote = null;

    function toggleChain(el) {
      const chainId = el.dataset.chain;
      if (selectedChains.has(chainId)) {
        selectedChains.delete(chainId);
        el.classList.remove('selected');
      } else {
        selectedChains.add(chainId);
        el.classList.add('selected');
      }
      document.getElementById('deploy-btn').disabled = selectedChains.size === 0;
    }

    async function connectWallet() {
      if (!window.ethereum) { alert('Please install MetaMask'); return; }
      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      address = await signer.getAddress();

      document.getElementById('wallet-address').textContent = `${address.slice(0,6)}...${address.slice(-4)}`;
      document.getElementById('wallet-status').classList.remove('hidden');
      document.getElementById('connect-btn').classList.add('hidden');
    }

    async function startDeploy() {
      if (selectedChains.size === 0) return;

      const btn = document.getElementById('deploy-btn');
      btn.disabled = true;
      btn.textContent = 'Signing...';

      try {
        const signedRequests = [];

        for (const chainId of selectedChains) {
          btn.textContent = `Signing for ${CHAINS[chainId].name}...`;

          const calldata = buildLaunchCalldata();
          const signed = await signForwardRequest(parseInt(chainId), calldata);

          signedRequests.push({
            chain: parseInt(chainId),
            target: V5.forwarder,
            data: signed.encodedData,
            value: '0'
          });
        }

        btn.textContent = 'Getting quote...';
        currentQuote = await getRelayrQuote(signedRequests);

        showPaymentOptions(currentQuote);
        btn.textContent = 'Step 2: Select Payment Chain';

      } catch (error) {
        console.error(error);
        btn.textContent = 'Error - Try Again';
        btn.disabled = false;
      }
    }

    async function signForwardRequest(chainId, calldata) {
      const domain = {
        name: 'Juicebox',
        version: '1',
        chainId: chainId,
        verifyingContract: V5.forwarder
      };

      const types = {
        ForwardRequest: [
          { name: 'from', type: 'address' },
          { name: 'to', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'gas', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint48' },
          { name: 'data', type: 'bytes' }
        ]
      };

      const deadline = Math.floor(Date.now() / 1000) + 48 * 60 * 60;

      const message = {
        from: address,
        to: V5.controller,
        value: '0',
        gas: '1000000',
        nonce: 0, // Query from forwarder in production
        deadline: deadline,
        data: calldata
      };

      const signature = await signer.signTypedData(domain, types, message);

      const forwarderInterface = new ethers.Interface([
        'function execute((address,address,uint256,uint256,uint256,uint48,bytes),bytes)'
      ]);

      const encodedData = forwarderInterface.encodeFunctionData('execute', [
        [message.from, message.to, message.value, message.gas, message.nonce, message.deadline, message.data],
        signature
      ]);

      return { message, signature, encodedData };
    }

    function buildLaunchCalldata() {
      // Build launchProjectFor calldata
      // See /jb-project for full struct encoding
      return '0x...';
    }

    async function getRelayrQuote(signedRequests) {
      const response = await fetch(`${RELAYR_API}/v1/bundle/prepaid`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          transactions: signedRequests,
          virtual_nonce_mode: 'Disabled'
        })
      });

      if (!response.ok) throw new Error('Failed to get quote');
      return await response.json();
    }

    function showPaymentOptions(quote) {
      document.getElementById('payment-section').classList.remove('hidden');

      const container = document.getElementById('payment-chains');
      container.innerHTML = '';

      quote.payment_info.forEach(payment => {
        const chain = CHAINS[payment.chain];
        if (!chain) return;

        const costEth = ethers.formatEther(payment.amount);

        const chip = document.createElement('div');
        chip.className = 'chain-chip';
        chip.innerHTML = `${chain.name}<br><small>${parseFloat(costEth).toFixed(4)} ETH</small>`;
        chip.onclick = () => selectPaymentChain(payment, chip);
        container.appendChild(chip);
      });
    }

    async function selectPaymentChain(payment, chip) {
      document.querySelectorAll('#payment-chains .chain-chip').forEach(c => c.classList.remove('payment'));
      chip.classList.add('payment');

      const btn = document.getElementById('deploy-btn');
      btn.textContent = `Pay on ${CHAINS[payment.chain].name}`;
      btn.disabled = false;
      btn.onclick = () => executePayment(payment);
    }

    async function executePayment(payment) {
      const btn = document.getElementById('deploy-btn');
      btn.disabled = true;
      btn.textContent = 'Confirm in wallet...';

      try {
        const tx = await signer.sendTransaction({
          to: payment.target,
          value: payment.amount,
          data: payment.calldata
        });

        btn.textContent = 'Payment sent...';
        showStatusPanel();

        await tx.wait();
        pollBundleStatus(currentQuote.bundle_uuid);

      } catch (error) {
        console.error(error);
        btn.textContent = 'Error - Try Again';
        btn.disabled = false;
      }
    }

    function showStatusPanel() {
      document.getElementById('tx-status').classList.remove('hidden');
      const container = document.getElementById('chain-statuses');
      container.innerHTML = '';

      for (const chainId of selectedChains) {
        const item = document.createElement('div');
        item.className = 'status-item';
        item.id = `status-${chainId}`;
        item.innerHTML = `
          <span>${CHAINS[chainId].name}</span>
          <span class="status-badge">⏳ Pending</span>
        `;
        container.appendChild(item);
      }
    }

    async function pollBundleStatus(bundleUuid) {
      const poll = async () => {
        try {
          const response = await fetch(`${RELAYR_API}/v1/bundle/${bundleUuid}`);
          const status = await response.json();

          status.transactions.forEach((tx, i) => {
            const chainId = Array.from(selectedChains)[i];
            const statusEl = document.querySelector(`#status-${chainId} .status-badge`);
            if (!statusEl) return;

            if (tx.status === 'Success' || tx.status === 'Completed') {
              statusEl.textContent = '✅ Complete';
              statusEl.style.color = 'var(--success)';
            } else if (tx.status === 'Failed') {
              statusEl.textContent = '❌ Failed';
            } else {
              statusEl.textContent = '🔄 ' + tx.status;
            }
          });

          const allDone = status.transactions.every(
            tx => ['Success', 'Completed', 'Failed'].includes(tx.status)
          );

          if (!allDone) {
            setTimeout(poll, 2000);
          } else {
            document.getElementById('deploy-btn').textContent = '✅ Deployment Complete!';
          }

        } catch (error) {
          console.error('Poll error:', error);
          setTimeout(poll, 2000);
        }
      };

      poll();
    }
  </script>
</body>
</html>
```

---

## Omnichain Dashboard UI Template

Display unified stats across all chains using Bendystraw.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Omnichain Dashboard</title>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 900px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.75rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 2rem; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 1.5rem; }
    .metric-card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; }
    .metric-label { font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; margin-bottom: 0.5rem; }
    .metric-value { font-size: 1.5rem; font-weight: 600; }
    .metric-sub { font-size: 0.875rem; color: var(--text-muted); margin-top: 0.25rem; }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    h2 { font-size: 1.1rem; color: var(--text-muted); margin-bottom: 1rem; }
    .chain-breakdown { display: flex; gap: 1rem; flex-wrap: wrap; }
    .chain-card { flex: 1; min-width: 200px; background: var(--bg); border-radius: 4px; padding: 1rem; }
    .chain-name { font-weight: 600; margin-bottom: 0.5rem; }
    .chain-stat { display: flex; justify-content: space-between; font-size: 0.875rem; padding: 0.25rem 0; }
    .activity-item { display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border); }
    .activity-item:last-child { border-bottom: none; }
    .loading { color: var(--text-muted); text-align: center; padding: 2rem; }
  </style>
</head>
<body>
  <h1 id="project-name">Loading...</h1>
  <p class="subtitle">Omnichain Project Dashboard</p>

  <div class="grid">
    <div class="metric-card">
      <div class="metric-label">Total Balance</div>
      <div class="metric-value" id="total-balance">-</div>
      <div class="metric-sub">across all chains</div>
    </div>
    <div class="metric-card">
      <div class="metric-label">Total Volume</div>
      <div class="metric-value" id="total-volume">-</div>
      <div class="metric-sub">all-time</div>
    </div>
    <div class="metric-card">
      <div class="metric-label">Token Supply</div>
      <div class="metric-value" id="total-supply">-</div>
      <div class="metric-sub">total issued</div>
    </div>
    <div class="metric-card">
      <div class="metric-label">Contributors</div>
      <div class="metric-value" id="total-contributors">-</div>
      <div class="metric-sub">unique addresses</div>
    </div>
  </div>

  <div class="card">
    <h2>Chain Breakdown</h2>
    <div class="chain-breakdown" id="chain-breakdown">
      <div class="loading">Loading chain data...</div>
    </div>
  </div>

  <div class="card">
    <h2>Recent Activity</h2>
    <div id="activity-feed">
      <div class="loading">Loading activity...</div>
    </div>
  </div>

  <script>
    // Configuration
    const SUCKER_GROUP_ID = '0x...'; // Your sucker group ID
    const API_PROXY = '/api/bendystraw'; // Server-side proxy

    const CHAINS = {
      1: { name: 'Ethereum' },
      10: { name: 'Optimism' },
      8453: { name: 'Base' },
      42161: { name: 'Arbitrum' }
    };

    async function query(graphql, variables = {}) {
      const response = await fetch(API_PROXY, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: graphql, variables })
      });
      const result = await response.json();
      return result.data;
    }

    async function loadDashboard() {
      try {
        const data = await query(`
          query($id: String!) {
            suckerGroup(id: $id) {
              volume
              volumeUsd
              balance
              tokenSupply
              paymentsCount
              contributorsCount
              projects_rel {
                projectId
                chainId
                name
                balance
                volume
                paymentsCount
              }
            }
          }
        `, { id: SUCKER_GROUP_ID });

        const group = data.suckerGroup;

        // Update totals
        document.getElementById('project-name').textContent =
          group.projects_rel[0]?.name || 'Omnichain Project';
        document.getElementById('total-balance').textContent =
          formatEth(group.balance) + ' ETH';
        document.getElementById('total-volume').textContent =
          formatEth(group.volume) + ' ETH';
        document.getElementById('total-supply').textContent =
          formatNumber(group.tokenSupply);
        document.getElementById('total-contributors').textContent =
          formatNumber(group.contributorsCount);

        // Chain breakdown
        document.getElementById('chain-breakdown').innerHTML =
          group.projects_rel.map(project => `
            <div class="chain-card">
              <div class="chain-name">${CHAINS[project.chainId]?.name || 'Chain ' + project.chainId}</div>
              <div class="chain-stat">
                <span>Balance</span>
                <span>${formatEth(project.balance)} ETH</span>
              </div>
              <div class="chain-stat">
                <span>Volume</span>
                <span>${formatEth(project.volume)} ETH</span>
              </div>
              <div class="chain-stat">
                <span>Payments</span>
                <span>${formatNumber(project.paymentsCount)}</span>
              </div>
            </div>
          `).join('');

        // Load activity
        if (group.projects_rel.length > 0) {
          const first = group.projects_rel[0];
          await loadActivity(first.projectId, first.chainId);
        }

      } catch (error) {
        console.error('Failed to load:', error);
        document.getElementById('project-name').textContent = 'Error loading';
      }
    }

    async function loadActivity(projectId, chainId) {
      const data = await query(`
        query($projectId: Int!, $chainId: Int!) {
          payEvents(
            where: { projectId: $projectId, chainId: $chainId }
            orderBy: "timestamp"
            orderDirection: "desc"
            limit: 10
          ) {
            items {
              timestamp
              from
              amount
              memo
            }
          }
        }
      `, { projectId, chainId });

      const events = data.payEvents.items;

      if (events.length === 0) {
        document.getElementById('activity-feed').innerHTML =
          '<div class="loading">No recent activity</div>';
        return;
      }

      document.getElementById('activity-feed').innerHTML = events.map(e => `
        <div class="activity-item">
          <div>
            <div>${truncate(e.from)} paid</div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">
              ${e.memo || 'No memo'} · ${formatTime(e.timestamp)}
            </div>
          </div>
          <div style="font-weight: 600;">${formatEth(e.amount)} ETH</div>
        </div>
      `).join('');
    }

    function formatEth(wei) {
      if (!wei) return '0';
      return (parseFloat(wei) / 1e18).toFixed(4);
    }

    function formatNumber(n) {
      if (!n) return '0';
      return parseInt(n).toLocaleString();
    }

    function truncate(addr) {
      if (!addr) return '';
      return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
    }

    function formatTime(ts) {
      return new Date(parseInt(ts) * 1000).toLocaleDateString();
    }

    loadDashboard();
  </script>
</body>
</html>
```

---

## Server-Side Proxy

Bendystraw requires an API key. Use a server-side proxy to keep it secret.

### Next.js

```typescript
// pages/api/bendystraw.ts
export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const response = await fetch(
    `https://bendystraw.xyz/${process.env.BENDYSTRAW_API_KEY}/graphql`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body)
    }
  );

  res.json(await response.json());
}
```

### Express

```javascript
app.post('/api/bendystraw', async (req, res) => {
  const response = await fetch(
    `https://bendystraw.xyz/${process.env.BENDYSTRAW_API_KEY}/graphql`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body)
    }
  );

  res.json(await response.json());
});
```

---

## Common Patterns

### Fetch Project + Check if Omnichain

```javascript
async function loadProject(projectId, chainId) {
  const project = await bendystrawQuery(`
    query($projectId: Int!, $chainId: Int!) {
      project(projectId: $projectId, chainId: $chainId) {
        name balance volume suckerGroupId
      }
    }
  `, { projectId, chainId });

  if (project.suckerGroupId) {
    // Omnichain - fetch aggregated data
    const group = await bendystrawQuery(`
      query($id: String!) {
        suckerGroup(id: $id) {
          volume balance tokenSupply
          projects_rel { chainId balance }
        }
      }
    `, { id: project.suckerGroupId });

    return { project, omnichainStats: group };
  }

  return { project, omnichainStats: null };
}
```

### Poll After Relayr Deploy

```javascript
async function deployAndWaitForIndex(signer, chains, calldata) {
  // Deploy via Relayr
  const quote = await relayrClient.createBundle(/* ... */);
  await payForBundle(quote);
  await relayrClient.waitForCompletion(quote.bundle_uuid);

  // Wait for Bendystraw to index (~1 minute)
  console.log('Waiting for indexer...');
  await new Promise(r => setTimeout(r, 60000));

  // Now fetch from Bendystraw
  const project = await bendystrawQuery(/* ... */);
  return project;
}
```

---

## Related Skills

- `/jb-relayr` - Complete Relayr API reference
- `/jb-bendystraw` - Complete Bendystraw GraphQL reference
- `/jb-deploy-ui` - Single-chain deployment UIs
- `/jb-interact-ui` - Project interaction UIs
