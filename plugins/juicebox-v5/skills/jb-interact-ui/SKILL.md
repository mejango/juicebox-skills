---
name: jb-interact-ui
description: Generate minimal frontends for interacting with existing Juicebox V5 projects. Pay, cash out, claim tokens, view project state - all in standalone HTML files.
---

# Juicebox V5 Interaction UI Generator

Generate simple, CSS-minimal frontends for interacting with existing Juicebox projects. Pay into treasuries, cash out tokens, view project state - no build tools required.

## Philosophy

> **Let users interact with Juicebox projects without touching a command line.**

These UIs are for:
- Paying into a project treasury
- Cashing out tokens for ETH
- Viewing project configuration and state
- Claiming ERC-20 tokens from credits

## Template: Project Payment UI

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pay Project</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
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
      max-width: 480px;
      margin: 0 auto;
    }

    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 1.5rem; }

    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1.25rem;
      margin-bottom: 1rem;
    }

    .stat { display: flex; justify-content: space-between; padding: 0.5rem 0; }
    .stat-label { color: var(--text-muted); }
    .stat-value { font-weight: 500; }

    label {
      display: block;
      font-size: 0.875rem;
      color: var(--text-muted);
      margin-bottom: 0.25rem;
    }

    input {
      width: 100%;
      padding: 0.75rem;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 4px;
      color: var(--text);
      font-size: 1rem;
      margin-bottom: 0.75rem;
    }

    input:focus {
      outline: none;
      border-color: var(--accent);
    }

    .input-suffix {
      position: relative;
    }

    .input-suffix input {
      padding-right: 3rem;
    }

    .input-suffix span {
      position: absolute;
      right: 0.75rem;
      top: 50%;
      transform: translateY(-75%);
      color: var(--text-muted);
    }

    button {
      background: var(--accent);
      color: white;
      border: none;
      padding: 0.875rem 1.5rem;
      border-radius: 4px;
      font-size: 1rem;
      cursor: pointer;
      width: 100%;
      font-weight: 500;
    }

    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }

    .receive-preview {
      background: var(--bg);
      border-radius: 4px;
      padding: 0.75rem;
      margin: 0.75rem 0;
      text-align: center;
    }

    .receive-amount {
      font-size: 1.25rem;
      font-weight: 600;
    }

    .receive-label {
      font-size: 0.75rem;
      color: var(--text-muted);
    }

    #tx-status {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem;
      margin-top: 1rem;
    }

    .hidden { display: none !important; }

    a { color: var(--accent); }
  </style>
</head>
<body>
  <h1>Pay Project #<span id="project-id">1</span></h1>
  <p class="subtitle">Contribute ETH and receive tokens</p>

  <!-- Wallet Connection -->
  <div class="card">
    <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    <div id="wallet-status" class="hidden">
      <div class="stat">
        <span class="stat-label">Connected</span>
        <span class="stat-value" id="wallet-address"></span>
      </div>
      <div class="stat">
        <span class="stat-label">Balance</span>
        <span class="stat-value" id="wallet-balance"></span>
      </div>
    </div>
  </div>

  <!-- Project Stats -->
  <div class="card" id="project-stats">
    <div class="stat">
      <span class="stat-label">Treasury Balance</span>
      <span class="stat-value" id="treasury-balance">-</span>
    </div>
    <div class="stat">
      <span class="stat-label">Token Supply</span>
      <span class="stat-value" id="token-supply">-</span>
    </div>
    <div class="stat">
      <span class="stat-label">Tokens per ETH</span>
      <span class="stat-value" id="tokens-per-eth">-</span>
    </div>
  </div>

  <!-- Payment Form -->
  <div class="card">
    <label>Amount to Pay</label>
    <div class="input-suffix">
      <input type="number" id="pay-amount" placeholder="0.0" step="0.001" min="0" oninput="updateReceivePreview()">
      <span>ETH</span>
    </div>

    <div class="receive-preview">
      <div class="receive-amount" id="receive-amount">0</div>
      <div class="receive-label">tokens you'll receive</div>
    </div>

    <label>Memo (optional)</label>
    <input type="text" id="memo" placeholder="Thanks for building!">

    <button id="pay-btn" onclick="pay()" disabled>Pay Project</button>
  </div>

  <!-- Status -->
  <div id="tx-status" class="hidden">
    <span id="tx-state"></span>
    <a id="tx-link" href="#" target="_blank" class="hidden">View transaction</a>
  </div>

  <script>
    // Configuration - UPDATE THESE
    const PROJECT_ID = 1; // Change to your project ID
    const CHAIN_ID = 1; // 1 = Ethereum, 10 = Optimism, 8453 = Base

    // V5 Addresses (same across supported chains)
    const TERMINAL = '0x2db6d704058e552defe415753465df8df0361846';
    const DIRECTORY = '0x0061e516886a0540f63157f112c0588ee0651dcf';

    const TERMINAL_ABI = [
      'function pay(uint256 projectId, address token, uint256 amount, address beneficiary, uint256 minReturnedTokens, string memo, bytes metadata) payable returns (uint256)',
      'function currentSurplusOf(uint256 projectId, tuple(address token, uint8 decimals, uint32 currency)[] accountingContexts, uint256 decimals, uint256 currency) view returns (uint256)'
    ];

    let provider, signer, address, tokensPerEth = 0n;

    document.getElementById('project-id').textContent = PROJECT_ID;

    async function connectWallet() {
      if (!window.ethereum) {
        alert('Please install MetaMask');
        return;
      }

      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      address = await signer.getAddress();

      // Check network
      const network = await provider.getNetwork();
      if (Number(network.chainId) !== CHAIN_ID) {
        alert(`Please switch to the correct network (Chain ID: ${CHAIN_ID})`);
        return;
      }

      // Update UI
      document.getElementById('wallet-address').textContent =
        `${address.slice(0, 6)}...${address.slice(-4)}`;

      const balance = await provider.getBalance(address);
      document.getElementById('wallet-balance').textContent =
        `${parseFloat(ethers.formatEther(balance)).toFixed(4)} ETH`;

      document.getElementById('wallet-status').classList.remove('hidden');
      document.getElementById('connect-btn').classList.add('hidden');
      document.getElementById('pay-btn').disabled = false;

      await loadProjectStats();
    }

    async function loadProjectStats() {
      // In production, fetch from controller/terminal
      // Simplified example:
      tokensPerEth = ethers.parseEther('1000000'); // 1M tokens per ETH

      document.getElementById('treasury-balance').textContent = '10.5 ETH';
      document.getElementById('token-supply').textContent = '10,500,000';
      document.getElementById('tokens-per-eth').textContent = '1,000,000';
    }

    function updateReceivePreview() {
      const amount = document.getElementById('pay-amount').value || '0';
      if (tokensPerEth > 0n) {
        const receive = parseFloat(amount) * parseFloat(ethers.formatEther(tokensPerEth));
        document.getElementById('receive-amount').textContent =
          receive.toLocaleString(undefined, { maximumFractionDigits: 0 });
      }
    }

    async function pay() {
      const amount = document.getElementById('pay-amount').value;
      const memo = document.getElementById('memo').value || '';

      if (!amount || parseFloat(amount) <= 0) {
        alert('Enter an amount to pay');
        return;
      }

      const terminal = new ethers.Contract(TERMINAL, TERMINAL_ABI, signer);
      const value = ethers.parseEther(amount);

      showTxPending('Please confirm in wallet...');

      try {
        const tx = await terminal.pay(
          PROJECT_ID,
          '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // Native token
          value,
          address, // beneficiary = sender
          0, // minReturnedTokens
          memo,
          '0x', // no metadata
          { value }
        );

        showTxSent(tx.hash);
        await tx.wait();
        showTxConfirmed(tx.hash);

      } catch (error) {
        showTxError(error);
      }
    }

    function showTxPending(msg) {
      document.getElementById('tx-status').classList.remove('hidden');
      document.getElementById('tx-state').textContent = '⏳ ' + msg;
      document.getElementById('tx-link').classList.add('hidden');
    }

    function showTxSent(hash) {
      document.getElementById('tx-state').textContent = '🔄 Transaction sent...';
      const link = document.getElementById('tx-link');
      link.href = `https://etherscan.io/tx/${hash}`;
      link.classList.remove('hidden');
    }

    function showTxConfirmed(hash) {
      document.getElementById('tx-state').textContent = '✅ Payment successful!';
    }

    function showTxError(error) {
      document.getElementById('tx-state').textContent = '❌ ' + (error.shortMessage || error.message);
    }
  </script>
</body>
</html>
```

## Template: Cash Out UI

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cash Out Tokens</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    /* Same minimal CSS as above */
  </style>
</head>
<body>
  <h1>Cash Out</h1>
  <p class="subtitle">Burn tokens to reclaim ETH from treasury</p>

  <!-- Wallet Connection -->
  <div class="card">
    <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    <div id="wallet-status" class="hidden">
      <div class="stat">
        <span class="stat-label">Your Token Balance</span>
        <span class="stat-value" id="token-balance">-</span>
      </div>
    </div>
  </div>

  <!-- Cash Out Preview -->
  <div class="card">
    <label>Tokens to Cash Out</label>
    <div class="input-suffix">
      <input type="number" id="cash-out-amount" placeholder="0" oninput="updateCashOutPreview()">
      <span>tokens</span>
    </div>

    <button type="button" onclick="setMax()" style="background: var(--border); margin-bottom: 0.75rem;">
      Max
    </button>

    <div class="receive-preview">
      <div class="receive-amount" id="reclaim-amount">0</div>
      <div class="receive-label">ETH you'll receive</div>
    </div>

    <button id="cashout-btn" onclick="cashOut()" disabled>Cash Out</button>
  </div>

  <!-- Warning -->
  <div class="card" style="border-color: var(--error);">
    <p style="font-size: 0.875rem; color: var(--text-muted);">
      ⚠️ Cash outs burn your tokens permanently. You'll receive your proportional share of the treasury surplus.
    </p>
  </div>

  <div id="tx-status" class="hidden"></div>

  <script>
    const PROJECT_ID = 1;
    const TERMINAL = '0x2db6d704058e552defe415753465df8df0361846';

    const TERMINAL_ABI = [
      'function cashOutTokensOf(address holder, uint256 projectId, uint256 cashOutCount, address tokenToReclaim, uint256 minTokensReclaimed, address beneficiary, bytes metadata) returns (uint256)'
    ];

    let provider, signer, address, tokenBalance = 0n;

    async function connectWallet() {
      // ... similar to pay UI ...
      await loadTokenBalance();
    }

    async function loadTokenBalance() {
      // Fetch from JBTokens contract
      tokenBalance = ethers.parseEther('1000000'); // Example
      document.getElementById('token-balance').textContent =
        parseInt(ethers.formatEther(tokenBalance)).toLocaleString() + ' tokens';
    }

    function setMax() {
      document.getElementById('cash-out-amount').value =
        parseInt(ethers.formatEther(tokenBalance));
      updateCashOutPreview();
    }

    function updateCashOutPreview() {
      // Calculate reclaim amount based on surplus and supply
      const amount = document.getElementById('cash-out-amount').value || '0';
      // Simplified - in production, query terminal for exact amount
      const reclaim = parseFloat(amount) * 0.00001; // Example rate
      document.getElementById('reclaim-amount').textContent =
        reclaim.toFixed(4) + ' ETH';
    }

    async function cashOut() {
      const amount = document.getElementById('cash-out-amount').value;
      const terminal = new ethers.Contract(TERMINAL, TERMINAL_ABI, signer);

      showTxPending('Please confirm in wallet...');

      try {
        const tx = await terminal.cashOutTokensOf(
          address,
          PROJECT_ID,
          ethers.parseEther(amount),
          '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // Reclaim ETH
          0, // minTokensReclaimed
          address, // beneficiary
          '0x' // no metadata
        );

        showTxSent(tx.hash);
        await tx.wait();
        showTxConfirmed(tx.hash);

      } catch (error) {
        showTxError(error);
      }
    }

    // ... tx status functions ...
  </script>
</body>
</html>
```

## Template: NFT Mint UI (721 Hook)

For projects using the 721 tiered NFT hook:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mint NFT</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>/* Minimal CSS */</style>
</head>
<body>
  <h1>Mint NFT</h1>

  <!-- Tier Selection -->
  <div id="tiers-container">
    <!-- Dynamically populated -->
  </div>

  <!-- Selected Tier Preview -->
  <div class="card" id="selected-tier" class="hidden">
    <div id="tier-image"></div>
    <h3 id="tier-name"></h3>
    <div class="stat">
      <span class="stat-label">Price</span>
      <span class="stat-value" id="tier-price"></span>
    </div>
    <div class="stat">
      <span class="stat-label">Remaining</span>
      <span class="stat-value" id="tier-remaining"></span>
    </div>
    <button onclick="mint()">Mint for <span id="mint-price"></span> ETH</button>
  </div>

  <script>
    const PROJECT_ID = 1;
    const TERMINAL = '0x2db6d704058e552defe415753465df8df0361846';

    // Tier data - in production, fetch from hook store
    const TIERS = [
      { id: 1, name: 'Common', price: '0.01', remaining: 100, image: '' },
      { id: 2, name: 'Rare', price: '0.1', remaining: 50, image: '' },
      { id: 3, name: 'Legendary', price: '1.0', remaining: 10, image: '' }
    ];

    let selectedTier = null;

    function renderTiers() {
      const container = document.getElementById('tiers-container');
      container.innerHTML = TIERS.map(tier => `
        <div class="card tier-card" onclick="selectTier(${tier.id})">
          <h3>${tier.name}</h3>
          <p>${tier.price} ETH • ${tier.remaining} left</p>
        </div>
      `).join('');
    }

    function selectTier(tierId) {
      selectedTier = TIERS.find(t => t.id === tierId);
      document.getElementById('tier-name').textContent = selectedTier.name;
      document.getElementById('tier-price').textContent = selectedTier.price + ' ETH';
      document.getElementById('tier-remaining').textContent = selectedTier.remaining;
      document.getElementById('mint-price').textContent = selectedTier.price;
      document.getElementById('selected-tier').classList.remove('hidden');
    }

    async function mint() {
      if (!selectedTier) return;

      // Encode tier ID in metadata for 721 hook
      const metadata = ethers.AbiCoder.defaultAbiCoder().encode(
        ['bytes4', 'bool', 'uint16[]'],
        [
          '0x00000000', // JB721TiersHook metadata ID
          true, // allowOverspending
          [selectedTier.id]
        ]
      );

      const terminal = new ethers.Contract(TERMINAL, TERMINAL_ABI, signer);
      const value = ethers.parseEther(selectedTier.price);

      const tx = await terminal.pay(
        PROJECT_ID,
        '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
        value,
        address,
        0,
        '',
        metadata,
        { value }
      );

      await tx.wait();
      alert('NFT minted!');
    }

    renderTiers();
  </script>
</body>
</html>
```

## Generation Guidelines

1. **Project ID as config** - Make it easy to change which project the UI targets
2. **Network switching** - Detect wrong network and prompt user to switch
3. **Real-time previews** - Show expected token amounts before transaction
4. **Error handling** - Catch wallet rejections and contract reverts gracefully
5. **Loading states** - Disable buttons and show spinners during transactions

## Fetching Project Data

To show real project stats, query the contracts:

```javascript
async function getProjectStats(projectId) {
  const controller = new ethers.Contract(CONTROLLER, [
    'function currentRulesetOf(uint256) view returns (tuple(uint256 cycleNumber, uint256 id, uint256 basedOnId, uint256 start, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, uint256 metadata), tuple(...))'
  ], provider);

  const [ruleset, metadata] = await controller.currentRulesetOf(projectId);

  return {
    weight: ruleset.weight,
    duration: ruleset.duration,
    reservedRate: metadata.reservedRate,
    cashOutTaxRate: metadata.cashOutTaxRate
  };
}
```

## Template: Project Admin UI

For project owners to send payouts and manage configuration:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Project Admin</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; --success: #4caf50; --warning: #ff9800; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 640px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 1.5rem; }
    h2 { font-size: 1.1rem; margin: 1.5rem 0 0.75rem; color: var(--text-muted); }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    .stat { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid var(--border); }
    .stat:last-child { border-bottom: none; }
    .stat-label { color: var(--text-muted); }
    .stat-value { font-weight: 500; font-family: monospace; }
    label { display: block; font-size: 0.875rem; color: var(--text-muted); margin-bottom: 0.25rem; }
    input { width: 100%; padding: 0.75rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--text); font-size: 0.875rem; margin-bottom: 0.75rem; }
    input:focus { outline: none; border-color: var(--accent); }
    button { background: var(--accent); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 4px; font-size: 0.875rem; cursor: pointer; width: 100%; margin-top: 0.5rem; }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .btn-secondary { background: var(--border); }
    .warning { background: rgba(255, 152, 0, 0.1); border-color: var(--warning); }
    .warning p { color: var(--warning); font-size: 0.875rem; }
    .tabs { display: flex; gap: 0.5rem; margin-bottom: 1rem; }
    .tab { flex: 1; padding: 0.75rem; background: var(--surface); border: 1px solid var(--border); border-radius: 4px; cursor: pointer; text-align: center; }
    .tab.active { background: var(--accent); border-color: var(--accent); }
    .tab-content { display: none; }
    .tab-content.active { display: block; }
    .hidden { display: none !important; }
    #tx-status { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; margin-top: 1rem; }
    a { color: var(--accent); }
  </style>
</head>
<body>
  <h1>Project #<span id="project-id">1</span> Admin</h1>
  <p class="subtitle">Manage treasury operations</p>

  <div class="card">
    <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    <div id="wallet-status" class="hidden">
      <div class="stat">
        <span class="stat-label">Connected</span>
        <span class="stat-value" id="wallet-address"></span>
      </div>
      <div class="stat">
        <span class="stat-label">Owner Status</span>
        <span class="stat-value" id="owner-status">Checking...</span>
      </div>
    </div>
  </div>

  <div class="card" id="treasury-card">
    <h2>Treasury Status</h2>
    <div class="stat">
      <span class="stat-label">Balance</span>
      <span class="stat-value" id="treasury-balance">-</span>
    </div>
    <div class="stat">
      <span class="stat-label">Distributable</span>
      <span class="stat-value" id="distributable">-</span>
    </div>
    <div class="stat">
      <span class="stat-label">Payout Limit</span>
      <span class="stat-value" id="payout-limit">-</span>
    </div>
    <div class="stat">
      <span class="stat-label">Current Cycle</span>
      <span class="stat-value" id="current-cycle">-</span>
    </div>
  </div>

  <div class="tabs">
    <div class="tab active" onclick="showTab('payouts')">Send Payouts</div>
    <div class="tab" onclick="showTab('allowance')">Use Allowance</div>
    <div class="tab" onclick="showTab('reserved')">Reserved</div>
  </div>

  <!-- Send Payouts Tab -->
  <div id="payouts-tab" class="tab-content active">
    <div class="card">
      <h2>Distribute to Splits</h2>
      <p style="color: var(--text-muted); font-size: 0.875rem; margin-bottom: 1rem;">
        Send funds to configured split recipients (within payout limit).
      </p>

      <label>Amount to Distribute (ETH)</label>
      <div style="position: relative;">
        <input type="number" id="payout-amount" placeholder="0.0" step="0.01">
      </div>
      <button class="btn-secondary" onclick="setMaxPayout()" style="margin-bottom: 1rem;">Max Available</button>

      <div id="splits-preview" style="background: var(--bg); padding: 0.75rem; border-radius: 4px; margin-bottom: 1rem; font-size: 0.875rem;">
        <strong>Split Recipients:</strong>
        <div id="splits-list" style="margin-top: 0.5rem; color: var(--text-muted);">Loading...</div>
      </div>

      <button onclick="sendPayouts()">Send Payouts</button>
    </div>
  </div>

  <!-- Use Allowance Tab -->
  <div id="allowance-tab" class="tab-content">
    <div class="card">
      <h2>Use Surplus Allowance</h2>
      <p style="color: var(--text-muted); font-size: 0.875rem; margin-bottom: 1rem;">
        Withdraw from surplus (discretionary spending, outside of splits).
      </p>

      <div class="stat">
        <span class="stat-label">Remaining Allowance</span>
        <span class="stat-value" id="surplus-allowance">-</span>
      </div>

      <label>Amount to Withdraw (ETH)</label>
      <input type="number" id="allowance-amount" placeholder="0.0" step="0.01">

      <label>Beneficiary Address</label>
      <input type="text" id="allowance-beneficiary" placeholder="0x... (defaults to connected wallet)">

      <button onclick="useAllowance()">Withdraw from Surplus</button>
    </div>
  </div>

  <!-- Reserved Tokens Tab -->
  <div id="reserved-tab" class="tab-content">
    <div class="card">
      <h2>Distribute Reserved Tokens</h2>
      <p style="color: var(--text-muted); font-size: 0.875rem; margin-bottom: 1rem;">
        Mint and distribute accumulated reserved tokens to split recipients.
      </p>

      <div class="stat">
        <span class="stat-label">Pending Reserved Tokens</span>
        <span class="stat-value" id="pending-reserved">-</span>
      </div>

      <button onclick="sendReservedTokens()">Distribute Reserved Tokens</button>
    </div>
  </div>

  <div id="tx-status" class="hidden">
    <span id="tx-state"></span>
    <a id="tx-link" href="#" target="_blank" class="hidden">View transaction</a>
  </div>

  <script>
    const PROJECT_ID = 1; // UPDATE THIS
    const CHAIN_ID = 1;

    const TERMINAL = '0x2db6d704058e552defe415753465df8df0361846';
    const CONTROLLER = '0x27da30646502e2f642be5281322ae8c394f7668a';
    const PROJECTS = '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4';

    const TERMINAL_ABI = [
      'function sendPayoutsOf(uint256 projectId, address token, uint256 amount, uint256 currency, uint256 minTokensPaidOut) returns (uint256)',
      'function useAllowanceOf(uint256 projectId, address token, uint256 amount, uint256 currency, uint256 minTokensPaidOut, address beneficiary, address feeBeneficiary, string memo) returns (uint256)'
    ];

    const CONTROLLER_ABI = [
      'function sendReservedTokensToSplitsOf(uint256 projectId) returns (uint256)',
      'function pendingReservedTokenBalanceOf(uint256 projectId) view returns (uint256)'
    ];

    const PROJECTS_ABI = [
      'function ownerOf(uint256 tokenId) view returns (address)'
    ];

    let provider, signer, address;

    document.getElementById('project-id').textContent = PROJECT_ID;

    function showTab(tabName) {
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
      event.target.classList.add('active');
      document.getElementById(`${tabName}-tab`).classList.add('active');
    }

    async function connectWallet() {
      if (!window.ethereum) { alert('Please install MetaMask'); return; }

      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      address = await signer.getAddress();

      document.getElementById('wallet-address').textContent = `${address.slice(0,6)}...${address.slice(-4)}`;
      document.getElementById('wallet-status').classList.remove('hidden');
      document.getElementById('connect-btn').classList.add('hidden');

      // Check if owner
      const projects = new ethers.Contract(PROJECTS, PROJECTS_ABI, provider);
      const owner = await projects.ownerOf(PROJECT_ID);
      const isOwner = owner.toLowerCase() === address.toLowerCase();
      document.getElementById('owner-status').textContent = isOwner ? '✅ Owner' : '⚠️ Not Owner';

      await loadTreasuryStats();
    }

    async function loadTreasuryStats() {
      // In production, fetch from terminal and controller
      document.getElementById('treasury-balance').textContent = '10.5 ETH';
      document.getElementById('distributable').textContent = '8.0 ETH';
      document.getElementById('payout-limit').textContent = '8.0 ETH / cycle';
      document.getElementById('current-cycle').textContent = '3';
      document.getElementById('surplus-allowance').textContent = '2.5 ETH';
      document.getElementById('pending-reserved').textContent = '50,000 tokens';
      document.getElementById('splits-list').innerHTML = '• 0x1234...5678 (50%)<br>• Project #2 (50%)';
    }

    function setMaxPayout() {
      document.getElementById('payout-amount').value = '8.0';
    }

    async function sendPayouts() {
      const amount = document.getElementById('payout-amount').value;
      if (!amount || parseFloat(amount) <= 0) { alert('Enter an amount'); return; }

      const terminal = new ethers.Contract(TERMINAL, TERMINAL_ABI, signer);

      showTxPending('Please confirm in wallet...');

      try {
        const tx = await terminal.sendPayoutsOf(
          PROJECT_ID,
          '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // ETH
          ethers.parseEther(amount),
          0, // currency
          0  // minTokensPaidOut
        );

        showTxSent(tx.hash);
        await tx.wait();
        showTxConfirmed();
        await loadTreasuryStats();
      } catch (error) {
        showTxError(error);
      }
    }

    async function useAllowance() {
      const amount = document.getElementById('allowance-amount').value;
      const beneficiary = document.getElementById('allowance-beneficiary').value || address;

      if (!amount || parseFloat(amount) <= 0) { alert('Enter an amount'); return; }

      const terminal = new ethers.Contract(TERMINAL, TERMINAL_ABI, signer);

      showTxPending('Please confirm in wallet...');

      try {
        const tx = await terminal.useAllowanceOf(
          PROJECT_ID,
          '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
          ethers.parseEther(amount),
          0,
          0,
          beneficiary,
          address, // feeBeneficiary
          'Surplus allowance withdrawal'
        );

        showTxSent(tx.hash);
        await tx.wait();
        showTxConfirmed();
        await loadTreasuryStats();
      } catch (error) {
        showTxError(error);
      }
    }

    async function sendReservedTokens() {
      const controller = new ethers.Contract(CONTROLLER, CONTROLLER_ABI, signer);

      showTxPending('Please confirm in wallet...');

      try {
        const tx = await controller.sendReservedTokensToSplitsOf(PROJECT_ID);
        showTxSent(tx.hash);
        await tx.wait();
        showTxConfirmed();
        await loadTreasuryStats();
      } catch (error) {
        showTxError(error);
      }
    }

    function showTxPending(msg) {
      document.getElementById('tx-status').classList.remove('hidden');
      document.getElementById('tx-state').textContent = '⏳ ' + msg;
      document.getElementById('tx-link').classList.add('hidden');
    }
    function showTxSent(hash) {
      document.getElementById('tx-state').textContent = '🔄 Transaction sent...';
      const link = document.getElementById('tx-link');
      link.href = `https://etherscan.io/tx/${hash}`;
      link.classList.remove('hidden');
    }
    function showTxConfirmed() {
      document.getElementById('tx-state').textContent = '✅ Transaction confirmed!';
    }
    function showTxError(error) {
      document.getElementById('tx-state').textContent = '❌ ' + (error.shortMessage || error.message);
    }
  </script>
</body>
</html>
```

## Template: Claim Tokens UI

For converting credits to ERC-20 tokens:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Claim Tokens</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 480px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 1.5rem; }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    .stat { display: flex; justify-content: space-between; padding: 0.5rem 0; }
    .stat-label { color: var(--text-muted); }
    .stat-value { font-weight: 500; }
    label { display: block; font-size: 0.875rem; color: var(--text-muted); margin-bottom: 0.25rem; }
    input { width: 100%; padding: 0.75rem; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; color: var(--text); font-size: 1rem; margin-bottom: 0.75rem; }
    input:focus { outline: none; border-color: var(--accent); }
    button { background: var(--accent); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 4px; font-size: 0.875rem; cursor: pointer; width: 100%; }
    button:hover { opacity: 0.9; }
    button:disabled { opacity: 0.5; cursor: not-allowed; }
    .btn-secondary { background: var(--border); margin-bottom: 0.75rem; }
    .info { background: var(--bg); padding: 0.75rem; border-radius: 4px; font-size: 0.8rem; color: var(--text-muted); margin-bottom: 1rem; }
    .hidden { display: none !important; }
    #tx-status { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1rem; margin-top: 1rem; }
    a { color: var(--accent); }
  </style>
</head>
<body>
  <h1>Claim Tokens</h1>
  <p class="subtitle">Convert credits to ERC-20 tokens</p>

  <div class="card">
    <button id="connect-btn" onclick="connectWallet()">Connect Wallet</button>
    <div id="wallet-status" class="hidden">
      <div class="stat">
        <span class="stat-label">Connected</span>
        <span class="stat-value" id="wallet-address"></span>
      </div>
    </div>
  </div>

  <div class="card">
    <h2 style="font-size: 1.1rem; color: var(--text-muted); margin-bottom: 1rem;">Your Balances</h2>
    <div class="stat">
      <span class="stat-label">Credits (unclaimed)</span>
      <span class="stat-value" id="credit-balance">-</span>
    </div>
    <div class="stat">
      <span class="stat-label">ERC-20 Tokens</span>
      <span class="stat-value" id="token-balance">-</span>
    </div>
    <div class="stat">
      <span class="stat-label">Total Balance</span>
      <span class="stat-value" id="total-balance">-</span>
    </div>
  </div>

  <div class="card" id="claim-section">
    <div class="info">
      💡 Credits are stored in the Juicebox protocol. Claiming converts them to ERC-20 tokens in your wallet, which you can then transfer or use in DeFi.
    </div>

    <label>Amount to Claim</label>
    <input type="number" id="claim-amount" placeholder="0">
    <button class="btn-secondary" onclick="setMaxClaim()">Claim All</button>

    <button id="claim-btn" onclick="claimTokens()" disabled>Claim Tokens</button>
  </div>

  <div class="card" id="no-token-warning" class="hidden" style="border-color: var(--accent);">
    <p style="font-size: 0.875rem;">
      ⚠️ This project hasn't deployed an ERC-20 token yet. Credits cannot be claimed until the project owner deploys one.
    </p>
  </div>

  <div id="tx-status" class="hidden">
    <span id="tx-state"></span>
    <a id="tx-link" href="#" target="_blank" class="hidden">View transaction</a>
  </div>

  <script>
    const PROJECT_ID = 1; // UPDATE THIS

    const CONTROLLER = '0x27da30646502e2f642be5281322ae8c394f7668a';
    const TOKENS = '0x34b1e3cb8f7db8bde226e930b9ae9dd1ec44c586';

    const CONTROLLER_ABI = [
      'function claimTokensFor(address holder, uint256 projectId, uint256 tokenCount, address beneficiary)'
    ];

    const TOKENS_ABI = [
      'function creditBalanceOf(address holder, uint256 projectId) view returns (uint256)',
      'function tokenOf(uint256 projectId) view returns (address)',
      'function totalBalanceOf(address holder, uint256 projectId) view returns (uint256)'
    ];

    let provider, signer, address, creditBalance = 0n;

    async function connectWallet() {
      if (!window.ethereum) { alert('Please install MetaMask'); return; }

      provider = new ethers.BrowserProvider(window.ethereum);
      signer = await provider.getSigner();
      address = await signer.getAddress();

      document.getElementById('wallet-address').textContent = `${address.slice(0,6)}...${address.slice(-4)}`;
      document.getElementById('wallet-status').classList.remove('hidden');
      document.getElementById('connect-btn').classList.add('hidden');

      await loadBalances();
    }

    async function loadBalances() {
      const tokens = new ethers.Contract(TOKENS, TOKENS_ABI, provider);

      // Check if project has ERC-20 token
      const tokenAddr = await tokens.tokenOf(PROJECT_ID);
      const hasToken = tokenAddr !== ethers.ZeroAddress;

      if (!hasToken) {
        document.getElementById('claim-section').classList.add('hidden');
        document.getElementById('no-token-warning').classList.remove('hidden');
      }

      // Get balances
      creditBalance = await tokens.creditBalanceOf(address, PROJECT_ID);
      const totalBalance = await tokens.totalBalanceOf(address, PROJECT_ID);
      const tokenBalance = totalBalance - creditBalance;

      document.getElementById('credit-balance').textContent =
        parseInt(ethers.formatEther(creditBalance)).toLocaleString();
      document.getElementById('token-balance').textContent =
        parseInt(ethers.formatEther(tokenBalance)).toLocaleString();
      document.getElementById('total-balance').textContent =
        parseInt(ethers.formatEther(totalBalance)).toLocaleString();

      if (hasToken && creditBalance > 0n) {
        document.getElementById('claim-btn').disabled = false;
      }
    }

    function setMaxClaim() {
      document.getElementById('claim-amount').value =
        parseInt(ethers.formatEther(creditBalance));
    }

    async function claimTokens() {
      const amount = document.getElementById('claim-amount').value;
      if (!amount || parseInt(amount) <= 0) { alert('Enter an amount'); return; }

      const controller = new ethers.Contract(CONTROLLER, CONTROLLER_ABI, signer);

      showTxPending('Please confirm in wallet...');

      try {
        const tx = await controller.claimTokensFor(
          address,
          PROJECT_ID,
          ethers.parseEther(amount),
          address
        );

        showTxSent(tx.hash);
        await tx.wait();
        showTxConfirmed();
        await loadBalances();
      } catch (error) {
        showTxError(error);
      }
    }

    function showTxPending(msg) {
      document.getElementById('tx-status').classList.remove('hidden');
      document.getElementById('tx-state').textContent = '⏳ ' + msg;
      document.getElementById('tx-link').classList.add('hidden');
    }
    function showTxSent(hash) {
      document.getElementById('tx-state').textContent = '🔄 Transaction sent...';
      const link = document.getElementById('tx-link');
      link.href = `https://etherscan.io/tx/${hash}`;
      link.classList.remove('hidden');
    }
    function showTxConfirmed() {
      document.getElementById('tx-state').textContent = '✅ Tokens claimed!';
    }
    function showTxError(error) {
      document.getElementById('tx-state').textContent = '❌ ' + (error.shortMessage || error.message);
    }
  </script>
</body>
</html>
```

## Template: Project Dashboard UI

A read-only dashboard showing project state:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Project Dashboard</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/ethers/6.9.0/ethers.umd.min.js"></script>
  <style>
    :root { --bg: #0a0a0a; --surface: #141414; --border: #2a2a2a; --text: #e0e0e0; --text-muted: #808080; --accent: #5c6bc0; --success: #4caf50; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: var(--bg); color: var(--text); padding: 2rem; max-width: 800px; margin: 0 auto; line-height: 1.6; }
    h1 { font-size: 1.75rem; margin-bottom: 0.5rem; }
    .subtitle { color: var(--text-muted); margin-bottom: 2rem; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 1.5rem; }
    .metric-card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; }
    .metric-label { font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
    .metric-value { font-size: 1.5rem; font-weight: 600; }
    .metric-sub { font-size: 0.875rem; color: var(--text-muted); margin-top: 0.25rem; }
    .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 1.25rem; margin-bottom: 1rem; }
    h2 { font-size: 1.1rem; color: var(--text-muted); margin-bottom: 1rem; }
    .stat-row { display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border); }
    .stat-row:last-child { border-bottom: none; }
    .stat-label { color: var(--text-muted); }
    .stat-value { font-family: monospace; }
    .badge { display: inline-block; padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.75rem; background: var(--accent); }
    .badge-success { background: var(--success); }
    a { color: var(--accent); text-decoration: none; }
  </style>
</head>
<body>
  <h1 id="project-name">Loading...</h1>
  <p class="subtitle">Project #<span id="project-id">1</span></p>

  <div class="grid">
    <div class="metric-card">
      <div class="metric-label">Treasury Balance</div>
      <div class="metric-value" id="treasury-balance">-</div>
      <div class="metric-sub">ETH</div>
    </div>
    <div class="metric-card">
      <div class="metric-label">Token Supply</div>
      <div class="metric-value" id="token-supply">-</div>
      <div class="metric-sub">tokens issued</div>
    </div>
    <div class="metric-card">
      <div class="metric-label">Token Holders</div>
      <div class="metric-value" id="holder-count">-</div>
      <div class="metric-sub">unique addresses</div>
    </div>
    <div class="metric-card">
      <div class="metric-label">Current Cycle</div>
      <div class="metric-value" id="current-cycle">-</div>
      <div class="metric-sub" id="cycle-end">-</div>
    </div>
  </div>

  <div class="card">
    <h2>Current Ruleset</h2>
    <div class="stat-row">
      <span class="stat-label">Duration</span>
      <span class="stat-value" id="duration">-</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Weight (tokens/ETH)</span>
      <span class="stat-value" id="weight">-</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Reserved Rate</span>
      <span class="stat-value" id="reserved-rate">-</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Cash Out Tax Rate</span>
      <span class="stat-value" id="cash-out-tax">-</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Payout Limit</span>
      <span class="stat-value" id="payout-limit">-</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Data Hook</span>
      <span class="stat-value" id="data-hook">-</span>
    </div>
  </div>

  <div class="card">
    <h2>Project Owner</h2>
    <div class="stat-row">
      <span class="stat-label">Address</span>
      <span class="stat-value"><a id="owner-link" href="#" target="_blank"><span id="owner-address">-</span></a></span>
    </div>
  </div>

  <script>
    const PROJECT_ID = 1; // UPDATE THIS
    const CHAIN_ID = 1;

    const CONTROLLER = '0x27da30646502e2f642be5281322ae8c394f7668a';
    const PROJECTS = '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4';

    const CONTROLLER_ABI = [
      'function currentRulesetOf(uint256 projectId) view returns (tuple(uint256 cycleNumber, uint256 id, uint256 basedOnId, uint256 start, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, uint256 metadata), tuple(uint256 reservedRate, uint256 cashOutTaxRate, uint256 baseCurrency, bool pausePay, bool pauseCashOut, bool pauseTransfers, bool allowOwnerMinting, bool allowTerminalMigration, bool allowSetTerminals, bool allowSetController, bool allowAddAccountingContexts, bool allowAddPriceFeed, bool ownerMustSendPayouts, bool holdFees, bool useTotalSurplusForCashOuts, bool useDataHookForPay, bool useDataHookForCashOut, address dataHook, uint256 metadata))',
      'function totalTokenSupplyWithReservedTokensOf(uint256 projectId) view returns (uint256)'
    ];

    document.getElementById('project-id').textContent = PROJECT_ID;

    async function loadProjectData() {
      const provider = new ethers.JsonRpcProvider('https://eth.llamarpc.com');
      const controller = new ethers.Contract(CONTROLLER, CONTROLLER_ABI, provider);

      try {
        const [ruleset, metadata] = await controller.currentRulesetOf(PROJECT_ID);
        const totalSupply = await controller.totalTokenSupplyWithReservedTokensOf(PROJECT_ID);

        // Update UI
        document.getElementById('project-name').textContent = `Project #${PROJECT_ID}`;
        document.getElementById('token-supply').textContent =
          parseInt(ethers.formatEther(totalSupply)).toLocaleString();

        document.getElementById('current-cycle').textContent = ruleset.cycleNumber.toString();
        document.getElementById('duration').textContent =
          ruleset.duration > 0 ? `${Number(ruleset.duration) / 86400} days` : 'Indefinite';
        document.getElementById('weight').textContent =
          parseInt(ethers.formatEther(ruleset.weight)).toLocaleString();
        document.getElementById('reserved-rate').textContent =
          `${Number(metadata.reservedRate) / 100}%`;
        document.getElementById('cash-out-tax').textContent =
          `${Number(metadata.cashOutTaxRate) / 100}%`;
        document.getElementById('data-hook').textContent =
          metadata.dataHook === ethers.ZeroAddress ? 'None' : `${metadata.dataHook.slice(0,10)}...`;

        // These would need additional queries
        document.getElementById('treasury-balance').textContent = '-';
        document.getElementById('holder-count').textContent = '-';
        document.getElementById('payout-limit').textContent = '-';

      } catch (error) {
        console.error('Error loading project data:', error);
        document.getElementById('project-name').textContent = 'Error loading project';
      }
    }

    loadProjectData();
  </script>
</body>
</html>
```

## Generation Guidelines

1. **Project ID as config** - Make it easy to change which project the UI targets
2. **Network switching** - Detect wrong network and prompt user to switch
3. **Real-time previews** - Show expected token amounts before transaction
4. **Error handling** - Catch wallet rejections and contract reverts gracefully
5. **Loading states** - Disable buttons and show spinners during transactions
6. **Read-only mode** - Support viewing data without wallet connection

## Fetching Project Data

To show real project stats, query the contracts:

```javascript
async function getProjectStats(projectId) {
  const controller = new ethers.Contract(CONTROLLER, [
    'function currentRulesetOf(uint256) view returns (tuple(uint256 cycleNumber, uint256 id, uint256 basedOnId, uint256 start, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, uint256 metadata), tuple(...))'
  ], provider);

  const [ruleset, metadata] = await controller.currentRulesetOf(projectId);

  return {
    weight: ruleset.weight,
    duration: ruleset.duration,
    reservedRate: metadata.reservedRate,
    cashOutTaxRate: metadata.cashOutTaxRate
  };
}
```

## Fetching Data with Bendystraw

Instead of querying contracts directly, use Bendystraw for faster, indexed data:

```javascript
// Bendystraw client (use server-side proxy to hide API key)
async function bendystrawQuery(query, variables = {}) {
  const response = await fetch('/api/bendystraw', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, variables })
  });
  return (await response.json()).data;
}

// Get project stats
async function getProjectStats(projectId, chainId) {
  return bendystrawQuery(`
    query($projectId: Int!, $chainId: Int!) {
      project(projectId: $projectId, chainId: $chainId) {
        name handle logoUri owner
        balance volume volumeUsd
        tokenSupply token tokenSymbol
        paymentsCount contributorsCount
        trendingScore trendingVolume
      }
    }
  `, { projectId, chainId });
}

// Get recent payments
async function getRecentPayments(projectId, chainId) {
  return bendystrawQuery(`
    query($projectId: Int!, $chainId: Int!) {
      payEvents(
        where: { projectId: $projectId, chainId: $chainId }
        orderBy: "timestamp"
        orderDirection: "desc"
        limit: 20
      ) {
        items {
          timestamp txHash from beneficiary
          amount amountUsd memo newlyIssuedTokenCount
        }
      }
    }
  `, { projectId, chainId });
}

// Get participant token balance
async function getParticipant(projectId, chainId, address) {
  return bendystrawQuery(`
    query($projectId: Int!, $chainId: Int!, $address: String!) {
      participant(projectId: $projectId, chainId: $chainId, address: $address) {
        address
        balance creditBalance erc20Balance
        volume volumeUsd paymentsCount
      }
    }
  `, { projectId, chainId, address });
}

// Get top token holders
async function getTopHolders(projectId, chainId) {
  return bendystrawQuery(`
    query($projectId: Int!, $chainId: Int!) {
      participants(
        where: { projectId: $projectId, chainId: $chainId }
        orderBy: "balance"
        orderDirection: "desc"
        limit: 50
      ) {
        items {
          address balance volume paymentsCount
        }
      }
    }
  `, { projectId, chainId });
}
```

### Server-Side Proxy (Required)

Bendystraw requires an API key. Use a server-side proxy:

```javascript
// Next.js: pages/api/bendystraw.js
export default async function handler(req, res) {
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

Contact [@peripheralist](https://x.com/peripheralist) for an API key.

## Related Skills

- `/jb-deploy-ui` - UIs for deploying new projects
- `/jb-omnichain-ui` - Multi-chain UIs with Relayr & Bendystraw
- `/jb-query` - Direct contract queries (when Bendystraw unavailable)
- `/jb-v5-api` - Contract function signatures
