--!nonstrict
local Run=game:GetService("RunService");assert(Run:IsStudio(),"Willow QA only")
local Http=game:GetService("HttpService")
local root=workspace:WaitForChild("PotionTycoonWorld")
local O=Vector3.new(-142.5,.05,-65)
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local data=require(Shared.WillowData);local pixels=require(Shared.WillowPixels)
local triangles=0;for _,mesh in ipairs(data.meshes)do triangles+=#mesh.triangles end
local assets=require(script.Parent.Model).load(data,pixels)
local container=Instance.new("Folder");container.Name="WillowPrototype";container.Parent=workspace
local trees={assets.create(container,CFrame.new(O),1)}
for i=2,20 do
	local x=((i-2)%5-2)*34;local z=38+math.floor((i-2)/5)*30
	trees[i]=assets.create(container,CFrame.new(O+Vector3.new(x,0,z))*CFrame.Angles(0,i*.21,0),i)
	trees[i].Parent=nil
end
local wind=require(script.Parent.Wind).start(trees)
local View=require(script.Parent.EnvironmentView)
local beforeWind=workspace.GlobalWind
local view=View.start(root,{quality="full",pose="day"});view.setLook("OFF");view.setAnnotationsEnabled(false)
local player=game:GetService("Players").LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="WillowReview";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel");label.Size=UDim2.new(1,-24,0,32);label.Position=UDim2.new(0,12,1,-40)
label.BackgroundColor3=Color3.fromRGB(20,28,28);label.BackgroundTransparency=.12;label.TextColor3=Color3.fromRGB(235,236,215)
label.Font=Enum.Font.Gotham;label.TextSize=14;label.Parent=gui
local quality="full";local reduce=false;local count=1;local camera="front"
local originalFov=workspace.CurrentCamera.FieldOfView
local cameras={front={Vector3.new(0,15,-49),Vector3.new(0,12,0)},side={Vector3.new(49,15,0),Vector3.new(0,12,0)},
	angle={Vector3.new(38,20,-46),Vector3.new(0,12,0)},back={Vector3.new(0,15,49),Vector3.new(0,12,0)},
	forest={Vector3.new(85,64,-55),Vector3.new(0,12,55)}}
local function refresh()
	wind.setQuality(quality);wind.setReduceMotion(reduce);view.setQuality(quality);view.setReduceMotion(reduce)
	label.Text=string.format("WILLOW · ART PENDING | %d trees · %s · Reduce Motion %s | 1/2/3/4 Views · 5 Walk · T 1/20 · Q Quality · R Motion · P Measure · H Hide",count,quality,tostring(reduce))
end
Run:BindToRenderStep("WillowReviewCamera",Enum.RenderPriority.Camera.Value+1,function()
	local c=cameras[camera];if not c then return end
	workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable;workspace.CurrentCamera.FieldOfView=49
	workspace.CurrentCamera.CFrame=CFrame.lookAt(O+c[1],O+c[2]);workspace.CurrentCamera.Focus=CFrame.new(O+c[2])
end)
local function inspect()
	return {triangles=triangles,groups=84,treeCount=count,quality=quality,reduceMotion=reduce,bonesPerTree=9,meshPartsPerTree=2,
		wind={workspace.GlobalWind.X,workspace.GlobalWind.Y,workspace.GlobalWind.Z},updates=wind.updates,boneWrites=wind.boneWrites,lastWindMs=wind.lastMs,
		meshResources=#assets.meshes,imageResources=#assets.images,descendants=#container:GetDescendants()}
end
local measuring=false
local function measure()
	if measuring then return false end;measuring=true
	task.spawn(function()
		local frame,cpu={},{};local started=os.clock();local updates=wind.updates
		while os.clock()-started<10 do frame[#frame+1]=Run.RenderStepped:Wait()*1000;cpu[#cpu+1]=wind.lastMs end
		table.sort(frame);table.sort(cpu);local result=inspect()
		result.frames=#frame;result.frameMedianMs=frame[math.ceil(#frame*.5)];result.frameP95Ms=frame[math.ceil(#frame*.95)]
		result.windP95Ms=cpu[math.ceil(#cpu*.95)];result.windUpdates=wind.updates-updates
		result.memoryMb=game:GetService("Stats"):GetTotalMemoryUsageMb()
		print("WILLOW_PERF "..Http:JSONEncode(result));measuring=false
	end);return true
end
local qa=Instance.new("BindableFunction");qa.Name="WillowQA";qa.Parent=workspace
local inputConnection;local stopped=false
local function cleanup()
	if stopped then return end;stopped=true
	if inputConnection then inputConnection:Disconnect()end
	wind.stop();view.stop();assets.destroy();Run:UnbindFromRenderStep("WillowReviewCamera")
	workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.FieldOfView=originalFov
	workspace.CurrentCamera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	container:Destroy();gui:Destroy();task.defer(function()qa:Destroy()end)
end
qa.OnInvoke=function(action,value)
	if action=="camera" then assert(cameras[value] or value=="free");camera=value
		if value=="free"then workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid")end
	elseif action=="quality"then quality=value
	elseif action=="motion"then reduce=value
	elseif action=="time"then wind.time=value
	elseif action=="count"then assert(value==1 or value==20);count=value;for i=2,20 do trees[i].Parent=value==20 and container or nil end
	elseif action=="measure"then return measure()
	elseif action=="inspect"then return inspect()
	elseif action=="pose"then view.setPose(value)
	elseif action=="stop"then cleanup();return {windRestored=workspace.GlobalWind==beforeWind,meshResources=#assets.meshes,imageResources=#assets.images}
	end
	refresh();return inspect()
end
inputConnection=game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
	if processed then return end
	local key=input.KeyCode
	local cam=({[Enum.KeyCode.One]="front",[Enum.KeyCode.Two]="side",[Enum.KeyCode.Three]="angle",[Enum.KeyCode.Four]="back",[Enum.KeyCode.Five]="free"})[key]
	if cam then qa:Invoke("camera",cam)
	elseif key==Enum.KeyCode.T then qa:Invoke("count",count==1 and 20 or 1);qa:Invoke("camera",count==20 and "forest" or "front")
	elseif key==Enum.KeyCode.Q then qa:Invoke("quality",quality=="full" and "reduced" or quality=="reduced" and "minimal" or "full")
	elseif key==Enum.KeyCode.R then qa:Invoke("motion",not reduce)
	elseif key==Enum.KeyCode.P then measure()
	elseif key==Enum.KeyCode.H then gui.Enabled=not gui.Enabled end
end)
script.Destroying:Connect(cleanup)
refresh();print("WILLOW_READY "..Http:JSONEncode(inspect()))
