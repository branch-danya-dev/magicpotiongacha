--!nonstrict
local Transition=require("../src/shared/EnvironmentTransition")
local State=require("../src/shared/EnvironmentState")
local Config=require("../src/shared/EnvironmentConfig")
local Lights=require("../src/shared/EnvironmentLights")
local Camera=require("../src/shared/CameraClearance")
local Boundary=require("../src/shared/IslandBoundary")
local Terrain=require("../src/shared/IslandTerrain")
local Props=require("../src/shared/PropPlan")
local Nature=require("../src/shared/EnvironmentPlan")
local FactoryConfig=require("../src/shared/Config")
local function delta(a,b,period) return (b-a+period/2)%period-period/2 end
local function settled(entries,limit)
	for _=1,90 do Lights.step(entries,limit,145,1/60) end
end
return function(T:any)
	T.test("07a: moving clock target crosses antipode without changing the chosen arc",function()
		local tr=Transition.new(); tr.sample({clock=0,phase=0},0); tr.begin(0)
		local old=tr.sample({clock=11.99,phase=.499},3.99)
		local new=tr.sample({clock=12.01,phase=.501},4.01)
		T.truthy(math.abs(delta(old.clock,new.clock,24))<.1)
		T.truthy(math.abs(delta(old.phase,new.phase,1))<.01)
	end)
	T.test("07a: live midnight target stays continuous for the entire transition",function()
		local tr=Transition.new(); tr.sample({clock=20,phase=.9},0); tr.begin(0)
		local previous=tr.sample({clock=23.8,phase=.98},.01)
		for i=1,800 do
			local s=tr.sample({clock=(23.8+i*.001)%24,phase=(.98+i*.00005)%1},i*.01)
			T.truthy(math.abs(delta(previous.clock,s.clock,24))<.03)
			T.truthy(math.abs(delta(previous.phase,s.phase,1))<.01); previous=s
		end
	end)
	T.test("07a: interrupted manual transition starts at the displayed state",function()
		local tr=Transition.new(); local day=State.sample(Config,0,"day")
		tr.sample(day,0); tr.begin(0)
		local halfway=tr.sample(State.sample(Config,0,"night"),3)
		tr.begin(3); T.same(tr.sample(State.sample(Config,0,"rain"),3),halfway)
		local rain=State.sample(Config,0,"rain"); T.same(tr.sample(rain,11),rain)
		T.same(day,State.sample(Config,0,"day"))
	end)
	T.test("07a: weather retargeting preserves continuous phase and all six mood endpoints",function()
		local tr=Transition.new(); local now=0
		for _,pose in ipairs({"day","sunset","night","dawn","rain","afterrain"}) do
			local target=State.sample(Config,0,pose)
			tr.begin(now); local first=tr.sample(target,now)
			if tr.from then T.same(first,tr.from) end
			now+=8; T.same(tr.sample(target,now),target)
		end
	end)
	T.test("07a: lamp allocation is deterministic for tied distances and shuffled registration",function()
		local a={{id="b",distance=10},{id="a",distance=10},{id="c",distance=10}}
		local b={{id="c",distance=10},{id="b",distance=10},{id="a",distance=10}}
		settled(a,2); settled(b,2)
		for _,list in ipairs({a,b}) do for _,e in ipairs(list) do T.equal(e.weight,e.id=="c" and 0 or 1) end end
	end)
	T.test("07a: small avatar movement around the midpoint cannot swap lantern slots",function()
		local e={{id=1,distance=20},{id=2,distance=21}}; settled(e,1)
		for i=1,240 do
			e[1].distance=20+math.sin(i)*2; e[2].distance=20-math.sin(i)*2
			Lights.step(e,1,145,1/60); T.equal(e[1].weight,1); T.equal(e[2].weight,0)
		end
	end)
	T.test("07a: walking toward a new lamp releases the old slot before admitting the new",function()
		local e={{id=1,distance=5},{id=2,distance=60}}; settled(e,1)
		e[1].distance=80; e[2].distance=3; local previous=1
		for _=1,100 do
			T.truthy(Lights.step(e,1,145,1/60)<=1)
			T.truthy(e[1].weight==0 or e[2].weight==0)
			T.truthy(math.abs(e[1].weight-previous)<.03); previous=e[1].weight
		end
		T.equal(e[1].weight,0); T.equal(e[2].weight,1)
	end)
	T.test("07a: Full Reduced Minimal caps hold even during an occupied handover",function()
		local e={}; for i=1,6 do e[i]={id=i,distance=i*2} end; settled(e,4)
		for _,cap in ipairs({2,0,4,2,4,0,2}) do
			for _=1,20 do
				local count=Lights.step(e,cap,145,.1); T.truthy(count<=cap)
				local actual=0; for _,v in ipairs(e) do if v.weight>0 then actual+=1 end end
				T.equal(actual,count)
			end
		end
	end)
	T.test("07a: local light reaches zero before crossing the distance cutoff",function()
		local e={{id=1,distance=120}}; settled(e,1)
		for d=120,146,.05 do
			local previous=e[1].weight; e[1].distance=d
			Lights.step(e,1,145,1/60); T.truthy(math.abs(e[1].weight-previous)<.03)
		end
		T.equal(e[1].weight,0)
	end)
	T.test("07a: teleport and stalled frame never overshoot brightness or slot budgets",function()
		local e={{id=1,distance=0},{id=2,distance=999}}; settled(e,1)
		e[1].distance=999; e[2].distance=0
		T.equal(Lights.step(e,1,145,60),1)
		T.truthy(e[1].weight>0 and e[1].weight<1); T.equal(e[2].weight,0)
	end)
	T.test("07a: camera responds inward immediately, including walls closer than minimum zoom",function()
		T.near(Camera.distance(30,40,2,1/60),1.85)
		T.equal(Camera.distance(20,40,.1,1/60),0)
		T.equal(Camera.distance(nil,20,nil,1/60),20)
	end)
	T.test("07a: outward camera recovery is bounded, monotone and frame-rate independent",function()
		local function run(dt,n) local d=2; for _=1,n do
			local nextDistance=Camera.distance(d,40,nil,dt); T.truthy(nextDistance>=d and nextDistance<=40); d=nextDistance
		end; return d end
		T.near(run(1/30,30),run(1/120,120),1e-8)
		T.equal(Camera.distance(2,40,nil,0),2)
	end)
	T.test("07a: near-plane collision radius covers landscape and portrait viewport corners",function()
		for _,aspect in ipairs({.5,1,16/9,32/9}) do for _,fov in ipairs({60,70,90}) do
			local half=math.tan(math.rad(fov)/2)*.5
			T.truthy(Camera.radius(fov,aspect,-.5)>math.sqrt(half^2+(half*aspect)^2+.5^2))
		end end
	end)
	T.test("07a: ridge contour has no endpoint gaps and encloses all reserved walking cells",function()
		local segments=Boundary.segments(); T.equal(#segments,8)
		for i,s in ipairs(segments) do T.same(s.b,segments[i%#segments+1].a); T.truthy(s.length>20) end
		for x=-225,225 do for z=-130,150 do
			if Terrain.reserved(x,z) then T.truthy(Boundary.contains(x,z,4),x..","..z) end
		end end
	end)
	T.test("07a: every station pad, worker waypoint and spawn retains a four-stud boundary margin",function()
		for i=1,8 do local x,z=Terrain.origin(i)
			T.truthy(Boundary.contains(x,z+20,4))
			for _,s in pairs(FactoryConfig.stations) do
				T.truthy(Boundary.contains(x+s.offset[1],z+s.offset[3]+7,4))
				for _,p in pairs(s.waypoints) do T.truthy(Boundary.contains(x+p[1],z+p[3],4)) end
			end
		end
	end)
	T.test("07a: all seven outer ridge summits lie beyond the traversal contour",function()
		for _,p in ipairs({{-155,-151},{-35,-173},{125,-151},{-246,0},{236,40},{-107,180},{125,181}}) do
			T.falsy(Boundary.contains(p[1],p[2]))
			T.truthy(Boundary.top>Terrain.height(p[1],p[2])+20)
		end
		T.truthy(Boundary.bottom<=Terrain.bounds.min[2])
	end)
	T.test("07a: added eight invisible colliders fit the unchanged pilot geometry budget",function()
		local count,triangles=0,0
		local function add(p,n) local a,b=Props.metrics(p); count+=a*(n or 1); triangles+=b*(n or 1) end
		for id in pairs(FactoryConfig.stations) do add(Props.station(FactoryConfig,id)) end
		for _,id in ipairs({"warehouse","orders","altar","blueprint"}) do add(Props.station(FactoryConfig,id)) end
		add(Props.lantern(),6); add(Props.market(false),2); add(Props.market(true)); add(Props.workshop())
		local env=Nature.build(Config,1)
		T.truthy(count+env.metrics.parts+#Boundary.segments()<=Props.combinedPartLimit)
		T.truthy(triangles+env.metrics.triangles+#Boundary.segments()*12<=Props.combinedTriangleLimit)
	end)
end
