--!nonstrict
-- Decorative consumers only. No camera, Lighting owner, input binding or remote.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and workspace:GetAttribute("CurrentGameQA"),"Studio preview only")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local O=Vector3.new(table.unpack(require(Shared.PersonalIsland).origin))
local Assets=require(Shared.EnvironmentAssets)
local gameScripts=script.Parent.Parent:WaitForChild("PotionTycoon")
local Controller=require(gameScripts:WaitForChild("EnvironmentController"))
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("GroundCoverReady") or not Controller.view do task.wait(.1) end
local art=root:WaitForChild("EnvironmentArt")
local cliff=require(script.Parent.Cliff).create(art,O)
local waterfall=require(script.Parent.Waterfall).create(root,O,Assets.uri("mist"))
local models=require(script.Parent.NativeModel).load()
-- Replace the temporary ancient-tree proxy only in this client preview.
-- The native tree remains outside every station footprint and the central path.
local tree=models.create(art,CFrame.new(O+Vector3.new(47,.5,-29)),1)
for _,name in ipairs({"AncientTreeProxy","AncientTreeCrownProxy"}) do
	local proxy=art:FindFirstChild(name);if proxy then proxy:Destroy() end
end
local wind=require(script.Parent.Wind).start({tree})
local cloudAnchor=Instance.new("Part");cloudAnchor.Name="CurrentIslandCloudBank"
cloudAnchor.Anchored=true;cloudAnchor.Transparency=1;cloudAnchor.CanCollide=false;cloudAnchor.CanTouch=false;cloudAnchor.CanQuery=false
cloudAnchor.Position=O+Vector3.new(0,-78,-8);cloudAnchor.Size=Vector3.one;cloudAnchor.Parent=root
local clouds={}
for i=1,3 do
	local a=Instance.new("Attachment");a.Position=Vector3.new((i-2)*64,0,(i%2)*30);a.Parent=cloudAnchor
	local e=Instance.new("ParticleEmitter");e.Name="UnderIslandMist";e.Texture=Assets.uri("mist")
	e.Lifetime=NumberRange.new(30);e.Speed=NumberRange.new(.3,.6);e.SpreadAngle=Vector2.new(180,30);e.Size=NumberSequence.new(100)
	e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.38),NumberSequenceKeypoint.new(.8,.52),NumberSequenceKeypoint.new(1,1)})
	e.Color=ColorSequence.new(Color3.fromRGB(176,187,203));e.LightInfluence=0;e.LightEmission=.12
	e.Rotation=NumberRange.new(0,360);e.RotSpeed=NumberRange.new(-1,1);e.Rate=0;e.Parent=a;table.insert(clouds,e)
end
local quality,motion=nil,nil
local dead=false
local function refresh()
	if quality==Controller.quality and motion==Controller.reduceMotion then return end
	quality=Controller.quality;motion=Controller.reduceMotion
	wind.setQuality(quality);wind.setReduceMotion(motion);waterfall.set(quality,motion)
	for _,e in ipairs(clouds) do
		e:Clear();e.TimeScale=motion and 0 or 1;e.Rate=motion and 0 or (quality=="full" and .2 or quality=="reduced" and .1 or 0)
		e:Emit(motion and 0 or (quality=="minimal" and 2 or 5))
	end
end
refresh()
local elapsed=0
local connection=Run.Heartbeat:Connect(function(dt) elapsed+=dt;if elapsed>=.2 then elapsed=0;refresh() end end)
local control=Instance.new("BindableFunction");control.Name="CurrentGameQA";control.Parent=root
local function inspect()
	local bones=0;for _,v in ipairs(tree:GetDescendants()) do if v:IsA("Bone") then bones+=1 end end
	local weather=0;for _,v in ipairs(workspace:GetChildren()) do if v.Name=="M7ClientWeather" then weather+=1 end end
	return {quality=quality,reduceMotion=motion,willowBones=bones,windUpdates=wind.updates,lightingOwners=weather,
		grass=root:GetAttribute("GrassAddedParts"),cliffTriangles=cliff.triangles,waterfall=waterfall.stats(),environment=Controller.view and Controller.view.stats()}
end
control.OnInvoke=function(action,value)
	if action=="quality" then Controller.setQuality(value);refresh()
	elseif action=="motion" then Controller.setReduceMotion(value);refresh()
	elseif action=="pose" and Controller.view then Controller.view.setPose(value)
	elseif action=="moon" and Controller.view then Controller.view.setMoon(value) end
	return inspect()
end
local function cleanup()
	if dead then return end;dead=true
	connection:Disconnect();wind.stop();models.destroy();waterfall.destroy();cliff.part:Destroy();cliff.mesh:Destroy();cloudAnchor:Destroy();control:Destroy()
end
script.Destroying:Connect(cleanup);art.Destroying:Connect(cleanup)
print("CURRENT_GAME_CLIENT_READY",game:GetService("HttpService"):JSONEncode(inspect()))
