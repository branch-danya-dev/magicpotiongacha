--!nonstrict
-- Bounded, pure rules. Epoch and construction phase are independent axes.
local Epochs={}
function Epochs.id(p) return p.rebirths%3 end
function Epochs.rules(config,p) return config.epochRules[Epochs.id(p)] end
function Epochs.available(config,p,recipe)
	return recipe~=nil and (recipe.epoch==nil or recipe.epoch==Epochs.id(p))
end
function Epochs.cost(config,p,base) return base and math.floor((base*math.floor(Epochs.rules(config,p).cost*100+0.5)+99)/100) end
function Epochs.sale(config,p,base) return math.floor(base*math.floor(Epochs.rules(config,p).sale*100+0.5)/100) end
function Epochs.work(p) return 1+0.05*(p.longTerm and p.longTerm.perks.industry or 0) end
function Epochs.essence(p) return p.longTerm and p.longTerm.perks.essence or 0 end
function Epochs.duration(config,p,base) return base*Epochs.rules(config,p).duration/Epochs.work(p) end
return Epochs
