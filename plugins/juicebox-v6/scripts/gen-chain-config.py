# Regenerates shared/chain-config.json from deploy-all-v6/deployments.
# Usage: python3 scripts/gen-chain-config.py [path/to/deploy-all-v6/deployments]
# Sources: every non-_deprecated artifact per chain; USDC from script/libraries/JBChainTokens.sol;
# Permit2 from the JBMultiTerminal artifact constructor args (chain-same).
import json,os,glob,sys
HERE=os.path.dirname(os.path.abspath(__file__))
D=sys.argv[1] if len(sys.argv)>1 else os.path.join(HERE,'..','..','..','..','v6','evm','deploy-all-v6','deployments')
cfgp=os.path.join(HERE,'..','shared','chain-config.json')
cfg=json.load(open(cfgp))
dirs={'1':'ethereum','10':'optimism','8453':'base','42161':'arbitrum','11155111':'sepolia','11155420':'optimism_sepolia','84532':'base_sepolia','421614':'arbitrum_sepolia'}
USDC={'1':'0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48','11155111':'0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238','10':'0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85','11155420':'0x5fd84259d66Cd46123540766Be93DFE6D43130D7','8453':'0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913','84532':'0x036CbD53842c5426634e7929541eC2318f3dCF7e','42161':'0xaf88d065e77c8cC2239327C5EDb3A432268e5831','421614':'0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d'}
out={'_version':'6','_note':'Juicebox V6. Single contract set per chain. Generated from deploy-all-v6/deployments (latest artifact per name; superseded artifacts excluded). Core contracts share the same address on every chain (CREATE2). Chain-specific entries (JBUniswapV4Hook, CCIP suckers, price feeds, project instances, USDC) differ per chain. Permit2 is the canonical Uniswap deployment on every chain. Project-0 price feeds cover USD<->native, USD<->ETH(1), ETH(1)<->native and USD<->USDC only; there is no native/ETH<->USDC feed.','chains':{}}
for cid,d in dirs.items():
    old=cfg['chains'][cid]
    contracts={}
    for f in glob.glob(f'{D}/{d}/*.json'):
        n=os.path.basename(f)[:-5]
        if '_deprecated' in n: continue
        j=json.load(open(f)); assert int(j['chainId'],16)==int(cid)
        contracts[n]=j['address'].lower()
    mt=json.load(open(f'{D}/{d}/JBMultiTerminal.json'))
    p2=mt['args'][6].lower(); assert p2=='0x000000000022d473030f116ddee9f6b43ac78ba3'
    contracts['Permit2']=p2
    contracts['USDC']=USDC[cid].lower()
    out['chains'][cid]={'name':old['name'],'rpc':old['rpc'],'explorer':old['explorer'],'testnet':old['testnet'],'contracts':dict(sorted(contracts.items()))}
json.dump(out,open(cfgp,'w'),indent=2,ensure_ascii=False); open(cfgp,'a').write('\n')
print('ok')
