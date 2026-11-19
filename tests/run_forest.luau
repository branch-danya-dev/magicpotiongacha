--!nonstrict
local T=require("./Test")
local F=require("../qa/forest/Layout")
local Base=require("../src/shared/PersonalIsland")
local I=F.island(Base)
local C=require("../src/shared/Config")
local G=require("../src/shared/NatureGeometry")
local P=F.apply(require("../qa/landscape/Plan"),C,I,G,require("../qa/romantic-island/Layout"))
local Policy=require("../qa/vegetation/TreeWindPolicy")
local O=require("../qa/forest/Occlusion")
local R=require("../qa/forest/Readiness")
T.test("Expanded candidate does not change production bounds, saved construction or anchors",function()
	T.equal(Base.surface.width,124);T.equal(Base.surface.depth,116)
	T.equal(I.surface.width,184);T.equal(I.surface.depth,172)
	T.equal(I.origin,Base.origin);T.equal(I.core,Base.core);T.equal(I.buildable,Base.buildable);T.equal(I.serviceOffsets,Base.serviceOffsets)
	for _,id in ipairs(C.stationOrder)do T.equal(I.offset(C,id),C.stations[id].offset)end
end)
T.test("Expanded traversal follows the same irregular rim as the cliff and terrain",function()
	for n=0,71 do
		local a=n/72*math.pi*2;local rim=1+.10*math.sin(a*5)+.035*math.cos(a*7)
		T.truthy(I.surfaceContains(math.cos(a)*F.rx*(rim-.08),-8+math.sin(a)*F.rz*(rim-.08),3))
		T.falsy(I.surfaceContains(math.cos(a)*F.rx*(rim+.04),-8+math.sin(a)*F.rz*(rim+.04),0))
	end
	T.truthy(I.surfaceContains(70,0,3));T.falsy(Base.surfaceContains(70,0,3))
	T.falsy(I.surfaceContains(0/0,1));T.falsy(I.surfaceContains(math.huge,1));T.falsy(I.surfaceContains(0,0,-1))
end)
T.test("Whole woodland has multiple depths in every direction and keeps the central clearing",function()
	T.truthy(#P.trees>=45 and #P.trees<=52)
	local banks={west=0,east=0,north=0,south=0};local outer=0
	for _,t in ipairs(P.trees)do
		if t.x < -45 then banks.west+=1 elseif t.x>45 then banks.east+=1 elseif t.z < -50 then banks.north+=1 else banks.south+=1 end
		if math.abs(t.x)>65 or t.z < -70 or t.z>55 then outer+=1 end
	end
	for name,n in pairs(banks)do T.truthy(n>=6,name)end;T.truthy(outer>=14)
	local a=P.audit(C,I);T.truthy(a.ok,table.concat(a.errors,"; "));T.equal(a.stations,13)
end)
T.test("New forest paths and supported roots stay clear of trunks and low plants",function()
	for _,t in ipairs(P.trees)do T.falsy(F.path(t.x,t.z,2),t.id);T.truthy(F.margin(t.x,t.z)>=2.1,t.id)end
	for i,a in ipairs(P.trees)do for j=i+1,#P.trees do local b=P.trees[j]
		T.truthy((a.x-b.x)^2+(a.z-b.z)^2>=25,a.id.." / "..b.id)
	end end
	for _,list in ipairs({P.cover,P.stones})do for _,v in ipairs(list)do T.falsy(F.path(v[2],v[3],G[v[1]].radius*v[4]))end end
	for _,route in ipairs(F.routes)do for _,p in ipairs(route)do T.truthy(I.surfaceContains(p[1],p[2],3))end end
end)
T.test("Dense understory retains structural plants in Minimal within a bounded geometry cost",function()
	local a=P.auditDressing(C,I,G);T.truthy(a.ok,table.concat(a.errors,"; "))
	T.truthy(#P.cover>=150 and #P.cover<=200);T.truthy(a.parts<=300);T.truthy(a.triangles<=70000);T.truthy(a.minimalParts>=140)
end)
T.test("More planted trees do not bypass the 8/4/1 shared wind caps",function()
	for q,cap in pairs({full=8,reduced=4,minimal=1})do
		local entries={};for _,t in ipairs(P.trees)do if t.source then table.insert(entries,{id=t.id,species=t.source,distance=10,budget=P.windBudgets(t.source)[q]})end end
		T.equal(#Policy.select(entries,q),cap)
	end
end)
T.test("Forest camera occlusion fades only boxes on the camera-to-player segment",function()
	T.equal(O.alpha({0,0,0},{0,0,-12},{4,4,4}),.96)
	T.equal(O.alpha({0,0,12},{0,0,-12},{4,4,4}),.96)
	T.equal(O.alpha({12,0,12},{12,0,-12},{4,4,4}),0)
	T.equal(O.alpha({0,0,12},{0,0,8},{4,4,4}),0)
	T.equal(O.alpha({0,8,0},{12,8,0},{4,4,4}),0)
end)
T.test("Forest waits for every root after a delayed client terrain replication",function()
	local now,probes=0,0
	local hits=R.wait({{id="a",source=true},{id="b",source=true},{id="static"}},function(t)
		probes+=1;return now>=(t.id=="a" and .2 or .5) and t.id or nil
	end,function(dt)now+=dt end,function()return now end,function()return true end,2)
	T.equal(hits.a,"a");T.equal(hits.b,"b");T.truthy(probes>2);T.truthy(now>=.5)
end)
T.test("Missing terrain stops within the startup deadline instead of placing floating trees",function()
	local now=0;local ok,err=pcall(function()
		R.wait({{id="missing",source=true}},function()return nil end,function(dt)now+=dt end,function()return now end,function()return true end,.3)
	end)
	T.falsy(ok);T.truthy(tostring(err):find("Forest terrain unavailable"));T.truthy(now<=.4)
end)
T.test("Forest startup cancels cleanly when the preview is removed",function()
	local alive=true;local ok,err=pcall(function()
		R.wait({{id="a",source=true}},function()return nil end,function()alive=false end,function()return 0 end,function()return alive end,20)
	end)
	T.falsy(ok);T.truthy(tostring(err):find("Forest removed"))
end)
T.finish()
