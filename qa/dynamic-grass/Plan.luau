--!nonstrict
-- Deterministic, art-only planting. Footprints include the entire mesh and sway.
local P={maxPlants=320,grassLength=.24,seed=7604}
P.palette={{112,151,122},{130,151,104},{102,155,141},{119,164,135}}
local function distance(x,z,a,b) return math.sqrt((x-a)^2+(z-b)^2) end
function P.path(x,z,r)
	return math.abs(x-math.sin((24-z)*.17)*1.2)<3+r and z>-8-r and z<29+r
end
function P.protected(x,z,r,config)
	if P.path(x,z,r) or distance(x,z,0,-2)<7+r or distance(x,z,0,20)<3+r then return true end
	for _,id in ipairs(config.stationOrder) do
		local s=config.stations[id]
		if math.abs(x-s.offset[1])<5+r and math.abs(z-s.offset[3])<4.5+r then return true end
		for _,w in pairs(s.waypoints) do if distance(x,z,w[1],w[3])<2+r then return true end end
	end
	return false
end
function P.buildable(x,z,r,island)
	local b=island.buildable
	return x+r>b.minX and x-r<b.maxX and z+r>b.minZ and z-r<b.maxZ
end
function P.surface(x,z,config)
	-- The ground/stone path and station footprints have no native blades.
	if P.protected(x,z,0,config) then return "Ground" end
	local patch=math.sin(x*.19+math.sin(z*.1)*1.6)+.6*math.cos(z*.25-x*.07)
	-- Smooth, broad islands of moss; no checkerboard of individual voxels.
	return patch>1.13 and "LeafyGrass" or "Grass"
end
function P.build(config,island,geometry,layout)
	local state=P.seed
	local function rand() state=(state*48271)%2147483647;return state/2147483647 end
	local plants={}
	local function add(x,z,kind,scale,detail,zone)
		local g=geometry[kind];local radius=g.radius*scale+.22
		if not island.surfaceContains(x,z,radius+1) or P.protected(x,z,radius,config) then return end
		if g.height*scale>.48 and P.buildable(x,z,radius,island) then return end
		for _,p in ipairs(plants) do if distance(x,z,p.x,p.z)<math.min(radius,p.radius)*.9 then return end end
		if #plants>=P.maxPlants then return end
		table.insert(plants,{x=x,z=z,name=kind,scale=scale,yaw=rand()*360,detail=detail,zone=zone,
			radius=radius,height=g.height*scale,tint=P.palette[1+math.floor(rand()*#P.palette)],wind=kind~="Clover_2"})
	end
	-- Uneven forest-edge drifts, with broad fern leaves at tree bases.
	for _,tree in ipairs(layout.trees) do
		for i=1,14 do
			local a=rand()*math.pi*2;local r=2+rand()*7
			local fern=i%7==0
			add(tree.x+math.cos(a)*r,tree.z+math.sin(a)*r,fern and "Fern_1" or "Grass_Wispy_Tall",
				fern and (.40+rand()*.18) or (.68+rand()*.55),i%4==0 and 1 or (i%2==0 and 2 or 3),"grove")
		end
	end
	-- Cliff margins, clustered around irregular angular seed positions rather than a grid.
	for i=1,100 do
		local a=rand()*math.pi*2;local r=.76+rand()*.15
		add(math.cos(a)*59*r,-8+math.sin(a)*53*r,"Grass_Wispy_Tall",.65+rand()*.6,
			i%5==0 and 1 or (i%2==0 and 2 or 3),"rim")
	end
	-- Sparse low clover/grass in the clearing, never covering work pads or endpoints.
	for i=1,170 do
		local x=-36+rand()*72;local z=-44+rand()*72
		add(x,z,i%3==0 and "Grass_Common_Short" or "Clover_2",i%3==0 and .32 or .72,
			i%6==0 and 1 or (i%2==0 and 2 or 3),"clearing")
	end
	return plants
end
return P
