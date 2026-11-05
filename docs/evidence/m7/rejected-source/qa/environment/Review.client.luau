--!nonstrict
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui")
local RunService=game:GetService("RunService")
local Config=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.EnvironmentConfig)
local View=require(script.Parent.EnvironmentView)
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("VisualHarness") do task.wait() end
local view=View.start(root,{quality="full",pose="day"})
-- Beauty capture only; U restores the unchanged gameplay annotations for audit.
local annotations=false
view.setAnnotationsEnabled(false)
local function annotate(p)
	if p:IsA("ProximityPrompt") then p.Enabled=annotations end
end
root.DescendantAdded:Connect(annotate)
for _,p in ipairs(root:GetDescendants()) do annotate(p) end
local states={"day","sunset","night","rain","dawn"}; local cameras={"overview","spawn","bazaar"}; local mode,angle=1,1
local gui=Instance.new("ScreenGui"); gui.Name="M7VisualHarness"; gui.ResetOnSpawn=false; gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel"); label.Size=UDim2.fromOffset(760,42); label.Position=UDim2.new(.5,-380,1,-52)
label.BackgroundColor3=Color3.fromRGB(25,37,37); label.BackgroundTransparency=.12; label.TextColor3=Color3.fromRGB(246,236,212)
label.Font=Enum.Font.Gotham; label.TextSize=16; label.Parent=gui
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,false) end)
local function apply()
	local c=Config.cameras[cameras[angle]]; local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Scriptable
	camera.CFrame=CFrame.lookAt(Vector3.new(table.unpack(c.position)),Vector3.new(table.unpack(c.target))); camera.FieldOfView=53
	view.setPose(states[mode]); label.Text="M7.1 · STUDIO VISUAL HARNESS · "..states[mode].." / "..cameras[angle].." · 1–5 light / V camera / H label"
end
apply()
-- The character's initial camera setup must not overwrite a named review view.
RunService:BindToRenderStep("M7ReviewCamera",Enum.RenderPriority.Camera.Value+1,apply)
Input.InputBegan:Connect(function(input,handled)
	if handled then return end
	local keys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five}
	local index=table.find(keys,input.KeyCode)
	if index then mode=index; apply() elseif input.KeyCode==Enum.KeyCode.V then angle=angle%#cameras+1; apply()
	elseif input.KeyCode==Enum.KeyCode.H then label.Visible=not label.Visible end
	if input.KeyCode==Enum.KeyCode.U then annotations=not annotations; view.setAnnotationsEnabled(annotations); for _,p in ipairs(root:GetDescendants()) do annotate(p) end end
end)
