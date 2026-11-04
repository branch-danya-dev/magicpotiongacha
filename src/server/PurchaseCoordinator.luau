--!nonstrict
-- Trusted platform port; never callable by a client Remote. Each store has its own CAS boundary.
local runtimeScript=rawget(getfenv(),"script")
local Journal=require(runtimeScript and runtimeScript.Parent.ReceiptJournal or "./ReceiptJournal")
local Coordinator={}
function Coordinator.new(options)
	local service={}; local catalog,model=options.catalog,options.model
	function service.process(receipt)
		if not Journal.validReceipt(receipt) then return false,"Invalid receipt" end
		local offerId=catalog.resolve("product",receipt.ProductId); if not offerId then return false,"Unknown ProductId; investigate mapping" end
		local binding,why=options.journal.bind("product",receipt.ProductId,offerId,catalog.fingerprint(offerId)); if not binding then return false,why end
		local record,err=options.journal.record(receipt,offerId,binding.grantHash); if not record then return false,err end
		if record.state=="APPLIED" then return true,"already_processed" end
		local ok,result=options.transact(receipt.PlayerId,function(p,context)
			return model.acceptReceipt(p,receipt,offerId,options.engine,context)
		end)
		if not ok then return false,result end
		local committed,failure=options.journal.applied(record)
		if not committed then return false,failure end
		return true,result.status
	end
	function service.syncPass(userId,offerId)
		local passId=catalog.sku(offerId)
		if catalog.resolve("pass",passId)~=offerId then return false,"Pass unconfigured" end
		local identity=options.identity(userId); if not identity then return false,"Player unavailable" end
		local ok,owns=pcall(options.ownsPass,userId,passId)
		if not ok or owns~=true then return false,"Pass ownership unverified" end
		if options.identity(userId)~=identity then return false,"Player session changed" end
		local bound,err=options.journal.bind("pass",passId,offerId,catalog.fingerprint(offerId)); if not bound then return false,err end
		if options.identity(userId)~=identity then return false,"Player session changed" end
		return options.transact(userId,function(p,context)
			if options.identity(userId)~=identity then return false,"Player session changed" end
			context.verifiedOwned=true; return model.acceptPass(p,offerId,passId,options.engine,context)
		end)
	end
	return service
end
return Coordinator
