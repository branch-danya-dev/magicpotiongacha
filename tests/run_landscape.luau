--!nonstrict
local T=require("./Test")
local P=require("../qa/landscape/Plan")
local I=require("../src/shared/PersonalIsland")
local C=require("../src/shared/Config")
local G=require("../src/shared/NatureGeometry")
local L=require("../qa/romantic-island/Layout")
local Policy=require("../qa/vegetation/TreeWindPolicy")
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
T.finish()
