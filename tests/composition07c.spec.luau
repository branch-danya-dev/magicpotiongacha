--!nonstrict
local Ridge=require("../src/shared/RidgeComposition")
local Vista=require("../src/shared/VistaPlan")
local Ground=require("../src/shared/FarmGround")
local Island=require("../src/shared/IslandTerrain")
local Boundary=require("../src/shared/IslandBoundary")
local Nature=require("../src/shared/NatureGeometry")
local Forest=require("../src/shared/ForestPlan")
local Plan=require("../src/shared/EnvironmentPlan")
local Config=require("../src/shared/EnvironmentConfig")
local Factory=require("../src/shared/Config")
local Props=require("../src/shared/PropPlan")
local State=require("../src/shared/EnvironmentState")
local LOD=require("../src/shared/ForestLOD")
local function artTotals()
	local plan=Plan.build(Config,1); local parts,triangles=plan.metrics.parts,plan.metrics.triangles
	local function charge(p) local n,t=Props.metrics(p); parts+=n; triangles+=t end
	for _,id in ipairs(Factory.stationOrder) do charge(Props.station(Factory,id)) end
	for _,id in ipairs({"warehouse","altar","orders","blueprint"}) do charge(Props.station(Factory,id)) end
	charge(Props.workshop()); for _=1,6 do charge(Props.lantern()) end
	charge(Props.market(false)); charge(Props.market(false)); charge(Props.market(true))
	return parts+8,triangles+96
end
return function(T:any)
	T.test("07C: sculpture leaves the entire traversal polygon and exterior grace unchanged",function()
		for x=-226,226,4 do for z=-132,154,4 do if Boundary.contains(x,z,-4) then
			for _,height in ipairs({-2.4,-1.6,0,35}) do
				local h,m=Ridge.apply(x,z,height,"Ground"); T.equal(h,height); T.equal(m,"Ground")
			end
		end end end
	end)
	T.test("07C: all eight reserved plots and roads receive zero terrain lift",function()
		for x=-350,350,4 do for z=-270,286,4 do if Island.reserved(x,z) then
			T.equal(Ridge.lift(x,z,-2.2),0)
		end end end
		for i=1,8 do local x,z=Island.origin(i); T.equal(Ground.column(x,z),-1.6) end
	end)
	T.test("07C: raised crests are dry and stay below the existing voxel and boundary ceiling",function()
		for _,p in ipairs(Ridge.peaks) do T.near(Ground.column(p[1],p[2]),p[3],.001) end
		local rock,grass=0,0
		for x=-300,-60,4 do for z=-218,-6,4 do
			local h,m=Ground.column(x,z)
			T.truthy(h==h and h<Island.bounds.max[2]-8 and h<Boundary.top-20)
			if m=="Rock" then rock+=1 elseif m=="Grass" then grass+=1 end
		end end
		T.truthy(rock>300 and grass>300,"Rock shoulders and grassy shelves")
	end)
	T.test("07C: compact support preserves the other seven sectors and distant coast",function()
		for x=-350,350,8 do for z=-270,286,8 do
			if x>=-60 or z>=-6 or z<=-218 or x<=-298 then T.equal(Ridge.lift(x,z,-27),0) end
		end end
	end)
	T.test("07C: terrain deformation is continuous at support edges and the traversal mask",function()
		-- Same baseline isolates the new deformation from inherited Terrain noise.
		for x=-299,-60,1 do for z=-218,-6,2 do
			local a=Ridge.lift(x,z,-27)
			T.truthy(math.abs(a-Ridge.lift(x+.001,z,-27))<.02)
			T.truthy(math.abs(a-Ridge.lift(x,z+.001,-27))<.02)
		end end
	end)
	T.test("07C: terrain write volume and tile cap do not grow",function()
		local total=0
		for _,tile in ipairs(Island.tiles()) do
			local n=1; for i=1,3 do n*=(tile.max[i]-tile.min[i])/Island.resolution end
			T.truthy(n<=Island.maxWriteCells); total+=n
		end
		T.equal(total,1082880); T.truthy(total<Island.maxTotalCells)
	end)
	T.test("07C: repeated composition is deterministic and charges every real mesh",function()
		local a,b=Vista.build(),Vista.build(); T.same(a,b)
		local triangles,canopies,windows=0,0,0
		for _,d in ipairs(a.parts) do
			if d.shape=="Mesh" then
				local n=Nature[d.template]; T.truthy(n)
				T.equal(d.triangles,d.canopy and n.triangles-n.barkTriangles or n.triangles)
			end
			triangles+=d.triangles or 12; if d.canopy then canopies+=1 end; if d.window then windows+=1 end
		end
		T.equal(#a.parts,75); T.equal(triangles,17536); T.equal(a.metrics.triangles,triangles)
		T.equal(canopies,7); T.equal(windows,6); T.equal(a.metrics.lights,0); T.equal(a.metrics.textures,0)
		T.truthy(#a.parts<=Vista.maxParts and triangles<=Vista.maxTriangles)
		for _,color in pairs(Vista.palette) do
			local existing=false; for _,approved in pairs(Config.palette) do if color==approved then existing=true end end
			T.truthy(existing,"Backdrop must reuse the approved palette")
		end
	end)
	T.test("07C: full yaw/roll bounds of every backdrop part stay outside traversal with margin",function()
		for _,d in ipairs(Vista.build().parts) do
			local a,r=math.rad(d.angle),math.rad(d.roll or 0)
			local separated=false
			for _,s in ipairs(Boundary.segments()) do
				local nx,nz=-(s.b[2]-s.a[2])/s.length,(s.b[1]-s.a[1])/s.length
				local worst=-math.huge
				for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
					local x=sx*d.size[1]/2*math.cos(r)-sy*d.size[2]/2*math.sin(r)
					local z=sz*d.size[3]/2
					local px=d.position[1]+x*math.cos(a)+z*math.sin(a)
					local pz=d.position[3]-x*math.sin(a)+z*math.cos(a)
					worst=math.max(worst,nx*(px-s.a[1])+nz*(pz-s.a[2]))
				end end end
				if worst<=-6 then separated=true end
			end
			T.truthy(separated,d.id.." overlaps accepted traversal contour")
		end
	end)
	T.test("07C: foliage and ruin support are dry; the gate uses one coherent foundation",function()
		local ruin=0
		for _,d in ipairs(Vista.build().parts) do
			if d.canopy or d.role=="ground" then
				T.truthy(Ground.column(d.position[1],d.position[3])>Island.water+4,d.id)
			end
			if d.groundAnchor then
				ruin+=1; T.same(d.groundAnchor,{-267,-116})
				T.near(d.position[2]-d.bottom-d.size[2]/2,(Ground.column(table.unpack(d.groundAnchor))))
			end
		end
		T.equal(ruin,10)
	end)
	T.test("07C: offshore rocks start underwater and emerge above the sea",function()
		local count=0
		for _,d in ipairs(Vista.build().parts) do if d.shape=="Mesh" and not d.grounded then
			count+=1; T.truthy(d.position[2]-d.size[2]/2<Island.water)
			T.truthy(d.position[2]+d.size[2]/2>Island.water+4)
		end end
		T.equal(count,6)
	end)
	T.test("07C: distant canopies reuse foliage only and keep the total tree cap",function()
		local whole=0; for _,d in ipairs(Forest.build()) do if d.forest=="tree" then whole+=1 end end
		local distant=0
		for _,d in ipairs(Vista.build().parts) do if d.canopy then
			distant+=1; T.equal(d.source,Nature[d.template].parts[2].name); T.equal(d.bottom,-2)
		end end
		T.equal(whole,29); T.equal(whole+distant,36)
	end)
	T.test("07C: the backdrop is included exactly once in the existing complete art budgets",function()
		local plan=Plan.build(Config,1); local n,t=0,0
		for _,d in ipairs(plan.parts) do
			local geometry=d.template and Nature[d.template]
			n+=d.forestParts or (geometry and #geometry.parts or 1)
			t+=d.forestTriangles or (geometry and geometry.triangles or 12)
		end
		T.equal(plan.metrics.parts,n+Vista.build().metrics.parts)
		T.equal(plan.metrics.triangles,t+Vista.build().metrics.triangles)
		T.equal(plan.metrics.decoratedPlots,1)
		local parts,triangles=artTotals(); T.equal(parts,1173); T.equal(triangles,263910)
		T.truthy(parts<=1320 and triangles<=465000)
		T.truthy(plan.metrics.parts<=850 and plan.metrics.triangles<=300000)
		T.equal(plan.metrics.lights,6); T.equal(plan.metrics.externalTextures,12)
	end)
	T.test("07C: core landmarks survive all tiers from the pilot; Minimal removes small detail",function()
		for _,d in ipairs(Vista.build().parts) do
			local p=d.position; local distance=math.sqrt((p[1]+142.5)^2+(p[2]-9)^2+(p[3]+65)^2)
			for _,tier in ipairs({"full","reduced","minimal"}) do
				if d.role=="core" then T.equal(Vista.alpha(d.role,tier,distance),0,d.id) end
			end
			if d.role~="core" then T.equal(Vista.alpha(d.role,"minimal",0),1) end
		end
	end)
	T.test("07C: culling fades monotonically and is restored without frame-rate jumps",function()
		for _,role in ipairs({"core","detail","ground"}) do for _,tier in ipairs({"full","reduced","minimal"}) do
			local last=0
			for distance=0,750,.5 do local a=Vista.alpha(role,tier,distance); T.truthy(a>=last and a<=1); last=a end
			T.equal(last,1)
		end end
		for _,distance in ipairs({0/0,math.huge,-1}) do T.equal(Vista.alpha("core","full",distance),1) end
		T.equal(Vista.alpha("unknown","full",0),1)
		T.equal(Vista.alpha("core","invalid",600),Vista.alpha("core","reduced",600))
		local alpha=1; for _=1,30 do local nextAlpha=LOD.step(alpha,0,1/60); T.truthy(alpha-nextAlpha<=1/30+.000001); alpha=nextAlpha end
		T.near(alpha,0)
	end)
	T.test("07C: distant windows follow the existing time/weather state continuously",function()
		for _,rain in ipairs({0,.5,1}) do
			local last=Vista.window(State.at(Config,0,rain))
			for i=1,2000 do
				local nextColor=Vista.window(State.at(Config,(i/2000)%1,rain))
				for c=1,3 do T.truthy(nextColor[c]>=0 and nextColor[c]<=255); T.truthy(math.abs(nextColor[c]-last[c])<1) end
				last=nextColor
			end
			T.same(last,Vista.window(State.at(Config,0,rain)))
		end
	end)
	T.test("07C: landmark tip rays clear planned terrain from ordinary pilot viewpoints",function()
		-- Geometric preflight only: not native visibility, foliage occlusion or art approval.
		for _,ray in ipairs({{{-142.5,9,-36},{-197,91.5,-306}},{{-108,9,-65},{-390,67.45,-95}}}) do
			for i=1,200 do
				local a,b,t=ray[1],ray[2],i/200
				local x,y,z=a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t
				T.truthy(y-Ground.column(x,z)>5)
			end
		end
	end)
	T.test("07C: effect anchors reuse bounded pools and all quality and motion limits",function()
		T.equal(#Vista.fogAnchors,3); T.equal(#Vista.pollenAnchors,4); T.equal(#Vista.sunPools,2)
		T.truthy(Vista.moonSize<=64)
		for _,tier in ipairs({"full","reduced","minimal"}) do for _,reduce in ipairs({false,true}) do
			local q=State.quality(Config,tier,reduce)
			T.truthy(q.lights<=6 and q.fog<=3 and q.motes<=24 and q.rain<=60 and q.stars<=48)
			if reduce then T.equal(q.motion,0); T.equal(q.motes,0); T.equal(q.rain,0) end
		end end
	end)
end
