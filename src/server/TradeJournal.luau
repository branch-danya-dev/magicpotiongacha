--!nonstrict
-- Durable single-key decisions. Injected backend; no Roblox APIs in this module.
local runtimeScript=rawget(getfenv(),"script")
local C=require(runtimeScript and runtimeScript:FindFirstAncestorOfClass("DataModel").ReplicatedStorage.PotionTycoon.Shared.TradeCodec or "../shared/TradeCodec")
local Journal={}
function Journal.new(options)
	local service={}; local keys,index,nextShard={},1,0
	local shards,capacity=options.shards or 16,options.capacity or 128
	local function validId(id) return type(id)=="string" and #id>0 and #id<=80 and string.match(id,"^[%w_:%-%.]+$")~=nil end
	local function bucket(id) return tonumber(string.sub(C.sha256(id),1,8),16)%shards end
	local function validRegistry(r)
		if type(r)~="table" or r.schemaVersion~=1 or type(r.entries)~="table" then return false end
		local count=0
		for id,entry in pairs(r.entries) do
			count+=1
			if not validId(id) or type(entry)~="table" or type(entry.hash)~="string" or #entry.hash~=64
				or not string.match(entry.hash,"^[a-f0-9]+$") or type(entry.deadline)~="number" or entry.deadline~=entry.deadline
				or entry.deadline<0 or entry.deadline>1000000000000 or entry.deadline%1~=0 then return false end
		end
		return count<=capacity
	end
	local function registry(shard,transform)
		for attempt=1,2 do
			if options.budget and not options.budget() then return nil,"Trade request budget unavailable" end
			local rejection
			local ok,result=pcall(function()
				return options.backend:UpdateAsync("r:"..string.format("%02d",shard),function(current)
					current=current or {schemaVersion=1,entries={}}
					if not validRegistry(current) then rejection="Invalid recovery registry"; return nil end
					local replacement,reason=transform(C.copy(current)); rejection=reason
					if replacement and not validRegistry(replacement) then rejection="Invalid registry transition"; return nil end
					return replacement
				end)
			end)
			if ok then
				if result and validRegistry(result) then return result end
				return nil,rejection or (result and "Invalid registry result" or "Registry missing")
			end
			if attempt<2 then options.sleep(0.25) end
		end
		return nil,"Registry outcome unknown"
	end
	local function untrack(id,expected)
		return registry(bucket(id),function(r)
			local entry=r.entries[id]
			if entry and (entry.hash~=expected.hash or entry.deadline~=expected.deadline) then return nil,"Registry identity conflict" end
			r.entries[id]=nil; return r
		end)
	end
	function service.update(id,transform)
		if not validId(id) then return nil,"Invalid journal ID" end
		for attempt=1,2 do
			if options.budget and not options.budget() then return nil,"Trade request budget unavailable" end
			local rejection
			local ok,result=pcall(function()
				return options.backend:UpdateAsync("t:"..id,function(current)
					if current and (not options.validate(current) or current.id~=id) then rejection="Invalid journal"; return nil end
					local nextValue,reason=transform(C.copy(current),options.now()); rejection=reason
					if nextValue and (not options.validate(nextValue) or nextValue.id~=id) then rejection="Invalid journal transition"; return nil end
					return nextValue
				end)
			end)
			if ok then
				if result and options.validate(result) and result.id==id then return result end
				return nil,rejection or "Journal missing"
			end
			if attempt<2 then options.sleep(0.25) end
		end
		return nil,"Journal outcome unknown"
	end
	function service.read(id) return service.update(id,function(current) return current end) end
	function service.create(record)
		if not options.validate(record) or record.state~="PREPARING" then return nil,"Invalid new journal" end
		local tracked,reason=registry(bucket(record.id),function(r)
			if options.now()>=record.deadline then return nil,"Expired journal creation" end
			local old=r.entries[record.id]
			if old then
				if old.hash~=record.hash or old.deadline~=record.deadline then return nil,"Registry identity conflict" end
				return r
			end
			local count=0; for _ in pairs(r.entries) do count+=1 end
			if count>=capacity then return nil,"Recovery registry full; new trades paused" end
			r.entries[record.id]={hash=record.hash,deadline=record.deadline}; return r
		end)
		if not tracked then return nil,reason end
		return service.update(record.id,function(current,now)
			if current then
				if current.hash==record.hash and current.coordinator==record.coordinator then return current end
				return nil,"Journal ID collision"
			end
			if now>=record.deadline then return nil,"Expired journal creation" end
			return C.copy(record)
		end)
	end
	function service.prepared(id,side)
		return service.update(id,function(j)
			if not j then return nil end
			if j.state=="PREPARING" then j.prepared[tostring(side)]=true end
			return j
		end)
	end
	function service.decide(id,decision,coordinator,guard)
		return service.update(id,function(j,now)
			if not j then return nil end
			if j.state~="PREPARING" then return j end
			if decision=="COMMIT" then
				if j.coordinator~=coordinator or now>=j.deadline or not j.prepared["1"] or not j.prepared["2"] or not guard or not guard(now) then return nil,"Commit prerequisites changed" end
			elseif decision~="ABORT" or (coordinator~=j.coordinator and now<j.deadline) then return nil,"Abort not authorized yet" end
			j.state,j.decision=decision,decision; return j
		end)
	end
	function service.ack(id,field,side)
		return service.update(id,function(j,now)
			if not j then return nil end
			if j.state=="COMPLETE" then return j end
			if field=="applied" and j.decision then j.applied[tostring(side)]=true
			elseif field=="cleared" and j.state=="SETTLED" then j.cleared[tostring(side)]=true
			else return nil,"Invalid acknowledgment stage" end
			if j.applied["1"] and j.applied["2"] then j.state="SETTLED" end
			if j.cleared["1"] and j.cleared["2"] then
				j.state,j.completedAt="COMPLETE",now
				for _,participant in ipairs(j.sides) do participant.items=nil end
			end
			return j
		end)
	end
	function service.collect(id)
		local j,reason=service.read(id); if not j then return false,reason end
		if j.state~="COMPLETE" or options.now()<math.max(j.deadline,j.completedAt)+options.retentionSeconds then return false,"Retained" end
		if options.budget and not options.budget() then return false,"Trade request budget unavailable" end
		-- COMPLETE is immutable and creation has expired. A late worker cannot
		-- replace this ID with a new transaction after the conditional read.
		local ok=pcall(function() options.backend:RemoveAsync("t:"..id) end)
		if not ok then return false,"GC pending" end
		local removed,err=untrack(id,j); return removed~=nil,err or "Collected"
	end
	function service.cleanMissing(id,entry)
		if not entry or options.now()<=entry.deadline then return false,"Creation still possible" end
		local j,reason=service.read(id)
		if j or reason~="Journal missing" then return false,reason or "Journal exists" end
		local removed,err=untrack(id,entry); return removed~=nil,err
	end
	function service.nextKey()
		if index<=#keys then local key=keys[index]; index+=1; return key.id,key.entry end
		for _=1,shards do
			local shard=nextShard; nextShard=(nextShard+1)%shards
			local r,reason=registry(shard,function(current) return current end)
			if not r then return nil,reason end
			keys={}; index=1
			for id,entry in pairs(r.entries) do table.insert(keys,{id=id,entry=entry}) end
			table.sort(keys,function(a,b) return a.id<b.id end)
			if #keys>0 then local key=keys[index]; index+=1; return key.id,key.entry end
		end
		return nil
	end
	return service
end
return Journal
