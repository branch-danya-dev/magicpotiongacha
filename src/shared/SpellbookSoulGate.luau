--!strict
-- Late preload callbacks cannot resurrect a stopped owner or override a timeout.
local Gate = {}
function Gate.new()
	local self = {status = "pending", stopped = false}
	function self.finish(ok: boolean): boolean
		if self.stopped or self.status ~= "pending" then return false end
		self.status = if ok then "ready" else "failed"
		return true
	end
	function self.stop() self.stopped = true end
	return self
end
return Gate
