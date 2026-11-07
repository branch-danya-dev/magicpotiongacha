--!strict
-- Placement for the imported Spellbook Lectern. Crystal and Essence stay the gameplay ids.
-- File measures come from assets/props/spellbook-lectern.glb and are only used to keep scale uniform.
local Plan = {}

Plan.templateName = "SpellbookLectern"
Plan.stationId = "crystal"
Plan.targetHeight = 6.5
-- Measured from the GLB node bounds: footprint 6.24, height 5.664, base at y = 0.
-- Energy sits just above the open pages (page top 4.485). Particles rise from that point.
Plan.file = { x = 6.24, y = 5.664, z = 6.24 }
Plan.energy = { 0, 4.65, 0.15 }
Plan.particles = { 0, 4.95, 0.15 }

function Plan.uniformScale(importedHeight: number): number
	if importedHeight <= 0.001 then
		return 1
	end
	return Plan.targetHeight / importedHeight
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
