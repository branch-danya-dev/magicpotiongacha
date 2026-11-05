--!nonstrict
local runtimeScript=rawget(getfenv(),"script")
local Style=require(runtimeScript and runtimeScript.Parent.AtmosphereStyle or "./AtmosphereStyle")
local State={}
local function smooth(x) x=math.clamp(x,0,1); return x*x*(3-2*x) end
local function lerp(a:any,b:any,t:number):any
	if type(a)=="table" then return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
	return a+(b-a)*t
end
-- Independent weather envelope. Each overlay has zero slope at stage boundaries.
-- Stages: clear, buildup, rain, clearing, after-rain, clear. Labels are diagnostic
-- only; the renderer consumes continuous channels, never switches on a stage.
function State.weather(config,time)
	local w=config.weather; local t=time%config.weatherSeconds
	local buildup=w.buildup or 0; local clearing=w.clearing or 0; local after=w.afterRain or 0
	local endRain=w.finish+w.fall; local endClear=endRain+clearing
	local rain=smooth((t-w.start)/w.rise)*(1-smooth((t-w.finish)/w.fall))
	local cloud=(buildup>0 and smooth((t-w.start+buildup)/buildup) or rain)
		*(clearing>0 and (1-smooth((t-endRain)/clearing)) or (1-smooth((t-w.finish)/w.fall)))
	local wet=smooth((t-w.start)/w.rise)*(1-smooth((t-endRain)/math.max(1,clearing+after)))
	local afterRain=clearing>0 and smooth((t-endRain)/clearing)*(1-smooth((t-endClear)/math.max(1,after))) or 0
	return {rain=rain,cloud=cloud,wet=wet,afterRain=afterRain}
end
function State.weatherStage(config,time)
	local w=config.weather; local t=time%config.weatherSeconds
	if t<w.start-(w.buildup or 0) then return "clear" end
	if t<w.start then return "buildup" end
	if t<w.finish+w.fall then return "rain" end
	if t<w.finish+w.fall+(w.clearing or 0) then return "clearing" end
	if t<w.finish+w.fall+(w.clearing or 0)+(w.afterRain or 0) then return "after-rain" end
	return "clear"
end
function State.at(config:any,phase:number,rain:number,weather:any?):any
	assert(phase==phase and rain==rain and phase>=0 and phase<1 and rain>=0 and rain<=1,"Invalid environment sample")
	local a,b=config.keys[1],config.keys[2]
	for i=1,#config.keys-1 do if phase>=config.keys[i].phase and phase<config.keys[i+1].phase then a,b=config.keys[i],config.keys[i+1]; break end end
	local t=smooth((phase-a.phase)/(b.phase-a.phase)); local r:any={phase=phase,rain=rain}
	for key,value in pairs(a) do if key~="phase" then r[key]=lerp(value,b[key],t) end end
	local w=weather or {cloud=rain,wet=rain,afterRain=0}
	r.cloud=w.cloud or rain; r.wet=w.wet or rain; r.afterRain=w.afterRain or 0
	r.clock%=24; r.brightness*=1-.16*r.cloud-.16*rain; r.density+=.045*rain-.025*r.afterRain; r.haze+=.45*rain-.25*r.afterRain
	r.cover=.12+.72*r.cloud; r.cloudDensity=.22+.5*r.cloud
	r.tint=lerp(r.tint,{218,235,246},r.cloud*.32); r.sky=lerp(r.sky,{163,186,204},r.cloud*.6)
	r.sun=lerp(r.sun,{182,199,215},r.cloud*.82); r.cloudColor=lerp({240,237,229},{145,167,189},r.cloud)
	r.fog=math.max(r.dawn,rain*.22); r.glint=math.max(r.dawn*.7,r.wet*(1-rain))*(1-r.night)
	r.celestial=smooth((r.night-.22)/.55)*(1-smooth(r.cloud/.85))
	r.wetStone=r.wet*(1-rain*.2)
	r.wind=.25+.5*r.cloud+.25*rain
	-- Eligibility only: renderer also checks actual sun elevation/view direction.
	r.rainbow=r.afterRain*(1-r.night)*(1-r.cloud)
	return Style.apply(r)
end
-- Art-directed celestial path, deliberately lower than the engine's zenith moon.
-- World-oriented, never locked to camera rotation. Smooth/periodic at the cycle seam.
function State.moon(phase)
	local az=math.rad(15+12*math.sin(phase*math.pi*2)); local el=math.rad(20+3*math.cos(phase*math.pi*2))
	return {math.sin(az)*math.cos(el),math.sin(el),-math.cos(az)*math.cos(el)}
end
function State.star(index)
	local az=index<=16 and (-60+(index*37%120)) or (index*137.507764%360)
	local el=12+(index*23%59)
	local a,e=math.rad(az),math.rad(el)
	return {x=math.sin(a)*math.cos(e),y=math.sin(e),z=-math.cos(a)*math.cos(e),size=1.5+(index%4)*.6,alpha=.6+(index%3)*.15}
end
function State.sample(config:any,serverSeconds:number,pose:string?):any
	assert(type(serverSeconds)=="number" and serverSeconds==serverSeconds and math.abs(serverSeconds)<1e13,"Invalid environment clock")
	local preview=pose and config.poses[pose]
	local phase=preview and preview.phase or (serverSeconds%config.cycleSeconds)/config.cycleSeconds
	local w=preview and {rain=preview.rain,cloud=preview.cloud or preview.rain,wet=preview.wet or preview.rain,afterRain=preview.afterRain or 0} or State.weather(config,serverSeconds)
	return State.at(config,phase,w.rain,w)
end
function State.preview(config,elapsed)
	assert(elapsed==elapsed and math.abs(elapsed)<1e13,"Invalid preview time")
	local phase=(elapsed%config.previewSeconds)/config.previewSeconds
	local rain=smooth((phase-.72)/.06)*(1-smooth((phase-.87)/.04))
	local cloud=smooth((phase-.65)/.07)*(1-smooth((phase-.89)/.06))
	local wet=smooth((phase-.72)/.06)*(1-smooth((phase-.96)/.04))
	local afterRain=smooth((phase-.91)/.04)*(1-smooth((phase-.97)/.03))
	return State.at(config,phase,rain,{cloud=cloud,wet=wet,afterRain=afterRain})
end
function State.quality(config,name,reduceMotion)
	local q=config.quality[name] or config.quality.reduced; local result={}
	for k,v in pairs(q) do result[k]=v end
	if reduceMotion then result.motion=0; result.rain=0; result.motes=0 end
	return result
end
-- Bounded deterministic local motes, never rewards or simulation inputs.
function State.mote(index,time,night,rain)
	local firefly=index%3~=0
	local x=-142.5+(index%2==0 and -1 or 1)*(30+(index*7%13))
	local z=-65-43+(index*19%66)
	return {x=x+math.sin(time*.27+index)*1.2,y=2.7+(index%5)*.7+math.sin(time*.38+index)*.5,
		z=z+math.cos(time*.23+index)*1.1,firefly=firefly,
		alpha=(firefly and night*.65 or (1-night)*.24)*(1-rain*.9)*(.85+.15*math.sin(time*.55+index))}
end
-- TASK06_STYLE_BEGIN: all consumers share this state; Style has no owner/clock.
State.wind=Style.wind
State.pollen=Style.pollen
State.sunSlots=Style.sunSlots
State.sunVisibility=Style.sunVisibility
-- TASK06_STYLE_END
function State.surface(config,rebirths,aurora)
	if aurora then return {color={96,116,168},material="Neon"} end -- Existing M6 entitlement semantics.
	local colors={config.palette.grass,{148,153,108},{113,146,131}}
	return {color=colors[rebirths%3+1],material="Grass"}
end
return State
