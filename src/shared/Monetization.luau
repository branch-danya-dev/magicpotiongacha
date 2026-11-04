--!nonstrict
-- Pure candidates; only the trusted receipt coordinator may call paid/pass methods.
local runtimeScript=rawget(getfenv(),"script")
local C=require(runtimeScript and runtimeScript.Parent.TradeCodec or "./TradeCodec")
local Catalog=require(runtimeScript and runtimeScript.Parent.OfferCatalog or "./OfferCatalog")
local Familiars=require(runtimeScript and runtimeScript.Parent.Familiars or "./Familiars")
local Protocol=require(runtimeScript and runtimeScript.Parent.Protocol or "./Protocol")
local Monetization={}
local actions={buyEventGold=true,deliverPurchases=true}
local function plain(v) return type(v)=="table" and getmetatable(v)==nil end
local function count(t) local n=0; for _ in pairs(t) do n+=1 end; return n end
function Monetization.initial() return {sequence=0,receipts={},passes={}} end
function Monetization.isAction(action) return actions[action]==true end
function Monetization.new(config)
	local service={}; local catalog=Catalog.new(config); local familiars=Familiars.new(config)
	function service.queued(p) local n=0; for _,r in pairs(p.monetization.receipts) do if plain(r) and r.status=="queued" then n+=1 end end; return n end
	function service.room(p,grant)
		if grant.kind=="pet" then return count(p.pets)<config.maxPets and p.nextPetSerial<config.maxCount end
		if grant.kind=="cauldron" then return count(p.cauldrons)<config.trading.maxCauldrons and p.nextCauldronSerial<config.maxCount end
		return true
	end
	local function insert(p,grant,paid,purchaseHash,productId)
		if not service.room(p,grant) then return nil,"Inventory full; delivery right retained" end
		if grant.kind=="cosmetic" then p.entitlements[grant.entitlement]=true; return grant.entitlement end
		local pet=grant.kind=="pet"; local serial=pet and p.nextPetSerial or p.nextCauldronSerial
		local id=string.format("%.0f",p.userId)..(pet and ":pet:" or ":cauldron:")..serial
		if p.pets[id] or p.cauldrons[id] then return nil,"Instance identity conflict" end
		local source=purchaseHash and "developer_product" or "event_gold"
		local origin={source=source,paidDerived=paid,offerId=grant.offerId,eventId=grant.eventId,version=grant.version,purchaseHash=purchaseHash,productId=productId}
		if pet then
			local value=familiars.create(id,grant.species,grant.stats,source,paid)
			for k,v in pairs(origin) do value.provenance[k]=v end
			p.pets[id]=value; p.nextPetSerial+=1
		else
			p.cauldrons[id]={id=id,ownerId=p.userId,type=grant.cauldronType,bonus=grant.bonus,brewSpeedBonus=grant.brewSpeedBonus,locked=false,provenance=origin}
			p.nextCauldronSerial+=1
		end
		return id
	end
	function service.validate(p)
		local m=p.monetization
		if not plain(m) or not Catalog.integer(m.sequence,0,config.maxBalance) or not plain(m.receipts) or not plain(m.passes)
			or count(m.receipts)>config.monetization.maxReceipts or count(m.passes)>64 or service.queued(p)>config.monetization.maxQueued then return false end
		if m.sequence==0 then if m.last~=nil then return false end
		elseif not plain(m.last) or m.last.requestId~=m.sequence or not actions[m.last.action] or type(m.last.fingerprint)~="string"
			or #m.last.fingerprint>1024 or not plain(m.last.result) or type(m.last.result.message)~="string" or #m.last.result.message>256 then return false end
		local instances={}
		for key,r in pairs(m.receipts) do
			if not Catalog.hash(key) or not plain(r) or not Catalog.integer(r.productId,1,9007199254740991) or r.grantHash~=catalog.fingerprint(r.offerId)
				or not Catalog.hash(r.grantHash) or config.monetization.offers[r.offerId].platformKind~="product"
				or (r.status~="queued" and r.status~="delivered") or not Catalog.integer(r.acceptedAt,0,config.maxTimestamp) then return false end
			if r.status=="queued" and r.instanceId~=nil then return false end
			if r.status=="delivered" and (type(r.instanceId)~="string" or #r.instanceId<1 or #r.instanceId>80) then return false end
			if r.instanceId then
				if instances[r.instanceId] then return false end; instances[r.instanceId]=true
				local item=p.pets[r.instanceId] or p.cauldrons[r.instanceId]
				if item and (item.provenance.purchaseHash~=key or item.provenance.productId~=r.productId or item.provenance.offerId~=r.offerId) then return false end
			end
		end
		local purchaseItems={}
		for _,inventory in ipairs({p.pets,p.cauldrons}) do for _,item in pairs(inventory) do
			local key=item.provenance.purchaseHash
			if key then
				if purchaseItems[key] then return false end; purchaseItems[key]=true
				local proof=m.receipts[key]
				if proof and (proof.status~="delivered" or proof.instanceId~=item.id) then return false end
			end
		end end
		for key,proof in pairs(m.passes) do
			if type(key)~="string" or not Catalog.integer(tonumber(key),1,9007199254740991) or not plain(proof)
				or proof.grantHash~=catalog.fingerprint(proof.offerId) or not Catalog.hash(proof.grantHash) then return false end
			local def=config.monetization.offers[proof.offerId]
			if def.platformKind~="pass" or p.entitlements[def.entitlement]~=true then return false end
		end
		return true
	end
	local function allowed(p,engine,ctx)
		if p.trade.pending or ctx.tradeActive then return false,"Finish trade recovery first" end
		if not Catalog.integer(ctx.now,0,config.maxTimestamp) or ctx.now<p.lastSimulatedAt then return false,"Invalid server clock" end
		if ctx.guard and not ctx.guard() then return false,"Player session changed" end
		local result=engine.advance(p,ctx.now,false); return result.ok,result.error
	end
	local function publish(profile,p,engine,result)
		local ok,reason=engine.validate(p); if not ok then return false,reason end
		table.clear(profile); for k,v in pairs(p) do profile[k]=v end; return true,result,false
	end
	function service.acceptReceipt(profile,receipt,offerId,engine,ctx)
		if profile.userId~=receipt.PlayerId then return false,"Receipt player mismatch" end
		local grant=catalog.grant(offerId); if not grant or grant.platformKind~="product" then return false,"Unknown product grant" end
		local key=C.sha256(receipt.PurchaseId); local proof=profile.monetization.receipts[key]
		if proof then
			if proof.productId~=receipt.ProductId or proof.grantHash~=catalog.fingerprint(offerId) then return false,"Receipt identity conflict" end
			return true,{status=proof.status,instanceId=proof.instanceId},true
		end
		if count(profile.monetization.receipts)>=config.monetization.maxReceipts or service.queued(profile)>=config.monetization.maxQueued then return false,"Receipt history/queue limit; payment remains unacknowledged" end
		local p=C.copy(profile); local ok,why=allowed(p,engine,ctx); if not ok then return false,why end
		local id=insert(p,grant,true,key,receipt.ProductId)
		p.monetization.receipts[key]={offerId=offerId,productId=receipt.ProductId,grantHash=catalog.fingerprint(offerId),acceptedAt=ctx.now,status=id and "delivered" or "queued",instanceId=id}
		return publish(profile,p,engine,{status=id and "delivered" or "queued",instanceId=id})
	end
	function service.acceptPass(profile,offerId,passId,engine,ctx)
		local def=config.monetization.offers[offerId]
		if not def or def.platformKind~="pass" or ctx.verifiedOwned~=true or not Catalog.integer(passId,1,9007199254740991) then return false,"Pass ownership unverified" end
		local key=string.format("%.0f",passId); local proof=profile.monetization.passes[key]
		if proof then return proof.offerId==offerId and proof.grantHash==catalog.fingerprint(offerId),{message="Право уже подтверждено"},true end
		local p=C.copy(profile); local ok,why=allowed(p,engine,ctx); if not ok then return false,why end
		p.entitlements[def.entitlement]=true; p.monetization.passes[key]={offerId=offerId,grantHash=catalog.fingerprint(offerId)}
		return publish(profile,p,engine,{message="Постоянное оформление сохранено"})
	end
	function service.apply(profile,action,payload,engine,ctx)
		if not actions[action] or not Protocol.validate(action,payload) then return false,"Invalid shop intent" end
		local old=profile.monetization; local fingerprint=C.encode({action=action,payload=payload})
		if payload.requestId==old.sequence and old.last then
			if old.last.fingerprint~=fingerprint then return false,"Request ID conflict" end
			return true,C.copy(old.last.result),true
		end
		if payload.requestId~=old.sequence+1 or old.sequence>=config.maxBalance then return false,"Stale shop request" end
		local p=C.copy(profile); local ok,why=allowed(p,engine,ctx); if not ok then return false,why end
		local result={message="Покупка сохранена"}
		if action=="buyEventGold" then
			local available,reason=catalog.available(p,payload.offerId,ctx.now); if not available then return false,reason end
			local def=config.monetization.offers[payload.offerId]; if p.gold<def.goldCost then return false,"Недостаточно заработанного Gold" end
			local id,err=insert(p,catalog.grant(payload.offerId),p.currencyPaid.gold); if not id then return false,err end
			p.gold-=def.goldCost; result.instanceId=id
		else
			local keys={}; for key,r in pairs(p.monetization.receipts) do if r.status=="queued" then table.insert(keys,key) end end; table.sort(keys)
			local delivered=0
			for _,key in ipairs(keys) do
				local r=p.monetization.receipts[key]; local id=insert(p,catalog.grant(r.offerId),true,key,r.productId)
				if id then r.status,r.instanceId="delivered",id; delivered+=1 end
			end
			if delivered==0 then return false,"Нет доступной доставки: освободи место, оплаченные права сохранены" end
			result.message="Доставлено предметов: "..delivered; result.delivered=delivered
		end
		p.monetization.sequence=payload.requestId; p.monetization.last={requestId=payload.requestId,action=action,fingerprint=fingerprint,result=C.copy(result)}
		return publish(profile,p,engine,result)
	end
	function service.state(p,now)
		local cards={}
		for _,id in ipairs(config.monetization.offerOrder) do
			local def=config.monetization.offers[id]; local available,status=catalog.available(p,id,now)
			local owned,queued,delivered=0,0,0
			if def.kind=="cosmetic" then owned=p.entitlements[def.entitlement] and 1 or 0
			else for _,item in pairs(def.kind=="pet" and p.pets or p.cauldrons) do if item.provenance.offerId==id then owned+=1 end end end
			for _,r in pairs(p.monetization.receipts) do if r.offerId==id then if r.status=="queued" then queued+=1 else delivered+=1 end end end
			table.insert(cards,{offerId=id,name=def.name,kind=def.kind,visual=def.visual,effect=def.effect,stats=def.stats and C.copy(def.stats),goldCost=def.goldCost,
				available=available,status=status,owned=owned,queued=queued,delivered=delivered,room=service.room(p,catalog.grant(id)),event=config.events[def.eventId] and C.copy(config.events[def.eventId])})
		end
		return {sequence=p.monetization.sequence,cards=cards,queued=service.queued(p),receiptCount=count(p.monetization.receipts),last=p.monetization.last and C.copy(p.monetization.last.result)}
	end
	return service
end
return Monetization
