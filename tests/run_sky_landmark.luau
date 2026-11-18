--!nonstrict
local T=require("./Test")
local M=require("../qa/sky-landmark/Model")
local C=require("../qa/sky-landmark/Config")
local R=require("../qa/sky-landmark/Resources")
local Lunar=require("../qa/lunar/Cycle")
local H=require("../qa/sky-landmark/Horizon")
local function sample(n,w,c)return {night=n,warm=w,cloud=c}end
T.test("Landmark is distant and apparent size changes less than 5 percent across island",function()
	local p=C.offset;local d=math.sqrt(p[1]^2+p[2]^2+p[3]^2);T.truthy(d>2400)
	local near,far=math.huge,0
	for x=-62,62,124 do for z=-58,58,116 do local v=math.sqrt((p[1]-x)^2+p[2]^2+(p[3]-z)^2);near=math.min(near,v);far=math.max(far,v)end end
	T.truthy(far/near<1.05);T.truthy(C.offset[2]>0)
end)
T.test("The landmark does not change lunar probabilities or the existing clock",function()
	T.equal(Lunar.seconds,1500);T.same(Lunar.weights,{60,20,20})
	local s=sample(1,0,.2);local weights={.2,.5,.3};local prior=table.clone(s)
	for i=1,100 do M.project(s,weights,"full",i,false)end;T.same(s,prior);T.same(weights,{.2,.5,.3})
end)
T.test("Day silhouette is visible and dusk/night retain bounded glow",function()
	local day=M.project(sample(0,0,0),{1,0,0},"full",0,false)
	local dusk=M.project(sample(.5,1,0),{1,0,0},"full",0,false)
	local night=M.project(sample(1,0,0),{1,0,0},"full",0,false)
	T.truthy(day.tree>.3 and day.glow<.03);T.truthy(dusk.tree>day.tree);T.truthy(night.glow>day.glow and night.glow<.16)
end)
T.test("Blood and frost only subtly tint the retained tree palette",function()
	local a=M.project(sample(1,0,0),{1,0,0},"full",0,false)
	for _,w in ipairs({{0,1,0},{0,0,1}})do local b=M.project(sample(1,0,0),w,"full",0,false);for i=1,3 do T.truthy(math.abs(a.color[i]-b.color[i])<.06)end end
end)
T.test("Weather and lunar crossfades remain continuous",function()
	local prior=M.project(sample(1,0,0),{1,0,0},"full",0,false)
	for i=1,1000 do local t=i/1000;local b=M.project(sample(1,0,t),{1-t,t,0},"full",0,false);T.truthy(math.abs(b.tree-prior.tree)<.001);T.truthy(math.abs(b.color[1]-prior.color[1])<.001);prior=b end
end)
T.test("Minimal and Reduce Motion freeze cloud phase while zero wind remains stationary",function()
	T.equal(M.advance(7,.1,20,2,"minimal",false),7);T.equal(M.advance(7,.1,20,2,"full",true),7)
	T.equal(M.advance(7,.1,0,0,"full",false),7);T.truthy(M.advance(7,.1,20,2,"full",false)>7)
	T.truthy(M.advance(7,.1,-20,-2,"full",false)<7)
	local a=M.project(sample(1,0,0),{1,0,0},"minimal",7,false);T.equal(a.minimal,1);T.equal(a.moving,0);T.equal(a.glow,0)
end)
T.test("Motion stays inside the permanent lower cloud cover, even at storm strength",function()
	for i=0,1000 do local s=M.project(sample(1,0,0),{1,0,0},"full",i,false);T.truthy(math.abs(s.x)<=1);T.truthy(math.abs(s.y)<=1)end
	T.near(M.smooth(M.smooth(0,1,.1),1,.1),M.smooth(0,1,.2),1e-10)
end)
T.test("Resource cache cannot multiply textures across 20 quality changes",function()
	local r=R.new();local creates,destroys=0,0
	local function make()creates+=1;return {Destroy=function()destroys+=1 end}end
	for _=1,20 do for _,name in ipairs({"tree","cloud","glow","minimal"})do r.get(name,make)end end
	T.equal(creates,4);r.destroy();r.destroy();T.equal(destroys,4);T.equal(#r.items,0);T.falsy(pcall(r.get,"tree",make))
end)
T.test("Partial allocation failure releases every previously created resource",function()
	local r=R.new();local freed=0;r.get("first",function()return{Destroy=function()freed+=1 end}end)
	T.falsy(pcall(r.get,"failure",function()error("image budget")end));r.destroy();T.equal(freed,1);T.equal(#r.items,0)
end)
T.test("Quality and memory budgets are explicit",function()
	T.equal(C.imageCount,4);T.equal(C.textureBytes,6553600);T.equal(C.maxInstances,45)
	T.truthy(C.quality.full.hz>C.quality.reduced.hz and C.quality.reduced.hz>C.quality.minimal.hz)
	T.equal(C.quality.minimal.layers,10);T.falsy(pcall(M.project,sample(0,0,0),{1,0,0},"invalid",0,false))
end)
T.test("Alpha-aware composition meets the owner's approximate reference rectangle without camera overrides",function()
	-- Estimated from book/arch/pine positions in the provided image(7), not a native art PASS.
	local yaw=math.rad(-14.98);local x,z=C.offset[1]+6.085,C.offset[3]-22.277
	local center={x*math.cos(yaw)+z*math.sin(yaw),C.offset[2]-8,x*math.sin(yaw)-z*math.cos(yaw)}
	local shape={crop={x=52,y=288,width=921,height=370},visible={x=61,y=296,width=903,height=341}}
	local b=M.bounds(center,C.tree.size,C.tree.offset,shape,{2048,1074},70)
	T.near(b.left,820,15);T.near(b.right,1805,15);T.near(b.top,140,15);T.near(b.bottom,560,15)
	T.truthy((b.right-b.left)/2048>.47 and (b.right-b.left)/2048<.50)
	T.equal(M.bounds({0,0,-5000},C.tree.size,C.tree.offset,shape,{2048,1074},70),nil)
end)
T.test("Cloud ocean is below the island with overlapping coverage around all bearings",function()
	local banks=M.ocean(C);T.equal(#banks+1,8)
	for _,b in ipairs(banks)do
		T.truthy(b.y< -800);T.near(math.sqrt(b.x*b.x+b.z*b.z),C.cloud.radius,1e-6)
		-- Conservatively ignore the outer 20 percent soft fringe.
		T.truthy(math.deg(2*math.atan(b.width*.8/(2*C.cloud.radius)))>360/C.cloud.sectors)
		T.truthy(b.density>=.94 and b.density<=1)
	end
end)
T.test("Cloud mass remains visible at night in every quality while extra layers are disabled",function()
	for _,q in ipairs({"full","reduced","minimal"})do
		local p=M.project(sample(1,0,0),{1,0,0},q,0,false)
		T.truthy(p.cloud*C.cloud.opacity*C.cloud.density>.8)
		for _,channel in ipairs(p.cloudColor)do T.truthy(channel>.3 and channel<.8)end
		if q=="minimal"then T.equal(p.glow,0);T.equal(p.haze,0);T.equal(p.moving,0)end
	end
end)
T.test("R3 keeps R2 placement and independent layer sizes exactly",function()
	T.same(C.offset,{510,1150,-5175});T.same(C.tree.size,{6400,2920});T.same(C.tree.offset,{0,0})
	T.same(C.cloud.size,{6750,2500});T.same(C.cloud.offset,{0,-2070});T.same(C.glow.size,{7350,3520})
end)
T.test("Sun and moon directions select the lit side; below-horizon lights cannot illuminate",function()
	local d={sun={-.8,.6,.6},moon={.8,-.6,-.6}}
	local a=M.light(sample(0,0,0),{1,0,0},"full",d)
	T.truthy(a.left>.3 and a.right==0 and a.top>0);T.truthy(a.color[1]>a.color[3])
	d.sun={.8,.6,.6};local b=M.light(sample(0,0,0),{1,0,0},"full",d);T.near(a.left,b.right,1e-10)
	d.sun={1,1,-.3};d.moon={1,1,-.3}
	local dark=M.light(sample(.5,.5,0),{1,0,0},"full",d);T.equal(dark.top,0);T.equal(dark.left,0);T.equal(dark.right,0)
end)
T.test("Three lunar accents stay distinct without changing base tree color or geometry",function()
	local d={sun={0,-1,-1},moon={.6,.8,.8}}
	local p=M.light(sample(1,0,0),{1,0,0},"full",d)
	local b=M.light(sample(1,0,0),{0,1,0},"full",d)
	local f=M.light(sample(1,0,0),{0,0,1},"full",d)
	T.truthy(p.color[3]>p.color[1]);T.truthy(b.color[1]>b.color[2]*1.5)
	T.truthy(f.color[2]>f.color[1]*1.5);T.near(p.top,b.top,1e-10);T.near(p.top,f.top,1e-10)
end)
T.test("Directional accents remain bounded and continuous across dusk and horizon",function()
	local prior=nil
	for i=0,1000 do
		local t=i/1000;local d={sun={.8,.3,.3-.6*t},moon={-.8,.3,-.3+.6*t}}
		local l=M.light(sample(t,1,0),{1-t,t,0},"full",d)
		for _,k in ipairs({"top","left","right"})do T.truthy(l[k]>=0 and l[k]<=.55);if prior then T.truthy(math.abs(l[k]-prior[k])<.006)end end
		prior=l
	end
end)
T.test("Minimal retains only top light and Reduce Motion does not freeze astronomical lighting",function()
	local d={sun={-.8,.6,.6},moon={.8,-.6,-.6}}
	local min=M.project(sample(0,0,0),{1,0,0},"minimal",7,true,d)
	T.truthy(min.lightTop>0);T.equal(min.lightLeft,0);T.equal(min.lightRight,0)
	local a=M.project(sample(0,0,0),{1,0,0},"full",7,true,d)
	d.sun={.8,.6,.6};local b=M.project(sample(0,0,0),{1,0,0},"full",7,true,d)
	T.truthy(a.lightLeft>b.lightLeft and b.lightRight>a.lightRight)
end)
T.test("Weather attenuates highlights and ocean follows final atmosphere without whitening",function()
	local d={sun={.8,.6,.6},moon={-.8,-.6,-.6},sky={.5,.6,.7}}
	local clear=M.project(sample(0,0,0),{1,0,0},"full",0,false,d)
	local storm=M.project(sample(0,0,1),{1,0,0},"full",0,false,d)
	T.truthy(storm.lightRight<clear.lightRight*.5)
	for _,c in ipairs(clear.cloudColor)do T.truthy(c>.5 and c<.9)end
end)
T.test("Horizon ablations isolate controls and always return to a complete candidate",function()
	T.falsy(H.valid("publish"));T.falsy(H.valid(nil));T.falsy(pcall(H.plan,"bad"))
	T.equal(H.plan("baseline").offset,.15);T.equal(H.plan("offset0").offset,0);T.equal(H.plan("offsetNegative").offset,-.05)
	for _,pair in ipairs({{"noAtmosphere","atmosphere"},{"noOcean","ocean"},{"noSky","sky"},{"noNativeClouds","nativeClouds"}})do
		local plan=H.plan(pair[1]);T.equal(plan.offset,.15)
		for _,key in ipairs({"atmosphere","ocean","sky","nativeClouds"})do T.equal(plan[key],key~=pair[2])end
	end
	local p=H.plan("candidate");for _,key in ipairs({"atmosphere","ocean","sky","nativeClouds"})do T.truthy(p[key])end
	T.equal(p.offset,0);T.falsy(p.neutralScatter)
end)
T.finish()
