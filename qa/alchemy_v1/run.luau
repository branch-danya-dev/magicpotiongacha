--!nonstrict
-- V1-03: test the same generated Factory used by the Studio-memory place.
local T=require("../../tests/Test")
local Config=require("../../build/alchemy/Config")
local Factory=require("../../build/alchemy/Factory")
local Alchemy=require("./AlchemyV1")
local engine=Factory.new(Config)
local catalog=Config.alchemyV1
local bed=Config.gardenV1.beds[1]
local function action(p,intent,payload,now)
 local ok,reason=engine.act(p,intent,payload,now)
 if not ok then error(intent..": "..tostring(reason)) end
 local valid,why=engine.validate(p)
 if not valid then error("invalid after "..intent..": "..tostring(why)) end
end
local function advance(p,to,offline)
 local outcome=engine.advance(p,to,offline)
 if not outcome.ok then error("advance failed: "..tostring(outcome.error)) end
 local valid,why=engine.validate(p)
 if not valid then error("invalid after tick: "..tostring(why)) end
 return outcome
end
local function fresh(uid,time,species,stations)
 local p=engine.newProfile(uid,time)
 T.truthy(engine.claimStarterBudget(p))
 action(p,"chooseStarter",{speciesId=species or "slime"},time)
 if stations~=false then
  action(p,"buyStarterStation",{stationId="garden"},time)
  action(p,"buyStarterStation",{stationId="cauldron"},time)
 end
 return p
end
local function supply(p,itemId,n,now)
 action(p,"buyAlchemySupply",{itemId=itemId,amount=n or 1},now)
end
local function readyMandrake(p,now)
 action(p,"buyCropSeed",{cropId="mandrake",amount=1},now)
 action(p,"plantCrop",{bedId=bed,cropId="mandrake"},now)
 action(p,"waterCrop",{bedId=bed},now)
 advance(p,now+90,false)
 action(p,"harvestCrop",{bedId=bed},now+90)
 advance(p,now+92,false)
end
T.test("V1-03: six ordered classes and quality stages, unique nonempty recipe definitions",function()
 T.equal(Config.schemaVersion,8)
 T.truthy(Config.alchemyV1QA)
 T.equal(#catalog.classes,6);T.equal(#catalog.quality,6)
 T.equal(catalog.classes[1].id,"novice")
 T.equal(catalog.classes[6].id,"grandmaster")
 local seen={}
 for _,id in ipairs(catalog.recipeOrder) do
  T.falsy(seen[id]);seen[id]=true
  local r=catalog.recipes[id]
  T.equal(r.id,id)
  T.truthy(catalog.classes[r.class]);T.truthy(r.base.id and r.base.amount>0)
  T.truthy(next(r.core)~=nil);T.truthy(r.duration>0 and r.essence>0)
  T.truthy(r.visual and r.visual.liquid and r.visual.flash)
 end
 T.equal(Alchemy.rank(Config,0),1)
 T.equal(Alchemy.rank(Config,3),2)
 T.equal(Alchemy.rank(Config,120),6)
end)
T.test("V1-03: real novice loop debits Gold/resources/Essence; creates potion, NOT instant Gold",function()
 local p=fresh(7301,1000,"slime")
 readyMandrake(p,1000)
 T.equal(p.inventory.mandrake,2)
 supply(p,"water",1,1092)
 local beforeGold=p.gold
 local beforeEssence=p.essence
 action(p,"craftPotion",{recipeId="healing",optionalId=""},1092)
 T.equal(p.gold,beforeGold)
 T.equal(p.essence,beforeEssence-catalog.recipes.healing.essence)
 T.equal(p.inventory.mandrake or 0,0)
 T.equal(p.alchemyV1.supplies.water or 0,0)
 T.equal(next(p.alchemyV1.owned),nil)
 advance(p,1098,false)
 local id="v1p:7301:1"
 local potion=p.alchemyV1.owned[id]
 T.truthy(potion);T.equal(potion.recipeId,"healing")
 T.equal(potion.quality,2);T.equal(potion.price,250)
 T.equal(p.gold,beforeGold);T.truthy(p.tutorial.brew)
 T.equal(p.alchemyV1.xp,1)
 action(p,"sellPotion",{potionId=id},1098)
 T.equal(p.gold,beforeGold+250)
 T.truthy(p.tutorial.sale)
 T.equal(p.alchemyV1.owned[id],nil)
 local ok=engine.act(p,"sellPotion",{potionId=id},1098)
 T.falsy(ok);T.equal(p.gold,beforeGold+250)
 T.equal(p.alchemyV1.xp,1)
end)
T.test("V1-03: no free alchemy materials, no Essence bypass, no double resource charge",function()
 local p=fresh(7302,2000,"farmer")
 p.inventory.mandrake=3
 local gold=p.gold
 local ok=engine.act(p,"craftPotion",{recipeId="healing",optionalId=""},2000)
 T.falsy(ok);T.equal(p.gold,gold);T.equal(p.inventory.mandrake,3)
 supply(p,"water",1,2000)
 local water=p.alchemyV1.supplies.water
 ok=engine.act(p,"craftPotion",{recipeId="healing",optionalId=""},2000)
 T.falsy(ok);T.equal(p.alchemyV1.supplies.water,water)
 T.equal(p.inventory.mandrake,3)
 advance(p,2015,false)
 action(p,"craftPotion",{recipeId="healing",optionalId=""},2015)
 local essence=p.essence
 ok=engine.act(p,"craftPotion",{recipeId="healing",optionalId=""},2015)
 T.falsy(ok);T.equal(p.essence,essence)
 T.equal(p.inventory.mandrake,1)
end)
T.test("V1-03: fire recipe optional Bayun whisker changes quality, rarity, value and visual metadata without owning cat",function()
 local p=fresh(7303,3000,"slime")
 p.inventory.mandrake=2
 supply(p,"water",2,3000)
 supply(p,"fire_salt",2,3000)
 supply(p,"bayun_whisker",1,3000)
 advance(p,3040,false)
 action(p,"craftPotion",{recipeId="fire_dance",optionalId=""},3040)
 advance(p,3050,false)
 local plain=p.alchemyV1.owned["v1p:7303:1"]
 T.truthy(plain);T.equal(plain.quality,2)
 T.equal(Alchemy.describe(Config,plain).visual.flash,"fire_sparks")
 local beforeGold=p.gold
 action(p,"craftPotion",{recipeId="fire_dance",optionalId="bayun_whisker"},3050)
 advance(p,3060,false)
 local enhanced=p.alchemyV1.owned["v1p:7303:2"]
 T.truthy(enhanced);T.equal(enhanced.quality,4)
 T.truthy(enhanced.price>plain.price)
 T.truthy(enhanced.rarity~=plain.rarity)
 local description=Alchemy.describe(Config,enhanced)
 T.truthy(description.name:find("Искра Баюна",1,true))
 T.equal(description.effectId,"fire_bayun_stub")
 T.equal(description.effectStrength,4)
 T.equal(p.gold,beforeGold)
 T.truthy(p.pets["7303:starter_slime"])
 T.falsy(p.pets["7303:starter_brewer"])
end)
T.test("V1-03: arctic biter grown in V1-02 is usable as Frost recipe core",function()
 local p=fresh(7304,4000)
 action(p,"buyCropSeed",{cropId="antarctic_biter",amount=1},4000)
 action(p,"plantCrop",{bedId=bed,cropId="antarctic_biter"},4000)
 action(p,"waterCrop",{bedId=bed},4000)
 advance(p,4160,false)
 T.equal(p.gardenV1.plots[bed].progress,125)
 action(p,"waterCrop",{bedId=bed},4160)
 advance(p,4285,false)
 action(p,"harvestCrop",{bedId=bed},4285)
 advance(p,4290,false)
 T.equal(p.inventory.antarctic_biter,3)
 supply(p,"water",1,4290)
 supply(p,"frost_salt",1,4290)
 action(p,"craftPotion",{recipeId="frost_tincture",optionalId=""},4290)
 advance(p,4304,true)
 T.truthy(p.alchemyV1.owned["v1p:7304:1"])
 T.equal(p.inventory.antarctic_biter,2)
end)
T.test("V1-03: ranked recipe needs both class XP and upgraded cauldron",function()
 local p=fresh(7305,5000)
 p.inventory.mandrake=10
 supply(p,"water",6,5000)
 advance(p,5200,false)
 local ok,reason=engine.act(p,"craftPotion",{recipeId="moon_echo",optionalId=""},5200)
 T.falsy(ok);T.equal(reason,"Alchemy rank too low")
 for i=1,3 do
  local t=5200+(i-1)*6
  action(p,"craftPotion",{recipeId="healing",optionalId=""},t)
  advance(p,t+6,false)
 end
 T.equal(p.alchemyV1.xp,3)
 T.equal(Alchemy.rank(Config,p.alchemyV1.xp),2)
 ok,reason=engine.act(p,"craftPotion",{recipeId="moon_echo",optionalId=""},5218)
 T.falsy(ok);T.equal(reason,"Upgrade cauldron first")
 p.stations.cauldron.level=2
 p.inventory.antarctic_biter=1
 supply(p,"moon_dew",1,5218)
 action(p,"craftPotion",{recipeId="moon_echo",optionalId=""},5218)
 advance(p,5246,false)
 local item=p.alchemyV1.owned["v1p:7305:4"]
 T.truthy(item);T.equal(item.recipeId,"moon_echo")
 T.truthy(engine.validate(p))
end)
T.test("V1-03: completed potion identity/price and stock are deterministic online/offline",function()
 local a=fresh(7306,6000)
 local b=fresh(7306,6000)
 for _,p in ipairs({a,b}) do
  p.inventory.mandrake=2
  supply(p,"water",1,6000)
  advance(p,6030,false)
  action(p,"craftPotion",{recipeId="healing",optionalId=""},6030)
 end
 advance(a,6036,false)
 advance(b,6036,true)
 local id="v1p:7306:1"
 T.equal(a.alchemyV1.owned[id].quality,b.alchemyV1.owned[id].quality)
 T.equal(a.alchemyV1.owned[id].price,b.alchemyV1.owned[id].price)
 T.equal(a.alchemyV1.owned[id].createdAt,b.alchemyV1.owned[id].createdAt)
 T.equal(a.essence,b.essence)
 T.equal(a.gold,b.gold)
 T.equal(a.alchemyV1.xp,b.alchemyV1.xp)
end)
T.test("V1-03: invalid recipe, modifier, supply and foreign potion ID never mint",function()
 local p=fresh(7307,7000)
 local before=p.gold
 for _,payload in ipairs({
  {recipeId="unknown",optionalId=""},{recipeId="fire_dance",optionalId="moon_dew"},
  {recipeId="moon_echo",optionalId=""},
 }) do
  local ok=engine.act(p,"craftPotion",payload,7000)
  T.falsy(ok)
 end
 local ok=engine.act(p,"buyAlchemySupply",{itemId="secret_material",amount=1},7000)
 T.falsy(ok)
 ok=engine.act(p,"sellPotion",{potionId="v1p:7306:1"},7000)
 T.falsy(ok)
 T.equal(p.gold,before)
 T.truthy(engine.validate(p))
end)
T.test("V1-03: full owned capacity preserves already paid craft; sale frees a slot exactly once",function()
 local p=fresh(7308,8000)
 p.inventory.mandrake=2
 supply(p,"water",1,8000)
 advance(p,8030,false)
 action(p,"craftPotion",{recipeId="healing",optionalId=""},8030)
 local state=p.alchemyV1
 local def=catalog.recipes.healing
 for serial=1,catalog.maxOwned do
  local id="v1p:7308:"..serial
  state.owned[id]={id=id,recipeId="healing",optionalId="",quality=2,
   rarity=Alchemy.rarity(Config,2,""),price=Alchemy.worth(Config,def,2,""),createdAt=8000}
 end
 state.nextSerial=catalog.maxOwned+1
 T.truthy(engine.validate(p))
 advance(p,8036,false)
 T.truthy(state.job)
 T.equal(state.job.progress,6)
 T.equal(state.xp,0)
 local sellId="v1p:7308:1"
 action(p,"sellPotion",{potionId=sellId},8036)
 T.truthy(state.job)
 advance(p,8037,false)
 T.equal(state.job,nil);T.equal(state.xp,1)
 T.truthy(state.owned["v1p:7308:81"])
 T.equal(#(function()local ids={};for k in pairs(state.owned) do table.insert(ids,k) end;return ids end)(),catalog.maxOwned)
 T.truthy(engine.validate(p))
end)
T.test("V1-03: legacy instant-sale path is closed for modern profiles but existing jobs settle",function()
 local p=fresh(7309,9000)
 local ok,reason=engine.act(p,"brew",{stationId="cauldron"},9000)
 T.falsy(ok);T.equal(reason,"Use the Potion Book for V1 brewing")
 ok=engine.act(p,"setAuto",{stationId="cauldron",enabled=true},9000)
 T.falsy(ok)
 p.stations.cauldron.auto=true
 p.discoveredRecipes.healing=true
 p.stations.cauldron.job={
  kind="brew",recipeId="healing",automatic=true,duration=6,
  doubleChance=0,outputQuantity=1}
 T.truthy(engine.validate(p))
 local oldGold=p.gold
 local first=advance(p,9006,false)
 T.equal(first.sold.healing,1)
 T.equal(p.gold,oldGold+Config.economyV2.healing.goldValue)
 local second=advance(p,9012,false)
 T.equal(second.sold.healing or 0,0)
 T.equal(p.alchemyV1.job,nil)
 T.truthy(engine.validate(p))
 local legacy=engine.newProfile(7310,9100)
 engine.grantHistoricalStarters(legacy)
 T.truthy(engine.advance(legacy,9101,false).ok)
 T.equal(legacy.alchemyV1,nil)
end)
T.finish()
