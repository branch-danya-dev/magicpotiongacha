--!nonstrict
-- One owner of environment lighting while enabled. No remotes or profile mutation.
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local ContentProvider=game:GetService("ContentProvider")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.EnvironmentConfig)
local State=require(Shared.EnvironmentState)
-- AG63_BEGIN_IMPORT
local Look=require(Shared.PostFXLook)
-- AG63_END_IMPORT
local Style=require(Shared.AtmosphereStyle)
local Transition=require(Shared.EnvironmentTransition)
local Clock=require(Shared.EnvironmentClock)
local Labels=require(Shared.EnvironmentLabels)
local ForestLOD=require(Shared.ForestLOD)
local Meadow=require(Shared.MeadowPlan)
local MeadowMotion=require(Shared.MeadowMotion)
local LightSlots=require(Shared.EnvironmentLights)
local Boundary=require(Shared.IslandBoundary)
local RainField=require(Shared.RainField)
local Vista=require(Shared.VistaPlan)
local Players=game:GetService("Players")
local View={}
local active=nil
local function color(v) return Color3.fromRGB(v[1],v[2],v[3]) end
function View.start(root,settings)
	assert(not active,"Environment lighting already has an owner")
	local self={quality=settings and settings.quality or "reduced",reduceMotion=false,pose=settings and settings.pose,root=root,parts={},rain={}}
	active=self
	-- AG63_BEGIN_STATE
	local look=Look.default
	local lookInspect
	-- AG63_END_STATE
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
		local uri=Style.skyPrefix..face..".png"; sky[property]=uri; table.insert(assets,uri)
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
		if active==self and RunService:IsStudio() then print("M7_19E_ASSETS failures="..self.assetFailures.." source=original-CC0-local permissions=LOCAL_ONLY") end
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
	local groundTargets={workspace.Terrain,root.ForestFloor}
	for _,child in ipairs(root:GetChildren()) do
		local floor=child:FindFirstChild("Floor")
		if string.sub(child.Name,1,5)=="Plot_" and floor then table.insert(groundTargets,floor) end
	end
	ground.FilterDescendantsInstances=groundTargets
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
	for i,pos in ipairs(Vista.fogAnchors) do
		fog[i]=sprite("GroundMist_"..i,"mist",Vector2.new(42,6.5),Vector3.new(pos[1],surface(pos[1],pos[2])+1.7,pos[2]))
	end
	local glints={}
	for i=1,Config.budgets.glints do
		local x=-142.5+(i%2==0 and -1 or 1)*(14+i*2); local z=-46-i*9
		local p=localPart("DewAndGlow_"..i,Vector3.new(.3,.04,.18)); local mesh=effect("SpecialMesh","GlintShape",p); mesh.MeshType=Enum.MeshType.Sphere; mesh.Scale=Vector3.one; p.Material=Enum.Material.Neon
		p.Position=Vector3.new(x,surface(x,z)+.2,z); p.Color=Color3.fromRGB(129,218,224); glints[i]=p
	end
	-- Two local sun accents share the existing active-light ceiling with lanterns.
	local sunPools={}
	for i,pos in ipairs(Style.sunPools) do
		local p=localPart("SunPool_"..i,Vector3.new(.1,.1,.1)); p.Position=Vector3.new(pos[1],surface(pos[1],pos[2])+14,pos[2])
		local light=effect("SpotLight","CanopySun",p); light.Face=Enum.NormalId.Bottom
		light.Angle=75; light.Range=22; light.Shadows=false; light.Brightness=0; light.Enabled=false
		light.Color=Color3.fromRGB(255,223,168); sunPools[i]=light
	end
	local pollenGround={}
	for i,pos in ipairs(Style.pollenAnchors) do pollenGround[i]=surface(pos[1],pos[2]) end
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
	local moon=celestialSprite("Moon",Config.skyPrefix.."moon.png",Vista.moonSize,Vector3.new(0,1,0))
	local stars={}
	for i=1,Config.celestial.stars do
		local d=State.star(i); stars[i]=celestialSprite("Star_"..i,Config.polishPrefix.."star.png",d.size,Vector3.new(d.x,d.y,d.z)); stars[i].alpha=d.alpha
	end
	local lights={}; local lanternSlots={}; local sunSlots={}; local lampPanes={}; local lampsById={}
	for i,l in ipairs(sunPools) do sunSlots[i]={id=i,light=l,distance=math.huge} end
	local wind={}; local canopyGroups={}; local registered={}; local wetSurfaces={}
	local meadowWind={}; local meadowParts={}; local forestParts={}; local forestByPart={}
	local vistaParts={}; local vistaByPart={}
	local labels={}; local annotations=true; local labelsDirty=0; local pendingPanes={}
	local function bindPane(p)
		local id=p:GetAttribute("EnvironmentLanternPane")
		if not id then return false end
		lampPanes[id]=p; if lampsById[id] then lampsById[id].Parent=p end
		return true
	end
	local function registerLabel(gui)
		if gui:IsA("BillboardGui") then table.insert(labels,{gui=gui,enabled=gui.Enabled}) end
		if gui:IsA("BasePart") and string.find(gui.Name,"AmberPane",1,true) then
			-- Attributes may replicate after ancestry; six bounded one-shot hooks.
			if not bindPane(gui) and not pendingPanes[gui] then
				pendingPanes[gui]=gui:GetAttributeChangedSignal("EnvironmentLanternPane"):Connect(function()
					if bindPane(gui) then pendingPanes[gui]:Disconnect(); pendingPanes[gui]=nil end
				end)
			end
		end
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
				local l=effect("PointLight","M7LocalLantern",p); l.Enabled=false; l.Color=color(Config.palette.amber); l.Range=14; l.Shadows=false; table.insert(lights,l)
				lampsById[p.Name]=l; if lampPanes[p.Name] then l.Parent=lampPanes[p.Name] end
				table.insert(lanternSlots,{id=p.Name,light=l,distance=math.huge})
			end
			-- Reviewed templates name leaf meshes *_2 and trunks *_1. Reading
			-- SurfaceAppearance maps requires Plugin capability, unavailable here.
			local leaf=string.match(p.Name,"Tree.*_2$") or string.match(p.Name,"Pine.*_2$")
			local plant=string.find(p.Name,"Grass") or string.find(p.Name,"Fern") or leaf
			local forestRole=p:GetAttribute("ForestRole")
			local vistaRole=p:GetAttribute("VistaRole")
			if vistaRole then
				local entry={part=p,role=vistaRole,alpha=1,target=1,saved=p.LocalTransparencyModifier,
					color=p.Color,window=p:GetAttribute("VistaWindow")==true}
				table.insert(vistaParts,entry); vistaByPart[p]=entry; p.LocalTransparencyModifier=1
			end
			if forestRole then
				local entry={part=p,role=forestRole,anchor=p:GetAttribute("ForestAnchor"),alpha=1,target=1,saved=p.LocalTransparencyModifier}
				table.insert(forestParts,entry); forestByPart[p]=entry; p.LocalTransparencyModifier=1
				if p:GetAttribute("ForestCanopy") then
					local group=canopyGroups[p.Parent]
					if not group then
						local pivot=p.Parent:GetPivot()
						group={part=p,base=pivot,pivot=pivot,items={},cost=0,visible=false,canopy=true}
						canopyGroups[p.Parent]=group; table.insert(wind,group)
					end
					table.insert(group.items,{part=p,base=p.CFrame}); group.cost+=1
				end
			end
			if p:GetAttribute("Meadow") then
				table.insert(meadowParts,p); p.LocalTransparencyModifier=1; p:SetAttribute("MeadowTargetAlpha",1)
				if p:GetAttribute("MeadowWind") then
					local pivot=CFrame.new(0,p:GetAttribute("MeadowGroundY")-p.Position.Y,0)*p.CFrame
					table.insert(meadowWind,{part=p,base=p.CFrame,pivot=pivot,offset=pivot:ToObjectSpace(p.CFrame),visible=false})
				end
			elseif plant and not forestRole and not vistaRole then table.insert(wind,{part=p,base=p.CFrame,pivot=p.CFrame*CFrame.new(0,-p.Size.Y/2,0),height=p.Size.Y,cost=1,items={{part=p,base=p.CFrame}},visible=false}) end
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
		local p=effect("Part","AmbientMote_"..i,folder); p.Shape=Enum.PartType.Ball; p.Size=Vector3.new(.11,.11,.11)
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
		p.Material=i%3~=0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
		p.Color=i%3~=0 and Color3.fromRGB(238,226,140) or Color3.fromRGB(242,222,184); p.Transparency=1; motes[i]=p
	end
	local fx={bloom=0,rays=0}
	local function apply(sample,q,flow,elapsed)
		Lighting.ClockTime=sample.clock; Lighting.Brightness=sample.brightness; Lighting.Ambient=color(sample.ambient)
		Lighting.OutdoorAmbient=color(sample.outdoor); Lighting.GlobalShadows=q.shadows; Lighting.ExposureCompensation=sample.exposure
		Lighting.GeographicLatitude=26; Lighting.ShadowSoftness=sample.shadowSoftness
		Lighting.ColorShift_Top=color(sample.sun):Lerp(Color3.new(),.65); Lighting.ColorShift_Bottom=Color3.fromRGB(8,12,22)
		Lighting.EnvironmentDiffuseScale=sample.diffuse; Lighting.EnvironmentSpecularScale=sample.specular
		atmosphere.Color=color(sample.sky); atmosphere.Decay=color(sample.decay); atmosphere.Density=sample.density; atmosphere.Haze=sample.haze*q.haze; atmosphere.Glare=.08*(1-sample.rain); atmosphere.Offset=.15
		clouds.Cover=sample.cover; clouds.Density=sample.cloudDensity; clouds.Color=color(sample.cloudColor)
		correction.TintColor=color(sample.tint); correction.Saturation=sample.saturation; correction.Contrast=.025
		workspace.GlobalWind=Vector3.new(flow.x,0,flow.z)
		fx.bloom=Clock.effect(fx.bloom,q.bloom,elapsed); fx.rays=Clock.effect(fx.rays,q.rays,elapsed)
		-- Quality changes ease post effects, but hard light/particle caps still
		-- take effect immediately. No extra sources during a fade.
		bloom.Intensity=fx.bloom; bloom.Enabled=fx.bloom>.0001
		rays.Intensity=fx.rays*(1-sample.rain)*(1-sample.night); rays.Enabled=fx.rays>.0001
		-- AG63_BEGIN_APPLY
		-- Project from this frame's unmodified M7 sample, never the previous look.
		-- OFF executes none of these writes; the original apply above owns baseline.
		local post=Look.project(sample,look,self.quality,fx.bloom)
		if post then
			Lighting.Brightness=post.brightness; Lighting.ExposureCompensation=post.exposure
			Lighting.Ambient=color(post.ambient); Lighting.OutdoorAmbient=color(post.outdoor)
			Lighting.ColorShift_Top=color(post.sun):Lerp(Color3.new(),.65)
			atmosphere.Density=post.density; atmosphere.Haze=post.haze*q.haze
			correction.TintColor=color(post.tint); correction.Saturation=post.saturation; correction.Contrast=post.contrast
			bloom.Intensity=post.bloom; bloom.Enabled=post.bloom>.0001
		end
		-- AG63_END_APPLY
	end
	local lod=0; local step=0; local connection
	local transition=Transition.new({forward=true,clockAtPhase=function(phase) return Clock.at(Config,phase) end})
	function self.setQuality(name) if Config.quality[name] then self.quality=name; lod=1 end end
	-- AG63_BEGIN_METHOD
	function self.setLook(name)
		if not RunService:IsStudio() or not Look.valid(name) then return false end
		look=name; return true
	end
	-- AG63_END_METHOD
	function self.setReduceMotion(enabled) self.reduceMotion=enabled==true; lod=1 end
	function self.setPose(name)
		if RunService:IsStudio() and (name==nil or Config.poses[name]) and (name~=self.pose or self.previewStart or self.clockPhase or self.weather) then
			transition.begin(os.clock()); self.pose=name; self.previewStart=nil; self.clockPhase=nil; self.clockHour=nil; self.weather=nil
		end
	end
	function self.setTime(hour)
		if not RunService:IsStudio() then return false end
		local phase=hour~=nil and Clock.phase(Config,hour) or nil
		if hour~=nil and not phase then return false end
		local value=hour~=nil and hour%24 or nil
		if value==self.clockHour and not self.previewStart then return true end
		transition.begin(os.clock()); self.clockHour=value; self.clockPhase=phase; self.previewStart=nil
		return true
	end
	function self.setWeather(name)
		if not RunService:IsStudio() or (name~=nil and not Clock.weather[name]) then return false end
		if name==self.weather and not self.previewStart then return true end
		transition.begin(os.clock()); self.weather=name; self.previewStart=nil; return true
	end
	function self.setPreview(enabled)
		if RunService:IsStudio() and (enabled==true)~=(self.previewStart~=nil) then
			transition.begin(os.clock()); self.previewStart=enabled and os.clock() or nil
		end
	end
	function self.stats()
		local counts={lights=0,rain=0,motes=0,wind=0,emitters=0,fog=0,glints=0,rainbow=0,stars=0,moon=0,assetFailures=self.assetFailures}
		for _,l in ipairs(lights) do if l.Enabled then counts.lights+=1 end end
		for _,l in ipairs(sunPools) do if l.Enabled then counts.lights+=1 end end
		for _,p in ipairs(self.rain) do if p.Transparency<1 then counts.rain+=1 end end
		for _,p in ipairs(motes) do if p.Transparency<1 then counts.motes+=1 end end
		for _,w in ipairs(wind) do if w.moving then counts.wind+=w.cost end end
		counts.meadow=#meadowParts; counts.meadowMoving=0; counts.meadowVisible=0
		for _,w in ipairs(meadowWind) do if (w.weight or 0)>0 then counts.meadowMoving+=1 end end
		for _,p in ipairs(meadowParts) do if p.LocalTransparencyModifier<.99 then counts.meadowVisible+=1 end end
		for _,v in ipairs(fog) do if v.image.ImageTransparency<1 then counts.fog+=1 end end
		for _,p in ipairs(glints) do if p.Transparency<1 then counts.glints+=1 end end
		counts.rainbow=rainbow.image.ImageTransparency<1 and 1 or 0
		for _,v in ipairs(stars) do if v.image.ImageTransparency<1 then counts.stars+=1 end end
		counts.moon=moon.image.ImageTransparency<1 and 1 or 0
		counts.forest=#forestParts; counts.forestVisible=0
		for _,f in ipairs(forestParts) do if f.alpha<.99 then counts.forestVisible+=1 end end
		counts.vista=#vistaParts; counts.vistaVisible=0
		for _,v in ipairs(vistaParts) do if v.alpha<.99 then counts.vistaVisible+=1 end end
		-- AG63_BEGIN_STATS
		counts.postFXLook=look
		-- AG63_END_STATS
		return counts
	end
	function self.setAnnotationsEnabled(enabled) annotations=enabled~=false; labelsDirty=1 end
	function self.update(dt)
		step+=dt; lod+=dt; labelsDirty+=dt; if step<1/30 then return end; local elapsed=step; step=0
		local camera=workspace.CurrentCamera; if not camera then return end
		local character=Players.LocalPlayer.Character
		local avatar=character and character:FindFirstChild("HumanoidRootPart")
		local lightOrigin=avatar and avatar.Position or camera.Focus.Position
		local time=workspace:GetServerTimeNow(); local now=os.clock()
		local target=self.previewStart and State.preview(Config,now-self.previewStart) or State.sample(Config,time,self.pose)
		if not self.previewStart and (self.clockPhase or self.weather) then
			local weather=self.weather and Clock.weather[self.weather] or target
			target=State.at(Config,self.clockPhase or target.phase,weather.rain,weather)
		end
		local sample=transition.sample(target,now); local q=State.quality(Config,self.quality,self.reduceMotion)
		local flow=State.wind(sample,time,self.reduceMotion)
		apply(sample,q,flow,elapsed)
		local sun=Lighting:GetSunDirection(); local sunlight=State.sunVisibility(sample,sun.Y)
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
				local hidden=detail>q.detail or ((detail>1 or p:GetAttribute("Meadow")) and (p.Position-camera.CFrame.Position).Magnitude>q.distance)
				local f=forestByPart[p]
				local v=vistaByPart[p]
				if v then
					v.target=Vista.alpha(v.role,self.quality,(camera.CFrame.Position-p.Position).Magnitude)
				elseif f then
					local delta=camera.CFrame.Position-f.anchor
					f.target=ForestLOD.alpha(f.role,self.quality,Vector2.new(delta.X,delta.Z).Magnitude)
				elseif p:GetAttribute("Meadow") then p:SetAttribute("MeadowTargetAlpha",hidden and 1 or 0)
				else p.LocalTransparencyModifier=hidden and 1 or 0 end
			end
			table.sort(wind,function(a,b) return (a.base.Position-camera.CFrame.Position).Magnitude<(b.base.Position-camera.CFrame.Position).Magnitude end)
			for _,w in ipairs(meadowWind) do
				local screen,onScreen=camera:WorldToViewportPoint(w.base.Position)
				local distance=(w.base.Position-camera.CFrame.Position).Magnitude
				w.visible=onScreen and screen.Z>0 and distance<65 and w.part:GetAttribute("MeadowTargetAlpha")==0
				w.rank=distance+(w.visible and 0 or 10000)
			end
			table.sort(meadowWind,function(a,b) return a.rank<b.rank end)
			local center=camera.CFrame.Position
			for i,p in ipairs(self.rain) do
				local x,z=RainField.world(i,center.X,center.Z)
				p:SetAttribute("GroundY",surface(x,z)); p:SetAttribute("RainX",x); p:SetAttribute("RainZ",z)
			end
		end
		for _,group in ipairs({lanternSlots,sunSlots}) do
			for _,e in ipairs(group) do e.distance=(e.light.Parent.Position-lightOrigin).Magnitude end
		end
		LightSlots.step(lanternSlots,math.max(0,q.lights-State.sunSlots(self.quality)),q.distance,elapsed)
		LightSlots.step(sunSlots,State.sunSlots(self.quality),q.distance,elapsed)
		for _,e in ipairs(lanternSlots) do
			e.light.Enabled=e.weight>0; e.light.Brightness=(.10+sample.night*1.53)*e.weight
		end
		for _,e in ipairs(sunSlots) do
			e.light.Enabled=e.weight>0; e.light.Brightness=.42*sunlight*e.weight
		end
		for _,p in ipairs(meadowParts) do
			local target=p:GetAttribute("MeadowTargetAlpha") or 0; local alpha=p.LocalTransparencyModifier
			if alpha~=target then p.LocalTransparencyModifier=alpha+math.clamp(target-alpha,-elapsed*2,elapsed*2) end
		end
		for _,f in ipairs(forestParts) do
			if f.alpha~=f.target then f.alpha=ForestLOD.step(f.alpha,f.target,elapsed); f.part.LocalTransparencyModifier=f.alpha end
		end
		local windowColor=color(Vista.window(sample))
		for _,v in ipairs(vistaParts) do
			if v.alpha~=v.target then v.alpha=ForestLOD.step(v.alpha,v.target,elapsed); v.part.LocalTransparencyModifier=v.alpha end
			if v.window then v.part.Color=windowColor end
		end
		MeadowMotion.step(meadowWind,self.reduceMotion and 0 or (Meadow.maxMoving[self.quality] or Meadow.maxMoving.reduced),elapsed)
		for _,w in ipairs(meadowWind) do
			if w.weight>0 then
				local a=Meadow.angle(time,w.base.Position.X,w.base.Position.Z,flow.strength)*w.weight
				w.part.CFrame=w.pivot*CFrame.Angles(a*.38,0,a)*w.offset
			elseif w.wasMoving then w.part.CFrame=w.base end
			w.wasMoving=w.weight>0
		end
		-- Imported canopies move as one group; every moving mesh costs one slot.
		for _,w in ipairs(wind) do
			w.visible=w.part.LocalTransparencyModifier<.99 and (w.base.Position-camera.CFrame.Position).Magnitude<q.distance
		end
		MeadowMotion.step(wind,q.motion,elapsed)
		for _,w in ipairs(wind) do
			if w.weight>0 then
				local a=Meadow.angle(time,w.base.Position.X,w.base.Position.Z,flow.strength)*.075*w.weight
				local transform=w.pivot*CFrame.Angles(a*.3,0,a)*w.pivot:Inverse()
				for _,item in ipairs(w.items) do item.part.CFrame=transform*item.base end
			elseif w.moving then for _,item in ipairs(w.items) do item.part.CFrame=item.base end end
			w.moving=w.weight>0
		end
		for i,p in ipairs(motes) do
			local m=State.pollen(i,time,sample,flow); local position=Vector3.new(m.x,pollenGround[m.anchor]+m.y,m.z)
			local visible=i<=q.motes and (position-camera.CFrame.Position).Magnitude<q.distance
			p.Transparency=visible and 1-m.alpha or 1; if visible then p.Position=position end
			p.Color=m.firefly and color({168+70*sample.warm,224,181-50*sample.warm}) or color({235,229-33*sample.warm,213-55*sample.warm})
		end
		local cameraPosition=camera.CFrame.Position
		for i,p in ipairs(self.rain) do
			local x,z=RainField.world(i,cameraPosition.X,cameraPosition.Z)
			if math.abs(x-(p:GetAttribute("RainX") or x))>2 or math.abs(z-(p:GetAttribute("RainZ") or z))>2 or p:GetAttribute("GroundY")==nil then
				p:SetAttribute("GroundY",surface(x,z))
			end
			p:SetAttribute("RainX",x); p:SetAttribute("RainZ",z)
			local visible=RainField.visible(i,q.rain,sample.rain,Boundary.contains(x,z,8))
			p.Transparency=visible and (1-sample.rain*.52) or 1
			if visible then
				local fall=(time*1.15+i*.173)%1; local y=p:GetAttribute("GroundY") or .5
				-- Splashes reuse the same rain slots; no emitters or additional pool.
				if fall>.91 then
					local radius=.08+(fall-.91)*3; p.Size=Vector3.new(radius,.025,radius)
					p.CFrame=CFrame.new(x,y+.06,z); p.Transparency=1-sample.rain*.38*(1-(fall-.91)/.09)
				else
					p.Size=Vector3.new(.045,.85,.045); p.CFrame=CFrame.new(x+(1-fall)*flow.x*.18,y+.2+(1-fall)*24,z+(1-fall)*flow.z*.18)*CFrame.Angles(math.atan(flow.z*.007),0,-math.atan(flow.x*.007))
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
			p.Color=color({228-99*sample.night,232-14*sample.night,190+34*sample.night})
		end
		local horizontal=Vector3.new(-sun.X,0,-sun.Z)
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
	local requests={}
	if RunService:IsStudio() then
		-- AG63_BEGIN_INSPECT
		-- Read-only native QA bridge to the actual owner (Command Bar has a
		-- separate require cache). It never changes quality, weather or rewards.
		lookInspect=Instance.new("BindableFunction"); lookInspect.Name="PostFXInspect"
		lookInspect.OnInvoke=function() return self.stats(),self.quality,self.reduceMotion end
		lookInspect.Parent=root
		-- AG63_END_INSPECT
		-- Local Studio review inputs feed this owner; no helper, remote or save.
		-- Direct Lighting.ClockTime writes are intentionally not a second API.
		local function request()
			-- AG63_BEGIN_REQUEST
			local requestedLook=Look.request(root:GetAttribute("EnvironmentReview"))
			if requestedLook then self.setLook(requestedLook); return end
			-- AG63_END_REQUEST
			local command=Clock.request(Config,root:GetAttribute("EnvironmentReview"))
			if not command then return end
			local method=({pose=self.setPose,time=self.setTime,weather=self.setWeather,preview=self.setPreview})[command.kind]
			method(command.value)
		end
		table.insert(requests,root:GetAttributeChangedSignal("EnvironmentReview"):Connect(request))
		request()
	end
	function self.stop()
		if active~=self then return end; active=nil
		-- AG63_BEGIN_STOP
		if lookInspect then lookInspect:Destroy(); lookInspect=nil end
		-- AG63_END_STOP
		if connection then connection:Disconnect() end
		added:Disconnect()
		labelAdded:Disconnect()
		for _,pending in pairs(pendingPanes) do pending:Disconnect() end
		for _,request in ipairs(requests) do request:Disconnect() end
		if not root:GetAttribute("WorldContextOwned") then
			for _,l in ipairs(labels) do l.gui.Enabled=l.enabled end
		end
		for k,v in pairs(saved) do Lighting[k]=v end
		workspace.GlobalWind=savedWind
		for _,p in ipairs(self.parts) do p.LocalTransparencyModifier=0 end
		for _,f in ipairs(forestParts) do f.part.LocalTransparencyModifier=f.saved end
		for _,v in ipairs(vistaParts) do v.part.LocalTransparencyModifier=v.saved; v.part.Color=v.color end
		for _,w in ipairs(wind) do for _,item in ipairs(w.items) do item.part.CFrame=item.base end end
		for _,w in ipairs(meadowWind) do w.part.CFrame=w.base end
		for _,v in ipairs(wetSurfaces) do v.part.Color=v.color end
		for _,l in ipairs(lights) do l:Destroy() end
		atmosphere:Destroy(); sky:Destroy(); clouds:Destroy(); correction:Destroy(); bloom:Destroy(); rays:Destroy(); folder:Destroy()
		for _,v in ipairs(displaced) do v.object.Parent=v.parent end
	end
	self.update(1); connection=RunService.RenderStepped:Connect(self.update)
	return self
end
return View
