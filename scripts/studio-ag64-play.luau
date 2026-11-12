-- AG64 local Play diagnostics. Paste into CLIENT Command Bar; never shipped by Rojo.
-- Moves the local test avatar; uses existing validated intents only. No profile edits.
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(),"Client Play only")
if _G.AG64 then _G.AG64.stop() end
local Q={connections={},state=nil,grants=0}
_G.AG64=Q
local p=game.Players.LocalPlayer
local root=game.ReplicatedStorage.PotionTycoon
local R=root.Remotes
local Config=require(root.Shared.Config)
local Access=require(root.Shared.Access)
local J=game:GetService("HttpService")
local function log(label,value) print("AG64 "..label.." "..J:JSONEncode(value)) end
function Q.stop() for _,c in ipairs(Q.connections) do c:Disconnect() end end
table.insert(Q.connections,R.State.OnClientEvent:Connect(function(s)
 local prior=Q.state; Q.state=s
 if not prior or prior.gold~=s.gold or prior.essence~=s.essence or prior.stations.crystal.level~=s.stations.crystal.level then
  log("snapshot",{mode=s.mode,gold=s.gold,essence=s.essence,level=s.stations.crystal.level,offer=s.builds.crystal,receipt=s.presentation.essenceClick})
 end
end))
table.insert(Q.connections,R.Notice.OnClientEvent:Connect(function(n) log("notice",n) end))
function Q.plot() return workspace.PotionTycoonWorld:FindFirstChild("Plot_"..p:GetAttribute("PotionPlotIndex")) end
function Q.near(id)
 local anchor=assert(Q.plot():FindFirstChild(id),id)
 p.Character:PivotTo(anchor.CFrame+Vector3.new(0,3,5)); task.wait(.7)
 return anchor
end
function Q.act(action,payload)
 assert(Q.state and Q.state.mode=="STUDIO_MEMORY","No real saves permitted by this helper")
 payload=payload or {}; local target=Access.target(action,payload); if target then Q.near(target) end
 R.Action:FireServer(action,payload); task.wait(.8)
end
function Q.prepareUpgrade()
 assert(Q.state and Q.state.mode=="STUDIO_MEMORY" and Q.state.stations.garden.level==0,"Fresh memory fixture required")
 if not Q.state.starter.claimed then Q.act("chooseStarter",{speciesId="farmer"}) end
 for _=1,6 do Q.act("click") end
 Q.act("buyStarterStation",{stationId="garden"}); Q.act("buySeed",{amount=5})
 for batch=1,2 do
  Q.act("plantSeed",{bedId=Config.firstSession.bedId}); task.wait(9)
  Q.act("harvestCrop",{bedId=Config.firstSession.bedId})
  if batch==1 then Q.act("buyStarterStation",{stationId="cauldron"}) end
  Q.act("load",{stationId="cauldron"}); Q.act("brew",{stationId="cauldron"}); task.wait(9)
 end
 Q.near("crystal"); log("upgrade-ready",{gold=Q.state.gold,offer=Q.state.builds.crystal})
end
function Q.status()
 local gui=p.PlayerGui.PotionTycoonUI; local hud=gui:FindFirstChild("LandscapeHUD")
 local objects={}
 if hud then for _,o in ipairs(hud:GetChildren()) do if o:IsA("GuiObject") then
  objects[o.Name]={visible=o.Visible,x=o.AbsolutePosition.X,y=o.AbsolutePosition.Y,w=o.AbsoluteSize.X,h=o.AbsoluteSize.Y}
 end end end
 log("ui",{viewport=tostring(workspace.CurrentCamera.ViewportSize),safe=tostring(gui.AbsoluteSize),enabled=gui.Enabled,
  touch=game:GetService("UserInputService").TouchEnabled,menu=hud and hud:GetAttribute("SelectedMenu"),
  legacy=gui.ResourceBar.Visible,objects=objects})
end
function Q.rollback()
 workspace:SetAttribute("UIFoundationDemo",false)
 for _=1,20 do
  workspace:SetAttribute("LandscapeHUDEnabled",false); task.wait(.05)
  local gui=p.PlayerGui.PotionTycoonUI
  assert(not gui:FindFirstChild("LandscapeHUD") and gui.ResourceBar.Visible and gui.Guide.Visible,"Legacy restore")
  workspace:SetAttribute("LandscapeHUDEnabled",true); task.wait(.05)
  assert(gui:FindFirstChild("LandscapeHUD") and not gui.ResourceBar.Visible,"New HUD restore")
 end
 log("rollback",{cycles=20,screenGuis=#p.PlayerGui:GetChildren(),hudCount=1})
end
function Q.sample(label)
 local values={}; local c=game:GetService("RunService").RenderStepped:Connect(function(dt) table.insert(values,dt*1000) end)
 task.wait(3); c:Disconnect(); table.sort(values)
 log("frame-cadence",{label=label,samples=#values,medianMs=values[math.ceil(#values*.5)],p95Ms=values[math.ceil(#values*.95)]})
end
R.Ready:FireServer()
log("installed",{engine=version()})
