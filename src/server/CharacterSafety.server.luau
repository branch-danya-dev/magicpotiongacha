--!nonstrict
-- Server-only recovery; no remotes, profile writes, rewards or interaction grants.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Recovery=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.CharacterRecovery)
local Boundary=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.IslandBoundary)
local root=workspace:WaitForChild("PotionTycoonWorld")
local rescues=setmetatable({},{__mode="k"})
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
	elapsed+=dt
	if elapsed<Recovery.interval then return end
	elapsed=0
	for _,player in ipairs(Players:GetPlayers()) do
		local character=player.Character
		local hrp=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local spawn=player.RespawnLocation
		local plot=spawn and spawn.Parent
		if not hrp or not humanoid or humanoid.Health<=0 or not spawn or not plot
			or plot.Parent~=root or plot:GetAttribute("OwnerUserId")~=player.UserId then continue end
		local now=os.clock()
		local last=rescues[character] or -math.huge
		local escaped=root:GetAttribute("EnvironmentArtEnabled")==true and Boundary.escaped(hrp.Position.X,hrp.Position.Z) and now-last>=Recovery.cooldown
		if escaped or Recovery.needed(hrp.Position.Y,hrp.AssemblyLinearVelocity.Y,Recovery.interval,workspace.FallenPartsDestroyHeight,last,now) then
			-- No yield between ownership/character validation and the move.
			humanoid.Sit=false
			hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
			character:PivotTo(spawn.CFrame+Vector3.new(0,4,0))
			rescues[character]=now
			if RunService:IsStudio() then print("M7_18A_RECOVERY ownSpawn="..plot.Name.." alive=true") end
		end
	end
end)
