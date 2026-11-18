--!strict
-- Pure QA ablation plan. Only EnvironmentView applies it; never a second owner.
local M={}
M.modes={"candidate","baseline","offset0","offsetNegative","neutralScatter","noAtmosphere","noOcean","noSky","noNativeClouds"}
function M.valid(mode:any):boolean
	return type(mode)=="string" and table.find(M.modes,mode)~=nil
end
function M.plan(mode:string):any
	assert(M.valid(mode),"Unknown horizon comparison")
	return {offset=(mode=="candidate" or mode=="offset0") and 0 or (mode=="offsetNegative" and -.05 or .15),
		atmosphere=mode~="noAtmosphere",ocean=mode~="noOcean",sky=mode~="noSky",nativeClouds=mode~="noNativeClouds",
		neutralScatter=mode=="neutralScatter"}
end
return M
