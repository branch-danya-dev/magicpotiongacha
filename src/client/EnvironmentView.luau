--!nonstrict
-- One owner of environment lighting while enabled. No remotes or profile mutation.
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.EnvironmentConfig)
local State=require(Shared.EnvironmentState)
local Labels=require(Shared.EnvironmentLabels)
local View={}
local active=nil
local function color(v) return Color3.fromRGB(v[1],v[2],v[3]) end
function View.start(root,settings)
	assert(not active,"Environment lighting already has an owner")
	local self={quality=settings and settings.quality or "reduced",reduceMotion=false,pose=settings and settings.pose,root=root,parts={},rain={}}
	active=self
	local saved={}
	for _,key in ipairs({"ClockTime","Brightness","Ambient","OutdoorAmbient","GlobalShadows","ExposureCompensation","GeographicLatitude","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do saved[key]=Lighting[key] end
	local displaced={}
	for _,parent in ipairs({Lighting,workspace.Terrain}) do for _,v in ipairs(parent:GetChildren()) do
		if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") then
			table.insert(displaced,{object=v,parent=parent}); v.Parent=nil
		end
	end end
	local function effect(class,name,parent)
		local v=Instance.new(class); v.Name=name; v.Parent=parent; return v
	end
	local atmosphere=effect("Atmosphere","M7Atmosphere",Lighting)
	local sky=effect("Sky","M7Sky",Lighting) -- Engine-bundled sky, sun and moon; no marketplace IDs.
	sky.StarCount=350; sky.SunAngularSize=8; sky.MoonAngularSize=11
	local clouds=effect("Clouds","M7Clouds",workspace.Terrain)
	local correction=effect("ColorCorrectionEffect","M7Color",Lighting)
	local bloom=effect("BloomEffect","M7Bloom",Lighting); bloom.Size=18; bloom.Threshold=2.3
	local rays=effect("SunRaysEffect","M7SunRays",Lighting); rays.Spread=.35
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
			-- Reviewed templates name leaf meshes *_2 and trunks *_1. Reading
			-- SurfaceAppearance maps requires Plugin capability, unavailable here.
			local leaf=string.match(p.Name,"Tree.*_2$") or string.match(p.Name,"Pine.*_2$")
			local plant=string.find(p.Name,"Grass") or string.find(p.Name,"Fern") or leaf
			if plant then table.insert(wind,{part=p,base=p.CFrame,pivot=p.CFrame*CFrame.new(0,-p.Size.Y/2,0),height=p.Size.Y}) end
		end
	end
	-- Children can replicate after the enable attribute. Do not miss late lanterns.
	local added=root.EnvironmentArt.DescendantAdded:Connect(register)
	for _,p in ipairs(root.EnvironmentArt:GetDescendants()) do register(p) end
	for i=1,Config.budgets.rain do
		local p=effect("Part","LocalRain_"..i,folder); p.Size=Vector3.new(.035,.9,.035)
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
		p.Color=Color3.fromRGB(189,211,214); p.Transparency=1; table.insert(self.rain,p)
	end
	local motes={}
	for i=1,Config.budgets.motes do
		local p=effect("Part","AmbientMote_"..i,folder); p.Shape=Enum.PartType.Ball; p.Size=Vector3.new(.15,.15,.15)
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
		p.Material=i%3~=0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
		p.Color=i%3~=0 and Color3.fromRGB(238,226,140) or Color3.fromRGB(242,222,184); p.Transparency=1; motes[i]=p
	end
	local function apply(sample,q)
		Lighting.ClockTime=sample.clock; Lighting.Brightness=sample.brightness; Lighting.Ambient=color(sample.ambient)
		Lighting.OutdoorAmbient=color(sample.outdoor); Lighting.GlobalShadows=q.shadows; Lighting.ExposureCompensation=sample.exposure
		Lighting.GeographicLatitude=26; Lighting.ShadowSoftness=.5
		Lighting.ColorShift_Top=color(sample.sun):Lerp(Color3.new(),.65); Lighting.ColorShift_Bottom=Color3.fromRGB(8,12,22)
		Lighting.EnvironmentDiffuseScale=.45; Lighting.EnvironmentSpecularScale=.12
		atmosphere.Color=color(sample.sky); atmosphere.Decay=color(sample.decay); atmosphere.Density=sample.density; atmosphere.Haze=sample.haze*q.haze; atmosphere.Glare=.08*(1-sample.rain); atmosphere.Offset=.15
		clouds.Cover=sample.cover; clouds.Density=sample.cloudDensity; clouds.Color=color(sample.cloudColor)
		correction.TintColor=color(sample.tint); correction.Saturation=-.04-.10*sample.rain; correction.Contrast=.015
		bloom.Intensity=q.bloom; bloom.Enabled=q.bloom>0
		rays.Intensity=q.rays*(1-sample.rain)*(1-sample.night); rays.Enabled=q.rays>0
	end
	local lod=0; local step=0; local connection
	function self.setQuality(name) if Config.quality[name] then self.quality=name; lod=1 end end
	function self.setReduceMotion(enabled) self.reduceMotion=enabled==true; lod=1 end
	function self.setPose(name) if RunService:IsStudio() and (name==nil or Config.poses[name]) then self.pose=name end end
	function self.setPreview(enabled) if RunService:IsStudio() then self.previewStart=enabled and os.clock() or nil end end
	function self.stats()
		local counts={lights=0,rain=0,motes=0,wind=0,emitters=0}
		for _,l in ipairs(lights) do if l.Enabled then counts.lights+=1 end end
		for _,p in ipairs(self.rain) do if p.Transparency<1 then counts.rain+=1 end end
		for _,p in ipairs(motes) do if p.Transparency<1 then counts.motes+=1 end end
		for _,w in ipairs(wind) do if w.moving then counts.wind+=1 end end
		return counts
	end
	function self.setAnnotationsEnabled(enabled) annotations=enabled~=false; labelsDirty=1 end
	function self.update(dt)
		step+=dt; lod+=dt; labelsDirty+=dt; if step<1/30 then return end; step=0
		local camera=workspace.CurrentCamera; if not camera then return end
		local time=workspace:GetServerTimeNow(); local sample=self.previewStart and State.preview(Config,os.clock()-self.previewStart) or State.sample(Config,time,self.pose); local q=State.quality(Config,self.quality,self.reduceMotion)
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
			for i,l in ipairs(lights) do l.Enabled=i<=q.lights and (l.Parent.Position-camera.CFrame.Position).Magnitude<q.distance end
			table.sort(wind,function(a,b) return (a.base.Position-camera.CFrame.Position).Magnitude<(b.base.Position-camera.CFrame.Position).Magnitude end)
		end
		for _,l in ipairs(lights) do l.Brightness=.18+sample.night*1.45 end
		for i,w in ipairs(wind) do
			w.moving=i<=q.motion and w.part.LocalTransparencyModifier==0 and (w.base.Position-camera.CFrame.Position).Magnitude<q.distance
			w.part.CFrame=w.moving and w.pivot*CFrame.Angles(0,0,math.sin(time*.65+w.base.Position.X)*.009)*CFrame.new(0,w.height/2,0) or w.base
		end
		for i,p in ipairs(motes) do
			local m=State.mote(i,time,sample.night,sample.rain); local position=Vector3.new(m.x,m.y,m.z)
			local visible=i<=q.motes and (position-camera.CFrame.Position).Magnitude<q.distance
			p.Transparency=visible and 1-m.alpha or 1; if visible then p.Position=position end
		end
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
		if active~=self then return end; active=nil
		if connection then connection:Disconnect() end
		added:Disconnect()
		labelAdded:Disconnect()
		for _,l in ipairs(labels) do l.gui.Enabled=l.enabled end
		for k,v in pairs(saved) do Lighting[k]=v end
		for _,p in ipairs(self.parts) do p.LocalTransparencyModifier=0 end
		for _,w in ipairs(wind) do w.part.CFrame=w.base end
		for _,l in ipairs(lights) do l:Destroy() end
		atmosphere:Destroy(); sky:Destroy(); clouds:Destroy(); correction:Destroy(); bloom:Destroy(); rays:Destroy(); folder:Destroy()
		for _,v in ipairs(displaced) do v.object.Parent=v.parent end
	end
	self.update(1); connection=RunService.RenderStepped:Connect(self.update)
	return self
end
return View
