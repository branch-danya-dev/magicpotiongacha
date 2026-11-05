--!nonstrict
-- Hide presentation slabs; keep gameplay anchors and floor collision contracts.
local Landscape={}
function Landscape.attach(world)
	for _,plot in ipairs(world.plots) do
		local floor=plot.model.Floor
		if floor.CustomPhysicalProperties==nil then floor.CustomPhysicalProperties=PhysicalProperties.new(floor.Material) end
		floor.Transparency=1
		-- RespawnLocation still refers to this exact instance/position. Its visible
		-- pedestal is removed so an invisible one-stud step cannot snag the player.
		plot.spawn.Transparency=1; plot.spawn.CanCollide=false
		for _,child in ipairs(plot.spawn:GetChildren()) do if child:IsA("Decal") then child.Transparency=1 end end
	end
	world.root.Bazaar.Transparency=1
	world.root:SetAttribute("FarmGroundVersion",1)
end
return Landscape
