--!nonstrict
-- One bounded local pool, driven by the existing context owner/server snapshot.
local Shared=game.ReplicatedStorage.PotionTycoon.Shared
local Ground=require(Shared.FarmGround)
local View={}
function View.new(root,player)
	local folder=Instance.new("Folder"); folder.Name="FarmAffordance"; folder.Parent=workspace
	local border,glow={},{}
	local function part(name,color)
		local p=Instance.new("Part"); p.Name=name; p.Anchored=true
		p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=false,false,false,false
		p.Color=color; p.Material=Enum.Material.Neon; p.Transparency=1; p.Parent=folder
		return p
	end
	for i=1,Ground.borderParts do border[i]=part("Boundary_"..i,Color3.fromRGB(210,187,97)) end
	for i=1,Ground.glowParts do
		local p=part("BuildGlow_"..i,Color3.fromRGB(146,204,118)); p.Shape=Enum.PartType.Cylinder
		local width=5.4-(i-1)*1.2; p.Size=Vector3.new(.035,width,width); glow[i]=p
	end
	local filter=RaycastParams.new(); filter.FilterType=Enum.RaycastFilterType.Include; filter.FilterDescendantsInstances={workspace.Terrain}
	local function ground(x,z)
		local hit=workspace:Raycast(Vector3.new(x,60,z),Vector3.new(0,-110,0),filter)
		return hit and hit.Position+Vector3.new(0,.055,0) or nil
	end
	local plotIndex,glowAnchor=nil,nil
	local function hide(parts) for _,p in ipairs(parts) do p.Transparency=1 end end
	local self={}
	function self.update(current,state,position)
		local enabled=root:GetAttribute("EnvironmentArtEnabled")==true and root:GetAttribute("FarmGroundVersion")==1
		local owned
		if enabled then for _,plot in ipairs(root:GetChildren()) do
			if plot:GetAttribute("OwnerUserId")==player.UserId then owned=plot; break end
		end end
		local index=owned and owned:GetAttribute("PlotIndex")
		if index~=plotIndex then
			plotIndex=index; hide(border)
			if index then
				local points=Ground.border(index)
				for i,p in ipairs(points) do
					local q=points[i%#points+1]; local a,b=ground(p[1],p[2]),ground(q[1],q[2])
					local line=border[i]
					if a and b then line.Size=Vector3.new(Ground.borderWidth,.025,(b-a).Magnitude)
						line.CFrame=CFrame.lookAt((a+b)/2,b); line:SetAttribute("Grounded",true)
					else line:SetAttribute("Grounded",false) end
				end
			end
		end
		local near=owned and position and (owned.Floor.Position-position).Magnitude<=Ground.borderDistance
		for _,line in ipairs(border) do line.Transparency=near and line:GetAttribute("Grounded") and .48 or 1 end
		local show=enabled and Ground.canGlow(state,current,player.UserId)
		local anchor=show and current.anchor or nil
		if anchor~=glowAnchor then
			glowAnchor=anchor; hide(glow)
			if anchor then
				local p=ground(anchor.Position.X,anchor.Position.Z)
				if p then for i,disc in ipairs(glow) do
					disc.CFrame=CFrame.new(p+Vector3.new(0,i*.012,0))*CFrame.Angles(0,0,math.pi/2)
				end else glowAnchor=nil end
			end
		end
		for i,disc in ipairs(glow) do disc.Transparency=glowAnchor and (.97-i*.025) or 1 end
		folder:SetAttribute("GlowingStation",glowAnchor and current.station or nil)
	end
	function self.stop() folder:Destroy() end
	return self
end
return View
