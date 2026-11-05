--!nonstrict
-- Pure transition inside EnvironmentView's single ownership boundary.
local Transition={seconds=8}
local function wrap(a,b,t,period)
	local delta=(b-a+period/2)%period-period/2
	return (a+delta*t)%period
end
function Transition.blend(a,b,progress)
	if progress<=0 then return a end
	if progress>=1 then return b end
	local t=math.clamp(progress,0,1); t=t*t*(3-2*t)
	local result={}
	for key,value in pairs(b) do
		if type(value)=="table" then
			result[key]={}
			for i,v in ipairs(value) do result[key][i]=a[key][i]+(v-a[key][i])*t end
		elseif key=="clock" or key=="phase" then
			result[key]=wrap(a[key],value,t,key=="clock" and 24 or 1)
		else result[key]=a[key]+(value-a[key])*t end
	end
	return result
end
function Transition.new()
	local self={last=nil,from=nil,started=0,unwrapped={}}
	function self.begin(now)
		self.from=self.last; self.started=now; self.unwrapped={}
	end
	function self.sample(target,now)
		local elapsed=now-self.started
		self.last=self.from and Transition.blend(self.from,target,elapsed/Transition.seconds) or target
		if self.from and elapsed>0 and elapsed<Transition.seconds then
			-- Keep the chosen arc as a moving target passes the antipode. Choosing
			-- the shortest arc again each frame can jump by half a day mid-fade.
			local t=math.clamp(elapsed/Transition.seconds,0,1); t=t*t*(3-2*t)
			for key,period in pairs({clock=24,phase=1}) do
				local previous=self.unwrapped[key] or self.from[key]
				local value=previous+(target[key]-previous+period/2)%period-period/2
				self.unwrapped[key]=value
				self.last[key]=(self.from[key]+(value-self.from[key])*t)%period
			end
		end
		if elapsed>=Transition.seconds then self.from=nil end
		return self.last
	end
	return self
end
return Transition
