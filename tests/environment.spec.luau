--!nonstrict
local Config=require("../src/shared/EnvironmentConfig")
local State=require("../src/shared/EnvironmentState")
local Plan=require("../src/shared/EnvironmentPlan")
local Codec=require("../src/shared/TradeCodec")
local Settings=require("../src/server/ServerSettings")
local Controller=require("../src/client/EnvironmentController")
local Labels=require("../src/shared/EnvironmentLabels")
return function(T:any)
	T.test("M7 annotations: nearest wins overlap and selection leaves source untouched",function()
		local entries={{id=1,x=200,y=200,z=1,distance=50,w=230,h=64,enabled=true},
			{id=2,x=210,y=200,z=1,distance=10,w=230,h=64,enabled=true},
			{id=3,x=600,y=400,z=1,distance=70,w=230,h=64,enabled=true}}
		local before=Codec.copy(entries); T.same(Labels.select(entries,1280,720),{[2]=true,[3]=true}); T.same(entries,before)
	end)
	T.test("M7 annotations: hidden, distant, offscreen and behind camera are excluded",function()
		local entries={}
		for i=1,5 do entries[i]={id=i,x=100,y=100,z=1,distance=20,w=230,h=64,enabled=true} end
		entries[1].enabled=false; entries[2].distance=116; entries[3].x=-1; entries[4].y=1000; entries[5].z=-1
		T.same(Labels.select(entries,640,480),{})
	end)
	T.test("M7 annotations: mobile and desktop caps with deterministic ties",function()
		local entries={}; for i=1,9 do entries[i]={id=i,x=50,y=i*75,z=1,distance=1,w=20,h=20,enabled=true} end
		local mobile,desktop=Labels.select(entries,400,1000),Labels.select(entries,1280,1000)
		local a,b=0,0; for _ in pairs(mobile) do a+=1 end; for _ in pairs(desktop) do b+=1 end
		T.equal(a,3); T.equal(b,6); T.truthy(mobile[1]); T.falsy(mobile[4])
	end)
	T.test("M7 Gate A: release off, one pilot, no implicit eight-plot rollout",function()
		T.falsy(Settings.EnvironmentArtEnabled); T.falsy(Settings.MonetizationEnabled); T.falsy(Settings.TradingEnabled)
		local p=Plan.build(Config,1); T.equal(p.metrics.decoratedPlots,1); T.throws(function() Plan.build(Config,2) end)
	end)
	T.test("M7 pilot: deterministic closed palette and bounded native geometry",function()
		local a=Plan.build(Config,1); T.same(a,Plan.build(Config,1)); local seen={}
		for _,p in ipairs(a.parts) do
			T.falsy(seen[p.id]); seen[p.id]=true; T.truthy(Config.palette[p.color]); T.truthy(p.detail>=1 and p.detail<=3)
			for _,n in ipairs(p.position) do T.truthy(n==n and math.abs(n)<1000) end
			for _,n in ipairs(p.size) do T.truthy(n>0 and n<100) end
		end
		for _,k in ipairs({"parts","lights","motion","palette"}) do T.truthy(a.metrics[k]<=Config.budgets[k],k) end
		T.equal(a.metrics.externalTextures,0); T.equal(a.metrics.serverParticles,0)
		print("M7_PILOT "..Codec.encode(a.metrics))
		print("M7_PROJECTION nativePartsUpperBound8="..(a.metrics.parts*8).." (arithmetic only; Gate B not built)")
	end)
	for i=1,8 do
		T.test("M7 topology: original 4x2 plot origin / "..i,function()
			T.same(Plan.origin(i),{({-142.5,-47.5,47.5,142.5})[(i-1)%4+1],0,i<=4 and -65 or 85})
		end)
	end
	for _,pose in ipairs({"day","sunset","night","dawn","rain"}) do
		T.test("M7 light: readable bounded preset / "..pose,function()
			local s=State.sample(Config,0,pose); T.truthy(s.clock>=0 and s.clock<24); T.truthy(s.brightness>=.9 and s.brightness<=3)
			T.truthy(s.density<=.45); T.truthy(s.rain>=0 and s.rain<=1); for _,v in ipairs(s.ambient) do T.truthy(v>=90) end
			T.equal(s.rain,pose=="rain" and 1 or 0)
		end)
	end
	T.test("M7 schedule: same server time gives identical weather without player state",function()
		for _,time in ipairs({0,1499,1500,100000,1793836800,1793836800.125}) do T.same(State.sample(Config,time),State.sample(Config,time)) end
		T.same(State.sample(Config,0),State.sample(Config,10500)) -- least common multiple of both cycles.
	end)
	T.test("M7 transitions: midnight and day/weather boundaries are continuous",function()
		for time=1,4500 do
			local a,b=State.sample(Config,time-.01),State.sample(Config,time+.01)
			local distance=math.abs(a.clock-b.clock); T.truthy(math.min(distance,24-distance)<.01)
			T.truthy(math.abs(a.brightness-b.brightness)<.01); T.truthy(math.abs(a.rain-b.rain)<.01)
		end
	end)
	for _,name in ipairs({"full","reduced","minimal"}) do
		T.test("M7 quality: light/rain/motion ceilings and Reduce Motion / "..name,function()
			local before=Codec.copy(Config); local q=State.quality(Config,name,false); T.truthy(q.lights<=6); T.truthy(q.rain<=60); T.truthy(q.motion<=12)
			q=State.quality(Config,name,true); T.equal(q.motion,0); T.equal(q.rain,0); T.same(Config,before)
		end)
	end
	T.test("M7 quality: invalid selection fails to reduced, minimal has no animated effects",function()
		T.same(State.quality(Config,"invalid",false),Config.quality.reduced)
		local q=State.quality(Config,"minimal",false); T.equal(q.rain,0); T.equal(q.motion,0); T.equal(q.lights,0); T.falsy(q.shadows)
	end)
	for epoch=0,2 do
		T.test("M7 appearance: personal epoch is local and M6 aurora remains intact / "..epoch,function()
			local before=State.sample(Config,900); T.equal(State.surface(Config,epoch,false).material,"Grass")
			T.same(State.surface(Config,epoch,true),{color={96,116,168},material="Neon"}); T.same(before,State.sample(Config,900))
		end)
	end
	T.test("M7 local settings: valid quality and accessibility do not need a server command",function()
		local calls={}; Controller.view={setQuality=function(v) calls.quality=v end,setReduceMotion=function(v) calls.motion=v end}
		Controller.setQuality("minimal"); Controller.setReduceMotion(true); T.same(calls,{quality="minimal",motion=true})
		Controller.setQuality("unknown"); T.equal(Controller.quality,"minimal"); Controller.view=nil; Controller.setQuality("reduced"); Controller.setReduceMotion(false)
	end)
	for _,value in ipairs({0/0,math.huge,-math.huge}) do
		T.test("M7 schedule: rejects nonfinite time / "..tostring(value),function() T.throws(function() State.sample(Config,value) end) end)
	end
end
