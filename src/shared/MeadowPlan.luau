--!nonstrict
-- Task 04: bounded pilot planting using the already reviewed Quaternius catalog.
local runtimeScript=rawget(getfenv(),"script")
local Factory=require(runtimeScript and runtimeScript.Parent.Config or "./Config")
local Meadow={maxPlants=456,maxMoving={full=64,reduced=32,minimal=0}}
local function segment(x,z,ax,az,bx,bz)
	local dx,dz=bx-ax,bz-az
	local t=math.clamp(((x-ax)*dx+(z-az)*dz)/(dx*dx+dz*dz),0,1)
	return math.sqrt((x-ax-t*dx)^2+(z-az-t*dz)^2)
end
local fixtures={{-8,-30},{10,-30},{27,-32},{0,10}}
for _,s in pairs(Factory.stations) do table.insert(fixtures,{s.offset[1],s.offset[3]}) end
-- Coordinates relative to Plot 1. Reserve full future station and input/output
-- footprints, all purchase pads, spawn, worker approaches and path widths.
function Meadow.clear(x,z,radius)
	if x< -59 or x>44 or z< -70 or z>39 then return false end
	for _,p in ipairs(fixtures) do
		if math.abs(x-p[1])<5.1+radius and math.abs(z-p[2])<4.5+radius then return false end
		if math.abs(x-p[1])<3.7+radius and math.abs(z-p[2]-7)<3.3+radius then return false end
	end
	if math.abs(x)<4+radius and z>18 then return false end
	if segment(x,z,0,30,0,-29)<3.2+radius then return false end
	if segment(x,z,-29,-7,29,-7)<3.2+radius then return false end
	if segment(x,z,-9,-30,28,-32)<3+radius then return false end
	-- Broad open lane alongside the western stations and the entry fence.
	if math.abs(x+9)<2+radius and z> -30 and z<23 then return false end
	if math.abs(z-28)<1+radius and math.abs(x)>10 and math.abs(x)<31 then return false end
	return true
end
local function noise(i,j) return ((i*92821+j*68917+i*j*31)%104729)/104729 end
function Meadow.build()
	local candidates={}
	for i=0,30 do for j=0,31 do
		local x=-58+i*3.35+(noise(i+5,j)-.5)*1.4
		local z=-69+j*3.35+(noise(j+9,i)-.5)*1.4
		local n=noise(i+17,j+31)
		local scale=3.0+n*1.1; local radius=scale*.43
		if Meadow.clear(x,z,radius) and n>.055 then
			table.insert(candidates,{x=x,z=z,n=n,scale=scale,radius=radius,rank=n+math.max(0,-z-48)*.012})
		end
	end end
	table.sort(candidates,function(a,b) return a.rank<b.rank end)
	local result={}
	for i=1,math.min(390,#candidates) do
		local p=candidates[i]; local tall=i%11==0
		local template=tall and "Grass_Wispy_Tall" or "Grass_Common_Short"
		local scale=tall and p.scale*.35 or p.scale
		local height=.65+p.n*.65
		table.insert(result,{template=template,x=p.x,z=p.z,scale=scale,flatten=height/(scale*(tall and 1.8 or 1.1)),
			angle=i*137.507764,detail=i%7==0 and 3 or (i%3==0 and 2 or 1),radius=p.radius,
			tint=({{129,175,94},{150,189,108},{110,160,89},{161,192,118}})[i%4+1],wind=true})
	end
	-- Curated wildflower pockets and low clover break the repeated shrub rhythm.
	for i=1,66 do
		local p=candidates[1+(i*37)%#candidates]; local flower=i%3==0
		local scale=flower and (.8+(i%4)*.12) or (2.5+(i%5)*.18)
		local radius=flower and scale*.82 or scale*.27
		local x,z=p.x+.7,p.z-.7
		if Meadow.clear(x,z,radius) then table.insert(result,{template=flower and "Flower_3_Group" or "Clover_2",x=x,z=z,
			scale=scale,flatten=flower and .85 or .25,angle=i*71,detail=i%4==0 and 2 or 1,radius=radius,
			tint=flower and ({{255,244,240},{255,220,235},{223,232,255}})[i%7%3+1] or {157,194,116},wind=false}) end
	end
	assert(#result<=Meadow.maxPlants)
	return result
end
function Meadow.angle(time,x,z,strength)
	-- Continuous travelling gusts, same weather scalar as the environment owner.
	local wave=math.sin(time*1.65-x*.19-z*.12)*.72+math.sin(time*.73+x*.11)*.28
	return wave*(.075+.10*math.clamp(strength,0,1))
end
return Meadow
