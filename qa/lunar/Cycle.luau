--!nonstrict
-- Pure QA presentation: no player, remotes, rewards, persistence or random state.
local M={seconds=1500,fadeSeconds=8,names={"pearl","blood","frost"},durations={300,375,675,150}}
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
M.smooth=smooth
function M.index(seconds)
	assert(type(seconds)=="number" and seconds==seconds and math.abs(seconds)<1e13,"Invalid lunar clock")
	return math.floor(seconds/M.seconds)
end
function M.choose(cycle)
	-- Park-Miller integer arithmetic remains exact in double precision. No math.random.
	local h=((cycle%2147483646)+739391)*48271%2147483647
	h=h*48271%2147483647;h=h*48271%2147483647
	local roll=h%10000
	return roll<7000 and 1 or roll<8000 and 2 or 3
end
function M.period(phase)
	phase%=1
	return phase<.2 and "day" or phase<.45 and "dusk" or phase<.9 and "night" or "dawn"
end
function M.envelope(phase)
	phase%=1
	return smooth((phase-.2)/.25)*(1-smooth((phase-.9)/.1))
end
function M.valid(name) for _,v in ipairs(M.names) do if v==name then return true end end;return name=="auto" end
function M.number(name) for i,v in ipairs(M.names) do if v==name then return i end end;return nil end
function M.new()
	local self={target=nil,from={1,0,0},last={1,0,0},started=0}
	function self.sample(seconds,now,forced)
		local target=M.number(forced) or M.choose(M.index(seconds))
		if self.target~=target then
			self.from=table.clone(self.last);self.started=now
			if not self.target then self.started=now-M.fadeSeconds end
			self.target=target
		end
		local t=smooth((now-self.started)/M.fadeSeconds)
		for i=1,3 do self.last[i]=self.from[i]+((i==target and 1 or 0)-self.from[i])*t end
		return self.last
	end
	return self
end
local palettes={
	{ambient={143,162,194},outdoor={162,181,209},sun={177,204,251},sky={103,134,184},decay={73,86,140},tint={230,242,255},halo={155,191,239}},
	{ambient={162,145,171},outdoor={181,161,185},sun={225,169,189},sky={145,105,152},decay={112,69,111},tint={250,231,240},halo={183,79,111}},
	{ambient={131,170,185},outdoor={153,190,206},sun={163,224,240},sky={92,153,177},decay={62,113,142},tint={220,249,255},halo={128,222,230}},
}
function M.palette(weights,key)
	local c={0,0,0};for i=1,3 do for j=1,3 do c[j]+=palettes[i][key][j]*weights[i] end end;return c
end
function M.apply(sample,weights)
	local r=table.clone(sample);local strength=M.envelope(r.phase)*(1-.45*r.cloud)
	for _,key in ipairs({"ambient","outdoor","sun","sky","decay","tint"}) do
		local p=M.palette(weights,key);r[key]={}
		for j=1,3 do r[key][j]=sample[key][j]+(p[j]-sample[key][j])*strength end
	end
	-- Fill light survives Minimal (which disables point lights and global shadows).
	r.exposure=sample.exposure+.08*strength;r.brightness=sample.brightness+.12*strength
	r.haze=sample.haze+.08*strength;r.diffuse=sample.diffuse+.06*strength
	return r
end
function M.alpha(sample,elevation)
	return .95*M.envelope(sample.phase)*smooth((elevation+.025)/.15)*(1-smooth(sample.cloud/.9))
end
function M.halo(quality) return quality=="full" and .16 or quality=="reduced" and .08 or 0 end
return M
