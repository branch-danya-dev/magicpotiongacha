--!nonstrict
local H=require("./M2Harness")
local Config=require("../src/shared/Config")
local Progression=require("../src/shared/Progression")
local M={copy=H.copy,count=H.count}
function M.new()
	local h=H.new(); h.progression=Progression.new(Config)
	function h.command(action,payload,profile)
		h.now+=1; profile=profile or h.profile; payload=H.copy(payload)
		payload.requestId=payload.requestId or profile.progression.sequence+1
		return h.progression.apply(profile,action,payload,h.engine,h.now)
	end
	function h.act(action,payload)
		local ok,reason=h.engine.act(h.profile,action,payload or {},h.now); assert(ok,reason); assert(h.engine.validate(h.profile))
	end
	function h.advance(seconds,offline)
		h.now+=seconds; local report=h.engine.advance(h.profile,h.now,offline or false); assert(report.ok,report.error); assert(h.engine.validate(h.profile)); return report
	end
	function h.phasePrerequisites()
		local p=h.profile; local target=Config.phases[p.phase+1]; assert(target)
		for id,level in pairs(target.stations) do
			local station=p.stations[id]; station.level=level
			if Config.stations[id].defaultRecipe then station.recipeId=Config.stations[id].defaultRecipe end
		end
		for _,id in ipairs(target.recipes) do p.discoveredRecipes[id]=true end
		if target.pipes then p.pipes=true end
		if target.warehouse then p.warehouseLevel=target.warehouse end
	end
	function h.toPhase(phase)
		while h.profile.phase<phase do h.phasePrerequisites(); local ok,reason=h.command("advancePhase",{expectedPhase=h.profile.phase}); assert(ok,reason) end
	end
	function h.built(slot,level,recipe)
		local station=h.profile.stations[slot]; station.level=level or 1
		station.recipeId=recipe or Config.stations[slot].defaultRecipe
		return station
	end
	return h
end
return M
