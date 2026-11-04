--!nonstrict
-- Crash-safe orchestration; profiles.mutate must use normal lease/revision fencing.
local runtimeScript=rawget(getfenv(),"script")
local C=require(runtimeScript and runtimeScript:FindFirstAncestorOfClass("DataModel").ReplicatedStorage.PotionTycoon.Shared.TradeCodec or "../shared/TradeCodec")
local Coordinator={}
function Coordinator.new(options)
	local service={}; local journal,model=options.journal,options.model
	function service.recover(id,abortOwner)
		local j,reason=journal.read(id); if not j then return false,reason end
		if j.state=="PREPARING" then
			if not abortOwner and options.now()<j.deadline then return false,"Waiting for coordinator" end
			j,reason=journal.decide(id,"ABORT",abortOwner); if not j then return false,reason end
		end
		if j.state=="COMPLETE" then return true,j end
		for index,side in ipairs(j.sides) do
			if not j.applied[tostring(index)] then
				local ok,err=options.profiles.mutate(side.userId,function(p) return model.apply(p,j,index) end)
				if not ok then return false,err end
				j,reason=journal.ack(id,"applied",index); if not j then return false,reason end
			end
		end
		for index,side in ipairs(j.sides) do
			if not j.cleared[tostring(index)] then
				local ok,err=options.profiles.mutate(side.userId,function(p) return model.clear(p,j,index) end)
				if not ok then return false,err end
				j,reason=journal.ack(id,"cleared",index); if not j then return false,reason end
			end
		end
		return j.state=="COMPLETE",j
	end
	function service.start(id,proposal,refreshGuard)
		local now=options.now()
		local record={schemaVersion=1,id=id,coordinator=options.owner,version=proposal.version,sides=C.copy(proposal.sides),
			hash=C.hash(proposal),createdAt=now,deadline=now+options.prepareSeconds,state="PREPARING",prepared={},applied={},cleared={}}
		local j,reason=journal.create(record); if not j then return false,reason end
		if j.state~="PREPARING" then return service.recover(id) end
		for index,side in ipairs(j.sides) do
			if not j.prepared[tostring(index)] then
				local ok,err=options.profiles.mutate(side.userId,function(p) return model.reserve(p,j,index,options.now()) end)
				if not ok then service.recover(id,options.owner); return false,err end
				j,reason=journal.prepared(id,index); if not j then return false,reason end
				if j.state~="PREPARING" then return service.recover(id) end
			end
		end
		-- This may yield for policy. The returned guard must be non-yielding and
		-- recheck identity/proximity/fresh policy inside the journal's CAS callback.
		local ok,guard=pcall(refreshGuard)
		if not ok or not guard then return service.recover(id,options.owner) end
		local decided,err=journal.decide(id,"COMMIT",options.owner,guard)
		if not decided then
			-- Could be a lost COMMIT reply: read the journal, never assume ABORT.
			local recovered,result=service.recover(id,options.owner)
			return recovered,result or err
		end
		return service.recover(id)
	end
	return service
end
return Coordinator
