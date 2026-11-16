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
	-- Keyboard contract: Roblox's default Tab PlayerList cannot overlay the
	-- RPG Inventory. Observe only; this QA script never changes CoreGui state.
	local tabUsesKeyboard=workspace:GetAttribute("AG75GroupedHUDEnabled")==true
		and game:GetService("UserInputService").KeyboardEnabled
	if tabUsesKeyboard then
		local starterGui=game:GetService("StarterGui")
		local ui=player:WaitForChild("PlayerGui"):WaitForChild("PotionTycoonUI",10)
		local suppressed=false
		for _=1,20 do
			local ok,enabled=pcall(function() return starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) end)
			if ok and not enabled and ui and ui:GetAttribute("AG75PlayerListSuppressed")==true then
				suppressed=true;break
			end
			task.wait(.25)
		end
		assert(suppressed,"AG76-R1: Tab still conflicts with Roblox PlayerList")
	end
	print("AG76_NATIVE_CLIENT_PASS",game:GetService("HttpService"):JSONEncode({owner=player.UserId,stations=n,
		gold=snapshot.gold,essence=snapshot.essence,starterClaimed=snapshot.starter.claimed,
		playerListSuppressed=tabUsesKeyboard,memory=true}))
end)
