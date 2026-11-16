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
local floor=assert(root:FindFirstChild("ForestFloor"),"AG76-R1 walkable forest surface missing")
assert(floor:IsA("Part") and floor.Shape==Enum.PartType.Cylinder and floor.CanCollide)
assert(floor.Size.Y>=Island.surface.width and floor.Size.Z>=Island.surface.depth)
assert(math.abs(floor.Position.X-Island.origin[1])<.01)
assert(root:GetAttribute("IslandSurfaceWidth")==Island.surface.width)
assert(root:GetAttribute("IslandSurfaceDepth")==Island.surface.depth)
local relief=assert(root:FindFirstChild("EnvironmentArt"),"AG76-R1 relief missing")
local terrainCount=0
local terrainNames={}
for _,descriptor in ipairs(Island.terrainPlan()) do
	assert(relief:FindFirstChild(descriptor.name),"Missing terrain piece: "..descriptor.name)
	terrainNames[descriptor.name]=true
end
for _,piece in ipairs(relief:GetChildren()) do
	-- IslandLantern_* are lighting anchors, not terrain. Validate the exact plan.
	if terrainNames[piece.Name] then
		assert(piece:IsA("BasePart") and piece.Anchored and not piece.CanCollide)
		terrainCount+=1
	end
end
assert(terrainCount==root:GetAttribute("IslandTerrainParts"))
assert(terrainCount>=50 and terrainCount<=Island.maxTerrainParts)
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
	schema=Config.schemaVersion,instances=#root:GetDescendants(),sceneryParts=root:GetAttribute("IslandSceneryParts"),terrainParts=terrainCount,
	surfaceWidth=Island.surface.width,surfaceDepth=Island.surface.depth,memory=true,trading=false,purchases=false}))
