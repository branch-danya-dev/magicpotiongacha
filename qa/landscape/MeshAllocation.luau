--!nonstrict
-- Portable lifecycle: one expandable scratch mesh, then a fixed-size retained copy.
local M={}
function M.new(api)
	local busy=false;local completed,failed,active,peak=0,0,0,0
	local self={}
	function self.build(fill)
		while busy do api.wait()end
		busy=true
		local scratch,fixed
		local ok,err=pcall(function()
			scratch=assert(api.create(),"Editable scratch mesh budget unavailable")
			active+=1;peak=math.max(peak,active)
			fill(scratch)
			fixed=assert(api.compact(scratch),"Fixed mesh budget unavailable")
			assert(fixed~=scratch,"Compaction must return an independent mesh")
		end)
		if scratch then api.destroy(scratch);active-=1 end
		busy=false
		if not ok then
			if fixed and fixed~=scratch then api.destroy(fixed)end
			failed+=1;error(err,0)
		end
		completed+=1;return fixed
	end
	function self.stats()return {activeScratch=active,peakScratch=peak,completed=completed,failed=failed,busy=busy}end
	return self
end
return M
