--!strict
-- Pure projection of the existing environment sample. No time/moon selection.
local M={}
local function unit(v:number):number return math.clamp(v,0,1) end
function M.advance(phase:number,dt:number,windX:number,windZ:number,quality:string,motion:boolean):number
	if motion or quality=="minimal" then return phase end
	-- Project the owner's world wind onto the landmark's horizontal right axis.
	local speed=math.clamp(windX*.965-windZ*.261,-30,30)
	return phase+math.clamp(dt,0,.2)*speed*.004
end
function M.project(sample:any,weights:{number},quality:string,phase:number,motion:boolean):any
	assert(quality=="full" or quality=="reduced" or quality=="minimal","Invalid landmark quality")
	local night,warm,cloud=unit(sample.night),unit(sample.warm),unit(sample.cloud)
	local blood,frost=unit(weights[2]),unit(weights[3])
	local color={1-.11*night+.035*blood*night-.035*frost*night,1-.13*night-.045*blood*night+.025*frost*night,1-.08*warm-.06*night+.045*frost*night}
	local glow=(.025+.075*night+.05*warm)*(1-.45*cloud)
	if quality=="reduced" then glow*=.55 elseif quality=="minimal" then glow=0 end
	local pulse=(not motion and quality=="full") and 1+.025*math.sin(phase*.7) or 1
	return {tree=(.42+.2*night+.12*warm)*(1-.3*cloud),cloud=(.64-.19*night)*(1+.12*cloud),glow=glow*pulse,
		color=color,glowColor={1,.94-.08*blood*night, .84+.10*frost*night},
		x=.012*math.sin(phase),y=.004*math.sin(phase*.43),
		moving=quality=="full" and not motion and .16 or 0,haze=quality=="full" and .08 or 0,
		minimal=quality=="minimal" and 1 or 0}
end
function M.smooth(a:number,b:number,dt:number):number return a+(b-a)*(1-math.exp(-math.max(0,dt)/.6)) end
return M
