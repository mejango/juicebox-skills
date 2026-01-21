---
name: jb-swap-terminal-permit2
description: |
  Fix permit2 metadata parsing failures when paying Juicebox V5 projects through swap terminals
  with USDC. Use when: (1) Tenderly shows "exists: false" for permit2 metadata lookup,
  (2) "Called function does not exist" error at JBSwapTerminalRegistry abi.decode line,
  (3) USDC payments through JBSwapTerminal fail despite correct permit2 signature,
  (4) metadata ID calculation returns wrong bytes4 value. Root cause: permit2 metadata ID
  and spender must use the terminal address returned by primaryTerminalOf, which should be
  the swap terminal registry (0x60b4f5595ee509c4c22921c7b7999f1616e6a4f6 for ETH projects,
  0x1ce40d201cdec791de05810d17aaf501be167422 for USDC projects).
---

# JBSwapTerminal Permit2 Integration

## Problem

USDC payments to Juicebox V5 projects via swap terminals fail with permit2 metadata parsing
errors. The transaction reverts when trying to decode `JBSingleAllowance` from metadata.

## Context / Trigger Conditions

- Tenderly trace shows `exists: false` and `parsedMetadata: "0x00"` at `getDataFor` call
- Error: "Called function does not exist in the contract" at JBSwapTerminalRegistry line ~415
- Payment token is USDC (or other ERC20 requiring permit2)
- Terminal type is 'swap' (payment goes through JBSwapTerminal/JBSwapTerminalRegistry)

## Swap Terminal Registries

There are TWO swap terminal registries, deployed at the same address on all chains via CREATE2:

| Registry | Address | TOKEN_OUT | Purpose |
|----------|---------|-----------|---------|
| **JBSwapTerminalRegistry** | `0x60b4f5595ee509c4c22921c7b7999f1616e6a4f6` | NATIVE_TOKEN (ETH) | Swaps incoming tokens → ETH |
| **JBSwapTerminalUSDCRegistry** | `0x1ce40d201cdec791de05810d17aaf501be167422` | USDC | Swaps incoming tokens → USDC |

**Choose based on what the project should RECEIVE** after the swap, not what the user pays with.

## Project Configuration

Like all terminals, swap terminal registries are configured during project creation via `terminalConfigurations` in `launchProjectFor()`:

```solidity
JBTerminalConfig[] memory terminalConfigurations = new JBTerminalConfig[](1);
terminalConfigurations[0] = JBTerminalConfig({
    terminal: IJBTerminal(JB_SWAP_TERMINAL_USDC_REGISTRY),  // or JB_SWAP_TERMINAL_REGISTRY for ETH
    accountingContextsToAccept: tokenContexts
});

controller.launchProjectFor({
    owner: projectOwner,
    projectUri: "...",
    rulesetConfigurations: rulesets,
    terminalConfigurations: terminalConfigurations,
    memo: ""
});
```

## Permit2 Metadata

### Key Rule

**Use the terminal address returned by `primaryTerminalOf` for permit2.**

Projects configured properly will have the correct swap terminal registry registered. Query it:

```typescript
const terminal = await client.readContract({
    address: JB_DIRECTORY,
    abi: directoryAbi,
    functionName: 'primaryTerminalOf',
    args: [projectId, tokenAddress],
})
// Use `terminal` for permit2 ID and spender
```

### Correct ID Calculation (byte arrays, not BigInt)

**WRONG** - BigInt has byte alignment issues:
```typescript
function computePermit2MetadataId(addr: Address): Hex {
  const addrBigInt = BigInt(addr)
  const hashBigInt = BigInt(keccak256(toBytes('permit2')))
  const purposeBytes20 = hashBigInt >> BigInt(96)
  const xored = addrBigInt ^ purposeBytes20
  const result = (xored >> BigInt(128)) & BigInt(0xFFFFFFFF)
  return `0x${result.toString(16).padStart(8, '0')}`
}
```

**CORRECT** - Use byte arrays:
```typescript
import { toBytes, bytesToHex, keccak256 } from 'viem'

function computePermit2MetadataId(targetAddress: Address): Hex {
  const targetBytes = toBytes(targetAddress)  // 20 bytes
  const purposeHashFull = toBytes(keccak256(toBytes('permit2')))
  const purposeBytes20 = purposeHashFull.slice(0, 20)  // First 20 bytes

  // XOR byte by byte (matches Solidity bytes20 ^ bytes20)
  const xorResult = new Uint8Array(20)
  for (let i = 0; i < 20; i++) {
    xorResult[i] = targetBytes[i] ^ purposeBytes20[i]
  }

  // Take first 4 bytes (matches Solidity bytes4(...))
  return bytesToHex(xorResult.slice(0, 4)) as Hex
}
```

### Permit2 Signature

The `spender` in the Permit2 signature must also be the terminal address from `primaryTerminalOf`:

```typescript
const signature = await walletClient.signTypedData({
    domain: { name: 'Permit2', chainId, verifyingContract: PERMIT2_ADDRESS },
    types: PERMIT2_TYPES,
    primaryType: 'PermitSingle',
    message: {
        details: { token: usdcAddress, amount, expiration, nonce },
        spender: terminalAddress,  // From primaryTerminalOf
        sigDeadline
    }
})
```

## Verification

1. Query `primaryTerminalOf(projectId, token)` to get the correct terminal
2. Compute permit2 ID using byte array XOR with that terminal address
3. Set permit2 spender to that same terminal address
4. In Tenderly simulation, verify `exists: true` at `getDataFor` call

## Related Code Locations

**Solidity (JBSwapTerminalRegistry.sol ~line 410)**:
```solidity
(bool exists, bytes memory parsedMetadata) =
    JBMetadataResolver.getDataFor(JBMetadataResolver.getId("permit2"), metadata);
// getId("permit2") uses address(this) = the registry address
```

**JBMetadataResolver.getId**:
```solidity
function getId(string memory purpose) internal view returns (bytes4) {
    return bytes4(bytes20(address(this)) ^ bytes20(keccak256(bytes(purpose))));
}
```

## Notes

- This only affects ERC20 payments through swap terminals requiring permit2
- ETH payments don't use permit2 and aren't affected
- JBMultiTerminal (non-swap) uses its own address for permit2
- Payments can be routed through swap terminals even if not explicitly registered, but proper registration via `terminalConfigurations` is recommended

## References

- JBMetadataResolver: `/nana-core-v5/src/libraries/JBMetadataResolver.sol`
- JBSwapTerminalRegistry: `/nana-swap-terminal-v5/src/JBSwapTerminalRegistry.sol`
- juice-sdk-v4 metadata helpers: `/juice-sdk-v4/packages/react/src/hooks/jb721Hook/helpers.ts`
- Permit2 test: `/nana-core-v5/test/TestPermit2Terminal.sol`
