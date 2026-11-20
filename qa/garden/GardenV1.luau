--!nonstrict
-- V1-02 pure, deterministic, server-owned gardening. The visual scene merely reads state.
-- The adapter is intentionally Studio-memory only: gameplay schema V8 release is unchanged.
local Garden = {}
local function integer(v,low,high)
 return type(v)=="number" and v==v and v%1==0 and v>=low and v<=high
end
local function plain(v)
 return type(v)=="table" and getmetatable(v)==nil
end
local function exact(v,required)
 if not plain(v) then return false end
 for k in pairs(v) do if not required[k] then return false end end
 for k in pairs(required) do if v[k]==nil then return false end end
 return true
end
function Garden.active(config,profile)
 return type(config)=="table" and config.gardenV1QA==true
  and type(config.gardenV1)=="table" and type(profile)=="table"
  and type(profile.starter)=="table" and profile.starter.legacyGrant~=true
end
local function configOf(config)
 return config.gardenV1
end
local function crop(config,id)
 return configOf(config).crops[id]
end
local function bedIndex(config,id)
 for i,bed in ipairs(configOf(config).beds) do
  if bed==id then return i end
 end
 return nil
end
local function state(profile)
 return profile.gardenV1
end
function Garden.bootstrap(profile,config)
 if not Garden.active(config,profile) then return end
 if state(profile) then return end
 local plots={}
 -- The old single-bed V8 crop is conservatively moved, never copied or regranted.
 local old=profile.plants[config.firstSession.bedId]
 if old then
  local definition=crop(config,"mandrake")
  local progress=math.floor(old.progress*definition.growthSeconds/old.duration)
  progress=math.clamp(progress,0,definition.growthSeconds)
  plots[config.firstSession.bedId]={
   cropId="mandrake",plantedAt=old.plantedAt,progress=progress,
   wateredCount=1,harvestProgress=-1,
  }
  profile.plants[config.firstSession.bedId]=nil
 end
 profile.gardenV1={ownedBeds=1,sprinkler=false,plots=plots}
end
function Garden.validate(profile,config)
 if not Garden.active(config,profile) then return true end
 local s=state(profile)
 if s==nil then return true end -- old V8 data is lazily migrated at first action/tick
 if not exact(s,{ownedBeds=true,sprinkler=true,plots=true})
  or not integer(s.ownedBeds,1,#configOf(config).beds)
  or type(s.sprinkler)~="boolean" or not plain(s.plots) then
  return false,"Invalid V1 garden state"
 end
 if next(profile.plants)~=nil then return false,"Duplicate legacy crop and V1 garden" end
 for id,p in pairs(s.plots) do
  local ix=bedIndex(config,id)
  if not ix or ix>s.ownedBeds or not exact(p,{
    cropId=true,plantedAt=true,progress=true,wateredCount=true,harvestProgress=true,
   }) then return false,"Invalid V1 garden plot" end
  local def=crop(config,p.cropId)
  if not def or not integer(p.plantedAt,0,config.maxTimestamp)
   or not integer(p.progress,0,def.growthSeconds)
   or not integer(p.wateredCount,0,#def.wateringAt)
   or not integer(p.harvestProgress,-1,def.harvestSeconds) then
   return false,"Invalid V1 crop progress"
  end
  local nextWater=def.wateringAt[p.wateredCount+1]
  if nextWater and p.progress>nextWater then return false,"V1 crop crossed unwatered checkpoint" end
  if p.harvestProgress>=0 and p.progress<def.growthSeconds then
   return false,"V1 premature harvest"
  end
 end
 return true
end
local function built(profile)
 return profile.stations.garden and profile.stations.garden.level>=1
end
function Garden.action(profile,config,action,payload,now,availableRoom)
 if not Garden.active(config,profile) then return false,"Garden V1 unavailable" end
 if not built(profile) then return false,"Buy the garden first" end
 Garden.bootstrap(profile,config)
 local s=state(profile);local c=configOf(config)
 if action=="buyCropSeed" then
  local def=crop(config,payload.cropId)
  if not def or not integer(payload.amount,1,config.maxCount) then return false,"Invalid crop seed" end
  if profile.stations.garden.level<def.requiredGardenLevel then return false,"Upgrade garden first" end
  local cost=payload.amount*def.seedCost
  if not integer(cost,1,config.maxBalance) or profile.gold<cost then return false,"Not enough gold" end
  if (profile.seeds[payload.cropId] or 0)+payload.amount>config.maxCount then return false,"Seed limit reached" end
  profile.gold-=cost
  profile.seeds[payload.cropId]=(profile.seeds[payload.cropId] or 0)+payload.amount
  profile.tutorial.seeds=true
  return true,"Seeds purchased"
 elseif action=="buyGardenBed" then
  local nextIndex=s.ownedBeds+1
  if nextIndex>#c.beds or payload.bedId~=c.beds[nextIndex] then return false,"Next bed unavailable" end
  local price=c.bedPrices[nextIndex]
  if profile.gold<price then return false,"Not enough gold" end
  profile.gold-=price;s.ownedBeds=nextIndex
  return true,"Garden bed constructed"
 elseif action=="buySprinkler" then
  if s.sprinkler then return true,"Automatic watering already unlocked" end
  if profile.gold<c.sprinklerCost then return false,"Not enough gold" end
  profile.gold-=c.sprinklerCost;s.sprinkler=true
  return true,"Automatic watering unlocked"
 elseif action=="plantCrop" then
  local ix=bedIndex(config,payload.bedId)
  local def=crop(config,payload.cropId)
  if not ix or ix>s.ownedBeds or not def then return false,"Invalid crop or bed" end
  if profile.stations.garden.level<def.requiredGardenLevel then return false,"Upgrade garden first" end
  if s.plots[payload.bedId] then return false,"Bed is occupied" end
  if (profile.seeds[payload.cropId] or 0)<1 then return false,"No seeds" end
  profile.seeds[payload.cropId]-=1
  if profile.seeds[payload.cropId]==0 then profile.seeds[payload.cropId]=nil end
  s.plots[payload.bedId]={cropId=payload.cropId,plantedAt=math.floor(now),
   progress=0,wateredCount=0,harvestProgress=-1}
  return true,"Crop planted"
 elseif action=="waterCrop" then
  local plot=s.plots[payload.bedId]
  if not plot then return false,"Nothing planted" end
  local def=crop(config,plot.cropId)
  local checkpoint=def.wateringAt[plot.wateredCount+1]
  if checkpoint==nil or plot.progress<checkpoint then return false,"Crop does not need water yet" end
  plot.wateredCount+=1
  return true,"Crop watered"
 elseif action=="harvestCrop" then
  local plot=s.plots[payload.bedId]
  if not plot then return false,"Nothing planted" end
  local def=crop(config,plot.cropId)
  if plot.progress<def.growthSeconds then return false,"Crop is still growing" end
  if plot.harvestProgress>=0 then return false,"Harvest already started" end
  if availableRoom(plot.cropId,def.yieldAmount)<def.yieldAmount then return false,"Raw storage is full" end
  plot.harvestProgress=0
  return true,"Harvest started"
 end
 return false,"Unknown garden action"
end
function Garden.tick(profile,config,now,summary,availableRoom)
 if not Garden.active(config,profile) then return end
 Garden.bootstrap(profile,config)
 local s=state(profile)
 if not built(profile) then return end
 for _,id in ipairs(configOf(config).beds) do
  local p=s.plots[id]
  if p then
   local def=crop(config,p.cropId)
   if p.progress<def.growthSeconds then
    local due=def.wateringAt[p.wateredCount+1]
    if due~=nil and p.progress>=due and s.sprinkler then
     p.wateredCount+=1
     due=def.wateringAt[p.wateredCount+1]
    end
    if due==nil or p.progress<due then p.progress+=1 end
   elseif p.harvestProgress>=0 then
    p.harvestProgress=math.min(def.harvestSeconds,p.harvestProgress+1)
    if p.harvestProgress==def.harvestSeconds and availableRoom(p.cropId,def.yieldAmount)>=def.yieldAmount then
     profile.inventory[p.cropId]=(profile.inventory[p.cropId] or 0)+def.yieldAmount
     summary.produced[p.cropId]=(summary.produced[p.cropId] or 0)+def.yieldAmount
     s.plots[id]=nil
     profile.tutorial.crop=true;profile.tutorial.ingredients=true
    end
   end
  end
 end
end
return Garden
