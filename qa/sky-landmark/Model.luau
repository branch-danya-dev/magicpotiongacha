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
-- Directions are projected onto billboard right/up, plus WORLD altitude.
-- Below-horizon gates stay continuous and do not accidentally use camera pitch.
function M.light(sample:any,weights:{number},quality:string,directions:any):any
	local s=directions and directions.sun or {0,0,-1}
	local m=directions and directions.moon or {0,0,-1}
	local night,warm,cloud=unit(sample.night),unit(sample.warm),unit(sample.cloud)
	local function gate(y:number):number local t=unit((y+.12)/.30);return t*t*(3-2*t)end
	local solar=(1-night)*gate(s[3])*(1-.65*cloud)
	local lunar=night*gate(m[3])*.82*(1-.55*cloud)
	local blood,frost=unit(weights[2]),unit(weights[3])
	local sunColor={1,.87-.19*warm,.65-.24*warm}
	local moonColor={.69+.09*blood-.18*frost,.83-.45*blood+.11*frost,1-.55*blood}
	local tint={};local sum=solar+lunar
	for i=1,3 do tint[i]=sum>1e-6 and (sunColor[i]*solar+moonColor[i]*lunar)/sum or moonColor[i]end
	local top=.55*(solar*(.45+.55*unit(s[2]))+lunar*(.45+.55*unit(m[2])))
	local left=.45*(solar*unit(-s[1])+lunar*unit(-m[1]))
	local right=.45*(solar*unit(s[1])+lunar*unit(m[1]))
	local cost=quality=="reduced" and .85 or 1
	if quality=="minimal" then top*=.7;left=0;right=0 end
	return {top=top*cost,left=left*cost,right=right*cost,color=tint}
end
function M.project(sample:any,weights:{number},quality:string,phase:number,motion:boolean,directions:any?):any
	assert(quality=="full" or quality=="reduced" or quality=="minimal","Invalid landmark quality")
	local night,warm,cloud=unit(sample.night),unit(sample.warm),unit(sample.cloud)
	local blood,frost=unit(weights[2]),unit(weights[3])
	-- Coverage reveals edited interior shadows instead of bleaching the silhouette.
	local color={.88-.12*night+.035*blood*night-.025*frost*night,.94-.12*night-.035*blood*night+.02*frost*night,.89+.035*night-.035*warm+.035*frost*night}
	-- Avoid the old dark blue cut-outs: gently match the final owner's atmosphere,
	-- not the pre-AG70 sample. Alpha still retains the original cloud relief.
	local ocean={.82-.24*night+.025*warm,.85-.22*night-.02*warm,.91-.22*night}
	if directions and directions.sky then for i=1,3 do ocean[i]=ocean[i]*.82+unit(directions.sky[i])*.18 end end
	local light=M.light(sample,weights,quality,directions)
	local glow=(.022+.07*night+.04*warm)*(1-.35*cloud)
	if quality=="reduced" then glow*=.5 elseif quality=="minimal" then glow=0 end
	local pulse=(not motion and quality=="full") and 1+.02*math.sin(phase*.7) or 1
	return {tree=(.83+.06*night+.025*warm)*(1-.10*cloud),cloud=.94+.04*cloud,glow=glow*pulse,
		color=color,cloudColor=ocean,glowColor={1,.94-.08*blood*night,.84+.10*frost*night},
		lightTop=light.top,lightLeft=light.left,lightRight=light.right,lightColor=light.color,
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
