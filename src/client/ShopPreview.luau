--!nonstrict
-- Local primitives only: illustrative greybox, never an inventory or reward object.
local Preview={}
function Preview.create(parent,style)
	local view=Instance.new("ViewportFrame"); view.Size=UDim2.new(1,-8,0,120); view.BackgroundColor3=Color3.fromRGB(24,31,43)
	view.Ambient=Color3.fromRGB(200,220,235); view.LightColor=Color3.new(1,1,1); view.Parent=parent
	local camera=Instance.new("Camera"); camera.CFrame=CFrame.lookAt(Vector3.new(7,5,8),Vector3.new(0,0.6,0)); camera.Parent=view; view.CurrentCamera=camera
	local function block(size,position,color,shape)
		local p=Instance.new("Part"); p.Size=size; p.Position=position; p.Color=color; p.Anchored=true; p.CanCollide=false
		p.Material=Enum.Material.Neon; p.Shape=shape or Enum.PartType.Block; p.Parent=view; return p
	end
	local cyan=Color3.fromRGB(116,235,246); local violet=Color3.fromRGB(163,116,243)
	if style=="ghost" then
		block(Vector3.new(3,1.2,1.2),Vector3.new(0,0.6,0),cyan,Enum.PartType.Ball)
		block(Vector3.new(1.4,1.3,1.1),Vector3.new(1.6,1.2,0),cyan,Enum.PartType.Ball)
		for _,z in ipairs({-0.4,0.4}) do block(Vector3.new(0.35,0.8,0.3),Vector3.new(1.4,2,z),violet) end
		for _,x in ipairs({-1,1}) do for _,z in ipairs({-0.4,0.4}) do block(Vector3.new(0.35,0.8,0.35),Vector3.new(x,-0.2,z),cyan) end end
		block(Vector3.new(1.5,0.5,0.5),Vector3.new(-2,1,0),violet)
	elseif style=="spectral" then
		block(Vector3.new(3.2,2.4,3.2),Vector3.new(0,0.3,0),violet,Enum.PartType.Ball)
		block(Vector3.new(2.8,0.25,2.8),Vector3.new(0,1.3,0),cyan)
	else
		block(Vector3.new(5,0.3,3),Vector3.new(0,0,0),violet)
		for _,x in ipairs({-2,2}) do block(Vector3.new(0.35,2.6,0.35),Vector3.new(x,1.2,0),cyan) end
		block(Vector3.new(4.5,0.3,0.3),Vector3.new(0,2.6,0),cyan)
	end
	return view
end
return Preview
