# Contributing to Juicebox Skills

## Scope: What Belongs Here

Juicebox-skills contains **objective protocol knowledge** for building with Juicebox V5:

**Include:**
- Contract addresses and ABIs
- Function signatures and parameters
- Protocol mechanics (how rulesets work, cash out calculations, etc.)
- Integration patterns (how to deploy, query, configure)
- Code examples and deployment scripts
- Error messages and their causes
- Technical gotchas and edge cases

**Exclude:**
- App-specific tone or voice guidelines
- User-facing terminology preferences (e.g., "say X instead of Y")
- UX/UI recommendations
- Marketing language
- Opinions on how to present information to users

## Principle

These skills should work for **any** app building on Juicebox - not just one specific implementation. Keep content neutral and technical. Let each app decide its own voice and terminology.

## Examples

**Good skill content:**
- "NATIVE_TOKEN address is 0x000000000000000000000000000000000000EEEe"
- "Currency in JBAccountingContext is uint32(uint160(tokenAddress))"
- "Use cashOutTaxRate: 0 for full redemptions"

**Does NOT belong here:**
- "Say 'community fund' instead of 'DAO treasury'"
- "Avoid crypto jargon in user interfaces"
- "Use friendly tone when explaining"

These app-specific choices belong in the app's own prompt configuration, not in shared protocol knowledge.
