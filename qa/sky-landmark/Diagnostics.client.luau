--!nonstrict
-- Optional bounded numeric checks in the ordinary game. No screenshots/camera control.
local Run=game:GetService("RunService")
if not Run:IsStudio() or not workspace:GetAttribute("SkyLandmarkQA") then return end
local Http=game:GetService("HttpService")
local Controller=require(script.Parent.EnvironmentController)
local View=require(script.Parent.EnvironmentView)
local Diagnostics=require(script.Parent.LunarDiagnostics)
local Config=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.SkyLandmarkConfig)
local root=workspace:WaitForChild("PotionTycoonWorld")
local function emit(kind,data)print("SKY_LANDMARK_"..kind,Http:JSONEncode(data))end
local running=false
local function inspect()
	local v=Controller.view;return v and v.stats().skyLandmark
end
local function checks()
	if running then return false end;running=true
	local quality,motion=Controller.quality,Controller.reduceMotion
	local initial=Controller.view;local pose=initial.pose;local stopped=false
	local ok,err=pcall(function()
		local s=assert(inspect());assert(s.ready,s.error);assert(s.images==4 and s.instances==Config.maxInstances and s.pixelWrites==4)
		local camera=workspace.CurrentCamera
		assert(camera.CameraType==Enum.CameraType.Custom,"Choose a familiar and obtain the ordinary character camera before checks")
		assert(root:GetAttribute("WillowV2Ready"),"Willow must also load before scene/performance verification")
		local initialFov=camera.FieldOfView
		emit("START",{landmark=s,camera=camera.CameraType.Name,viewPosition={camera.CFrame.Position.X,camera.CFrame.Position.Y,camera.CFrame.Position.Z}})
		for _,p in ipairs({"day","dusk","night"})do
			Controller.view.setPose(p);task.wait(9)
			local st=Controller.view.stats();local anchor=workspace.M7ClientWeather.SkyLandmark.WorldAnchor
			local moon=game:GetService("Lighting"):GetMoonDirection()
			local separation=math.deg(math.acos(math.clamp((anchor.Position-camera.CFrame.Position).Unit:Dot(moon),-1,1)))
			emit("POSE",{pose=p,clock=game:GetService("Lighting").ClockTime,camera=camera.CameraType.Name,moonSeparationDegrees=separation,landmark=st.skyLandmark,lunar=st.lunar.weights})
		end
		for _,name in ipairs({"pearl","blood","frost"})do Controller.view.setMoon(name);task.wait(9);emit("MOON",{name=name,landmark=inspect(),weights=Controller.view.stats().lunar.weights})end
		for i=1,20 do
			Controller.setQuality(({"full","reduced","minimal"})[(i-1)%3+1]);Controller.setReduceMotion(i%2==0);task.wait(.25)
			local st=inspect();assert(st.images==4 and st.instances==Config.maxInstances and st.pixelWrites==4 and st.renderConnections==0 and st.lifecycleConnections==1)
		end
		Controller.setQuality("full");Controller.setReduceMotion(true);task.wait(.3)
		local frozen=inspect().phase;task.wait(.5);assert(inspect().phase==frozen)
		emit("QUALITY",{switches=20,reduceMotionFrozen=true,landmark=inspect()})
		local metrics={};for _,q in ipairs({"full","reduced","minimal"})do
			Controller.setQuality(q);Controller.setReduceMotion(false);task.wait(5)
			assert(inspect().visibleLayers==Config.quality[q].layers,"Steady layer budget mismatch")
			local samples,cpu={},0
			for i=1,90 do local dt=Run.RenderStepped:Wait();samples[i]=dt*1000;cpu+=inspect().lastMs end
			table.sort(samples);metrics[q]={frames=90,frameMedianMs=samples[45],frameP95Ms=samples[86],sampledUpdateMeanMs=cpu/90,totalClientMemoryMb=game:GetService("Stats"):GetTotalMemoryUsageMb()}
		end;assert(camera.CameraType==Enum.CameraType.Custom and camera.FieldOfView==initialFov,"Native camera or FOV changed");emit("TIMING",metrics)
		local old=Controller.view;old.stop();stopped=true;assert(old.stats().skyLandmark.destroyed and old.stats().skyLandmark.images==0)
		local restored=Diagnostics.restored(old.skyBaseline);assert(restored.pass,Http:JSONEncode(restored));emit("RESTORE",restored)
		Controller.view=View.start(root,{quality=quality});stopped=false;Controller.view.setLook("OFF")
		emit("PASS",{resourcesReleased=true,restarted=inspect()})
	end)
	if stopped then Controller.view=View.start(root,{quality=quality});Controller.view.setLook("OFF")end
	Controller.setQuality(quality);Controller.setReduceMotion(motion)
	if Controller.view then Controller.view.setPose(pose);Controller.view.setMoon("auto")end
	if not ok then emit("FAIL",{error=tostring(err)})end;running=false;return ok
end
local control=Instance.new("BindableFunction");control.Name="SkyLandmarkQA";control.Parent=root
control.OnInvoke=function(action)if action=="check" then task.spawn(checks);return true end;return inspect()end
task.spawn(function()
	for _=1,300 do local s=inspect();if s and s.ready then
		emit("READY",s)
		if workspace:GetAttribute("SkyLandmarkAutoCheck")then
			emit("AWAIT_CHARACTER",{message="Choose a starter familiar normally; probe will not alter the camera or send a choice"})
			for _=1,600 do
				if workspace.CurrentCamera.CameraType==Enum.CameraType.Custom and root:GetAttribute("WillowV2Ready") then task.wait(3);checks();return end
				task.wait(.2)
			end
			emit("BLOCKED",{error="Ordinary character camera and WillowV2Ready not both available within 120 seconds"})
		end
		return
	end;task.wait(.1)end
	emit("BLOCKED",{error="Landmark did not become ready in 30 seconds",landmark=inspect()})
end)
script.Destroying:Connect(function()control:Destroy()end)
