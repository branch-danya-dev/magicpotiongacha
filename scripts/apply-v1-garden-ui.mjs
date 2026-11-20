// UI-only companion patch to the server-authoritative V1 garden. No local currency writes.
import assert from "node:assert/strict";
export function attachGardenUi({shared,client,read,write,swap}){
 let session=read(shared.FirstSessionView.$path);
 session=swap(session,
  '\tcrop = "Посади семя и собери урожай.",',
  '\tcrop = "Посади, полей и собери урожай.",',
  "guide wording");
 session=swap(session,
  '\tif step == "crop" then\n\t\tlocal session = type(config) == "table" and config.firstSession or {}',
  '\tif step == "crop" then\n'+
  '\t\tif config.gardenV1QA and profile.gardenV1 then\n'+
  '\t\t\tlocal plot=profile.gardenV1.plots[config.firstSession.bedId]\n'+
  '\t\t\tif not plot then return "Посади мандрагору на первой грядке." end\n'+
  '\t\t\tlocal def=config.gardenV1.crops[plot.cropId]\n'+
  '\t\t\tif plot.progress>=def.growthSeconds then return plot.harvestProgress>=0 and "Идёт сбор урожая." or "Урожай созрел: собери его." end\n'+
  '\t\t\tlocal due=def.wateringAt[plot.wateredCount+1]\n'+
  '\t\t\tif due and plot.progress>=due then return "Полей грядку, чтобы продолжить рост." end\n'+
  '\t\t\treturn "Растение растёт. Следи за поливом." end\n'+
  '\t\tlocal session = type(config) == "table" and config.firstSession or {}',
  "guide growth/watering status");
 session=swap(session,
  '\telseif step == "crop" then\n\t\tlocal plant = profile.plants and profile.plants[bed]',
  '\telseif step == "crop" then\n'+
  '\t\tif config.gardenV1QA and profile.gardenV1 then\n'+
  '\t\t\tlocal plot=profile.gardenV1.plots[bed]\n'+
  '\t\t\tif not plot then return {{id="plant",label="Посадить мандрагору",action="plantCrop",payload={bedId=bed,cropId="mandrake"}}} end\n'+
  '\t\t\tlocal def=config.gardenV1.crops[plot.cropId]\n'+
  '\t\t\tlocal due=def.wateringAt[plot.wateredCount+1]\n'+
  '\t\t\tif due and plot.progress>=due then return {{id="water",label="Полить грядку",action="waterCrop",payload={bedId=bed}}} end\n'+
  '\t\t\tif plot.progress>=def.growthSeconds and plot.harvestProgress<0 then return {{id="harvest",label="Начать сбор",action="harvestCrop",payload={bedId=bed}}} end\n'+
  '\t\t\treturn {} end\n'+
  '\t\tlocal plant = profile.plants and profile.plants[bed]',
  "tutorial planting/irrigation/harvest intents");
 shared.FirstSessionView=write("FirstSessionView",session);
 let main=read(client.Main.$path);
 const marker='\t\t\tif stationId == "garden" and state.firstSession and state.starter and not state.starter.legacyGrant then';
 const suffix='\n\t\t\tend\n\t\telseif stationId == "logistics" then';
 const from=main.indexOf(marker),end=main.indexOf(suffix,from);
 assert(from>=0&&end>from&&main.indexOf(marker,from+1)===-1,"V1-02 garden UI seam drift");
 const old=main.slice(from,end+'\n\t\t\tend'.length);
 const originalBody=old.slice(marker.length,-'\n\t\t\tend'.length);
 const lines=[
 '\t\t\t\tif workspace:GetAttribute("GardenV1QA")==true then',
 '\t\t\t\t\tlocal cfg=Config.gardenV1',
 '\t\t\t\t\tlocal garden=state.gardenV1 or {ownedBeds=1,sprinkler=false,plots={}}',
 '\t\t\t\t\ttext("Огород · "..(garden.sprinkler and "автоматический полив" or "ручной полив"),30)',
 '\t\t\t\t\tfor i,bedId in ipairs(cfg.beds) do',
 '\t\t\t\t\t\tif i<=garden.ownedBeds then',
 '\t\t\t\t\t\t\tlocal growing=garden.plots[bedId]',
 '\t\t\t\t\t\t\tif growing then',
 '\t\t\t\t\t\t\t\tlocal def=cfg.crops[growing.cropId]',
 '\t\t\t\t\t\t\t\tlocal due=def.wateringAt[growing.wateredCount+1]',
 '\t\t\t\t\t\t\t\tlocal status=" · рост"',
 '\t\t\t\t\t\t\t\tif growing.harvestProgress>=0 then status=" · сбор "..growing.harvestProgress.."/"..def.harvestSeconds',
 '\t\t\t\t\t\t\t\telseif growing.progress>=def.growthSeconds then status=" · урожай готов"',
 '\t\t\t\t\t\t\t\telseif due and growing.progress>=due then status=" · нужен полив" end',
 '\t\t\t\t\t\t\t\ttext("Грядка "..i..": "..def.name.." "..growing.progress.."/"..def.growthSeconds.." с"..status,54)',
 '\t\t\t\t\t\t\t\tif due and growing.progress>=due then',
 '\t\t\t\t\t\t\t\t\taction("Полить грядку "..i,function() send("waterCrop",{bedId=bedId}) end)',
 '\t\t\t\t\t\t\t\tend',
 '\t\t\t\t\t\t\t\tif growing.progress>=def.growthSeconds and growing.harvestProgress<0 then',
 '\t\t\t\t\t\t\t\t\taction("Собрать с грядки "..i,function() send("harvestCrop",{bedId=bedId}) end)',
 '\t\t\t\t\t\t\t\tend',
 '\t\t\t\t\t\t\telse',
 '\t\t\t\t\t\t\t\ttext("Грядка "..i.." · пусто",28)',
 '\t\t\t\t\t\t\t\tfor _,cropId in ipairs({"mandrake","antarctic_biter"}) do',
 '\t\t\t\t\t\t\t\t\tlocal def=cfg.crops[cropId]',
 '\t\t\t\t\t\t\t\t\taction("Посадить: "..def.name.." ("..tostring(state.seeds[cropId] or 0)..")",function()',
 '\t\t\t\t\t\t\t\t\t\tsend("plantCrop",{bedId=bedId,cropId=cropId})',
 '\t\t\t\t\t\t\t\t\tend)',
 '\t\t\t\t\t\t\t\tend',
 '\t\t\t\t\t\t\tend',
 '\t\t\t\t\t\tend',
 '\t\t\t\t\tend',
 '\t\t\t\t\tfor _,cropId in ipairs({"mandrake","antarctic_biter"}) do',
 '\t\t\t\t\t\tlocal def=cfg.crops[cropId]',
 '\t\t\t\t\t\taction("Семя: "..def.name.." · "..def.seedCost.." Gold",function()',
 '\t\t\t\t\t\t\tsend("buyCropSeed",{cropId=cropId,amount=1})',
 '\t\t\t\t\t\tend)',
 '\t\t\t\t\tend',
 '\t\t\t\t\tif garden.ownedBeds<#cfg.beds then',
 '\t\t\t\t\t\tlocal nextBed=garden.ownedBeds+1',
 '\t\t\t\t\t\taction("Построить грядку "..nextBed.." · "..cfg.bedPrices[nextBed].." Gold",function()',
 '\t\t\t\t\t\t\tsend("buyGardenBed",{bedId=cfg.beds[nextBed]})',
 '\t\t\t\t\t\tend)',
 '\t\t\t\t\tend',
 '\t\t\t\t\tif not garden.sprinkler then',
 '\t\t\t\t\t\taction("Автоматический полив · "..cfg.sprinklerCost.." Gold",function() send("buySprinkler",{}) end)',
 '\t\t\t\t\tend',
 '\t\t\t\telse'
 ];
 const updated=marker+'\n'+lines.join('\n')+originalBody+'\n\t\t\t\tend\n\t\t\tend';
 main=main.slice(0,from)+updated+main.slice(end+'\n\t\t\tend'.length);
 client.Main=write("Main.client",main);
}