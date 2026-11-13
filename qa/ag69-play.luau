--!nocheck
-- Optional CLIENT Command Bar after ordinary F5. Not mapped by Rojo.
-- Uses existing owner bridges. Never grants currency, changes saves or publishes.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
local p=game.Players.LocalPlayer
local root=workspace.PotionTycoonWorld
local book=p.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
local q={}
if _G.AG69StateConnection then _G.AG69StateConnection:Disconnect() end
_G.AG69StateConnection=game.ReplicatedStorage.PotionTycoon.Remotes.State.OnClientEvent:Connect(function(s) q.latest=s end)
function q.status(label)
	local s,quality,motion=workspace.M7ClientWeather.PostFXInspect:Invoke()
	local b=book:Invoke()
	print("AG69_STATE",label,quality,motion,s.assetComplete,s.assetFailures,s.skyFallback,s.postFXLook,s.lights,s.rain,s.motes,s.fog,s.stars,b.mode,b.tracked,b.feedback,q.latest and q.latest.essence)
	assert(s.assetComplete and s.assetFailures==0 and not s.skyFallback)
	return s
end
function q.capture(pose,camera)
	root:SetAttribute("EnvironmentReview",pose)
	book:Invoke("quality","reduced"); book:Invoke("motion",true)
	root:SetAttribute("EnvironmentReview","look:AG68")
	local pos=root.Plot_1.crystal.Position
	local offset=({near=Vector3.new(13,9,21),wide=Vector3.new(23,14,31)})[camera]
	local c=workspace.CurrentCamera; c.CameraType=Enum.CameraType.Scriptable
	c.CFrame=CFrame.lookAt(pos+offset,pos+Vector3.new(0,2,-7)); c.FieldOfView=65
	task.delay(10,function()
		q.status(pose.."-"..camera)
		print("AG69_CAPTURE_READY",pose,camera,c.FieldOfView,c.ViewportSize.X,c.ViewportSize.Y,c.CFrame:GetComponents())
	end)
end
function q.near()
	p.Character:PivotTo(CFrame.new(root.Plot_1.crystal.Position+Vector3.new(0,0,6)))
	local c=workspace.CurrentCamera; c.CameraType=Enum.CameraType.Scriptable
	c.CFrame=CFrame.lookAt(root.Plot_1.crystal.Position+Vector3.new(13,9,21),root.Plot_1.crystal.Position+Vector3.new(0,2,-7));c.FieldOfView=65
end
function q.matrix()
	task.spawn(function()
		for _,quality in ipairs({"full","reduced","minimal"}) do for _,motion in ipairs({false,true}) do
			book:Invoke("quality",quality);book:Invoke("motion",motion)
			for _,look in ipairs({"OFF","AG68"}) do
				root:SetAttribute("EnvironmentReview","look:"..look);task.wait(1)
				local s=q.status("matrix")
				assert(s.postFXLook==look)
			end
		end end
		for i=1,8 do
			local plot=assert(root:FindFirstChild("Plot_"..i));assert(plot:FindFirstChild("crystal"))
			local found=0
			for _,m in ipairs(game:GetService("CollectionService"):GetTagged("SpellbookLecternVisual")) do if m.Parent==plot then found+=1 end end
			assert(found==1);print("AG69_PLOT",i,"book=1",plot.crystal.Position)
		end
		book:Invoke("quality","reduced");book:Invoke("motion",false)
		print("AG69_MATRIX_COMPLETE",true)
	end)
end
function q.restore()
	task.spawn(function()
		root:SetAttribute("EnvironmentArtEnabled",false);task.wait(1)
		local L=game:GetService("Lighting");local refs=L:GetChildren();local wind=workspace.GlobalWind
		local before={}
		for _,k in ipairs({"ClockTime","Brightness","Ambient","OutdoorAmbient","GlobalShadows","ExposureCompensation","GeographicLatitude","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do before[k]=L[k] end
		root:SetAttribute("EnvironmentArtEnabled",true);task.wait(3);q.status("restart")
		root:SetAttribute("EnvironmentArtEnabled",false);task.wait(1)
		for k,v in pairs(before) do assert(L[k]==v,"restore "..k) end
		for _,v in ipairs(refs) do assert(v.Parent==L) end
		assert(#refs==#L:GetChildren() and workspace.GlobalWind==wind and not workspace:FindFirstChild("M7ClientWeather"))
		print("AG69_OWNER_RESTORED",true)
		root:SetAttribute("EnvironmentArtEnabled",true)
	end)
end
_G.AG69QA=q
q.status("automatic-start")
