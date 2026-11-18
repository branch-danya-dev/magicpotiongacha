--!nonstrict
-- Read the actual authored recipe for the build receipt; no duplicated counts.
local P=require("../qa/landscape/Plan")
local G=require("../src/shared/NatureGeometry")
local a=P.auditDressing(require("../src/shared/Config"),require("../src/shared/PersonalIsland"),G)
assert(a.ok,table.concat(a.errors,"; "))
local parts,triangles,minimal=a.parts,a.triangles,a.minimalParts
for _,t in ipairs(P.trees)do if t.template then
	parts+=#G[t.template].parts;minimal+=#G[t.template].parts;triangles+=G[t.template].triangles
end end
print(string.format('{"coverModels":%d,"stoneModels":%d,"staticParts":%d,"staticTriangles":%d,"minimalStaticParts":%d}',
	#P.cover,#P.stones,parts,triangles,minimal))
