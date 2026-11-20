// V1-03 Studio-memory-only alchemy overlay stacked after V1-02 garden overlay.
import assert from "node:assert/strict";
function swap(input,oldText,newText,why){
 const found=input.split(oldText);
 assert.equal(found.length,2,"V1-03 adapter drift: "+why);
 return found.join(newText);
}
export function applyAlchemyV1({project,read,write,path}){
 const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared;
 const server=project.tree.ServerScriptService.PotionTycoon;
 const client=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
 shared.AlchemyCatalog={$path:path("qa/alchemy_v1/Catalog.luau")};
 shared.AlchemyV1={$path:path("qa/alchemy_v1/AlchemyV1.luau")};
 let config=read(shared.Config.$path);
 config=swap(config,"return Config",
  'Config.alchemyV1QA=true\n'+
  'Config.alchemyV1=require(runtimeScript and runtimeScript.Parent.AlchemyCatalog or "../../qa/alchemy_v1/Catalog")\n'+
  'Config.firstSession.tutorialSteps={"familiar","essence","garden","seeds","crop","cauldron","brew","sale"}\n'+
  'return Config',"source catalog, no change to persistent V8");
 shared.Config=write("Config",config);
 let factory=read(shared.Factory.$path);
 factory=swap(factory,"local Factory = {}",
  'local AlchemyV1=require(runtimeScript and runtimeScript.Parent.AlchemyV1 or "../../qa/alchemy_v1/AlchemyV1")\nlocal Factory = {}',
  "reusable pure alchemy engine");
 factory=swap(factory,
  '\t\tlocal gardenValid,gardenReason=GardenV1.validate(profile,config)',
  '\t\tlocal alchemyValid,alchemyReason=AlchemyV1.validate(profile,config)\n'+
  '\t\tif not alchemyValid then return false,alchemyReason end\n'+
  '\t\tlocal gardenValid,gardenReason=GardenV1.validate(profile,config)',
  "new saved state validation before any mutation");
 factory=swap(factory,
  '\t\tif GardenV1.active(config,profile) then\n\t\t\tGardenV1.tick',
  '\t\tAlchemyV1.tick(profile,config,now)\n'+
  '\t\tif GardenV1.active(config,profile) then\n\t\t\tGardenV1.tick',
  "offline and online alchemy job processing");
 factory=swap(factory,
  '\t\tplantCrop={bedId=true,cropId=true},waterCrop={bedId=true},buyCropSeed={cropId=true,amount=true},',
  '\t\tplantCrop={bedId=true,cropId=true},waterCrop={bedId=true},buyCropSeed={cropId=true,amount=true},\n'+
  '\t\tcraftPotion={recipeId=true,optionalId=true},buyAlchemySupply={itemId=true,amount=true},sellPotion={potionId=true},',
  "alchemy intent allowlist");
 factory=swap(factory,
  '\t\tif fields.recipeId and not config.recipes[payload.recipeId] then return false end',
  '\t\tif fields.recipeId and not config.recipes[payload.recipeId] and not\n'+
  '\t\t\t(action=="craftPotion" and config.alchemyV1QA and config.alchemyV1.recipes[payload.recipeId]) then return false end',
  "prevent forged recipe IDs");
 factory=swap(factory,
  '\t\tif fields.itemId and (not config.items[payload.itemId] or config.items[payload.itemId].kind == "potion") then return false end',
  '\t\tif fields.itemId and action=="buyAlchemySupply" then\n'+
  '\t\t\tif not (config.alchemyV1QA and config.alchemyV1.supplies[payload.itemId]) then return false end\n'+
  '\t\telseif fields.itemId and (not config.items[payload.itemId] or config.items[payload.itemId].kind == "potion") then return false end',
  "allow only registered gold reagents");
 factory=swap(factory,
  '\t\tif GardenV1.active(config,profile) and (action=="plantSeed"',
  '\t\tif AlchemyV1.active(config,profile) then\n'+
  '\t\t\tif action=="craftPotion" or action=="buyAlchemySupply" or action=="sellPotion" then\n'+
  '\t\t\t\treturn AlchemyV1.apply(profile,config,action,payload,now)\n'+
  '\t\t\tend\n'+
  '\t\t\tif action=="brew" or action=="load" or action=="setRecipe" or action=="setAuto" then\n'+
  '\t\t\t\treturn false,"Use the Potion Book for V1 brewing"\n'+
  '\t\t\tend\n'+
  '\t\t\tif action=="buyAutomation" then return false,"Alchemy automation is not implemented in V1-03" end\n'+
  '\t\tend\n'+
  '\t\tif GardenV1.active(config,profile) and (action=="plantSeed"',
  "V1 uses only new recipe engine, historic profiles stay on old workflows");
 factory=swap(factory,
  'if not station.job and station.auto and (automationOn(profile, "brew") or (station.workerId and not AlchemyFirst.active(config,profile))) then',
  'if not AlchemyV1.active(config,profile) and not station.job and station.auto and (automationOn(profile, "brew") or (station.workerId and not AlchemyFirst.active(config,profile))) then',
  "do not sell new potions via legacy automatic jobs");
 factory=swap(factory,
  '\t\tif automationOn(profile, "supply") then\n\t\t\tfor _, stationId in ipairs(config.machineOrder)',
  '\t\tif automationOn(profile, "supply") and not AlchemyV1.active(config,profile) then\n\t\t\tfor _, stationId in ipairs(config.machineOrder)',
  "do not move new recipe ingredients to obsolete cauldron buffers");
 factory=swap(factory,
  '\t\tif not job then\n\t\t\tbeginHaul(profile)\n\t\t\treturn\n\t\tend',
  '\t\tif not job then\n\t\t\tif not AlchemyV1.active(config,profile) then beginHaul(profile) end\n\t\t\treturn\n\t\tend',
  "finish saved hauls but do not steal garden ingredients for old machines");
 factory=swap(factory,
  '\t\tif profile.pipes then\n\t\t\tlocal firstBuilt, nextBuilt',
  '\t\tif profile.pipes and not AlchemyV1.active(config,profile) then\n\t\t\tlocal firstBuilt, nextBuilt',
  "stop obsolete pipe inputs during new brewing");
 factory=swap(factory,
  'brew = { "cauldron", "Загрузи Mandrake и Essence, затем свари Healing." },',
  'brew = { "cauldron", "В Книге Зелий выбери Настойку исцеления, купи воду и свари зелье." },',
  "guide complete first potion");
 factory=swap(factory,
  'sale = { "cauldron", "Продай Healing. Партия приносит " .. healing.goldValue .. " Gold." },',
  'sale = { "cauldron", "Найди готовое зелье в Книге и продай его вручную за Gold." },',
  "guide manual sale");
 shared.Factory=write("Factory",factory);
 let protocol=read(shared.Protocol.$path);
 protocol=swap(protocol,
  '\tplantCrop={bedId="id",cropId="id"},waterCrop={bedId="id"},',
  '\tplantCrop={bedId="id",cropId="id"},waterCrop={bedId="id"},\n'+
  '\tcraftPotion={recipeId="id",optionalId="id-or-empty"},buyAlchemySupply={itemId="id",amount="count"},\n'+
  '\tsellPotion={potionId="id"},',
  "closed remote schemas for crafting, reagents and owned-item sale");
 shared.Protocol=write("Protocol",protocol);
 let access=read(shared.Access.$path);
 access=swap(access,
  '\tif action == "plantSeed" or action == "harvestCrop" or action=="plantCrop"',
  '\tif action=="craftPotion" then return "cauldron" end\n'+
  '\tif action=="buyAlchemySupply" or action=="sellPotion" then return "warehouse" end\n'+
  '\tif action == "plantSeed" or action == "harvestCrop" or action=="plantCrop"',
  "enforce authenticated cauldron proximity and owner market access");
 shared.Access=write("Access",access);
 let serverMain=read(server.Main.$path);
 serverMain=swap(serverMain,
  'gardenV1=copy(profile.gardenV1),',
  'gardenV1=copy(profile.gardenV1), alchemyV1=copy(profile.alchemyV1),',
  "send only explicit owned potion state to book client");
 server.Main=write("Main.server",serverMain);
 let session=read(shared.FirstSessionView.$path);
 session=swap(session,
  'return action == "buySeed"',
  'return action == "buySeed" or action=="buyAlchemySupply" or action=="sellPotion"',
  "personal inventory/market remote shop");
 session=swap(session,
  '\tbrew = "Свари Healing.",',
  '\tbrew = "Свари настойку исцеления через Книгу Зелий.",',
  "guided book progression");
 session=swap(session,
  '\tsale = "Зелье продано. Gold уже на счёте.",',
  '\tsale = "Продай готовое зелье из Книги Зелий за Gold.",',
  "manual sale hint");
 const from=session.indexOf('\telseif step == "brew" then');
 const to=session.indexOf('\telseif step == "sale" and acknowledged == "brew" then',from);
 assert(from>=0&&to>from,"V1-03 tutorial brew action drift");
 session=session.slice(0,from)+'\telseif step == "brew" then\n\t\treturn {} -- Potion Book offers the authoritative craft action.\n'+session.slice(to);
 shared.FirstSessionView=write("FirstSessionView",session);
 let main=read(client.Main.$path);
 main=swap(main,
  '\t\telseif definition.defaultRecipe then\n\t\t\tlocal recipe = text("", 48)',
  '\t\telseif definition.defaultRecipe then\n'+
  '\t\t\tif workspace:GetAttribute("AlchemyV1QA")==true and stationId=="cauldron" then\n'+
  '\t\t\t\ttext("Настойки готовятся через Книгу Зелий. Список ингредиентов, качество, варка и продажа доступны там.",92)\n'+
  '\t\t\t\tlocal build=state.builds and state.builds.cauldron\n'+
  '\t\t\t\tif build and build.available then\n'+
  '\t\t\t\t\taction("Улучшить котёл · "..tostring(build.cost).." Gold",function()\n'+
  '\t\t\t\t\t\tsend("build",{upgradeId="cauldron",expectedLevel=getStation().level,requestId=state.progression.sequence+1})\n'+
  '\t\t\t\t\tend)\n'+
  '\t\t\t\tend\n'+
  '\t\t\t\trefresh();return\n'+
  '\t\t\tend\n'+
  '\t\t\tlocal recipe = text("", 48)',
  "suppress obsolete instant-selling cauldron interface");
 client.Main=write("Main.client",main);
 project.tree.StarterPlayer.StarterPlayerScripts.AlchemyPotionBook={
  $path:path("qa/alchemy_v1/PotionBook.client.luau")
 };
 project.tree.Workspace.$attributes.AlchemyV1QA=true;
}