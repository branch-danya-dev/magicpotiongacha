--!nonstrict
-- Conservative sphere/OBB overlap recovery in box-local coordinates. Using an
-- inflated box deliberately errs toward clearance, including MeshPart bounds.
local Geometry={iterations=8,terrainCells=32768,cacheSide=128,cacheMargin=16}
function Geometry.inside(p,half,radius)
	return math.abs(p[1])<half[1]+radius and math.abs(p[2])<half[2]+radius and math.abs(p[3])<half[3]+radius
end
function Geometry.exit(p,half,radius,preferred)
	if not Geometry.inside(p,half,radius) then return p,false end
	local axis,depth=1,math.huge
	for i=1,3 do
		local d=half[i]+radius-math.abs(p[i])
		if d<depth then axis,depth=i,d end
	end
	local direction=p[axis]
	if math.abs(direction)<1e-6 then direction=preferred and preferred[axis] or 1 end
	local out=table.clone(p); out[axis]=(direction<0 and -1 or 1)*(half[axis]+radius+.01)
	return out,true
end
function Geometry.index(x,y,z) return ((x-1)*32+y-1)*32+z-1 end
function Geometry.terrainLift(solid,minimum,position,radius)
	local low,high={},{}
	for i=1,3 do
		low[i]=(position[i]-radius-minimum[i])/4; high[i]=(position[i]+radius-minimum[i])/4
		if low[i]<0 or high[i]>=32 then return position[2],false end
	end
	local top=position[2]-radius; local overlap=false
	for x=math.floor(low[1])+1,math.floor(high[1])+1 do
		for y=math.floor(low[2])+1,math.floor(high[2])+1 do
			for z=math.floor(low[3])+1,math.floor(high[3])+1 do
				if buffer.readu8(solid,Geometry.index(x,y,z))~=0 then top=math.max(top,minimum[2]+y*4); overlap=true end
			end
		end
	end
	return overlap and top+radius+.01 or position[2],true
end
return Geometry
