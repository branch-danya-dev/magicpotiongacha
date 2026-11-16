--!nonstrict
-- QA data projection only. Unchanged EnvironmentView remains the sole owner.
local Base=require(script.Parent.AtmosphereStyleBase)
local Style=table.clone(Base)
function Style.apply(r)
	r=Base.apply(r)
	r.saturation=.035-.06*r.night
	r.diffuse=.62+.12*r.night
	r.tint={246-16*r.warm-22*r.night,250-13*r.warm-17*r.night,255}
	return r
end
return Style
