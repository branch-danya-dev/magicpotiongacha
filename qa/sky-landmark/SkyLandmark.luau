--!nonstrict
-- One world-anchored layered billboard, driven only by EnvironmentView.update.
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
	local pool=Resources.new();local folder,anchor,gui,cleanupConnection;local labels={};local elapsed=0;local current
	local function dispose()
		if self.destroyed then return end;self.destroyed=true;self.ready=false
		if cleanupConnection then cleanupConnection:Disconnect();cleanupConnection=nil end
		if folder then folder:Destroy();folder=nil end;table.clear(labels);pool.destroy()
	end
	self.destroy=dispose
	local ok,err=pcall(function()
		folder=Instance.new("Folder");folder.Name="SkyLandmark";folder.Parent=parent
		anchor=Instance.new("Part");anchor.Name="WorldAnchor";anchor.Size=Vector3.one;anchor.Transparency=1
		anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false
		anchor.Position=Vector3.new(table.unpack(require(Shared.PersonalIsland).origin))+Vector3.new(table.unpack(Config.offset));anchor.Parent=folder
		gui=Instance.new("BillboardGui");gui.Name="DistantComposition";gui.Adornee=anchor;gui.AlwaysOnTop=false
		gui.LightInfluence=0;gui.Size=UDim2.fromScale(Config.size,Config.size);gui.MaxDistance=Config.maxDistance
		gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Active=false;gui.ClipsDescendants=false;gui.Parent=anchor
		local images={}
		for _,name in ipairs({"Tree","Cloud","Glow","Minimal"})do
			local d=Data[name]
			local img=pool.get(name,function()return Asset:CreateEditableImage({Size=Vector2.new(d.size,d.size)})end)
			local pixels=game:GetService("EncodingService"):Base64Decode(buffer.fromstring(d.rgba))
			assert(buffer.len(pixels)==d.size*d.size*4,"Landmark pixel length mismatch")
			img:WritePixelsBuffer(Vector2.zero,img.Size,pixels);self.pixelWrites+=1;images[name]=img
		end
		for _,entry in ipairs({{"TreeGlow","Glow",1},{"WorldTree","Tree",2},{"AtmosphericHaze","Cloud",3},{"CloudOcclusion","Cloud",4},{"CloudDrift","Cloud",5},{"MinimalComposition","Minimal",6}})do
			local label=Instance.new("ImageLabel");label.Name=entry[1];label.BackgroundTransparency=1;label.ImageTransparency=1;label.Active=false
			label.Size=UDim2.fromScale(1,1);label.AnchorPoint=Vector2.new(.5,.5);label.Position=UDim2.fromScale(.5,.5)
			label.ImageContent=Content.fromObject(images[entry[2]]);label.ZIndex=entry[3];label.Parent=gui;labels[entry[1]]=label
		end
		labels.CloudOcclusion.Position=UDim2.fromScale(.5,.5+Config.cloudOffsetY)
		labels.AtmosphericHaze.Position=UDim2.fromScale(.5,.38)
		self.ready=true;cleanupConnection=folder.Destroying:Connect(dispose)
	end)
	if not ok then self.error=tostring(err);dispose();warn("SKY_LANDMARK_BLOCKED",err)end
	function self.update(sample,weights,wind,quality,reduceMotion,dt)
		if not self.ready then return end
		elapsed+=dt;self.quality=quality;self.reduceMotion=reduceMotion
		if elapsed<1/Config.quality[quality].hz then return end
		local step=elapsed;elapsed=0;local started=os.clock()
		self.phase=Model.advance(self.phase,step,wind.X,wind.Z,quality,reduceMotion)
		local target=Model.project(sample,weights,quality,self.phase,reduceMotion)
		if not current then current=target else
			for key,value in pairs(target)do
				if type(value)=="number" then current[key]=Model.smooth(current[key],value,step)
				else for i,v in ipairs(value)do current[key][i]=Model.smooth(current[key][i],v,step)end end
			end
		end
		local c=Color3.new(table.unpack(current.color));local layered=1-current.minimal
		local function set(name,alpha,color)labels[name].ImageTransparency=1-math.clamp(alpha,0,1);labels[name].ImageColor3=color or c end
		set("WorldTree",current.tree*layered)
		set("TreeGlow",current.glow*layered,Color3.new(table.unpack(current.glowColor)))
		set("CloudOcclusion",current.cloud*.9*layered)
		set("AtmosphericHaze",current.haze*current.cloud*layered)
		set("CloudDrift",current.moving*current.cloud*layered)
		set("MinimalComposition",current.minimal*current.tree)
		-- Freeze the position immediately for Minimal/Reduce Motion; global lighting still follows its owner.
		if quality~="minimal" and not reduceMotion then labels.CloudDrift.Position=UDim2.fromScale(.5+current.x,.5+Config.cloudOffsetY+current.y)end
		self.updates+=1;self.lastMs=(os.clock()-started)*1000
	end
	function self.stats()
		local visible=0;for _,l in pairs(labels)do if l.ImageTransparency<.999 then visible+=1 end end
		local camera=workspace.CurrentCamera;local screen,onScreen
		if camera and anchor and anchor.Parent then screen,onScreen=camera:WorldToViewportPoint(anchor.Position)end
		return {ready=self.ready,error=self.error,destroyed=self.destroyed,images=#pool.items,pixelWrites=self.pixelWrites,
			pixelBytes=#pool.items>0 and Config.textureBytes or 0,instances=folder and #folder:GetDescendants()+1 or 0,
			visibleLayers=visible,updates=self.updates,lastMs=self.lastMs,quality=self.quality,reduceMotion=self.reduceMotion,
			phase=self.phase,renderConnections=0,lifecycleConnections=cleanupConnection and 1 or 0,
			centerOnScreen=onScreen or false,centerDepth=screen and screen.Z or 0,alwaysOnTop=false,
			anchor=anchor and {anchor.Position.X,anchor.Position.Y,anchor.Position.Z} or nil}
	end
	return self
end
return M
