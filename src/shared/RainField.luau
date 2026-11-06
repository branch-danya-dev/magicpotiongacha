--!nonstrict
-- Camera-local rain. Weather intensity stays in EnvironmentState; this only places drops.
local Field = {}
local GOLDEN = 2.399963229728653

function Field.offset(index)
	local radius = 6 + ((index * 5) % 14)
	local angle = (index * GOLDEN) % (math.pi * 2)
	return math.cos(angle) * radius, math.sin(angle) * radius
end

function Field.world(index, cameraX, cameraZ)
	local x, z = Field.offset(index)
	return cameraX + x, cameraZ + z
end

function Field.visible(index, limit, amount, inside)
	return index <= limit and (tonumber(amount) or 0) > 0 and inside == true
end

return Field
