--!nonstrict
local Plan=require("../src/shared/PropPlan")
local Config=require("../src/shared/Config")
local Environment=require("../src/shared/EnvironmentPlan")
local EnvironmentConfig=require("../src/shared/EnvironmentConfig")
local Factory=require("../src/shared/Factory").new(Config)
local H=require("./M5Harness")
local ids={}; for _,id in ipairs(Config.stationOrder) do table.insert(ids,id) end
for _,id in ipairs({"warehouse","orders","altar","blueprint"}) do table.insert(ids,id) end
local function visible(pieces,state)
	local result={}; for _,p in ipairs(pieces) do if Plan.appearance(p,state) then result[p.name]=true end end
	return result
end
return function(T:any)
	T.test("19f: every fixed station and service has an original deterministic model",function()
		for _,id in ipairs(ids) do
			local pieces=Plan.station(Config,id); T.same(pieces,Plan.station(Config,id)); T.truthy(#pieces>=6 and #pieces<=34,id)
			for _,p in ipairs(pieces) do
				T.truthy(Plan.palette[p.tint]); T.truthy(({Block=true,Sphere=true,Cylinder=true,Wedge=true})[p.shape])
				for _,v in ipairs(p.size) do T.truthy(v>0 and v<8,id) end
			end
		end
		T.throws(function() Plan.station(Config,"not_a_station") end)
	end)
	T.test("19f: rotated station geometry stays in reserved station footprints and below labels",function()
		for _,id in ipairs(ids) do for _,p in ipairs(Plan.station(Config,id)) do
			local e=Plan.extents(p)
			T.truthy(math.abs(p.position[1])+e[1]<=3.95,id.." x / "..p.name)
			T.truthy(math.abs(p.position[3])+e[3]<=3.15,id.." z / "..p.name)
			T.truthy(p.position[2]+e[2]<6.8,id.." label / "..p.name)
			T.truthy(p.position[2]-e[2]>=-.22,id.." ground / "..p.name)
		end end
	end)
	T.test("19f: no station artwork covers any purchase pad or its approach",function()
		local offsets={warehouse={-8,2,-30},orders={10,2,-30},altar={27,2,-32},blueprint={0,2,10}}
		for id,d in pairs(Config.stations) do offsets[id]=d.offset end
		for _,id in ipairs(ids) do local o=offsets[id]
			for _,p in ipairs(Plan.station(Config,id)) do local e=Plan.extents(p)
				for other,q in pairs(offsets) do if Config.stations[other] or other=="warehouse" or other=="blueprint" then
					T.truthy(math.abs(o[1]+p.position[1]-q[1])>=e[1]+2.5 or math.abs(o[3]+p.position[3]-q[3]-7)>=e[3]+2,id.." over pad "..other)
				end end
			end
		end
	end)
	T.test("19f: potion liquid and rim cover the closed bowl top without intersections",function()
		local pieces=Plan.station(Config,"cauldron"); local named={}; for _,p in ipairs(pieces) do named[p.name]=p end
		local bowl,rim,liquid=named.IronBowl,named.RolledRim,named.PotionSurface
		T.truthy(bowl.position[2]+bowl.size[2]/2<liquid.position[2]-liquid.size[1]/2)
		T.truthy(liquid.size[2]<rim.size[2]); T.truthy(liquid.position[2]>rim.position[2]+rim.size[1]/2)
	end)
	T.test("19f: baseline profile shows only already built machines, not unlocked ghost equipment",function()
		local profile=Factory.newProfile(1,0)
		for id,def in pairs(Config.stations) do
			local state=Plan.state(Config,profile,id,Factory.productionState(profile)); local shown=visible(Plan.station(Config,id),state)
			local level=(id=="garden" or id=="cauldron") and 0 or def.initialLevel
			T.equal(state.level,level)
			T.equal(shown.SitePlan==true,level==0)
			T.equal(shown.StatusInlay==true,level>0)
		end
	end)
	T.test("19f: rendering reads do not mutate economy, inventory or production jobs",function()
		local h=H.new(); h.complete(); local p=h.profile; local before=H.copy(p); local config=H.copy(Config)
		for _=1,20 do for _,id in ipairs(ids) do local s=Plan.state(Config,p,id,h.engine.productionState(p))
			for _,piece in ipairs(Plan.station(Config,id)) do Plan.appearance(piece,s) end
		end end
		T.same(p,before); T.same(Config,config)
	end)
	T.test("19f: failed build leaves surveyed site; paid build shows actual tier and replay is unchanged",function()
		local h=H.new(); local p=h.profile; local pieces=Plan.station(Config,"mine"); p.gold=0
		T.falsy(h.command("build",{upgradeId="mine",expectedLevel=0}))
		T.truthy(visible(pieces,Plan.state(Config,p,"mine")).SitePlan)
		p.gold=100; local request={upgradeId="mine",expectedLevel=0,requestId=p.progression.sequence+1}
		T.truthy(h.command("build",request)); local before=H.copy(p)
		local shown=visible(pieces,Plan.state(Config,p,"mine")); T.truthy(shown.CoalOutcrop); T.falsy(shown.SitePlan)
		T.truthy(h.command("build",request)); T.same(p,before)
	end)
	T.test("19f: all three purchased tiers add decoration without expanding the station footprint",function()
		local h=H.new(); h.toPhase(4)
		for _,id in ipairs(Config.stationOrder) do
			local pieces=Plan.station(Config,id); h.profile.stations[id].level=0; h.profile.stations[id].recipeId=nil; h.profile.stations[id].essence=0
			for level=1,3 do
				T.truthy(h.command("build",{upgradeId=id,expectedLevel=level-1}))
				local shown=visible(pieces,Plan.state(Config,h.profile,id))
				T.equal(shown.TierBand==true,level>=2); T.equal(shown.MasterSeal==true,level>=3)
			end
		end
	end)
	T.test("19f: warehouse level zero is a usable storage model and all capacity upgrades stay visible",function()
		local h=H.new(); local pieces=Plan.station(Config,"warehouse")
		for level=0,3 do
			h.profile.warehouseLevel=level
			local s=Plan.state(Config,h.profile,"warehouse"); T.equal(s.level,level+1)
			T.truthy(visible(pieces,s).StorageChest)
		end
	end)
	T.test("19f: workshop phase changes have no phase-one shell and retain the back-strip clearance",function()
		local h=H.new(); local pieces=Plan.workshop(); T.equal(next(visible(pieces,Plan.state(Config,h.profile,"workshop"))),nil)
		for phase=2,4 do
			h.toPhase(phase); local s=Plan.state(Config,h.profile,"workshop"); local shown=visible(pieces,s)
			T.truthy(shown.RoofSlope); T.equal(shown.MasonryFoot==true,phase>=3); T.equal(shown.AetherInlay==true,phase==4)
			for _,p in ipairs(pieces) do local e=Plan.extents(p)
				T.truthy(math.abs(p.position[1])+e[1]<=23.5)
				T.truthy(p.position[3]+e[3]-41.5<=-38.5)
			end
		end
	end)
	T.test("19f: release and a new tenant cannot retain purchased machines or workshop phases",function()
		local old=H.new(); old.complete()
		for _,id in ipairs(Config.stationOrder) do
			local s=Plan.state(Config,nil,id); T.equal(s.level,0); T.equal(s.phase,1); T.falsy(s.spectral); T.falsy(s.working)
		end
		local fresh=Factory.newProfile(2,0)
		T.equal(Plan.state(Config,fresh,"cauldron2").level,0)
		T.equal(next(visible(Plan.workshop(),Plan.state(Config,fresh,"workshop"))),nil)
	end)
	T.test("19f: real Rebirth clears visual tiers and equipped vessel but preserves collection",function()
		local h=H.new(); h.complete(); local collection=H.copy(h.profile.cauldrons)
		T.truthy(Plan.state(Config,h.profile,"cauldron2").level==3); T.truthy(h.rebirth())
		for id,def in pairs(Config.stations) do T.equal(Plan.state(Config,h.profile,id).level,def.initialLevel) end
		T.same(h.profile.cauldrons,collection); T.equal(next(visible(Plan.workshop(),Plan.state(Config,h.profile,"workshop"))),nil)
	end)
	T.test("19f: seasonal cauldron tint clears on unequip and does not create light or alter stats",function()
		local h=H.new(); local p=h.profile; local station=p.stations.cauldron
		station.cauldronId="visual-fixture"; p.cauldrons["visual-fixture"]={type="spectral"}
		local before=H.copy(p); local s=Plan.state(Config,p,"cauldron")
		for _,piece in ipairs(Plan.station(Config,"cauldron")) do if piece.role=="vessel" then
			local _,tint=Plan.appearance(piece,s); T.equal(tint,"aqua")
		end end
		T.same(p,before); station.cauldronId=nil; T.falsy(Plan.state(Config,p,"cauldron").spectral)
		station.cauldronId="visual-fixture"; p.cauldrons["visual-fixture"].type="resonant"
		for _,piece in ipairs(Plan.station(Config,"cauldron")) do if piece.role=="vessel" then
			local _,tint=Plan.appearance(piece,Plan.state(Config,p,"cauldron")); T.equal(tint,"copper")
		end end
	end)
	T.test("19f: production inlays reflect working versus waiting without inventing production",function()
		local h=H.new(); local p=h.profile; local before=H.copy(p)
		local a=Plan.state(Config,p,"cauldron",{cauldron={code="working"}})
		local b=Plan.state(Config,p,"cauldron",{cauldron={code="waiting_essence"}})
		T.truthy(a.working); T.falsy(a.blocked); T.falsy(b.working); T.truthy(b.blocked)
		T.same(p,before)
	end)
	T.test("19f: lanterns and limited market sample fit their original sites and keep central access",function()
		for _,p in ipairs(Plan.market(false)) do local e=Plan.extents(p)
			T.truthy(math.abs(p.position[1])+e[1]<=5.5)
			T.truthy(math.abs(p.position[3])+e[3]<=3.5)
			-- Samples at x +/-12, z -20.5 leave the original bazaar approach open.
			T.truthy(12-math.abs(p.position[1])-e[1]>6)
		end
		for _,p in ipairs(Plan.market(true)) do local e=Plan.extents(p)
			T.truthy(math.abs(p.position[1])+e[1]<2.5 and math.abs(p.position[3])+e[3]<2.5)
		end
		for _,p in ipairs(Plan.lantern()) do T.falsy(p.light); T.falsy(p.texture) end
	end)
	T.test("19f: full preallocated prop pool including hidden upgrades fits an explicit combined budget",function()
		local count,triangles=0,0
		local function add(p,n) local a,b=Plan.metrics(p); count+=a*(n or 1); triangles+=b*(n or 1) end
		for _,id in ipairs(ids) do add(Plan.station(Config,id)) end
		add(Plan.lantern(),6); add(Plan.market(false),2); add(Plan.market(true)); add(Plan.workshop())
		T.truthy(count<=Plan.maxParts); T.truthy(triangles<=Plan.maxTriangleCharge)
		local env=Environment.build(EnvironmentConfig,1)
		T.truthy(count+env.metrics.parts<=Plan.combinedPartLimit)
		T.truthy(triangles+env.metrics.triangles<=Plan.combinedTriangleLimit)
		print("M7_19F_BUDGET props="..count.." charges="..triangles.." combined="..(count+env.metrics.parts).." combinedCharges="..(triangles+env.metrics.triangles))
	end)
end
