--!strict
-- Pure projection of the existing environment sample. No time/moon selection.
local M={}
local function unit(v:number):number return math.clamp(v,0,1) end
function M.advance(phase:number,dt:number,windX:number,windZ:number,quality:string,motion:boolean):number
	if motion or quality=="minimal" then return phase end
	-- Project the owner's world wind onto the landmark's horizontal right axis.
	local speed=math.clamp(windX*.995+windZ*.098,-30,30)
	return phase+math.clamp(dt,0,.2)*speed*.004
end
function M.project(sample:any,weights:{number},quality:string,phase:number,motion:boolean):any
	assert(quality=="full" or quality=="reduced" or quality=="minimal","Invalid landmark quality")
	local night,warm,cloud=unit(sample.night),unit(sample.warm),unit(sample.cloud)
	local blood,frost=unit(weights[2]),unit(weights[3])
	-- Coverage reveals edited interior shadows instead of bleaching the silhouette.
	local color={.88-.12*night+.035*blood*night-.025*frost*night,.94-.12*night-.035*blood*night+.02*frost*night,.89+.035*night-.035*warm+.035*frost*night}
	local ocean={.72-.32*night+.035*warm,.80-.33*night-.025*warm,.88-.29*night}
	local glow=(.022+.07*night+.04*warm)*(1-.35*cloud)
	if quality=="reduced" then glow*=.5 elseif quality=="minimal" then glow=0 end
	local pulse=(not motion and quality=="full") and 1+.02*math.sin(phase*.7) or 1
	return {tree=(.83+.06*night+.025*warm)*(1-.10*cloud),cloud=.94+.04*cloud,glow=glow*pulse,
		color=color,cloudColor=ocean,glowColor={1,.94-.08*blood*night,.84+.10*frost*night},
		x=math.sin(phase),y=math.sin(phase*.43),
		moving=quality=="full" and not motion and .16 or 0,haze=quality=="full" and 1 or 0,
		minimal=quality=="minimal" and 1 or 0}
end
function M.smooth(a:number,b:number,dt:number):number return a+(b-a)*(1-math.exp(-math.max(0,dt)/.6)) end
-- First cloud bank shares the tree GUI for guaranteed Z-order; seven surround it.
function M.ocean(config:any):{any}
	local out={};local bearing=math.atan2(config.offset[1],-config.offset[3])
	for i=1,config.cloud.sectors-1 do
		local angle=bearing+i*2*math.pi/config.cloud.sectors
		table.insert(out,{x=math.sin(angle)*config.cloud.radius,z=-math.cos(angle)*config.cloud.radius,
			y=config.offset[2]+config.cloud.offset[2]+45*math.sin(i*2.1),
			width=config.cloud.size[1]*(1+.045*math.sin(i*1.7)),height=config.cloud.size[2]*(1+.04*math.cos(i*2.3)),
			density=.94+.06*math.sin(i*1.3)^2})
	end
	return out
end
-- Approximate unoccluded bounds of alpha>=32, never a screenshot or art PASS.
-- Camera-space center has positive forward Z. Billboard axes face the camera.
function M.bounds(center:{number},size:{number},offset:{number},shape:any,viewport:{number},fov:number):any
	if center[3]<=0 then return nil end
	local crop,visible=shape.crop,shape.visible;local f=viewport[2]/(2*math.tan(math.rad(fov)/2))
	local x0=center[1]+offset[1]+((visible.x-crop.x)/crop.width-.5)*size[1]
	local x1=x0+visible.width/crop.width*size[1]
	local y1=center[2]+offset[2]+(.5-(visible.y-crop.y)/crop.height)*size[2]
	local y0=y1-visible.height/crop.height*size[2]
	return {left=viewport[1]/2+x0*f/center[3],right=viewport[1]/2+x1*f/center[3],
		top=viewport[2]/2-y1*f/center[3],bottom=viewport[2]/2-y0*f/center[3]}
end
return M
