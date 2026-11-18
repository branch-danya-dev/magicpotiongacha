--!nonstrict
-- Three rigged instances, shared source pools and one existing bone scheduler.
-- Static Quaternius foliage stays with EnvironmentView; no mesh has two owners.
local Run=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local P=require(Shared.LandscapePlan)
local Data=require(Shared.VegetationData)
local Pixels=require(Shared.VegetationPixels)
local Model=require(script.Parent.VegetationTreeModel)
local Appearance=require(script.Parent.Appearance)
local Controller=require(script.Parent.VegetationWindController)
local M={}
function M.start(root,origin)
	assert(Run:IsStudio() and workspace:GetAttribute("LandscapePilotQA"))
	local self={quality="reduced",reduceMotion=false,ready=false,error=nil}
	local folder=Instance.new("Folder");folder.Name="LandscapeRigged";folder.Parent=root
	local libraries,entries,catalog={},{},{};local wind;local dead=false
	local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.Terrain}
	local function release()
		if wind then wind.stop();wind=nil end
		for _,lib in pairs(libraries)do lib.destroy()end;table.clear(libraries);table.clear(entries)
	end
	local function style(t)
		local c=P.palette
		return Appearance.resolve("Natural",{GeometryVariant=t.variant,BarkColor=c.bark,
			LeafColor=t.magic and c.magicLeaf or c.leaf,LeafSecondaryColor=t.magic and c.magicSecondary or c.secondary,
			MagicGlowColor=c.glow,MagicGlowIntensity=t.magic and c.glowIntensity or 0,WindStrength=t.wind})
	end
	local ok,err=pcall(function()
		local lookup={};for _,data in ipairs(Data)do lookup[data.key]=data end
		for _,t in ipairs(P.trees)do if t.source then
			local data=assert(lookup[t.source]);local key=t.source.."/"..t.variant
			if not libraries[key]then libraries[key]=Model.load(data,Pixels[t.source],t.variant)end
			if not catalog[t.source]then
				local rig,phases={},{};for _,b in ipairs(data.variants[1].bones)do rig[b.name]=b.role;phases[b.name]=tonumber(string.match(b.name,"%d+$")) or 0 end
				catalog[t.source]={rig=rig,phaseIndices=phases,wind={amplitude=.045,speed=.65,gustResponse=.35,smoothing=1.3,phaseSpread=.7,branchDelay=0,budgets=P.windBudgets(t.source)}}
			end
			local hit=workspace:Raycast(origin+Vector3.new(t.x,20,t.z),Vector3.new(0,-40,0),params)
			assert(hit,"Unsupported rigged root: "..t.id)
			local at=CFrame.new(origin.X+t.x,hit.Position.Y-.035,origin.Z+t.z)*CFrame.Angles(0,math.rad(t.yaw),0)
			local s=style(t);local tree=libraries[key].create(folder,at,t.id,s,self.quality);tree:ScaleTo(t.scale)
			tree:SetAttribute("LandscapeGeometry",t.variant);tree:SetAttribute("LandscapeScale",t.scale)
			local parts={};for _,p in ipairs(tree:GetChildren())do if p:IsA("MeshPart")then table.insert(parts,p)end end
			entries[t.id]={tree=tree,lib=libraries[key],style=s,parts=parts,rest=at,descriptor=t}
		end end
		local trees={};for _,e in pairs(entries)do table.insert(trees,e.tree)end
		wind=Controller.start(trees,catalog);wind.setQuality(self.quality)
	end)
	if not ok then release();self.error=tostring(err);warn("LANDSCAPE_LOAD_BLOCKED",self.error)
	else self.ready=root:GetAttribute("LandscapeStaticReady")==true;self.error=root:GetAttribute("LandscapeStaticError")end
	function self.update()
		-- Called by the inherited 5 Hz additions poll, no additional frame loop.
		if dead or not workspace.CurrentCamera then return end
		for _,e in pairs(entries)do
			local distance=(e.tree:GetPivot().Position-workspace.CurrentCamera.CFrame.Position).Magnitude
			for _,p in ipairs(e.parts)do
				local target=P.detailAlpha(p:GetAttribute("VegetationRole"),self.quality,distance)
				p.LocalTransparencyModifier+=math.clamp(target-p.LocalTransparencyModifier,-.4,.4)
			end
		end
	end
	local function refresh()
		if wind then wind.setQuality(self.quality);wind.setReduceMotion(self.reduceMotion)end
		for _,e in pairs(entries)do e.lib.apply(e.tree,e.style,self.quality)end;self.update()
	end
	function self.setQuality(q)assert(P.budgets[q]);self.quality=q;refresh()end
	function self.setReduceMotion(v)self.reduceMotion=v==true;refresh()end
	function self.stats()
		local meshes,images,trees=0,0,0
		for _,lib in pairs(libraries)do meshes+=#lib.meshes;images+=#lib.images end
		for _ in pairs(entries)do trees+=1 end
		return {ready=self.ready,error=self.error,quality=self.quality,reduceMotion=self.reduceMotion,riggedTrees=trees,
			meshes=meshes,images=images,instances=#folder:GetDescendants(),staticParts=root:GetAttribute("LandscapeStaticParts"),
			wind=wind and wind.stats(),newLights=0,clientMemoryMiB=game:GetService("Stats"):GetTotalMemoryUsageMb()}
	end
	local running=false
	local function checks()
		assert(self.ready and not running,"Grove unavailable or checks already running")
		assert(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom,"Choose a familiar first")
		running=true
		task.spawn(function()
			local q,m=self.quality,self.reduceMotion;local before=self.stats();local timings={}
			local passed,message=pcall(function()
				for i=1,20 do
					assert(not dead);self.setQuality(({"full","reduced","minimal"})[(i-1)%3+1]);self.setReduceMotion(i%2==0);task.wait(.1)
					local s=self.stats();assert(s.meshes==before.meshes and s.images==before.images and s.instances==before.instances)
					assert(s.wind.connections==1)
					for _,e in pairs(entries)do
						assert((e.tree:GetPivot().Position-e.rest.Position).Magnitude<.001,"Root drift")
						for _,p in ipairs(e.parts)do assert(not p.CanCollide and not p.CanTouch and not p.CanQuery)end
						for _,b in ipairs(e.tree:GetDescendants())do if b:IsA("Bone") and (b.Name=="Root" or self.reduceMotion)then assert(b.Transform==CFrame.identity)end end
					end
				end
				for _,quality in ipairs({"full","reduced","minimal"})do
					self.setQuality(quality);self.setReduceMotion(false);local frames,updates={},{};local last=wind.updates
					for _=1,120 do
						assert(not dead);table.insert(frames,Run.RenderStepped:Wait()*1000)
						if wind.updates~=last then table.insert(updates,wind.lastMs);last=wind.updates end
					end
					table.sort(frames);table.sort(updates)
					timings[quality]={frameP50ms=frames[60],frameP95ms=frames[114],windP95ms=updates[math.ceil(#updates*.95)],state=self.stats()}
				end
			end)
			if not dead then self.setQuality(q);self.setReduceMotion(m)end;running=false
			print(passed and "LANDSCAPE_CHECK_PASS" or "LANDSCAPE_CHECK_FAIL",game:GetService("HttpService"):JSONEncode({error=message,timings=timings,ownerArt="PENDING"}))
		end)
		return true
	end
	local control=Instance.new("BindableFunction");control.Name="LandscapeQA";control.Parent=root
	control.OnInvoke=function(action,value)
		assert(not dead)
		if action=="checks"then return checks()
		elseif action=="appearance"then
			local e=assert(entries[value.id],"Unknown instance");local values=table.clone(e.style)
			for k,v in pairs(value.values)do values[k]=v end
			assert(values.GeometryVariant==e.descriptor.variant,"Geometry changes require a reproducible rebuild")
			e.style=Appearance.resolve("Natural",values);refresh()
		elseif action=="stop"then self.stop()
		elseif action~="inspect"then error("Use CurrentGameQA for shared quality and motion")end
		return self.stats()
	end
	function self.stop()if dead then return end;dead=true;release();folder:Destroy();control:Destroy();self.ready=false;root:SetAttribute("LandscapeRiggedReady",false)end
	root:SetAttribute("LandscapeRiggedReady",self.ready)
	print("LANDSCAPE_CLIENT_STATE",game:GetService("HttpService"):JSONEncode(self.stats()))
	return self
end
return M
