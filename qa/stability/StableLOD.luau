--!strict
-- P0 default: keep static silhouettes continuously. No high/low mesh swapping
-- while the first-play frame hitch and occlusion invalidation are investigated.
local M={}
type Entry={id:string,distance:number,high:boolean?}
M.budgets={
 full={count=0,near=0,far=0},
 reduced={count=0,near=0,far=0},
 minimal={count=0,near=0,far=0},
}
function M.select(_entries:{Entry},_quality:string):{[string]:boolean}
 return {}
end
function M.detailAlpha(detail:number,quality:string,distance:number):number
 -- Critical foliage silhouettes do not disappear just because camera turned.
 -- Very distant small understory may still be culled in Minimal quality.
 if detail<2 then return 0 end
 if quality=="minimal" and distance>110 then return 1 end
 return 0
end
return M
