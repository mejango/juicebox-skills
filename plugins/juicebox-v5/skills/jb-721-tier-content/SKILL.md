---
name: jb-721-tier-content
description: |
  Juicebox V5 721 tier content patterns: IPFS-based static content vs on-chain resolver content.
  Use when: (1) building NFT tier displays for Juicebox projects, (2) deciding between encodedIPFSUri
  and tokenUriResolver for tier content, (3) implementing custom on-chain SVG resolvers like Banny,
  (4) debugging tier metadata not loading, (5) understanding the tiersOf() and tokenUriOf() flow.
---

# 721 Tier Content Patterns

Juicebox V5 721 hooks support two content resolution mechanisms for NFT tier metadata:

1. **Static IPFS Content** - Most projects use `encodedIPFSUri` to reference pinned IPFS files
2. **Dynamic On-Chain Content** - Projects like Banny use a custom `tokenUriResolver` for on-chain SVGs

## Quick Decision Guide

| Use Case | Solution |
|----------|----------|
| Static artwork per tier | `encodedIPFSUri` in tier config |
| Dynamic/generative art | Custom `IJB721TokenUriResolver` |
| Composable/layered NFTs | Custom `IJB721TokenUriResolver` |
| On-chain SVG | Custom `IJB721TokenUriResolver` |
| Simple project, minimal gas | `encodedIPFSUri` (no resolver needed) |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        JB721TiersHook                               │
│                              │                                       │
│                        STORE()                                       │
│                              ▼                                       │
│                    JB721TiersHookStore                              │
│                              │                                       │
│              ┌───────────────┴───────────────┐                      │
│              ▼                               ▼                       │
│    tiersOf(hook, ...)              tokenUriResolverOf(hook)         │
│              │                               │                       │
│              ▼                               ▼                       │
│    ┌─────────────────┐              ┌─────────────────┐             │
│    │ encodedIPFSUri  │              │ Custom Resolver │             │
│    │ (bytes32)       │              │ (address)       │             │
│    └────────┬────────┘              └────────┬────────┘             │
│             │                                │                       │
│             ▼                                ▼                       │
│    ┌─────────────────┐              ┌─────────────────┐             │
│    │ IPFS Gateway    │              │ tokenUriOf()    │             │
│    │ ipfs://Qm...    │              │ On-chain SVG    │             │
│    └─────────────────┘              └─────────────────┘             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Pattern 1: Static IPFS Content (Most Projects)

### How It Works

1. Tier configured with `encodedIPFSUri` (bytes32 encoding of IPFS CID)
2. `tiersOf()` returns tier data with encoded URI
3. Frontend decodes to `ipfs://Qm...`
4. Fetches JSON metadata from IPFS gateway
5. Displays `image` field from metadata

### Tier Configuration

```typescript
const tierConfig = {
  price: parseEther('0.01'),
  initialSupply: 100,
  votingUnits: 0,
  reserveFrequency: 0,
  reserveBeneficiary: zeroAddress,
  // IPFS CID encoded as bytes32
  encodedIPFSUri: encodeIpfsUri('ipfs://QmYourMetadataHash'),
  category: 0, // Default to 0 unless organizing multiple item types
  discountPercent: 0,
  allowOwnerMint: false,
  useReserveBeneficiaryAsDefault: false,
  transfersPausable: false,
  useVotingUnits: false,
  cannotBeRemoved: false,
  cannotIncreaseDiscountPercent: false,
}
```

### IPFS Metadata Format (ERC-721 Standard)

```json
{
  "name": "Tier 1 NFT",
  "description": "Description of this tier",
  "image": "ipfs://QmImageHash",
  "attributes": [
    { "trait_type": "Category", "value": "Art" },
    { "trait_type": "Rarity", "value": "Common" }
  ]
}
```

### Frontend Resolution

```typescript
import { decodeEncodedIPFSUri, resolveIpfsUri } from './utils/ipfs'

// Decode bytes32 to IPFS URI
const ipfsUri = decodeEncodedIPFSUri(tier.encodedIPFSUri)
// Result: ipfs://QmYourMetadataHash

// Resolve to HTTP gateway
const metadataUrl = resolveIpfsUri(ipfsUri)
// Result: https://ipfs.io/ipfs/QmYourMetadataHash

// Fetch metadata
const response = await fetch(metadataUrl)
const metadata = await response.json()

// Resolve image URI
const imageUrl = resolveIpfsUri(metadata.image)
```

### Encoding/Decoding Functions

```typescript
// Encode IPFS CID to bytes32 for on-chain storage
function encodeIpfsUri(cid: string): `0x${string}` {
  // CIDv0 (Qm...) -> bytes32 (strip 0x1220 multihash prefix)
  const decoded = base58Decode(cid.replace('ipfs://', ''))
  const hash = decoded.slice(2) // Skip 0x1220
  return `0x${Buffer.from(hash).toString('hex')}`
}

// Decode bytes32 to IPFS URI
function decodeEncodedIPFSUri(encoded: string): string | null {
  if (!encoded || encoded === '0x' + '0'.repeat(64)) return null
  const hash = encoded.slice(2) // Remove 0x
  const multihash = '1220' + hash // Add sha256 prefix
  const bytes = hexToBytes(multihash)
  const cid = base58Encode(bytes)
  return `ipfs://${cid}`
}
```

---

## Pattern 2: On-Chain Resolver Content (Banny-Style)

### How It Works

1. No `encodedIPFSUri` in tier config (set to zero bytes)
2. Custom resolver registered via `tokenUriResolverOf(hook)`
3. Resolver implements `IJB721TokenUriResolver`
4. Frontend calls `tokenUriOf(hook, syntheticTokenId)`
5. Resolver returns data URI with SVG/metadata

### The Synthetic Token ID Formula

For unminted tiers (displaying tier catalog before purchase):

```
syntheticTokenId = tierId * 1_000_000_000 + 0
```

This tells the resolver to return the "base" tier appearance without any specific token traits.

For minted tokens, the actual tokenId encodes both tier and sequence:
```
tokenId = tierId * 1_000_000_000 + mintSequence
```

### IJB721TokenUriResolver Interface

```solidity
interface IJB721TokenUriResolver {
    /// @notice Returns the token URI for the given token
    /// @param hook The 721 hook address
    /// @param tokenId The token ID (or synthetic ID for tier preview)
    /// @return The token URI (data: or ipfs: or https:)
    function tokenUriOf(
        address hook,
        uint256 tokenId
    ) external view returns (string memory);
}
```

### Banny-Style Implementation

```solidity
contract Banny721TokenUriResolver is IJB721TokenUriResolver {
    function tokenUriOf(
        address hook,
        uint256 tokenId
    ) external view override returns (string memory) {
        // Extract tier ID from token ID
        uint256 tierId = tokenId / 1_000_000_000;

        // Get tier traits/outfit from storage
        BannyOutfit memory outfit = _outfitOf[hook][tokenId];

        // Generate SVG on-chain
        string memory svg = _renderSvg(tierId, outfit);

        // Build metadata JSON
        string memory json = string(abi.encodePacked(
            '{"name":"Banny #', tokenId.toString(),
            '","description":"A Banny NFT",',
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)),
            '"}'
        ));

        // Return as data URI
        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(bytes(json))
        ));
    }
}
```

### Frontend Resolution

```typescript
async function resolveTierUri(
  hookAddress: `0x${string}`,
  tierId: number,
  chainId: number
): Promise<string | null> {
  const client = createPublicClient({ chain, transport: http(rpcUrl) })

  // 1. Get store from hook
  const storeAddress = await client.readContract({
    address: hookAddress,
    abi: JB721TiersHookAbi,
    functionName: 'STORE',
  })

  // 2. Get resolver from store
  const resolverAddress = await client.readContract({
    address: storeAddress,
    abi: [{ name: 'tokenUriResolverOf', ... }],
    functionName: 'tokenUriResolverOf',
    args: [hookAddress],
  })

  if (!resolverAddress || resolverAddress === zeroAddress) return null

  // 3. Generate synthetic token ID for tier preview
  const syntheticTokenId = BigInt(tierId) * 1_000_000_000n

  // 4. Call resolver
  const dataUri = await client.readContract({
    address: resolverAddress,
    abi: [{ name: 'tokenUriOf', ... }],
    functionName: 'tokenUriOf',
    args: [hookAddress, syntheticTokenId],
  })

  return dataUri
}

// Parse the data URI response
function parseDataUri(dataUri: string): { image?: string } {
  // dataUri = "data:application/json;base64,eyJuYW1lIjoi..."
  const base64Data = dataUri.split(',')[1]
  const jsonStr = atob(base64Data)
  return JSON.parse(jsonStr)
}
```

### Lazy Loading Pattern

Since resolver calls are gas-intensive, use lazy loading:

```tsx
function NFTTierCard({ tier, hookAddress, chainId }) {
  const [onChainImage, setOnChainImage] = useState<string | null>(null)

  // Resolve IPFS first (fast path)
  const ipfsImageUrl = resolveIpfsUri(tier.imageUri)

  // Lazy load on-chain SVG only if no IPFS image
  useEffect(() => {
    if (ipfsImageUrl || !hookAddress) return
    if (!tier.encodedIPFSUri && !tier.imageUri) {
      resolveTierUri(hookAddress, tier.tierId, chainId)
        .then(dataUri => {
          if (dataUri) {
            const { image } = parseDataUri(dataUri)
            setOnChainImage(image)
          }
        })
    }
  }, [tier.tierId, hookAddress])

  const imageUrl = ipfsImageUrl || onChainImage
  return <img src={imageUrl} />
}
```

---

## Deployment: Registering a Resolver

When deploying a 721 hook with custom resolver:

```typescript
const deploy721Config = {
  name: 'My NFT Collection',
  symbol: 'MYNFT',
  baseUri: '', // Empty if using resolver
  tokenUriResolver: resolverAddress, // Your custom resolver
  contractUri: 'ipfs://QmContractMetadata',
  tiers: tierConfigs,
  flags: {
    noNewTiersWithReserves: false,
    noNewTiersWithVotes: false,
    noNewTiersWithOwnerMinting: false,
    preventOverspending: false,
  },
}
```

---

## Performance Considerations

### IPFS-Based Content
- **Pros**: Simple, cheap to deploy, no gas for content
- **Cons**: Depends on IPFS gateway availability, pinning costs
- **Tip**: Use multiple gateways with fallback

### On-Chain Resolver Content
- **Pros**: Fully on-chain, no external dependencies, dynamic content
- **Cons**: Gas-intensive reads, complex to implement
- **Tip**: Use lazy loading, cache results, consider RPC gas limits

### Gas Limits for Resolver Calls

Public RPCs typically have 1-5M gas limits. Complex on-chain SVGs can exceed this:

```typescript
// May fail on public RPC with large SVG
const uri = await client.readContract({
  address: resolverAddress,
  functionName: 'tokenUriOf',
  args: [hookAddress, tokenId],
})

// Use an RPC with higher gas limit for on-chain content
const MAINNET_RPC_ENDPOINTS = [
  'https://ethereum-rpc.publicnode.com', // 5M gas limit
  'https://eth.llamarpc.com',
]
```

---

## Common Patterns

### Category-Based Organization

The 721 hook is a **selling machine** - use categories to organize what a project sells.

**Category System:**
- `category` field is a `uint24` (values 0-16,777,215)
- Use categories 0-199 for custom selling categories
- Tiers MUST be sorted by category (lowest to highest) when calling `adjustTiers`
- UI groups and filters tiers by category

**Common Category Patterns:**
| Category | Use Case |
|----------|----------|
| 0 | Rewards (thank-you perks for supporters) |
| 1 | Merchandise (t-shirts, stickers, hats) |
| 2 | Digital Goods (downloads, access codes, exclusive content) |
| 3 | Services (consultations, lessons, commissioned work) |
| 4 | Memberships (access passes, subscriptions, VIP tiers) |
| 5 | Collectibles (limited edition items, art, memorabilia) |

**Store category names in project metadata:**

The project's `projectUri` should include a `721Categories` field mapping integers to human-readable names:

```json
{
  "name": "My Project",
  "description": "...",
  "721Categories": {
    "0": "Rewards",
    "1": "Merch",
    "2": "Digital",
    "3": "Services"
  }
}
```

**Fetch tiers by category:**
```typescript
const artTiers = await client.readContract({
  address: storeAddress,
  functionName: 'tiersOf',
  args: [hookAddress, [1n], false, 0n, 100n], // Category 1 only
})
```

**When adding tiers:**
- **Default to category 0** unless there's a clear need to organize different types of items
- Only introduce multiple categories if needed (e.g., separating rewards vs merchandise vs services)
- If using multiple categories, update project metadata via `setUriOf` with category names

### Composable NFTs (Banny Pattern)

Banny uses a slot-based system where base NFTs can have items attached:

```solidity
struct BannyOutfit {
    uint256 headId;   // Hat tier
    uint256 bodyId;   // Clothing tier
    uint256 handId;   // Held item tier
}

mapping(address hook => mapping(uint256 tokenId => BannyOutfit)) _outfitOf;
```

The resolver combines layers into a single SVG based on equipped items.

---

## Reference Implementations

- **Banny (On-Chain SVG)**: [github.com/mejango/banny-retail-v5](https://github.com/mejango/banny-retail-v5)
- **721 Hook Store**: [github.com/Bananapus/nana-721-hook-v5](https://github.com/Bananapus/nana-721-hook-v5)

---

## Troubleshooting

### Tier images not loading

1. **Check `encodedIPFSUri`**: Is it zero bytes? → Try on-chain resolver
2. **Check IPFS gateway**: Is the content pinned? Try alternate gateways
3. **Check resolver**: Does `tokenUriResolverOf(hook)` return non-zero address?

### Resolver calls reverting

1. **Gas limit**: On-chain SVGs can exceed RPC limits. Use high-limit RPC
2. **Wrong token ID**: Use synthetic ID (`tierId * 1B`) for tier preview
3. **ABI mismatch**: Ensure ABI matches the actual resolver interface

### tiersOf() reverting with includeResolvedUri=true

Some resolvers (like Banny) return large SVGs. Fetch without resolved URI:

```typescript
const tiers = await client.readContract({
  functionName: 'tiersOf',
  args: [hookAddress, [], false, 0n, 100n], // false = don't include resolved URI
})
// Then lazy-load resolver content per-tier
```
