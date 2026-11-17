--!nonstrict
local T=require("./Test")
local C=require("../qa/trees/TreeVisualConfig")
local W=require("../qa/trees/TreeWindModel")
local c=C.species.willow
T.test("Tree appearance is stable, independent of spawn order",function()
	local a=C.select("willow","hero");C.select("willow","unrelated");T.same(a,C.select("willow","hero"))
	local counts={c={},r={},b={},f={}}
	for i=1,100 do local v=C.select("willow","tree-"..i);counts.c[v.crown]=true;counts.r[v.root]=true;counts.b[v.bark]=true;counts.f[v.foliage]=true;T.truthy(v.scale>=c.scaleMin and v.scale<=c.scaleMax)end
	for _,key in ipairs({"c","r","f"})do for i=1,3 do T.truthy(counts[key][i])end end
	for i=1,4 do T.truthy(counts.b[i])end
end)
T.test("Unknown species and empty stable IDs reject",function()
	T.falsy(pcall(C.select,"unknown","hero"));T.falsy(pcall(C.hash,""))
end)
T.test("Willow V2 geometry budget and taller baseline are explicit",function()
	T.equal(c.triangles,5783);T.truthy(c.triangles<c.triangleBudget);T.near(c.baseHeight/23.848,1.3,.001)
	T.truthy(c.foliageDensity<1);T.equal(c.bones,8)
end)
T.test("Leaf palette darkens 15–20 percent by luminance and reduces yellow",function()
	for _,p in ipairs(c.foliagePalette)do local y=.2126*p[1]+.7152*p[2]+.0722*p[3];T.truthy(y>=.80 and y<=.85);T.truthy(p[1]<p[2] and p[1]<p[3])end
end)
T.test("V2 zero wind and Reduce Motion are exactly identity",function()
	for _,q in ipairs({"full","reduced","minimal"})do
		local x,z=W.sample(c.wind,1794888000,1,2,1,0,0,q,false);T.equal(x,0);T.equal(z,0)
		x,z=W.sample(c.wind,1794888000,1,2,1,70,20,q,true);T.equal(x,0);T.equal(z,0)
	end
end)
T.test("Long branches react more, phases differ, quality remains legible",function()
	local short=W.sample(c.wind,7,1,2,.7,2,0,"full",false);local long=W.sample(c.wind,7,1,2,1.2,2,0,"full",false)
	T.truthy(short>0 and long>short)
	local minimal=W.sample(c.wind,7,1,2,1.2,2,0,"minimal",false);T.truthy(minimal>0 and minimal<long)
	T.truthy(math.abs(long-W.sample(c.wind,7,3,2,1.2,2,0,"full",false))>.0001)
end)
T.test("Storms stay bounded and follow wind direction",function()
	for i=0,300 do local x,z=W.sample(c.wind,i*.13,1,2,1.3,300,400,"full",false);T.truthy(x>=0 and z>=0 and math.sqrt(x*x+z*z)<=.156);T.near(x*4,z*3,1e-8)end
end)
T.test("Wind smoothing removes step changes without frame-rate drift",function()
	local a=0;for _=1,30 do a=W.smooth(a,20,1/30,1.1)end
	local b=0;for _=1,60 do b=W.smooth(b,20,1/60,1.1)end
	T.near(a,b,1e-8);T.truthy(a>0 and a<20);T.truthy(W.smooth(0,20,1/60,1.1)<.31)
end)
T.test("Real epoch response is continuous and invalid inputs remain finite",function()
	for i=1,100 do local a=W.sample(c.wind,1794888000+i,1,2,1,20,0,"full",false);local b=W.sample(c.wind,1794888000+i+.001,1,2,1,20,0,"full",false);T.truthy(math.abs(a-b)<.0002)end
	for _,x in ipairs({0/0,math.huge,-math.huge})do local a,b=W.sample(c.wind,x,1,2,1,x,x,"full",false);T.equal(a,0);T.equal(b,0)end
end)
T.test("Willow trunk collider clears all thirteen stations, waypoints, building and main path",function()
	local Config=require("../src/shared/Config");local Island=require("../src/shared/PersonalIsland")
	local d=c.collider;local s=c.scaleMax;local minX=47+(d.x-d.width/2)*s;local maxX=47+(d.x+d.width/2)*s
	local minZ=-29-d.depth/2*s;local maxZ=-29+d.depth/2*s
	T.truthy(minX>Island.buildable.maxX)
	local function dist(x,z)return math.sqrt(math.max(minX-x,0,x-maxX)^2+math.max(minZ-z,0,z-maxZ)^2)end
	for _,id in ipairs(Config.stationOrder)do local v=Config.stations[id];T.truthy(dist(v.offset[1],v.offset[3])>8,id);for _,p in pairs(v.waypoints)do T.truthy(dist(p[1],p[3])>3,id)end end
	T.truthy(dist(0,20)>6 and dist(0,-2)>6)
end)
T.finish()
