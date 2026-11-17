--!nonstrict
-- Isolated QA transport for the explicitly authorized group-owned FBX import.
-- Uses the exported Studio template, never uploads or loads scripts from Roblox.
local M={}
function M.load()
	assert(game:GetService("RunService"):IsStudio(),"Willow QA only")
	local template=game:GetService("ReplicatedStorage"):WaitForChild("WillowNativeTemplate")
	local self={meshes={},images={},templates={},trees={}}
	function self.create(parent,at,index)
		local tree=template:Clone();tree.Name="Willow_"..index
		for _,v in ipairs(tree:GetDescendants())do
			assert(not v:IsA("LuaSourceContainer"),"Unexpected script in imported template")
			if v:IsA("BasePart")then
				v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
				if v:IsA("MeshPart")then
					local foliage=v.Name=="Willow_Foliage"
					v.DoubleSided=foliage
					assert(v:FindFirstChildOfClass("SurfaceAppearance"),"Missing prepared material")
					v.Color=foliage and Color3.new(1,1,1) or Color3.fromRGB(123,104,82)
				else v.Transparency=1 end
			end
		end
		tree:PivotTo(at)
		local collider=Instance.new("Part");collider.Name="TrunkCollider";collider.Size=Vector3.new(3.8,9,3.8)
		collider.CFrame=at*CFrame.new(-3,4.5,0);collider.Transparency=1;collider.Anchored=true
		collider.CanCollide=true;collider.CanQuery=true;collider.CanTouch=false;collider.Parent=tree
		tree.Parent=parent;table.insert(self.trees,tree);return tree
	end
	function self.destroy()for _,v in ipairs(self.trees)do v:Destroy()end;table.clear(self.trees)end
	return self
end
return M
