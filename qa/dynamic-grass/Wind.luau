--!nonstrict
-- Input to the existing EnvironmentView owner, not a Workspace writer.
local W={period=12}
function W.sample(sample,time,reduceMotion)
	if reduceMotion then return {strength=0,x=0,z=0} end
	local pulse=((1-math.cos(time*math.pi*2/W.period))*.5)^3
	local strength=.24+.48*pulse+math.clamp(sample.wind or 0,0,1)*.12
	local direction=.12*math.sin(time*.17)
	return {strength=strength,x=(5+10*pulse)*math.cos(direction),z=2+2*pulse}
end
return W
