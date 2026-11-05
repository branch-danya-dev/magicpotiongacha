--!nonstrict
local State=require("../src/shared/EnvironmentState")
local Config=require("../src/shared/EnvironmentConfig")
local Style=require("../src/shared/AtmosphereStyle")
local Motion=require("../src/shared/MeadowMotion")
local Codec=require("../src/shared/TradeCodec")
local Transition=require("../src/shared/EnvironmentTransition")
return function(T:any)
	T.test("19e: six moods retain distinct identities and readable continuous bounds",function()
		local before=Codec.copy(Config)
		for _,pose in ipairs({"day","dawn","sunset","night","rain","afterrain"}) do
			local s=State.sample(Config,0,pose)
			T.truthy(s.density>=.12 and s.density<=.34 and s.brightness>=.9 and s.brightness<=3)
			T.truthy(s.sunlight>=0 and s.sunlight<=1 and s.pollen>=0 and s.pollen<=.4)
			T.truthy(s.diffuse>=.3 and s.diffuse<=.5 and s.specular<=.16)
		end
		local day,night=State.sample(Config,0,"day"),State.sample(Config,0,"night")
		T.truthy(day.sunlight>.9 and day.pollen>.1 and day.fog>0 and day.glint>0)
		T.equal(night.sunlight,0); T.equal(night.pollen,0); T.truthy(night.tint[3]>night.tint[1]+30)
		T.same(Config,before)
	end)
	T.test("19e: weather suppresses sun/pollen, strengthens wind and preserves sun phase",function()
		for _,phase in ipairs({0,.3,.39,.51,.79}) do
			local clear=State.at(Config,phase,0)
			local rain=State.at(Config,phase,1,{cloud=1,wet=1,afterRain=0})
			T.equal(clear.clock,rain.clock); T.equal(clear.night,rain.night)
			T.truthy(rain.sunlight<=clear.sunlight and rain.pollen<=clear.pollen)
			T.truthy(State.wind(rain,12,false).strength>State.wind(clear,12,false).strength)
		end
	end)
	T.test("19e: after-rain stays clear and wet without sustained sunlight in the storm",function()
		local rain,after=State.sample(Config,0,"rain"),State.sample(Config,0,"afterrain")
		T.equal(rain.sunlight,0); T.equal(after.rain,0)
		T.truthy(after.sunlight>.4 and after.glint>.4 and after.rainbow>0)
	end)
	T.test("19e: every styling field remains continuous at day and weather seams",function()
		for _,time in ipairs({0,450,585,765,1050,1185,1500,660,900,990,1470,1560,1740,1950,2100}) do
			local a,b=State.sample(Config,time-.0001),State.sample(Config,time+.0001)
			for _,k in ipairs({"sunlight","pollen","diffuse","specular","shadowSoftness","saturation","density","haze"}) do T.truthy(math.abs(a[k]-b[k])<.001,k) end
		end
	end)
	T.test("19e: manual pose transitions blend the new channels without a second timeline",function()
		local a,b=State.sample(Config,0,"day"),State.sample(Config,0,"rain")
		local previous=a
		for i=1,100 do
			local s=Transition.blend(a,b,i/100)
			T.truthy(s.sunlight<=previous.sunlight and s.sunlight>=0)
			T.truthy(math.abs(s.pollen-previous.pollen)<.01); previous=s
		end
		T.same(previous,b)
	end)
	T.test("19e: common gust vector is deterministic, bounded and smooth",function()
		local s=State.sample(Config,0,"rain")
		for i=1,500 do
			local a,b=State.wind(s,i*.1,false),State.wind(s,i*.1+.001,false)
			T.same(a,State.wind(s,i*.1,false)); T.truthy(a.strength>=.8 and a.strength<=1)
			T.truthy(a.x*a.x+a.z*a.z<=169.001)
			T.truthy(math.abs(a.x-b.x)<.01 and math.abs(a.z-b.z)<.01)
		end
	end)
	T.test("19e: Reduce Motion removes global gusts, rain, pollen and both foliage budgets",function()
		for _,tier in ipairs({"full","reduced","minimal"}) do
			local q=State.quality(Config,tier,true)
			T.equal(q.motion,0); T.equal(q.motes,0); T.equal(q.rain,0)
			T.same(State.wind(State.sample(Config,0,"rain"),300,true),{strength=0,x=0,z=0})
		end
	end)
	T.test("19e: Reduced retains directional lighting, pollen, fog and restrained rays",function()
		local q=State.quality(Config,"reduced",false)
		T.truthy(q.shadows and q.rays>0 and q.rays<=.01 and q.motes>=9 and q.fog>=2)
		local m=State.quality(Config,"minimal",false); T.falsy(m.shadows); T.equal(m.rays,0)
	end)
	T.test("19e: sun accents reserve slots within the inherited total light cap",function()
		for _,tier in ipairs({"full","reduced","minimal"}) do
			local q=State.quality(Config,tier,false); local sun=State.sunSlots(tier)
			local lamps=math.max(0,q.lights-sun); T.equal(lamps+sun,q.lights)
			T.truthy(sun<=#Style.sunPools and lamps+sun<=Config.budgets.lights)
		end
	end)
	T.test("19e: sun accents depend on actual solar elevation, never underground sun",function()
		local s=State.sample(Config,0,"day")
		T.equal(State.sunVisibility(s,-.1),0); T.equal(State.sunVisibility(s,.04),0)
		T.truthy(State.sunVisibility(s,.14)>.4); T.equal(State.sunVisibility(s,.5),s.sunlight)
		T.equal(State.sunVisibility(State.sample(Config,0,"rain"),.7),0)
	end)
	T.test("19e: daytime pollen uses all Reduced slots and stays local above ground",function()
		local s=State.sample(Config,0,"day"); local flow=State.wind(s,25,false)
		for i=1,Config.quality.reduced.motes do
			local a,b=State.pollen(i,25,s,flow),State.pollen(i,25.001,s,flow)
			local anchor=Style.pollenAnchors[a.anchor]
			T.truthy(a.alpha>0 and a.alpha<=.4 and a.y>1 and a.y<5)
			T.truthy(math.abs(a.x-anchor[1])<4 and math.abs(a.z-anchor[2])<4)
			T.truthy(math.abs(a.x-b.x)<.01 and math.abs(a.y-b.y)<.01 and math.abs(a.alpha-b.alpha)<.001)
		end
	end)
	T.test("19e: pollen and firefly channels trade places without storm visual noise",function()
		for i=1,24 do
			local day=State.sample(Config,0,"day"); local rain=State.sample(Config,0,"rain"); local night=State.sample(Config,0,"night")
			local flow=State.wind(day,15,false)
			local a,b,c=State.pollen(i,15,day,flow),State.pollen(i,15,rain,flow),State.pollen(i,15,night,flow)
			T.truthy(b.alpha<a.alpha and c.alpha<=.6)
			if i%3==0 then T.equal(c.alpha,0) else T.truthy(c.alpha>a.alpha) end
		end
	end)
	for _,cap in ipairs({4,12}) do
		T.test("19e: grouped crown costs include fading lobes during camera turns / "..cap,function()
			local entries={}; for i=1,16 do entries[i]={visible=true,cost=i%3==0 and 1 or 4,weight=0} end
			for frame=1,300 do
				if frame%11==0 then table.insert(entries,1,table.remove(entries)) end
				local used=Motion.step(entries,cap,1/30); local counted=0
				for _,e in ipairs(entries) do if e.weight>0 then counted+=e.cost end end
				T.equal(used,counted); T.truthy(used<=cap)
			end
		end)
	end
	T.test("19e: quality downgrade clears whole groups; cannot split a four-lobe crown",function()
		local entries={{visible=true,cost=4,weight=1},{visible=true,cost=4,weight=1},{visible=true,cost=1,weight=1}}
		T.equal(Motion.step(entries,4,.03),4); T.equal(entries[2].weight,0); T.equal(entries[3].weight,0)
		T.equal(Motion.step(entries,0,.03),0)
		for _,e in ipairs(entries) do T.equal(e.weight,0) end
	end)
end
