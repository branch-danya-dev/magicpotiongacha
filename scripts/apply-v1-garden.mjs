// V1-02 generated Studio-memory gameplay overlay. Source files and release V8 stay intact.
import assert from "node:assert/strict";
import {attachGardenUi} from "./apply-v1-garden-ui.mjs";
function swap(source,oldText,newText,name){
 const pieces=source.split(oldText);
 assert.equal(pieces.length,2,"V1-02 adapter drift: "+name);
 return pieces.join(newText);
}
export function applyGardenV1({project,read,write,path}){
 const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared;
 const server=project.tree.ServerScriptService.PotionTycoon;
 const client=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
 shared.GardenCropCatalog={$path:path("qa/garden/Catalog.luau")};
 shared.GardenV1={$path:path("qa/garden/GardenV1.luau")};
 let config=read(shared.Config.$path);
 config=swap(config,"return Config",
  'local runtimeScript=rawget(getfenv(),"script")\n'+
  'Config.gardenV1QA=true\n'+
  'Config.gardenV1=require(runtimeScript and runtimeScript.Parent.GardenCropCatalog or "../../qa/garden/Catalog")\n'+
  'Config.items.antarctic_biter={name="Antarctic Biter",kind="raw",fluid=false}\n'+
  'return Config',"catalog and QA flag");
 shared.Config=write("Config",config);
 let factory=read(shared.Factory.$path);
 factory=swap(factory,"local Factory = {}",
  'local GardenV1=require(runtimeScript and runtimeScript.Parent.GardenV1 or "../../qa/garden/GardenV1")\nlocal Factory = {}',
  "garden module import");
 factory=swap(factory,
  'if id ~= seedItem or not integer(count, 1, config.maxCount) then return false, "Invalid seed inventory" end',
  'if (id ~= seedItem and not (GardenV1.active(config,profile) and config.gardenV1.crops[id])) or not integer(count, 1, config.maxCount) then return false, "Invalid seed inventory" end',
  "V8 seed validation for new crops");
 factory=swap(factory,
  '\t\tif profile.automation ~= nil then',
  '\t\tlocal gardenValid,gardenReason=GardenV1.validate(profile,config)\n\t\tif not gardenValid then return false,gardenReason end\n\t\tif profile.automation ~= nil then',
  "garden strict validation");
 factory=swap(factory,
  '\t\tgrowBed(profile)\n\t\tif automationOn(profile, "harvest") then harvestBed(profile, summary) end\n\t\trestockSeeds(profile)\n\t\tif automationOn(profile, "replant") then plantBed(profile, now) end',
  '\t\tif GardenV1.active(config,profile) then\n'+
  '\t\t\tGardenV1.tick(profile,config,now,summary,function(itemId,_amount) return inventoryRoom(profile,itemId) end)\n'+
  '\t\telse\n'+
  '\t\t\tgrowBed(profile)\n\t\t\tif automationOn(profile, "harvest") then harvestBed(profile, summary) end\n'+
  '\t\t\trestockSeeds(profile)\n\t\t\tif automationOn(profile, "replant") then plantBed(profile, now) end\n'+
  '\t\tend',"replace legacy garden tick in V1");
 factory=swap(factory,
  '\t\tclick = {}, chooseStarter = { speciesId = true }, plantSeed = { bedId = true }, harvestCrop = { bedId = true },',
  '\t\tclick = {}, chooseStarter = { speciesId = true }, plantSeed = { bedId = true }, harvestCrop = { bedId = true },\n'+
  '\t\tplantCrop={bedId=true,cropId=true},waterCrop={bedId=true},buyCropSeed={cropId=true,amount=true},\n'+
  '\t\tbuyGardenBed={bedId=true},buySprinkler={},',"garden payload registration");
 factory=swap(factory,
  '\t\tif fields.bedId and (type(config.firstSession) ~= "table" or payload.bedId ~= config.firstSession.bedId) then return false end',
  '\t\tif fields.bedId then\n'+
  '\t\t\tlocal allowed=type(config.firstSession)=="table" and payload.bedId==config.firstSession.bedId\n'+
  '\t\t\tif config.gardenV1QA then for _,id in ipairs(config.gardenV1.beds) do if id==payload.bedId then allowed=true end end end\n'+
  '\t\t\tif not allowed then return false end\n'+
  '\t\tend\n'+
  '\t\tif fields.cropId and (not config.gardenV1QA or not config.gardenV1.crops[payload.cropId]) then return false end',
  "allowlisted plot and crop IDs");
 factory=swap(factory,
  '\t\tif action == "chooseStarter" then',
  '\t\tif GardenV1.active(config,profile) and (action=="plantSeed" or action=="harvestCrop" or action=="plantCrop" or action=="waterCrop" or action=="buyCropSeed" or action=="buyGardenBed" or action=="buySprinkler") then\n'+
  '\t\t\tif action=="plantSeed" then action="plantCrop";payload={bedId=payload.bedId,cropId=config.firstSession.seedItem} end\n'+
  '\t\t\treturn GardenV1.action(profile,config,action,payload,now,function(itemId,_amount) return inventoryRoom(profile,itemId) end)\n'+
  '\t\tend\n\t\tif action == "chooseStarter" then',
  "redirect new garden intents to authoritative domain");
 factory=swap(factory,
  '\t\t\tif payload.feature == "basic" then',
  '\t\t\tif GardenV1.active(config,profile) and payload.feature=="basic" then\n'+
  '\t\t\t\tif profile.automation.brew and profile.automation.supply then return true,"Equipment automation already unlocked" end\n'+
  '\t\t\t\tif profile.gold<session.automationCost then return false,"Not enough gold" end\n'+
  '\t\t\t\tprofile.gold-=session.automationCost\n'+
  '\t\t\t\tprofile.automation.brew=true;profile.automation.supply=true\n'+
  '\t\t\t\tlocal cauldron=profile.stations.cauldron\n'+
  '\t\t\t\tif cauldron.recipeId and profile.discoveredRecipes[cauldron.recipeId] then cauldron.auto=true end\n'+
  '\t\t\t\tprofile.tutorial.automation=true\n'+
  '\t\t\t\treturn true,"Brewing equipment automation unlocked"\n'+
  '\t\t\tend\n\t\t\tif payload.feature == "basic" then',
  "semi-auto equipment, no plant/harvest skip");
 factory=swap(factory,
  'crop = { "garden", "Посади семя и дождись урожая. Одно семя даёт ингредиенты для одного Healing." },',
  'crop = { "garden", "Посади мандрагору, полей грядку и собери урожай." },',
  "tutorial crop hint");
 shared.Factory=write("Factory",factory);
 let protocol=read(shared.Protocol.$path);
 protocol=swap(protocol,'\tplantSeed = { bedId = "id" },',
  '\tplantSeed = { bedId = "id" },\n'+
  '\tplantCrop={bedId="id",cropId="id"},waterCrop={bedId="id"},\n'+
  '\tbuyCropSeed={cropId="id",amount="count"},buyGardenBed={bedId="id"},buySprinkler={},',
  "protocol declarations");
 shared.Protocol=write("Protocol",protocol);
 let access=read(shared.Access.$path);
 access=swap(access,
  'if action == "plantSeed" or action == "harvestCrop" then return "garden" end',
  'if action == "plantSeed" or action == "harvestCrop" or action=="plantCrop" or action=="waterCrop" or action=="buyCropSeed" or action=="buyGardenBed" or action=="buySprinkler" then return "garden" end',
  "garden server ownership/distance routing");
 shared.Access=write("Access",access);
 let serverMain=read(server.Main.$path);
 serverMain=swap(serverMain,
  '\t\tseeds = copy(profile.seeds), plants = copy(profile.plants),',
  '\t\tseeds = copy(profile.seeds), plants = copy(profile.plants), gardenV1=copy(profile.gardenV1),',
  "client-only safe garden view");
 server.Main=write("Main.server",serverMain);
 attachGardenUi({shared,client,read,write,swap});
 project.tree.Workspace.$attributes.GardenV1QA=true;
}
