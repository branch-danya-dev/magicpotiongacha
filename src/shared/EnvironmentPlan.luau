--!nonstrict
-- One authored farm composition; only the reviewed catalog can be instantiated.
local runtimeScript=rawget(getfenv(),"script")
local Terrain=require(runtimeScript and runtimeScript.Parent.EnvironmentTerrain or "./EnvironmentTerrain")
local FactoryConfig=require(runtimeScript and runtimeScript.Parent.Config or "./Config")
local Meadow=require(runtimeScript and runtimeScript.Parent.MeadowPlan or "./MeadowPlan")
local Plan={catalog={CommonTree_1={1866,2},CommonTree_3={1866,2},CommonTree_5={1866,2},Pine_2={1486,2},TwistedTree_1={1866,2},
	Bush_Common_Flowers={423,2},Clover_2={427,1},Fern_1={288,1},Flower_3_Group={422,2},Grass_Common_Short={155,1},
	Grass_Wispy_Tall={428,1},Pebble_Round_1={136,1},RockPath_Round_Small_1={428,1},Rock_Medium_1={342,1}}}
function Plan.origin(index) return {((index-1)%4-1.5)*95,0,index<=4 and -65 or 85} end
function Plan.build(config,index)
	assert(index==config.pilotPlot,"Gate B requires owner visual approval")
	local o=Plan.origin(index); local parts={}
	local pads={{0,17},{-8,-23}} -- Blueprint and warehouse; other pads use station offsets.
	for _,station in pairs(FactoryConfig.stations) do if station.offset then
		table.insert(pads,{station.offset[1],station.offset[3]+7})
	end end
	local function add(kind,size,pos,color,detail,rotation,extra,world)
		local d={id="Decor_"..(#parts+1),kind=kind,size=size,position=world and pos or {o[1]+pos[1],pos[2],o[3]+pos[3]},color=color,
			detail=detail or 1,rotation=rotation or {0,0,0},material="Wood"}
		for k,v in pairs(extra or {}) do d[k]=v end; table.insert(parts,d); return d
	end
	local function mesh(name,x,z,scale,angle,detail,y)
		assert(Plan.catalog[name],"Unreviewed template")
		if name=="RockPath_Round_Small_1" then
			-- Imported footprint (1.128 x 1.571 studs) plus original 5 x 4 pads.
			local a=math.rad(angle or 0)
			local rx=scale*(1.128*math.abs(math.cos(a))+1.571*math.abs(math.sin(a)))/2
			local rz=scale*(1.128*math.abs(math.sin(a))+1.571*math.abs(math.cos(a)))/2
			for _,pad in ipairs(pads) do
				if math.abs(x-pad[1])<rx+2.7 and math.abs(z-pad[2])<rz+2.2 then return end
			end
		end
		return add("mesh",{scale,scale,scale},{x,y or Terrain.height(o[1]+x,o[3]+z)-.08,z},"cream",detail,{0,angle or 0,0},{template=name,scale=scale,flatten=name=="RockPath_Round_Small_1" and .3 or 1})
	end
	-- Layered groups frame the clearing; every station and the entrance stay open.
	for _,t in ipairs({
		{"CommonTree_1",-49,-25,1.06,25},{"CommonTree_3",-57,-47,.95,105},{"CommonTree_5",-43,-57,1.12,220},
		{"CommonTree_1",-24,-64,1.20,140},{"Pine_2",-45,-83,.94,35},{"Pine_2",-10,-91,1.18,75},
		{"CommonTree_3",3,-70,1.15,215},{"CommonTree_5",24,-64,1.2,310},{"CommonTree_1",43,-54,1.02,280},
		{"Pine_2",36,-86,1.16,115},{"TwistedTree_1",-66,-7,.92,55},{"CommonTree_5",-47,16,.90,80},
		{"CommonTree_3",45,-23,.92,165},{"CommonTree_5",43,11,.80,280},{"Pine_2",-77,-53,1.05,0}
	}) do mesh(t[1],t[2],t[3],t[4],t[5],1) end
	-- Thin stone ribbons follow the unchanged floor and never act as colliders.
	for i=0,10 do mesh("RockPath_Round_Small_1",math.sin(i*.65)*1.1,28-i*5.3,5,i*23,1,.515) end
	for i=0,4 do mesh("RockPath_Round_Small_1",0,33+i*4.4,5,15+i*19,1,.49) end
	for _,side in ipairs({-1,1}) do for i=1,5 do mesh("RockPath_Round_Small_1",side*i*5,-7-math.sin(i)*.8,4.4,i*27,1,.515) end end
	for i=0,5 do mesh("RockPath_Round_Small_1",-7+i*5,-30,4.2,i*21,1,.515) end
	for i,p in ipairs({{-44,-36},{-56,-13},{-42,24},{-29,-53},{17,-58},{43,-43},{44,19},{-69,-48},{29,-72}}) do
		mesh("Rock_Medium_1",p[1],p[2],.8+(i%3)*.23,i*47,2)
		mesh("Pebble_Round_1",p[1]+2,p[2]+2,1.1,i*31,2)
	end
	-- TASK04_MEADOW_BEGIN: keep the rest of the approved composition exact.
	for _,p in ipairs(Meadow.build()) do
		local d=mesh(p.template,p.x,p.z,p.scale,p.angle,p.detail)
		d.meadow=true; d.flatten=p.flatten; d.tint=p.tint; d.meadowWind=p.wind; d.radius=p.radius
	end
	mesh("Fern_1",-49,-39,.7,34,2); mesh("Fern_1",-53,-60,.8,170,2)
	mesh("Bush_Common_Flowers",-57,-47,.75,45,2)
	-- TASK04_MEADOW_END
	local function lantern(x,z,world)
		add("beam",{.45,6,.45},{x,3,z},"wood",1,nil,nil,world)
		add("beam",{1.9,.3,.4},{x+.7,6,z},"wood",1,nil,nil,world)
		add("block",{.9,1.3,.9},{x+1.3,5.1,z},"amber",1,nil,{material="Neon",light=true},world)
		add("block",{1.35,.25,1.35},{x+1.3,5.9,z},"bark",1,nil,nil,world)
	end
	lantern(-7,29); lantern(7,29); lantern(-34,-30); lantern(33,-30)
	for _,side in ipairs({-1,1}) do for i=0,2 do
		add("beam",{.5,3,.5},{side*(13+i*7),1.7,28},"wood",1,nil,{barrier=true})
		if i<2 then add("beam",{7,.35,.35},{side*(16.5+i*7),2.5,28},"wood",1,{0,0,side*3},{barrier=true}) end
	end end
	-- Adjacent Bazaar sample; original road and trade post are unchanged.
	for _,x in ipairs({-12,12}) do
		lantern(x,-15,true)
		for _,z in ipairs({-18,-23}) do add("beam",{.55,7,.55},{x,3.5,z},"wood",1,nil,nil,true) end
		add("block",{11,.25,7},{x,7,-20.5},"cream",1,{0,0,x<0 and 5 or -5},nil,true)
		add("beam",{9,2,3},{x,1,-22},"wood",1,nil,nil,true)
	end
	local metrics={parts=0,triangles=0,lights=0,motion=0,palette=0,externalTextures=12,textureMiB=27.96,serverParticles=0,decoratedPlots=1}
	local colors={}
	for _,d in ipairs(parts) do
		local entry=d.template and Plan.catalog[d.template]
		metrics.parts+=entry and entry[2] or 1; metrics.triangles+=entry and entry[1] or 12
		colors[d.color]=true; if d.light then metrics.lights+=1 end
	end
	for _ in pairs(colors) do metrics.palette+=1 end
	return {version=config.version,pilot=index,parts=parts,metrics=metrics}
end
return Plan
