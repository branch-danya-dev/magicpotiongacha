--!nonstrict
local T=require("./Test")
local P=require("../qa/landscape/Plan")
local I=require("../src/shared/PersonalIsland")
local C=require("../src/shared/Config")
local G=require("../src/shared/NatureGeometry")
local L=require("../qa/romantic-island/Layout")
local Policy=require("../qa/vegetation/TreeWindPolicy")
local Allocation=require("../qa/landscape/MeshAllocation")
local function allocator(options)
	options=options or {};local bytes,peak,created,destroyed=0,0,0,0
	local function reserve(cost)
		if bytes+cost>1000 then return nil end
		bytes+=cost;peak=math.max(bytes,peak);created+=1
		return {cost=cost,vertices={},dead=false}
	end
	local api={create=function()if options.createFail then return nil end;return reserve(150)end,
		compact=function(m)
			if options.yieldCompact then coroutine.yield("compacting")end
			if options.compactFail then error("compaction failed")end
			if options.compactNil then return nil end
			local f=reserve(1);f.vertices=table.clone(m.vertices);return f
		end,
		destroy=function(m)T.falsy(m.dead);m.dead=true;bytes-=m.cost;destroyed+=1 end,
		wait=function()coroutine.yield("queued")end}
	return Allocation.new(api),api,function()return bytes,peak,created,destroyed end
end
T.test("Pilot whole crowns clear all 13 stations, services, routes, construction and sightlines",function()
	local a=P.audit(C,I);T.truthy(a.ok,table.concat(a.errors,"; "));T.equal(a.stations,13);T.truthy(a.minStationCrownGap>=4)
end)
T.test("Regression detector rejects book-route and cauldron overlap",function()
	for _,point in ipairs({{0,10},{20,12},{0,-2},{0,-65}})do
		local t=table.clone(P.trees[1]);t.x=point[1];t.z=point[2];T.falsy(P.audit(C,I,{t}).ok)
	end
end)
T.test("Only pilot region and old willow proxy are replaced; retained layout is immutable",function()
	local before=#L.trees;local kept=P.keepTrees(L.trees)
	T.truthy(#kept<before);T.equal(#L.trees,before)
	for _,t in ipairs(L.trees)do
		local found=false;for _,v in ipairs(kept)do if v==t then found=true end end
		T.equal(found,not t.hero and not P.inPilot(t.x,t.z))
	end
end)
T.test("Three ordinary types and one magic type, three rigged instances with stable IDs",function()
	local kinds={};local rigged,magic=0,0
	for _,t in ipairs(P.trees)do if t.magic then magic+=1 else kinds[t.template or t.source]=true end;if t.source then rigged+=1 end end
	local n=0;for _ in pairs(kinds)do n+=1 end;T.equal(n,3);T.equal(magic,1);T.equal(rigged,3)
	local duplicates={P.trees[1],P.trees[1]};T.falsy(P.audit(C,I,duplicates).ok)
end)
T.test("Authored undergrowth roots remain on island and outside construction",function()
	T.equal(#P.cover,22)
	for _,v in ipairs(P.cover)do
		T.truthy(G[v[1]],v[1]);T.truthy(I.surfaceContains(v[2],v[3],1))
		T.truthy(P.terrainMargin(v[2],v[3])>=2.1,v[1].." unsupported terrain edge")
		local r=G[v[1]].radius*v[4]
		T.truthy(v[2]+r<I.buildable.minX or v[3]-r>I.buildable.maxZ,v[1].." construction overhang")
	end
end)
T.test("Grove wind uses nearest selection with strict quality and far caps",function()
	for quality,maxCount in pairs({full=3,reduced=2,minimal=1})do
		local list={};for n=1,6 do table.insert(list,{id=tostring(n),species="same",distance=n,budget=P.budgets[quality]})end
		T.equal(#Policy.select(list,quality),maxCount)
		T.equal(Policy.rate(P.budgets[quality],P.budgets[quality].distance+1),0)
	end
end)
T.test("Reduced and Minimal keep primary silhouette and fade optional leaf layer",function()
	for q in pairs(P.budgets)do for _,role in ipairs({"Bark","Leaf","Magic"})do T.equal(P.detailAlpha(role,q,999),0)end end
	T.equal(P.detailAlpha("LeafSecondary","reduced",70),0);T.near(P.detailAlpha("LeafSecondary","reduced",80),.5)
	T.equal(P.detailAlpha("LeafSecondary","minimal",1),1);T.equal(P.detailAlpha("LeafSecondary","full",10),0)
end)
T.test("Actual mixed grove is capped to 3/2/1 animated trees",function()
	for q,cap in pairs({full=3,reduced=2,minimal=1})do
		local items={};for _,t in ipairs(P.trees)do if t.source then table.insert(items,{id=t.id,species=t.source,distance=10,budget=P.windBudgets(t.source)[q]})end end
		T.equal(#Policy.select(items,q),cap)
	end
end)
T.test("Six retained expandable R4 meshes reproduce the seventh-allocation cliff failure",function()
	local _,api=allocator();for _=1,6 do T.truthy(api.create())end;T.equal(api.create(),nil)
end)
T.test("R4 plus cliff plus 17 tree meshes retain only compact resources",function()
	local a,api,stats=allocator();local retained={}
	for i=1,24 do
		local fixed=a.build(function(m)m.vertices={i,2,3}end);T.equal(fixed.vertices[1],i);table.insert(retained,fixed)
	end
	local bytes,peak,created,destroyed=stats();T.equal(bytes,24);T.truthy(peak<=174);T.equal(created,48);T.equal(destroyed,24)
	T.equal(a.stats().activeScratch,0);T.equal(a.stats().peakScratch,1)
	for _,m in ipairs(retained)do api.destroy(m)end;T.equal(stats(),0)
end)
T.test("Fill failure frees scratch and allows the next grove resource",function()
	local a,api,stats=allocator();T.falsy(pcall(a.build,function()error("bad geometry")end));T.equal(stats(),0);T.falsy(a.stats().busy)
	local f=a.build(function(m)m.vertices={1}end);T.equal(a.stats().completed,1);api.destroy(f)
end)
T.test("Create and compaction failures release the queue without leaking",function()
	for _,key in ipairs({"createFail","compactFail","compactNil"})do
		local options={[key]=true};local a,api,stats=allocator(options)
		T.falsy(pcall(a.build,function()end));T.equal(stats(),0);T.equal(a.stats().activeScratch,0);T.falsy(a.stats().busy)
		options[key]=false;local f=a.build(function()end);api.destroy(f);T.equal(stats(),0)
	end
end)
T.test("Concurrent environment and grove tasks serialize yielding compaction",function()
	local a,api,stats=allocator({yieldCompact=true});local first,second
	local c1=coroutine.create(function()first=a.build(function(m)m.vertices={1}end)end)
	local c2=coroutine.create(function()second=a.build(function(m)m.vertices={2}end)end)
	local ok,state=coroutine.resume(c1);T.truthy(ok);T.equal(state,"compacting")
	ok,state=coroutine.resume(c2);T.truthy(ok);T.equal(state,"queued");T.equal(a.stats().activeScratch,1)
	T.truthy(coroutine.resume(c1));T.truthy(first);T.equal(a.stats().activeScratch,0)
	ok,state=coroutine.resume(c2);T.truthy(ok);T.equal(state,"compacting");T.truthy(coroutine.resume(c2))
	T.equal(second.vertices[1],2);T.equal(a.stats().peakScratch,1);api.destroy(first);api.destroy(second);T.equal(stats(),0)
end)
T.finish()
