--!nonstrict
-- One cyclic phase controls both sun time and celestial overlays. Manual weather
-- is independent of that phase; these functions never write Lighting or a save.
local Clock={weather={clear={rain=0,cloud=0,wet=0,afterRain=0},
	buildup={rain=0,cloud=.75,wet=0,afterRain=0},rain={rain=1,cloud=1,wet=1,afterRain=0},
	clearing={rain=.2,cloud=.6,wet=1,afterRain=.2},afterrain={rain=0,cloud=.15,wet=.85,afterRain=1}}}
function Clock.at(config,phase)
	phase%=1
	for i=1,#config.keys-1 do
		local a,b=config.keys[i],config.keys[i+1]
		if phase>=a.phase and phase<b.phase then
			local t=(phase-a.phase)/(b.phase-a.phase); t=t*t*(3-2*t)
			return (a.clock+(b.clock-a.clock)*t)%24
		end
	end
	return config.keys[1].clock%24
end
function Clock.phase(config,hour)
	if type(hour)~="number" or hour~=hour or math.abs(hour)==math.huge then return nil end
	local target=hour%24; local base=config.keys[1].clock%24
	if target<base then target+=24 end
	local low,high=0,1
	for _=1,30 do
		local mid=(low+high)/2; local value=Clock.at(config,mid)
		if value<base then value+=24 end
		if value<target then low=mid else high=mid end
	end
	return (low+high)/2
end
function Clock.effect(previous,target,dt)
	return previous+(target-previous)*(1-math.exp(-8*math.max(0,dt)))
end
function Clock.request(config,text: any)
	if type(text)~="string" or #text>32 then return nil end
	if text=="auto" then return {kind="pose"} end
	if text=="preview" then return {kind="preview",value=true} end
	if config.poses[text] then return {kind="pose",value=text} end
	local hour=string.match(text,"^time:([%d%.]+)$")
	if hour then
		local value=tonumber(hour)
		if value and value>=0 and value<24 then return {kind="time",value=value} end
	end
	local weather=string.match(text,"^weather:([a-z]+)$")
	if weather and Clock.weather[weather] then return {kind="weather",value=weather} end
	return nil
end
return Clock
