--!nonstrict
-- AG70 review palette: projection of the existing continuous time/weather state.
-- No clock, renderer, asset, reward, release flag or second lighting owner.
local Forest={releaseEnabled=false,version="2.1-iteration2"}
function Forest.default(studio) return studio==true and "AG70" or "OFF" end
function Forest.request(value) return value=="look:AG70" and "AG70" or nil end
local function mix(a,b,t)
	if type(a)=="table" then return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
	return a+(b-a)*t
end
local palette={
	day={brightness=2.8,exposure=.02,ambient={50,75,82},outdoor={119,145,149},
		tint={247,255,250},sky={135,196,214},decay={83,111,151},sun={255,219,165},
		saturation=.035,contrast=.13,density=.30,haze=1.5,glare=.16,diffuse=.25},
	sunset={brightness=3.0,exposure=.06,ambient={66,78,108},outdoor={124,137,172},
		tint={255,247,237},sky={243,187,164},decay={77,95,151},sun={255,174,87},
		saturation=.025,contrast=.11,density=.32,haze=1.8,glare=.24,diffuse=.18},
	night={brightness=1.8,exposure=.02,ambient={43,61,95},outdoor={85,112,160},
		tint={237,244,255},sky={78,102,157},decay={39,58,106},sun={146,187,255},
		saturation=.015,contrast=.09,density=.34,haze=1.85,glare=.01,diffuse=.10},
	dawn={brightness=2.5,exposure=.06,ambient={61,87,100},outdoor={130,155,162},
		tint={255,246,248},sky={224,189,204},decay={99,135,162},sun={255,214,173},
		saturation=.045,contrast=.12,density=.31,haze=1.6,glare=.12,diffuse=.23},
}
local tiers={full={bloom=.10,rays=.025,baseBloom=.04,baseRays=.02},
	reduced={bloom=.045,rays=.008,baseBloom=.012,baseRays=.008},
	minimal={bloom=0,rays=0,baseBloom=1,baseRays=1}}
function Forest.project(sample,name,quality,baseBloom,baseRays)
	if name~="AG70" then return nil end
	local r={}
	for key,value in pairs(palette.day) do
		r[key]=mix(mix(mix(value,palette.sunset[key],sample.warm),palette.dawn[key],sample.dawn),palette.night[key],sample.night)
	end
	local cloud,rain,night=sample.cloud,sample.rain,sample.night
	r.brightness*=1-.14*cloud-.10*rain
	-- Weather shifts hue without raising the night fill into an overcast day.
	r.ambient=mix(r.ambient,mix({66,83,108},{45,63,94},night),cloud*.45)
	r.outdoor=mix(r.outdoor,mix({113,134,161},{80,103,146},night),cloud*.5)
	r.tint=mix(r.tint,{226,239,252},cloud*.25)
	r.sky=mix(r.sky,mix({141,165,191},{72,94,144},night),cloud*.65)
	r.sun=mix(r.sun,{177,199,230},cloud*.85)
	r.density=math.clamp(r.density+.022*rain-.025*sample.afterRain,.25,.35)
	r.haze+=.35*rain-.30*sample.afterRain
	r.glare*=1-cloud
	r.contrast-=.03*cloud
	r.saturation-=.06*cloud
	r.diffuse*=1-.2*cloud
	r.specular=.045+.065*sample.wet*(1-night)
	r.bottom={6,11,24}
	local q=tiers[quality] or tiers.reduced
	r.bloom=q.bloom*math.clamp((baseBloom or q.baseBloom)/q.baseBloom,0,1)
	r.rays=q.rays*math.clamp((baseRays or q.baseRays)/q.baseRays,0,1)*(1-rain)*(1-night)
	r.bloomSize=20; r.bloomThreshold=1.9
	-- Minimal preserves the same palette without rays, bloom or local lights.
	if quality=="minimal" then r.contrast*=.72; r.outdoor=mix(r.outdoor,{85,107,149},night*.20) end
	return r
end
-- Retune the existing bounded lamps and canopy pools, never add a light.
function Forest.localLight(sample,kind)
	if kind=="lantern" then return {brightness=.14+sample.night*2.9,color={255,191,105}} end
	return {brightness=.7*sample.sunlight+sample.warm*.55+sample.night*1.45,color=mix({255,225,171},{128,177,255},sample.night)}
end
return Forest
