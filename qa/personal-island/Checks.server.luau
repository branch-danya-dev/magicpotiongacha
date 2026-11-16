--!nonstrict
-- Read-only native diagnostics for the isolated build. No grants, remotes or persistence.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("AG76PersonalIsland")~=true then return end
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Island=require(Shared.PersonalIsland)
local Config=require(Shared.Config)
local Settings=require(game:GetService("ServerScriptService").PotionTycoon.ServerSettings)
local root=workspace:WaitForChild("PotionTycoonWorld",30)
assert(root,"AG76 native: world not created")
local model=root:WaitForChild("Island_primary",30)
if not model then warn("AG76_NATIVE_PENDING: configured owner has not loaded; check AG76QAOwnerUserId");return end
task.wait(3)
assert(Settings.UseMemoryInStudio and not Settings.TradingEnabled and not Settings.MonetizationEnabled)
assert(Config.schemaVersion==8)
local owner=workspace:GetAttribute("AG76QAOwnerUserId")
assert(model:GetAttribute("OwnerUserId")==owner and model:GetAttribute("IslandId")==Island.identity(owner))
local owned=0
for _,p in ipairs(root:GetChildren()) do
	if p:GetAttribute("OwnerUserId")~=nil then owned+=1 end
	assert(not p.Name:match("^Plot_") and p.Name~="Bazaar" and p.Name~="TradePost")
end
assert(owned==1)
for _,id in ipairs(Config.stationOrder) do
	local p=assert(model:FindFirstChild(id),id)
	assert(p:GetAttribute("StationId")==id and p:GetAttribute("IslandId")==Island.identity(owner))
	local expected=Vector3.new(table.unpack(Island.origin))+Vector3.new(table.unpack(Config.stations[id].offset))
	assert((p.Position-expected).Magnitude<.01,id.." moved")
end
for _,p in ipairs(root:GetDescendants()) do
	assert(not p.Name:match("^Buy_") and p.Name~="Sign" and p.Name~="TradePost")
end
assert((root:GetAttribute("IslandSceneryParts") or math.huge)<=Island.maxSceneryParts)
print("AG76_NATIVE_SERVER_PASS",game:GetService("HttpService"):JSONEncode({owner=owner,islands=owned,logicalStations=#Config.stationOrder,
	schema=Config.schemaVersion,instances=#root:GetDescendants(),sceneryParts=root:GetAttribute("IslandSceneryParts"),memory=true,trading=false,purchases=false}))
