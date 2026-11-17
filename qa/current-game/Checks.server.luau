--!nonstrict
-- Read-only assertions for the combined preview, not an economy fixture.
assert(game:GetService("RunService"):IsStudio() and workspace:GetAttribute("CurrentGameQA"))
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.Config)
local Island=require(Shared.PersonalIsland)
local Settings=require(game:GetService("ServerScriptService").PotionTycoon.ServerSettings)
local root=workspace:WaitForChild("PotionTycoonWorld",30);assert(root)
local island=root:WaitForChild("Island_primary",30);assert(island,"Owner profile did not load")
while not root:GetAttribute("GroundCoverReady") do task.wait(.1) end
assert(Settings.UseMemoryInStudio and not Settings.TradingEnabled and not Settings.MonetizationEnabled)
assert(Config.schemaVersion==8 and island:GetAttribute("OwnerUserId")==workspace:GetAttribute("AG76QAOwnerUserId"))
for _,id in ipairs(Config.stationOrder) do
	local anchor=assert(island:FindFirstChild(id),id)
	assert((anchor.Position-Vector3.new(table.unpack(Island.origin))-Vector3.new(table.unpack(Config.stations[id].offset))).Magnitude<.01,id.." moved")
end
assert(island:FindFirstChild("SpellbookLectern") and not root.EnvironmentArt:FindFirstChild("SpellbookLectern"),"Duplicate or missing book")
assert(root.ForestFloor.CanCollide and root:GetAttribute("IslandSurfaceWidth")==124 and root:GetAttribute("IslandSurfaceDepth")==116)
assert((root:GetAttribute("GrassAddedParts") or 0)>=150)
print("CURRENT_GAME_SERVER_PASS",game:GetService("HttpService"):JSONEncode({owner=island:GetAttribute("OwnerUserId"),stations=#Config.stationOrder,grass=root:GetAttribute("GrassAddedParts"),schema=Config.schemaVersion,memory=true}))
