--!nonstrict
assert(game:GetService("RunService"):IsStudio(),"Willow QA only")
local O=Vector3.new(-142.5,0,-65)
local root=Instance.new("Model");root.Name="PotionTycoonWorld";root:SetAttribute("WorldContextOwned",true)
local art=Instance.new("Folder");art.Name="EnvironmentArt";art.Parent=root
local floor=Instance.new("Part");floor.Name="ForestFloor";floor.Size=Vector3.new(350,1,300)
floor.Position=O+Vector3.new(0,-.5,50);floor.Anchored=true;floor.Material=Enum.Material.Ground
floor.Color=Color3.fromRGB(85,99,79);floor.Parent=root
local spawn=Instance.new("SpawnLocation");spawn.Name="WillowQASpawn";spawn.Size=Vector3.new(5,1,5)
spawn.Position=O+Vector3.new(0,.1,-34);spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false
spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root
root.Parent=workspace
