--!nonstrict
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui")
local RunService=game:GetService("RunService")
local Config=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.EnvironmentConfig)
local View=require(script.Parent.EnvironmentView)
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("VisualHarness") do task.wait() end
-- Real-engine lifecycle and effect-cap audit, confined to this disposable harness.
local lighting=game:GetService("Lighting")
local original={}
local originalWind=workspace.GlobalWind
for _,key in ipairs({"ClockTime","Brightness","Ambient","OutdoorAmbient","GlobalShadows","ExposureCompensation","GeographicLatitude","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do original[key]=lighting[key] end
local sentinel=Instance.new("ColorCorrectionEffect"); sentinel.Name="M7AuditSentinel"; sentinel.Parent=lighting
local sentinelSky=Instance.new("Sky"); sentinelSky.Parent=lighting
local sentinelClouds=Instance.new("Clouds"); sentinelClouds.Parent=workspace.Terrain
local sentinelGrading=Instance.new("ColorGradingEffect"); sentinelGrading.Parent=lighting
local audit=View.start(root,{quality="full",pose="rain"})
assert(not pcall(function() View.start(root,{}) end),"Duplicate environment owner accepted")
assert(sentinel.Parent==nil,"Prior lighting not suspended")
assert(sentinelSky.Parent==nil and sentinelClouds.Parent==nil,"Prior sky/clouds not suspended")
assert(sentinelGrading.Parent==nil,"Prior grading not suspended")
local ownedSky=lighting.M7Sky; local ownedClouds=workspace.Terrain.M7Clouds
local fixedFaces={}
for _,key in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","SunTextureId","MoonTextureId"}) do fixedFaces[key]=ownedSky[key] end
workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(-175,39,-7),Vector3.new(-145,9,-83))
for _,tier in ipairs({"full","reduced","minimal"}) do
	audit.setQuality(tier); audit.setReduceMotion(false); audit.setPose("rain"); audit.update(1)
	local s=audit.stats(); local q=Config.quality[tier]
	assert(s.lights<=q.lights and s.rain<=q.rain and s.motes<=q.motes and s.wind<=q.motion,"Effect cap exceeded")
	assert(s.fog<=q.fog and s.glints<=q.glints and s.rainbow<=q.rainbow,"Local prop cap exceeded")
	print("M7_A2_AUDIT "..tier.." lights="..s.lights.." rain="..s.rain.." motes="..s.motes.." wind="..s.wind.." emitters="..s.emitters)
	audit.setReduceMotion(true); audit.update(1); s=audit.stats()
	assert(s.rain==0 and s.motes==0 and s.wind==0,"Reduce Motion still animates")
	for pose in pairs(Config.poses) do
		audit.setPose(pose); audit.setReduceMotion(false)
		for frame=1,40 do
			workspace.CurrentCamera.CFrame=CFrame.new(-175+(frame%2)*60,9,-65)
			audit.update(1/30); local actual=audit.stats()
			assert(actual.wind<=q.motion and actual.fog<=q.fog and actual.glints<=q.glints and actual.rainbow<=q.rainbow,"Transition cap exceeded")
		end
		assert(lighting.M7Sky==ownedSky and workspace.Terrain.M7Clouds==ownedClouds,"Sky/cloud owner replaced")
		for key,value in pairs(fixedFaces) do assert(ownedSky[key]==value,"Runtime sky texture churn") end
	end
end
audit.stop(); audit.stop()
for k,v in pairs(original) do assert(lighting[k]==v,"Lighting not restored: "..k) end
assert(sentinel.Parent==lighting and not workspace:FindFirstChild("M7ClientWeather"),"Effect lifecycle leak")
assert(workspace.GlobalWind==originalWind,"Wind not restored")
assert(sentinelSky.Parent==lighting and sentinelClouds.Parent==workspace.Terrain,"Sky/cloud identity not restored")
assert(sentinelGrading.Parent==lighting,"Grading not restored")
sentinel:Destroy(); sentinelSky:Destroy(); sentinelClouds:Destroy(); sentinelGrading:Destroy()
print("M7_A2B_LIFECYCLE PASS original sky/cloud identity, immutable textures, all-pose camera transitions within caps, GlobalWind restored")
print("M7_A2_LIFECYCLE PASS duplicate owner, all tiers, Reduce Motion, stop twice, lighting restoration")
local view=View.start(root,{quality="full",pose="day"})
-- Beauty capture only; U restores the unchanged gameplay annotations for audit.
local annotations=false
view.setAnnotationsEnabled(false)
local function annotate(p)
	if p:IsA("ProximityPrompt") then p.Enabled=annotations end
end
root.DescendantAdded:Connect(annotate)
for _,p in ipairs(root:GetDescendants()) do annotate(p) end
local states={"day","sunset","night","rain","dawn","afterrain"}; local cameras={"overview","spawn","bazaar","foliage","sunset","rainbow","sky"}; local mode,angle=1,1
local style=lighting.LightingStyle
local preview=false; local quality=1; local tiers={"full","reduced","minimal"}; local reducedMotion=false
local gui=Instance.new("ScreenGui"); gui.Name="M7VisualHarness"; gui.ResetOnSpawn=false; gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel"); label.Size=UDim2.fromOffset(760,42); label.Position=UDim2.new(.5,-380,1,-52)
label.BackgroundColor3=Color3.fromRGB(25,37,37); label.BackgroundTransparency=.12; label.TextColor3=Color3.fromRGB(246,236,212)
label.Font=Enum.Font.Gotham; label.TextSize=16; label.Parent=gui
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end)
local function apply()
	local c=Config.cameras[cameras[angle]]; local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=CFrame.lookAt(Vector3.new(table.unpack(c.position)),Vector3.new(table.unpack(c.target))); camera.FieldOfView=53
	view.setPose(states[mode]); label.Text="M7.1 A.2b · "..(preview and "45s cycle" or states[mode]).." / "..cameras[angle].." / "..tiers[quality].." / "..style.Name
end
apply()
-- The character's initial camera setup must not overwrite a named review view.
RunService:BindToRenderStep("M7ReviewCamera",Enum.RenderPriority.Camera.Value+1,apply)
Input.InputBegan:Connect(function(input,handled)
	if handled then return end
	local keys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six}
	local index=table.find(keys,input.KeyCode)
	if index then mode=index; preview=false; view.setPreview(false); apply() elseif input.KeyCode==Enum.KeyCode.V then angle=angle%#cameras+1; apply()
	elseif input.KeyCode==Enum.KeyCode.H then label.Visible=not label.Visible end
	if input.KeyCode==Enum.KeyCode.T then preview=not preview; view.setPreview(preview) end
	if input.KeyCode==Enum.KeyCode.Q then quality=quality%#tiers+1; view.setQuality(tiers[quality]) end
	if input.KeyCode==Enum.KeyCode.R then reducedMotion=not reducedMotion; view.setReduceMotion(reducedMotion) end
	if input.KeyCode==Enum.KeyCode.P then
		local s=view.stats(); print("M7_A2_BUDGET quality="..tiers[quality].." reduceMotion="..tostring(reducedMotion).." lights="..s.lights.." rain="..s.rain.." motes="..s.motes.." wind="..s.wind.." emitters="..s.emitters)
		local sun=lighting:GetSunDirection(); print("M7_A2B_FRAME pose="..states[mode].." style="..lighting.LightingStyle.Name.." clock="..lighting.ClockTime.." sun="..tostring(sun).." exposure="..lighting.ExposureCompensation.." fog="..s.fog.." glints="..s.glints.." rainbow="..s.rainbow.." assetFailures="..s.assetFailures)
		print("M7_A2B_GRAPHICS "..UserSettings():GetService("UserGameSettings").SavedQualityLevel.Name.." lightingPriority="..tostring(lighting.PrioritizeLightingQuality))
	end
	if input.KeyCode==Enum.KeyCode.U then annotations=not annotations; view.setAnnotationsEnabled(annotations); for _,p in ipairs(root:GetDescendants()) do annotate(p) end end
end)
