--!nonstrict
-- Isolated owner art scene. Diagnostics are text/numbers only; no capture API.
local Run=game:GetService("RunService");assert(Run:IsStudio() and workspace:GetAttribute("WillowV2QA"))
local Http=game:GetService("HttpService");local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("PotionTycoon"):WaitForChild("Shared")
local O=Vector3.new(table.unpack(require(Shared.PersonalIsland).origin))
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("GroundCoverReady")do task.wait()end
local beforeWind=workspace.GlobalWind
local assets=require(script.Parent.TreeModel).load(require(Shared.WillowV2Data),require(Shared.WillowV2Pixels))
local container=Instance.new("Folder");container.Name="WillowV2Trees";container.Parent=root
local trees={assets.create(container,CFrame.new(O+Vector3.new(47,.38,-29)),"willow","island-hero")}
local hidden={}
for _,item in ipairs(root.EnvironmentArt:GetChildren())do
	if item.Name=="AncientTreeProxy" or item.Name=="AncientTreeCrownProxy" then hidden[#hidden+1]=item;item.Parent=nil end
end
-- Benchmark trees are off-island, never in a station/build footprint.
for i=2,20 do
	local p=O+Vector3.new(((i-2)%5-2)*34,.38,85+math.floor((i-2)/5)*32)
	trees[i]=assets.create(container,CFrame.new(p)*CFrame.Angles(0,(i%5)*.27,0),"willow","grove-"..i);trees[i].Parent=nil
end
local deck=Instance.new("Part");deck.Name="WillowV2OffIslandBenchmark";deck.Anchored=true;deck.Size=Vector3.new(180,1,145);deck.Position=O+Vector3.new(0,-.5,133)
deck.Material=Enum.Material.Ground;deck.Color=Color3.fromRGB(63,77,64);deck.Parent=nil
local cliff=require(script.Parent.Cliff).create(root.EnvironmentArt,O)
local waterfall=require(script.Parent.Waterfall).create(root,O,require(Shared.EnvironmentAssets).uri("mist"))
local view=require(script.Parent.EnvironmentView).start(root,{quality="full",pose="dusk"});view.setLook("OFF");view.setAnnotationsEnabled(false)
local wind=require(script.Parent.TreeWindController).start(trees)
local player=Players.LocalPlayer;local gui=Instance.new("ScreenGui");gui.Name="WillowV2Review";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel");label.Size=UDim2.new(1,-20,0,34);label.Position=UDim2.new(0,10,1,-44);label.BackgroundColor3=Color3.fromRGB(24,29,34);label.TextColor3=Color3.fromRGB(232,232,218);label.TextSize=14;label.Font=Enum.Font.Gotham;label.Parent=gui
local quality="full";local motion=false;local pose="dusk";local count=1;local cameraMode="hero";local stopped=false;local running=false
local oldFov=workspace.CurrentCamera.FieldOfView
local cameras={hero={Vector3.new(16,12,12),Vector3.new(45,14,-29)},island={Vector3.new(99,48,102),Vector3.new(0,3,-8)},forest={Vector3.new(84,45,36),Vector3.new(0,15,127)}}
Run:BindToRenderStep("WillowV2ReviewCamera",Enum.RenderPriority.Camera.Value+1,function()
	local c=cameras[cameraMode];if not c then return end
	local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=64;camera.CFrame=CFrame.lookAt(O+c[1],O+c[2]);camera.Focus=CFrame.new(O+c[2])
end)
local function refresh()
	wind.setQuality(quality);wind.setReduceMotion(motion);view.setQuality(quality);view.setReduceMotion(motion);view.setPose(pose);waterfall.set(quality,motion)
	for i=2,20 do trees[i].Parent=i<=count and container or nil end;deck.Parent=count>1 and root or nil
	label.Text=string.format("WILLOW V2 · OWNER ART PENDING | %s / %s / %d trees | 1 Hero 2 Island 3 Walk 4 Grove · 5/6/7 Day/Dusk/Night · T 1/3/20 · Q Quality · R Motion · K Checks",pose,quality,count)
	if cameraMode=="free"then workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid")end
end
local function inspect()
	local owners=0;for _,c in ipairs(workspace:GetChildren())do if c.Name=="M7ClientWeather"then owners+=1 end end
	return {trees=count,trianglesPerTree=5783,meshes=#assets.meshes,images=#assets.images,templates=#assets.templates,bonesPerTree=9,
		quality=quality,reduceMotion=motion,pose=pose,wind={workspace.GlobalWind.X,workspace.GlobalWind.Z},windStats=wind.stats(),owners=owners,treeDescendants=#container:GetDescendants()}
end
local function emit(kind,data)print("WILLOW_V2_"..kind.." "..Http:JSONEncode(data))end
local function measure(seconds)
	local frame,cpu={},{};local start=os.clock();local updates=wind.updates
	while os.clock()-start<seconds and not stopped do frame[#frame+1]=Run.RenderStepped:Wait()*1000;cpu[#cpu+1]=wind.lastMs end
	table.sort(frame);table.sort(cpu);return {quality=quality,trees=count,seconds=os.clock()-start,frames=#frame,p50ms=frame[math.ceil(#frame*.5)],p95ms=frame[math.ceil(#frame*.95)],windP95ms=cpu[math.ceil(#cpu*.95)],updates=wind.updates-updates,activeTrees=wind.activeTrees,memoryMiB=game:GetService("Stats"):GetTotalMemoryUsageMb()}
end
local function resetBones()
	for _,tree in ipairs(trees)do for _,b in ipairs(tree:GetDescendants())do if b:IsA("Bone")and b.Transform~=CFrame.identity then return false end end end;return true
end
local function walk()
	local character=player.Character or player.CharacterAdded:Wait();local h=character:WaitForChild("Humanoid");local result={}
	for _,p in ipairs({{0,2},{-20,2},{-30,-20},{0,-30},{28,-12},{20,16},{0,20}})do
		h:MoveTo(O+Vector3.new(p[1],.5,p[2]));local reached=h.MoveToFinished:Wait();result[#result+1]={x=p[1],z=p[2],reached=reached,health=h.Health};if not reached then break end
	end
	emit("WALK",{points=result,method="Normal Humanoid MoveTo; no teleport"})
end
local function checks()
	if running or stopped then return false end;running=true
	task.spawn(function()
		local ok,err=pcall(function()
			emit("START",inspect())
			local variants={};for _,t in ipairs(trees)do variants[#variants+1]={id=t:GetAttribute("StableTreeId"),c=t:GetAttribute("crown"),r=t:GetAttribute("root"),b=t:GetAttribute("bark"),f=t:GetAttribute("foliage"),scale=t:GetAttribute("scale")}end
			for i=1,20,5 do local chunk={};for j=i,i+4 do chunk[#chunk+1]=variants[j]end;emit("VARIANTS",chunk)end
			for _,p in ipairs({"day","dusk","night"})do pose=p;refresh();task.wait(9);local a=inspect();assert(a.owners==1);emit("POSE",{pose=p,owners=a.owners,wind=a.wind,clock=game:GetService("Lighting").ClockTime,exposure=game:GetService("Lighting").ExposureCompensation})end
			pose="dusk";count=20;cameraMode="forest";refresh();task.wait(2)
			local baseline=#container:GetDescendants();local meshCount=#assets.meshes
			for i=1,20 do quality=({"full","reduced","minimal"})[i%3+1];motion=i%2==0;refresh();task.wait(.2);assert(#container:GetDescendants()==baseline);assert(#assets.meshes==meshCount);assert(wind.connections==1);if motion then assert(resetBones(),"Reduce Motion residual")end end
			emit("SWITCHES",{cycles=20,descendants=baseline,meshes=meshCount,images=#assets.images,connections=wind.connections,reduceMotionIdentity=resetBones()})
			motion=false
			for _,q in ipairs({"full","reduced","minimal"})do quality=q;refresh();task.wait(1);emit("PERF",measure(6))end
			quality="full";count=1;cameraMode="hero";refresh();task.wait(1);emit("PERF",measure(6))
			local bones={};for _,b in ipairs(trees[1]:GetDescendants())do if b:IsA("Bone")then bones[b.Name]=b.Transform end end;task.wait(1)
			local changed=0;for _,b in ipairs(trees[1]:GetDescendants())do if b:IsA("Bone")then if b.Name=="Root"then assert(b.Transform==CFrame.identity)elseif b.Transform~=bones[b.Name]then changed+=1 end end end
			assert(changed==8,"Crown motion frozen");emit("MOTION",{movingCrownBones=changed,rootFixed=true})
			cameraMode="free";refresh();walk()
			pose="dusk";cameraMode="hero";refresh();emit("PASS",inspect())
		end)
		if not ok then emit("FAIL",{error=tostring(err)})end;running=false
	end);return true
end
local qa=Instance.new("BindableFunction");qa.Name="WillowV2QA";qa.Parent=workspace
local inputConnection
local function cleanup()
	if stopped then return end;stopped=true
	if inputConnection then inputConnection:Disconnect()end
	wind.stop();view.stop();waterfall.destroy();cliff.part:Destroy();cliff.mesh:Destroy();assets.destroy();container:Destroy();deck:Destroy();gui:Destroy()
	for _,item in ipairs(hidden)do item.Parent=root.Parent and root.EnvironmentArt or nil end
	Run:UnbindFromRenderStep("WillowV2ReviewCamera");workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.FieldOfView=oldFov
	emit("CLEANUP",{connections=wind.connections,meshes=#assets.meshes,images=#assets.images,trees=#assets.trees,windRestored=workspace.GlobalWind==beforeWind});qa:Destroy()
end
qa.OnInvoke=function(action,value)
	if action=="inspect"then return inspect()elseif action=="checks"then return checks()elseif action=="stop"then cleanup();return true
	elseif action=="quality"then quality=value elseif action=="motion"then motion=value==true elseif action=="pose"then pose=value
	elseif action=="count"then assert(value==1 or value==3 or value==20);count=value
	elseif action=="camera"then assert(cameras[value] or value=="free");cameraMode=value end
	refresh();return inspect()
end
inputConnection=game:GetService("UserInputService").InputBegan:Connect(function(input,handled)
	if handled then return end;local k=input.KeyCode
	local c=({[Enum.KeyCode.One]="hero",[Enum.KeyCode.Two]="island",[Enum.KeyCode.Three]="free",[Enum.KeyCode.Four]="forest"})[k]
	local p=({[Enum.KeyCode.Five]="day",[Enum.KeyCode.Six]="dusk",[Enum.KeyCode.Seven]="night"})[k]
	if c then cameraMode=c elseif p then pose=p elseif k==Enum.KeyCode.T then count=count==1 and 3 or count==3 and 20 or 1;cameraMode=count==1 and "hero" or "forest"
	elseif k==Enum.KeyCode.Q then quality=quality=="full" and "reduced" or quality=="reduced" and "minimal" or "full"
	elseif k==Enum.KeyCode.R then motion=not motion elseif k==Enum.KeyCode.K then checks();return else return end;refresh()
end)
script.Destroying:Connect(cleanup)
refresh();emit("READY",inspect()) -- Run K explicitly; never hijack the owner's review.
