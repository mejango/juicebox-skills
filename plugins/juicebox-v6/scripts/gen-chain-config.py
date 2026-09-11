# Regenerates shared/chain-config.json from deploy-all-v6/deployments.
# Usage: python3 scripts/gen-chain-config.py [path/to/deploy-all-v6/deployments] [--check]
#   --check: exit 1 if the committed file differs from what the artifacts produce (CI parity gate).
# Sources: every deployed artifact per chain, including retired generations; USDC from script/libraries/JBChainTokens.sol;
# Permit2 from the JBMultiTerminal artifact constructor args (chain-same).
import json,os,glob,sys
HERE=os.path.dirname(os.path.abspath(__file__))
CHECK='--check' in sys.argv; argv=[a for a in sys.argv[1:] if a!='--check']
D=argv[0] if argv else os.path.join(HERE,'..','..','..','..','deploy-all-v6','deployments')
cfgp=os.path.join(HERE,'..','shared','chain-config.json')
cfg=json.load(open(cfgp))
dirs={'1':'ethereum','10':'optimism','8453':'base','42161':'arbitrum','11155111':'sepolia','11155420':'optimism_sepolia','84532':'base_sepolia','421614':'arbitrum_sepolia'}
USDC={'1':'0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48','11155111':'0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238','10':'0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85','11155420':'0x5fd84259d66Cd46123540766Be93DFE6D43130D7','8453':'0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913','84532':'0x036CbD53842c5426634e7929541eC2318f3dCF7e','42161':'0xaf88d065e77c8cC2239327C5EDb3A432268e5831','421614':'0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d'}
out={'_version':'6','_note':'Juicebox V6. Generated only from flat deploy-all-v6/deployments records, never proposals. Contracts includes the current artifact and all _deprecated generations for history and still-selected projects. deploymentInfo maps router/buyback/feed records to their package generation, ABI and deployment evidence. Canonical presence does not replace registry.terminalOf(projectId) or registry.hookOf(projectId); unwrap a selected gateway via ROUTER(). Ratio feeds connect USDC to ETH/native only on chains where deployed and registered.','chains':{}}
rollout_names={'JBBuybackHook','JBRouterTerminal','JBRouterTerminalGateway','JBRatioPriceFeed'}
abi_outputs={}
latest_abis={}

for cid,d in dirs.items():
    old=cfg['chains'][cid]
    contracts={}
    deployment_info={}
    for f in sorted(glob.glob(f'{D}/{d}/*.json')):
        n=os.path.basename(f)[:-5]
        j=json.load(open(f)); assert int(j['chainId'],16)==int(cid)
        contracts[n]=j['address'].lower()
        if j.get('contractName') in rollout_names:
            receipt=j.get('receipt') or {}
            if int(str(receipt.get('status','0')),0)!=1 or not receipt.get('transactionHash'):
                raise ValueError(f'{f}: rollout artifact must have a successful deployment receipt')
            package=j['gitCommit'].removeprefix('npm:')
            version=package.rsplit('@',1)[-1]
            abi_name=f"{j['contractName']}__{version.replace('.', '_')}.json"
            abi_text=json.dumps(j['abi'],indent=1)+'\n'
            if abi_name in abi_outputs and abi_outputs[abi_name]!=abi_text:
                raise ValueError(f'{f}: ABI differs within package generation {package}')
            abi_outputs[abi_name]=abi_text
            generation=tuple(int(part) for part in version.split('.'))
            if generation>latest_abis.get(j['contractName'],((-1,),None))[0]:
                latest_abis[j['contractName']]=(generation,abi_text)
            deployment_info[n]={'generation': 'v1' if n.endswith('_deprecated') else 'previous' if '_deprecated' in n else 'current',
                'package':package,'abi':f'shared/abis/{abi_name}',
                'blockNumber':int(str(receipt['blockNumber']),0),'transactionHash':receipt['transactionHash']}

    mt=json.load(open(f'{D}/{d}/JBMultiTerminal.json'))
    p2=mt['args'][6].lower(); assert p2=='0x000000000022d473030f116ddee9f6b43ac78ba3'
    contracts['Permit2']=p2
    contracts['USDC']=USDC[cid].lower()
    out['chains'][cid]={'name':old['name'],'rpc':old['rpc'],'explorer':old['explorer'],'testnet':old['testnet'],'contracts':dict(sorted(contracts.items())),'deploymentInfo':deployment_info}
new=json.dumps(out,indent=2,ensure_ascii=False)+'\n'
outputs={cfgp:new}
for name,(_,abi_text) in latest_abis.items():
    abi_outputs[name+'.json']=abi_text
for name,abi_text in abi_outputs.items():
    outputs[os.path.join(HERE,'..','shared','abis',name)]=abi_text
stale=[path for path,content in outputs.items() if not os.path.exists(path) or open(path).read()!=content]
if CHECK:
    if stale:
        print('Generated deployment data is out of date: '+', '.join(os.path.basename(p) for p in stale)); sys.exit(1)
    print('chain-config.json and rollout ABIs match deploy-all artifacts'); sys.exit(0)
for path,content in outputs.items():
    with open(path,'w') as target: target.write(content)
print(f'Generated chain-config and {len(abi_outputs)} rollout ABIs')
