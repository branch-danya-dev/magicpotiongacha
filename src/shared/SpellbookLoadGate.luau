--!strict
-- One shared content attempt per client; terminal failure cannot pop in late.
local Gate = {}
function Gate.finish(state: string, loaded: number, expected: number, succeeded: boolean): string
	if state ~= "loading" then return state end
	return succeeded and loaded == expected and expected > 0 and "ready" or "fallback"
end
return Gate
