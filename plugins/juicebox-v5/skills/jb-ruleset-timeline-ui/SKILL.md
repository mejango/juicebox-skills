# Juicebox V5 Ruleset Timeline UI

Visual timeline explorer for Juicebox project ruleset history. Shows the evolution of project configurations over time.

## Overview

This skill generates vanilla JS/HTML interfaces for visualizing:
- Complete ruleset history for any project
- Timeline of configuration changes
- Upcoming queued rulesets
- Ruleset approval status
- Parameter comparisons between rulesets

## Ruleset Timeline UI Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Juicebox Ruleset Timeline</title>
  <script src="https://cdn.jsdelivr.net/npm/ethers@6/dist/ethers.umd.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0d0d0d;
      color: #e0e0e0;
      min-height: 100vh;
      padding: 20px;
    }
    .container { max-width: 1000px; margin: 0 auto; }
    h1 { color: #ffcc00; margin-bottom: 20px; font-size: 1.8rem; }
    h2 { color: #ffcc00; margin-bottom: 15px; font-size: 1.3rem; }

    .search-section {
      background: #1a1a1a;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 20px;
    }
    .search-row {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }
    .search-row input, .search-row select {
      flex: 1;
      min-width: 150px;
      padding: 12px;
      background: #2a2a2a;
      border: 1px solid #333;
      border-radius: 8px;
      color: #fff;
      font-size: 14px;
    }
    .search-row button {
      padding: 12px 24px;
      background: #ffcc00;
      color: #000;
      border: none;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
    }
    .search-row button:hover { background: #e6b800; }

    .project-header {
      background: #1a1a1a;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 20px;
      display: none;
    }
    .project-header.visible { display: block; }
    .project-name { font-size: 1.5rem; font-weight: 600; color: #fff; }
    .project-id { color: #888; margin-top: 5px; }

    .timeline-container {
      position: relative;
      padding-left: 40px;
    }
    .timeline-line {
      position: absolute;
      left: 15px;
      top: 0;
      bottom: 0;
      width: 2px;
      background: linear-gradient(180deg, #ffcc00 0%, #333 100%);
    }

    .ruleset-card {
      background: #1a1a1a;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 20px;
      position: relative;
      border-left: 3px solid #333;
    }
    .ruleset-card.current {
      border-left-color: #00ff88;
      background: linear-gradient(90deg, rgba(0,255,136,0.1) 0%, #1a1a1a 20%);
    }
    .ruleset-card.upcoming {
      border-left-color: #ffcc00;
      background: linear-gradient(90deg, rgba(255,204,0,0.1) 0%, #1a1a1a 20%);
    }
    .ruleset-card.past {
      opacity: 0.7;
    }

    .timeline-dot {
      position: absolute;
      left: -33px;
      top: 20px;
      width: 16px;
      height: 16px;
      border-radius: 50%;
      background: #333;
      border: 3px solid #1a1a1a;
    }
    .ruleset-card.current .timeline-dot { background: #00ff88; }
    .ruleset-card.upcoming .timeline-dot { background: #ffcc00; }

    .ruleset-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 15px;
    }
    .ruleset-title {
      font-size: 1.1rem;
      font-weight: 600;
      color: #fff;
    }
    .ruleset-status {
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }
    .ruleset-status.current { background: rgba(0,255,136,0.2); color: #00ff88; }
    .ruleset-status.upcoming { background: rgba(255,204,0,0.2); color: #ffcc00; }
    .ruleset-status.past { background: rgba(136,136,136,0.2); color: #888; }
    .ruleset-status.pending { background: rgba(255,136,0,0.2); color: #ff8800; }

    .ruleset-dates {
      display: flex;
      gap: 20px;
      margin-bottom: 15px;
      font-size: 13px;
      color: #888;
    }
    .ruleset-dates span { display: flex; align-items: center; gap: 5px; }

    .params-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 15px;
    }
    .param-item {
      background: #2a2a2a;
      padding: 12px;
      border-radius: 8px;
    }
    .param-label {
      font-size: 11px;
      color: #888;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 5px;
    }
    .param-value {
      font-size: 14px;
      font-weight: 600;
      color: #fff;
    }
    .param-value.changed {
      color: #ffcc00;
      position: relative;
    }
    .param-value.changed::after {
      content: "Changed";
      position: absolute;
      right: 0;
      font-size: 10px;
      color: #ffcc00;
      font-weight: 400;
    }

    .expand-btn {
      background: none;
      border: 1px solid #333;
      color: #888;
      padding: 8px 16px;
      border-radius: 6px;
      cursor: pointer;
      margin-top: 15px;
      font-size: 13px;
    }
    .expand-btn:hover { border-color: #ffcc00; color: #ffcc00; }

    .expanded-details {
      display: none;
      margin-top: 15px;
      padding-top: 15px;
      border-top: 1px solid #333;
    }
    .expanded-details.visible { display: block; }

    .splits-section { margin-top: 15px; }
    .splits-title {
      font-size: 13px;
      color: #888;
      margin-bottom: 10px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .split-item {
      display: flex;
      justify-content: space-between;
      padding: 8px 12px;
      background: #2a2a2a;
      border-radius: 6px;
      margin-bottom: 5px;
      font-size: 13px;
    }
    .split-address { font-family: monospace; color: #888; }
    .split-percent { color: #00ff88; font-weight: 600; }

    .legend {
      display: flex;
      gap: 20px;
      margin-bottom: 20px;
      font-size: 13px;
    }
    .legend-item { display: flex; align-items: center; gap: 8px; }
    .legend-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
    }
    .legend-dot.current { background: #00ff88; }
    .legend-dot.upcoming { background: #ffcc00; }
    .legend-dot.past { background: #666; }

    .loading {
      text-align: center;
      padding: 40px;
      color: #888;
    }
    .spinner {
      width: 40px;
      height: 40px;
      border: 3px solid #333;
      border-top-color: #ffcc00;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 0 auto 15px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }

    .empty-state {
      text-align: center;
      padding: 60px 20px;
      color: #888;
    }

    .compare-btn {
      background: #2a2a2a;
      border: 1px solid #333;
      color: #fff;
      padding: 6px 12px;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
      margin-left: 10px;
    }
    .compare-btn:hover { border-color: #ffcc00; }

    .compare-modal {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.8);
      z-index: 1000;
      padding: 20px;
      overflow-y: auto;
    }
    .compare-modal.visible { display: flex; justify-content: center; align-items: flex-start; }
    .compare-content {
      background: #1a1a1a;
      border-radius: 12px;
      padding: 20px;
      max-width: 900px;
      width: 100%;
      margin-top: 40px;
    }
    .compare-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }
    .close-btn {
      background: none;
      border: none;
      color: #888;
      font-size: 24px;
      cursor: pointer;
    }
    .compare-table {
      width: 100%;
      border-collapse: collapse;
    }
    .compare-table th, .compare-table td {
      padding: 12px;
      text-align: left;
      border-bottom: 1px solid #333;
    }
    .compare-table th { color: #888; font-weight: 500; }
    .compare-table td.changed { color: #ffcc00; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Ruleset Timeline</h1>

    <div class="search-section">
      <div class="search-row">
        <input type="number" id="projectId" placeholder="Project ID" min="1">
        <select id="chainSelect">
          <option value="1">Ethereum</option>
          <option value="10">Optimism</option>
          <option value="8453">Base</option>
          <option value="42161">Arbitrum</option>
          <option value="11155111">Sepolia</option>
        </select>
        <button onclick="loadTimeline()">Load Timeline</button>
      </div>
    </div>

    <div class="project-header" id="projectHeader">
      <div class="project-name" id="projectName">-</div>
      <div class="project-id" id="projectIdDisplay">-</div>
    </div>

    <div class="legend" id="legend" style="display: none;">
      <div class="legend-item">
        <div class="legend-dot current"></div>
        <span>Current Ruleset</span>
      </div>
      <div class="legend-item">
        <div class="legend-dot upcoming"></div>
        <span>Queued/Upcoming</span>
      </div>
      <div class="legend-item">
        <div class="legend-dot past"></div>
        <span>Past Rulesets</span>
      </div>
    </div>

    <div id="timelineContainer"></div>
  </div>

  <div class="compare-modal" id="compareModal">
    <div class="compare-content">
      <div class="compare-header">
        <h2>Compare Rulesets</h2>
        <button class="close-btn" onclick="closeCompare()">&times;</button>
      </div>
      <div id="compareBody"></div>
    </div>
  </div>

  <script>
    // Chain configurations
    const CHAINS = {
      1: { name: 'Ethereum', rpc: 'https://eth.llamarpc.com', controller: '0x0Ae7403b3C3B4C5222bBbE664bdD8600C593b23e' },
      10: { name: 'Optimism', rpc: 'https://optimism.llamarpc.com', controller: '0x0Ae7403b3C3B4C5222bBbE664bdD8600C593b23e' },
      8453: { name: 'Base', rpc: 'https://base.llamarpc.com', controller: '0x0Ae7403b3C3B4C5222bBbE664bdD8600C593b23e' },
      42161: { name: 'Arbitrum', rpc: 'https://arbitrum.llamarpc.com', controller: '0x0Ae7403b3C3B4C5222bBbE664bdD8600C593b23e' },
      11155111: { name: 'Sepolia', rpc: 'https://sepolia.drpc.org', controller: '0x0Ae7403b3C3B4C5222bBbE664bdD8600C593b23e' }
    };

    const CONTROLLER_ABI = [
      'function currentRulesetOf(uint256 projectId) view returns (tuple(uint256 cycleNumber, uint256 id, uint256 basedOnId, uint256 start, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, uint256 metadata) ruleset, tuple(uint256 reservedRate, uint256 cashOutTaxRate, uint256 baseCurrency, bool pausePay, bool pauseCashOut, bool pauseTransfers, bool allowOwnerMinting, bool allowTerminalMigration, bool allowSetTerminals, bool allowSetController, bool allowAddAccountingContexts, bool allowAddPriceFeed, bool ownerMustSendPayouts, bool holdFees, bool useTotalSurplusForCashOuts, bool useDataHookForPay, bool useDataHookForCashOut, address dataHook, uint256 metadata) metadata)',
      'function upcomingRulesetOf(uint256 projectId) view returns (tuple(uint256 cycleNumber, uint256 id, uint256 basedOnId, uint256 start, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, uint256 metadata) ruleset, tuple(uint256 reservedRate, uint256 cashOutTaxRate, uint256 baseCurrency, bool pausePay, bool pauseCashOut, bool pauseTransfers, bool allowOwnerMinting, bool allowTerminalMigration, bool allowSetTerminals, bool allowSetController, bool allowAddAccountingContexts, bool allowAddPriceFeed, bool ownerMustSendPayouts, bool holdFees, bool useTotalSurplusForCashOuts, bool useDataHookForPay, bool useDataHookForCashOut, address dataHook, uint256 metadata) metadata)',
      'function latestQueuedRulesetOf(uint256 projectId) view returns (tuple(uint256 cycleNumber, uint256 id, uint256 basedOnId, uint256 start, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, uint256 metadata) ruleset, tuple(uint256 reservedRate, uint256 cashOutTaxRate, uint256 baseCurrency, bool pausePay, bool pauseCashOut, bool pauseTransfers, bool allowOwnerMinting, bool allowTerminalMigration, bool allowSetTerminals, bool allowSetController, bool allowAddAccountingContexts, bool allowAddPriceFeed, bool ownerMustSendPayouts, bool holdFees, bool useTotalSurplusForCashOuts, bool useDataHookForPay, bool useDataHookForCashOut, address dataHook, uint256 metadata) metadata, uint256 approvalStatus)',
      'function allRulesetsOf(uint256 projectId, uint256 startingId, uint256 size) view returns (tuple(tuple(uint256 cycleNumber, uint256 id, uint256 basedOnId, uint256 start, uint256 duration, uint256 weight, uint256 weightCutPercent, address approvalHook, uint256 metadata) ruleset, tuple(uint256 reservedRate, uint256 cashOutTaxRate, uint256 baseCurrency, bool pausePay, bool pauseCashOut, bool pauseTransfers, bool allowOwnerMinting, bool allowTerminalMigration, bool allowSetTerminals, bool allowSetController, bool allowAddAccountingContexts, bool allowAddPriceFeed, bool ownerMustSendPayouts, bool holdFees, bool useTotalSurplusForCashOuts, bool useDataHookForPay, bool useDataHookForCashOut, address dataHook, uint256 metadata) metadata)[])',
      'function PROJECTS() view returns (address)'
    ];

    const PROJECTS_ABI = [
      'function tokenURI(uint256 tokenId) view returns (string)'
    ];

    let allRulesets = [];
    let currentRulesetId = null;

    async function loadTimeline() {
      const projectId = document.getElementById('projectId').value;
      const chainId = document.getElementById('chainSelect').value;

      if (!projectId) {
        alert('Please enter a project ID');
        return;
      }

      const container = document.getElementById('timelineContainer');
      container.innerHTML = '<div class="loading"><div class="spinner"></div>Loading ruleset history...</div>';

      const chain = CHAINS[chainId];
      const provider = new ethers.JsonRpcProvider(chain.rpc);
      const controller = new ethers.Contract(chain.controller, CONTROLLER_ABI, provider);

      try {
        // Load project metadata
        const projectsAddr = await controller.PROJECTS();
        const projects = new ethers.Contract(projectsAddr, PROJECTS_ABI, provider);

        try {
          const uri = await projects.tokenURI(projectId);
          if (uri) {
            const metadataUrl = uri.startsWith('ipfs://')
              ? `https://ipfs.io/ipfs/${uri.slice(7)}`
              : uri;
            const response = await fetch(metadataUrl);
            const metadata = await response.json();
            document.getElementById('projectName').textContent = metadata.name || `Project ${projectId}`;
          }
        } catch (e) {
          document.getElementById('projectName').textContent = `Project ${projectId}`;
        }

        document.getElementById('projectIdDisplay').textContent = `ID: ${projectId} on ${chain.name}`;
        document.getElementById('projectHeader').classList.add('visible');

        // Load current ruleset
        const [currentRuleset, currentMetadata] = await controller.currentRulesetOf(projectId);
        currentRulesetId = currentRuleset.id.toString();

        // Load upcoming ruleset
        let upcomingRuleset = null;
        try {
          const [upcoming, upcomingMeta] = await controller.upcomingRulesetOf(projectId);
          if (upcoming.id.toString() !== currentRulesetId) {
            upcomingRuleset = { ruleset: upcoming, metadata: upcomingMeta, status: 'upcoming' };
          }
        } catch (e) {}

        // Load queued ruleset with approval status
        let queuedRuleset = null;
        try {
          const [queued, queuedMeta, approvalStatus] = await controller.latestQueuedRulesetOf(projectId);
          const queuedId = queued.id.toString();
          if (queuedId !== currentRulesetId && (!upcomingRuleset || queuedId !== upcomingRuleset.ruleset.id.toString())) {
            queuedRuleset = { ruleset: queued, metadata: queuedMeta, approvalStatus, status: 'pending' };
          }
        } catch (e) {}

        // Load historical rulesets
        const historicalRulesets = await controller.allRulesetsOf(projectId, 0, 50);

        // Combine and sort rulesets
        allRulesets = [];

        // Add queued/pending
        if (queuedRuleset) {
          allRulesets.push(queuedRuleset);
        }

        // Add upcoming
        if (upcomingRuleset) {
          allRulesets.push(upcomingRuleset);
        }

        // Add current
        allRulesets.push({
          ruleset: currentRuleset,
          metadata: currentMetadata,
          status: 'current'
        });

        // Add historical (excluding current)
        for (const rs of historicalRulesets) {
          if (rs.ruleset.id.toString() !== currentRulesetId) {
            const existing = allRulesets.find(r => r.ruleset.id.toString() === rs.ruleset.id.toString());
            if (!existing) {
              allRulesets.push({ ...rs, status: 'past' });
            }
          }
        }

        // Sort by start time descending (newest first)
        allRulesets.sort((a, b) => Number(b.ruleset.start) - Number(a.ruleset.start));

        renderTimeline();
        document.getElementById('legend').style.display = 'flex';

      } catch (error) {
        console.error(error);
        container.innerHTML = `<div class="empty-state">Error loading rulesets: ${error.message}</div>`;
      }
    }

    function renderTimeline() {
      const container = document.getElementById('timelineContainer');

      if (allRulesets.length === 0) {
        container.innerHTML = '<div class="empty-state">No rulesets found for this project</div>';
        return;
      }

      let html = '<div class="timeline-container"><div class="timeline-line"></div>';

      allRulesets.forEach((rs, index) => {
        const { ruleset, metadata, status, approvalStatus } = rs;
        const startDate = new Date(Number(ruleset.start) * 1000);
        const endDate = ruleset.duration > 0
          ? new Date((Number(ruleset.start) + Number(ruleset.duration)) * 1000)
          : null;

        const statusLabel = status === 'pending'
          ? getApprovalStatusLabel(approvalStatus)
          : status;

        html += `
          <div class="ruleset-card ${status}" data-index="${index}">
            <div class="timeline-dot"></div>
            <div class="ruleset-header">
              <div>
                <div class="ruleset-title">
                  Ruleset #${ruleset.cycleNumber.toString()}
                  ${index < allRulesets.length - 1 ? `<button class="compare-btn" onclick="compareRulesets(${index}, ${index + 1})">Compare with previous</button>` : ''}
                </div>
              </div>
              <span class="ruleset-status ${status}">${statusLabel}</span>
            </div>

            <div class="ruleset-dates">
              <span>Start: ${startDate.toLocaleString()}</span>
              ${endDate ? `<span>End: ${endDate.toLocaleString()}</span>` : '<span>Duration: Indefinite</span>'}
              ${ruleset.duration > 0 ? `<span>Cycle: ${formatDuration(Number(ruleset.duration))}</span>` : ''}
            </div>

            <div class="params-grid">
              <div class="param-item">
                <div class="param-label">Weight</div>
                <div class="param-value">${formatWeight(ruleset.weight)}</div>
              </div>
              <div class="param-item">
                <div class="param-label">Weight Cut %</div>
                <div class="param-value">${(Number(ruleset.weightCutPercent) / 10000000).toFixed(2)}%</div>
              </div>
              <div class="param-item">
                <div class="param-label">Reserved Rate</div>
                <div class="param-value">${(Number(metadata.reservedRate) / 100).toFixed(2)}%</div>
              </div>
              <div class="param-item">
                <div class="param-label">Cash Out Tax</div>
                <div class="param-value">${(Number(metadata.cashOutTaxRate) / 100).toFixed(2)}%</div>
              </div>
            </div>

            <button class="expand-btn" onclick="toggleDetails(${index})">Show more details</button>

            <div class="expanded-details" id="details-${index}">
              <div class="params-grid">
                <div class="param-item">
                  <div class="param-label">Pause Pay</div>
                  <div class="param-value">${metadata.pausePay ? 'Yes' : 'No'}</div>
                </div>
                <div class="param-item">
                  <div class="param-label">Pause Cash Out</div>
                  <div class="param-value">${metadata.pauseCashOut ? 'Yes' : 'No'}</div>
                </div>
                <div class="param-item">
                  <div class="param-label">Owner Minting</div>
                  <div class="param-value">${metadata.allowOwnerMinting ? 'Allowed' : 'Disabled'}</div>
                </div>
                <div class="param-item">
                  <div class="param-label">Terminal Migration</div>
                  <div class="param-value">${metadata.allowTerminalMigration ? 'Allowed' : 'Disabled'}</div>
                </div>
                <div class="param-item">
                  <div class="param-label">Set Terminals</div>
                  <div class="param-value">${metadata.allowSetTerminals ? 'Allowed' : 'Disabled'}</div>
                </div>
                <div class="param-item">
                  <div class="param-label">Set Controller</div>
                  <div class="param-value">${metadata.allowSetController ? 'Allowed' : 'Disabled'}</div>
                </div>
                <div class="param-item">
                  <div class="param-label">Hold Fees</div>
                  <div class="param-value">${metadata.holdFees ? 'Yes' : 'No'}</div>
                </div>
                <div class="param-item">
                  <div class="param-label">Data Hook (Pay)</div>
                  <div class="param-value">${metadata.useDataHookForPay ? 'Enabled' : 'Disabled'}</div>
                </div>
                <div class="param-item">
                  <div class="param-label">Data Hook (Cash Out)</div>
                  <div class="param-value">${metadata.useDataHookForCashOut ? 'Enabled' : 'Disabled'}</div>
                </div>
                ${metadata.dataHook !== ethers.ZeroAddress ? `
                <div class="param-item">
                  <div class="param-label">Data Hook Address</div>
                  <div class="param-value" style="font-family: monospace; font-size: 11px;">${metadata.dataHook}</div>
                </div>
                ` : ''}
                ${ruleset.approvalHook !== ethers.ZeroAddress ? `
                <div class="param-item">
                  <div class="param-label">Approval Hook</div>
                  <div class="param-value" style="font-family: monospace; font-size: 11px;">${ruleset.approvalHook}</div>
                </div>
                ` : ''}
              </div>
            </div>
          </div>
        `;
      });

      html += '</div>';
      container.innerHTML = html;
    }

    function toggleDetails(index) {
      const details = document.getElementById(`details-${index}`);
      details.classList.toggle('visible');

      const btn = details.previousElementSibling;
      btn.textContent = details.classList.contains('visible') ? 'Hide details' : 'Show more details';
    }

    function compareRulesets(index1, index2) {
      const rs1 = allRulesets[index1];
      const rs2 = allRulesets[index2];

      const fields = [
        { key: 'weight', label: 'Weight', format: formatWeight },
        { key: 'weightCutPercent', label: 'Weight Cut %', format: v => (Number(v) / 10000000).toFixed(2) + '%' },
        { key: 'duration', label: 'Duration', format: v => Number(v) === 0 ? 'Indefinite' : formatDuration(Number(v)) },
        { key: 'reservedRate', label: 'Reserved Rate', format: v => (Number(v) / 100).toFixed(2) + '%', metadata: true },
        { key: 'cashOutTaxRate', label: 'Cash Out Tax', format: v => (Number(v) / 100).toFixed(2) + '%', metadata: true },
        { key: 'pausePay', label: 'Pause Pay', format: v => v ? 'Yes' : 'No', metadata: true },
        { key: 'pauseCashOut', label: 'Pause Cash Out', format: v => v ? 'Yes' : 'No', metadata: true },
        { key: 'allowOwnerMinting', label: 'Owner Minting', format: v => v ? 'Allowed' : 'Disabled', metadata: true },
        { key: 'useDataHookForPay', label: 'Pay Data Hook', format: v => v ? 'Enabled' : 'Disabled', metadata: true },
        { key: 'useDataHookForCashOut', label: 'Cash Out Data Hook', format: v => v ? 'Enabled' : 'Disabled', metadata: true },
      ];

      let html = `
        <table class="compare-table">
          <thead>
            <tr>
              <th>Parameter</th>
              <th>Ruleset #${rs1.ruleset.cycleNumber.toString()}</th>
              <th>Ruleset #${rs2.ruleset.cycleNumber.toString()}</th>
            </tr>
          </thead>
          <tbody>
      `;

      fields.forEach(field => {
        const val1 = field.metadata ? rs1.metadata[field.key] : rs1.ruleset[field.key];
        const val2 = field.metadata ? rs2.metadata[field.key] : rs2.ruleset[field.key];
        const formatted1 = field.format(val1);
        const formatted2 = field.format(val2);
        const changed = formatted1 !== formatted2;

        html += `
          <tr>
            <td>${field.label}</td>
            <td class="${changed ? 'changed' : ''}">${formatted1}</td>
            <td>${formatted2}</td>
          </tr>
        `;
      });

      html += '</tbody></table>';

      document.getElementById('compareBody').innerHTML = html;
      document.getElementById('compareModal').classList.add('visible');
    }

    function closeCompare() {
      document.getElementById('compareModal').classList.remove('visible');
    }

    function formatWeight(weight) {
      const w = BigInt(weight);
      const tokens = Number(w) / 1e18;
      if (tokens >= 1000000) return (tokens / 1000000).toFixed(2) + 'M';
      if (tokens >= 1000) return (tokens / 1000).toFixed(2) + 'K';
      return tokens.toFixed(4);
    }

    function formatDuration(seconds) {
      if (seconds < 3600) return Math.round(seconds / 60) + ' minutes';
      if (seconds < 86400) return Math.round(seconds / 3600) + ' hours';
      if (seconds < 604800) return Math.round(seconds / 86400) + ' days';
      return Math.round(seconds / 604800) + ' weeks';
    }

    function getApprovalStatusLabel(status) {
      const labels = {
        0: 'Empty',
        1: 'Upcoming',
        2: 'Active',
        3: 'ApprovalExpected',
        4: 'Approved',
        5: 'Failed'
      };
      return labels[Number(status)] || 'pending';
    }

    // Close modal on escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') closeCompare();
    });

    // Close modal on outside click
    document.getElementById('compareModal').addEventListener('click', (e) => {
      if (e.target.id === 'compareModal') closeCompare();
    });
  </script>
</body>
</html>
```

## Key Features

### Timeline Visualization
- Vertical timeline with visual indicators
- Color-coded status (current, upcoming, past)
- Chronological ordering

### Ruleset Comparison
- Side-by-side parameter comparison
- Highlights changed values
- Compare any two rulesets

### Detailed Information
- Expandable details for each ruleset
- All metadata fields displayed
- Approval hook status

## Data Sources

The timeline uses on-chain data via:
- `currentRulesetOf()` - Active ruleset
- `upcomingRulesetOf()` - Next ruleset
- `latestQueuedRulesetOf()` - Queued with approval status
- `allRulesetsOf()` - Historical rulesets

## Customization Points

1. **Visual styling**: Modify CSS for different themes
2. **Additional fields**: Add more metadata fields to display
3. **Date formatting**: Customize date/time display
4. **Comparison logic**: Extend fields in compare function

## Integration Notes

- Works with any V5 Juicebox project
- Supports all major chains
- No API key required (uses public RPC)
- Can be embedded in larger applications
