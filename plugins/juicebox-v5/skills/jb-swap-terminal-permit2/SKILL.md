---
name: jb-swap-terminal-permit2
description: Encode Permit2 metadata for Juicebox V5 terminal payments (JBMultiTerminal, JBSwapTerminal). Use when implementing gasless ERC20 payments via Permit2, seeing AllowanceExpired errors, metadata extraction returns zeros, building JBSingleAllowance struct, or Tenderly shows exists false at getDataFor call. Use juicebox-metadata-helper library.
---

# JBSwapTerminal Permit2 Integration

## Problem

USDC payments to Juicebox V5 projects via terminals need proper Permit2 metadata encoding.
The permit2 authorization data must follow the JBMetadataResolver format exactly, or the
terminal will either not find the permit2 data or extract zeros.

## Context / Trigger Conditions

- Implementing USDC or other ERC20 payments to Juicebox projects
- Want single-transaction UX instead of approve + pay (two transactions)
- Tenderly trace shows `exists: false` and `parsedMetadata: "0x00"` at `getDataFor` call
- Tenderly shows `exists: true` but extracted data is all zeros or shifted values
- Seeing "AllowanceExpired" error from Permit2 contract
- Error: "Called function does not exist in the contract" at terminal abi.decode line
- Decoded values appear shifted (e.g., sigDeadline shows 288 instead of timestamp)

## Critical Insight: Use the Official Library

**ALWAYS use `juicebox-metadata-helper` for metadata construction.** Manual metadata
construction has subtle bugs that are extremely difficult to debug:

```bash
npm install juicebox-metadata-helper
```

The library handles:
- Correct offset calculation (in words, not bytes)
- Proper padding to 32-byte boundaries
- Lookup table format matching JBMetadataResolver exactly

## Swap Terminal Registries

There are TWO swap terminal registries, deployed at the same address on all chains via CREATE2:

| Registry | Address | TOKEN_OUT | Purpose |
|----------|---------|-----------|---------|
| **JBSwapTerminalRegistry** | `0x60b4f5595ee509c4c22921c7b7999f1616e6a4f6` | NATIVE_TOKEN (ETH) | Swaps incoming tokens → ETH |
| **JBSwapTerminalUSDCRegistry** | `0x1ce40d201cdec791de05810d17aaf501be167422` | USDC | Swaps incoming tokens → USDC |

**Choose based on what the project should RECEIVE** after the swap, not what the user pays with.

## Solution

### 1. Install Dependencies

```bash
npm install juicebox-metadata-helper ethers@5
```

### 2. Query the Correct Terminal Address

**Use the terminal address returned by `primaryTerminalOf` for permit2.**

```typescript
const terminal = await client.readContract({
    address: JB_DIRECTORY,
    abi: directoryAbi,
    functionName: 'primaryTerminalOf',
    args: [projectId, tokenAddress],
})
// Use `terminal` for permit2 ID and spender
```

### 3. Compute the Permit2 Metadata ID (Use ethers.js)

**CRITICAL**: Use ethers.js for ID computation. Viem's byte handling can have subtle issues
with the XOR operation that cause `exists: false` errors.

```typescript
import { ethers } from 'ethers'
import type { Address } from 'viem'

function computePermit2MetadataId(terminalAddress: Address): string {
  // Use ethers to match Solidity's bytes20 XOR exactly
  const purposeHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes('permit2'))

  // Get first 20 bytes of hash (40 hex chars after 0x)
  const purposeBytes20 = purposeHash.slice(0, 42)

  // Terminal address is already 20 bytes
  const terminalBytes20 = terminalAddress.toLowerCase()

  // XOR as BigNumbers - this matches Solidity's bytes20 ^ bytes20
  const purposeBN = ethers.BigNumber.from(purposeBytes20)
  const terminalBN = ethers.BigNumber.from(terminalBytes20)
  const xorResult = purposeBN.xor(terminalBN)

  // Get first 4 bytes (8 hex chars) - matches Solidity's bytes4(...)
  return xorResult.toHexString().slice(0, 10)
}
```

### 4. Encode JBSingleAllowance Struct

```typescript
import { encodeAbiParameters, type Hex } from 'viem'

function encodeJBSingleAllowance(
  sigDeadline: bigint,
  amount: bigint,
  expiration: number,
  nonce: number,
  signature: Hex
): Hex {
  return encodeAbiParameters(
    [
      { type: 'uint256' },  // sigDeadline
      { type: 'uint160' },  // amount
      { type: 'uint48' },   // expiration
      { type: 'uint48' },   // nonce
      { type: 'bytes' },    // signature
    ],
    [sigDeadline, amount, expiration, nonce, signature]
  )
}
```

### 5. Build Metadata with the Library

**This is the critical piece. Use `juicebox-metadata-helper`, NOT manual construction.**

```typescript
import createMetadata from 'juicebox-metadata-helper'
import type { Hex, Address } from 'viem'

function buildPermit2Metadata(allowanceData: Hex, terminalAddress: Address): Hex {
  const permit2Id = computePermit2MetadataId(terminalAddress)

  // Pad allowance data to 32-byte boundary (required by the library)
  const dataLen = (allowanceData.length - 2) / 2
  const paddedLen = Math.ceil(dataLen / 32) * 32
  const paddedData = ('0x' + allowanceData.slice(2).padEnd(paddedLen * 2, '0')) as Hex

  // Use the official library - it handles format correctly
  return createMetadata([permit2Id], [paddedData]) as Hex
}
```

### 6. Sign the Permit2 Message

```typescript
const PERMIT2_ADDRESS = '0x000000000022D473030F116dDEE9F6B43aC78BA3'

const PERMIT2_TYPES = {
  PermitSingle: [
    { name: 'details', type: 'PermitDetails' },
    { name: 'spender', type: 'address' },
    { name: 'sigDeadline', type: 'uint256' },
  ],
  PermitDetails: [
    { name: 'token', type: 'address' },
    { name: 'amount', type: 'uint160' },
    { name: 'expiration', type: 'uint48' },
    { name: 'nonce', type: 'uint48' },
  ],
}

// Get current nonce from Permit2
const [, , currentNonce] = await publicClient.readContract({
  address: PERMIT2_ADDRESS,
  abi: permit2AllowanceAbi,
  functionName: 'allowance',
  args: [userAddress, tokenAddress, terminalAddress],
})

const nowSeconds = Math.floor(Date.now() / 1000)
const expiration = nowSeconds + 30 * 24 * 60 * 60  // 30 days
const sigDeadline = BigInt(nowSeconds + 30 * 60)   // 30 minutes

const signature = await walletClient.signTypedData({
  domain: {
    name: 'Permit2',
    chainId: chainId,
    verifyingContract: PERMIT2_ADDRESS,
  },
  types: PERMIT2_TYPES,
  primaryType: 'PermitSingle',
  message: {
    details: {
      token: tokenAddress,
      amount: paymentAmount,
      expiration: expiration,
      nonce: Number(currentNonce),
    },
    spender: terminalAddress,  // The terminal that will call permit2
    sigDeadline: sigDeadline,
  },
})
```

### 7. Complete Payment Flow

```typescript
// 1. Ensure token is approved to Permit2 (one-time)
const tokenToPermit2Allowance = await publicClient.readContract({
  address: tokenAddress,
  abi: erc20Abi,
  functionName: 'allowance',
  args: [userAddress, PERMIT2_ADDRESS],
})

if (tokenToPermit2Allowance < amount) {
  // Approve max to Permit2 (one-time unlimited approval)
  await walletClient.writeContract({
    address: tokenAddress,
    abi: erc20Abi,
    functionName: 'approve',
    args: [PERMIT2_ADDRESS, maxUint256],
  })
}

// 2. Get terminal address
const terminalAddress = await publicClient.readContract({
  address: JB_DIRECTORY,
  abi: directoryAbi,
  functionName: 'primaryTerminalOf',
  args: [projectId, tokenAddress],
})

// 3. Sign permit and build metadata
const signature = await walletClient.signTypedData(...)
const allowanceData = encodeJBSingleAllowance(sigDeadline, amount, expiration, nonce, signature)
const metadata = buildPermit2Metadata(allowanceData, terminalAddress)

// 4. Call pay with metadata - single transaction!
await walletClient.writeContract({
  address: terminalAddress,
  abi: terminalAbi,
  functionName: 'pay',
  args: [projectId, tokenAddress, amount, beneficiary, 0n, memo, metadata],
})
```

## Debugging Guide

### `exists: false` in Tenderly trace

**Problem**: The permit2 ID is not being found in the metadata lookup table.

**Solution**:
1. Verify you're using ethers.js for ID computation (not viem byte arrays)
2. Verify the terminal address matches what `primaryTerminalOf` returns
3. Log both the computed ID and compare with what the contract expects

### `exists: true` but decoded values are zeros or shifted

**Problem**: The metadata format is incorrect - data is in the wrong position.

**Solution**:
1. Use `juicebox-metadata-helper` library instead of manual construction
2. Ensure data is padded to 32-byte boundaries before passing to library
3. Check that offset is in WORDS (not bytes)

### Decoded sigDeadline shows wrong value (e.g., 288)

**Problem**: The contract is reading the data length instead of the actual data.

**Solution**: This indicates the offset or format is wrong. Use the library.

## Common Mistakes

1. **Manual metadata construction**: Has subtle bugs. ALWAYS use `juicebox-metadata-helper`.
2. **Viem for ID computation**: Use ethers.js BigNumber.xor() instead - it matches Solidity exactly.
3. **Wrong terminal address**: Must use the terminal from `primaryTerminalOf`, not hardcoded.
4. **Offset in bytes instead of words**: The offset is in 32-byte words.
5. **Missing padding**: Data must be padded to 32-byte boundaries BEFORE passing to library.
6. **Wrong spender**: Permit2 spender must be the terminal address, not Permit2 itself.

## Verification

1. **Check metadata ID matches**:
   - Terminal uses `JBMetadataResolver.getId("permit2")` which XORs with `address(this)`
   - Your computed ID must match

2. **Verify metadata structure**:
   - Total length: ~352 bytes for a 65-byte signature
   - Data starts at the correct word offset

3. **In Tenderly trace**:
   - `getDataFor()` should return `(true, <non-zero-data>)`
   - If `exists: false`, ID computation is wrong
   - If `exists: true` but data is wrong, format is wrong (use the library!)

## Example

For paying 1 USDC to project 1 on Base via JBSwapTerminalRegistry:

```typescript
import { ethers } from 'ethers'
import createMetadata from 'juicebox-metadata-helper'

const terminalAddress = '0x60b4f5595ee509c4c22921c7b7999f1616e6a4f6' // JBSwapTerminalRegistry
const usdcAddress = '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913'
const amount = 1000000n // 1 USDC (6 decimals)

// Compute ID with ethers (NOT viem)
const permit2Id = computePermit2MetadataId(terminalAddress)

// Encode allowance data
const allowanceData = encodeJBSingleAllowance(sigDeadline, amount, expiration, nonce, signature)

// Build metadata with library (NOT manually)
const metadata = buildPermit2Metadata(allowanceData, terminalAddress)

// Pay with single transaction
await terminal.pay(projectId, usdcAddress, amount, beneficiary, 0n, memo, metadata)
```

## Notes

- **Signature format**: Must be `r || s || v` (65 bytes), which is what viem's `signTypedData` returns
- **Nonce**: Must read current nonce from `Permit2.allowance(owner, token, spender)`
- **Fallback**: If user rejects signature, fall back to standard ERC20 approve flow
- **JBSwapTerminal**: Supports Permit2 same as JBMultiTerminal (both inherit from JBPermit2Payable)

## References

- [JBMetadataResolver.sol](https://github.com/Bananapus/nana-core-v5/blob/main/src/libraries/JBMetadataResolver.sol)
- [JBSingleAllowance.sol](https://github.com/Bananapus/nana-core-v5/blob/main/src/structs/JBSingleAllowance.sol)
- [TestPermit2Terminal5_1.sol](https://github.com/Bananapus/nana-core-v5/blob/main/test/TestPermit2Terminal5_1.sol)
- [Permit2 AllowanceTransfer](https://github.com/Uniswap/permit2)
- [juicebox-metadata-helper](https://www.npmjs.com/package/juicebox-metadata-helper)
