--!nonstrict
local runtimeScript=rawget(getfenv(),"script")
local Catalog=require(runtimeScript and runtimeScript.Parent.OfferCatalog or "./OfferCatalog")
local Origin={}
function Origin.event(config,origin,kind,identity)
	if type(origin)~="table" or getmetatable(origin)~=nil or (origin.source~="event_gold" and origin.source~="developer_product") then return false end
	local def=config.monetization.offers[origin.offerId]
	if not def or def.kind~=kind or origin.version~=def.version or origin.eventId~=def.eventId or type(origin.paidDerived)~="boolean" then return false end
	if kind=="pet" and identity~=def.species or kind=="cauldron" and identity~=def.cauldronType then return false end
	if origin.source=="developer_product" then
		return origin.paidDerived and Catalog.hash(origin.purchaseHash) and Catalog.integer(origin.productId,1,9007199254740991)
	end
	return origin.purchaseHash==nil and origin.productId==nil
end
function Origin.cauldron(config,item)
	local def=type(item)=="table" and config.cauldronTypes[item.type]; local origin=def and item.provenance
	if not def or item.bonus~=def.bonus or (item.brewSpeedBonus or 0)~=(def.brewSpeedBonus or 0)
		or type(origin)~="table" or getmetatable(origin)~=nil or type(origin.paidDerived)~="boolean" then return false end
	if item.type=="resonant" then return origin.source=="phase3" and item.brewSpeedBonus==nil end
	return Origin.event(config,origin,"cauldron",item.type)
end
return Origin
