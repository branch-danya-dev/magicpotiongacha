--!nonstrict
-- V1-03 pure server-authoritative recipe, quality and owned-potion engine.
-- QA-only state: a future live release MUST version its persistence migration.
local Alchemy={}
local function integer(x,lo,hi)
 return type(x)=="number" and x==x and x%1==0 and x>=lo and x<=hi
end
local function plain(x) return type(x)=="table" and getmetatable(x)==nil end
local function exact(x,required)
 if not plain(x) then return false end
 for k in pairs(x) do if not required[k] then return false end end
 for k in pairs(required) do if x[k]==nil then return false end end
 return true
end
local function count(t)
 local n=0;for _ in pairs(t) do n+=1 end;return n
end
local function catalog(config) return config.alchemyV1 end
local function have(map,id) return map[id] or 0 end
local function spend(map,id,n)
 map[id]=have(map,id)-n
 if map[id]==0 then map[id]=nil end
end
function Alchemy.active(config,profile)
 return type(config)=="table" and config.alchemyV1QA==true and type(config.alchemyV1)=="table"
  and type(profile)=="table" and type(profile.starter)=="table" and profile.starter.legacyGrant~=true
end
function Alchemy.bootstrap(profile,config)
 if not Alchemy.active(config,profile) or profile.alchemyV1 then return end
 local discovered={}
 -- Mirror only known, legitimate legacy discoveries; no free potion is granted.
 for id in pairs(catalog(config).recipes) do
  if profile.discoveredRecipes[id]==true then discovered[id]=true end
 end
 profile.alchemyV1={supplies={},owned={},discovered=discovered,job=nil,nextSerial=1,xp=0}
end
function Alchemy.rank(config,xp)
 local n=1
 for index,definition in ipairs(catalog(config).classes) do
  if xp>=definition.minXP then n=index end
 end
 return n
end
function Alchemy.quality(config,profile,recipe,optionalId)
 local grade=2
 if optionalId~="" then grade+=2 end
 if profile.stations.cauldron.level>=2 then grade+=1 end
 if Alchemy.rank(config,profile.alchemyV1.xp)>=2 then grade+=1 end
 return math.min(6,grade)
end
function Alchemy.rarity(config,grade,optionalId)
 local index=math.max(1,math.min(6,grade-1+(optionalId~="" and 1 or 0)))
 return catalog(config).rarity[index]
end
function Alchemy.worth(config,recipe,grade,optionalId)
 local quality=catalog(config).quality[grade]
 local bonus=optionalId~="" and 30 or 0
 return math.floor((recipe.goldValue*quality.factor)/100)+bonus
end
function Alchemy.describe(config,item)
 local recipe=catalog(config).recipes[item.recipeId]
 if not recipe then return nil end
 local grade=catalog(config).quality[item.quality]
 if not grade then return nil end
 local suffix=recipe.optional and item.optionalId==recipe.optional.id and (" — "..recipe.optional.suffix) or ""
 return {
  name=grade.name.." "..recipe.name..suffix,
  quality=grade.name,rarity=item.rarity,
  visual=recipe.visual, effectId=(item.optionalId~="" and recipe.optional.effectId or recipe.baseEffectId),
  effectDuration=(item.optionalId~="" and recipe.optional.effectDuration or 0),
  effectStrength=item.quality, -- Placeholder metadata, NOT an active gameplay buff.
 }
end
function Alchemy.validate(profile,config)
 if not Alchemy.active(config,profile) then return true end
 local state=profile.alchemyV1
 if state==nil then return true end
 if not exact(state,{supplies=true,owned=true,discovered=true,nextSerial=true,xp=true})
  and not exact(state,{supplies=true,owned=true,discovered=true,nextSerial=true,xp=true,job=true}) then
  return false,"Invalid alchemy state"
 end
 if not integer(state.nextSerial,1,config.maxCount) or not integer(state.xp,0,config.maxBalance)
  or not plain(state.supplies) or not plain(state.owned) or not plain(state.discovered) then
  return false,"Invalid alchemy inventory"
 end
 for id,amount in pairs(state.supplies) do
  if not catalog(config).supplies[id] or not integer(amount,1,catalog(config).maxSupplies) then
   return false,"Invalid alchemy supply"
  end
 end
 for id,done in pairs(state.discovered) do
  if not catalog(config).recipes[id] or done~=true then return false,"Invalid recipe discovery" end
 end
 if count(state.owned)>catalog(config).maxOwned then return false,"Potion storage full" end
 for id,potion in pairs(state.owned) do
  if type(id)~="string" or #id>80 or not exact(potion,{
   id=true,recipeId=true,optionalId=true,quality=true,rarity=true,price=true,createdAt=true,
  }) or potion.id~=id then return false,"Invalid potion item" end
  local recipe=catalog(config).recipes[potion.recipeId]
  if not recipe or not integer(potion.quality,1,6)
   or not integer(potion.createdAt,0,config.maxTimestamp)
   or not integer(potion.price,1,config.maxBalance)
   or (potion.optionalId~="" and (not recipe.optional or potion.optionalId~=recipe.optional.id))
   or potion.price~=Alchemy.worth(config,recipe,potion.quality,potion.optionalId)
   or potion.rarity~=Alchemy.rarity(config,potion.quality,potion.optionalId) then
   return false,"Invalid potion parameters"
  end
  local prefix=string.format("v1p:%.0f:",profile.userId)
  if id:sub(1,#prefix)~=prefix then return false,"Invalid potion owner" end
  local serial=tonumber(id:sub(#prefix+1))
  if not integer(serial,1,state.nextSerial-1) then return false,"Invalid potion serial" end
 end
 local job=state.job
 if job~=nil then
  if not exact(job,{recipeId=true,optionalId=true,progress=true,duration=true,quality=true,price=true})
   then return false,"Invalid alchemy job" end
  local recipe=catalog(config).recipes[job.recipeId]
  if not recipe or job.duration~=recipe.duration or not integer(job.progress,0,job.duration)
   or not integer(job.quality,1,6)
   or (job.optionalId~="" and (not recipe.optional or recipe.optional.id~=job.optionalId))
   or job.price~=Alchemy.worth(config,recipe,job.quality,job.optionalId) then
   return false,"Invalid alchemy job parameters"
  end
 end
 return true
end
function Alchemy.recipeState(profile,config,recipeId,optionalId)
 local recipe=catalog(config).recipes[recipeId]
 if not recipe then return nil,"Unknown potion recipe" end
 local state=profile.alchemyV1
 local rank=Alchemy.rank(config,state.xp)
 if rank<recipe.class then return nil,"Alchemy rank too low" end
 if not profile.stations.cauldron or profile.stations.cauldron.level<recipe.minCauldron then
  return nil,"Upgrade cauldron first"
 end
 if profile.stations.cauldron.job then return nil,"Cauldron is busy with previous batch" end
 if optionalId~="" and (not recipe.optional or recipe.optional.id~=optionalId) then
  return nil,"Invalid optional ingredient"
 end
 local requirements={}
 local function add(id,amount) requirements[id]=(requirements[id] or 0)+amount end
 add(recipe.base.id,recipe.base.amount)
 for id,n in pairs(recipe.core) do add(id,n) end
 if optionalId~="" then add(recipe.optional.id,recipe.optional.amount) end
 return {recipe=recipe,requires=requirements,optionalId=optionalId}
end
function Alchemy.apply(profile,config,action,payload,now)
 if not Alchemy.active(config,profile) then return false,"Alchemy V1 unavailable" end
 Alchemy.bootstrap(profile,config)
 local state=profile.alchemyV1
 if action=="buyAlchemySupply" then
  local def=catalog(config).supplies[payload.itemId]
  if not def or not integer(payload.amount,1,config.maxCount) then return false,"Unknown alchemy supply" end
  local cost=def.gold*payload.amount
  if not integer(cost,1,config.maxBalance) or profile.gold<cost then return false,"Not enough gold" end
  if have(state.supplies,payload.itemId)+payload.amount>catalog(config).maxSupplies then
   return false,"Supply capacity reached"
  end
  profile.gold-=cost
  state.supplies[payload.itemId]=have(state.supplies,payload.itemId)+payload.amount
  return true,"Alchemy reagent purchased"
 elseif action=="craftPotion" then
  if state.job then return false,"Cauldron is busy" end
  if count(state.owned)>=catalog(config).maxOwned then return false,"Potion storage full" end
  local optionalId=payload.optionalId or ""
  local plan,reason=Alchemy.recipeState(profile,config,payload.recipeId,optionalId)
  if not plan then return false,reason end
  local recipe=plan.recipe
  if profile.essence<recipe.essence then return false,"Not enough essence" end
  for id,needed in pairs(plan.requires) do
   local source=catalog(config).supplies[id] and state.supplies or profile.inventory
   if have(source,id)<needed then return false,"Missing ingredient: "..id end
  end
  -- All checks precede any mutation. Exactly one batch is paid.
  for id,needed in pairs(plan.requires) do
   local source=catalog(config).supplies[id] and state.supplies or profile.inventory
   spend(source,id,needed)
  end
  profile.essence-=recipe.essence
  local quality=Alchemy.quality(config,profile,recipe,optionalId)
  state.job={recipeId=payload.recipeId,optionalId=optionalId,
   progress=0,duration=recipe.duration,quality=quality,
   price=Alchemy.worth(config,recipe,quality,optionalId)}
  return true,"Potion brewing started"
 elseif action=="sellPotion" then
  local item=state.owned[payload.potionId]
  if not item then return false,"Potion not owned" end
  if profile.gold>config.maxBalance-item.price then return false,"Gold capacity reached" end
  profile.gold+=item.price
  state.owned[payload.potionId]=nil
  if item.recipeId=="healing" then profile.tutorial.sale=true end
  return true,"Potion sold"
 end
 return false,"Unknown alchemy action"
end
-- Reconcile prepaid-legacy, unspent cauldron buffers without minting anything.
-- Existing in-flight jobs own their resources until they settle. Full storage keeps
-- the remainder in the old buffer until a later safe tick.
function Alchemy.recoverLegacyBuffers(profile,config,room)
 if not Alchemy.active(config,profile) then return end
 local station=profile.stations.cauldron
 if not station or station.job then return end
 for itemId,amount in pairs(station.input) do
  if amount>0 and config.items[itemId] then
   local take=math.min(amount,math.max(0,room(itemId,amount)))
   if take>0 then
    spend(station.input,itemId,take)
    profile.inventory[itemId]=have(profile.inventory,itemId)+take
   end
  end
 end
 local essence=math.min(station.essence,math.max(0,config.maxBalance-profile.essence))
 if essence>0 then station.essence-=essence;profile.essence+=essence end
end
function Alchemy.tick(profile,config,now)
 if not Alchemy.active(config,profile) then return end
 Alchemy.bootstrap(profile,config)
 local state=profile.alchemyV1
 local job=state.job
 if not job then return end
 job.progress=math.min(job.duration,job.progress+1)
 if job.progress<job.duration or count(state.owned)>=catalog(config).maxOwned
  or state.nextSerial>=config.maxCount then return end
 local recipe=catalog(config).recipes[job.recipeId]
 local id=string.format("v1p:%.0f:%d",profile.userId,state.nextSerial)
 state.owned[id]={
  id=id,recipeId=job.recipeId,optionalId=job.optionalId,quality=job.quality,
  rarity=Alchemy.rarity(config,job.quality,job.optionalId),
  price=job.price,createdAt=math.floor(now),
 }
 state.nextSerial+=1
 state.discovered[job.recipeId]=true
 state.xp=math.min(config.maxBalance,state.xp+1)
 if job.recipeId=="healing" then
  profile.tutorial.brew=true;profile.tutorial.manual=true
 end
 state.job=nil
end
return Alchemy
