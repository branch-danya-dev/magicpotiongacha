--!nonstrict
-- Replaces only the generated QA wind entry point. One scheduler includes the willow.
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Visual=require(script.Parent.TreeVisualConfig)
local Model=require(script.Parent.VegetationTreeModel)
local Appearance=require(script.Parent.Appearance)
local Controller=require(script.Parent.VegetationWindController)
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Data=require(Shared.VegetationData)
local Pixels=require(Shared.VegetationPixels)
local M={}
function M.start(root,origin,willow)
	assert(Run:IsStudio() and workspace:GetAttribute("VegetationV2QA"))
	local self={quality="reduced",reduceMotion=false,error=nil,ready=false}
	local libraries,trees={},{};local wind;local dead=false
	local palette="Natural";local variant="Natural";local overrides={};local folder=Instance.new("Folder");folder.Name="VegetationV2Candidates";folder.Parent=root
	local catalog=table.clone(Visual.species)
	for _,data in ipairs(Data)do
		local rig,phases={},{};for _,b in ipairs(data.variants[1].bones)do rig[b.name]=b.role;phases[b.name]=tonumber(string.match(b.name,"%d+$")) or 0 end
		catalog[data.key]={rig=rig,phaseIndices=phases,wind={amplitude=.055,speed=.75,gustResponse=.45,smoothing=1.1,phaseSpread=.7,branchDelay=0,
			budgets={full={hz=30,distance=180,trees=8,scale=1},reduced={hz=15,distance=125,trees=4,scale=.7},minimal={hz=6,distance=70,trees=1,scale=.35}}}}
	end
	local function emit(kind,value)print("VEGETATION_V2_"..kind,Http:JSONEncode(value))end
	local function style()
		local values=table.clone(overrides);values.GeometryVariant=variant
		return Appearance.resolve(palette,values)
	end
	local function release()
		if wind then wind.stop();wind=nil end
		for _,lib in ipairs(libraries)do lib.destroy()end;table.clear(libraries);table.clear(trees)
	end
	local function refresh()
		if wind then wind.setQuality(self.quality);wind.setReduceMotion(self.reduceMotion)end
		for i,tree in ipairs(trees)do libraries[i].apply(tree,style(),self.quality)end
	end
	local function rebuild()
		release();self.ready=false;self.error=nil
		local ok,err=pcall(function()
			for i,data in ipairs(Data)do
				local lib=Model.load(data,Pixels[data.key],variant);libraries[i]=lib
				-- Presentation only; existing stations/routes/colliders are untouched.
				local p=i==1 and Vector3.new(-49,.38,42) or Vector3.new(43,.38,46)
				trees[i]=lib.create(folder,CFrame.new(origin+p),data.key.."-pilot",style(),self.quality)
			end
		end)
		if not ok then release();self.error=tostring(err);emit("LOAD_BLOCKED",{error=self.error})end
		local all={willow};for _,tree in ipairs(trees)do table.insert(all,tree)end
		local started,owner=pcall(Controller.start,all,catalog)
		if started then wind=owner else
			release();self.error=tostring(owner);emit("RIG_BLOCKED",{error=self.error})
			wind=Controller.start({willow},catalog)
		end
		refresh();self.ready=ok and started
	end
	function self.stats()
		local meshes,images,instances=0,0,#folder:GetDescendants()
		for _,lib in ipairs(libraries)do meshes+=#lib.meshes;images+=#lib.images end
		return {ready=self.ready,error=self.error,palette=palette,variant=variant,quality=self.quality,reduceMotion=self.reduceMotion,
			candidates=#trees,meshes=meshes,images=images,instances=instances,wind=wind and wind.stats(),newLights=0}
	end
	function self.setQuality(q)assert(q=="full" or q=="reduced" or q=="minimal");self.quality=q;refresh()end
	function self.setReduceMotion(v)self.reduceMotion=v==true;refresh()end
	local running=false
	local function checks()
		assert(not running and self.ready,"Preview unavailable or checks already running")
		assert(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom,"Choose a familiar before ordinary-camera checks")
		running=true
		task.spawn(function()
			local q,m,p,v,o=self.quality,self.reduceMotion,palette,variant,overrides
			local ok,err=pcall(function()
				local baseline=self.stats();local camera=workspace.CurrentCamera
				local clock=game:GetService("Lighting").ClockTime
				for i=1,20 do
					assert(not dead,"Preview disposed");self.setQuality(({"full","reduced","minimal"})[(i-1)%3+1]);self.setReduceMotion(i%2==0)
					task.wait(.1);local s=self.stats()
					assert(s.meshes==baseline.meshes and s.images==baseline.images and s.instances==baseline.instances)
					assert(s.wind.connections==1)
					if self.reduceMotion then for _,tree in ipairs(trees)do for _,bone in ipairs(tree:GetDescendants())do if bone:IsA("Bone")then assert(bone.Transform==CFrame.identity)end end end end
				end
				for _,name in ipairs({"Natural","Enchanted","Blossom"})do palette=name;refresh();assert(self.ready)end
				for _,name in ipairs({"Windswept","Natural"})do
					variant=name;rebuild();assert(self.ready,self.error);assert(self.stats().images==2)
					for _,tree in ipairs(trees)do for _,part in ipairs(tree:GetChildren())do if part:IsA("BasePart")then assert(not part.CanCollide and not part.CanTouch)end end end
				end
				self.setQuality("full");self.setReduceMotion(false);task.wait(.6)
				local before={};for _,tree in ipairs(trees)do for _,bone in ipairs(tree:GetDescendants())do if bone:IsA("Bone")then before[bone]=bone.Transform end end end
				task.wait(.5);local changed=0
				for bone,transform in pairs(before)do if bone.Name=="Root"then assert(bone.Transform==CFrame.identity)elseif bone.Transform~=transform then changed+=1 end end
				if workspace.GlobalWind.Magnitude>.1 then assert(changed>0,"No wind deformation")end
				local timing={}
				for _,quality in ipairs({"full","reduced","minimal"})do
					self.setQuality(quality);local frames={};local samples={};local previous=wind.updates
					for _=1,90 do assert(not dead);table.insert(frames,Run.RenderStepped:Wait()*1000);if wind.updates~=previous then table.insert(samples,wind.lastMs);previous=wind.updates end end
					table.sort(frames);table.sort(samples)
					timing[quality]={frameP50ms=frames[45],frameP95ms=frames[86],windP95ms=samples[math.ceil(#samples*.95)],activeTrees=wind.activeTrees,clientMemoryMiB=game:GetService("Stats"):GetTotalMemoryUsageMb()}
				end
				assert(camera==workspace.CurrentCamera and camera.CameraType==Enum.CameraType.Custom)
				emit("CHECK_PASS",{switches=20,movingBones=changed,timing=timing,clockAtStart=clock,artAcceptance="PENDING",stats=self.stats()})
			end)
			if not dead then palette=p;variant=v;overrides=o;self.quality=q;self.reduceMotion=m;rebuild()end
			if not ok then emit("CHECK_FAIL",{error=tostring(err)})end;running=false
		end)
		return true
	end
	local control=Instance.new("BindableFunction");control.Name="VegetationQA";control.Parent=root
	control.OnInvoke=function(action,value)
		assert(not dead,"Preview disposed")
		if action=="palette"then Appearance.resolve(value);palette=value;refresh()
		elseif action=="variant"then Appearance.resolve(palette,{GeometryVariant=value});variant=value;rebuild()
		elseif action=="appearance"then
			Appearance.resolve(palette,value);overrides=table.clone(value)
			if value.GeometryVariant and value.GeometryVariant~=variant then variant=value.GeometryVariant;rebuild()else refresh()end
		elseif action=="quality"then self.setQuality(value)
		elseif action=="motion"then self.setReduceMotion(value)
		elseif action=="checks"then return checks()
		elseif action=="stop"then self.stop()
		elseif action~="inspect"then error("Unknown vegetation action")end
		emit("STATE",self.stats());return self.stats()
	end
	function self.stop()
		if dead then return end;dead=true;release();folder:Destroy();control:Destroy();self.ready=false
	end
	rebuild();emit("READY",self.stats())
	return self
end
return M
