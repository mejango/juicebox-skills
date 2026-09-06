import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const root = fileURLToPath(new URL('..', import.meta.url)).replace(/\/$/, '');
// The mock transport needs ABI names only; actual shared ABI files are read below.
const parseAbiItem = (signature) => ({ type: 'function', name: signature.match(/^function (\w+)/)[1] });
const read = (skill) => readFileSync(`${root}/skills/${skill}/SKILL.md`, 'utf8');
const gallery = read('jb-nft-gallery-ui');
const helper = gallery.slice(gallery.indexOf('    async function verifyV6GalleryHook'), gallery.indexOf('    window.loadGallery'));
const config = JSON.parse(readFileSync(`${root}/shared/chain-config.json`, 'utf8'));
const addresses = config.chains['8453'].contracts;
const hook = '0x1234567890123456789012345678901234567890';
const owner = '0x2222222222222222222222222222222222222222';
const loadABI = async (name) => JSON.parse(readFileSync(`${root}/shared/abis/${name}.json`, 'utf8'));
const HOOK_ABI = [parseAbiItem('function DIRECTORY() view returns (address)'), parseAbiItem('function projectId() view returns (uint256)')];
const verify = runInNewContext(`${helper}\nverifyV6GalleryHook`, { loadABI, loadChainConfig: async () => config, HOOK_ABI, parseAbiItem });
async function scenario(overrides = {}) {
  const called = [];
  const client = {
    getBlockNumber: async () => 100n,
    readContract: async (request) => {
      called.push(request.functionName);
      assert.equal(request.blockNumber, 100n);
      assert.ok(request.abi.some((entry) => entry.type === 'function' && entry.name === request.functionName), request.functionName);
      const value = {
        DIRECTORY: addresses.JBDirectory,
        deployerOf: addresses.JB721TiersHookDeployer,
        projectId: 42n,
        ownerOf: owner,
        controllerOf: addresses.JBController,
        currentRulesetOf: [{id: 99n}, {useDataHookForPay:true, dataHook:hook}],
        tiered721HookOf: hook,
        ...overrides,
      }[request.functionName];
      if (value instanceof Error) throw value;
      return value;
    },
  };
  return { promise: verify(client, 8453, hook), called };
}
assert.equal(await (await scenario()).promise, 42n);
const foreign = await scenario({DIRECTORY: owner});
await assert.rejects(foreign.promise, /does not belong/);
assert.deepEqual(foreign.called, ['DIRECTORY']);
await assert.rejects((await scenario({deployerOf: owner})).promise, /not a verified/);
await assert.rejects((await scenario({controllerOf: owner})).promise, /custom controller/);
await assert.rejects((await scenario({currentRulesetOf:[{id:99n}, {useDataHookForPay:false,dataHook:hook}]})).promise, /no active/);
await assert.rejects((await scenario({currentRulesetOf:[{id:99n}, {useDataHookForPay:true,dataHook:owner}]})).promise, /current NFT/);
assert.equal(await (await scenario({currentRulesetOf:[{id:99n}, {useDataHookForPay:true,dataHook:addresses.REVOwner}]})).promise, 42n);
assert.equal(await (await scenario({currentRulesetOf:[{id:99n}, {useDataHookForPay:true,dataHook:addresses.JBOmnichainDeployer}],tiered721HookOf:[hook,false]})).promise, 42n);

const omni = read('jb-omnichain-ui');
const groupBody = omni.slice(omni.indexOf('  async function getSuckerGroupId'), omni.indexOf('  // 2) Group-wide'));
for (const project of [null, {version:5,chainId:8453,projectId:42}, {version:6,chainId:1,projectId:42}, {version:6,chainId:8453,projectId:17}]) {
  const getGroup = runInNewContext(`${groupBody}\ngetSuckerGroupId`, {query:async () => ({project})});
  await assert.rejects(getGroup(42,8453), /No matching V6/);
}
const getGroup = runInNewContext(`${groupBody}\ngetSuckerGroupId`, {query:async () => ({project:{version:6,chainId:8453,projectId:42,suckerGroupId:''}})});
assert.equal(await getGroup(42,8453), null);
console.log('Passed 8 NFT identity scenarios and 5 project absence/identity scenarios.');
