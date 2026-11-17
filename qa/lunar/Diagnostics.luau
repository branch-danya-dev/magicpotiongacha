--!nonstrict
-- Read-only QA probe, not an owner. No event connections or writes.
local M={}
local Lighting=game:GetService("Lighting")
local keys={"ClockTime","Brightness","Ambient","OutdoorAmbient","GlobalShadows","ExposureCompensation","GeographicLatitude","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}
function M.snapshot()
	local r={properties={},wind=workspace.GlobalWind,objects={}}
	for _,k in ipairs(keys) do r.properties[k]=Lighting[k] end
	for _,p in ipairs({Lighting,workspace.Terrain}) do for _,v in ipairs(p:GetChildren()) do r.objects[v]=p end end
	return r
end
function M.restored(r)
	local failures={}
	for k,v in pairs(r.properties) do if Lighting[k]~=v then table.insert(failures,k) end end
	if workspace.GlobalWind~=r.wind then table.insert(failures,"GlobalWind") end
	for v,p in pairs(r.objects) do if v.Parent~=p then table.insert(failures,"missing:"..v.Name) end end
	for _,p in ipairs({Lighting,workspace.Terrain}) do for _,v in ipairs(p:GetChildren()) do if not r.objects[v] then table.insert(failures,"extra:"..v.Name) end end end
	if workspace:FindFirstChild("M7ClientWeather") then table.insert(failures,"weather folder survived") end
	return {pass=#failures==0,failures=failures,propertyCount=#keys}
end
return M
