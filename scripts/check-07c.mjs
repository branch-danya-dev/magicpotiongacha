// Protect the accepted technical package and all 1045 inherited test scenarios.
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {beforeAG69} from './ag69-preservation.mjs';
const read=p=>beforeAG69(p,readFileSync(p,'utf8').replaceAll('\r\n','\n'));
const sha=s=>createHash('sha256').update(s).digest('hex');
const baseline=JSON.parse(read('tests/fixtures/composition07c-invariants.json'));
assert.equal(baseline.base,'7aa500e9491d7eb0747c692a77a346ff7a83aaee');
function once(s,from,to='') {
  assert.equal(s.split(from).length,2,`Missing or repeated seam: ${from}`);
  return s.replace(from,to);
}
for(const [p,digest] of Object.entries(baseline.unchanged)) {
  let source=read(p);
  if(p==='tests/run.luau') source=once(source,'\trequire("./composition07c.spec")(Test)\n');
  assert.equal(sha(source),digest,p);
}
let ground=read('src/shared/FarmGround.luau');
ground=once(ground,'local Ridge=require(runtimeScript and runtimeScript.Parent.RidgeComposition or "./RidgeComposition")\n');
ground=once(ground,'return Ridge.apply(x,z,h,material)','return h,material');
assert.equal(sha(ground),baseline.seams['src/shared/FarmGround.luau']);
let style=read('src/shared/AtmosphereStyle.luau');
style=once(style,'local runtimeScript=rawget(getfenv(),"script")\n');
style=once(style,'local Vista=require(runtimeScript and runtimeScript.Parent.VistaPlan or "./VistaPlan")\n');
style=once(style,'local Style={skyPrefix="rbxasset://m7task07a-v1/",sunPools=Vista.sunPools,pollenAnchors=Vista.pollenAnchors}',
  'local Style={skyPrefix="rbxasset://m7task07a-v1/",sunPools={{-171,-88},{-120,-54}},\n\tpollenAnchors={{-174,-52},{-164,-94},{-118,-58},{-138,-89}}}');
assert.equal(sha(style),baseline.seams['src/shared/AtmosphereStyle.luau']);
const art=read('src/server/VistaArt.luau'),view=read('src/client/EnvironmentView.luau');
assert(!/Lighting|DataStore|RemoteEvent|RemoteFunction|HttpService|loadstring|MeshId\s*=|TextureID\s*=|Connect\(|task\.|while\s|PointLight|ParticleEmitter/.test(art));
assert(art.includes('p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false'));
assert(art.includes('params.IgnoreWater=true') && art.includes('params.FilterDescendantsInstances={workspace.Terrain}'));
assert(art.includes('assert(hit,"Backdrop ground missing: "..key)'));
assert(art.includes('assert(not parent:FindFirstChild("PilotVista")'));
assert(art.includes('p:SetAttribute("VistaRole",d.role)'));
assert(art.indexOf('p:SetAttribute("VistaRole",d.role)')<art.indexOf('p.Parent=folder'));
assert.equal(read('src/server/EnvironmentArt.luau').split('require(script.Parent.VistaArt).attach(world,folder,templates)').length,2);
assert.equal((view.match(/:Connect\(/g)||[]).length,5,'No new event owner');
assert.equal((view.match(/RenderStepped:Connect/g)||[]).length,1);
assert(!/BindToRenderStep|task\.defer/.test(view));
assert.equal((view.match(/task\.spawn\(/g)||[]).length,1,'Only the inherited asset preload task');
assert(view.includes('elseif plant and not forestRole and not vistaRole'));
assert(view.includes('alpha=1,target=1,saved=p.LocalTransparencyModifier'));
assert(view.includes('v.target=Vista.alpha(v.role,self.quality,'));
assert(view.includes('v.alpha=ForestLOD.step(v.alpha,v.target,elapsed)'));
const stop=view.slice(view.indexOf('function self.stop('));
assert(stop.includes('v.part.LocalTransparencyModifier=v.saved; v.part.Color=v.color'));
assert(stop.includes('connection:Disconnect()') && stop.includes('added:Disconnect()'));
assert(view.includes('Vista.moonSize') && view.includes('Config.skyPrefix.."moon.png"'));
const plan=read('src/shared/EnvironmentPlan.luau');
assert.equal((plan.match(/-- TASK07C_VISTA_BEGIN/g)||[]).length,1);
assert.equal((plan.match(/-- TASK07C_VISTA_END/g)||[]).length,1);
assert(plan.includes('metrics.parts+=vista.parts; metrics.triangles+=vista.triangles'));
console.log(`07C integrity PASS: ${Object.keys(baseline.unchanged).length} accepted source/test hashes; precise terrain/style seams; one owner, inert backdrop, LOD/restoration; native art NOT VERIFIED`);
