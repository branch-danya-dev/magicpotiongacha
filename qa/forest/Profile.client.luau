--!nonstrict
-- Explicit, bounded native Studio experiment; no production animation owner.
local Run=game:GetService("RunService");assert(Run:IsStudio())
local started=os.clock();local Stats=game:GetService("Stats");local Http=game:GetService("HttpService")
local startup={};local startupConnection=Run.RenderStepped:Connect(function(dt)startup[#startup+1]=dt*1000 end)
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Summary=require(Shared.ForestPerfStats)
local O=Vector3.new(table.unpack(require(Shared.PersonalIsland).origin))
local root=workspace:WaitForChild("PotionTycoonWorld")
local function emit(kind,data)print("FOREST_PERF "..kind.." "..Http:JSONEncode(data))end
local readyAt
while not root:GetAttribute("LandscapeRiggedReady")do
	Run.RenderStepped:Wait()
	assert(os.clock()-started<90,"Forest profiling startup timeout")
end
readyAt=os.clock()-started
startupConnection:Disconnect()
emit("startup",{readySec=readyAt,frames=#startup>0 and Summary.summary(startup)or nil,memoryMiB=Stats:GetTotalMemoryUsageMb(),code=workspace:GetAttribute("ForestCodeSHA256")})
local qa=root:WaitForChild("CurrentGameQA");local grove=root:WaitForChild("LandscapeQA")
local control=Instance.new("BindableFunction");control.Name="ForestPerfQA";control.Parent=root
local running=false
local originals={};local static=root.EnvironmentArt:WaitForChild("LandscapeStatic");local rigged=root:WaitForChild("LandscapeRigged")
for _,m in ipairs(static:GetChildren())do originals[m]={parent=static,tree=m.Name:match("^forest%-")~=nil}end
originals[rigged]={parent=root,tree=true}
local function show(trees,cover)
	for m,d in pairs(originals)do m.Parent=((d.tree and trees)or(not d.tree and cover))and d.parent or nil end
end
local function property(name)local ok,v=pcall(function()return Stats[name]end);return ok and v or nil end
local function run(label,soak)
	assert(not running);assert(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom,"Choose a familiar first")
	running=true;root:SetAttribute("ForestPerfRunning",true)
	task.spawn(function()
		local camera=workspace.CurrentCamera;local character=game.Players.LocalPlayer.Character;local hum=character:FindFirstChildOfClass("Humanoid")
		local oldCF,oldCam,oldMode=character:GetPivot(),camera.CFrame,workspace:GetAttribute("SkyTreeDepthMode")
		local old=grove:Invoke("inspect");local poses={"day","dusk","night"}
		local passed,message=pcall(function()
			local stages=soak and {{id="soak",trees=true,cover=true,wind=true,mode="R3",quality="reduced",seconds=300}}or{
				{id="noForest",trees=false,cover=false,wind=false,mode="R3"},
				{id="trees",trees=true,cover=false,wind=false,mode="R3"},
				{id="understory",trees=true,cover=true,wind=false,mode="R3"},
				{id="windR3",trees=true,cover=true,wind=true,mode="R3"},
				{id="windR4",trees=true,cover=true,wind=true,mode="R4"}}
			for _,stage in ipairs(stages)do
				show(stage.trees,stage.cover);qa:Invoke("quality",stage.quality or "reduced");qa:Invoke("motion",not stage.wind);qa:Invoke("pose","day");workspace:SetAttribute("SkyTreeDepthMode",stage.mode)
				character:PivotTo(CFrame.new(O+Vector3.new(0,5,20)));hum:MoveTo(O+Vector3.new(0,5,20));camera.CameraType=Enum.CameraType.Scriptable
				task.wait(10)
				local route={{-35,20},{-68,20},{0,20},{68,14},{0,20},{8,-65},{0,20},{0,58},{0,20}}
				local cursor,arrivals,timeouts,due=1,0,0,0
				local frames,render,draw,tri,wind,mem,active={},{},{},{},{},{},{}
				local meshParts={};for _,p in ipairs(workspace:GetDescendants())do if p:IsA("MeshPart")then table.insert(meshParts,p)end end
				local stationary,moving={},{};local freezes={};local t0=os.clock();local lastSecond=-1;local lastWind=-1
				local duration=stage.seconds or 80;local elapsed=0
				while elapsed<duration do
					local dt=Run.RenderStepped:Wait();elapsed=os.clock()-t0
					local ms=dt*1000;frames[#frames+1]=ms;local list=elapsed<15 and stationary or moving;list[#list+1]=ms
					if ms>100 and #freezes<40 then freezes[#freezes+1]={at=elapsed,ms=ms}end
					local pos=character:GetPivot().Position
					if elapsed>=15 then
						local target=O+Vector3.new(route[cursor][1],pos.Y-O.Y,route[cursor][2]);local delta=Vector3.new(pos.X-target.X,0,pos.Z-target.Z).Magnitude
						if due==0 then hum:MoveTo(target);due=elapsed+8
						elseif delta<2.5 or elapsed>due then
							if delta<2.5 then arrivals+=1 else timeouts+=1 end;cursor=cursor%#route+1;due=0
						end
					end
					local angle=elapsed<15 and 0 or math.sin((elapsed-15)*.22)*1.1
					camera.CFrame=CFrame.lookAt(pos+Vector3.new(math.sin(angle)*22,10,math.cos(angle)*22),pos+Vector3.new(0,4,-5));camera.Focus=CFrame.new(pos+Vector3.new(0,3,0))
					if math.floor(elapsed)~=lastSecond then
						lastSecond=math.floor(elapsed);mem[#mem+1]=Stats:GetTotalMemoryUsageMb()
						local rc=property("RenderCPUFrameTime");if rc then render[#render+1]=rc*1000 end
						local dc=property("SceneDrawcallCount");if dc then draw[#draw+1]=dc end
						local tc=property("SceneTriangleCount");if tc then tri[#tri+1]=tc end
						local visible=0;for _,p in ipairs(meshParts)do if p.Parent and p.Transparency<.999 and p.LocalTransparencyModifier<.999 then visible+=1 end end;active[#active+1]=visible
						local s=grove:Invoke("inspect");if s.wind and s.wind.updates~=lastWind then wind[#wind+1]=s.wind.lastMs;lastWind=s.wind.updates end
						if soak and lastSecond%30==0 then
							local i=math.floor(lastSecond/30);qa:Invoke("quality",({"full","reduced","minimal"})[i%3+1]);qa:Invoke("motion",i%2==1);qa:Invoke("pose",poses[i%3+1])
						end
					end
				end
				local meta={run=label,stage=stage.id,seconds=elapsed,arrivals=arrivals,timeouts=timeouts,viewport={camera.ViewportSize.X,camera.ViewportSize.Y},fov=camera.FieldOfView,quality=stage.quality or "reduced",mode=stage.mode}
				emit("case",meta);emit("frames",{run=label,stage=stage.id,all=Summary.summary(frames),stationary=Summary.summary(stationary),moving=Summary.summary(moving)})
				emit("resources",{run=label,stage=stage.id,memory=Summary.summary(mem),drawCalls=#draw>0 and Summary.summary(draw)or nil,sceneTriangles=#tri>0 and Summary.summary(tri)or nil})
				emit("meshes",{run=label,stage=stage.id,visibleCandidates=Summary.summary(active),note="nontransparent Workspace MeshParts; includes offscreen; rendered triangles/drawcalls are separate Stats counters"})
				emit("work",{run=label,stage=stage.id,renderCPUms=#render>0 and Summary.summary(render)or nil,windMs=#wind>0 and Summary.summary(wind)or nil})
				for i,f in ipairs(freezes)do emit("stall",{run=label,stage=stage.id,index=i,at=f.at,ms=f.ms})end
				emit("state",{run=label,stage=stage.id,state=grove:Invoke("inspect")})
			end
		end)
		show(true,true);workspace:SetAttribute("SkyTreeDepthMode",oldMode);qa:Invoke("quality",old.quality);qa:Invoke("motion",old.reduceMotion);qa:Invoke("pose",nil)
		character:PivotTo(oldCF);hum:MoveTo(oldCF.Position);camera.CameraType=Enum.CameraType.Custom;camera.CFrame=oldCam
		running=false;root:SetAttribute("ForestPerfRunning",false);root:SetAttribute("ForestPerfComplete",passed)
		emit("complete",{run=label,ok=passed,error=message})
	end)
end
control.OnInvoke=function(action,label)if action=="run"or action=="soak"then run(label,action=="soak")else return {running=running,readySec=readyAt}end;return true end
