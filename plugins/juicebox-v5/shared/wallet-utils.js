/**
 * Juicebox V5 UI Skills - Wallet Utilities
 * Common wallet connection and chain switching helpers
 * Requires: viem (https://viem.sh)
 *
 * Usage in HTML:
 * <script type="module">
 *   import { createPublicClient, http } from 'https://esm.sh/viem'
 *   import { mainnet, optimism, base, arbitrum, sepolia } from 'https://esm.sh/viem/chains'
 * </script>
 */

/**
 * Chain configurations for viem
 */
const CHAIN_CONFIGS = {
  1: {
    id: 1,
    name: 'Ethereum',
    network: 'mainnet',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: {
      default: { http: ['https://eth.llamarpc.com'] },
      public: { http: ['https://eth.llamarpc.com'] }
    },
    blockExplorers: {
      default: { name: 'Etherscan', url: 'https://etherscan.io' }
    }
  },
  10: {
    id: 10,
    name: 'Optimism',
    network: 'optimism',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: {
      default: { http: ['https://mainnet.optimism.io'] },
      public: { http: ['https://mainnet.optimism.io'] }
    },
    blockExplorers: {
      default: { name: 'Optimistic Etherscan', url: 'https://optimistic.etherscan.io' }
    }
  },
  8453: {
    id: 8453,
    name: 'Base',
    network: 'base',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: {
      default: { http: ['https://mainnet.base.org'] },
      public: { http: ['https://mainnet.base.org'] }
    },
    blockExplorers: {
      default: { name: 'Basescan', url: 'https://basescan.org' }
    }
  },
  42161: {
    id: 42161,
    name: 'Arbitrum One',
    network: 'arbitrum',
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: {
      default: { http: ['https://arb1.arbitrum.io/rpc'] },
      public: { http: ['https://arb1.arbitrum.io/rpc'] }
    },
    blockExplorers: {
      default: { name: 'Arbiscan', url: 'https://arbiscan.io' }
    }
  },
  11155111: {
    id: 11155111,
    name: 'Sepolia',
    network: 'sepolia',
    nativeCurrency: { name: 'Sepolia Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: {
      default: { http: ['https://rpc.sepolia.org'] },
      public: { http: ['https://rpc.sepolia.org'] }
    },
    blockExplorers: {
      default: { name: 'Sepolia Etherscan', url: 'https://sepolia.etherscan.io' }
    }
  }
};

/**
 * Chain display info (simplified)
 */
const CHAINS = {
  1: { name: 'Ethereum', symbol: 'ETH', explorer: 'https://etherscan.io' },
  10: { name: 'Optimism', symbol: 'ETH', explorer: 'https://optimistic.etherscan.io' },
  8453: { name: 'Base', symbol: 'ETH', explorer: 'https://basescan.org' },
  42161: { name: 'Arbitrum', symbol: 'ETH', explorer: 'https://arbiscan.io' },
  11155111: { name: 'Sepolia', symbol: 'ETH', explorer: 'https://sepolia.etherscan.io' }
};

/**
 * JBWallet - Wallet connection manager using viem + window.ethereum
 * For React apps, use wagmi instead: https://wagmi.sh
 */
class JBWallet {
  constructor() {
    this.client = null;
    this.walletClient = null;
    this.address = null;
    this.chainId = null;
    this.onAccountChange = null;
    this.onChainChange = null;
  }

  /**
   * Check if a wallet is available
   */
  isAvailable() {
    return typeof window !== 'undefined' && window.ethereum;
  }

  /**
   * Connect to wallet and optionally switch to target chain
   * @param {number} targetChainId - Optional chain ID to switch to
   * @param {object} viem - Pass viem module for ES module support
   * @returns {Promise<{address: string, chainId: number}>}
   */
  async connect(targetChainId = 1, viem = null) {
    if (!this.isAvailable()) {
      throw new Error('No wallet found. Please install MetaMask or another Web3 wallet.');
    }

    // Dynamic import if viem not passed
    if (!viem) {
      viem = await import('https://esm.sh/viem');
    }

    const { createWalletClient, createPublicClient, custom, http } = viem;

    // Request accounts
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    this.address = accounts[0];

    // Switch chain if needed
    if (targetChainId) {
      await this.switchChain(targetChainId);
    }

    // Get current chain
    const chainIdHex = await window.ethereum.request({ method: 'eth_chainId' });
    this.chainId = parseInt(chainIdHex, 16);

    // Create clients
    const chain = CHAIN_CONFIGS[this.chainId] || CHAIN_CONFIGS[1];

    this.walletClient = createWalletClient({
      account: this.address,
      chain,
      transport: custom(window.ethereum)
    });

    this.client = createPublicClient({
      chain,
      transport: http()
    });

    // Set up listeners
    this._setupListeners();

    return {
      address: this.address,
      chainId: this.chainId
    };
  }

  /**
   * Switch to a different chain
   * @param {number} chainId - Target chain ID
   */
  async switchChain(chainId) {
    const hexChainId = '0x' + chainId.toString(16);

    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: hexChainId }]
      });
    } catch (error) {
      // Chain not added, try to add it
      if (error.code === 4902) {
        await this.addChain(chainId);
      } else {
        throw error;
      }
    }
    this.chainId = chainId;
  }

  /**
   * Add a chain to the wallet
   * @param {number} chainId - Chain ID to add
   */
  async addChain(chainId) {
    const chain = CHAIN_CONFIGS[chainId];
    if (!chain) {
      throw new Error(`Unknown chain ID: ${chainId}`);
    }

    await window.ethereum.request({
      method: 'wallet_addEthereumChain',
      params: [{
        chainId: '0x' + chainId.toString(16),
        chainName: chain.name,
        nativeCurrency: chain.nativeCurrency,
        rpcUrls: chain.rpcUrls.default.http,
        blockExplorerUrls: [chain.blockExplorers.default.url]
      }]
    });
  }

  /**
   * Disconnect wallet (clear local state)
   */
  disconnect() {
    this.client = null;
    this.walletClient = null;
    this.address = null;
    this.chainId = null;
    this._removeListeners();
  }

  /**
   * Check if wallet is connected
   */
  isConnected() {
    return this.address !== null;
  }

  /**
   * Format address for display
   */
  formatAddress(address = this.address) {
    if (!address) return '';
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  }

  _setupListeners() {
    if (!window.ethereum) return;

    window.ethereum.on('accountsChanged', (accounts) => {
      if (accounts.length === 0) {
        this.disconnect();
      } else {
        this.address = accounts[0];
      }
      if (this.onAccountChange) this.onAccountChange(accounts);
    });

    window.ethereum.on('chainChanged', (chainId) => {
      this.chainId = parseInt(chainId, 16);
      if (this.onChainChange) this.onChainChange(this.chainId);
    });
  }

  _removeListeners() {
    if (!window.ethereum) return;
    window.ethereum.removeAllListeners?.('accountsChanged');
    window.ethereum.removeAllListeners?.('chainChanged');
  }
}

/**
 * Get explorer URL for a transaction
 */
function getTxUrl(chainId, txHash) {
  const chain = CHAINS[chainId];
  if (!chain) return null;
  return `${chain.explorer}/tx/${txHash}`;
}

/**
 * Get explorer URL for an address
 */
function getAddressUrl(chainId, address) {
  const chain = CHAINS[chainId];
  if (!chain) return null;
  return `${chain.explorer}/address/${address}`;
}

/**
 * Formatting utilities
 */
function truncateAddress(address) {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function formatEth(wei) {
  if (!wei) return '0';
  // Handle both bigint and number
  const value = typeof wei === 'bigint' ? wei : BigInt(wei);
  return (Number(value) / 1e18).toFixed(4);
}

function formatNumber(n) {
  if (!n) return '0';
  return Number(n).toLocaleString();
}

function formatTimeAgo(timestamp) {
  if (!timestamp) return '';
  const seconds = Math.floor(Date.now() / 1000 - Number(timestamp));

  if (seconds < 60) return `${seconds}s ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

function formatDate(timestamp) {
  if (!timestamp) return '';
  return new Date(Number(timestamp) * 1000).toLocaleString();
}

/**
 * Create a read-only public client for a chain
 * @param {number} chainId - Chain ID
 * @param {object} viem - Pass viem module for ES module support
 */
async function createReadClient(chainId, viem = null) {
  if (!viem) {
    viem = await import('https://esm.sh/viem');
  }

  const { createPublicClient, http } = viem;
  const chain = CHAIN_CONFIGS[chainId];

  if (!chain) {
    throw new Error(`Unknown chain ID: ${chainId}`);
  }

  return createPublicClient({
    chain,
    transport: http()
  });
}

/**
 * Load an ABI by contract name
 * @param {string} contractName - Contract name (e.g., 'JBController', 'REVDeployer')
 * @returns {Promise<Array>} ABI array
 */
async function loadABI(contractName) {
  const paths = [
    `/shared/abis/${contractName}.json`,
    `./abis/${contractName}.json`,
    new URL(`./abis/${contractName}.json`, import.meta.url).href
  ];

  for (const path of paths) {
    try {
      const res = await fetch(path);
      if (res.ok) return res.json();
    } catch (e) {
      continue;
    }
  }
  throw new Error(`ABI not found: ${contractName}`);
}

/**
 * Get contract address from chain config
 * @param {number} chainId - Chain ID
 * @param {string} contractName - Contract name
 * @param {boolean} useV5 - Use V5.0 addresses (for revnets), default false (V5.1)
 * @returns {string|null} Contract address or null if not found
 */
function getContractAddress(chainId, contractName, useV5 = false) {
  const config = _getInlineConfig();
  const chain = config.chains[chainId];
  if (!chain) return null;

  if (useV5 && chain.contractsV5?.[contractName]) {
    return chain.contractsV5[contractName];
  }
  return chain.contracts?.[contractName] || null;
}

/**
 * Internal: Get inline config (synchronous)
 */
function _getInlineConfig() {
  return {
    chains: {
      1: {
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf',
          JBTokens: '0x4d0edd347fb1fa21589c1e109b3474924be87636',
          JBPermissions: '0x04fd6913d6c32d8c216e153a43c04b1857a7793d',
          JB721TiersHookDeployer: '0x792bdd4dd1e52fcf8fb3e80278a2b4e4396d2732'
        },
        contractsV5: {
          JBController: '0x27da30646502e2f642be5281322ae8c394f7668a',
          JBMultiTerminal: '0x2db6d704058e552defe415753465df8df0361846',
          REVDeployer: '0x2ca27bde7e7d33e353b44c27acfcf6c78dde251d'
        }
      },
      10: {
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf'
        }
      },
      8453: {
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf'
        }
      },
      42161: {
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf'
        }
      }
    }
  };
}

/**
 * Load chain configuration from shared config
 */
async function loadChainConfig() {
  try {
    const res = await fetch(new URL('./chain-config.json', import.meta.url));
    if (res.ok) return res.json();
  } catch (e) {
    // Try relative path
    try {
      const res = await fetch('/shared/chain-config.json');
      if (res.ok) return res.json();
    } catch (e2) {
      // Fall through to inline config
    }
  }

  // Inline fallback with V5.1 addresses
  return {
    _version: '5.1',
    chains: {
      1: {
        name: 'Ethereum',
        rpc: 'https://eth.llamarpc.com',
        explorer: 'https://etherscan.io',
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf',
          JBTokens: '0x4d0edd347fb1fa21589c1e109b3474924be87636',
          JBPermissions: '0x04fd6913d6c32d8c216e153a43c04b1857a7793d',
          JB721TiersHookDeployer: '0x792bdd4dd1e52fcf8fb3e80278a2b4e4396d2732'
        },
        contractsV5: {
          JBController: '0x27da30646502e2f642be5281322ae8c394f7668a',
          JBMultiTerminal: '0x2db6d704058e552defe415753465df8df0361846',
          REVDeployer: '0x2ca27bde7e7d33e353b44c27acfcf6c78dde251d'
        }
      },
      10: {
        name: 'Optimism',
        rpc: 'https://mainnet.optimism.io',
        explorer: 'https://optimistic.etherscan.io',
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf'
        }
      },
      8453: {
        name: 'Base',
        rpc: 'https://mainnet.base.org',
        explorer: 'https://basescan.org',
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf'
        }
      },
      42161: {
        name: 'Arbitrum',
        rpc: 'https://arb1.arbitrum.io/rpc',
        explorer: 'https://arbiscan.io',
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf'
        }
      },
      11155111: {
        name: 'Sepolia',
        rpc: 'https://rpc.sepolia.org',
        explorer: 'https://sepolia.etherscan.io',
        contracts: {
          JBController: '0xf3cc99b11bd73a2e3b8815fb85fe0381b29987e1',
          JBMultiTerminal: '0x52869db3d61dde1e391967f2ce5039ad0ecd371c',
          JBProjects: '0x885f707efa18d2cb12f05a3a8eba6b4b26c8c1d4',
          JBDirectory: '0x0061e516886a0540f63157f112c0588ee0651dcf'
        }
      }
    }
  };
}

// Export for ES modules
export {
  JBWallet,
  CHAINS,
  CHAIN_CONFIGS,
  getTxUrl,
  getAddressUrl,
  truncateAddress,
  formatEth,
  formatNumber,
  formatTimeAgo,
  formatDate,
  createReadClient,
  loadChainConfig,
  loadABI,
  getContractAddress
};

// Also expose on window for script tag usage
if (typeof window !== 'undefined') {
  window.JBWalletUtils = {
    JBWallet,
    CHAINS,
    CHAIN_CONFIGS,
    getTxUrl,
    getAddressUrl,
    truncateAddress,
    formatEth,
    formatNumber,
    formatTimeAgo,
    formatDate,
    createReadClient,
    loadChainConfig,
    loadABI,
    getContractAddress
  };
}
