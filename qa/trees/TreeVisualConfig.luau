--!strict
-- Species data, stable instance identity and geometry selection; no Roblox services.
local M={}
M.species=({willow={baseHeight=30.99751,scaleMin=.96,scaleMax=1.04,crownVariants=3,rootVariants=3,
	foliageDensity=76/84,foliagePalette={{.70,.84,.82},{.72,.82,.84},{.68,.85,.80}},
	barkPalette={{.94,.83,.69},{.88,.78,.68},{1,.88,.75},{.86,.82,.73}},
	bonePrefix="Crown_",bones=8,triangleBudget=6500,triangles=5783,
	collider={x=-3,y=6.4,z=0,width=3.8,height=12.8,depth=3.8},
	wind={amplitude=.077,speed=.82,gustResponse=.55,smoothing=1.1,phaseSpread=.79,branchDelay=.16,
		budgets={full={hz=30,distance=220,trees=20,scale=1},reduced={hz=15,distance=150,trees=12,scale=.8},minimal={hz=6,distance=90,trees=6,scale=.4}}}}} :: {[string]:any})
function M.hash(id:string):number
	assert(#id>0,"Tree needs a stable non-empty ID")
	local n=5381
	for i=1,#id do n=(n*33+string.byte(id,i))%2147483647 end
	return n
end
function M.select(species:string,id:string)
	local c=M.species[species];assert(c,"Unknown tree species")
	local function h(s:string):number return M.hash(species..":"..id..":"..s) end
	return {species=species,id=id,crown=h("crown")%c.crownVariants+1,root=h("roots")%c.rootVariants+1,
		foliage=h("leaves")%#c.foliagePalette+1,bark=h("bark")%#c.barkPalette+1,
		scale=c.scaleMin+(c.scaleMax-c.scaleMin)*(h("scale")%10001)/10000,
		phase=(h("phase")%10000)/10000*math.pi*2,yaw=(h("yaw")%360)/180*math.pi}
end
return M
