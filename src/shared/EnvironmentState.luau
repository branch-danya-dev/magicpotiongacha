--!nonstrict
local State={}
local function smooth(x) x=math.clamp(x,0,1); return x*x*(3-2*x) end
local function lerp(a:any,b:any,t:number):any
	if type(a)=="table" then return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
	return a+(b-a)*t
end
function State.at(config:any,phase:number,rain:number):any
	assert(phase==phase and rain==rain and phase>=0 and phase<1 and rain>=0 and rain<=1,"Invalid environment sample")
	local a,b=config.keys[1],config.keys[2]
	for i=1,#config.keys-1 do if phase>=config.keys[i].phase and phase<config.keys[i+1].phase then a,b=config.keys[i],config.keys[i+1]; break end end
	local t=smooth((phase-a.phase)/(b.phase-a.phase)); local r:any={phase=phase,rain=rain}
	for key,value in pairs(a) do if key~="phase" then r[key]=lerp(value,b[key],t) end end
	r.clock%=24; r.brightness*=1-.32*rain; r.density+=.07*rain; r.haze+=.6*rain
	r.cover=.18+.68*rain; r.cloudDensity=.28+.43*rain; r.tint=lerp(r.tint,{225,237,246},rain*.35)
	r.sky=lerp(r.sky,{177,197,212},rain*.7); r.sun=lerp(r.sun,{182,199,215},rain*.85)
	r.cloudColor=lerp({238,238,240},{168,184,201},rain)
	return r
end
function State.sample(config:any,serverSeconds:number,pose:string?):any
	assert(type(serverSeconds)=="number" and serverSeconds==serverSeconds and math.abs(serverSeconds)<1e13,"Invalid environment clock")
	local preview=pose and config.poses[pose]
	local phase=preview and preview.phase or (serverSeconds%config.cycleSeconds)/config.cycleSeconds
	local weather=serverSeconds%config.weatherSeconds; local w=config.weather
	local rain=preview and preview.rain or smooth((weather-w.start)/w.rise)*(1-smooth((weather-w.finish)/w.fall))
	return State.at(config,phase,rain)
end
function State.preview(config,elapsed)
	assert(elapsed==elapsed and math.abs(elapsed)<1e13,"Invalid preview time")
	local phase=(elapsed%config.previewSeconds)/config.previewSeconds
	return State.at(config,phase,smooth((phase-.72)/.06)*(1-smooth((phase-.90)/.07)))
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
function State.surface(config,rebirths,aurora)
	if aurora then return {color={96,116,168},material="Neon"} end -- Existing M6 entitlement semantics.
	local colors={config.palette.grass,{148,153,108},{113,146,131}}
	return {color=colors[rebirths%3+1],material="Grass"}
end
return State
