// Generated-only adaptations: the source R4/cliff/library remain byte-identical.
import assert from 'node:assert/strict';
const change=(s,a,b)=>{assert.equal(s.split(a).length,2,`Memory adapter drift: ${a}`);return s.replace(a,b);};
const factory='local MeshFactory=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.MeshFactory)\n';
export function compactCliff(source){
 let s=change(source,'local Cliff={}',factory+'local Cliff={}');
 s=change(s,'local editable=assert(asset:CreateEditableMesh(),"Local editable mesh memory unavailable")','local vertexCount,faceCount=0,0\n\tlocal editable=MeshFactory.build(function(editable)');
 s=change(s,'local part=asset:CreateMeshPartAsync','vertexCount=#points;faceCount=#faces\n\tend)\n\tlocal part=asset:CreateMeshPartAsync');
 // The recipe arrays now live only for the duration of scratch construction.
 s=s.replaceAll('"OriginalCliffVertices",#points','"OriginalCliffVertices",vertexCount').replaceAll('"OriginalCliffTriangles",#faces','"OriginalCliffTriangles",faceCount')
 .replaceAll('"WIZARD_CLIFF_READY",#points,#faces','"WIZARD_CLIFF_READY",vertexCount,faceCount').replaceAll('vertices=#points,triangles=#faces','vertices=vertexCount,triangles=faceCount');
 return s;
}
export function compactDepth(source){
 let s=change(source,'local M={}',factory+'local M={}');
 s=change(s,'local mesh=pool.get("mesh"..i,function()return Asset:CreateEditableMesh()end)','local mesh=pool.get("mesh"..i,function()return MeshFactory.build(function(mesh)');
 s=change(s,'local p=Asset:CreateMeshPartAsync','end)end)\n   local p=Asset:CreateMeshPartAsync');
 return s;
}
export function compactTrees(source){
 let s=change(source,'local M={}',factory+'local M={}');
 s=change(s,'local mesh=assert(Asset:CreateEditableMesh(),"Vegetation mesh budget exhausted");table.insert(self.meshes,mesh)',
  'local used\n\t\t\tlocal mesh=MeshFactory.build(function(mesh)');
 s=change(s,'local used={[1]=true}','used={[1]=true}');
 s=change(s,'local part=Asset:CreateMeshPartAsync','end)\n\t\t\ttable.insert(self.meshes,mesh)\n\t\t\tlocal part=Asset:CreateMeshPartAsync');
 return s;
}
