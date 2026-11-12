--!nonstrict
local Look=require("../src/shared/PostFXLook")
local State=require("../src/shared/EnvironmentState")
local Config=require("../src/shared/EnvironmentConfig")
local function sample(pose) return State.sample(Config,0,pose) end
return function(T: any)
 T.test("AG63 defaults to OFF and produces no override",function()
  T.equal(Look.default,"OFF"); T.equal(Look.project(sample("day"),"OFF","reduced",.012),nil)
 end)
 T.test("AG63 Studio request accepts only four exact look commands",function()
  for _,name in ipairs({"OFF","A","B","C"}) do T.equal(Look.request("look:"..name),name) end
  for _,bad in ipairs({false,42,{},"A","look:a","look:D","look:A\n","look:A;rain"," look:OFF","day"}) do
   T.equal(Look.request(bad),nil)
  end
  T.equal(Look.request(nil),nil)
 end)
 T.test("AG63 invalid look cannot project a new style",function()
  T.equal(Look.project(sample("day"),"bad","full",.04),nil)
 end)
 T.test("AG63 look never mutates the inherited state or weather",function()
  for _,pose in ipairs({"day","dawn","sunset","night","rain","afterrain"}) do
   local before=sample(pose); local expected=sample(pose)
   for _,name in ipairs({"A","B","C"}) do Look.project(before,name,"full",.04) end
   T.same(before,expected)
  end
 end)
 T.test("AG63 twenty switches do not accumulate corrections",function()
  local s=sample("sunset"); local expected={}
  for _,name in ipairs({"A","B","C"}) do expected[name]=Look.project(s,name,"reduced",.012) end
  for i=1,20 do
   local name=({"A","B","C","OFF"})[(i-1)%4+1]
   T.same(Look.project(s,name,"reduced",.012),expected[name])
  end
  T.same(s,sample("sunset"))
 end)
 T.test("AG63 styles remain distinct at daytime and nighttime",function()
  for _,pose in ipairs({"day","night"}) do
   local s=sample(pose); local a,b,c=Look.project(s,"A","reduced",.012),Look.project(s,"B","reduced",.012),Look.project(s,"C","reduced",.012)
   T.truthy(a.tint[3]<b.tint[3]); T.truthy(a.contrast<b.contrast and b.contrast<c.contrast)
  end
 end)
 T.test("AG63 rain remains more diffuse than clear weather in every look",function()
  for _,name in ipairs({"A","B","C"}) do
   local clear=Look.project(State.at(Config,.3,0),name,"full",.04)
   local rain=Look.project(State.at(Config,.3,1),name,"full",.04)
   T.truthy(rain.brightness<clear.brightness); T.truthy(rain.haze>clear.haze)
   T.truthy(rain.density>=clear.density)
  end
 end)
 T.test("AG63 preserves bounded legibility across full day and weather cycle",function()
  for step=0,359 do
   for _,rain in ipairs({0,.5,1}) do
    local s=State.at(Config,step/360,rain)
    for _,name in ipairs({"A","B","C"}) do
     for _,q in ipairs({"full","reduced","minimal"}) do
      local p=Look.project(s,name,q,q=="full" and .04 or .012)
      for _,key in ipairs({"brightness","exposure","contrast","density","haze","bloom"}) do
       T.truthy(p[key]==p[key] and math.abs(p[key])<10)
      end
      T.truthy(p.brightness>=s.brightness and p.brightness<=s.brightness*1.061)
      T.truthy(p.exposure>=s.exposure-.071 and p.exposure<=s.exposure)
      T.truthy(p.density>=.1 and p.density<=.38 and p.contrast<=.0951)
      for _,key in ipairs({"ambient","outdoor","tint","sun"}) do
       for _,component in ipairs(p[key]) do T.truthy(component>=0 and component<=255) end
      end
     end
    end
   end
  end
 end)
 T.test("AG63 night contrast is gentler than daytime contrast",function()
  for _,name in ipairs({"A","B","C"}) do
   local day=Look.project(sample("day"),name,"full",.04)
   local night=Look.project(sample("night"),name,"full",.04)
   T.truthy(math.abs(night.contrast-.025)<math.abs(day.contrast-.025))
  end
 end)
 T.test("AG63 quality decreases correction strength and never increases bloom",function()
  for _,name in ipairs({"A","B","C"}) do
   local s=sample("day")
   local f,r,m=Look.project(s,name,"full",.04),Look.project(s,name,"reduced",.012),Look.project(s,name,"minimal",0)
   T.truthy(math.abs(f.exposure-s.exposure)>math.abs(r.exposure-s.exposure))
   T.truthy(math.abs(r.exposure-s.exposure)>math.abs(m.exposure-s.exposure))
   T.truthy(f.bloom<=.04 and r.bloom<=.012); T.equal(m.bloom,0); T.equal(m.haze,s.haze)
  end
 end)
 T.test("AG63 Reduce Motion does not change look or add motion dependence",function()
  for _,q in ipairs({"full","reduced","minimal"}) do
   local moving=State.quality(Config,q,false); local still=State.quality(Config,q,true)
   for _,name in ipairs({"A","B","C"}) do
    T.same(Look.project(sample("day"),name,q,moving.bloom),Look.project(sample("day"),name,q,still.bloom))
   end
  end
 end)
 T.test("AG63 projection stays continuous through time and weather boundaries",function()
  for step=0,999 do
   local phase=step/1000
   local before=State.at(Config,phase,.4)
   local after=State.at(Config,phase+.000001,.400001)
   for _,name in ipairs({"A","B","C"}) do
    local a,b=Look.project(before,name,"full",.04),Look.project(after,name,"full",.04)
    for _,key in ipairs({"brightness","exposure","contrast","density","haze"}) do T.near(a[key],b[key],.001) end
   end
  end
 end)
end
