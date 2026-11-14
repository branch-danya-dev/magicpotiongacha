--!nonstrict
-- AG70 review palette: projection of the existing continuous time/weather state.
-- No clock, renderer, asset, reward, release flag or second lighting owner.
local Forest={releaseEnabled=false,version="2.1-iteration5"}
function Forest.default(studio) return studio==true and "AG70" or "OFF" end
function Forest.request(value) return value=="look:AG70" and "AG70" or nil end
local function mix(a,b,t)
	if type(a)=="table" then return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
	return a+(b-a)*t
end
local palette={
	day={brightness=2.7,exposure=-.12,ambient={37,69,92},outdoor={97,133,157},
		tint={233,248,255},sky={135,196,214},decay={83,111,151},sun={255,219,165},
		saturation=.02,contrast=.19,density=.30,haze=1.5,glare=.16,diffuse=.25},
	-- The pilot ridge occludes the low sun: lift warm fill locally and retain
	-- violet shadow separation instead of flattening the entire cycle.
	sunset={brightness=3.0,exposure=.10,ambient={70,83,113},outdoor={129,145,174},
		tint={255,246,237},sky={243,187,164},decay={77,95,151},sun={255,174,87},
		saturation=.025,contrast=.11,density=.32,haze=1.8,glare=.24,diffuse=.18},
	night={brightness=1.8,exposure=.02,ambient={43,61,95},outdoor={85,112,160},
		tint={237,244,255},sky={78,102,157},decay={39,58,106},sun={146,187,255},
		saturation=.015,contrast=.035,density=.34,haze=1.85,glare=.01,diffuse=.10},
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
	if quality=="minimal" then r.contrast*=.55; r.outdoor=mix(r.outdoor,{85,112,160},night*.20) end
	return r
end
-- Retune the existing bounded lamps and canopy pools, never add a light.
function Forest.localLight(sample,kind)
	local key=sample.warm*(1-sample.night)*(1-sample.cloud)*(1-sample.rain)
	if kind=="lantern" then return {brightness=.14+sample.night*2.9+.55*key,color={255,191,105},range=14+6*sample.night+2*key} end
	return {brightness=.7*sample.sunlight+key*1.65+sample.night*1.55,
		color=mix(mix({255,225,171},{255,188,108},key),{146,191,255},sample.night),
		range=22+14*sample.night+20*key,angle=75+30*sample.night+25*key}
end
-- Reuse two fixed pools. A sunward offset gives the sunset key direction even
-- behind the ridge; night coverage joins the entrance and production path.
-- No camera/avatar following, raycasts per frame or additional light slots.
function Forest.pool(sample,index,sunX,sunZ)
	local day=index==1 and {-148.5,-73} or {-119,-102}
	local route=index==1 and {-142.5,-71} or {-142.5,-43}
	local key=sample.warm*(1-sample.night)*(1-sample.cloud)*(1-sample.rain)
	local blend=math.max(sample.night,key)
	local target={day[1]+(route[1]-day[1])*blend,day[2]+(route[2]-day[2])*blend}
	local length=math.sqrt(sunX*sunX+sunZ*sunZ)
	local offset=length>1e-5 and 18*key/length or 0
	return {x=target[1],z=target[2],dx=sunX*offset,dz=sunZ*offset,height=14+2*sample.night+4*key}
end
return Forest
