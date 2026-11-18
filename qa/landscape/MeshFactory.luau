--!nonstrict
-- Shared by R4, cliff and grove within this candidate only; no upload or owner.
local Asset=game:GetService("AssetService")
local Allocation=require(script.Parent.MeshAllocation)
return Allocation.new({
	create=function()return Asset:CreateEditableMesh()end,
	compact=function(scratch)
		local fixed=Asset:CreateEditableMeshAsync(Content.fromObject(scratch),{FixedSize=true})
		if not fixed then return nil end
		local ok,err=pcall(function()
			assert(fixed.FixedSize,"Expected fixed topology")
			assert(#fixed:GetVertices()==#scratch:GetVertices(),"Compaction changed vertices")
			assert(#fixed:GetFaces()==#scratch:GetFaces(),"Compaction changed faces")
			assert(#fixed:GetBones()==#scratch:GetBones(),"Compaction changed skeleton")
		end)
		if not ok then fixed:Destroy();error(err,0)end
		return fixed
	end,
	destroy=function(mesh)mesh:Destroy()end,
	wait=function()task.wait()end,
})
