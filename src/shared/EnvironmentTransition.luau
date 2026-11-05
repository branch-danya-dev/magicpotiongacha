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
	local self={last=nil,from=nil,started=0}
	function self.begin(now)
		self.from=self.last; self.started=now
	end
	function self.sample(target,now)
		local elapsed=now-self.started
		self.last=self.from and Transition.blend(self.from,target,elapsed/Transition.seconds) or target
		if elapsed>=Transition.seconds then self.from=nil end
		return self.last
	end
	return self
end
return Transition
