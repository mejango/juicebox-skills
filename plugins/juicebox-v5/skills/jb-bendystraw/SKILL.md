---
name: jb-bendystraw
description: Bendystraw GraphQL API reference for querying Juicebox project data across all chains. Get project stats, payments, token holders, and cross-chain aggregations.
---

# Bendystraw: Cross-Chain Juicebox Data API

Bendystraw is a GraphQL indexer for Juicebox V5 events across all supported chains. It aggregates data and provides unified cross-chain queries for projects, payments, token holders, and NFTs.

## API Base URLs

```
Production: https://bendystraw.xyz/{API_KEY}/graphql
Testnet: https://testnet.bendystraw.xyz/{API_KEY}/graphql
Playground: https://bendystraw.xyz (browser-based GraphQL explorer)
```

## Authentication

**API key required.** Contact [@peripheralist](https://x.com/peripheralist) on Twitter/X to get one.

```javascript
const response = await fetch(`https://bendystraw.xyz/${API_KEY}/graphql`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: '...',
    variables: { ... }
  })
});
```

**Important:** Never expose API keys in frontend code. Use a server-side proxy.

---

## Supported Chains

| Chain | Chain ID | Network |
|-------|----------|---------|
| Ethereum | 1 | Mainnet |
| Optimism | 10 | Mainnet |
| Base | 8453 | Mainnet |
| Arbitrum | 42161 | Mainnet |
| Sepolia | 11155111 | Testnet |

---

## GraphQL Schema Reference

### Project Entity

```graphql
type Project {
  # Identifiers
  id: String!                    # "{chainId}-{projectId}"
  projectId: Int!
  chainId: Int!

  # Metadata
  handle: String
  name: String
  description: String
  logoUri: String
  infoUri: String
  owner: String!
  deployer: String

  # Financial
  balance: String!               # Current balance (wei)
  volume: String!                # Total received (wei)
  volumeUsd: String              # USD equivalent
  redeemVolume: String!          # Total redeemed (wei)
  redeemVolumeUsd: String

  # Tokens
  tokenSupply: String!           # Total token supply
  token: String                  # ERC20 address if deployed
  tokenSymbol: String

  # Activity counts
  paymentsCount: Int!
  redeemCount: Int!
  contributorsCount: Int!
  nftsMintedCount: Int!

  # Trending (7-day window)
  trendingScore: Float
  trendingVolume: String
  trendingPaymentsCount: Int

  # Omnichain
  suckerGroupId: String          # Linked cross-chain group

  # Timestamps
  createdAt: Int!
  deployedAt: Int
}
```

### SuckerGroup Entity (Omnichain Projects)

```graphql
type SuckerGroup {
  id: String!                    # Unique group identifier
  projects: [String!]!           # Array of project IDs

  # Aggregated totals across all chains
  volume: String!
  volumeUsd: String
  balance: String!
  tokenSupply: String!
  paymentsCount: Int!
  contributorsCount: Int!

  # Related projects (expanded)
  projects_rel: [Project!]!
}
```

### Participant Entity (Token Holders)

```graphql
type Participant {
  id: String!                    # "{chainId}-{projectId}-{address}"
  address: String!
  projectId: Int!
  chainId: Int!

  # Balances
  balance: String!               # Total balance (credits + ERC20)
  creditBalance: String!         # Unclaimed credits
  erc20Balance: String!          # Claimed ERC20 tokens

  # Activity
  volume: String!                # Total contributed
  volumeUsd: String
  paymentsCount: Int!
  redeemCount: Int!

  # Timestamps
  lastPaidAt: Int
  firstPaidAt: Int
}
```

### PayEvent Entity

```graphql
type PayEvent {
  id: String!
  projectId: Int!
  chainId: Int!
  rulesetId: Int!

  # Transaction
  txHash: String!
  timestamp: Int!
  logIndex: Int!
  blockNumber: Int!

  # Payment details
  from: String!                  # Payer address
  beneficiary: String!           # Token recipient
  amount: String!                # Payment amount (wei)
  amountUsd: String
  distributionFromPayAmount: String!

  # Tokens
  newlyIssuedTokenCount: String!
  beneficiaryTokenCount: String!

  # Metadata
  memo: String
  feeFromPayAmount: String
}
```

### CashOutEvent Entity

```graphql
type CashOutEvent {
  id: String!
  projectId: Int!
  chainId: Int!
  rulesetId: Int!

  # Transaction
  txHash: String!
  timestamp: Int!

  # Redemption details
  holder: String!
  beneficiary: String!
  cashOutCount: String!          # Tokens burned
  reclaimAmount: String!         # ETH received
  reclaimAmountUsd: String
  metadata: String
}
```

### NFT Entity

```graphql
type NFT {
  id: String!
  tokenId: Int!
  projectId: Int!
  chainId: Int!
  hook: String!                  # 721 hook address

  # Tier
  tierId: Int!
  tierCategory: Int

  # Ownership
  owner: String!
  createdAt: Int!

  # Metadata
  tokenUri: String
}
```

---

## Query Examples

### Get Single Project

```graphql
query GetProject($projectId: Int!, $chainId: Int!) {
  project(projectId: $projectId, chainId: $chainId) {
    id
    name
    handle
    owner
    balance
    volume
    volumeUsd
    tokenSupply
    paymentsCount
    contributorsCount
    suckerGroupId
  }
}
```

### Get Participant (Token Holder)

```graphql
query GetParticipant($projectId: Int!, $chainId: Int!, $address: String!) {
  participant(projectId: $projectId, chainId: $chainId, address: $address) {
    balance
    creditBalance
    erc20Balance
    volume
    volumeUsd
    paymentsCount
  }
}
```

### Get Sucker Group (Omnichain Totals)

```graphql
query GetSuckerGroup($id: String!) {
  suckerGroup(id: $id) {
    id
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
    }
  }
}
```

### List Projects

```graphql
query ListProjects($chainId: Int, $limit: Int!, $offset: Int!) {
  projects(
    where: { chainId: $chainId }
    orderBy: "volume"
    orderDirection: "desc"
    limit: $limit
    offset: $offset
  ) {
    items {
      projectId
      chainId
      name
      handle
      volume
      balance
      paymentsCount
    }
    totalCount
  }
}
```

### List Recent Payments

```graphql
query ListPayments($projectId: Int!, $chainId: Int!, $limit: Int!) {
  payEvents(
    where: { projectId: $projectId, chainId: $chainId }
    orderBy: "timestamp"
    orderDirection: "desc"
    limit: $limit
  ) {
    items {
      timestamp
      txHash
      from
      beneficiary
      amount
      amountUsd
      memo
      newlyIssuedTokenCount
    }
  }
}
```

### List Top Token Holders

```graphql
query ListParticipants($projectId: Int!, $chainId: Int!, $limit: Int!) {
  participants(
    where: { projectId: $projectId, chainId: $chainId }
    orderBy: "balance"
    orderDirection: "desc"
    limit: $limit
  ) {
    items {
      address
      balance
      creditBalance
      erc20Balance
      volume
      paymentsCount
    }
    totalCount
  }
}
```

### Get Trending Projects

```graphql
query TrendingProjects($limit: Int!) {
  projects(
    orderBy: "trendingScore"
    orderDirection: "desc"
    limit: $limit
  ) {
    items {
      projectId
      chainId
      name
      handle
      trendingScore
      trendingVolume
      trendingPaymentsCount
    }
  }
}
```

### List Cash Out Events

```graphql
query ListCashOuts($projectId: Int!, $chainId: Int!, $limit: Int!) {
  cashOutEvents(
    where: { projectId: $projectId, chainId: $chainId }
    orderBy: "timestamp"
    orderDirection: "desc"
    limit: $limit
  ) {
    items {
      timestamp
      txHash
      holder
      beneficiary
      cashOutCount
      reclaimAmount
      reclaimAmountUsd
    }
  }
}
```

### List NFTs for Project

```graphql
query ListNFTs($projectId: Int!, $chainId: Int!, $limit: Int!) {
  nfts(
    where: { projectId: $projectId, chainId: $chainId }
    orderBy: "createdAt"
    orderDirection: "desc"
    limit: $limit
  ) {
    items {
      tokenId
      tierId
      tierCategory
      owner
      createdAt
      tokenUri
    }
  }
}
```

---

## Filtering

The `where` clause supports these operators:

```graphql
where: {
  # Exact match
  projectId: 1
  chainId: 1

  # Multiple values (OR)
  chainId_in: [1, 10, 8453]

  # Comparison operators
  balance_gt: "1000000000000000000"
  balance_gte: "1000000000000000000"
  balance_lt: "100000000000000000000"
  balance_lte: "100000000000000000000"
  timestamp_gte: 1704067200

  # Text search
  name_contains: "dao"
  handle_starts_with: "jb"
}
```

---

## Sorting

```graphql
orderBy: "volume"           # Field to sort by
orderDirection: "desc"      # "asc" or "desc"
```

**Sortable Fields by Entity:**

| Entity | Sortable Fields |
|--------|-----------------|
| Project | `volume`, `balance`, `tokenSupply`, `paymentsCount`, `createdAt`, `trendingScore` |
| Participant | `balance`, `volume`, `paymentsCount` |
| PayEvent | `timestamp`, `amount` |
| CashOutEvent | `timestamp`, `reclaimAmount` |
| NFT | `createdAt`, `tokenId` |

---

## Pagination

All list queries support pagination:

```graphql
query PaginatedPayments(
  $projectId: Int!,
  $chainId: Int!,
  $limit: Int!,
  $offset: Int!
) {
  payEvents(
    where: { projectId: $projectId, chainId: $chainId }
    limit: $limit
    offset: $offset
  ) {
    items { ... }
    totalCount
  }
}
```

**Parameters:**
- `limit`: Max items to return (default: 100, max: 1000)
- `offset`: Number of items to skip

---

## Special Endpoints

### Participant Snapshots

Get historical participant balances at a specific timestamp. Useful for governance snapshots and airdrops.

```
POST https://bendystraw.xyz/{API_KEY}/participants
```

**Request:**
```json
{
  "suckerGroupId": "0x...",
  "timestamp": 1704067200
}
```

**Response:**
```json
{
  "participants": [
    {
      "address": "0x...",
      "balance": "1000000000000000000000",
      "chains": {
        "1": "600000000000000000000",
        "10": "400000000000000000000"
      }
    }
  ]
}
```

---

## Complete JavaScript Example

```javascript
const BENDYSTRAW_URL = 'https://bendystraw.xyz';
const API_KEY = process.env.BENDYSTRAW_API_KEY;

/**
 * Execute GraphQL query
 */
async function query(graphql, variables = {}) {
  const response = await fetch(`${BENDYSTRAW_URL}/${API_KEY}/graphql`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: graphql, variables })
  });

  const result = await response.json();

  if (result.errors) {
    throw new Error(result.errors[0].message);
  }

  return result.data;
}

/**
 * Get project stats
 */
async function getProject(projectId, chainId) {
  const data = await query(`
    query($projectId: Int!, $chainId: Int!) {
      project(projectId: $projectId, chainId: $chainId) {
        name
        handle
        owner
        balance
        volume
        volumeUsd
        tokenSupply
        paymentsCount
        contributorsCount
        suckerGroupId
      }
    }
  `, { projectId, chainId });

  return data.project;
}

/**
 * Get omnichain totals for sucker group
 */
async function getOmnichainStats(suckerGroupId) {
  const data = await query(`
    query($id: String!) {
      suckerGroup(id: $id) {
        volume
        volumeUsd
        balance
        tokenSupply
        contributorsCount
        projects_rel {
          chainId
          name
          balance
          volume
        }
      }
    }
  `, { id: suckerGroupId });

  return data.suckerGroup;
}

/**
 * Get recent payments
 */
async function getRecentPayments(projectId, chainId, limit = 20) {
  const data = await query(`
    query($projectId: Int!, $chainId: Int!, $limit: Int!) {
      payEvents(
        where: { projectId: $projectId, chainId: $chainId }
        orderBy: "timestamp"
        orderDirection: "desc"
        limit: $limit
      ) {
        items {
          timestamp
          from
          beneficiary
          amount
          amountUsd
          memo
          newlyIssuedTokenCount
        }
      }
    }
  `, { projectId, chainId, limit });

  return data.payEvents.items;
}

/**
 * Get top token holders
 */
async function getTopHolders(projectId, chainId, limit = 100) {
  const data = await query(`
    query($projectId: Int!, $chainId: Int!, $limit: Int!) {
      participants(
        where: { projectId: $projectId, chainId: $chainId }
        orderBy: "balance"
        orderDirection: "desc"
        limit: $limit
      ) {
        items {
          address
          balance
          creditBalance
          erc20Balance
          volume
        }
        totalCount
      }
    }
  `, { projectId, chainId, limit });

  return {
    holders: data.participants.items,
    total: data.participants.totalCount
  };
}

/**
 * Get participant balance
 */
async function getParticipant(projectId, chainId, address) {
  const data = await query(`
    query($projectId: Int!, $chainId: Int!, $address: String!) {
      participant(projectId: $projectId, chainId: $chainId, address: $address) {
        balance
        creditBalance
        erc20Balance
        volume
        volumeUsd
        paymentsCount
      }
    }
  `, { projectId, chainId, address });

  return data.participant;
}

/**
 * Get trending projects
 */
async function getTrendingProjects(chainId = null, limit = 10) {
  const where = chainId ? { chainId } : {};

  const data = await query(`
    query($where: ProjectWhereInput, $limit: Int!) {
      projects(
        where: $where
        orderBy: "trendingScore"
        orderDirection: "desc"
        limit: $limit
      ) {
        items {
          projectId
          chainId
          name
          handle
          trendingScore
          trendingVolume
          trendingPaymentsCount
        }
      }
    }
  `, { where, limit });

  return data.projects.items;
}

/**
 * Get historical snapshot for governance
 */
async function getSnapshot(suckerGroupId, timestamp) {
  const response = await fetch(`${BENDYSTRAW_URL}/${API_KEY}/participants`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ suckerGroupId, timestamp })
  });

  return await response.json();
}

// Example usage
async function main() {
  // Get project on Ethereum mainnet
  const project = await getProject(1, 1);
  console.log(`${project.name}: ${project.balance} wei balance`);

  // If omnichain, get aggregated stats
  if (project.suckerGroupId) {
    const omni = await getOmnichainStats(project.suckerGroupId);
    console.log(`Omnichain total: ${omni.volume} wei volume across ${omni.projects_rel.length} chains`);
  }

  // Get recent activity
  const payments = await getRecentPayments(1, 1, 5);
  console.log(`Last ${payments.length} payments:`);
  payments.forEach(p => {
    console.log(`  ${p.from.slice(0,8)}... paid ${p.amount} wei`);
  });

  // Get top holders
  const { holders, total } = await getTopHolders(1, 1, 10);
  console.log(`Top 10 of ${total} holders:`);
  holders.forEach((h, i) => {
    console.log(`  ${i + 1}. ${h.address.slice(0,8)}... - ${h.balance} tokens`);
  });
}

main().catch(console.error);
```

---

## BendystrawClient Class

```javascript
class BendystrawClient {
  constructor(apiKey, isTestnet = false) {
    this.baseUrl = isTestnet
      ? 'https://testnet.bendystraw.xyz'
      : 'https://bendystraw.xyz';
    this.apiKey = apiKey;
  }

  async query(graphql, variables = {}) {
    const response = await fetch(`${this.baseUrl}/${this.apiKey}/graphql`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: graphql, variables })
    });

    if (!response.ok) {
      throw new Error(`Bendystraw request failed: ${response.statusText}`);
    }

    const result = await response.json();
    if (result.errors) {
      throw new Error(result.errors[0].message);
    }

    return result.data;
  }

  // Convenience methods
  async getProject(projectId, chainId) { ... }
  async getSuckerGroup(id) { ... }
  async getPayments(projectId, chainId, limit) { ... }
  async getParticipants(projectId, chainId, limit) { ... }
  async getSnapshot(suckerGroupId, timestamp) { ... }
}
```

---

## Server-Side Proxy

Since the API key must be kept secret, use a server-side proxy:

### Next.js API Route

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

  const data = await response.json();
  res.json(data);
}
```

### Express Middleware

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

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `Unauthorized` | Invalid API key | Verify API key is correct |
| `Rate limited` | Too many requests | Add backoff/retry logic |
| `Invalid query` | GraphQL syntax error | Check query structure |
| `Not found` | Entity doesn't exist | Verify projectId/chainId |
| `Timeout` | Query too complex | Reduce limit, add filters |

---

## Best Practices

1. **Use server-side proxy** - Never expose API key in frontend code
2. **Cache responses** - Data updates every ~1 minute, cache accordingly
3. **Query only needed fields** - Reduces payload size and latency
4. **Use pagination** - Don't fetch thousands of records at once
5. **Handle nulls** - Fields like `volumeUsd`, `handle` may be null
6. **Consider freshness** - Indexer may lag 1-2 blocks behind chain
7. **Use filters** - Narrow queries by chainId, projectId when possible

---

## Use Cases

- **Project dashboards** - Display stats, activity, holders
- **Governance snapshots** - Get token balances at specific timestamps
- **Analytics** - Track trends, volumes, contributor growth
- **Portfolio tracking** - Show user's positions across projects
- **Omnichain aggregation** - Unified view of cross-chain projects
- **Airdrops** - Generate recipient lists from holder data

---

## Related Skills

- `/jb-relayr` - Execute multi-chain transactions
- `/jb-omnichain-ui` - Build UIs with Bendystraw data
- `/jb-query` - Direct on-chain queries via cast/ethers
