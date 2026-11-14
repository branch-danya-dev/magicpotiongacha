--!nonstrict
local Forest=require("../src/shared/ArcaneForest")
local State=require("../src/shared/EnvironmentState")
local Config=require("../src/shared/EnvironmentConfig")
return function(T)
	T.test("AG70 only opts Studio into review; legacy requests remain separate",function()
		assert(Forest.default(true)=="AG70" and Forest.default(false)=="OFF" and Forest.default(nil)=="OFF")
		assert(Forest.releaseEnabled==false and Forest.request("look:AG70")=="AG70")
		assert(Forest.request("AG70")==nil and Forest.request("look:AG68")==nil)
	end)
	T.test("AG70 OFF and legacy presets never project",function()
		for _,name in ipairs({"OFF","AG68","A","B","C","invalid"}) do assert(Forest.project({},name,"full")==nil) end
	end)
	for _,tier in ipairs({"full","reduced","minimal"}) do
		T.test("AG70 continuous bounded day/weather cycle "..tier,function()
			local previous
			for i=0,3000 do
				local sample=State.sample(Config,i)
				local p=Forest.project(sample,"AG70",tier)
				assert(p.density>=.25 and p.density<=.35 and p.haze<2.2)
				assert(p.exposure<.15 and p.bloom<=.10 and p.bloomThreshold>=1.9)
				for k,v in pairs(p) do
					if type(v)=="number" then assert(v==v and math.abs(v)<100) end
					if previous and type(v)=="number" then assert(math.abs(v-previous[k])<.1,k.." discontinuity") end
				end
				previous=p
			end
		end)
		T.test("AG70 night has lower fill than day even in rain "..tier,function()
			local day=Forest.project(State.sample(Config,0,"day"),"AG70",tier)
			local night=State.sample(Config,0,"night")
			for _,cloud in ipairs({0,.5,1}) do
				local p=Forest.project(State.at(Config,night.phase,cloud,{cloud=cloud,wet=cloud,afterRain=0}),"AG70",tier)
				assert(p.ambient[1]<day.ambient[1] and p.outdoor[2]<day.outdoor[2])
				assert(p.diffuse<day.diffuse and p.exposure<=day.exposure)
			end
		end)
	end
	T.test("AG70 post effects respect tier caps and fade",function()
		local s=State.sample(Config,0,"day")
		local f=Forest.project(s,"AG70","full");local r=Forest.project(s,"AG70","reduced");local m=Forest.project(s,"AG70","minimal")
		assert(f.bloom>r.bloom and f.rays>r.rays and m.bloom==0 and m.rays==0)
		local zero=Forest.project(s,"AG70","full",0,0);assert(zero.bloom==0 and zero.rays==0)
		local half=Forest.project(s,"AG70","full",.02,.01);assert(half.bloom==f.bloom*.5 and half.rays==f.rays*.5)
	end)
	T.test("AG70 local pools have bounded steady intensity and warmer lamps",function()
		for i=0,1500 do
			local s=State.sample(Config,i)
			local a=Forest.localLight(s,"lantern");local b=Forest.localLight(s,"canopy")
			assert(a.brightness>=0 and a.brightness<=3.1 and b.brightness>=0 and b.brightness<=1.6)
			assert(a.color[1]>a.color[3])
		end
	end)
	T.test("AG70 projection does not mutate baseline sample or accumulate",function()
		local s=State.sample(Config,0,"sunset");local saved=table.clone(s);local first=Forest.project(s,"AG70","reduced")
		for _=1,80 do
			assert(Forest.project(s,"OFF","reduced")==nil)
			local p=Forest.project(s,"AG70","reduced");assert(p.exposure==first.exposure and p.ambient[2]==first.ambient[2])
		end
		for k,v in pairs(s) do assert(v==saved[k]) end
	end)
end
