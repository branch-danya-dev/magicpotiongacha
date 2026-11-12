--!nonstrict
-- The engine adapter uses this same bounded registry and fault cleanup policy.
local Lifecycle = {}
function Lifecycle.new(ops, limit)
	local self = { records={}, count=0, stopped=false }
	function self.remove(key)
		local record = self.records[key]
		if not record then return end
		self.records[key]=nil; self.count-=1
		ops.dispose(record)
	end
	function self.add(key)
		if self.stopped or self.records[key] or self.count>=limit or not ops.valid(key) then return false end
		local ok, record = pcall(ops.capture,key)
		if not ok or not record then return false end -- capture must not allocate/mutate engine objects
		self.records[key]=record; self.count+=1
		return true
	end
	function self.step(now, dt, config)
		for key,record in pairs(self.records) do
			if not ops.valid(key) then self.remove(key)
			else
				local ok,err=pcall(ops.update,record,now,dt,config)
				if not ok then self.remove(key); if ops.failed then ops.failed(err) end end
			end
		end
	end
	function self.stop()
		if self.stopped then return end
		self.stopped=true
		for key in pairs(self.records) do self.remove(key) end
	end
	return self
end
return Lifecycle
