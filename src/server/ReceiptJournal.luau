--!nonstrict
-- Immutable SKU binding + monotonic receipt evidence. No profile rewards in callbacks.
local runtimeScript=rawget(getfenv(),"script")
local Shared=runtimeScript and runtimeScript:FindFirstAncestorOfClass("DataModel").ReplicatedStorage.PotionTycoon.Shared
local C=require(Shared and Shared.TradeCodec or "../shared/TradeCodec")
local Catalog=require(Shared and Shared.OfferCatalog or "../shared/OfferCatalog")
local Journal={}
local function plain(v) return type(v)=="table" and getmetatable(v)==nil end
function Journal.validReceipt(r)
	return plain(r) and type(r.PurchaseId)=="string" and #r.PurchaseId>0 and #r.PurchaseId<=128
		and string.match(r.PurchaseId,"^[%w_:%-%.]+$")~=nil and Catalog.integer(r.PlayerId,1,9007199254740991)
		and Catalog.integer(r.ProductId,1,9007199254740991)
end
function Journal.key(purchaseId) return "r:"..string.sub(C.sha256(purchaseId),1,48) end -- DataStore keys <=50 bytes; full identity verified inside.
local function valid(r)
	return plain(r) and r.schemaVersion==1 and Journal.validReceipt({PurchaseId=r.purchaseId,PlayerId=r.userId,ProductId=r.productId})
		and r.keyHash==C.sha256(r.purchaseId) and Catalog.hash(r.grantHash) and type(r.offerId)=="string" and #r.offerId>0 and #r.offerId<=64
		and (r.state=="RECORDED" or r.state=="APPLIED")
end
function Journal.new(options)
	local service={}
	local function cas(key,transform,verify)
		for attempt=1,3 do
			local ok,result=pcall(function() return options.backend:UpdateAsync(key,transform) end)
			if ok then if result~=nil and verify(result) then return C.copy(result) end; return nil,"Journal conflict or invalid state" end
			if attempt<3 then options.sleep(0.25*2^(attempt-1)) end
		end
		return nil,"Journal outcome unconfirmed"
	end
	function service.bind(kind,sku,offerId,grantHash)
		if (kind~="product" and kind~="pass") or not Catalog.integer(sku,1,9007199254740991) or not Catalog.hash(grantHash) then return nil,"Invalid SKU binding" end
		local wanted={schemaVersion=1,kind=kind,sku=sku,offerId=offerId,grantHash=grantHash}
		local function same(r) return plain(r) and C.encode(r)==C.encode(wanted) end
		return cas("sku:"..kind..":"..string.format("%.0f",sku),function(old)
			if old==nil then return C.copy(wanted) end
			return same(old) and old or nil
		end,same)
	end
	function service.record(receipt,offerId,grantHash)
		if not Journal.validReceipt(receipt) or not Catalog.hash(grantHash) then return nil,"Invalid platform receipt" end
		local wanted={schemaVersion=1,purchaseId=receipt.PurchaseId,keyHash=C.sha256(receipt.PurchaseId),userId=receipt.PlayerId,
			productId=receipt.ProductId,offerId=offerId,grantHash=grantHash,state="RECORDED"}
		local function same(r)
			return valid(r) and r.purchaseId==wanted.purchaseId and r.keyHash==wanted.keyHash and r.userId==wanted.userId
				and r.productId==wanted.productId and r.offerId==wanted.offerId and r.grantHash==wanted.grantHash
		end
		return cas(Journal.key(receipt.PurchaseId),function(old) if old==nil then return C.copy(wanted) end; return same(old) and old or nil end,same)
	end
	function service.applied(record)
		if not valid(record) then return nil,"Invalid receipt evidence" end
		local function same(r)
			return valid(r) and r.purchaseId==record.purchaseId and r.userId==record.userId and r.productId==record.productId
				and r.offerId==record.offerId and r.grantHash==record.grantHash
		end
		return cas(Journal.key(record.purchaseId),function(old)
			if not same(old) then return nil end
			local result=C.copy(old); result.state="APPLIED"; return result
		end,function(r) return same(r) and r.state=="APPLIED" end)
	end
	return service
end
return Journal
