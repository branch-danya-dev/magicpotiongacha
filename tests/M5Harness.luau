--!nonstrict
local M=require("./M3Harness")
local Config=require("../src/shared/Config")
local LongTerm=require("../src/shared/LongTerm")
local Epochs=require("../src/shared/Epochs")
local H={copy=M.copy,count=M.count}
function H.new()
	local h=M.new(); h.longTerm=LongTerm.new(Config)
	function h.run(action,payload,profile,context)
		profile=profile or h.profile; payload=M.copy(payload or {})
		payload.requestId=payload.requestId or profile.longTerm.sequence+1
		context=context or {}; context.now=context.now or math.floor(h.now)
		return h.longTerm.apply(profile,action,payload,h.engine,context)
	end
	function h.complete()
		h.toPhase(4)
		local recipeId=Epochs.rules(Config,h.profile).finalRecipe; local recipe=Config.recipes[recipeId]
		-- Explicit rich unit fixture only. Earned economy traces live in m5_acceptance.spec.
		local station=h.built("cauldron2",3,recipeId)
		station.input=M.copy(recipe.inputs); station.essence=recipe.essenceCost
		h.act("brew",{stationId="cauldron2"}); h.advance(30)
		assert(h.profile.longTerm.cycle.finalProduced)
	end
	function h.rebirth()
		return h.run("rebirth",{expectedRebirthCount=h.profile.rebirths,confirmed=true})
	end
	return h
end
return H
