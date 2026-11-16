--!nonstrict
local Run=game:GetService("RunService")
assert(Run:IsStudio(),"Art review is Studio-only")
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Stats=game:GetService("Stats")
local Http=game:GetService("HttpService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Assets=require(Shared.EnvironmentAssets)
local O=Vector3.new(table.unpack(require(Shared.PersonalIsland).origin))
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("WizardReady") do task.wait() end
local cliff=require(script.Parent.Cliff).create(root.EnvironmentArt,O)
script.Destroying:Connect(function() cliff.part:Destroy();cliff.mesh:Destroy() end)
local View=require(script.Parent.EnvironmentView)
local view=View.start(root,{quality="full",pose="dusk"})
view.setLook("OFF");view.setAnnotationsEnabled(false)
local player=Players.LocalPlayer
pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end)
local gui=Instance.new("ScreenGui");gui.Name="WizardReview";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel");label.Size=UDim2.new(1,-40,0,34);label.Position=UDim2.new(0,20,1,-48)
label.BackgroundColor3=Color3.fromRGB(17,24,34);label.BackgroundTransparency=.12
label.TextColor3=Color3.fromRGB(235,229,208);label.Font=Enum.Font.Gotham;label.TextSize=14;label.Parent=gui
local cameras={
	spawn={Vector3.new(0,8,32),Vector3.new(0,5,-6),62},
	overview={Vector3.new(120,66,140),Vector3.new(0,-16,-8),47},
	altar={Vector3.new(13,7.8,12),Vector3.new(-1,4.3,-4),52},
}
local cameraMode="spawn";local pose="dusk";local quality="full";local motion=false
local function applyCamera()
	local camera=workspace.CurrentCamera
	if cameraMode=="free" then return end
	local c=cameras[cameraMode];camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=CFrame.lookAt(O+c[1],O+c[2]);camera.Focus=CFrame.new(O+c[2]);camera.FieldOfView=c[3]
end
Run:BindToRenderStep("WizardReviewCamera",Enum.RenderPriority.Camera.Value+1,applyCamera)
-- Local cloud bank, using the existing private CC0 mist image. This is not global fog.
local cloudAnchor=Instance.new("Part");cloudAnchor.Name="WizardCloudBank";cloudAnchor.Anchored=true
cloudAnchor.Transparency=1;cloudAnchor.CanCollide=false;cloudAnchor.CanQuery=false;cloudAnchor.CanTouch=false
cloudAnchor.Position=O+Vector3.new(0,-78,-8);cloudAnchor.Size=Vector3.one;cloudAnchor.Parent=workspace
local clouds={}
for i=1,3 do
	local a=Instance.new("Attachment");a.Position=Vector3.new((i-2)*64,0,(i%2)*30);a.Parent=cloudAnchor
	local e=Instance.new("ParticleEmitter");e.Name="UnderIslandMist";e.Texture=Assets.uri("mist")
	e.Lifetime=NumberRange.new(30);e.Rate=0;e.Speed=NumberRange.new(.3,.6);e.SpreadAngle=Vector2.new(180,30)
	e.Size=NumberSequence.new(100);e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.38),NumberSequenceKeypoint.new(.8,.52),NumberSequenceKeypoint.new(1,1)})
	e.Color=ColorSequence.new(Color3.fromRGB(176,187,203));e.LightInfluence=0;e.LightEmission=.12
	e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-1,1);e.Parent=a;table.insert(clouds,e)
end
local book=root.EnvironmentArt:WaitForChild("SpellbookLectern")
local host=book:FindFirstChild("Cover",true)
local glimmer=Instance.new("ParticleEmitter");glimmer.Name="AltarMotes";glimmer.Texture=Assets.uri("star")
glimmer.Rate=2;glimmer.Lifetime=NumberRange.new(2,3);glimmer.Speed=NumberRange.new(.4,.8)
glimmer.Size=NumberSequence.new(.12);glimmer.Color=ColorSequence.new(Color3.fromRGB(142,207,227))
glimmer.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.15),NumberSequenceKeypoint.new(1,1)})
glimmer.SpreadAngle=Vector2.new(30,30);glimmer.LightEmission=.5;glimmer.Parent=host
local function refresh()
	view.setQuality(quality);view.setReduceMotion(motion);view.setPose(pose)
	for _,e in ipairs(clouds) do
		e:Clear();e.TimeScale=motion and 0 or 1
		e.Rate=motion and 0 or (quality=="full" and .2 or quality=="reduced" and .1 or 0)
		e:Emit(motion and 0 or (quality=="minimal" and 2 or 5))
	end
	glimmer.Enabled=quality~="minimal" and not motion
	local light=host:FindFirstChild("AltarGlow");if light then light.Enabled=quality~="minimal" end
	if cameraMode=="free" then local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Custom;c.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") end
	label.Text="WIZARD ISLAND / ART PENDING   ·   "..pose.." / "..quality.."   |   1 Spawn  2 Island  3 Altar  4 Walk   5 Day  6 Dusk  7 Night   Q Quality  R Motion  H Hide  P Timings"
	root:SetAttribute("ReviewPose",pose);root:SetAttribute("ReviewCamera",cameraMode);root:SetAttribute("ReviewQuality",quality)
	print("WIZARD_VIEW",pose,cameraMode,quality,"reduceMotion="..tostring(motion))
end
local measuring=false
local function measure()
	if measuring then return end;measuring=true
	task.spawn(function()
		local measuredPose,measuredCamera,measuredQuality=pose,cameraMode,quality
		local dt={};local elapsed=0
		while elapsed<15 do local t=Run.RenderStepped:Wait();table.insert(dt,t*1000);elapsed+=t end
		table.sort(dt)
		local data={pose=measuredPose,camera=measuredCamera,quality=measuredQuality,seconds=elapsed,frames=#dt,
			fps=#dt/elapsed,p50ms=dt[math.ceil(#dt*.5)],p95ms=dt[math.ceil(#dt*.95)],memoryMiB=Stats:GetTotalMemoryUsageMb(),
			meshParts=root:GetAttribute("MeshParts"),natureTriangles=root:GetAttribute("NatureTriangles"),effects=view.stats(),
			graphics=UserSettings():GetService("UserGameSettings").SavedQualityLevel.Name,
			valid=pose==measuredPose and cameraMode==measuredCamera and quality==measuredQuality}
		print("WIZARD_PERF "..Http:JSONEncode(data));measuring=false
	end)
end
local review=Instance.new("BindableFunction");review.Name="WizardReviewControl";review.Parent=root
review.OnInvoke=function(action,value)
	if action=="camera" and (cameras[value] or value=="free") then cameraMode=value
	elseif action=="pose" and ({day=true,dusk=true,night=true})[value] then pose=value
	elseif action=="quality" and ({full=true,reduced=true,minimal=true})[value] then quality=value
	elseif action=="motion" then motion=value==true
	elseif action=="measure" then measure();return true
	elseif action=="hide" then gui.Enabled=not value;return true end
	refresh();return {pose=pose,camera=cameraMode,quality=quality,effects=view.stats()}
end
Input.InputBegan:Connect(function(key,handled)
	if handled then return end
	local c=({[Enum.KeyCode.One]="spawn",[Enum.KeyCode.Two]="overview",[Enum.KeyCode.Three]="altar",[Enum.KeyCode.Four]="free"})[key.KeyCode]
	local p=({[Enum.KeyCode.Five]="day",[Enum.KeyCode.Six]="dusk",[Enum.KeyCode.Seven]="night"})[key.KeyCode]
	if c then cameraMode=c elseif p then pose=p
	elseif key.KeyCode==Enum.KeyCode.Q then quality=quality=="full" and "reduced" or quality=="reduced" and "minimal" or "full"
	elseif key.KeyCode==Enum.KeyCode.R then motion=not motion
	elseif key.KeyCode==Enum.KeyCode.H then gui.Enabled=not gui.Enabled;return
	elseif key.KeyCode==Enum.KeyCode.P then measure();return else return end
	refresh()
end)
refresh();applyCamera()
task.spawn(function()
	local failed={};local ok,err=pcall(function()
		game:GetService("ContentProvider"):PreloadAsync(root:GetDescendants(),function(uri,status)
			if status~=Enum.AssetFetchStatus.Success then failed[uri]=status.Name end
		end)
	end)
	print("WIZARD_ASSETS "..Http:JSONEncode({ok=ok,failed=failed,error=not ok and tostring(err) or nil}))
end)
