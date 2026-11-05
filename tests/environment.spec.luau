--!nonstrict
local Config=require("../src/shared/EnvironmentConfig")
local State=require("../src/shared/EnvironmentState")
local Plan=require("../src/shared/EnvironmentPlan")
local Meadow=require("../src/shared/MeadowPlan")
local Terrain=require("../src/shared/EnvironmentTerrain")
local Codec=require("../src/shared/TradeCodec")
local Settings=require("../src/server/ServerSettings")
local Controller=require("../src/client/EnvironmentController")
local Labels=require("../src/shared/EnvironmentLabels")
return function(T:any)
	T.test("M7 A2c: moon world bearing is normalized, low and continuous across the seam",function()
		for i=0,1000 do
			local d=State.moon(i/1000); T.truthy(math.abs(d[1]^2+d[2]^2+d[3]^2-1)<1e-9)
			T.truthy(d[2]>.28 and d[2]<.4)
		end
		local a,b=State.moon(0),State.moon(1); for i=1,3 do T.truthy(math.abs(a[i]-b[i])<1e-9) end
	end)
	T.test("M7 A2c: celestial fade excludes day and overcast night without popping",function()
		T.equal(State.sample(Config,0,"day").celestial,0)
		T.equal(State.sample(Config,0,"night").celestial,1)
		T.equal(State.at(Config,.51,1).celestial,0)
		for i=1,1000 do
			local a=State.at(Config,.51,0,{cloud=(i-1)/1000}); local b=State.at(Config,.51,0,{cloud=i/1000})
			T.truthy(b.celestial<=a.celestial and math.abs(a.celestial-b.celestial)<.003)
		end
	end)
	T.test("M7 A2c: static stars stay normalized, above horizon and within alpha bounds",function()
		for i=1,Config.celestial.stars do
			local d=State.star(i); T.same(d,State.star(i)); T.truthy(math.abs(d.x*d.x+d.y*d.y+d.z*d.z-1)<1e-9)
			T.truthy(d.y>.2 and d.y<1); T.truthy(d.alpha>0 and d.alpha<=1); T.truthy(d.size<=3.3)
		end
	end)
	T.test("M7 A2c: dawn and sunset have distinct shadow hues and localized fog",function()
		local a,b=State.sample(Config,0,"dawn"),State.sample(Config,0,"sunset")
		T.truthy(a.ambient[2]>a.ambient[1]+30); T.truthy(b.ambient[3]>b.ambient[2])
		T.truthy(a.fog>b.fog+.8); T.truthy(a.glint>0); T.truthy(a.warm<b.warm)
	end)
	T.test("M7 A2c: wet stone survives clearing and dries without changing material semantics",function()
		local a=State.sample(Config,0,"afterrain"); T.truthy(a.wetStone>.5)
		T.equal(State.sample(Config,0,"day").wetStone,0)
		T.equal(State.surface(Config,0,false).material,"Grass")
		T.equal(State.surface(Config,0,true).material,"Neon")
	end)
	for _,tier in ipairs({"full","reduced","minimal"}) do
		T.test("M7 A2c: core night identity survives Reduce Motion / "..tier,function()
			local q=State.quality(Config,tier,true); T.truthy(q.stars>=12 and q.stars<=Config.budgets.stars)
			T.equal(q.rain,0); T.equal(q.motion,0); T.equal(q.motes,0)
		end)
	end
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
	T.test("M7 pilot: deterministic reviewed catalog and bounded geometry",function()
		local a=Plan.build(Config,1); T.same(a,Plan.build(Config,1)); local seen={}
		for _,p in ipairs(a.parts) do
			T.falsy(seen[p.id]); seen[p.id]=true; T.truthy(Config.palette[p.color]); T.truthy(p.detail>=1 and p.detail<=3)
			for _,n in ipairs(p.position) do T.truthy(n==n and math.abs(n)<1000) end
			for _,n in ipairs(p.size) do T.truthy(n>0 and n<100) end
		end
		for _,k in ipairs({"parts","lights","motion","palette","triangles","textureMiB"}) do T.truthy(a.metrics[k]<=Config.budgets[k],k) end
		T.equal(a.metrics.externalTextures,12); T.equal(a.metrics.serverParticles,0)
		print("M7_PILOT "..Codec.encode(a.metrics))
		print("M7_PROJECTION meshPartsUpperBound8="..(a.metrics.parts*8).." (arithmetic only; Gate B not built)")
	end)
	T.test("M7 terrain: continuous flat clearing contains all fixed work anchors",function()
		for x=-38,38,2 do for z=-45,29,2 do
			T.truthy(math.abs(Terrain.height(-142.5+x,-65+z)-.45)<.0001); T.truthy(Terrain.reserved(-142.5+x,-65+z))
		end end
		for x=-240,-92,3 do for z=-180,-20,3 do
			local h=Terrain.height(x,z); T.truthy(h>-24 and h<32)
			T.truthy(math.abs(h-Terrain.height(x+.01,z))<.1)
		end end
	end)
	T.test("M7 terrain: aligned reserved region excludes other plots and public corridor",function()
		for _,b in pairs(Terrain.bounds) do for _,v in ipairs(b) do T.equal(v%4,0) end end
		for i=2,8 do local o=Plan.origin(i); T.falsy(Terrain.contains(o[1]-38.5,o[3]-45.5)); T.falsy(Terrain.contains(o[1]+38.5,o[3]+29.5)) end
		T.falsy(Terrain.contains(-142.5,-12)); T.falsy(Terrain.contains(0,0))
	end)
	T.test("M7 assets: all placements use the closed catalog and plants avoid work zones",function()
		local used={}
		for _,p in ipairs(Plan.build(Config,1).parts) do if p.template then
			T.truthy(Plan.catalog[p.template]); used[p.template]=true
			if p.meadow then T.truthy(Meadow.clear(p.position[1]+142.5,p.position[3]+65,p.radius))
			elseif p.template~="RockPath_Round_Small_1" then
				local x,z=p.position[1]+142.5,p.position[3]+65
				T.truthy(math.abs(x)>38.5 or z< -45.5 or z>29.5,p.template)
			end
		end end
		for name in pairs(Plan.catalog) do T.truthy(used[name],name) end
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
	T.test("M7 A2: all atmosphere fields remain continuous at authored keys and cycle seam",function()
		for _,key in ipairs(Config.keys) do
			local a=State.at(Config,(key.phase-1e-6)%1,.5); local b=State.at(Config,(key.phase+1e-6)%1,.5)
			for name,value in pairs(a) do if name~="phase" and name~="clock" then
				if type(value)=="table" then for i,v in ipairs(value) do T.truthy(math.abs(v-b[name][i])<.01,name) end
				else T.truthy(math.abs(value-b[name])<.01,name) end
			end end
		end
	end)
	T.test("M7 A2: rain timing is configurable and periodic without abrupt onset",function()
		local c=Codec.copy(Config); c.weatherSeconds=100; c.weather={start=10,rise=20,finish=60,fall=30}
		T.equal(State.sample(c,9).rain,0); T.equal(State.sample(c,30).rain,1); T.equal(State.sample(c,90).rain,0)
		T.truthy(State.sample(c,20).rain>0 and State.sample(c,20).rain<1)
		T.equal(State.sample(c,20).rain,State.sample(c,120).rain)
	end)
	T.test("M7 A2: reproducible preview loops and reaches night plus rain",function()
		T.same(State.preview(Config,0),State.preview(Config,Config.previewSeconds))
		T.truthy(State.preview(Config,Config.previewSeconds*.51).night>.95)
		T.truthy(State.preview(Config,Config.previewSeconds*.84).rain>.95)
		T.throws(function() State.preview(Config,math.huge) end)
	end)
	for _,tier in ipairs({"full","reduced","minimal"}) do
		T.test("M7 A2: bounded ambient effects and complete ReduceMotion / "..tier,function()
			local q=State.quality(Config,tier,false)
			T.truthy(q.motes<=Config.budgets.motes); T.truthy(q.bloom<=.05); T.truthy(q.rays<=.03)
			q=State.quality(Config,tier,true); T.equal(q.motes,0); T.equal(q.motion,0); T.equal(q.rain,0)
		end)
	end
	T.test("M7 A2: motes stay at the pilot perimeter, fade smoothly and do not mutate inputs",function()
		local before=Codec.copy(Config)
		for i=1,24 do for time=0,30 do
			local m=State.mote(i,time,1,0); local n=State.mote(i,time+.01,1,0)
			T.same(m,State.mote(i,time,1,0)); T.truthy(m.x> -190 and m.x< -95 and m.z> -112 and m.z< -37)
			T.truthy(m.y>1 and m.y<7); T.truthy(m.alpha>=0 and m.alpha<=.65)
			T.truthy(math.abs(m.alpha-n.alpha)<.01); T.truthy(State.mote(i,time,1,1).alpha<=m.alpha)
		end end
		T.same(Config,before)
	end)
	T.test("M7 A2b: weather stages advance independently of sun and return to clear",function()
		for _,entry in ipairs({{0,"clear"},{700,"buildup"},{1100,"rain"},{1600,"clearing"},{1800,"after-rain"},{2050,"clear"}}) do
			T.equal(State.weatherStage(Config,entry[1]),entry[2])
		end
		local buildup=State.weather(Config,780); T.truthy(buildup.cloud>0); T.equal(buildup.rain,0)
		local clearing=State.weather(Config,1630); T.equal(clearing.rain,0); T.truthy(clearing.cloud>0 and clearing.wet>0)
		local after=State.weather(Config,1800); T.equal(after.cloud,0); T.truthy(after.afterRain>0 and after.wet>0)
	end)
	T.test("M7 A2b: weather overlay preserves time, night and dawn identities",function()
		for _,p in ipairs({0,.3,.39,.51,.79,.999}) do
			local clear,wet=State.at(Config,p,0),State.at(Config,p,1,{cloud=1,wet=1,afterRain=0})
			for _,k in ipairs({"clock","night","dawn","warm"}) do T.equal(clear[k],wet[k]) end
			T.truthy(wet.brightness<clear.brightness); T.truthy(wet.cover>clear.cover); T.truthy(wet.haze>clear.haze)
		end
	end)
	T.test("M7 A2b: every weather channel is bounded and continuous across two cycles",function()
		for time=0,4200 do
			local a,b=State.weather(Config,time-.001),State.weather(Config,time+.001)
			for k,v in pairs(a) do T.truthy(v>=0 and v<=1,k); T.truthy(math.abs(v-b[k])<.001,k) end
		end
	end)
	T.test("M7 A2b: all preview fields close at the seam without a texture switch",function()
		local a,b=State.preview(Config,45-.00001),State.preview(Config,.00001)
		for k,v in pairs(a) do if k~="phase" then
			if type(v)=="table" then for i,c in ipairs(v) do T.truthy(math.abs(c-b[k][i])<.001,k) end
			else T.truthy(math.abs(v-b[k])<.001,k) end
		end end
	end)
	T.test("M7 A2b: six review states, intermediate dusk, and actual sunset target",function()
		local after=State.sample(Config,0,"afterrain"); T.equal(after.rain,0); T.truthy(after.wet>.5 and after.rainbow>0)
		local dusk=State.sample(Config,0,"dusk"); T.truthy(dusk.night>.3 and dusk.night<1)
		local sunset=State.sample(Config,0,"sunset"); T.truthy(sunset.clock>=17.6 and sunset.clock<=18.5)
		T.truthy(State.sample(Config,0,"dawn").fog>State.sample(Config,0,"day").fog)
	end)
	for _,tier in ipairs({"full","reduced","minimal"}) do
		T.test("M7 A2b: pooled local effects remain capped with motion disabled / "..tier,function()
			local q=State.quality(Config,tier,true)
			for _,k in ipairs({"fog","glints","rainbow","rain","motes","motion","lights"}) do T.truthy(q[k]<=Config.budgets[k],k) end
			T.equal(q.haze,1) -- Core atmosphere/weather identity is not culled by quality.
			T.equal(q.rain,0); T.equal(q.motion,0); T.equal(q.motes,0)
		end)
	end
end
