--!nonstrict
-- One owner of environment lighting while enabled. No remotes or profile mutation.
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local ContentProvider=game:GetService("ContentProvider")
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
	local saved={}; local savedWind=workspace.GlobalWind
	for _,key in ipairs({"ClockTime","Brightness","Ambient","OutdoorAmbient","GlobalShadows","ExposureCompensation","GeographicLatitude","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do saved[key]=Lighting[key] end
	local displaced={}
	for _,parent in ipairs({Lighting,workspace.Terrain}) do for _,v in ipairs(parent:GetChildren()) do
		if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("ColorCorrectionEffect") or v:IsA("ColorGradingEffect") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") then
			table.insert(displaced,{object=v,parent=parent}); v.Parent=nil
		end
	end end
	local function effect(class,name,parent)
		local v=Instance.new(class); v.Name=name; v.Parent=parent; return v
	end
	local atmosphere=effect("Atmosphere","M7Atmosphere",Lighting)
	local sky=effect("Sky","M7Sky",nil)
	local assets={}
	for property,face in pairs({SkyboxBk="bk",SkyboxDn="dn",SkyboxFt="ft",SkyboxLf="lf",SkyboxRt="rt",SkyboxUp="up"}) do
		local uri=Config.skyPrefix..face..".png"; sky[property]=uri; table.insert(assets,uri)
	end
	sky.SunTextureId=Config.skyPrefix.."sun.png"; sky.MoonTextureId=Config.skyPrefix.."moon.png"
	for _,name in ipairs({"sun","moon","mist","rainbow"}) do table.insert(assets,Config.skyPrefix..name..".png") end
	for _,name in ipairs({"meadow","star"}) do table.insert(assets,Config.polishPrefix..name..".png") end
	-- The sky retains its sun; a single owned celestial rig supplies a low moon
	-- and legible stars. Native zenith moon/stars are disabled, never duplicated.
	sky.CelestialBodiesShown=true; sky.StarCount=0; sky.SunAngularSize=7; sky.MoonAngularSize=0
	-- A single asset set for the entire session. No texture swaps at time/weather keys.
	sky.Parent=Lighting
	self.assetFailures=0
	task.spawn(function()
		local ok=pcall(function() ContentProvider:PreloadAsync(assets,function(_,status)
			if status~=Enum.AssetFetchStatus.Success then self.assetFailures+=1 end
		end) end)
		if not ok then self.assetFailures+=1 end
		if active==self and RunService:IsStudio() then print("M7_A2C_ASSETS failures="..self.assetFailures.." source=original-CC0-local permissions=LOCAL_ONLY") end
	end)
	local clouds=effect("Clouds","M7Clouds",workspace.Terrain)
	local correction=effect("ColorCorrectionEffect","M7Color",Lighting)
	local bloom=effect("BloomEffect","M7Bloom",Lighting); bloom.Size=18; bloom.Threshold=2.3
	local rays=effect("SunRaysEffect","M7SunRays",Lighting); rays.Spread=.35
	local folder=effect("Folder","M7ClientWeather",workspace)
	local function localPart(name,size)
		local p=effect("Part",name,folder); p.Size=size
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
		p.Transparency=1; return p
	end
	local ground=RaycastParams.new(); ground.FilterType=Enum.RaycastFilterType.Include
	ground.FilterDescendantsInstances={workspace.Terrain,root.ForestFloor,root.Plot_1.Floor}
	local function surface(x,z)
		local hit=workspace:Raycast(Vector3.new(x,70,z),Vector3.new(0,-120,0),ground)
		return hit and hit.Position.Y or .5
	end
	local function sprite(name,texture,size,position)
		local p=localPart(name,Vector3.new(.1,.1,.1)); p.Position=position
		local gui=effect("BillboardGui",name.."Sprite",p); gui.Size=UDim2.fromScale(size.X,size.Y); gui.LightInfluence=0; gui.AlwaysOnTop=false
		local img=effect("ImageLabel","Image",gui); img.BackgroundTransparency=1; img.Size=UDim2.fromScale(1,1); img.Image=Config.skyPrefix..texture..".png"; img.ImageTransparency=1
		return {part=p,gui=gui,image=img}
	end
	local fog={}
	for i,pos in ipairs({{-169,-112},{-115,-106},{-184,-58}}) do
		fog[i]=sprite("GroundMist_"..i,"mist",Vector2.new(42,6.5),Vector3.new(pos[1],surface(pos[1],pos[2])+1.7,pos[2]))
	end
	local glints={}
	for i=1,Config.budgets.glints do
		local x=-142.5+(i%2==0 and -1 or 1)*(14+i*2); local z=-46-i*9
		local p=localPart("DewAndGlow_"..i,Vector3.new(.3,.04,.18)); p.Shape=Enum.PartType.Ball; p.Material=Enum.Material.Neon
		p.Position=Vector3.new(x,surface(x,z)+.2,z); p.Color=Color3.fromRGB(129,218,224); glints[i]=p
	end
	local rainbow=sprite("AfterRainArc","rainbow",Vector2.new(95,48),Vector3.new(-140,50,-160))
	-- One non-rendering anchor, no per-star Parts/lights/emitters. The rig follows
	-- camera translation only so celestial bearings remain fixed in the world.
	local celestialAnchor=localPart("CelestialAnchor",Vector3.new(.1,.1,.1))
	local function celestialSprite(name,uri,size,direction)
		local attachment=effect("Attachment",name,celestialAnchor); attachment.Position=direction*Config.celestial.distance
		local gui=effect("BillboardGui",name.."Sprite",attachment); gui.Adornee=attachment
		gui.Size=UDim2.fromScale(size,size); gui.LightInfluence=0; gui.AlwaysOnTop=false
		local img=effect("ImageLabel","Image",gui); img.BackgroundTransparency=1; img.Size=UDim2.fromScale(1,1); img.Image=uri; img.ImageTransparency=1
		return {attachment=attachment,gui=gui,image=img}
	end
	local moon=celestialSprite("Moon",Config.skyPrefix.."moon.png",Config.celestial.moonSize,Vector3.new(0,1,0))
	local stars={}
	for i=1,Config.celestial.stars do
		local d=State.star(i); stars[i]=celestialSprite("Star_"..i,Config.polishPrefix.."star.png",d.size,Vector3.new(d.x,d.y,d.z)); stars[i].alpha=d.alpha
	end
	local lights={}; local wind={}; local registered={}; local wetSurfaces={}
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
			if string.find(p.Name,"RockPath") then table.insert(wetSurfaces,{part=p,color=p.Color,wet=Color3.new(p.Color.R*.70,p.Color.G*.75,p.Color.B*.78)}) end
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
		Lighting.GeographicLatitude=26; Lighting.ShadowSoftness=.7
		Lighting.ColorShift_Top=color(sample.sun):Lerp(Color3.new(),.65); Lighting.ColorShift_Bottom=Color3.fromRGB(8,12,22)
		Lighting.EnvironmentDiffuseScale=.35; Lighting.EnvironmentSpecularScale=.1
		atmosphere.Color=color(sample.sky); atmosphere.Decay=color(sample.decay); atmosphere.Density=sample.density; atmosphere.Haze=sample.haze*q.haze; atmosphere.Glare=.08*(1-sample.rain); atmosphere.Offset=.15
		clouds.Cover=sample.cover; clouds.Density=sample.cloudDensity; clouds.Color=color(sample.cloudColor)
		correction.TintColor=color(sample.tint); correction.Saturation=.04-.12*sample.cloud; correction.Contrast=.025
		workspace.GlobalWind=self.reduceMotion and Vector3.zero or Vector3.new(4+sample.wind*8,0,2+sample.wind*3)
		bloom.Intensity=q.bloom; bloom.Enabled=q.bloom>0
		rays.Intensity=q.rays*(1-sample.rain)*(1-sample.night); rays.Enabled=q.rays>0
	end
	local lod=0; local step=0; local connection
	function self.setQuality(name) if Config.quality[name] then self.quality=name; lod=1 end end
	function self.setReduceMotion(enabled) self.reduceMotion=enabled==true; lod=1 end
	function self.setPose(name) if RunService:IsStudio() and (name==nil or Config.poses[name]) then self.pose=name end end
	function self.setPreview(enabled) if RunService:IsStudio() then self.previewStart=enabled and os.clock() or nil end end
	function self.stats()
		local counts={lights=0,rain=0,motes=0,wind=0,emitters=0,fog=0,glints=0,rainbow=0,stars=0,moon=0,assetFailures=self.assetFailures}
		for _,l in ipairs(lights) do if l.Enabled then counts.lights+=1 end end
		for _,p in ipairs(self.rain) do if p.Transparency<1 then counts.rain+=1 end end
		for _,p in ipairs(motes) do if p.Transparency<1 then counts.motes+=1 end end
		for _,w in ipairs(wind) do if w.moving then counts.wind+=1 end end
		for _,v in ipairs(fog) do if v.image.ImageTransparency<1 then counts.fog+=1 end end
		for _,p in ipairs(glints) do if p.Transparency<1 then counts.glints+=1 end end
		counts.rainbow=rainbow.image.ImageTransparency<1 and 1 or 0
		for _,v in ipairs(stars) do if v.image.ImageTransparency<1 then counts.stars+=1 end end
		counts.moon=moon.image.ImageTransparency<1 and 1 or 0
		return counts
	end
	function self.setAnnotationsEnabled(enabled) annotations=enabled~=false; labelsDirty=1 end
	function self.update(dt)
		step+=dt; lod+=dt; labelsDirty+=dt; if step<1/30 then return end; local elapsed=step; step=0
		local camera=workspace.CurrentCamera; if not camera then return end
		local time=workspace:GetServerTimeNow(); local sample=self.previewStart and State.preview(Config,os.clock()-self.previewStart) or State.sample(Config,time,self.pose); local q=State.quality(Config,self.quality,self.reduceMotion)
		apply(sample,q)
		celestialAnchor.Position=camera.CFrame.Position
		moon.attachment.Position=Vector3.new(table.unpack(State.moon(sample.phase)))*Config.celestial.distance
		moon.image.ImageTransparency=1-sample.celestial*.94
		for i,v in ipairs(stars) do v.image.ImageTransparency=1-(i<=q.stars and sample.celestial*v.alpha or 0) end
		for _,v in ipairs(wetSurfaces) do v.part.Color=v.color:Lerp(v.wet,sample.wetStone*.35) end
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
			-- Issue #18 owns gameplay context independently of art/quality. The
			-- historical annotation selector is retained only in the art harness.
			if not root:GetAttribute("WorldContextOwned") then
				for id,l in ipairs(labels) do l.gui.Enabled=selected[id]==true end
			end
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
			local center=camera.CFrame.Position
			for i,p in ipairs(self.rain) do
				local x=math.clamp(center.X,-181,-104)+(i*17%47)-23; local z=math.clamp(center.Z,-109,-36)+(i*29%43)-21
				p:SetAttribute("GroundY",surface(x,z)); p:SetAttribute("RainX",x); p:SetAttribute("RainZ",z)
			end
		end
		for _,l in ipairs(lights) do l.Brightness=.18+sample.night*1.45 end
		-- Fading OUT still consumes a slot. New nearby foliage waits for a free
		-- slot, so camera movement cannot double the motion budget during fades.
		local occupied=0
		for i,w in ipairs(wind) do
			w.wanted=i<=q.motion and w.part.LocalTransparencyModifier==0 and (w.base.Position-camera.CFrame.Position).Magnitude<q.distance
			w.weight=w.weight or 0
			if w.weight>0 then
				if occupied>=q.motion then w.weight=0
				elseif w.wanted then w.weight=math.min(1,w.weight+elapsed*1.5)
				else w.weight=math.max(0,w.weight-elapsed*1.5) end
				if w.weight>0 then occupied+=1 end
			end
		end
		for _,w in ipairs(wind) do
			if w.wanted and w.weight==0 and occupied<q.motion then w.weight=math.min(1,elapsed*1.5); occupied+=1 end
			w.moving=w.weight>0
			w.part.CFrame=w.pivot*CFrame.Angles(0,0,math.sin(time*.65+w.base.Position.X)*(.007+.007*sample.wind)*w.weight)*CFrame.new(0,w.height/2,0)
		end
		for i,p in ipairs(motes) do
			local m=State.mote(i,time,sample.night,sample.rain); local position=Vector3.new(m.x,m.y,m.z)
			local visible=i<=q.motes and (position-camera.CFrame.Position).Magnitude<q.distance
			p.Transparency=visible and 1-m.alpha or 1; if visible then p.Position=position end
			p.Color=m.firefly and color({168+70*sample.warm,224,181-50*sample.warm}) or color({235,229-33*sample.warm,213-55*sample.warm})
		end
		for i,p in ipairs(self.rain) do
			local pilotDistance=(camera.CFrame.Position-Vector3.new(-142.5,5,-65)).Magnitude
			local visible=i<=q.rain and sample.rain>0 and pilotDistance<q.distance
			p.Transparency=visible and (1-sample.rain*.52) or 1
			if visible then
				local fall=(time*1.15+i*.173)%1; local y=p:GetAttribute("GroundY") or .5
				local x,z=p:GetAttribute("RainX") or -142.5,p:GetAttribute("RainZ") or -65
				-- Splashes reuse the same rain slots; no emitters or additional pool.
				if fall>.91 then
					local radius=.08+(fall-.91)*3; p.Size=Vector3.new(radius,.025,radius)
					p.CFrame=CFrame.new(x,y+.06,z); p.Transparency=1-sample.rain*.38*(1-(fall-.91)/.09)
				else
					p.Size=Vector3.new(.045,.85,.045); p.CFrame=CFrame.new(x+(1-fall)*1.8,y+.2+(1-fall)*24,z)*CFrame.Angles(0,0,-.09)
				end
			end
		end
		for i,v in ipairs(fog) do
			local distance=(v.part.Position-camera.CFrame.Position).Magnitude
			local fade=math.clamp((q.distance-distance)/20,0,1)
			v.image.ImageTransparency=1-(i<=q.fog and sample.fog*.85*fade or 0)
			v.image.ImageColor3=Color3.fromRGB(214,229,239):Lerp(Color3.fromRGB(228,249,241),sample.dawn)
		end
		for i,p in ipairs(glints) do
			local distance=(p.Position-camera.CFrame.Position).Magnitude; local fade=math.clamp((q.distance-distance)/20,0,1)
			p.Transparency=1-(i<=q.glints and math.max(sample.night*.6,sample.glint*.65)*fade or 0)
			p.Color=color({195-66*sample.night,231-13*sample.night,219+5*sample.night})
		end
		local sun=Lighting:GetSunDirection(); local horizontal=Vector3.new(-sun.X,0,-sun.Z)
		local eligible=sun.Y>.08 and sun.Y<.88 and horizontal.Magnitude>.01
		local arc=eligible and sample.rainbow*.45 or 0
		if eligible then
			local direction=horizontal.Unit; local facing=math.clamp((camera.CFrame.LookVector:Dot(direction)-.1)/.4,0,1)
			local elevation=math.clamp((sun.Y-.08)/.08,0,1)*math.clamp((.88-sun.Y)/.08,0,1)
			arc*=facing*elevation; rainbow.part.Position=Vector3.new(-142.5,23,-65)+direction*105
		end
		local nearPilot=(camera.CFrame.Position-Vector3.new(-142.5,5,-65)).Magnitude<q.distance
		rainbow.image.ImageTransparency=1-(q.rainbow>0 and nearPilot and arc or 0)
	end
	function self.stop()
		if active~=self then return end; active=nil
		if connection then connection:Disconnect() end
		added:Disconnect()
		labelAdded:Disconnect()
		if not root:GetAttribute("WorldContextOwned") then
			for _,l in ipairs(labels) do l.gui.Enabled=l.enabled end
		end
		for k,v in pairs(saved) do Lighting[k]=v end
		workspace.GlobalWind=savedWind
		for _,p in ipairs(self.parts) do p.LocalTransparencyModifier=0 end
		for _,w in ipairs(wind) do w.part.CFrame=w.base end
		for _,v in ipairs(wetSurfaces) do v.part.Color=v.color end
		for _,l in ipairs(lights) do l:Destroy() end
		atmosphere:Destroy(); sky:Destroy(); clouds:Destroy(); correction:Destroy(); bloom:Destroy(); rays:Destroy(); folder:Destroy()
		for _,v in ipairs(displaced) do v.object.Parent=v.parent end
	end
	self.update(1); connection=RunService.RenderStepped:Connect(self.update)
	return self
end
return View
