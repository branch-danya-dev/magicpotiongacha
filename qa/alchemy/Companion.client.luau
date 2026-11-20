--!nonstrict
-- V1-01: a single decorative starter companion in the owner's isolated Studio QA world.
-- No assignments, buffs, remotes to the server, persistence, collision or pathfinding.
-- Simple placeholder body parts are replaced by the real animated pet assets later.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("AlchemyFirstQA")~=true then return end

local player = Players.LocalPlayer
local stateRemote = ReplicatedStorage:WaitForChild("PotionTycoon"):WaitForChild("Remotes"):WaitForChild("State")
local body, parts, species = nil, {}, nil
local motion = 0
local palette = {
 slime = Color3.fromRGB(117,217,150),
 brewer = Color3.fromRGB(174,146,218),
 farmer = Color3.fromRGB(214,181,114),
}
local function part(name, size, localCFrame, color, shape)
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.Shape=shape or Enum.PartType.Ball
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 p.CastShadow=false;p.Material=Enum.Material.SmoothPlastic;p.Color=color
 p.Parent=body
 table.insert(parts,{part=p,localCFrame=localCFrame})
 return p
end
local function clear()
 if body then body:Destroy() end
 body=nil;species=nil;table.clear(parts)
end
local function show(typeName)
 if typeName==species then return end
 clear()
 if not palette[typeName] then return end
 species=typeName
 body=Instance.new("Model")
 body.Name="V1CompanionVisual"
 body:SetAttribute("VisualOnly",true)
 body:SetAttribute("PlaceholderUntilPetRigImport",true)
 body.Parent=workspace
 local coat=palette[typeName]
 part("Body",Vector3.new(1.15,1.1,1.05),CFrame.new(),coat)
 part("LeftEye",Vector3.new(.15,.21,.1),CFrame.new(-.22,.18,-.48),Color3.fromRGB(33,36,45))
 part("RightEye",Vector3.new(.15,.21,.1),CFrame.new(.22,.18,-.48),Color3.fromRGB(33,36,45))
 if typeName=="brewer" then
  part("LeftEar",Vector3.new(.36,.48,.33),CFrame.new(-.37,.53,0),coat,Enum.PartType.Block)
  part("RightEar",Vector3.new(.36,.48,.33),CFrame.new(.37,.53,0),coat,Enum.PartType.Block)
 elseif typeName=="farmer" then
  part("LeftWing",Vector3.new(.43,.55,.62),CFrame.new(-.66,-.07,0),coat)
  part("RightWing",Vector3.new(.43,.55,.62),CFrame.new(.66,-.07,0),coat)
 end
end
stateRemote.OnClientEvent:Connect(function(state)
 if type(state)~="table" then return end
 local starter=state.starter
 if type(starter)~="table" or starter.legacyGrant==true or starter.claimed~=true then
  clear();return
 end
 show(starter.choice)
end)
RunService.RenderStepped:Connect(function(dt)
 if not body then return end
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root then return end
 motion+=math.min(dt,.05)
 local orbit=Vector3.new(math.sin(motion*.7)*1.1,0,math.cos(motion*.7)*.8)
 local pos=root.Position-root.CFrame.LookVector*3.5+root.CFrame.RightVector*2.2+orbit
 local base=CFrame.lookAt(pos+Vector3.new(0,1.2+math.sin(motion*2.7)*.12,0),
  pos+root.CFrame.LookVector*4+Vector3.new(0,1.2,0))
 for _,entry in ipairs(parts) do entry.part.CFrame=base*entry.localCFrame end
end)
script.Destroying:Connect(clear)
