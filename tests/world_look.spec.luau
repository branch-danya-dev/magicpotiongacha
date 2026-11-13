--!nonstrict
local Look=require("../src/shared/WorldLook")
local State=require("../src/shared/EnvironmentState")
local Config=require("../src/shared/EnvironmentConfig")
local Transition=require("../src/shared/EnvironmentTransition")
local function sample(pose) return State.sample(Config,0,pose) end
local function project(s,q) return Look.project(s,"AG68",q or "reduced") end
return function(T: any)
 T.test("AG68 opts in only for literal Studio true, never release",function()
  T.equal(Look.default(true),"AG68");T.equal(Look.default(false),"OFF");T.equal(Look.default(nil),"OFF")
  T.equal(Look.default("true"),"OFF");T.equal(Look.releaseEnabled,false)
 end)
 T.test("AG68 request parsing is exact and leaves other reviews to their owner",function()
  T.equal(Look.request("look:AG68"),"AG68")
  for _,bad in ipairs({false,5,{},"look:ag68","look:AG68\n","AG68","look:OFF","look:A","day"}) do T.equal(Look.request(bad),nil) end
  T.equal(Look.request(nil),nil)
 end)
 T.test("AG68 OFF and historical AG63 looks produce no new projection",function()
  for _,name in ipairs({"OFF","A","B","C","invalid"}) do T.equal(Look.project(sample("night"),name,"full"),nil) end
 end)
 T.test("AG68 never mutates the time/weather sample or palette",function()
  local s=sample("rain");local old=sample("rain");local day=table.clone(Look.palette.day)
  local first=project(s);first.ambient[1]=0;first.brightness=0
  T.same(s,old);T.same(Look.palette.day,day);T.truthy(project(s).ambient[1]>0)
 end)
 T.test("AG68 color identity survives Reduced and Minimal without extra VFX",function()
  for _,pose in ipairs({"day","sunset","night","rain"}) do
   local s=sample(pose);local a,b,c=project(s,"full"),project(s,"reduced"),project(s,"minimal")
   T.same(a.tint,b.tint);T.same(b.tint,c.tint);T.same(a.ambient,c.ambient)
   T.equal(c.bloom,0);T.equal(c.rays,0);T.truthy(b.bloom<a.bloom)
  end
 end)
 T.test("AG68 downward quality changes obey immediate effect caps",function()
  local s=sample("day")
  for _,q in ipairs({"full","reduced","minimal"}) do
   local p=Look.project(s,"AG68",q,1,1)
   T.truthy(p.bloom<=Look.quality[q].bloom);T.truthy(p.rays<=Look.quality[q].rays)
  end
  T.equal(Look.project(s,"AG68","full",0,0).bloom,0)
 end)
 T.test("AG68 unknown quality falls back to Reduced",function() T.same(project(sample("day"),"bad"),project(sample("day"))) end)
 T.test("AG68 clear sunset, day and night have distinct legible color targets",function()
  local day,sunset,night=project(sample("day")),project(sample("sunset")),project(sample("night"))
  T.truthy(day.tint[3]>day.tint[1]);T.truthy(sunset.tint[1]>sunset.tint[3]);T.truthy(night.ambient[3]>night.ambient[1]*1.5)
  T.truthy(night.exposure>day.exposure);T.truthy(night.contrast<day.contrast)
  T.truthy(night.brightness>1.6);T.truthy(day.contrast>.1)
 end)
 T.test("AG68 independent rain overlay cools, diffuses and keeps night readable",function()
  for _,phase in ipairs({0,.3,.51,.79}) do
   local clear=project(State.at(Config,phase,0));local rain=project(State.at(Config,phase,1))
   T.truthy(rain.brightness<clear.brightness and rain.brightness>1.3)
   T.truthy(rain.haze>clear.haze);T.truthy(rain.density>=clear.density)
   T.equal(rain.rays,0);T.equal(rain.glare,0);T.truthy(rain.contrast<clear.contrast)
  end
 end)
 T.test("AG68 after rain clears haze without changing the weather sample",function()
  local a=State.at(Config,0,0,{cloud=0,wet=1,afterRain=1});local b=State.at(Config,0,0)
  T.truthy(project(a).haze<project(b).haze);T.truthy(project(a).density<project(b).density)
  T.equal(a.afterRain,1);T.equal(a.wet,1)
 end)
 T.test("AG68 complete continuous cycle stays inside legibility and effect budgets",function()
  for i=0,719 do for _,rain in ipairs({0,.5,1}) do for _,q in ipairs({"full","reduced","minimal"}) do
   local p=project(State.at(Config,i/720,rain),q)
   T.truthy(p.brightness>=1.3 and p.brightness<=2.71);T.truthy(p.exposure>=-.10 and p.exposure<=.73)
   T.truthy(p.density>=.20 and p.density<=.36);T.truthy(p.haze>=.49 and p.haze<=2.26)
   T.truthy(p.bloom<=.16 and p.rays<=.035 and p.contrast<=.145)
   for _,key in ipairs({"ambient","outdoor","tint","sky","decay","sun"}) do for _,v in ipairs(p[key]) do T.truthy(v>=0 and v<=255) end end
  end end end
 end)
 T.test("AG68 cycle seam and inherited weather stage boundaries do not pop",function()
  local function near(a,b) for k,v in pairs(a) do if type(v)=="table" then for j,n in ipairs(v) do T.near(n,b[k][j],.01) end else T.near(v,b[k],.01) end end end
  near(project(State.at(Config,1-1e-7,0)),project(State.at(Config,0,0)))
  for time=1,Config.weatherSeconds do
   local before=State.weather(Config,time-1e-5);local after=State.weather(Config,time+1e-5)
   near(project(State.at(Config,.3,before.rain,before)),project(State.at(Config,.3,after.rain,after)))
  end
 end)
 T.test("AG68 interrupted transitions use continuous owner channels",function()
  local t=Transition.new();t.sample(sample("day"),0);t.begin(0)
  local s=t.sample(sample("rain"),4);local before=project(s);t.begin(4)
  T.same(project(t.sample(sample("night"),4)),before)
  local after=project(t.sample(sample("night"),4.001));T.near(after.exposure,before.exposure,.001)
 end)
 T.test("AG68 20 switches at every quality/time do not accumulate or change baseline",function()
  for _,q in ipairs({"full","reduced","minimal"}) do for _,pose in ipairs({"day","sunset","night","rain"}) do
   local s=sample(pose);local expected=project(s,q)
   for i=1,20 do T.same(project(s,q),expected);T.equal(Look.project(s,"OFF",q),nil) end
   T.same(s,sample(pose))
  end end
 end)
end
