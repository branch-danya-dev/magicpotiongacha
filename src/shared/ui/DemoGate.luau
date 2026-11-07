--!strict
-- The foundation preview is a Studio developer switch, not a player surface.
local Gate = {}

function Gate.allowed(isStudio: boolean, flag: boolean): boolean
	return isStudio == true and flag == true
end

-- Studio shows the preview unless the attribute is explicitly false.
function Gate.preview(isStudio: boolean, flag: boolean?): boolean
	return isStudio == true and flag ~= false
end

return Gate
