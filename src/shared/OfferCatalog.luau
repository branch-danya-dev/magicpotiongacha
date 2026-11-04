--!nonstrict
-- Pure fixed outcomes. Sale admission can expire; released grants never do.
local runtimeScript=rawget(getfenv(),"script")
local C=require(runtimeScript and runtimeScript.Parent.TradeCodec or "./TradeCodec")
local Catalog={}
function Catalog.integer(n,lo,hi) return type(n)=="number" and n==n and n%1==0 and n>=lo and n<=hi end
function Catalog.hash(s) return type(s)=="string" and #s==64 and string.match(s,"^[a-f0-9]+$")~=nil end
function Catalog.new(config,skus)
	local service={}; local grants,products,passes={},{},{}
	for id,def in pairs(config.monetization.offers) do
		assert(Catalog.integer(def.version,1,1000) and Catalog.integer(def.goldCost,1,config.maxBalance),"Invalid offer version/cost")
		assert(type(def.enabled)=="boolean" and type(def.supportedEpochs)=="table" and #def.supportedEpochs==3,"Invalid availability")
		assert(def.eventId=="permanent" or config.events[def.eventId],"Unknown event")
		local event=config.events[def.eventId]
		if event then assert(Catalog.integer(event.startAtUtc,0,config.maxTimestamp) and Catalog.integer(event.endAtUtc,event.startAtUtc+1,config.maxTimestamp),"Invalid event interval") end
		assert((def.kind=="pet" or def.kind=="cauldron") and def.platformKind=="product" or def.kind=="cosmetic" and def.platformKind=="pass","Invalid fixed product kind")
		if def.kind=="pet" then
			local species=config.petSpecies[def.species]; assert(species and def.stats,"Invalid pet grant")
			for _,skill in ipairs({"Farming","Hauling","Brewing"}) do assert(Catalog.integer(def.stats[skill],species.ranges[skill][1],species.ranges[skill][2]),"Invalid fixed stat") end
		elseif def.kind=="cauldron" then
			local item=config.cauldronTypes[def.cauldronType]; assert(item and def.bonus==0 and item.bonus==def.bonus and def.brewSpeedBonus==item.brewSpeedBonus and def.brewSpeedBonus<=0.05,"Invalid fixed cauldron")
		else assert(type(def.entitlement)=="string" and #def.entitlement>0,"Invalid cosmetic entitlement") end
		local grant={offerId=id,version=def.version,eventId=def.eventId,kind=def.kind,platformKind=def.platformKind,visual=def.visual,
			species=def.species,stats=def.stats and C.copy(def.stats),cauldronType=def.cauldronType,bonus=def.bonus,brewSpeedBonus=def.brewSpeedBonus,entitlement=def.entitlement}
		grants[id]={data=grant,hash=C.hash(grant)}
		local sku=skus and skus[id] or 0; assert(Catalog.integer(sku,0,9007199254740991),"Invalid SKU")
		if sku>0 then local map=def.platformKind=="product" and products or passes; assert(not map[sku],"Duplicate SKU mapping"); map[sku]=id end
	end
	if skus then for id in pairs(skus) do assert(grants[id],"Unknown SKU offer") end end
	function service.grant(id) return grants[id] and C.copy(grants[id].data) end
	function service.fingerprint(id) return grants[id] and grants[id].hash end
	function service.resolve(kind,id) return (kind=="product" and products or kind=="pass" and passes or {})[id] end
	function service.sku(id) return skus and skus[id] or 0 end
	function service.available(p,id,now)
		local def=config.monetization.offers[id]
		if not def or not def.enabled or not Catalog.integer(now,0,config.maxTimestamp) then return false,"unavailable" end
		local event=config.events[def.eventId]
		if event and now<event.startAtUtc then return false,"upcoming" end
		if event and now>=event.endAtUtc then return false,"ended" end
		if not def.supportedEpochs[p.rebirths%3+1] then return false,"epoch_unavailable" end
		if def.kind=="cosmetic" and p.entitlements[def.entitlement] then return false,"owned" end
		return true,"available"
	end
	return service
end
return Catalog
