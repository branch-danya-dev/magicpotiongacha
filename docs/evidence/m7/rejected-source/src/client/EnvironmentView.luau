--!nonstrict
-- One owner of environment lighting while enabled. No remotes or profile mutation.
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.EnvironmentConfig)
local State=require(Shared.EnvironmentState)
local Labels=require(Shared.EnvironmentLabels)
local View={}
local function color(v) return Color3.fromRGB(v[1],v[2],v[3]) end
function View.start(root,settings)
	local self={quality=settings and settings.quality or "reduced",reduceMotion=false,pose=settings and settings.pose,root=root,parts={},rain={}}
	local function effect(class,name,parent)
		local v=Instance.new(class); v.Name=name; v.Parent=parent; return v
	end
	local atmosphere=effect("Atmosphere","M7Atmosphere",Lighting)
	local clouds=effect("Clouds","M7Clouds",workspace.Terrain)
	local correction=effect("ColorCorrectionEffect","M7Color",Lighting)
	local bloom=effect("BloomEffect","M7Bloom",Lighting); bloom.Size=24; bloom.Threshold=1.6
	local folder=effect("Folder","M7ClientWeather",workspace)
	local lights={}; local wind={}; local registered={}
	local labels={}; local annotations=true; local labelsDirty=0
	local function registerLabel(gui)
		if gui:IsA("BillboardGui") then table.insert(labels,{gui=gui,enabled=gui.Enabled}) end
	end
	for _,gui in ipairs(root:GetDescendants()) do registerLabel(gui) end
	local labelAdded=root.DescendantAdded:Connect(registerLabel)
	local function register(p)
		if registered[p] then return end
		if p:IsA("BasePart") then
			registered[p]=true
			table.insert(self.parts,p)
			if p:GetAttribute("EnvironmentLight") then
				local l=effect("PointLight","M7LocalLantern",p); l.Color=color(Config.palette.amber); l.Range=14; l.Shadows=false; table.insert(lights,l)
			end
			if p:GetAttribute("EnvironmentWind") then table.insert(wind,{part=p,base=p.CFrame}) end
		end
	end
	-- Children can replicate after the enable attribute. Do not miss late lanterns.
	local added=root.EnvironmentArt.ChildAdded:Connect(register)
	for _,p in ipairs(root.EnvironmentArt:GetChildren()) do register(p) end
	for i=1,Config.budgets.rain do
		local p=effect("Part","LocalRain_"..i,folder); p.Size=Vector3.new(.035,.9,.035)
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
		p.Color=Color3.fromRGB(189,211,214); p.Transparency=1; table.insert(self.rain,p)
	end
	local saved={ClockTime=Lighting.ClockTime,Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,GlobalShadows=Lighting.GlobalShadows,ExposureCompensation=Lighting.ExposureCompensation}
	local function apply(sample,q)
		Lighting.ClockTime=sample.clock; Lighting.Brightness=sample.brightness; Lighting.Ambient=color(sample.ambient)
		Lighting.OutdoorAmbient=color(sample.outdoor); Lighting.GlobalShadows=q.shadows; Lighting.ExposureCompensation=.05
		atmosphere.Color=color(sample.sky); atmosphere.Decay=Color3.fromRGB(142,161,174); atmosphere.Density=sample.density; atmosphere.Haze=sample.haze; atmosphere.Glare=.1
		clouds.Cover=sample.cover; clouds.Density=sample.cloudDensity; clouds.Color=Color3.fromRGB(235,234,225)
		correction.TintColor=color(sample.tint); correction.Saturation=-.03-.08*sample.rain; correction.Contrast=.04
		bloom.Intensity=q.bloom; bloom.Enabled=q.bloom>0
	end
	local lod=0; local step=0; local connection
	function self.setQuality(name) if Config.quality[name] then self.quality=name; lod=1 end end
	function self.setReduceMotion(enabled) self.reduceMotion=enabled==true; lod=1 end
	function self.setPose(name) if RunService:IsStudio() and (name==nil or Config.poses[name]) then self.pose=name end end
	function self.setAnnotationsEnabled(enabled) annotations=enabled~=false; labelsDirty=1 end
	function self.update(dt)
		step+=dt; lod+=dt; labelsDirty+=dt; if step<1/30 then return end; step=0
		local camera=workspace.CurrentCamera; if not camera then return end
		local time=workspace:GetServerTimeNow(); local sample=State.sample(Config,time,self.pose); local q=State.quality(Config,self.quality,self.reduceMotion)
		apply(sample,q)
		if labelsDirty>=.25 then
			labelsDirty=0
			local entries={}
			if annotations then
				for id,l in ipairs(labels) do
					local gui=l.gui; local anchor=gui.Adornee or gui.Parent
					if anchor and anchor:IsA("BasePart") then
						local p=camera:WorldToViewportPoint(anchor.Position+camera.CFrame:VectorToWorldSpace(gui.StudsOffset)+gui.StudsOffsetWorldSpace)
						table.insert(entries,{id=id,x=p.X,y=p.Y,z=p.Z,distance=(anchor.Position-camera.CFrame.Position).Magnitude,
							w=gui.Size.X.Offset,h=gui.Size.Y.Offset,enabled=l.enabled})
					end
				end
			end
			local selected=Labels.select(entries,camera.ViewportSize.X,camera.ViewportSize.Y)
			for id,l in ipairs(labels) do l.gui.Enabled=selected[id]==true end
		end
		if lod>=.5 then
			lod=0
			for _,p in ipairs(self.parts) do
				local detail=p:GetAttribute("EnvironmentDetail") or 1
				-- Preserve the scene silhouette at all tiers; only small decorative detail gets culled.
				if detail>q.detail or (detail>1 and (p.Position-camera.CFrame.Position).Magnitude>q.distance) then p.LocalTransparencyModifier=1 else p.LocalTransparencyModifier=0 end
			end
			table.sort(lights,function(a,b) return (a.Parent.Position-camera.CFrame.Position).Magnitude<(b.Parent.Position-camera.CFrame.Position).Magnitude end)
			for i,l in ipairs(lights) do l.Enabled=i<=q.lights and (l.Parent.Position-camera.CFrame.Position).Magnitude<q.distance; l.Brightness=.3+sample.night*.9 end
		end
		for i,w in ipairs(wind) do w.part.CFrame=w.base*CFrame.Angles(0,0,i<=q.motion and math.sin(time*.65+i)*.012 or 0) end
		for i,p in ipairs(self.rain) do
			local visible=i<=q.rain and sample.rain>.01
			p.Transparency=visible and (1-sample.rain*.3) or 1
			if visible then
				local center=camera.CFrame.Position; local x=(i*17%47)-23; local z=(i*29%43)-21
				p.CFrame=CFrame.new(center+Vector3.new(x,14-((time*15+i*1.7)%25),z))*CFrame.Angles(0,0,-.09)
			end
		end
	end
	function self.stop()
		if connection then connection:Disconnect() end
		added:Disconnect()
		labelAdded:Disconnect()
		for _,l in ipairs(labels) do l.gui.Enabled=l.enabled end
		for k,v in pairs(saved) do Lighting[k]=v end
		for _,p in ipairs(self.parts) do p.LocalTransparencyModifier=0 end
		for _,w in ipairs(wind) do w.part.CFrame=w.base end
		for _,l in ipairs(lights) do l:Destroy() end
		atmosphere:Destroy(); clouds:Destroy(); correction:Destroy(); bloom:Destroy(); folder:Destroy()
	end
	self.update(1); connection=RunService.RenderStepped:Connect(self.update)
	return self
end
return View
