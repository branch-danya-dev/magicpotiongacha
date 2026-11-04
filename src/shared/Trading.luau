--!nonstrict
-- Pure reserve/apply/clear protocol; only the server's journal coordinator calls it.
local runtimeScript=rawget(getfenv(),"script")
local C=require(runtimeScript and runtimeScript.Parent.TradeCodec or "./TradeCodec")
local Familiars=require(runtimeScript and runtimeScript.Parent.Familiars or "./Familiars")
local Origin=require(runtimeScript and runtimeScript.Parent.ItemOrigin or "./ItemOrigin")
local Trading={}
local function integer(n,lo,hi) return type(n)=="number" and n==n and n%1==0 and n>=lo and n<=hi end
local function plain(v) return type(v)=="table" and getmetatable(v)==nil end
local function id(v) return type(v)=="string" and #v>0 and #v<=80 and string.match(v,"^[%w_:%-%.]+$")~=nil end
local function hash(v) return type(v)=="string" and #v==64 and string.match(v,"^[a-f0-9]+$")~=nil end
local function count(t) local n=0; for _ in pairs(t) do n+=1 end; return n end
local function same(a,b) return C.encode(a)==C.encode(b) end
function Trading.frozen(p) return p.trade and p.trade.pending~=nil end
function Trading.validateProfile(p,maximum)
	local t=p.trade
	if not plain(t) or not integer(t.sequence,0,maximum) then return false end
	local last=t.last
	if last~=nil and (not plain(last) or not id(last.id) or not hash(last.hash) or not integer(last.sequence,1,t.sequence)
		or (last.decision~="COMMIT" and last.decision~="ABORT")) then return false end
	local pending=t.pending
	if pending and (not plain(pending) or not id(pending.id) or not hash(pending.hash) or pending.sequence~=t.sequence
		or not integer(pending.sequence,1,maximum)
		or (pending.stage~="prepared" and pending.stage~="applied")) then return false end
	if pending and pending.stage=="applied" and (not last or last.id~=pending.id or last.hash~=pending.hash or last.sequence~=pending.sequence) then return false end
	if t.sequence>0 and not pending and (not last or last.sequence~=t.sequence) then return false end
	return true
end
function Trading.policyAllowed(policy,now)
	return plain(policy) and policy.tradingKnown==true and policy.tradingAllowed==true
		and type(policy.expiresAt)=="number" and policy.expiresAt>now
end
function Trading.new(config)
	local model={}; local familiars=Familiars.new(config)
	function model.item(p,kind,itemId)
		if Trading.frozen(p) then return nil,"Trade recovery pending" end
		local item=(kind=="pet" and p.pets or kind=="cauldron" and p.cauldrons or {})[itemId]
		if not item or item.locked then return nil,"Item missing or locked" end
		if not plain(item.provenance) or type(item.provenance.paidDerived)~="boolean" or item.provenance.source=="legacy" then return nil,"Unknown historical provenance" end
		if kind=="pet" then
			if not familiars.validatePet(item) then return nil,"Invalid familiar" end
			if not Familiars.provenanceKnown(item) then return nil,"Unknown historical Fuse ancestry" end
			if item.provenance.source=="starter" then return nil,"Starter workers are protected" end
			for _,s in pairs(p.stations) do if s.workerId==itemId then return nil,"Unassign this familiar first" end end
		else
			if kind~="cauldron" or item.ownerId~=p.userId or not config.cauldronTypes[item.type]
				or not Origin.cauldron(config,item) then return nil,"Invalid cauldron owner/type" end
			for _,s in pairs(p.stations) do if s.cauldronId==itemId then return nil,"Unequip this cauldron first" end end
		end
		return {kind=kind,id=itemId,data=C.copy(item),timer=kind=="pet" and p.slimeWorkSeconds[itemId] or nil}
	end
	function model.offer(p,selection)
		if not plain(selection) or #selection>config.trading.maxItems then return nil,"Offer limit" end
		local items,seen={},{}
		for k,entry in pairs(selection) do
			if not integer(k,1,#selection) or not plain(entry) or not id(entry.id) or seen[entry.id] then return nil,"Invalid/duplicate offered ID" end
			seen[entry.id]=true
			local item,reason=model.item(p,entry.kind,entry.id); if not item then return nil,reason end
			table.insert(items,item)
		end
		if #items~=#selection then return nil,"Sparse offer" end
		table.sort(items,function(a,b) return a.id<b.id end); return items
	end
	local function capacity(p,outgoing,incoming)
		local pets,cauldrons=count(p.pets),count(p.cauldrons)
		for _,entry in ipairs(outgoing) do if entry.kind=="pet" then pets-=1 else cauldrons-=1 end end
		for _,entry in ipairs(incoming) do
			if p.pets[entry.id] or p.cauldrons[entry.id] then return false,"Incoming item ID collision" end
			if entry.kind=="pet" then pets+=1 else cauldrons+=1 end
		end
		return pets<=config.maxPets and cauldrons<=config.trading.maxCauldrons,"Incoming inventory is full"
	end
	function model.proposal(a,b,selectionA,selectionB,version)
		if a.userId==b.userId then return nil,"Self trade denied" end
		local x,why=model.offer(a,selectionA); if not x then return nil,why end
		local y,reason=model.offer(b,selectionB); if not y then return nil,reason end
		if #x+#y==0 then return nil,"Offer at least one item" end
		local ok,err=capacity(a,x,y); if not ok then return nil,err end
		ok,err=capacity(b,y,x); if not ok then return nil,err end
		return {version=version,sides={{userId=a.userId,sequence=a.trade.sequence+1,items=x},{userId=b.userId,sequence=b.trade.sequence+1,items=y}}}
	end
	function model.validateJournal(j)
		if not plain(j) or j.schemaVersion~=1 or not id(j.id) or not id(j.coordinator) or not hash(j.hash)
			or not integer(j.version,1,config.maxCount)
			or not integer(j.createdAt,0,config.maxTimestamp) or not integer(j.deadline,j.createdAt+1,config.maxTimestamp)
			or not ({PREPARING=true,COMMIT=true,ABORT=true,SETTLED=true,COMPLETE=true})[j.state]
			or not plain(j.sides) or #j.sides~=2 or count(j.sides)~=2 then return false end
		if not plain(j.prepared) or not plain(j.applied) or not plain(j.cleared) then return false end
		if j.state~="PREPARING" and j.decision~="COMMIT" and j.decision~="ABORT" then return false end
		if j.state=="PREPARING" and j.decision~=nil then return false end
		if j.state=="PREPARING" and (next(j.applied) or next(j.cleared)) then return false end
		if j.state~="SETTLED" and j.state~="COMPLETE" and next(j.cleared) then return false end
		if (j.state=="COMMIT" or j.state=="ABORT") and j.decision~=j.state then return false end
		local seen={}
		for index,side in ipairs(j.sides) do
			if not plain(side) or not integer(side.userId,-9007199254740991,9007199254740991)
				or not integer(side.sequence,1,config.maxBalance) then return false end
			for _,flags in ipairs({j.prepared,j.applied,j.cleared}) do
				for key,value in pairs(flags) do if (key~="1" and key~="2") or value~=true then return false end end
			end
			if j.state~="COMPLETE" then
				if not plain(side.items) or #side.items>config.trading.maxItems or count(side.items)~=#side.items then return false end
				for _,entry in ipairs(side.items) do
					if not plain(entry) or not id(entry.id) or seen[entry.id] or not plain(entry.data) or entry.data.id~=entry.id or entry.data.locked~=false then return false end
					seen[entry.id]=true
					if entry.kind=="pet" then
						if not familiars.validatePet(entry.data) or not Familiars.provenanceKnown(entry.data) or entry.data.provenance.source=="starter" then return false end
						if entry.timer~=nil and (not config.petSpecies[entry.data.species].slimeProducer or not integer(entry.timer,0,config.slimePeriod-1)) then return false end
					elseif entry.kind=="cauldron" then
						local item,def=entry.data,config.cauldronTypes[entry.data.type]
						if not def or item.ownerId~=side.userId or not Origin.cauldron(config,item) or entry.timer~=nil then return false end
					else return false end
				end
			elseif side.items~=nil then return false end
			if j.cleared[tostring(index)] and not j.applied[tostring(index)] then return false end
		end
		if j.sides[1].userId==j.sides[2].userId then return false end
		if j.decision=="COMMIT" and (not j.prepared["1"] or not j.prepared["2"]) then return false end
		if (j.state=="SETTLED" or j.state=="COMPLETE") and (not j.applied["1"] or not j.applied["2"]) then return false end
		if j.state=="COMPLETE" and (not j.cleared["1"] or not j.cleared["2"] or not integer(j.completedAt,j.createdAt,config.maxTimestamp)) then return false end
		if j.state~="COMPLETE" and C.hash({version=j.version,sides=j.sides})~=j.hash then return false end
		return true
	end
	function model.reserve(p,j,index,now)
		local side=j.sides[index]; local t=p.trade
		if p.userId~=side.userId then return false,"Participant mismatch" end
		if t.pending and t.pending.id==j.id and t.pending.hash==j.hash and t.pending.sequence==side.sequence then return true,"reserved",true end
		if j.state~="PREPARING" or now>=j.deadline or t.pending or t.sequence+1~=side.sequence then return false,"Stale reservation" end
		for _,entry in ipairs(side.items) do local item=model.item(p,entry.kind,entry.id); if not item or not same(item,entry) then return false,"Offered item changed" end end
		local ok,why=capacity(p,side.items,j.sides[3-index].items); if not ok then return false,why end
		t.sequence=side.sequence; t.pending={id=j.id,hash=j.hash,sequence=side.sequence,stage="prepared"}
		return true,"reserved"
	end
	function model.apply(p,j,index)
		if not j.decision or j.state=="PREPARING" or j.state=="COMPLETE" then return false,"No applicable decision" end
		local side=j.sides[index]; local t=p.trade; local pending=t.pending
		if p.userId~=side.userId then return false,"Participant mismatch" end
		if not pending or pending.id~=j.id then
			if j.decision=="COMMIT" then
				if t.sequence>=side.sequence and j.applied[tostring(index)] then return true,"already settled",true end
				return false,"Missing committed reservation"
			end
			if t.sequence>=side.sequence then return true,"abort fenced by later sequence",true end
			if pending or t.sequence+1~=side.sequence then return false,"Abort sequence conflict" end
			-- Fence a delayed prepare, even if this side was never reserved.
			t.sequence=side.sequence; t.last={id=j.id,hash=j.hash,sequence=side.sequence,decision="ABORT"}
			return true,"abort barrier"
		end
		if pending.hash~=j.hash or pending.sequence~=side.sequence then return false,"Reservation mismatch" end
		if pending.stage=="applied" then return true,"already applied",true end
		if j.decision=="COMMIT" then
			for _,entry in ipairs(side.items) do
				local actual=(entry.kind=="pet" and p.pets or p.cauldrons)[entry.id]
				if not same(actual,entry.data) or (entry.kind=="pet" and p.slimeWorkSeconds[entry.id]~=entry.timer) then return false,"Reserved item changed" end
			end
			local incoming=j.sides[3-index].items
			local ok,why=capacity(p,side.items,incoming); if not ok then return false,why end
			for _,entry in ipairs(side.items) do
				if entry.kind=="pet" then p.pets[entry.id]=nil; p.slimeWorkSeconds[entry.id]=nil else p.cauldrons[entry.id]=nil end
			end
			for _,entry in ipairs(incoming) do
				local item=C.copy(entry.data)
				if entry.kind=="pet" then p.pets[item.id]=item; p.slimeWorkSeconds[item.id]=entry.timer
				else item.ownerId=p.userId; p.cauldrons[item.id]=item end
			end
		end
		pending.stage="applied"; t.last={id=j.id,hash=j.hash,sequence=side.sequence,decision=j.decision}
		return true,"applied"
	end
	function model.clear(p,j,index)
		if j.state~="SETTLED" and j.state~="COMPLETE" then return false,"Both participants must settle" end
		local t=p.trade; local side=j.sides[index]
		if p.userId~=side.userId or t.sequence<side.sequence then return false,"Clear sequence mismatch" end
		if not t.pending or t.pending.id~=j.id then return true,"already cleared",true end
		if t.pending.stage~="applied" or t.pending.hash~=j.hash or not t.last or t.last.decision~=j.decision then return false,"Not applied" end
		t.pending=nil; return true,"cleared"
	end
	return model
end
return Trading
