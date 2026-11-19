--!nonstrict
local F=require("../qa/forest/Layout")
local I=F.island(require("../src/shared/PersonalIsland"))
local C=require("../src/shared/Config")
local G=require("../src/shared/NatureGeometry")
local P=F.apply(require("../qa/landscape/Plan"),C,I,G,require("../qa/romantic-island/Layout"))
local a=P.audit(C,I);assert(a.ok,table.concat(a.errors,"; "))
local d=P.auditDressing(C,I,G);assert(d.ok,table.concat(d.errors,"; "))
local rigged,static,parts,triangles=0,0,d.parts,d.triangles
for _,t in ipairs(P.trees)do
	assert(not F.path(t.x,t.z,2),t.id..": route trunk")
	if t.source then rigged+=1 else static+=1;parts+=#G[t.template].parts;triangles+=G[t.template].triangles end
end
print(string.format('{"trees":%d,"riggedTrees":%d,"staticTrees":%d,"coverModels":%d,"stoneModels":%d,"staticParts":%d,"staticTriangles":%d,"minimalStaticParts":%d}',#P.trees,rigged,static,#P.cover,#P.stones,parts,triangles,d.minimalParts+static*2))
