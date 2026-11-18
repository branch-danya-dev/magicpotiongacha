--!nonstrict
-- Bounded owned-resource cache, shared by all quality modes.
local M={}
function M.new()
	local self={items={},keys={},closed=false,created=0}
	function self.get(key,create)
		assert(not self.closed,"Resource owner stopped")
		if self.keys[key] then return self.keys[key] end
		local value=assert(create(),"Resource budget exhausted")
		self.keys[key]=value;table.insert(self.items,value);self.created+=1;return value
	end
	function self.destroy()
		if self.closed then return end;self.closed=true
		for i=#self.items,1,-1 do self.items[i]:Destroy() end
		table.clear(self.items);table.clear(self.keys)
	end
	return self
end
return M
