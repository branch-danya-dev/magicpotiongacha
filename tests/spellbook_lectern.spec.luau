--!strict
-- The lectern is a visual fit. Crystal id, Essence rate and station spacing stay put.
local Test = require("./Test")
local Plan = require("../src/shared/SpellbookLecternPlan")
local Config = require("../src/shared/Config")
local Props = require("../src/shared/PropPlan")

return function(T: typeof(Test))
	T.test("spellbook lectern scales uniformly and stays clear of the other stations", function()
		local scale = Plan.uniformScale(Plan.file.y)
		T.truthy(math.abs(scale * Plan.file.y - Plan.targetHeight) < 0.001)
		T.truthy(math.abs((Plan.file.x * scale) / Plan.file.x - (Plan.file.z * scale) / Plan.file.z) < 0.001)
		local size = { x = Plan.file.x * scale, y = Plan.targetHeight, z = Plan.file.z * scale }
		local stations = Config.stations :: any
		local crystal = stations.crystal.offset
		local nearest = 1000
		for id, station in pairs(stations) do
			if id ~= "crystal" then
				local dx = crystal[1] - station.offset[1]
				local dz = crystal[3] - station.offset[3]
				nearest = math.min(nearest, math.sqrt(dx * dx + dz * dz))
			end
		end
		T.truthy(nearest - size.x / 2 > 8)
		local energy = Plan.point(Plan.energy, size)
		local particles = Plan.point(Plan.particles, size)
		T.truthy(energy[2] > size.y * 0.79 and energy[2] < size.y * 0.9)
		T.truthy(particles[2] > energy[2] and particles[2] < size.y)
		T.equal(Plan.stationId, "crystal")
		T.equal(Plan.templateName, "SpellbookLectern")
		T.truthy(Plan.replaces("crystal"))
		T.falsy(Plan.replaces("garden"))
		T.equal(Config.stations.crystal.name, "Magic crystal")
		T.equal(Config.manualClickEssence, 1)
		local pieces = Props.station(Config :: any, "crystal")
		T.truthy(#pieces >= 5)
		for _, piece in ipairs(pieces) do
			T.falsy(piece.name == "Spellbook" or piece.name == "Lectern")
		end
	end)
end
