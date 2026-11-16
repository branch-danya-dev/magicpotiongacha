--!nonstrict
-- QA data projection only. Unchanged EnvironmentView remains the sole owner.
local Base=require(script.Parent.AtmosphereStyleBase)
local Style=table.clone(Base)
function Style.apply(r)
	r=Base.apply(r)
	r.saturation=-.22+.08*r.night
	r.diffuse=.58+.16*r.night
	r.tint={246-22*r.night,246-13*r.night,245}
	return r
end
return Style
