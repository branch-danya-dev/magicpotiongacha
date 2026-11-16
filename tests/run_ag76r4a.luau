--!nonstrict
local T=require("./Test")
local P=require("../qa/dynamic-grass/Plan")
local W=require("../qa/dynamic-grass/Wind")
local C=require("../src/shared/Config")
local I=require("../src/shared/PersonalIsland")
local G=require("../src/shared/NatureGeometry")
local L=require("../qa/romantic-island/Layout")
local M=require("../src/shared/MeadowPlan")
local Motion=require("../src/shared/MeadowMotion")
local plants=P.build(C,I,G,L)
T.test("R4A deterministic admitted planting stays bounded and contains all three zones",function()
	local other=P.build(C,I,G,L);local zones={};local kinds={}
	T.truthy(#plants>150);T.truthy(#plants<=320);T.equal(#plants,#other)
	for i,p in ipairs(plants) do T.equal(p.x,other[i].x);T.equal(p.z,other[i].z);zones[p.zone]=true;kinds[p.name]=true end
	T.truthy(zones.grove and zones.rim and zones.clearing)
	T.truthy(kinds.Grass_Wispy_Tall and kinds.Clover_2 and kinds.Fern_1)
end)
T.test("R4A preserves all 13 work footprints and 26 approaches with full plant extents",function()
	T.equal(#C.stationOrder,13)
	for _,p in ipairs(plants) do T.falsy(P.protected(p.x,p.z,p.radius,C));T.truthy(I.surfaceContains(p.x,p.z,p.radius+1)) end
end)
T.test("R4A never puts tall cover in future construction or six-stud corridor",function()
	for _,p in ipairs(plants) do
		T.falsy(P.path(p.x,p.z,p.radius))
		if P.buildable(p.x,p.z,p.radius,I) then T.truthy(p.height<=.48) end
	end
end)
T.test("R4A station, book and spawn terrain has no native grass; moss distribution is mixed",function()
	for _,s in pairs(C.stations) do T.equal(P.surface(s.offset[1],s.offset[3],C),"Ground") end
	T.equal(P.surface(0,-2,C),"Ground");T.equal(P.surface(0,20,C),"Ground")
	local materials={};for x=-50,50,4 do for z=-50,40,4 do materials[P.surface(x,z,C)]=true end end
	T.truthy(materials.Grass and materials.LeafyGrass and materials.Ground)
end)
T.test("R4A LOD tiers strictly reduce geometry while preserving low-quality cover",function()
	local n={0,0,0};for _,p in ipairs(plants) do n[p.detail]+=1 end
	T.truthy(n[1]>=20);T.truthy(n[2]>20);T.truthy(n[3]>20)
end)
T.test("R4A wind has bounded smooth periodic gusts and exact Reduce Motion zero",function()
	local last=W.sample({wind=.4},0,false);local low,high=99,0
	for i=1,2400 do local f=W.sample({wind=.4},i/100,false)
		T.truthy(math.abs(f.x-last.x)<.15);T.truthy(f.strength<1)
		low=math.min(low,f.x);high=math.max(high,f.x);last=f
	end
	T.truthy(high-low>8)
	for _,t in ipairs({0,3,6,12}) do local f=W.sample({wind=1},t,true);T.equal(f.x,0);T.equal(f.z,0);T.equal(f.strength,0) end
end)
T.test("R4A uses existing 64/32/0 motion caps including transitions and resets",function()
	T.equal(M.maxMoving.full,64);T.equal(M.maxMoving.reduced,32);T.equal(M.maxMoving.minimal,0)
	local e={};for i=1,#plants do e[i]={visible=true,weight=0} end
	for _,q in ipairs({"full","reduced","minimal","full"}) do
		for _=1,30 do T.truthy(Motion.step(e,M.maxMoving[q],.05)<=M.maxMoving[q]) end
	end
	T.equal(Motion.step(e,0,.05),0)
	for _,v in ipairs(e) do T.equal(v.weight,0) end
end)
T.finish()
