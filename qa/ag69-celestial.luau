--!nocheck
-- CLIENT Command Bar after ordinary F5; QA only, not Rojo-mapped.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
local root=workspace.PotionTycoonWorld
local L=game:GetService("Lighting")
local book=game.Players.LocalPlayer.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
local q={}
function q.body(name,quality,motion)
	book:Invoke("quality",quality or "reduced"); book:Invoke("motion",motion==true)
	root:SetAttribute("EnvironmentReview","weather:clear")
	root:SetAttribute("EnvironmentReview",name=="Sun" and "time:14" or "time:22.5")
	task.wait(9)
	local folder=workspace.M7ClientWeather
	local a=folder.CelestialAnchor
	local c=workspace.CurrentCamera; c.CameraType=Enum.CameraType.Scriptable
	local pos=Vector3.new(-142,120,-65)
	c.CFrame=CFrame.lookAt(pos,pos+a[name].Position); c.FieldOfView=65
	task.wait(2)
	local s,tier,rm=folder.PostFXInspect:Invoke()
	local gui=a[name]:FindFirstChildOfClass("BillboardGui")
	assert(gui.Enabled and gui.Image.IsLoaded and gui.Image.ImageTransparency<.99,"Actual celestial image must render")
	assert(L.M7Sky.SunTextureId=="" and L.M7Sky.MoonTextureId=="")
	assert(L.M7Sky.SunAngularSize==0 and L.M7Sky.MoonAngularSize==0)
	assert(s.assetComplete and s.assetFailures==0 and not s.skyFallback)
	assert(#a:GetChildren()==50 and s.lights<=({full=6,reduced=3,minimal=0})[tier])
	if name=="Sun" then assert((a.Sun.Position.Unit-L:GetSunDirection()).Magnitude<1e-4) end
	print("AG69_R1_BODY",name,tier,rm,gui.Image.IsLoaded,gui.Image.Image,gui.Image.ImageTransparency,#a:GetChildren(),s.lights)
end
function q.matrix()
	task.spawn(function()
		for _,tier in ipairs({"full","reduced","minimal"}) do for _,motion in ipairs({false,true}) do
			for _,name in ipairs({"Sun","Moon"}) do q.body(name,tier,motion) end
		end end
		print("AG69_R1_MATRIX_COMPLETE",12)
	end)
end
function q.restart()
	task.spawn(function()
		root:SetAttribute("EnvironmentArtEnabled",false); task.wait(1)
		local refs=L:GetChildren(); local wind=workspace.GlobalWind; local before={}
		for _,k in ipairs({"ClockTime","Brightness","Ambient","OutdoorAmbient","GlobalShadows","ExposureCompensation","GeographicLatitude","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do before[k]=L[k] end
		for i=1,3 do
			root:SetAttribute("EnvironmentArtEnabled",true); task.wait(2); q.body("Sun","reduced",false); q.body("Moon","reduced",false)
			root:SetAttribute("EnvironmentArtEnabled",false); task.wait(1)
			assert(not workspace:FindFirstChild("M7ClientWeather") and #L:GetChildren()==#refs)
			for _,v in ipairs(refs) do assert(v.Parent==L) end
			for k,v in pairs(before) do assert(L[k]==v,"restore "..k) end
			assert(workspace.GlobalWind==wind)
			print("AG69_R1_RESTORE",i,true)
		end
		root:SetAttribute("EnvironmentArtEnabled",true)
	end)
end
_G.AG69R1=q
print("AG69_R1_QA_READY")
