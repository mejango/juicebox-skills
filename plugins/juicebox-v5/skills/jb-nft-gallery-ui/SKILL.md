# Juicebox V5 NFT Gallery UI

Interactive gallery for browsing and managing NFTs from Juicebox 721 hooks. Displays tier information, owned NFTs, and minting interfaces.

## Overview

This skill generates vanilla JS/HTML interfaces for:
- Browsing all NFT tiers for a project
- Viewing owned NFTs by wallet
- Minting NFTs from available tiers
- Tier metadata and supply tracking
- NFT transfer functionality

## NFT Gallery UI Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Juicebox NFT Gallery</title>
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
    .container { max-width: 1400px; margin: 0 auto; }
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

    .tabs {
      display: flex;
      gap: 10px;
      margin-bottom: 20px;
    }
    .tab {
      padding: 10px 20px;
      background: #1a1a1a;
      border: 1px solid #333;
      border-radius: 8px;
      color: #888;
      cursor: pointer;
      font-weight: 500;
    }
    .tab.active {
      background: #ffcc00;
      color: #000;
      border-color: #ffcc00;
    }

    .stats-bar {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 15px;
      margin-bottom: 20px;
    }
    .stat-card {
      background: #1a1a1a;
      border-radius: 10px;
      padding: 15px;
      text-align: center;
    }
    .stat-value {
      font-size: 1.5rem;
      font-weight: 700;
      color: #fff;
    }
    .stat-label {
      font-size: 12px;
      color: #888;
      margin-top: 5px;
    }

    .gallery-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 20px;
    }

    .nft-card {
      background: #1a1a1a;
      border-radius: 12px;
      overflow: hidden;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .nft-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    }

    .nft-image {
      width: 100%;
      aspect-ratio: 1;
      background: #2a2a2a;
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;
    }
    .nft-image img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .nft-image .placeholder {
      font-size: 48px;
      color: #444;
    }
    .tier-badge {
      position: absolute;
      top: 10px;
      left: 10px;
      background: rgba(0,0,0,0.7);
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      color: #ffcc00;
      font-weight: 600;
    }
    .supply-badge {
      position: absolute;
      top: 10px;
      right: 10px;
      background: rgba(0,0,0,0.7);
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      color: #00ff88;
    }
    .supply-badge.sold-out {
      color: #ff4444;
    }

    .nft-info {
      padding: 15px;
    }
    .nft-name {
      font-size: 1.1rem;
      font-weight: 600;
      color: #fff;
      margin-bottom: 5px;
    }
    .nft-description {
      font-size: 13px;
      color: #888;
      margin-bottom: 10px;
      line-height: 1.4;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .nft-meta {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-top: 10px;
      border-top: 1px solid #333;
    }
    .nft-price {
      font-size: 1.1rem;
      font-weight: 700;
      color: #ffcc00;
    }
    .nft-votes {
      font-size: 12px;
      color: #888;
    }

    .mint-btn {
      width: 100%;
      padding: 12px;
      background: #ffcc00;
      color: #000;
      border: none;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
      margin-top: 10px;
    }
    .mint-btn:hover { background: #e6b800; }
    .mint-btn:disabled {
      background: #333;
      color: #666;
      cursor: not-allowed;
    }

    .owned-badge {
      position: absolute;
      bottom: 10px;
      left: 10px;
      background: #00ff88;
      color: #000;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }

    .wallet-section {
      background: #1a1a1a;
      border-radius: 12px;
      padding: 15px 20px;
      margin-bottom: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .wallet-info {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .wallet-address {
      font-family: monospace;
      color: #888;
    }
    .connect-btn {
      padding: 10px 20px;
      background: #2a2a2a;
      border: 1px solid #ffcc00;
      color: #ffcc00;
      border-radius: 8px;
      cursor: pointer;
      font-weight: 500;
    }
    .connect-btn:hover { background: #333; }

    .filter-bar {
      display: flex;
      gap: 10px;
      margin-bottom: 20px;
      flex-wrap: wrap;
    }
    .filter-btn {
      padding: 8px 16px;
      background: #1a1a1a;
      border: 1px solid #333;
      color: #888;
      border-radius: 20px;
      cursor: pointer;
      font-size: 13px;
    }
    .filter-btn.active {
      border-color: #ffcc00;
      color: #ffcc00;
    }

    .loading {
      text-align: center;
      padding: 60px 20px;
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

    .modal {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0,0,0,0.9);
      z-index: 1000;
      padding: 20px;
      overflow-y: auto;
    }
    .modal.visible { display: flex; justify-content: center; align-items: flex-start; }
    .modal-content {
      background: #1a1a1a;
      border-radius: 12px;
      max-width: 600px;
      width: 100%;
      margin-top: 40px;
    }
    .modal-image {
      width: 100%;
      aspect-ratio: 1;
      background: #2a2a2a;
    }
    .modal-image img {
      width: 100%;
      height: 100%;
      object-fit: contain;
    }
    .modal-info { padding: 20px; }
    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 15px;
    }
    .modal-title {
      font-size: 1.5rem;
      font-weight: 700;
      color: #fff;
    }
    .close-btn {
      background: none;
      border: none;
      color: #888;
      font-size: 28px;
      cursor: pointer;
      line-height: 1;
    }
    .modal-description {
      color: #888;
      line-height: 1.6;
      margin-bottom: 20px;
    }
    .modal-attributes {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 10px;
      margin-bottom: 20px;
    }
    .attribute {
      background: #2a2a2a;
      padding: 12px;
      border-radius: 8px;
    }
    .attribute-label {
      font-size: 11px;
      color: #888;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .attribute-value {
      font-size: 14px;
      font-weight: 600;
      color: #fff;
      margin-top: 4px;
    }

    .action-buttons {
      display: flex;
      gap: 10px;
    }
    .action-btn {
      flex: 1;
      padding: 14px;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
      border: none;
    }
    .action-btn.primary {
      background: #ffcc00;
      color: #000;
    }
    .action-btn.secondary {
      background: #2a2a2a;
      color: #fff;
      border: 1px solid #333;
    }

    .token-id-badge {
      font-family: monospace;
      font-size: 12px;
      color: #888;
      background: #2a2a2a;
      padding: 4px 8px;
      border-radius: 4px;
    }

    .category-filter {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      margin-bottom: 20px;
    }
    .category-chip {
      padding: 6px 14px;
      background: #2a2a2a;
      border-radius: 20px;
      font-size: 13px;
      cursor: pointer;
      color: #888;
    }
    .category-chip.active {
      background: #ffcc00;
      color: #000;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>NFT Gallery</h1>

    <div class="search-section">
      <div class="search-row">
        <input type="text" id="hookAddress" placeholder="721 Hook Address (0x...)">
        <select id="chainSelect">
          <option value="1">Ethereum</option>
          <option value="10">Optimism</option>
          <option value="8453">Base</option>
          <option value="42161">Arbitrum</option>
          <option value="11155111">Sepolia</option>
        </select>
        <button onclick="loadGallery()">Load Gallery</button>
      </div>
    </div>

    <div class="wallet-section" id="walletSection" style="display: none;">
      <div class="wallet-info">
        <span id="walletStatus">Not connected</span>
        <span class="wallet-address" id="walletAddress"></span>
      </div>
      <button class="connect-btn" id="connectBtn" onclick="connectWallet()">Connect Wallet</button>
    </div>

    <div class="stats-bar" id="statsBar" style="display: none;">
      <div class="stat-card">
        <div class="stat-value" id="totalTiers">-</div>
        <div class="stat-label">Total Tiers</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="totalMinted">-</div>
        <div class="stat-label">Total Minted</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="totalSupply">-</div>
        <div class="stat-label">Max Supply</div>
      </div>
      <div class="stat-card">
        <div class="stat-value" id="floorPrice">-</div>
        <div class="stat-label">Floor Price</div>
      </div>
    </div>

    <div class="tabs" id="tabsContainer" style="display: none;">
      <div class="tab active" data-tab="tiers" onclick="switchTab('tiers')">All Tiers</div>
      <div class="tab" data-tab="owned" onclick="switchTab('owned')">My NFTs</div>
    </div>

    <div class="category-filter" id="categoryFilter"></div>

    <div class="filter-bar" id="filterBar" style="display: none;">
      <button class="filter-btn active" data-filter="all" onclick="filterTiers('all')">All</button>
      <button class="filter-btn" data-filter="available" onclick="filterTiers('available')">Available</button>
      <button class="filter-btn" data-filter="sold-out" onclick="filterTiers('sold-out')">Sold Out</button>
    </div>

    <div id="galleryContainer"></div>
  </div>

  <div class="modal" id="nftModal">
    <div class="modal-content">
      <div class="modal-image" id="modalImage"></div>
      <div class="modal-info">
        <div class="modal-header">
          <div>
            <div class="modal-title" id="modalTitle">-</div>
            <span class="token-id-badge" id="modalTokenId"></span>
          </div>
          <button class="close-btn" onclick="closeModal()">&times;</button>
        </div>
        <div class="modal-description" id="modalDescription"></div>
        <div class="modal-attributes" id="modalAttributes"></div>
        <div class="action-buttons" id="modalActions"></div>
      </div>
    </div>
  </div>

  <script>
    // Chain configurations
    const CHAINS = {
      1: { name: 'Ethereum', rpc: 'https://eth.llamarpc.com' },
      10: { name: 'Optimism', rpc: 'https://optimism.llamarpc.com' },
      8453: { name: 'Base', rpc: 'https://base.llamarpc.com' },
      42161: { name: 'Arbitrum', rpc: 'https://arbitrum.llamarpc.com' },
      11155111: { name: 'Sepolia', rpc: 'https://sepolia.drpc.org' }
    };

    const HOOK_ABI = [
      'function STORE() view returns (address)',
      'function PROJECT_ID() view returns (uint256)',
      'function name() view returns (string)',
      'function symbol() view returns (string)',
      'function tokenURI(uint256 tokenId) view returns (string)',
      'function balanceOf(address owner) view returns (uint256)',
      'function tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)',
      'function ownerOf(uint256 tokenId) view returns (address)',
      'function totalSupply() view returns (uint256)',
      'function payCreditsOf(address) view returns (uint256)',
      'function transferFrom(address from, address to, uint256 tokenId)',
      'function safeTransferFrom(address from, address to, uint256 tokenId)'
    ];

    const STORE_ABI = [
      'function tiersOf(address hook, uint256[] categories, bool includeResolvedUri, uint256 startingId, uint256 size) view returns (tuple(uint256 id, uint256 price, uint256 remainingSupply, uint256 initialSupply, uint256 votingUnits, uint256 reserveFrequency, uint256 reserveBeneficiary, bytes32 encodedIPFSUri, uint256 category, uint8 discountPercent, bool allowOwnerMint, bool transfersPausable, bool useVotingUnits, bool cannotBeRemoved, string resolvedUri)[])',
      'function tierOf(address hook, uint256 tierId, bool includeResolvedUri) view returns (tuple(uint256 id, uint256 price, uint256 remainingSupply, uint256 initialSupply, uint256 votingUnits, uint256 reserveFrequency, uint256 reserveBeneficiary, bytes32 encodedIPFSUri, uint256 category, uint8 discountPercent, bool allowOwnerMint, bool transfersPausable, bool useVotingUnits, bool cannotBeRemoved, string resolvedUri))',
      'function tierIdOfToken(uint256 tokenId) view returns (uint256)',
      'function numberOfBurnedFor(address hook) view returns (uint256)',
      'function totalCashOutWeight(address hook) view returns (uint256)'
    ];

    let provider = null;
    let signer = null;
    let hookContract = null;
    let storeContract = null;
    let allTiers = [];
    let ownedNFTs = [];
    let currentTab = 'tiers';
    let currentFilter = 'all';
    let selectedCategory = null;
    let hookAddress = '';
    let chainId = 1;

    async function loadGallery() {
      hookAddress = document.getElementById('hookAddress').value;
      chainId = parseInt(document.getElementById('chainSelect').value);

      if (!hookAddress || !ethers.isAddress(hookAddress)) {
        alert('Please enter a valid hook address');
        return;
      }

      const container = document.getElementById('galleryContainer');
      container.innerHTML = '<div class="loading"><div class="spinner"></div>Loading NFT collection...</div>';

      const chain = CHAINS[chainId];
      provider = new ethers.JsonRpcProvider(chain.rpc);
      hookContract = new ethers.Contract(hookAddress, HOOK_ABI, provider);

      try {
        // Get store address
        const storeAddr = await hookContract.STORE();
        storeContract = new ethers.Contract(storeAddr, STORE_ABI, provider);

        // Load all tiers
        allTiers = await storeContract.tiersOf(hookAddress, [], true, 0, 100);

        // Calculate stats
        let totalMinted = 0;
        let totalMaxSupply = 0;
        let floorPrice = BigInt(0);

        const categories = new Set();

        allTiers.forEach(tier => {
          const minted = Number(tier.initialSupply) - Number(tier.remainingSupply);
          totalMinted += minted;
          totalMaxSupply += Number(tier.initialSupply);

          if (tier.category) categories.add(Number(tier.category));

          if (tier.remainingSupply > 0) {
            if (floorPrice === BigInt(0) || BigInt(tier.price) < floorPrice) {
              floorPrice = BigInt(tier.price);
            }
          }
        });

        // Update stats
        document.getElementById('totalTiers').textContent = allTiers.length;
        document.getElementById('totalMinted').textContent = totalMinted.toLocaleString();
        document.getElementById('totalSupply').textContent = totalMaxSupply.toLocaleString();
        document.getElementById('floorPrice').textContent = floorPrice > 0
          ? ethers.formatEther(floorPrice) + ' ETH'
          : 'N/A';

        // Render category filter
        if (categories.size > 0) {
          let categoryHtml = '<div class="category-chip active" onclick="filterCategory(null)">All</div>';
          [...categories].sort((a, b) => a - b).forEach(cat => {
            categoryHtml += `<div class="category-chip" onclick="filterCategory(${cat})">Category ${cat}</div>`;
          });
          document.getElementById('categoryFilter').innerHTML = categoryHtml;
        }

        // Show UI elements
        document.getElementById('statsBar').style.display = 'grid';
        document.getElementById('tabsContainer').style.display = 'flex';
        document.getElementById('filterBar').style.display = 'flex';
        document.getElementById('walletSection').style.display = 'flex';

        renderTiers();

      } catch (error) {
        console.error(error);
        container.innerHTML = `<div class="empty-state">Error loading collection: ${error.message}</div>`;
      }
    }

    async function connectWallet() {
      if (!window.ethereum) {
        alert('Please install MetaMask or another web3 wallet');
        return;
      }

      try {
        const browserProvider = new ethers.BrowserProvider(window.ethereum);
        await browserProvider.send('eth_requestAccounts', []);

        // Switch to correct chain
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x' + chainId.toString(16) }]
          });
        } catch (e) {
          console.log('Chain switch failed', e);
        }

        signer = await browserProvider.getSigner();
        const address = await signer.getAddress();

        document.getElementById('walletStatus').textContent = 'Connected:';
        document.getElementById('walletAddress').textContent = address.slice(0, 6) + '...' + address.slice(-4);
        document.getElementById('connectBtn').textContent = 'Disconnect';
        document.getElementById('connectBtn').onclick = disconnectWallet;

        // Load owned NFTs
        await loadOwnedNFTs(address);

      } catch (error) {
        console.error(error);
        alert('Failed to connect wallet');
      }
    }

    function disconnectWallet() {
      signer = null;
      ownedNFTs = [];
      document.getElementById('walletStatus').textContent = 'Not connected';
      document.getElementById('walletAddress').textContent = '';
      document.getElementById('connectBtn').textContent = 'Connect Wallet';
      document.getElementById('connectBtn').onclick = connectWallet;

      if (currentTab === 'owned') {
        switchTab('tiers');
      } else {
        renderTiers();
      }
    }

    async function loadOwnedNFTs(ownerAddress) {
      try {
        const balance = await hookContract.balanceOf(ownerAddress);
        ownedNFTs = [];

        for (let i = 0; i < balance; i++) {
          const tokenId = await hookContract.tokenOfOwnerByIndex(ownerAddress, i);
          const tierId = await storeContract.tierIdOfToken(tokenId);
          const tier = allTiers.find(t => t.id.toString() === tierId.toString());

          let metadata = {};
          try {
            const uri = await hookContract.tokenURI(tokenId);
            if (uri) {
              const metadataUrl = uri.startsWith('ipfs://')
                ? `https://ipfs.io/ipfs/${uri.slice(7)}`
                : uri;
              const response = await fetch(metadataUrl);
              metadata = await response.json();
            }
          } catch (e) {
            console.log('Failed to load metadata for token', tokenId.toString());
          }

          ownedNFTs.push({
            tokenId: tokenId.toString(),
            tierId: tierId.toString(),
            tier,
            metadata
          });
        }

        if (currentTab === 'owned') {
          renderOwnedNFTs();
        } else {
          renderTiers();
        }

      } catch (error) {
        console.error('Failed to load owned NFTs:', error);
      }
    }

    function switchTab(tab) {
      currentTab = tab;
      document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
      document.querySelector(`.tab[data-tab="${tab}"]`).classList.add('active');

      if (tab === 'tiers') {
        document.getElementById('filterBar').style.display = 'flex';
        renderTiers();
      } else {
        document.getElementById('filterBar').style.display = 'none';
        renderOwnedNFTs();
      }
    }

    function filterTiers(filter) {
      currentFilter = filter;
      document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
      document.querySelector(`.filter-btn[data-filter="${filter}"]`).classList.add('active');
      renderTiers();
    }

    function filterCategory(category) {
      selectedCategory = category;
      document.querySelectorAll('.category-chip').forEach(c => c.classList.remove('active'));
      if (category === null) {
        document.querySelector('.category-chip').classList.add('active');
      } else {
        document.querySelectorAll('.category-chip').forEach(c => {
          if (c.textContent === `Category ${category}`) c.classList.add('active');
        });
      }
      renderTiers();
    }

    function renderTiers() {
      const container = document.getElementById('galleryContainer');

      let filteredTiers = [...allTiers];

      // Apply category filter
      if (selectedCategory !== null) {
        filteredTiers = filteredTiers.filter(t => Number(t.category) === selectedCategory);
      }

      // Apply availability filter
      if (currentFilter === 'available') {
        filteredTiers = filteredTiers.filter(t => t.remainingSupply > 0);
      } else if (currentFilter === 'sold-out') {
        filteredTiers = filteredTiers.filter(t => t.remainingSupply === 0n);
      }

      if (filteredTiers.length === 0) {
        container.innerHTML = '<div class="empty-state">No tiers match the current filter</div>';
        return;
      }

      let html = '<div class="gallery-grid">';

      filteredTiers.forEach(tier => {
        const minted = Number(tier.initialSupply) - Number(tier.remainingSupply);
        const soldOut = tier.remainingSupply === 0n;
        const price = ethers.formatEther(tier.price);

        // Check if user owns any from this tier
        const owned = ownedNFTs.filter(nft => nft.tierId === tier.id.toString());

        html += `
          <div class="nft-card" onclick="openTierModal(${tier.id})">
            <div class="nft-image">
              ${tier.resolvedUri
                ? `<img src="${resolveUri(tier.resolvedUri)}" alt="Tier ${tier.id}" onerror="this.style.display='none';this.parentElement.innerHTML='<div class=\\'placeholder\\'>NFT</div>'">`
                : '<div class="placeholder">NFT</div>'
              }
              <div class="tier-badge">Tier ${tier.id}</div>
              <div class="supply-badge ${soldOut ? 'sold-out' : ''}">${minted}/${tier.initialSupply}</div>
              ${owned.length > 0 ? `<div class="owned-badge">Owned: ${owned.length}</div>` : ''}
            </div>
            <div class="nft-info">
              <div class="nft-name">Tier ${tier.id}</div>
              <div class="nft-description">Category ${tier.category || 0}</div>
              <div class="nft-meta">
                <div class="nft-price">${price} ETH</div>
                ${tier.votingUnits > 0 ? `<div class="nft-votes">${tier.votingUnits} votes</div>` : ''}
              </div>
              <button class="mint-btn" ${soldOut ? 'disabled' : ''} onclick="event.stopPropagation(); mintTier(${tier.id}, '${tier.price}')">
                ${soldOut ? 'Sold Out' : 'Mint'}
              </button>
            </div>
          </div>
        `;
      });

      html += '</div>';
      container.innerHTML = html;
    }

    function renderOwnedNFTs() {
      const container = document.getElementById('galleryContainer');

      if (!signer) {
        container.innerHTML = '<div class="empty-state">Connect your wallet to view owned NFTs</div>';
        return;
      }

      if (ownedNFTs.length === 0) {
        container.innerHTML = '<div class="empty-state">You don\'t own any NFTs from this collection</div>';
        return;
      }

      let html = '<div class="gallery-grid">';

      ownedNFTs.forEach(nft => {
        const tier = nft.tier;
        const name = nft.metadata?.name || `Tier ${nft.tierId} #${nft.tokenId}`;
        const image = nft.metadata?.image;

        html += `
          <div class="nft-card" onclick="openNFTModal('${nft.tokenId}')">
            <div class="nft-image">
              ${image
                ? `<img src="${resolveUri(image)}" alt="${name}" onerror="this.style.display='none';this.parentElement.innerHTML='<div class=\\'placeholder\\'>NFT</div>'">`
                : '<div class="placeholder">NFT</div>'
              }
              <div class="tier-badge">Tier ${nft.tierId}</div>
            </div>
            <div class="nft-info">
              <div class="nft-name">${name}</div>
              <div class="nft-description">Token ID: ${nft.tokenId}</div>
              <div class="nft-meta">
                <div class="nft-price">${tier ? ethers.formatEther(tier.price) + ' ETH' : '-'}</div>
                ${tier?.votingUnits > 0 ? `<div class="nft-votes">${tier.votingUnits} votes</div>` : ''}
              </div>
            </div>
          </div>
        `;
      });

      html += '</div>';
      container.innerHTML = html;
    }

    async function openTierModal(tierId) {
      const tier = allTiers.find(t => t.id.toString() === tierId.toString());
      if (!tier) return;

      const minted = Number(tier.initialSupply) - Number(tier.remainingSupply);
      const soldOut = tier.remainingSupply === 0n;
      const price = ethers.formatEther(tier.price);

      document.getElementById('modalTitle').textContent = `Tier ${tierId}`;
      document.getElementById('modalTokenId').textContent = `Category ${tier.category || 0}`;
      document.getElementById('modalDescription').textContent = tier.resolvedUri
        ? 'Tier metadata loaded from IPFS'
        : 'No metadata available';

      document.getElementById('modalImage').innerHTML = tier.resolvedUri
        ? `<img src="${resolveUri(tier.resolvedUri)}" alt="Tier ${tierId}">`
        : '<div style="display:flex;align-items:center;justify-content:center;height:100%;color:#444;font-size:64px;">NFT</div>';

      document.getElementById('modalAttributes').innerHTML = `
        <div class="attribute">
          <div class="attribute-label">Price</div>
          <div class="attribute-value">${price} ETH</div>
        </div>
        <div class="attribute">
          <div class="attribute-label">Supply</div>
          <div class="attribute-value">${minted} / ${tier.initialSupply}</div>
        </div>
        <div class="attribute">
          <div class="attribute-label">Remaining</div>
          <div class="attribute-value">${tier.remainingSupply.toString()}</div>
        </div>
        <div class="attribute">
          <div class="attribute-label">Voting Units</div>
          <div class="attribute-value">${tier.votingUnits || 0}</div>
        </div>
        ${tier.reserveFrequency > 0 ? `
        <div class="attribute">
          <div class="attribute-label">Reserve Frequency</div>
          <div class="attribute-value">1 in ${tier.reserveFrequency}</div>
        </div>
        ` : ''}
      `;

      document.getElementById('modalActions').innerHTML = `
        <button class="action-btn primary" ${soldOut ? 'disabled' : ''} onclick="mintTier(${tierId}, '${tier.price}')">
          ${soldOut ? 'Sold Out' : `Mint for ${price} ETH`}
        </button>
      `;

      document.getElementById('nftModal').classList.add('visible');
    }

    async function openNFTModal(tokenId) {
      const nft = ownedNFTs.find(n => n.tokenId === tokenId);
      if (!nft) return;

      const name = nft.metadata?.name || `Tier ${nft.tierId} #${tokenId}`;
      const description = nft.metadata?.description || 'No description available';
      const image = nft.metadata?.image;

      document.getElementById('modalTitle').textContent = name;
      document.getElementById('modalTokenId').textContent = `Token #${tokenId}`;
      document.getElementById('modalDescription').textContent = description;

      document.getElementById('modalImage').innerHTML = image
        ? `<img src="${resolveUri(image)}" alt="${name}">`
        : '<div style="display:flex;align-items:center;justify-content:center;height:100%;color:#444;font-size:64px;">NFT</div>';

      // Render attributes from metadata
      let attributesHtml = `
        <div class="attribute">
          <div class="attribute-label">Tier</div>
          <div class="attribute-value">${nft.tierId}</div>
        </div>
        <div class="attribute">
          <div class="attribute-label">Token ID</div>
          <div class="attribute-value">${tokenId}</div>
        </div>
      `;

      if (nft.metadata?.attributes) {
        nft.metadata.attributes.forEach(attr => {
          attributesHtml += `
            <div class="attribute">
              <div class="attribute-label">${attr.trait_type}</div>
              <div class="attribute-value">${attr.value}</div>
            </div>
          `;
        });
      }

      document.getElementById('modalAttributes').innerHTML = attributesHtml;

      document.getElementById('modalActions').innerHTML = `
        <button class="action-btn secondary" onclick="transferNFT('${tokenId}')">Transfer</button>
        <button class="action-btn secondary" onclick="cashOutNFT('${tokenId}')">Cash Out</button>
      `;

      document.getElementById('nftModal').classList.add('visible');
    }

    function closeModal() {
      document.getElementById('nftModal').classList.remove('visible');
    }

    async function mintTier(tierId, price) {
      if (!signer) {
        alert('Please connect your wallet first');
        return;
      }

      try {
        // Get project ID and terminal
        const projectId = await hookContract.PROJECT_ID();

        // For simplicity, we'll show the user needs to use the terminal to mint
        // In a full implementation, we'd call the terminal's pay() function

        alert(`To mint from Tier ${tierId}:\n\n1. Go to the Juicebox app\n2. Pay ${ethers.formatEther(price)} ETH to Project ${projectId}\n3. The NFT will be minted to your wallet\n\nAlternatively, use the Contract Explorer to call pay() directly.`);

      } catch (error) {
        console.error(error);
        alert('Minting failed: ' + error.message);
      }
    }

    async function transferNFT(tokenId) {
      if (!signer) {
        alert('Please connect your wallet first');
        return;
      }

      const recipient = prompt('Enter recipient address:');
      if (!recipient || !ethers.isAddress(recipient)) {
        alert('Invalid address');
        return;
      }

      try {
        const hookWithSigner = hookContract.connect(signer);
        const address = await signer.getAddress();

        const tx = await hookWithSigner.transferFrom(address, recipient, tokenId);
        alert('Transaction submitted: ' + tx.hash);

        await tx.wait();
        alert('Transfer successful!');

        // Reload owned NFTs
        await loadOwnedNFTs(address);
        closeModal();

      } catch (error) {
        console.error(error);
        alert('Transfer failed: ' + error.message);
      }
    }

    async function cashOutNFT(tokenId) {
      alert(`To cash out NFT #${tokenId}:\n\n1. Go to the Juicebox app\n2. Use the cash out function with this token ID\n3. The NFT will be burned and you'll receive your share of the treasury\n\nAlternatively, use the Contract Explorer to call cashOutTokensOf() directly.`);
    }

    function resolveUri(uri) {
      if (!uri) return '';
      if (uri.startsWith('ipfs://')) {
        return `https://ipfs.io/ipfs/${uri.slice(7)}`;
      }
      if (uri.startsWith('data:')) {
        return uri;
      }
      return uri;
    }

    // Close modal on escape or outside click
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') closeModal();
    });

    document.getElementById('nftModal').addEventListener('click', (e) => {
      if (e.target.id === 'nftModal') closeModal();
    });
  </script>
</body>
</html>
```

## Key Features

### Tier Browsing
- Grid layout with tier cards
- Supply tracking (minted/total)
- Price display in ETH
- Category filtering
- Availability filtering

### Owned NFTs View
- Wallet connection
- Display owned NFTs with metadata
- Transfer functionality
- Cash out guidance

### Collection Stats
- Total tiers
- Total minted
- Max supply
- Floor price

### NFT Details Modal
- Full metadata display
- Attribute listing
- Action buttons (mint/transfer/cash out)

## Data Sources

The gallery uses on-chain data via:
- `JB721TiersHook` - NFT contract
- `JB721TiersHookStore` - Tier data storage
- Token metadata from IPFS

## Customization Points

1. **Image handling**: Modify `resolveUri()` for different IPFS gateways
2. **Metadata display**: Extend attributes rendering
3. **Minting flow**: Integrate directly with terminal
4. **Styling**: Customize card layouts and colors

## Integration Notes

- Works with any V5 721 Hook deployment
- Supports all major chains
- Wallet connection for owned NFT view
- IPFS metadata resolution included
