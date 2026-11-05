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
for _,key in ipairs({"ClockTime","Brightness","Ambient","OutdoorAmbient","GlobalShadows","ExposureCompensation","GeographicLatitude","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do original[key]=lighting[key] end
local sentinel=Instance.new("ColorCorrectionEffect"); sentinel.Name="M7AuditSentinel"; sentinel.Parent=lighting
local audit=View.start(root,{quality="full",pose="rain"})
assert(not pcall(function() View.start(root,{}) end),"Duplicate environment owner accepted")
assert(sentinel.Parent==nil,"Prior lighting not suspended")
workspace.CurrentCamera.CameraType=Enum.CameraType.Scriptable
workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(-175,39,-7),Vector3.new(-145,9,-83))
for _,tier in ipairs({"full","reduced","minimal"}) do
	audit.setQuality(tier); audit.setReduceMotion(false); audit.setPose("rain"); audit.update(1)
	local s=audit.stats(); local q=Config.quality[tier]
	assert(s.lights<=q.lights and s.rain<=q.rain and s.motes<=q.motes and s.wind<=q.motion,"Effect cap exceeded")
	print("M7_A2_AUDIT "..tier.." lights="..s.lights.." rain="..s.rain.." motes="..s.motes.." wind="..s.wind.." emitters="..s.emitters)
	audit.setReduceMotion(true); audit.update(1); s=audit.stats()
	assert(s.rain==0 and s.motes==0 and s.wind==0,"Reduce Motion still animates")
end
audit.stop(); audit.stop()
for k,v in pairs(original) do assert(lighting[k]==v,"Lighting not restored: "..k) end
assert(sentinel.Parent==lighting and not workspace:FindFirstChild("M7ClientWeather"),"Effect lifecycle leak")
sentinel:Destroy()
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
local states={"day","sunset","night","rain","dawn"}; local cameras={"overview","spawn","bazaar","foliage"}; local mode,angle=1,1
local preview=false; local quality=1; local tiers={"full","reduced","minimal"}; local reducedMotion=false
local gui=Instance.new("ScreenGui"); gui.Name="M7VisualHarness"; gui.ResetOnSpawn=false; gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel"); label.Size=UDim2.fromOffset(760,42); label.Position=UDim2.new(.5,-380,1,-52)
label.BackgroundColor3=Color3.fromRGB(25,37,37); label.BackgroundTransparency=.12; label.TextColor3=Color3.fromRGB(246,236,212)
label.Font=Enum.Font.Gotham; label.TextSize=16; label.Parent=gui
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end)
local function apply()
	local c=Config.cameras[cameras[angle]]; local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=CFrame.lookAt(Vector3.new(table.unpack(c.position)),Vector3.new(table.unpack(c.target))); camera.FieldOfView=53
	view.setPose(states[mode]); label.Text="M7.1 A.2 · "..(preview and "45s cycle" or states[mode]).." / "..cameras[angle].." / "..tiers[quality].." · T cycle / Q quality / R motion"
end
apply()
-- The character's initial camera setup must not overwrite a named review view.
RunService:BindToRenderStep("M7ReviewCamera",Enum.RenderPriority.Camera.Value+1,apply)
Input.InputBegan:Connect(function(input,handled)
	if handled then return end
	local keys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five}
	local index=table.find(keys,input.KeyCode)
	if index then mode=index; preview=false; view.setPreview(false); apply() elseif input.KeyCode==Enum.KeyCode.V then angle=angle%#cameras+1; apply()
	elseif input.KeyCode==Enum.KeyCode.H then label.Visible=not label.Visible end
	if input.KeyCode==Enum.KeyCode.T then preview=not preview; view.setPreview(preview) end
	if input.KeyCode==Enum.KeyCode.Q then quality=quality%#tiers+1; view.setQuality(tiers[quality]) end
	if input.KeyCode==Enum.KeyCode.R then reducedMotion=not reducedMotion; view.setReduceMotion(reducedMotion) end
	if input.KeyCode==Enum.KeyCode.P then
		local s=view.stats(); print("M7_A2_BUDGET quality="..tiers[quality].." reduceMotion="..tostring(reducedMotion).." lights="..s.lights.." rain="..s.rain.." motes="..s.motes.." wind="..s.wind.." emitters="..s.emitters)
	end
	if input.KeyCode==Enum.KeyCode.U then annotations=not annotations; view.setAnnotationsEnabled(annotations); for _,p in ipairs(root:GetDescendants()) do annotate(p) end end
end)
