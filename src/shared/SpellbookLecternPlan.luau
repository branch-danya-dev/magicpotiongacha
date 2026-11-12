--!strict
-- Placement for the imported Spellbook Lectern. Crystal and Essence stay the gameplay ids.
-- File measures come from assets/props/spellbook-lectern.glb and are only used to keep scale uniform.
local Plan = {}
local runtimeScript = rawget(getfenv(), "script")
local Assets: {[string]: string} = if runtimeScript then (require :: any)(runtimeScript.Parent.SpellbookAssets) else require("./SpellbookAssets")

Plan.templateName = "SpellbookLectern"
Plan.stationId = "crystal"
Plan.targetHeight = 6.5
Plan.tag = "SpellbookLecternVisual"
Plan.loadTimeout = 15
Plan.assets = Assets
Plan.meshCount = 23
-- Measured from the GLB node bounds: footprint 6.24, height 5.664, base at y = 0.
-- Energy sits just above the open pages (page top 4.485). Particles rise from that point.
Plan.file = { x = 6.24, y = 5.664, z = 6.24 }
Plan.energy = { 0, 4.65, 0.15 }
Plan.particles = { 0, 4.95, 0.15 }

function Plan.validHeight(height: number): boolean
	return height == height and height > 0.05 and height < 1000
end

function Plan.uniformScale(importedHeight: number): number
	if not Plan.validHeight(importedHeight) then
		return 1
	end
	return Plan.targetHeight / importedHeight
end

function Plan.validateParts(parts: {any}): (boolean, string?)
	if #parts ~= Plan.meshCount then return false, "mesh-count" end
	local seen: {[string]: boolean} = {}
	for _, part in ipairs(parts) do
		if type(part.name) ~= "string" or seen[part.name] or Assets[part.name] ~= part.meshId then
			return false, "mesh-contract"
		end
		if part.textureId ~= "" or not part.anchored or part.collides then return false, "unsafe-mesh" end
		seen[part.name] = true
	end
	return true, nil
end

function Plan.point(filePoint: { number }, size: { x: number, y: number, z: number }): { number }
	return {
		filePoint[1] / Plan.file.x * size.x,
		filePoint[2] / Plan.file.y * size.y,
		filePoint[3] / Plan.file.z * size.z,
	}
end

function Plan.replaces(stationId: string): boolean
	return stationId == Plan.stationId
end

return Plan
