--!nonstrict
-- Reports actual ordinary-Play snapshots; never sends an action or changes the camera.
if not game:GetService("RunService"):IsStudio() or workspace:GetAttribute("AG76PersonalIsland")~=true then return end
local player=game:GetService("Players").LocalPlayer
local folder=game:GetService("ReplicatedStorage"):WaitForChild("PotionTycoon")
local remote=folder:WaitForChild("Remotes"):WaitForChild("State")
local seen=false
remote.OnClientEvent:Connect(function(snapshot)
	if seen then return end;seen=true
	assert(snapshot.mode=="STUDIO_MEMORY","AG76 must never use live persistence")
	local world=workspace:WaitForChild("PotionTycoonWorld")
	local island=world:WaitForChild("Island_primary",20);assert(island,"Island missing on client")
	assert(island:GetAttribute("OwnerUserId")==player.UserId)
	assert(island:GetAttribute("IslandId")==player:GetAttribute("PotionIslandId"))
	local n=0;for _ in pairs(snapshot.stations) do n+=1 end;assert(n==13)
	print("AG76_NATIVE_CLIENT_PASS",game:GetService("HttpService"):JSONEncode({owner=player.UserId,stations=n,
		gold=snapshot.gold,essence=snapshot.essence,starterClaimed=snapshot.starter.claimed,memory=true}))
end)
