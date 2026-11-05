--!nonstrict
local State={}
local function smooth(x) x=math.clamp(x,0,1); return x*x*(3-2*x) end
local function lerp(a:any,b:any,t:number):any
	if type(a)=="table" then return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
	return a+(b-a)*t
end
function State.sample(config:any,serverSeconds:number,pose:string?):any
	assert(type(serverSeconds)=="number" and serverSeconds==serverSeconds and math.abs(serverSeconds)<1e13,"Invalid environment clock")
	local preview=pose and config.poses[pose]
	local phase=preview and preview.phase or (serverSeconds%config.cycleSeconds)/config.cycleSeconds
	local weather=serverSeconds%config.weatherSeconds
	local rain=preview and preview.rain or smooth((weather-900)/90)*(1-smooth((weather-1470)/90))
	local a,b=config.keys[1],config.keys[2]
	for i=1,#config.keys-1 do if phase>=config.keys[i].phase and phase<config.keys[i+1].phase then a,b=config.keys[i],config.keys[i+1]; break end end
	local t=smooth((phase-a.phase)/(b.phase-a.phase)); local r:any={phase=phase,rain=rain}
	for key,value in pairs(a) do if key~="phase" then r[key]=lerp(value,b[key],t) end end
	r.clock%=24; r.brightness*=1-.22*rain; r.density+=.10*rain; r.haze+=.4*rain
	r.cover=.25+.53*rain; r.cloudDensity=.32+.30*rain; r.tint=lerp(r.tint,{224,234,237},rain*.45)
	r.night=1-smooth(math.abs(r.clock-0)>12 and (24-r.clock)/7 or r.clock/7)
	return r
end
function State.quality(config,name,reduceMotion)
	local q=config.quality[name] or config.quality.reduced; local result={}
	for k,v in pairs(q) do result[k]=v end
	if reduceMotion then result.motion=0; result.rain=0 end
	return result
end
function State.surface(config,rebirths,aurora)
	if aurora then return {color={96,116,168},material="Neon"} end -- Existing M6 entitlement semantics.
	local colors={config.palette.grass,{148,153,108},{113,146,131}}
	return {color=colors[rebirths%3+1],material="Grass"}
end
return State
