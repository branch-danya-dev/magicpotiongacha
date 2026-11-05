--!nonstrict
-- Task 03 visual ground plan. No ownership, rewards or saved data.
local runtimeScript=rawget(getfenv(),"script")
local Island=require(runtimeScript and runtimeScript.Parent.IslandTerrain or "./IslandTerrain")
local Ground={borderParts=20,glowParts=3,borderWidth=.14,borderDistance=110}
local function smooth(v) v=math.clamp(v,0,1); return v*v*(3-2*v) end
local function rect(x,z,rx,rz)
	return math.sqrt(math.max(math.abs(x)-rx,0)^2+math.max(math.abs(z)-rz,0)^2)
end
local function segment(x,z,ax,az,bx,bz)
	local dx,dz=bx-ax,bz-az
	local t=math.clamp(((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz),0,1)
	return math.sqrt((x-ax-t*dx)^2+(z-az-t*dz)^2)
end
function Ground.column(x,z)
	local _,material=Island.column(x,z)
	local h=Island.height(x,z)-2.2
	local distance=math.huge; local path=false
	for i=1,8 do
		local ox,oz=Island.origin(i); local u,v=x-ox,z-oz
		distance=math.min(distance,rect(u,v+8,38.5,37.5))
		-- Shared approaches join the old entrance/spawn coordinates to the bazaar.
		local start=oz<0 and oz+29.5 or 0; local finish=oz<0 and 0 or oz-45.5
		if z>=start-2 and z<=finish+2 and math.abs(u-math.sin((z-start)*.11)*.7)<3.4 then path=true end
		-- Only the pilot receives interior path dressing at this gate.
		if i==1 and (segment(u,v,0,29.5,0,-29)<2.6
			or segment(u,v,-29,-7,29,-7)<2.5
			or segment(u,v,-9,-30,28,-32)<2.2) then path=true end
	end
	-- Raise the visible soil close to, but below, the unchanged floor collider.
	-- Smooth the outer seam rather than introducing a second rectangular slab.
	local blend=1-smooth((distance-4)/8)
	h=h*(1-blend)-1.6*blend
	local road=math.abs(x)<180 and math.abs(z-math.sin(x*.027)*1.6)<6.3+.6*math.sin(x*.17)
	local plaza=(x/14)^2+(z/11)^2<1
	if (path or road or plaza) and Island.reserved(x,z) then material="Ground" end
	return h,material
end
function Ground.border(index)
	local ox,oz=Island.origin(index); local points={}; local r=2.5
	for _,corner in ipairs({{36,27,0},{-36,27,90},{-36,-43,180},{36,-43,270}}) do
		for step=0,4 do
			local a=math.rad(corner[3]+step*22.5)
			table.insert(points,{ox+corner[1]+r*math.cos(a),oz+corner[2]+r*math.sin(a)})
		end
	end
	return points
end
function Ground.canGlow(state,entry,userId)
	if not state or state.writable~=true or not entry or not entry.upgrade or entry.owner~=userId then return false end
	if not entry.enabled or not entry.visible or not entry.clear or not (entry.distance>=0 and entry.distance<=math.min(8,entry.maximum)) then return false end
	local offer=entry.station=="blueprint" and state.phase or state.builds and state.builds[entry.station]
	return offer~=nil and offer.available==true and type(offer.cost)=="number" and offer.cost>=0
		and type(state.gold)=="number" and state.gold>=offer.cost
end
return Ground
