--!nonstrict
local M={}
local function copy(t) local r={};for k,v in pairs(t) do r[k]=type(v)=="table" and copy(v) or v end;return r end
function M.build(base)
	local c=copy(base);c.cycleSeconds=1500
	local plan={{0,8.5,1},{.2,17.5,2},{.325,18.55,2},{.45,20.5,4},{.675,24,4},{.9,29,4},{.95,30.1,6},{1,32.5,1}}
	c.keys={}
	for i,p in ipairs(plan) do local k=copy(base.keys[p[3]]);k.phase=p[1];k.clock=p[2];c.keys[i]=k end
	c.keys[2].night=.08;c.keys[2].warm=.6
	c.keys[3].night=.55;c.keys[3].warm=.25
	for i=4,6 do local k=c.keys[i];k.night=1;k.dawn=0;k.warm=0
		k.ambient={147,166,192};k.outdoor={162,182,211};k.brightness=2.6;k.exposure=.32;k.density=.13;k.haze=.12
	end
	c.keys[7].night=.18;c.keys[7].dawn=1
	c.poses.day={phase=.1,rain=0,cloud=.08}
	c.poses.dusk={phase=.325,rain=0,cloud=.08}
	c.poses.night={phase=.45,rain=0,cloud=.08}
	c.poses.dawn={phase=.95,rain=0,cloud=.08}
	c.poses.dawnend={phase=.99999,rain=0,cloud=.08}
	return c
end
return M
