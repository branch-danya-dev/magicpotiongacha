--!nonstrict
-- Opt-in separate native-check build. Local visual fixtures only; no grants/remotes/saves.
local Run = game:GetService("RunService")
if not Run:IsStudio() then return end
local Players = game:GetService("Players")
local Storage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local player = Players.LocalPlayer
local scripts = player:WaitForChild("PlayerScripts"):WaitForChild("PotionTycoon")
local View = require(scripts:WaitForChild("FamiliarRigView"))
local Registry = require(scripts:WaitForChild("FamiliarVisualRegistry"))
local Environment = require(scripts:WaitForChild("EnvironmentController"))
local folder = workspace:WaitForChild("AG74Preview")
local inspect = folder:WaitForChild("Inspect")
local originalQuality, originalMotion = Environment.quality, Environment.reduceMotion
local originalAnimations = Registry.slime.animations
local fixtureFolder = Instance.new("Folder"); fixtureFolder.Name = "AG74NativeFixtures"; fixtureFolder.Parent = workspace
local temporary = {}
local anchor, saved, timer, renamedTemplate
local function record(name, data) print("AG74_CHECK "..Http:JSONEncode({name=name,data=data})) end
local function waitFor(predicate, seconds)
	local deadline=os.clock()+seconds
	repeat if predicate() then return end; Run.Heartbeat:Wait() until os.clock()>deadline
	error("native condition timed out",2)
end
local function livePets()
	local pets={}; for _,child in folder:GetChildren() do if child:IsA("Model") then table.insert(pets,child) end end
	return pets
end
local function ready()
	local result=inspect:Invoke()
	return #result.pets==2 and result.pets[1].ready and result.pets[2].ready
end
local function stopCount()
	local count=0
	for _,m in livePets() do count+=#m:FindFirstChildWhichIsA("Animator",true):GetPlayingAnimationTracks() end
	return count
end
local function flag(value) workspace:SetAttribute("GreenSlimeRigPreviewEnabled",value) end
local function restoreAnchor()
	if anchor and saved then
		anchor:SetAttribute("WorkerId",saved.id); anchor:SetAttribute("WorkerSpecies",saved.species)
		for _,key in {"HaulFrom","HaulTo","HaulProgress","WorkerReacting"} do anchor:SetAttribute(key,saved[key]) end
	end
end
local ok, problem=xpcall(function()
	waitFor(ready,20)
	record("loaded",inspect:Invoke())
	local world=workspace.PotionTycoonWorld
	local plots,owned=0,0
	for _,p in world:GetChildren() do
		if p.Name:match("^Plot") then plots+=1 end
		if p:GetAttribute("OwnerUserId")==player.UserId then owned+=1 end
	end
	for _,m in livePets() do
		assert(m:GetAttribute("QAOwnerUserId")==player.UserId,"preview owner")
		local bones=0
		for _,v in m:GetDescendants() do
			if v:IsA("Bone") then bones+=1 end
			if v:IsA("BasePart") then assert(not v.CanCollide and not v.CanTouch and not v.CanQuery,"inert proxy") end
		end
		assert(bones==8,"eight bones")
	end
	record("isolation",{plots=plots,owned=owned,previewPets=#livePets(),placeId=game.PlaceId,gameId=game.GameId})
	local elapsed,frames,maxFrame=0,0,0
	local head=livePets()[1]:FindFirstChild("Head",true)
	local initial=head.Transform; local moved=false; local mixed=false
	timer=Run.Heartbeat:Connect(function(dt)
		elapsed+=dt; frames+=1; maxFrame=math.max(maxFrame,dt)
		if (head.Transform.Position-initial.Position).Magnitude>.001 then moved=true end
		for _,m in livePets() do
			local weighted=0
			for _,track in m:FindFirstChildWhichIsA("Animator",true):GetPlayingAnimationTracks() do
				if track.WeightCurrent>.01 and track.WeightCurrent<.99 then weighted+=1 end
			end
			if weighted==2 then mixed=true end
		end
	end)
	waitFor(function()
		local states=inspect:Invoke(); local found={}
		for _,p in states.pets do for key in p.transitions do found[key]=true end end
		return found["1-1"] and found["1-2"] and found["2-1"] and found["2-2"]
	end,65)
	timer:Disconnect()
	assert(moved,"native Head deformation")
	assert(mixed,"native crossfade weights overlap")
	record("fourTransitions",inspect:Invoke())
	record("desktopTiming",{heartbeatHz=frames/elapsed,maxHeartbeatMs=maxFrame*1000,sampleSeconds=elapsed,headMoved=moved,crossfadeOverlap=mixed})
	for _,quality in {"full","reduced","minimal"} do
		Environment.setQuality(quality); task.wait(.5)
		local n=stopCount(); assert(quality=="minimal" and n==0 or quality~="minimal" and n>=2,"quality tracks")
		record("quality",{quality=quality,playing=n,count=View.count})
	end
	Environment.setQuality("reduced"); Environment.setReduceMotion(true); task.wait(.5)
	assert(stopCount()==0,"reduce motion stops animation")
	Environment.setReduceMotion(false); task.wait(.5); assert(stopCount()>=2)
	record("reduceMotion",true)
	workspace:SetAttribute("AG74React",true); task.wait(.5); assert(stopCount()==0,"reaction interrupt")
	workspace:SetAttribute("AG74React",nil); task.wait(.5); assert(stopCount()>=2)
	record("reactResume",true)
	-- Existing renderer receives a LOCAL replicated-attribute fixture, never a server assignment.
	for _,v in world:GetDescendants() do
		if v:IsA("BasePart") and v:GetAttribute("StationId") and not v:GetAttribute("WorkerId") then anchor=v; break end
	end
	assert(anchor,"available visual anchor")
	saved={id=anchor:GetAttribute("WorkerId"),species=anchor:GetAttribute("WorkerSpecies")}
	for _,key in {"HaulFrom","HaulTo","HaulProgress","WorkerReacting"} do saved[key]=anchor:GetAttribute(key) end
	anchor:SetAttribute("WorkerSpecies","slime"); anchor:SetAttribute("WorkerId","AG74_LOCAL_VISUAL_ONLY")
	local visuals=workspace.LocalFamiliarVisuals
	waitFor(function() for _,m in visuals:GetChildren() do if m:IsA("Model") and m:GetAttribute("AG74Loaded") then return true end end return false end,15)
	local function proxyVisible()
		for _,p in visuals:GetChildren() do if p.Name=="WorkerProxy" and p.Transparency==0 then return true end end
		return false
	end
	-- Loading finishes on Heartbeat; the existing renderer swaps visuals on RenderStepped.
	waitFor(function() return not proxyVisible() end,3)
	record("oldProxyHidden",true)
	local rig=visuals:FindFirstChild("GreenSlimeVisual")
	local animator=rig:FindFirstChildWhichIsA("Animator",true)
	anchor:SetAttribute("HaulFrom",anchor.Position); anchor:SetAttribute("HaulTo",anchor.Position+Vector3.new(2,0,0)); anchor:SetAttribute("HaulProgress",.5)
	task.wait(.4); assert(#animator:GetPlayingAnimationTracks()==0,"haul interrupts idle")
	anchor:SetAttribute("HaulFrom",nil); anchor:SetAttribute("HaulTo",nil); anchor:SetAttribute("HaulProgress",nil)
	anchor:SetAttribute("WorkerReacting",true); task.wait(.4); assert(#animator:GetPlayingAnimationTracks()==0,"worker reaction interrupts idle")
	anchor:SetAttribute("WorkerReacting",false); task.wait(.4); assert(#animator:GetPlayingAnimationTracks()>=1,"worker idle resumes")
	record("workerHaulReactResume",true)
	flag(false); waitFor(function() return View.count==0 end,3); waitFor(proxyVisible,3)
	record("flagOffRestoresOldProxy",{count=View.count,proxyVisible=proxyVisible(),previewPets=#livePets()})
	restoreAnchor(); anchor=nil
	local template=Storage.FamiliarTemplates.GreenSlime; renamedTemplate=template; template.Name="AG74TemporarilyUnavailable"
	flag(true); task.wait(.3); assert(View.create("slime",fixtureFolder)==nil,"missing template fails closed")
	template.Name="GreenSlime"; flag(false); task.wait(.3); flag(true); waitFor(ready,15)
	record("missingTemplateRecovery",true)
	-- Separate controlled bad ID verifies failure cleanup without requesting an upload.
	Registry.slime.animations={"rbxassetid://0","rbxassetid://0"}
	local broken=assert(View.create("slime",fixtureFolder,74)); table.insert(temporary,broken)
	waitFor(function() return broken.disposed end,15)
	assert(broken.failed and #broken.tracks==0 and #broken.animations==0,"failed load cleanup")
	Registry.slime.animations=originalAnimations
	record("missingAnimationFallback",{failed=broken.failed,disposed=broken.disposed,count=View.count})
	local extra=assert(View.create("slime",fixtureFolder,75)); table.insert(temporary,extra)
	waitFor(function() return extra.ready end,15); extra.update(CFrame.new(0,-100,0),true)
	extra.model:Destroy(); assert(extra.disposed and #extra.tracks==0,"remove cleanup")
	local again=assert(View.create("slime",fixtureFolder,76)); table.insert(temporary,again)
	waitFor(function() return again.ready end,15); again.destroy(); again.destroy()
	assert(View.count==2,"recreate without count leak")
	record("removeRecreate",{count=View.count})
	local capped={}
	for i=1,12 do local v=View.create("slime",fixtureFolder,100+i); if v then table.insert(capped,v); table.insert(temporary,v) end end
	assert(View.count==View.limit and #capped==8,"strict simultaneous cap")
	for _,v in capped do v.destroy() end
	assert(View.count==2,"cancel pending loaders")
	for _=1,5 do flag(false); waitFor(function() return View.count==0 end,3); flag(true); waitFor(ready,15) end
	local final=inspect:Invoke()
	for _,p in final.pets do assert(p.tracks==2 and p.connections==2,"bounded tracks and loop callbacks") end
	record("fiveRecreates",final)
	record("complete",true)
end,debug.traceback)
Registry.slime.animations=originalAnimations; restoreAnchor()
if timer then timer:Disconnect() end
if renamedTemplate then renamedTemplate.Name="GreenSlime" end
for _,v in temporary do v.destroy() end
fixtureFolder:Destroy()
workspace:SetAttribute("AG74React",nil)
Environment.setQuality(originalQuality); Environment.setReduceMotion(originalMotion); flag(true)
if not ok then record("FAILED",tostring(problem)) end
