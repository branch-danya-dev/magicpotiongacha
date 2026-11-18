--!nonstrict
local T=require("./Test")
local A=require("../qa/vegetation/Appearance")
local P=require("../qa/vegetation/TreeWindPolicy")
local W=require("../qa/trees/TreeWindModel")
local budget={hz=30,distance=180,trees=8}
T.test("Vegetation tint channels and caller overrides remain independent",function()
	local original=A.resolve("Natural");local input={LeafColor={.2,.3,.8}}
	local changed=A.resolve("Natural",input);T.same(changed.BarkColor,original.BarkColor);T.same(changed.LeafSecondaryColor,original.LeafSecondaryColor)
	input.LeafColor[1]=0;changed.LeafColor[2]=0
	T.same(A.resolve("Natural"),original);T.equal(changed.LeafColor[1],.2)
end)
T.test("Three palettes retain independent magic settings and two prepared variants",function()
	for _,name in ipairs({"Natural","Enchanted","Blossom"})do
		local v=A.resolve(name,{GeometryVariant="Windswept",WindStrength=.5,MagicGlowIntensity=0})
		T.equal(v.GeometryVariant,"Windswept");T.equal(v.WindStrength,.5);T.equal(v.MagicGlowIntensity,0)
		T.truthy(v.LeafColor~=v.BarkColor and v.LeafColor~=v.LeafSecondaryColor)
	end
end)
T.test("Appearance rejects unsupported geometry and nonfinite parameters",function()
	for _,v in ipairs({{WindStrength=0/0},{MagicGlowIntensity=math.huge},{LeafColor={1,2,0}}, {GeometryVariant="unprepared"},{Gold=100}})do T.falsy(pcall(A.resolve,"Natural",v))end
	T.falsy(pcall(A.resolve,"unknown"))
end)
T.test("Distance LOD progressively reduces work and excludes far or invalid trees",function()
	T.equal(P.rate(budget,20),30);T.equal(P.rate(budget,80),15);T.equal(P.rate(budget,150),10)
	T.equal(P.rate(budget,181),0);T.equal(P.rate(budget,0/0),0);T.equal(P.rate(budget,-1),0)
end)
T.test("Mixed-species scheduling honors global and per-species caps by distance",function()
	local candidates={};for i=1,60 do table.insert(candidates,{id=string.format("tree-%03d",i),distance=i,species="species-"..i%3,budget=budget})end
	for q,cap in pairs({full=20,reduced=12,minimal=6})do
		local picked=P.select(candidates,q);T.equal(#picked,cap)
		local counts={};local last=0
		for _,v in ipairs(picked)do counts[v.species]=(counts[v.species] or 0)+1;T.truthy(v.distance>last);last=v.distance end
		for _,n in pairs(counts)do T.truthy(n<=8)end
	end
end)
T.test("Nearest-tree selection is deterministic and does not mutate input",function()
	local c={{id="b",species="a",distance=5,budget=budget},{id="a",species="a",distance=5,budget=budget},{id="far",species="a",distance=999,budget=budget}}
	local v=P.select(c,"full");T.equal(#v,2);T.equal(v[1].id,"a");T.equal(c[1].id,"b")
end)
T.test("Tree roots stay fixed and canopy response is delayed and stronger",function()
	T.equal(P.roles.Root.strength,0);T.equal(P.roles.Root.delay,0)
	T.truthy(P.roles.Trunk.strength<P.roles.Branch.strength and P.roles.Branch.strength<P.roles.Foliage.strength)
	T.truthy(P.roles.Trunk.delay<P.roles.Branch.delay and P.roles.Branch.delay<P.roles.Foliage.delay)
	local cfg={amplitude=.055,speed=.75,gustResponse=.45,phaseSpread=.7,branchDelay=0,budgets={full={scale=1}}}
	local branch=W.sample(cfg,12-P.roles.Branch.delay,1,2,1,20,5,"full",false)
	local crownEarlier=W.sample(cfg,12-P.roles.Foliage.delay,1,2,1,20,5,"full",false)
	local sameBranchEarlier=W.sample(cfg,12-(P.roles.Foliage.delay-P.roles.Branch.delay)-P.roles.Branch.delay,1,2,1,20,5,"full",false)
	T.near(crownEarlier,sameBranchEarlier,1e-10);T.truthy(branch~=crownEarlier)
end)
T.test("Per-instance wind remains bounded and allows exact zero",function()
	T.equal(P.strength(nil),1);T.equal(P.strength(0),0);T.equal(P.strength(100),1.5)
	for _,v in ipairs({-1,0/0,math.huge,"bad"})do T.equal(P.strength(v),0)end
end)
T.finish()
