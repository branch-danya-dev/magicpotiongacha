--!nonstrict
-- Bounded startup-only sculpting. Never clears or overwrites pre-existing terrain.
local Field=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.IslandTerrain)
local FarmGround=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.FarmGround)
local Landscape={}
function Landscape.attach(world)
	assert(not world.root:GetAttribute("IslandSurfaceVersion"),"Island already built")
	local terrain=workspace.Terrain; local r=Field.resolution
	local started=os.clock(); local visited,written,kept=0,0,0
	for _,b in ipairs(Field.tiles()) do
		local cells=(b.max[1]-b.min[1])*(b.max[2]-b.min[2])*(b.max[3]-b.min[3])/r^3
		assert(cells<=Field.maxWriteCells,"Island write exceeds budget")
		visited+=cells; assert(visited<=Field.maxTotalCells,"Island volume exceeds budget")
		local region=Region3.new(Vector3.new(table.unpack(b.min)),Vector3.new(table.unpack(b.max)))
		local materials,occupancy=terrain:ReadVoxels(region,r)
		for ix=1,#materials do for iz=1,#materials[ix][1] do
			local x,z=b.min[1]+(ix-.5)*r,b.min[3]+(iz-.5)*r
			local h,surface=-100,"Sand"
			if not b.waterOnly then h,surface=FarmGround.column(x,z) end
			for iy=1,#materials[ix] do
				if occupancy[ix][iy][iz]==0 then
					local material,fill=Field.cell(h,surface,b.min[2]+(iy-.5)*r)
					if fill>0 then materials[ix][iy][iz]=Enum.Material[material]; occupancy[ix][iy][iz]=fill; written+=1 end
				else kept+=1 end
			end
		end end
		terrain:WriteVoxels(region,r,materials,occupancy)
		game:GetService("RunService").Heartbeat:Wait()
	end
	terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(141,166,107))
	terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(135,137,129))
	terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(190,177,143))
	terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(163,150,116))
	terrain.WaterColor=Color3.fromRGB(96,149,156); terrain.WaterTransparency=.35; terrain.WaterReflectance=.12
	-- Retain its collision/friction contract; Terrain now supplies the visible skin.
	world.root.ForestFloor.Transparency=1
	world.root:SetAttribute("IslandSurfaceVersion",Field.version)
	world.root:SetAttribute("IslandVoxelVisits",visited)
	if game:GetService("RunService"):IsStudio() then
		print(string.format("M7_19A_TERRAIN cells=%d written=%d preserved=%d startupSeconds=%.3f plots=8 decorated=1",visited,written,kept,os.clock()-started))
	end
end
return Landscape
