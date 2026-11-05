--!nonstrict
-- Task 02: deterministic island substrate only. No plot/economy/profile state.
local Island={version=1,resolution=4,tileCells=32,water=-8,
	bounds={min={-352,-48,-272},max={352,64,288}},
	ocean={min={-768,-24,-640},max={768,-8,640}},maxWriteCells=28672,maxTotalCells=1100000}
local function smooth(v) v=math.clamp(v,0,1); return v*v*(3-2*v) end
local function rectangle(x,z,cx,cz,rx,rz)
	return math.sqrt(math.max(math.abs(x-cx)-rx,0)^2+math.max(math.abs(z-cz)-rz,0)^2)
end
function Island.origin(i) return ((i-1)%4-1.5)*95,i<=4 and -65 or 85 end
function Island.clearance(x,z)
	-- Padded footprints protect all station slots, pads, worker waypoints and spawns.
	local d=rectangle(x,z,0,0,214,18)
	for i=1,8 do
		local ox,oz=Island.origin(i)
		d=math.min(d,rectangle(x,z,ox,oz-8,42.5,41.5))
		-- Connect each clearing to the central bazaar and the southern walking loop.
		d=math.min(d,rectangle(x,z,ox,40,8,88))
	end
	d=math.min(d,rectangle(x,z,0,128,195,8))
	return d
end
function Island.reserved(x,z) return Island.clearance(x,z)==0 end
local hills={{-155,-151,24,65,40},{-35,-173,31,76,42},{125,-151,26,72,40},
	{-246,0,22,45,94},{236,40,27,48,88},{-107,180,23,86,43},{125,181,26,70,46}}
function Island.height(x,z)
	local u,v=x/300,(z-8)/224
	local angle=math.atan2(v,u)
	local radius=math.sqrt(u*u+v*v)
	local outline=1+.055*math.sin(3*angle+.4)+.035*math.cos(5*angle-.8)
	local coast=smooth((radius/outline-.78)/.27)
	local h=3.8+1.4*math.sin(x*.024+z*.017)*math.cos(z*.027)
	for _,hill in ipairs(hills) do h+=hill[3]*math.exp(-((x-hill[1])/hill[4])^2-((z-hill[2])/hill[5])^2) end
	h=.45+smooth(Island.clearance(x,z)/23)*h
	h=h*(1-coast)-27*coast
	-- The old collision footprint is wholly on dry land, including its corners.
	local support=1-smooth(rectangle(x,z,0,0,214,129)/40)
	return math.max(h,-27+27.45*support)
end
function Island.column(x,z)
	local h=Island.height(x,z)
	-- Conservative voxel clearance, calibrated against engine raycasts in Play.
	return Island.reserved(x,z) and -2.4 or h-2.2,h<-2 and "Sand" or "Grass"
end
function Island.cell(h,surface,y)
	local fill=math.clamp((h-y+Island.resolution/2)/Island.resolution,0,1)
	if fill>0 then return y<h-6 and "Rock" or surface,fill end
	local water=math.clamp((Island.water-y+Island.resolution/2)/Island.resolution,0,1)
	if water>0 then return "Water",water end
	return "Air",0
end
function Island.regions()
	local b,o=Island.bounds,Island.ocean
	return {b,
		{min=o.min,max={b.min[1],o.max[2],o.max[3]},waterOnly=true},
		{min={b.max[1],o.min[2],o.min[3]},max=o.max,waterOnly=true},
		{min={b.min[1],o.min[2],o.min[3]},max={b.max[1],o.max[2],b.min[3]},waterOnly=true},
		{min={b.min[1],o.min[2],b.max[3]},max={b.max[1],o.max[2],o.max[3]},waterOnly=true}}
end
function Island.tiles()
	local result={}; local step=Island.tileCells*Island.resolution
	for _,b in ipairs(Island.regions()) do
		for x=b.min[1],b.max[1]-1,step do for z=b.min[3],b.max[3]-1,step do
			table.insert(result,{min={x,b.min[2],z},max={math.min(x+step,b.max[1]),b.max[2],math.min(z+step,b.max[3])},waterOnly=b.waterOnly==true})
		end end
	end
	return result
end
return Island
