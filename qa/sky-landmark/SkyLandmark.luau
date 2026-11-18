--!nonstrict
-- One world-anchored composition and a fixed cloud ring, driven by EnvironmentView.
local Asset=game:GetService("AssetService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.SkyLandmarkConfig)
local Model=require(Shared.SkyLandmarkModel)
local Resources=require(Shared.SkyLandmarkResources)
local Data=require(Shared.SkyLandmarkPixels)
local M={}
function M.create(parent)
	assert(game:GetService("RunService"):IsStudio(),"Sky landmark is a local art candidate")
	local self={ready=false,destroyed=false,error=nil,updates=0,pixelWrites=0,lastMs=0,phase=0,quality="reduced",reduceMotion=false}
	local pool=Resources.new();local folder,anchor,gui,cleanupConnection;local labels={};local banks={};local elapsed=0;local current
	local oceanEnabled=true
	local function cloudEdge(label)
		local g=Instance.new("UIGradient");g.Name="SoftOceanEdges"
		g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.13,.28),NumberSequenceKeypoint.new(.32,0),NumberSequenceKeypoint.new(.68,0),NumberSequenceKeypoint.new(.87,.28),NumberSequenceKeypoint.new(1,1)})
		g.Parent=label
	end
	local function place(label,layer,dx,dy)
		local scale=layer.scale or 1
		label.Size=UDim2.fromScale(layer.size[1]*scale/Config.canvas[1],layer.size[2]*scale/Config.canvas[2])
		label.Position=UDim2.fromScale(.5+(layer.offset[1]+(dx or 0))/Config.canvas[1],.5-(layer.offset[2]+(dy or 0))/Config.canvas[2])
	end
	local function dispose()
		if self.destroyed then return end;self.destroyed=true;self.ready=false
		if cleanupConnection then cleanupConnection:Disconnect();cleanupConnection=nil end
		if folder then folder:Destroy();folder=nil end;table.clear(labels);table.clear(banks);pool.destroy()
	end
	self.destroy=dispose
	local ok,err=pcall(function()
		folder=Instance.new("Folder");folder.Name="SkyLandmark";folder.Parent=parent
		anchor=Instance.new("Part");anchor.Name="WorldAnchor";anchor.Size=Vector3.one;anchor.Transparency=1
		anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false
		anchor.Position=Vector3.new(table.unpack(require(Shared.PersonalIsland).origin))+Vector3.new(table.unpack(Config.offset));anchor.Parent=folder
		gui=Instance.new("BillboardGui");gui.Name="DistantComposition";gui.Adornee=anchor;gui.AlwaysOnTop=false
		gui.LightInfluence=0;gui.Size=UDim2.fromScale(Config.canvas[1],Config.canvas[2]);gui.MaxDistance=Config.maxDistance
		gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Active=false;gui.ClipsDescendants=false;gui.Parent=anchor
		local images={}
		for _,name in ipairs({"Tree","Cloud","Glow","Minimal"})do
			local d=Data[name]
			local img=pool.get(name,function()return Asset:CreateEditableImage({Size=Vector2.new(d.size,d.size)})end)
			local pixels=game:GetService("EncodingService"):Base64Decode(buffer.fromstring(d.rgba))
			assert(buffer.len(pixels)==d.size*d.size*4,"Landmark pixel length mismatch")
			img:WritePixelsBuffer(Vector2.zero,img.Size,pixels);self.pixelWrites+=1;images[name]=img
		end
		local function crop(label,name)
			local c=Data[name].crop;label.ImageRectOffset=Vector2.new(c.x,c.y);label.ImageRectSize=Vector2.new(c.width,c.height)
			label.ImageContent=Content.fromObject(images[name])
		end
		for _,entry in ipairs({{"TreeGlow","Glow",1},{"WorldTree","Tree",2},{"AtmosphericHaze","Cloud",3},{"CloudOcclusion","Cloud",4},{"CloudDrift","Cloud",5},{"MinimalComposition","Minimal",2}})do
			local label=Instance.new("ImageLabel");label.Name=entry[1];label.BackgroundTransparency=1;label.ImageTransparency=1;label.Active=false
			label.Size=UDim2.fromScale(1,1);label.AnchorPoint=Vector2.new(.5,.5);label.Position=UDim2.fromScale(.5,.5)
			crop(label,entry[2]);label.ZIndex=entry[3];label.Parent=gui;labels[entry[1]]=label
		end
		place(labels.WorldTree,Config.tree);place(labels.MinimalComposition,Config.tree);place(labels.TreeGlow,Config.glow)
		place(labels.CloudOcclusion,Config.cloud);place(labels.CloudDrift,Config.cloud);place(labels.AtmosphericHaze,Config.haze)
		cloudEdge(labels.CloudOcclusion);cloudEdge(labels.CloudDrift)
		for _,entry in ipairs({{"CrownTop",90},{"CrownLeft",0},{"CrownRight",180}})do
			local l=Instance.new("ImageLabel");l.Name=entry[1];l.BackgroundTransparency=1;l.ImageTransparency=1;l.Active=false
			l.AnchorPoint=Vector2.new(.5,.5);l.ZIndex=3;crop(l,"Tree");place(l,Config.tree);l.Parent=gui;labels[entry[1]]=l
			local g=Instance.new("UIGradient");g.Name="CrownEdgeMask";g.Rotation=entry[2]
			g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.14,.24),NumberSequenceKeypoint.new(.32,.86),NumberSequenceKeypoint.new(.48,1),NumberSequenceKeypoint.new(1,1)})
			g.Parent=l
		end
		labels.AtmosphericHaze.ZIndex=4;labels.CloudOcclusion.ZIndex=5;labels.CloudDrift.ZIndex=6
		local origin=Vector3.new(table.unpack(require(Shared.PersonalIsland).origin))
		for i,b in ipairs(Model.ocean(Config))do
			local a=Instance.new("Part");a.Name="CloudBank"..i;a.Size=Vector3.one;a.Transparency=1;a.Anchored=true
			a.CanCollide=false;a.CanTouch=false;a.CanQuery=false;a.CastShadow=false;a.Position=origin+Vector3.new(b.x,b.y,b.z);a.Parent=folder
			local g=Instance.new("BillboardGui");g.Name="CloudOcean";g.Adornee=a;g.AlwaysOnTop=false;g.LightInfluence=0
			g.Size=UDim2.fromScale(b.width*Config.cloud.scale,b.height*Config.cloud.scale);g.MaxDistance=Config.maxDistance;g.Active=false;g.Parent=a
			local l=Instance.new("ImageLabel");l.Name="CloudMass";l.BackgroundTransparency=1;l.ImageTransparency=1
			l.Size=UDim2.fromScale(1,1);l.Active=false;crop(l,"Cloud");l.Parent=g;cloudEdge(l)
			table.insert(banks,{label=l,density=b.density})
		end
		self.ready=true;cleanupConnection=folder.Destroying:Connect(dispose)
	end)
	if not ok then self.error=tostring(err);dispose();warn("SKY_LANDMARK_BLOCKED",err)end
	function self.setOceanEnabled(enabled) oceanEnabled=enabled~=false end
	function self.update(sample,weights,wind,quality,reduceMotion,dt,illumination)
		if not self.ready then return end
		elapsed+=dt;self.quality=quality;self.reduceMotion=reduceMotion
		if elapsed<1/Config.quality[quality].hz then return end
		local step=elapsed;elapsed=0;local started=os.clock()
		self.phase=Model.advance(self.phase,step,wind.X,wind.Z,quality,reduceMotion)
		local directions
		local camera=workspace.CurrentCamera
		if illumination and camera then
			local function project(v)return {v:Dot(camera.CFrame.RightVector),v:Dot(camera.CFrame.UpVector),v.Y}end
			directions={sun=project(illumination.sun),moon=project(illumination.moon),sky={illumination.sky.R,illumination.sky.G,illumination.sky.B}}
		end
		local target=Model.project(sample,weights,quality,self.phase,reduceMotion,directions)
		if not current then current=target else
			for key,value in pairs(target)do
				if type(value)=="number" then current[key]=Model.smooth(current[key],value,step)
				else for i,v in ipairs(value)do current[key][i]=Model.smooth(current[key][i],v,step)end end
			end
		end
		local c=Color3.new(table.unpack(current.color));local layered=1-current.minimal
		local function set(name,alpha,color)labels[name].ImageTransparency=1-math.clamp(alpha,0,1);labels[name].ImageColor3=color or c end
		local coverage=current.tree*(1-Config.tree.atmosphericFade)
		local oceanColor=Color3.new(table.unpack(current.cloudColor))
		local cloudAlpha=oceanEnabled and current.cloud*Config.cloud.density*Config.cloud.opacity or 0
		set("WorldTree",coverage*layered)
		set("TreeGlow",current.glow*Config.glow.intensity*layered,Color3.new(table.unpack(current.glowColor)))
		-- Cloud cover survives Minimal and crossfades. It never exposes the tree base.
		set("CloudOcclusion",cloudAlpha,oceanColor)
		set("AtmosphericHaze",current.haze*Config.haze.opacity*layered,oceanColor)
		set("CloudDrift",current.moving*cloudAlpha*layered,oceanColor)
		set("MinimalComposition",current.minimal*coverage)
		local lightColor=Color3.new(table.unpack(current.lightColor))
		set("CrownTop",current.lightTop,lightColor);set("CrownLeft",current.lightLeft,lightColor);set("CrownRight",current.lightRight,lightColor)
		for _,bank in ipairs(banks)do bank.label.ImageTransparency=1-cloudAlpha*bank.density*Config.cloud.edgeBankOpacity;bank.label.ImageColor3=oceanColor end
		-- Freeze the position immediately for Minimal/Reduce Motion; global lighting still follows its owner.
		if quality~="minimal" and not reduceMotion then place(labels.CloudDrift,Config.cloud,current.x*Config.cloud.driftX,current.y*Config.cloud.driftY)end
		self.updates+=1;self.lastMs=(os.clock()-started)*1000
	end
	function self.stats()
		local visible=0;for _,l in pairs(labels)do if l.ImageTransparency<.999 then visible+=1 end end
		for _,b in ipairs(banks)do if b.label.ImageTransparency<.999 then visible+=1 end end
		local camera=workspace.CurrentCamera;local screen,onScreen,projected
		if camera and anchor and anchor.Parent then
			screen,onScreen=camera:WorldToViewportPoint(anchor.Position)
			local p=camera.CFrame:PointToObjectSpace(anchor.Position)
			projected=Model.bounds({p.X,p.Y,-p.Z},{Config.tree.size[1]*Config.tree.scale,Config.tree.size[2]*Config.tree.scale},Config.tree.offset,Data.Tree,{camera.ViewportSize.X,camera.ViewportSize.Y},camera.FieldOfView)
		end
		return {ready=self.ready,error=self.error,destroyed=self.destroyed,images=#pool.items,pixelWrites=self.pixelWrites,
			pixelBytes=#pool.items>0 and Config.textureBytes or 0,instances=folder and #folder:GetDescendants()+1 or 0,
			visibleLayers=visible,updates=self.updates,lastMs=self.lastMs,quality=self.quality,reduceMotion=self.reduceMotion,
			phase=self.phase,renderConnections=0,lifecycleConnections=cleanupConnection and 1 or 0,
			centerOnScreen=onScreen or false,centerDepth=screen and screen.Z or 0,alwaysOnTop=false,
			anchor=anchor and {anchor.Position.X,anchor.Position.Y,anchor.Position.Z} or nil,
			cloudBanks=self.ready and #banks+1 or 0,projectedAlphaBounds=projected,projectionIsApproximate=true,
			cameraType=camera and camera.CameraType.Name or nil,fieldOfView=camera and camera.FieldOfView or nil,
			oceanEnabled=oceanEnabled,light=current and {top=current.lightTop,left=current.lightLeft,right=current.lightRight,color=current.lightColor} or nil}
	end
	return self
end
return M
