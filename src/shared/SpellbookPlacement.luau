--!nonstrict
-- Atomic visual placement policy, portable for failure/ownership regression tests.
-- Operations only deal with presentation instances, never profile or station state.
local Placement = {}
function Placement.ensure(ops, plot, anchor)
	if not ops.target(plot, anchor) then return false, "invalid-target" end
	local existing = ops.existing(anchor)
	if existing then
		if ops.belongs(existing, plot, anchor) then return true, existing end
		return false, "foreign-or-invalid-link"
	end
	local template = ops.template()
	local valid, reason = ops.validate(template)
	if not valid then return false, reason end
	local model
	local ok, failure = pcall(function()
		model = ops.clone(template)
		ops.prepare(model, plot, anchor)
		ops.publish(model, plot, anchor)
	end)
	if not ok then
		if model then ops.discard(model, anchor) end
		return false, "placement-failed: " .. tostring(failure)
	end
	return true, model
end
return Placement
