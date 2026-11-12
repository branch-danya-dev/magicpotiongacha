--!nonstrict
-- AG63: pure relative look projection. No clock, engine owner, assets or economy.
local Look={default="OFF"}
Look.presets={
	A={brightness=1.04,exposure=-.04,ambient={168,158,140},ambientMix=.13,
		outdoor={195,188,160},outdoorMix=.12,tint={255,251,238},tintMix=.32,
		saturation=-.015,contrast=-.010,density=.92,densityAdd=0,haze=.80,bloom=.35,
		sun={255,229,194},sunMix=.10,warm=true},
	B={brightness=1.02,exposure=-.05,ambient={108,138,183},ambientMix=.28,
		outdoor={143,173,199},outdoorMix=.18,tint={224,235,255},tintMix=.30,
		saturation=.018,contrast=.018,density=1,densityAdd=.016,haze=1.15,bloom=.65,
		sun={211,226,255},sunMix=.12,warm=false},
	C={brightness=1.06,exposure=-.07,ambient={105,129,166},ambientMix=.24,
		outdoor={211,183,147},outdoorMix=.16,tint={249,242,233},tintMix=.14,
		saturation=-.025,contrast=.070,density=.94,densityAdd=0,haze=1.05,bloom=.45,
		sun={255,208,158},sunMix=.22,warm=true},
}
function Look.valid(value) return value=="OFF" or (type(value)=="string" and Look.presets[value]~=nil) end
function Look.request(text)
	if type(text)~="string" then return nil end
	local value=string.match(text,"^look:([A-Z]+)$")
	return if Look.valid(value) then value else nil
end
local function mix(a,b,t) return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
function Look.project(sample,name,quality,baseBloom)
	local p=Look.presets[name]
	if not p then return nil end -- OFF does not write anything over the baseline.
	local strength=if quality=="minimal" then .55 else if quality=="full" then 1 else .85
	local daylight=1-sample.night
	local warmth=if p.warm then 1-.75*sample.night else 1
	-- Night contrast is attenuated; weather/cloud/sun position never change.
	return {
		brightness=sample.brightness*(1+(p.brightness-1)*strength),
		exposure=sample.exposure+p.exposure*strength,
		ambient=mix(sample.ambient,p.ambient,p.ambientMix*strength*(if name=="A" then warmth else 1)),
		outdoor=mix(sample.outdoor,p.outdoor,p.outdoorMix*strength*warmth),
		tint=mix(sample.tint,p.tint,p.tintMix*strength),
		sun=mix(sample.sun,p.sun,p.sunMix*strength*daylight*(1-sample.cloud)),
		saturation=sample.saturation+p.saturation*strength,
		contrast=.025+p.contrast*strength*(1-.55*sample.night),
		density=math.clamp(sample.density*(1+(p.density-1)*strength)
			+(quality=="minimal" and 0 or p.densityAdd*strength),.10,.38),
		haze=sample.haze*(quality=="minimal" and 1 or 1+(p.haze-1)*strength),
		bloom=if quality=="minimal" then 0 else baseBloom*p.bloom,
	}
end
return Look
