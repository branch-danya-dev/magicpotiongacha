// Dedicated Studio-only game variant. Inherited forest and all production source remain intact.
import assert from 'node:assert/strict';
import {readFileSync, writeFileSync, mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p);
const read=p=>readFileSync(path(p),'utf8').replaceAll('\r\n','\n');
const hash=b=>createHash('sha256').update(b).digest('hex');
const git=()=>execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim();
const ownerArg=process.argv.find(a=>a.startsWith('--owner-user-id='));
assert(ownerArg,'Provide --owner-user-id for Studio memory mode');
const owner=Number(ownerArg.split('=')[1]);
assert(Number.isSafeInteger(owner) && owner!==0,'Invalid explicit owner');
const head=git();
if(!process.argv.includes('--reuse-forest')) {
 execFileSync(process.execPath,['scripts/build-forest.mjs',ownerArg],{cwd:root,stdio:'inherit'});
}
const previous=JSON.parse(read('build/forest/build.json'));
assert.equal(previous.head,head,'Forest input must come from this exact HEAD');
assert.equal(previous.owner,owner,'Forest input belongs to a different QA owner');
assert.equal(hash(readFileSync(path(previous.artifact))),previous.sha256,'Forest build content drift');
const project=JSON.parse(read('build/forest/game.project.json'));
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared;
const server=project.tree.ServerScriptService.PotionTycoon;
const client=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
mkdirSync(path('build/alchemy'),{recursive:true});
const generated=[];
function write(name,text) {
 const file='build/alchemy/'+name+'.luau';
 writeFileSync(path(file),text);
 generated.push(file);
 return {$path:path(file)};
}
function replaceOnce(source,from,to,context) {
 const pieces=source.split(from);
 assert.equal(pieces.length,2,'Alchemy adapter drift: '+context);
 return pieces.join(to);
}
// The QA config has a small level-1 passive rate; subsequent V2 tiers stay as designed.
let config=read(shared.Config.$path);
config=replaceOnce(config,'\teconomyV2 = {','\talchemyFirstQA = true,\n\teconomyV2 = {','feature flag');
config=replaceOnce(config,'passiveEssence = { 0, 2, 6, 18, 48 }',
 'passiveEssence = { 1, 2, 6, 18, 48 }','V2 first passive tier');
shared.Config=write('Config',config);
shared.AlchemyFirstPolicy={$path:path('qa/alchemy/Policy.luau')};
// Use the existing deterministic one-second online/offline simulator. Manual Essence
// intents are denied on the server for V2, not merely hidden in the client.
let factory=read(shared.Factory.$path);
factory=replaceOnce(factory,'local Factory = {}',
 'local AlchemyFirst = require(runtimeScript and runtimeScript.Parent.AlchemyFirstPolicy or "../../qa/alchemy/Policy")\nlocal Factory = {}','factory policy import');
factory=replaceOnce(factory,'\t\t\tearn(profile, "essence", gain, summary)',
 '\t\t\tearn(profile, "essence", gain, summary)\n\t\t\tif AlchemyFirst.active(config,profile) then AlchemyFirst.received(profile,gain) end',
 'server-paid passive Essence');
factory=replaceOnce(factory,'\t\telseif action == "click" then',
 '\t\telseif action == "click" then\n\t\t\tif AlchemyFirst.active(config,profile) then return false, "Essence accumulates automatically" end',
 'deny legacy click for V2');
// Generated module lives in build/alchemy, so CLI tests need corrected fallback
// paths. In Roblox the existing script.Parent lookups take precedence.
for(const module of ['Familiars','LegacyConfig','Progression','Trading','Epochs','Dailies','LongTerm','Monetization']) {
 factory=replaceOnce(factory,'or "./'+module+'"','or "../../src/shared/'+module+'"','portable '+module);
}
factory=replaceOnce(factory,
 'essence = { "crystal", "Собери Essence кликом. Для первого Healing нужно " .. healing.essenceCost .. "." },',
 'essence = { "crystal", "Essence накапливается сама (+1/с). Для первого Healing нужно " .. healing.essenceCost .. "." },',
 'passive Essence onboarding text');
factory=replaceOnce(factory,
 'passive = { "crystal", "Улучши кристалл. Следующий уровень даёт пассивную Essence и держит цепочку без кликов." },',
 'passive = { "crystal", "Улучши кристалл, чтобы увеличить пассивный поток Essence и ускорить варку." },',
 'passive upgrade onboarding text');
shared.Factory=write('Factory',factory);
// Tutorial automatically advances once Essence is earned, without a false click.
let session=read(shared.FirstSessionView.$path);
session=replaceOnce(session,
 'function View.line(profile, config, acknowledged)\n\tlocal step = View.displayStep(acknowledged, profile, config)',
 'function View.line(profile, config, acknowledged)\n\tlocal step = View.displayStep(acknowledged, profile, config)\n\tif step=="essence" and config.alchemyFirstQA then return "Essence поступает автоматически: +1 в секунду. Готовься к первой варке." end',
 'tutorial passive explanation');
session=replaceOnce(session,
 'if step == "essence" then\n\t\treturn { { id = "essence", label = "Собрать Essence", action = "click", payload = {} } }',
 'if step == "essence" then\n\t\tif config.alchemyFirstQA then return {} end\n\t\treturn { { id = "essence", label = "Собрать Essence", action = "click", payload = {} } }',
 'remove tutorial click intent');
shared.FirstSessionView=write('FirstSessionView',session);
// Reuse the existing authenticated station prompts and Factory buy/plant/load/brew intents.
let island=read(server.PersonalIslandWorld.$path);
island=replaceOnce(island,
 'prompt.ActionText=id=="crystal" and "+5 Essence" or "Управление"',
 'prompt.ActionText=id=="crystal" and "Источник Essence" or "Управление"',
 'crystal prompt copy');
island=replaceOnce(island,
 'if id=="crystal" then self.callbacks.action(actor,"click",{}) else self.callbacks.focus(actor,id) end',
 'self.callbacks.focus(actor,id)',
 'crystal no longer grants on prompt');
island=replaceOnce(island,
 '\tArt.attach(self.root,plot)\n\tLectern.ensure(plot,plot.anchors.crystal)',
 '\tArt.attach(self.root,plot)\n\trequire(script.Parent.AlchemyStarterProps).attach(plot)\n\tLectern.ensure(plot,plot.anchors.crystal)',
 'placeholder integration');
island=replaceOnce(island,
 'if id~="crystal" then\n\t\t\tif station.level>0 and not plot.props[id] then',
 'if id~="crystal" and id~="cauldron" and id~="garden" then\n\t\t\tif station.level>0 and not plot.props[id] then',
 'retain placeholder art instead of overlapping station models');
island=replaceOnce(island,
 'prompt.ActionText="+"..tostring(profile.starter and not profile.starter.legacyGrant and self.config.economyV2.clickEssence or self.config.manualClickEssence).." Essence"',
 'prompt.ActionText="Источник Essence"',
 'crystal prompt update does not reintroduce manual click');
server.PersonalIslandWorld=write('PersonalIslandWorld',island);
server.AlchemyStarterProps={$path:path('qa/alchemy/Props.luau')};
// The former click affordance is removed, not repurposed to award Essence on-device.
let main=read(client.Main.$path);
main=replaceOnce(main,
 '\t\tif stationId == "crystal" then\n\t\t\tlocal click=action("",function() send("click",{}) end)\n\t\t\tbindText(click,function() return "Собрать эссенцию +"..state.longTerm.manualClickEssence end)',
 '\t\tif stationId == "crystal" then\n\t\t\tif workspace:GetAttribute("AlchemyFirstQA")==true and state.starter and not state.starter.legacyGrant then\n\t\t\t\ttext("Источник Essence работает сам: +1 Essence в секунду на первом уровне. Улучшения увеличивают скорость.",76)\n\t\t\telse\n\t\t\t\tlocal click=action("",function() send("click",{}) end)\n\t\t\t\tbindText(click,function() return "Собрать эссенцию +"..state.longTerm.manualClickEssence end)\n\t\t\tend',
 'remove legacy crystal action from V2 panel');
client.Main=write('Main.client',main);
let arcade=read(client.ArcadeHUD.$path);
arcade=replaceOnce(arcade,
 'subtitle.Text="Уровень "..data.level.." · Магия начинается здесь"; perTap.Text="+"..data.amount.." Essence за касание"',
 'subtitle.Text="Уровень "..data.level.." · Магия начинается здесь"; perTap.Text=workspace:GetAttribute("AlchemyFirstQA")==true and "Essence: +1/с автоматически" or ("+"..data.amount.." Essence за касание")',
 'arcade passive subtitle');
arcade=replaceOnce(arcade,
 'collectText.Text="Собрать +"..data.amount; upgradeText.Text=data.upgradeText',
 'collectText.Text=workspace:GetAttribute("AlchemyFirstQA")==true and "Essence автоматически" or ("Собрать +"..data.amount); upgradeText.Text=data.upgradeText',
 'arcade collect text');
arcade=replaceOnce(arcade,
 'enable(collect,data.canCollect); enable(upgrade,data.upgrade.enabled); enable(confirm,data.canChoose)',
 'enable(collect,data.canCollect and workspace:GetAttribute("AlchemyFirstQA")~=true); enable(upgrade,data.upgrade.enabled); enable(confirm,data.canChoose)',
 'arcade click disabled');
arcade=replaceOnce(arcade,
 'collect.BackgroundTransparency=data.canCollect and 0 or .45; upgrade.BackgroundTransparency=data.upgrade.enabled and 0 or .45',
 'collect.Visible=workspace:GetAttribute("AlchemyFirstQA")~=true; collect.BackgroundTransparency=data.canCollect and 0 or .45; upgrade.BackgroundTransparency=data.upgrade.enabled and 0 or .45',
 'arcade click hidden');
client.ArcadeHUD=write('ArcadeHUD',arcade);
project.tree.StarterPlayer.StarterPlayerScripts.AlchemyPotionBook={$path:path('qa/alchemy/PotionBook.client.luau')};
project.tree.Workspace.$attributes.AlchemyFirstQA=true;
project.name='PotionTycoon-Alchemy-First';
const output='build/alchemy/game.project.json',artifact='build/PotionTycoon-Alchemy-First-QA.rbxlx';
writeFileSync(path(output),JSON.stringify(project,null,2)+'\n');
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),
 ['build',path(output),'-o',path(artifact)],{cwd:root,stdio:'inherit'});
const bytes=readFileSync(path(artifact));
for(const marker of ['AlchemyFirstQA','Essence accumulates automatically','BrewingCube','HerbGarden','AlchemyPotionBook']){
 assert(bytes.includes(marker),'Missing from Studio artifact: '+marker);
}
const codeSHA256=hash(Buffer.from(generated.map(file=>file+'\n'+read(file)).join('\n')));
const receipt={head,owner,artifact,bytes:bytes.length,sha256:hash(bytes),codeSHA256,
 inheritedForestSHA256:previous.sha256,firstLevelPassivePerSecond:1,
 prototype:{cauldronCube:true,garden:true,emptyPotionBook:true,clickDisabledForV2:true},
 mainOrLiveIntegrated:false,studioOnly:true,memoryOnly:true,uploads:0,paidFeatures:false,
 qaStatus:'CODE BUILD; NORMAL STUDIO F5 / OWNER REVIEW / MOBILE NOT RUN'};
writeFileSync(path('build/alchemy/build.json'),JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify(receipt,null,2));
