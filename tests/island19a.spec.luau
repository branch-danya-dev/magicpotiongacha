--!nonstrict
local Field=require("../src/shared/IslandTerrain")
local Plan=require("../src/shared/EnvironmentPlan")
local Config=require("../src/shared/Config")
return function(T:any)
	for i=1,8 do T.test("19a: unchanged plot "..i.." anchors, pads and waypoints stay dry and flat",function()
		local x,z=Field.origin(i); local old=Plan.origin(i); T.equal(x,old[1]); T.equal(z,old[3])
		local points={{0,20},{-8,-30},{-8,-23},{10,-30},{27,-32},{0,10},{0,17}}
		for _,s in pairs(Config.stations) do
			table.insert(points,{s.offset[1],s.offset[3]}); table.insert(points,{s.offset[1],s.offset[3]+7})
			for _,p in pairs(s.waypoints) do table.insert(points,{p[1],p[3]}) end
		end
		for _,p in ipairs(points) do
			T.truthy(Field.reserved(x+p[1],z+p[2])); T.truthy(math.abs(Field.height(x+p[1],z+p[2])-.45)<1e-9)
			T.equal(Field.column(x+p[1],z+p[2]),-2.4)
		end
	end) end
	T.test("19a: every work floor has a conservative four-stud voxel margin",function()
		for i=1,8 do local x,z=Field.origin(i)
			for u=-38.5,38.5,3.5 do for v=-45.5,29.5,3 do
				for _,d in ipairs({{-4,0},{4,0},{0,-4},{0,4}}) do T.truthy(Field.reserved(x+u+d[1],z+v+d[2])) end
			end end
		end
	end)
	T.test("19a: connected flat walking routes reach both rows and the bazaar",function()
		for i=1,8 do local x,z=Field.origin(i)
			for along=math.min(z+20,0),math.max(z+20,0),1 do T.truthy(Field.reserved(x,along)) end
		end
		for x=-200,200 do T.truthy(Field.reserved(x,0)); T.equal(Field.height(x,0),.45) end
	end)
	T.test("19a: hidden legacy base never permits walking above water",function()
		for x=-210,210,4 do for z=-125,125,4 do T.truthy(Field.height(x,z)>=.4499) end end
	end)
	T.test("19a: continuous irregular coast has sand, submerged sea floor and relief",function()
		local lowest,highest=math.huge,-math.huge; local sand=0
		for x=-350,350,8 do for z=-270,286,8 do
			local h=Field.height(x,z); lowest=math.min(lowest,h); highest=math.max(highest,h)
			T.truthy(h==h and h>=-27 and h<50)
			T.truthy(math.abs(h-Field.height(x+.01,z))<.06)
			local _,material=Field.column(x,z); if material=="Sand" then sand+=1 end
		end end
		T.truthy(lowest<Field.water-12); T.truthy(highest>20); T.truthy(sand>100)
	end)
	T.test("19a: chunk bounds are aligned, non-overlapping and within total budget",function()
		local tiles=Field.tiles(); local cells=0
		for n,b in ipairs(tiles) do
			local count=1
			for axis=1,3 do T.equal(b.min[axis]%4,0); T.equal(b.max[axis]%4,0); count*=((b.max[axis]-b.min[axis])/4) end
			T.truthy(count<=Field.maxWriteCells); cells+=count
			for m=1,n-1 do local a=tiles[m]
				T.truthy(a.max[1]<=b.min[1] or b.max[1]<=a.min[1] or a.max[3]<=b.min[3] or b.max[3]<=a.min[3])
			end
		end
		T.equal(cells,1082880); T.truthy(cells<=Field.maxTotalCells)
	end)
	T.test("19a: soil and water occupancy are finite and meet across the shoreline",function()
		for x=180,350,2 do local h,s=Field.column(x,0)
			for y=-46,62,4 do local material,fill=Field.cell(h,s,y)
				T.truthy(fill>=0 and fill<=1 and fill==fill)
				T.truthy(material=="Air" or material=="Water" or material=="Rock" or material=="Grass" or material=="Sand")
				if y<Field.water-2 then T.truthy(fill>0) end
			end
		end
		T.equal(Field.cell(-100,"Sand",-10),"Water"); T.equal(Field.cell(-100,"Sand",-6),"Air")
	end)
	T.test("19a: regional joins use identical world-space water levels",function()
		for _,region in ipairs(Field.regions()) do if region.waterOnly then
			T.equal(region.max[2],Field.water); T.equal(region.min[2],-24)
		end end
		for _,p in ipairs({{-352,0},{352,0},{0,-272},{0,288}}) do T.truthy(Field.height(p[1],p[2])<Field.water-8) end
	end)
end
