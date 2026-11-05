--!nonstrict
-- Original native model recipes. Pure presentation data; no asset IDs or economy.
local Plan={maxParts=560,maxTriangleCharge=160000,combinedPartLimit=1320,combinedTriangleLimit=465000}
Plan.palette={wood={108,77,56},edge={155,113,75},cream={215,201,162},stone={123,132,128},dark={49,60,65},
	copper={168,112,72},brass={192,157,92},sage={106,142,111},leaf={111,164,100},soil={85,68,53},
	purple={143,127,191},aqua={105,187,189},amber={225,182,102},paper={222,211,171},berry={173,86,105}}
local function kit()
	local pieces={}
	local function add(name,shape,size,position,tint,material,rotation,extra)
		local p={name=name,shape=shape,size=size,position=position,tint=tint,material=material or "SmoothPlastic",
			rotation=rotation or {0,0,0},minLevel=1,maxLevel=4}
		for k,v in pairs(extra or {}) do p[k]=v end
		table.insert(pieces,p); return p
	end
	local function box(n,s,p,c,m,r,e) return add(n,"Block",s,p,c,m,r,e) end
	local function round(n,s,p,c,m,e) return add(n,"Sphere",s,p,c,m,nil,e) end
	local function disc(n,diameter,height,p,c,m,e) return add(n,"Cylinder",{height,diameter,diameter},p,c,m,{0,0,90},e) end
	local function bottle(x,y,z,color,scale,extra)
		scale=scale or 1
		round("Bottle",{.66*scale,.9*scale,.66*scale},{x,y+.45*scale,z},color,nil,extra)
		disc("BottleNeck",.24*scale,.4*scale,{x,y+1*scale,z},"brass","Metal",extra)
	end
	local function bench(width,depth,height)
		box("Worktop",{width,.32,depth},{0,height,0},"edge","Wood")
		for _,x in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
			box("Leg",{.4,height,.4},{x*(width/2-.3),height/2,z*(depth/2-.3)},"wood","Wood")
		end end
	end
	local function roof(width,depth,y,z)
		for _,side in ipairs({-1,1}) do
			box("RoofSlope",{width/2+.3,.28,depth},{side*width/4,y,z},"sage","Wood",{0,0,-side*18})
		end
		box("RoofRidge",{.26,.36,depth+.25},{0,y+width*.08,z},"edge","Wood")
	end
	return pieces,add,box,round,disc,bottle,bench,roof
end

function Plan.station(config,id)
	local def=config.stations[id]; local kind=def and def.archetype or id
	local p,add,box,round,disc,bottle,bench,roof=kit()
	if kind=="crystal" then
		disc("Runestone",3.7,.35,{0,.2,0},"stone","Slate")
		box("CrystalHeart",{1.8,2.4,1.8},{0,2.5,0},"purple",nil,{0,45,0},{role="crystal"})
		for _,side in ipairs({-1,1}) do
			add("CrystalTip","Wedge",{1.8,1.5,.9},{0,4.45,side*.45},"aqua",nil,{0,side==1 and 0 or 180,0},{role="crystal"})
			box("Satellite",{.55,1.7,.6},{side*1.25,1.35,.1},"aqua",nil,{0,25,side*18},{minLevel=2})
		end
		for i=1,3 do disc("Rune"..i,.22,.06,{math.cos(i*2.1)*1.4,.42,math.sin(i*2.1)*1.4},"brass","Metal") end
	elseif kind=="cauldron" then
		for i=0,2 do local a=i*math.pi*2/3
			box("TripodFoot",{.42,1.3,.42},{math.cos(a)*1.25,.65,math.sin(a)*1.25},"dark","Metal",{0,0,0})
		end
		round("IronBowl",{3.65,2.45,3.65},{0,1.95,0},"dark","Metal",{role="vessel"})
		disc("RolledRim",3.7,.22,{0,3.14,0},"copper","Metal",{role="vessel"})
		disc("PotionSurface",3.1,.05,{0,3.29,0},"sage",nil,{role="liquid"})
		for _,x in ipairs({-2,2}) do
			box("Handle",{.3,.85,1.1},{x,2.6,0},"copper","Metal")
		end
		box("Ladle",{.12,2.7,.12},{.85,3.65,0},"edge","Wood",{0,0,-22})
		round("LadleCup",{.5,.2,.5},{1.35,4.85,0},"copper","Metal")
		bottle(-2.8,.2,1.6,"purple",.7,{minLevel=2})
	elseif kind=="distillery" then
		bench(6.3,3.7,1.1)
		round("CopperBoiler",{2.5,2.4,2.5},{-1.5,2.4,0},"copper","Metal")
		disc("BoilerNeck",.7,1.15,{-1.5,4,0},"brass","Metal")
		box("SwanNeck",{3,.28,.28},{-.1,4.45,0},"copper","Metal",{0,0,-9})
		disc("Condenser",1.3,2.6,{1.6,2.7,0},"sage","Metal")
		for i=1,3 do disc("CoilBand",1.4,.16,{1.6,1.5+i*.65,0},"copper","Metal") end
		bottle(2.6,1.3,1,"aqua",.75)
	elseif kind=="garden" then
		box("SoilBed",{6.4,.3,4.5},{0,.18,0},"soil","Ground")
		for _,x in ipairs({-3.25,3.25}) do box("BedEnd",{.22,.65,4.9},{x,.4,0},"edge","Wood") end
		for _,z in ipairs({-2.35,2.35}) do box("BedRail",{6.6,.65,.22},{0,.4,z},"wood","Wood") end
		for _,x in ipairs({-1.8,0,1.8}) do
			if id=="mushrooms" then
				disc("MushroomStalk",.24,1,{x,.85,0},"cream")
				round("MushroomCap",{1.25,.6,1.25},{x,1.4,0},"purple")
			elseif id=="berries" then
				round("BerryBush",{1.4,1.55,1.2},{x,1.2,0},"leaf")
				round("BerryCluster",{.45,.5,.45},{x+.25,1.5,.6},"berry")
			else
				round("MandrakeRoot",{.65,.8,.65},{x,.7,0},"cream")
				for _,side in ipairs({-1,1}) do add("BroadLeaf","Wedge",{.85,.2,1.4},{x+side*.3,1.2,0},"leaf",nil,{side*15,side*35,0}) end
			end
		end
	elseif kind=="mine" then
		for i=1,3 do add("CoalOutcrop","Wedge",{1.7,1.7+i*.3,2.8},{(i-2)*1.7,1.2,-.8},"stone","Slate",{0,i*26,0}) end
		for _,x in ipairs({-2.6,2.6}) do box("MineTimber",{.45,3.7,.5},{x,1.85,0},"wood","Wood") end
		box("MineLintel",{5.7,.5,.6},{0,3.5,0},"edge","Wood",{0,0,-4})
		box("OreBarrow",{2.8,.65,1.5},{0,.6,1.5},"edge","Wood")
		for i=1,3 do box("CoalChunk",{.7,.6,.65},{i-2,1.15,1.5},"dark","Slate",{0,i*28,15}) end
	elseif kind=="logistics" then
		box("CartBed",{4.7,.35,3.6},{0,1.2,0},"edge","Wood")
		for _,x in ipairs({-2.5,2.5}) do for _,z in ipairs({-1.2,1.2}) do
			add("CartWheel","Cylinder",{.28,1.5,1.5},{x,.75,z},"dark","Wood")
		end end
		for _,x in ipairs({-2.2,2.2}) do box("CartSide",{.25,.85,3.6},{x,1.75,0},"wood","Wood") end
		box("DeliveryBasket",{2.5,.85,2},{0,1.8,0},"cream","Wood")
		for _,x in ipairs({-.8,.8}) do bottle(x,2.25,0,"sage",.65) end
	elseif kind=="press" then
		bench(5.5,3.8,1.05)
		for _,x in ipairs({-2.1,2.1}) do box("PressUpright",{.5,3.7,.55},{x,2.9,0},"wood","Wood") end
		box("PressCrossbar",{4.8,.5,.7},{0,4.6,0},"edge","Wood")
		disc("PressScrew",.3,2.6,{0,3.5,0},"dark","Metal")
		disc("PressPlate",2.5,.2,{0,2.2,0},"brass","Metal")
		disc("PressBasket",2.7,1.05,{0,1.65,0},"edge","Wood")
		box("PressHandle",{2.4,.18,.18},{0,4.9,0},"dark","Metal")
	elseif kind=="centrifuge" then
		disc("RotorPlinth",3.7,.6,{0,.4,0},"stone","Slate")
		disc("RotorHousing",3,1.5,{0,1.4,0},"dark","Metal")
		disc("RotorDeck",3.1,.2,{0,2.25,0},"copper","Metal")
		for i=0,3 do local a=i*math.pi/2; bottle(math.cos(a),2.4,math.sin(a),"aqua",.8) end
		disc("Flywheel",.5,1.1,{0,2.85,0},"brass","Metal")
	elseif kind=="warehouse" then
		bench(6.7,3.8,.6)
		for _,x in ipairs({-2.8,2.8}) do box("ShelfUpright",{.35,4.6,.4},{x,2.7,-1.3},"wood","Wood") end
		for _,y in ipairs({1.6,3.3}) do box("Shelf",{5.9,.24,1.6},{0,y,-.7},"edge","Wood") end
		for i=1,3 do bottle((i-2)*1.5,1.8,-.7,"sage",.9) end
		box("StorageChest",{3.6,1.25,1.5},{0,1.3,1.1},"wood","Wood")
		for _,x in ipairs({-1.25,1.25}) do box("ChestStrap",{.2,1.3,1.55},{x,1.3,1.1},"brass","Metal") end
		roof(6.8,3.4,5.1,-.3)
	elseif kind=="orders" then
		for _,x in ipairs({-2.5,2.5}) do box("NoticePost",{.35,4.8,.4},{x,2.4,0},"wood","Wood") end
		box("NoticeBoard",{5.3,2.8,.25},{0,3.2,0},"edge","Wood")
		for i=1,3 do box("ContractParchment",{1.25,1.7,.06},{(i-2)*1.55,3.2,.18},"paper",nil,{0,0,(i-2)*6}) end
		roof(5.7,1.8,5.1,0)
	elseif kind=="altar" then
		disc("MoonPlinth",4.5,.35,{0,.2,0},"stone","Slate")
		disc("AltarStem",2.2,1.6,{0,1.15,0},"stone","Slate")
		disc("OfferingBowl",3.7,.3,{0,2.1,0},"brass","Metal")
		round("FamiliarEgg",{1.35,1.8,1.35},{0,3,0},"cream")
		for _,x in ipairs({-1.5,1.5}) do box("Candle",{.25,.8,.25},{x,2.6,0},"cream") end
	elseif kind=="blueprint" then
		bench(5.6,3.8,1.9)
		box("PlanningMap",{4.4,.06,2.6},{0,2.1,0},"paper")
		for _,x in ipairs({-2.3,2.3}) do add("MapRoll","Cylinder",{3,.22,.22},{x,2.24,0},"cream",nil,{0,90,0}) end
		box("ClosedLedger",{1.2,.3,1.5},{1.6,2.35,1.2},"sage",nil,{0,15,0})
	else error("No authored station recipe: "..tostring(id)) end
	if def then
		-- Small surveyed plot, not an opaque ghost machine. Never signals affordability.
		for _,x in ipairs({-2.8,2.8}) do box("SitePeg",{.15,.55,.15},{x,.27,2.2},"edge","Wood",nil,{minLevel=0,maxLevel=0}) end
		box("SitePlan",{1.2,.07,.8},{0,.07,1.8},"paper",nil,nil,{minLevel=0,maxLevel=0})
	end
	if def or id=="warehouse" then
		box("TierBand",{1.4,.16,.15},{0,.55,2.65},"brass","Metal",nil,{minLevel=2})
		box("MasterSeal",{.4,.45,.16},{0,.95,2.65},"aqua",nil,nil,{minLevel=3})
	end
	if def then disc("StatusInlay",.24,.06,{2.9,.15,2.65},"brass",nil,{role="status"}) end
	return p
end

function Plan.lantern()
	local p,_,box,_,disc,_,_,roof=kit()
	box("AmberPane",{.6,.9,.6},{0,0,0},"amber","Neon")
	for _,x in ipairs({-.4,.4}) do for _,z in ipairs({-.4,.4}) do box("LanternCage",{.1,1.25,.1},{x,0,z},"dark","Metal") end end
	disc("LanternFoot",1.1,.16,{0,-.65,0},"brass","Metal")
	roof(1.35,1.25,.7,0)
	return p
end

function Plan.market(counterOnly)
	local p,add,box,_,_,bottle,bench,roof=kit()
	bench(counterOnly and 4.6 or 8.8,counterOnly and 3.4 or 3.1,1.8)
	for _,x in ipairs({-1.3,0,1.3}) do bottle(x,2,0,"purple",.65) end
	box("TradingLedger",{1.3,.2,1},{0,2.1,1},"paper",nil,{0,12,0})
	if not counterOnly then
		for _,x in ipairs({-4.5,4.5}) do for _,z in ipairs({-2.3,2.3}) do box("StallPost",{.35,6.3,.35},{x,3.15,z},"wood","Wood") end end
		roof(10.4,6.6,6.9,0)
		for i=-2,2 do add("ScallopedValance","Wedge",{1.9,.65,.2},{i*1.95,6.15,3.1},i%2==0 and "cream" or "sage",nil,{0,0,180}) end
	end
	return p
end

function Plan.workshop()
	local p,_,box,_,disc,_,_,roof=kit()
	-- Open-front back pavilion stays inside the unused rear strip of the pilot.
	for _,x in ipairs({-22,0,22}) do
		box("PavilionPost",{.65,6.4,.65},{x,3.2,0},"wood","Wood",nil,{minPhase=2,role="structure"})
	end
	box("PavilionBack",{45,3.2,.4},{0,1.6,-1.5},"wood","Wood",nil,{minPhase=2,role="structure"})
	for i=-2,2 do
		box("PavilionPanel",{8.6,1.1,.16},{i*9,2.3,-1.2},"cream",nil,nil,{minPhase=2})
	end
	roof(46,5.4,7.2,0)
	for _,piece in ipairs(p) do piece.minPhase=piece.minPhase or 2 end
	for _,x in ipairs({-22,22}) do
		disc("MasonryFoot",1.55,.6,{x,.35,0},"stone","Slate",{minPhase=3})
		box("CopperConduit",{.16,5.2,.16},{x+.55,3,0},"copper","Metal",nil,{minPhase=4})
		box("AetherInlay",{.17,1.3,.2},{x+.55,4.8,.05},"aqua",nil,nil,{minPhase=4})
	end
	return p
end

function Plan.state(config,profile,id,production)
	local station=profile and profile.stations[id]
	local item=station and station.cauldronId and profile.cauldrons[station.cauldronId]
	return {level=station and station.level or (config.stations[id] and 0 or (id=="warehouse" and profile and profile.warehouseLevel+1 or 1)),
		phase=profile and profile.phase or 1,working=production and production[id] and production[id].code=="working" or false,
		blocked=production and production[id] and production[id].code~="working" and production[id].code~="idle" or false,
		spectral=item and item.type=="spectral" or false,resonant=item and item.type=="resonant" or false}
end
function Plan.appearance(p,s)
	local visible=s.level>=p.minLevel and s.level<=p.maxLevel and s.phase>=(p.minPhase or 1)
	local tint,material=p.tint,p.material
	if p.role=="status" then tint=s.working and "aqua" or (s.blocked and "amber" or "brass") end
	if p.role=="vessel" then
		if s.spectral then tint="aqua"
		elseif s.resonant or s.level==2 then tint="copper"
		elseif s.level>=3 then tint="brass" end
	end
	if p.role=="liquid" then tint=s.spectral and "aqua" or "sage" end
	if p.role=="crystal" then material="SmoothPlastic" end
	if p.role=="structure" and s.phase>=3 then tint=s.phase==4 and "dark" or "stone"; material=s.phase==4 and "Metal" or "Slate" end
	return visible,tint,material
end
function Plan.metrics(pieces)
	local triangles=0
	for _,p in ipairs(pieces) do triangles+=p.shape=="Sphere" and 1024 or (p.shape=="Cylinder" and 192 or 12) end
	return #pieces,triangles
end
-- Rotated bounding boxes allow tests to protect paths/pads without Roblox types.
function Plan.extents(p)
	local x,y,z=math.rad(p.rotation[1]),math.rad(p.rotation[2]),math.rad(p.rotation[3])
	local a,b,c,d,e,f=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
	local rows={{c*e,-c*f,d},{a*f+b*d*e,a*e-b*d*f,-b*c},{b*f-a*d*e,b*e+a*d*f,a*c}}
	local half={}
	for i=1,3 do half[i]=0; for j=1,3 do half[i]+=math.abs(rows[i][j])*p.size[j]/2 end end
	return half
end
return Plan
