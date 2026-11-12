--!nonstrict
-- One client-wide batch. Requests during its lifetime are coalesced, never queued
-- or allowed to extend it indefinitely. The native adapter and tests share this.
local Policy=require("./SpellbookEffectsPolicy")
local Burst={}
function Burst.new(ops)
	local self={items={},owner=nil,started=0,duration=0,bursts=0,peak=0,errors=0}
	function self.cancel(owner)
		if owner~=nil and self.owner~=owner then return end
		for _,item in ipairs(self.items) do ops.destroy(item) end
		table.clear(self.items); self.owner=nil
	end
	local function failed(err)
		self.errors+=1; self.cancel()
		if ops.failed then ops.failed(err) end
	end
	function self.trigger(owner,now,cfg,origin)
		if cfg.paperCount<=0 then return false end
		if self.owner and now<self.started+self.duration then return false end
		self.cancel()
		self.owner=owner; self.started=now; self.duration=cfg.paperSeconds; self.origin=origin
		local ok,err=pcall(function()
			for i=1,math.min(Policy.maxSheets,cfg.paperCount) do
				local item=ops.allocate() -- allocation only; setup happens after ownership
				table.insert(self.items,item)
				ops.setup(item,owner,i)
			end
		end)
		if not ok then failed(err); return false end
		self.bursts+=1; self.peak=math.max(self.peak,#self.items)
		return true
	end
	function self.step(now)
		if not self.owner then return end
		local t=(now-self.started)/self.duration
		if t>=1 or t<0 then self.cancel(); return end
		local ok,err=pcall(function()
			for i,item in ipairs(self.items) do ops.pose(item,self.origin,Policy.paper(t,i,#self.items)) end
		end)
		if not ok then failed(err) end
	end
	return self
end
return Burst
