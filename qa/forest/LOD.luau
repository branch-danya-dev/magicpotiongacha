--!strict
-- Whole-stand silhouettes are always retained. Only nearest trees are skinned.
local M={}
type Budget={count:number,near:number,far:number}
type Entry={id:string,distance:number,high:boolean?}
M.budgets=({full={count=8,near=58,far=68},reduced={count=4,near=40,far=50},minimal={count=1,near=23,far=31}} :: {[string]:Budget})
function M.select(entries:{Entry},quality:string):{[string]:boolean}
	local b=M.budgets[quality];assert(b,"Unknown forest quality");local eligible:{Entry}={}
	for _,e in ipairs(entries)do
		if e.distance>=0 and e.distance<(e.high and b.far or b.near)then table.insert(eligible,e)end
	end
	table.sort(eligible,function(a:Entry,b:Entry)
		-- Four studs of rank hysteresis prevents repeated swaps near an equal-distance pair.
		local da=a.distance-(a.high and 4 or 0);local db=b.distance-(b.high and 4 or 0)
		return da==db and a.id<b.id or da<db
	end)
	local out={};for i=1,math.min(b.count,#eligible)do out[eligible[i].id]=true end;return out
end
function M.detailAlpha(detail:number,quality:string,distance:number):number
	if detail>=2 and quality=="minimal"then return 1 end
	local far=quality=="full" and 105 or quality=="reduced" and 65 or 42
	return math.clamp((distance-(far-12))/12,0,1)
end
return M
