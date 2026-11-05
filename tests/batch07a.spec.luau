--!nonstrict
local Geometry=require("../src/shared/CameraGeometry")
local Camera=require("../src/shared/CameraClearance")
local Clock=require("../src/shared/EnvironmentClock")
local State=require("../src/shared/EnvironmentState")
local Transition=require("../src/shared/EnvironmentTransition")
local Config=require("../src/shared/EnvironmentConfig")
local Boundary=require("../src/shared/IslandBoundary")
local Fence=require("../src/shared/FenceGeometry")
local Plan=require("../src/shared/EnvironmentPlan")
local Props=require("../src/shared/PropPlan")
local Lights=require("../src/shared/EnvironmentLights")
local function delta(a,b,period) return (b-a+period/2)%period-period/2 end
return function(T:any)
	for _,case in ipairs({{name="center",p={0,0,0}},{name="face",p={1.4,0,0}},
		{name="edge missed by center ray",p={1.4,1.4,0}},{name="corner",p={1.3,1.3,1.3}},
		{name="negative face",p={-1.4,0,0}},{name="below",p={0,-1.4,0}}}) do
		T.test("07A batch: initial sphere overlap exits box / "..case.name,function()
			local p,moved=Geometry.exit(case.p,{1,1,1},.6,{-3,0,0})
			T.truthy(moved); T.falsy(Geometry.inside(p,{1,1,1},.6))
			local twice,again=Geometry.exit(p,{1,1,1},.6); T.falsy(again); T.same(twice,p)
		end)
	end
	T.test("07A batch: tangent and distant camera volumes are not displaced",function()
		for _,p in ipairs({{1.6,0,0},{10,0,0},{0,0,-6}}) do
			local result,moved=Geometry.exit(p,{1,1,1},.6); T.falsy(moved); T.same(result,p)
		end
	end)
	T.test("07A batch: centered overlap uses the subject side instead of flipping arbitrarily",function()
		local p=Geometry.exit({0,0,0},{.2,40,40},.6,{-4,0,0})
		T.truthy(p[1]<-.8); T.equal(p[2],0); T.equal(p[3],0)
	end)
	T.test("07A batch: actual cached Terrain cell detects overlap that a center ray misses",function()
		local solid=buffer.create(Geometry.terrainCells); buffer.writeu8(solid,Geometry.index(16,16,16),1)
		local p={.3,-.2,-.2}; local y,inCache=Geometry.terrainLift(solid,{-64,-64,-64},p,.6)
		T.truthy(inCache); T.truthy(y>=.6)
		local y2=Geometry.terrainLift(solid,{-64,-64,-64},{p[1],y,p[3]},.6)
		T.near(y2,y); T.equal(p[2],-.2)
	end)
	T.test("07A batch: empty occupancy is stable and out-of-cache space is not called clear",function()
		local solid=buffer.create(Geometry.terrainCells)
		local y,valid=Geometry.terrainLift(solid,{-64,-64,-64},{0,4,0},.6); T.truthy(valid); T.equal(y,4)
		local _,outside=Geometry.terrainLift(solid,{-64,-64,-64},{64,4,0},.6); T.falsy(outside)
	end)
	T.test("07A batch: terrain cache indices are bijective and a full boom fits refresh margin",function()
		local seen={}
		for x=1,32 do for y=1,32 do for z=1,32 do
			local i=Geometry.index(x,y,z); T.truthy(i>=0 and i<Geometry.terrainCells); T.falsy(seen[i]); seen[i]=true
		end end end
		T.truthy(Camera.maxZoom+Geometry.cacheMargin+Camera.radius(90,32/9,-.5)+Camera.skin<Geometry.cacheSide/2)
	end)
	T.test("07A batch: outside recovery has grace, rejects invalid input and leaves spawns alone",function()
		T.falsy(Boundary.escaped(0,0)); T.falsy(Boundary.escaped(224,0)); T.truthy(Boundary.escaped(240,0))
		T.falsy(Boundary.escaped(0/0,0)); T.falsy(Boundary.escaped(math.huge,0))
		for i=1,8 do local p=Plan.origin(i); T.falsy(Boundary.escaped(p[1],p[3]+20)) end
	end)
	T.test("07A batch: every radial and diagonal route out crosses a closed boundary",function()
		for degrees=0,359 do
			local ux,uz=math.cos(math.rad(degrees)),math.sin(math.rad(degrees))
			local crossed=false
			for _,s in ipairs(Boundary.segments()) do
				local dx,dz=s.b[1]-s.a[1],s.b[2]-s.a[2]
				local determinant=ux*dz-uz*dx
				if math.abs(determinant)>.0001 then
					local along=(s.a[1]*dz-s.a[2]*dx)/determinant
					local edge=(s.a[1]*uz-s.a[2]*ux)/determinant
					if along>0 and edge>=0 and edge<=1 then crossed=true end
				end
			end
			T.truthy(crossed,tostring(degrees))
		end
	end)
	T.test("07A batch: fence fillers meet the posts and leave the wide entrance intact",function()
		local count=0; local origin=Plan.origin(1)
		for _,d in ipairs(Plan.build(Config,1).parts) do if d.barrier and d.size[1]>1 then
			local size=Fence.size(d.size[1],d.rotation[3]); count+=1
			T.truthy(size[1]>d.size[1]); T.equal(Fence.bottom+size[2],Fence.top)
			T.truthy(math.abs(d.position[1]-origin[1])-size[1]/2>12.7)
			T.truthy(size[3]>=d.size[3]); T.truthy(Fence.bottom<.5)
		end end
		T.equal(count,4); T.equal(Fence.top,3.2); T.truthy(Boundary.top>Fence.top+50)
	end)
	T.test("07A batch: all lamp panes are permanent visible geometry, independent of active light slots",function()
		local panes=0
		for _,p in ipairs(Props.lantern()) do if string.find(p.name,"AmberPane",1,true) then
			panes+=1
			for phase=1,4 do local visible,_,material=Props.appearance(p,{level=1,phase=phase})
				T.truthy(visible); T.equal(material,"Neon")
			end
		end end
		T.equal(panes,1)
		local slots={{id=1,distance=5,weight=1}}; Lights.step(slots,0,95,1/30); T.equal(slots[1].weight,0)
	end)
	T.test("07A batch: manual clock inverse roundtrips all hours and midnight",function()
		for hour=0,24,.125 do
			local phase=Clock.phase(Config,hour); T.truthy(phase>=0 and phase<1)
			T.near(delta(hour%24,Clock.at(Config,phase),24),0,.000002)
		end
		T.equal(Clock.phase(Config,0/0),nil); T.equal(Clock.phase(Config,math.huge),nil); T.equal(Clock.phase(Config,"day"),nil)
	end)
	T.test("07A batch: one review request channel parses independent time and weather, rejects junk",function()
		T.same(Clock.request(Config,"time:18.2"),{kind="time",value=18.2})
		T.same(Clock.request(Config,"weather:rain"),{kind="weather",value="rain"})
		T.same(Clock.request(Config,"night"),{kind="pose",value="night"})
		T.same(Clock.request(Config,"auto"),{kind="pose"})
		for _,bad in ipairs({"time:nan","time:24","time:-1","time:1.2.3","weather:lava","day;print(1)",string.rep("x",33)}) do T.equal(Clock.request(Config,bad),nil) end
	end)
	for _,pair in ipairs({{"day","night"},{"night","day"},{"sunset","dawn"},{"dawn","sunset"}}) do
		T.test("07A batch: sun and moon follow the same forward phase / "..pair[1].." to "..pair[2],function()
			local tr=Transition.new({forward=true,clockAtPhase=function(p) return Clock.at(Config,p) end})
			local a,b=State.sample(Config,0,pair[1]),State.sample(Config,0,pair[2]); tr.sample(a,0); tr.begin(0)
			local previous=a
			for i=1,480 do
				local s=tr.sample(b,i/60)
				T.truthy(delta(previous.phase,s.phase,1)>=-1e-8); T.truthy(delta(previous.clock,s.clock,24)>=-1e-8)
				T.near(s.clock,Clock.at(Config,s.phase),.00001); previous=s
			end
			T.same(previous,b)
		end)
	end
	T.test("07A batch: weather overlays never change the selected sun clock",function()
		for _,phase in ipairs({0,.3,.51,.79,.999}) do for _,weather in pairs(Clock.weather) do
			local s=State.at(Config,phase,weather.rain,weather)
			T.near(s.clock,Clock.at(Config,phase)); T.equal(s.phase,phase); T.equal(s.cloud,weather.cloud)
		end end
	end)
	T.test("07A batch: weather change mid-transition begins with the currently displayed channels",function()
		local tr=Transition.new({forward=true,clockAtPhase=function(p) return Clock.at(Config,p) end})
		local a=State.at(Config,.3,0,Clock.weather.clear); tr.sample(a,0); tr.begin(0)
		local midway=tr.sample(State.at(Config,.3,1,Clock.weather.rain),3); tr.begin(3)
		T.same(tr.sample(State.at(Config,.3,0,Clock.weather.afterrain),3),midway)
		T.near(midway.clock,a.clock); T.near(midway.phase,a.phase)
	end)
	T.test("07A batch: post-effect quality easing has no overshoot or frame-rate dependence",function()
		local function run(dt,n) local value=.04; for _=1,n do
			local nextValue=Clock.effect(value,0,dt); T.truthy(nextValue>=0 and nextValue<=value); value=nextValue
		end; return value end
		T.near(run(1/30,30),run(1/120,120),1e-10)
		T.truthy(run(1/30,30)<.0001); T.equal(Clock.effect(.04,0,0),.04)
	end)
	T.test("07A batch: six moods retain weather bounds across quality tiers and Reduce Motion",function()
		for _,pose in ipairs({"day","sunset","night","dawn","rain","afterrain"}) do
			local s=State.sample(Config,0,pose)
			for _,tier in ipairs({"full","reduced","minimal"}) do for _,motion in ipairs({false,true}) do
				local q=State.quality(Config,tier,motion)
				T.truthy(q.lights<=6 and q.rain<=60 and q.motes<=24)
				if motion then T.equal(q.rain,0); T.equal(q.motes,0); T.equal(q.motion,0) end
				T.truthy(s.cover>=.12 and s.cover<=.84); T.truthy(s.density>=.12 and s.density<=.34)
			end end
		end
	end)
end
