--!nonstrict
-- AG68: art direction projected from the sole EnvironmentState sample. No clock,
-- instances, assets or gameplay state. Cheap palette survives every quality tier.
local WorldLook={releaseEnabled=false}
function WorldLook.default(studio) return studio==true and "AG68" or "OFF" end
function WorldLook.request(value) return value=="look:AG68" and "AG68" or nil end
local function mix(a,b,t)
	if type(a)=="table" then return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
	return a+(b-a)*t
end
WorldLook.palette={
	day={brightness=2.65,exposure=-.06,ambient={66,107,142},outdoor={125,164,186},
		tint={221,243,255},sky={137,202,227},decay={92,115,172},sun={255,218,158},
		saturation=.025,contrast=.145,density=.29,haze=1.35,glare=.18},
	sunset={brightness=2.7,exposure=.30,ambient={117,101,161},outdoor={192,149,172},
		tint={255,222,231},sky={249,170,191},decay={114,99,166},sun={255,161,89},
		saturation=.045,contrast=.115,density=.32,haze=1.75,glare=.27},
	night={brightness=1.9,exposure=.72,ambient={124,141,224},outdoor={156,177,241},
		tint={218,218,255},sky={85,90,169},decay={54,57,121},sun={159,191,255},
		saturation=.06,contrast=.09,density=.30,haze=1.20,glare=.02},
	dawn={brightness=2.55,exposure=.14,ambient={103,150,156},outdoor={162,186,183},
		tint={247,229,247},sky={231,184,218},decay={123,143,185},sun={255,205,164},
		saturation=.035,contrast=.105,density=.30,haze=1.45,glare=.16},
}
WorldLook.quality={
	full={bloom=.16,rays=.035,size=24,threshold=1.45,baseBloom=.04,baseRays=.02},
	reduced={bloom=.085,rays=.012,size=20,threshold=1.55,baseBloom=.012,baseRays=.008},
	minimal={bloom=0,rays=0,size=18,threshold=2.3,baseBloom=1,baseRays=1},
}
function WorldLook.project(sample,name,quality,baseBloom,baseRays)
	if name~="AG68" then return nil end
	local q=WorldLook.quality[quality] or WorldLook.quality.reduced
	local p={}
	-- Continuous channels also remain continuous during an interrupted weather or
	-- time transition. Never derive a discrete palette from the wall clock/pose.
	for key,day in pairs(WorldLook.palette.day) do
		local value=mix(day,WorldLook.palette.sunset[key],sample.warm)
		value=mix(value,WorldLook.palette.dawn[key],sample.dawn)
		p[key]=mix(value,WorldLook.palette.night[key],sample.night)
	end
	local cloud,rain=sample.cloud,sample.rain
	p.brightness*=1-.16*cloud-.12*rain
	p.exposure-=.03*cloud
	p.ambient=mix(p.ambient,{111,132,168},cloud*.32)
	p.outdoor=mix(p.outdoor,{142,162,188},cloud*.42)
	p.tint=mix(p.tint,{215,230,250},cloud*.40)
	p.sky=mix(p.sky,{140,161,195},cloud*.65)
	p.sun=mix(p.sun,{177,197,225},cloud*.85)
	p.density=math.clamp(p.density+.025*rain-.02*sample.afterRain,.20,.36)
	p.haze+=.50*rain-.25*sample.afterRain
	p.glare*=1-cloud
	p.contrast*=1-.25*cloud
	p.saturation-=.08*cloud
	p.diffuse=.37-.06*cloud; p.specular=.07+.05*sample.wet*(1-sample.night)
	p.bottom={16,23,49}
	-- Reuse the owner's smoother without feeding the projection back into it.
	-- A downward tier switch is capped immediately; Minimal always disables both.
	p.bloom=q.bloom*math.clamp((baseBloom or q.baseBloom)/q.baseBloom,0,1)
	p.rays=q.rays*math.clamp((baseRays or q.baseRays)/q.baseRays,0,1)*(1-rain)*(1-sample.night)
	p.bloomSize=q.size; p.bloomThreshold=q.threshold
	return p
end
return WorldLook
