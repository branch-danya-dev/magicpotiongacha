--!nocheck
-- Optional ordinary F5 CLIENT Command Bar. Not mapped into the game.
local q=assert(_G.AG68QA)
assert(game:GetService("RunService"):IsStudio())
local root=workspace.PotionTycoonWorld
assert(root:GetAttribute("EnvironmentArtEnabled")==true,"Preserve an already-enabled review session")
local L=game:GetService("Lighting")
local function same(a,b)
 if type(a)~=type(b) then return false end
 if type(a)=="number" then return math.abs(a-b)<1e-6 end
 if type(a)~="table" then return a==b end
 for k,v in pairs(a) do if not same(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
task.spawn(function()
 root:SetAttribute("EnvironmentArtEnabled",false);task.wait(2)
 local before=q.snapshot();local refs=L:GetChildren();local wind=workspace.GlobalWind
 root:SetAttribute("EnvironmentArtEnabled",true);task.wait(3)
 local counts=workspace.M7ClientWeather.PostFXInspect:Invoke()
 root:SetAttribute("EnvironmentArtEnabled",false);task.wait(2)
 local after=q.snapshot();local identities=#refs==#L:GetChildren()
 for _,v in ipairs(refs) do if v.Parent~=L then identities=false end end
 print("AG68 OWNER_RESTORE "..game:GetService("HttpService"):JSONEncode({restored=same(before,after),sameInstances=identities,
  windRestored=workspace.GlobalWind==wind,restartedLook=counts.postFXLook,weatherRemoved=workspace:FindFirstChild("M7ClientWeather")==nil,
  before=before,after=after}))
 root:SetAttribute("EnvironmentArtEnabled",true)
end)
