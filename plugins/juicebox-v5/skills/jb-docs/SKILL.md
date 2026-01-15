---
name: jb-docs
description: Query Juicebox V5 documentation programmatically via the juice-docs MCP server. Get latest contract addresses, API specs, and protocol documentation.
---

# Juicebox V5 Documentation Lookup

Query Juicebox documentation via the MCP server at `https://docs.juicebox.money/api/mcp`.

## MCP Server Configuration

Add the Juicebox docs MCP server to your Claude configuration:

```json
{
  "mcpServers": {
    "juicebox-docs": {
      "type": "http",
      "url": "https://docs.juicebox.money/api/mcp"
    }
  }
}
```

## Available Documentation

The MCP server provides access to:

### Protocol Documentation
- **Learn**: Conceptual guides and protocol overview
- **Build**: Implementation guides and tutorials
- **API**: Technical specifications and contract interfaces

### Contract Addresses
- Deployed addresses for all networks (Ethereum, Optimism, Arbitrum, Base)
- Latest V5 contract addresses
- Hook deployer addresses

### Code References
- Interface definitions
- Struct documentation
- Event signatures

## Direct API Access

If MCP is not available, query the docs directly:

### Base URL
```
https://docs.juicebox.money
```

### Documentation Structure
```
/dev/                    # Developer documentation root
/dev/learn/              # Conceptual documentation
/dev/build/              # Implementation guides
/dev/api/                # API reference
/dev/api/contracts/      # Contract documentation
/dev/api/interfaces/     # Interface specs
```

## Common Documentation Queries

### "What's the JBController address on mainnet?"
Look up contract addresses in the deployment documentation or use the MCP server.

### "How do I implement a pay hook?"
Reference the Build section for hook implementation guides.

### "What events does JBMultiTerminal emit?"
Check the API section for contract event documentation.

### "What's the latest V5 protocol changes?"
Review the Learn section for protocol overview and changelog.

## Using WebFetch for Docs

If MCP is not configured, use WebFetch to query docs:

```
WebFetch https://docs.juicebox.money/dev/api/contracts/jbcontroller/
"Extract the contract address and main functions"
```

## Documentation Resources

### Official Sources
- **Docs**: https://docs.juicebox.money
- **GitHub**: https://github.com/jbx-protocol
- **V5 Core**: https://github.com/Bananapus/nana-core-v5

### Reference Implementations
- **Buyback Hook**: https://github.com/Bananapus/nana-buyback-hook-v5
- **721 Hook**: https://github.com/Bananapus/nana-721-hook-v5
- **Revnet**: https://github.com/rev-net/revnet-core-v5

## MCP Tools

When connected to the juice-docs MCP server, use these tools:

### search_docs
Search documentation by keyword.

### get_contract_address
Get deployed contract address for a specific network.

### get_interface
Get interface definition for a contract.

## Generation Guidelines

1. **Check MCP availability** first
2. **Fall back to WebFetch** if MCP not configured
3. **Provide direct links** to relevant documentation
4. **Reference the /references folder** for offline interface/struct definitions

## Example Prompts

- "What's the JBController address on Optimism?"
- "Show me the documentation for pay hooks"
- "What events does the terminal emit?"
- "Get the latest V5 contract addresses"
