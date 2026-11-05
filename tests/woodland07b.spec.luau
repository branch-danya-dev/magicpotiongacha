--!nonstrict
local Nature=require("../src/shared/NatureGeometry")
local Forest=require("../src/shared/ForestPlan")
local Meadow=require("../src/shared/MeadowPlan")
local Plan=require("../src/shared/EnvironmentPlan")
local Config=require("../src/shared/EnvironmentConfig")
local Props=require("../src/shared/PropPlan")
local Factory=require("../src/shared/Config")
local Motion=require("../src/shared/MeadowMotion")
return function(T:any)
	T.test("07B: runtime catalog matches the full admitted geometry and no replacement primitives",function()
		for name,g in pairs(Nature) do
			T.equal(Plan.catalog[name][1],g.triangles,name); T.equal(Plan.catalog[name][2],#g.parts,name)
		end
		local trees=0
		for _,p in ipairs(Forest.build()) do if p.forest=="tree" then
			trees+=1; T.equal(p.parts,2); T.equal(p.nativeParts,0)
			T.equal(p.triangles,Nature[p.template].triangles); T.equal(#Forest.crowns(p.species,p.variant),1)
		end end
		T.truthy(trees>=28,"Whole forest, not a few sample objects")
	end)
	T.test("07B: all rotated imported tree vertices remain inside reserved crown radius",function()
		for _,d in ipairs(Forest.build()) do if d.forest=="tree" then
			for _,p in ipairs(Nature[d.template].parts) do
				for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do for deg=0,345,15 do
					local x,z=(p.position[1]+sx*p.size[1]/2)*d.scale,(p.position[3]+sz*p.size[3]/2)*d.scale
					local a=math.rad(deg); local rx,rz=x*math.cos(a)-z*math.sin(a),x*math.sin(a)+z*math.cos(a)
					T.truthy(math.sqrt(rx*rx+rz*rz)<d.radius,d.template)
				end end end
			end
		end end
	end)
	T.test("07B: undergrowth contains fern, flowering shrubs, clover and wildflowers",function()
		local counts={}
		for _,p in ipairs(Forest.build()) do if p.forest=="understory" then counts[p.template]=(counts[p.template] or 0)+1 end end
		for _,name in ipairs({"Fern_1","Bush_Common_Flowers","Clover_2","Flower_3_Group"}) do T.truthy((counts[name] or 0)>=5,name) end
	end)
	T.test("07B: meadow uses smaller upright tufts and multiple flower colors without more plants",function()
		local tall,colors=0,{}
		local plants=Meadow.build(); T.truthy(#plants<=456)
		for _,p in ipairs(plants) do
			if p.template=="Grass_Common_Short" then T.truthy(p.scale<=4.1 and p.flatten>.14) end
			if p.template=="Grass_Wispy_Tall" then tall+=1 end
			if p.template=="Flower_3_Group" then colors[table.concat(p.tint,",")]=true end
		end
		local n=0; for _ in pairs(colors) do n+=1 end
		T.truthy(tall>=30); T.equal(n,3)
	end)
	T.test("07B: actual meadow mesh bounds fit protected station and walking radii",function()
		for _,d in ipairs(Meadow.build()) do for _,p in ipairs(Nature[d.template].parts) do
			local x=math.abs(p.position[1])+p.size[1]/2; local z=math.abs(p.position[3])+p.size[3]/2
			T.truthy(math.sqrt(x*x+z*z)*d.scale<=d.radius,d.template)
		end end
	end)
	T.test("07B: complete pilot pool is smaller than the accepted 07A pool without raising caps",function()
		local plan=Plan.build(Config,1); local parts,triangles=plan.metrics.parts,plan.metrics.triangles
		local function charge(p) local n,t=Props.metrics(p); parts+=n; triangles+=t end
		for _,id in ipairs(Factory.stationOrder) do charge(Props.station(Factory,id)) end
		for _,id in ipairs({"warehouse","altar","orders","blueprint"}) do charge(Props.station(Factory,id)) end
		charge(Props.workshop()); for _=1,6 do charge(Props.lantern()) end
		charge(Props.market(false)); charge(Props.market(false)); charge(Props.market(true))
		parts+=8; triangles+=8*12 -- accepted ridge boundary, not new 07B geometry
		T.truthy(parts<1175 and triangles<324957)
		T.equal(Config.budgets.parts,850); T.equal(Config.budgets.triangles,300000)
		T.equal(plan.metrics.externalTextures,12); T.equal(plan.metrics.lights,6)
	end)
	T.test("07B: imported canopy wind counts each mesh and Reduce Motion clears the whole pool",function()
		local entries={}
		for _,p in ipairs(Forest.build()) do if p.forest=="tree" then table.insert(entries,{visible=true,cost=#Forest.crowns(p.species,p.variant)}) end end
		for _,limit in ipairs({12,4,0,4,12}) do
			for _=1,30 do T.truthy(Motion.step(entries,limit,1/30)<=limit) end
			local count=0; for _,p in ipairs(entries) do if p.weight>0 then count+=p.cost end end
			T.truthy(count<=limit)
		end
	end)
	T.test("07B: every planted object stays in the pilot envelope and retains actual source accounting",function()
		for _,p in ipairs(Forest.build()) do
			T.truthy(Forest.clear(p.x,p.z,p.radius)); T.equal(p.nativeParts,0)
			T.equal(p.meshTriangles,p.triangles)
		end
		T.equal(Plan.build(Config,1).metrics.decoratedPlots,1)
	end)
end
