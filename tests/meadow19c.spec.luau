--!nonstrict
local Meadow=require("../src/shared/MeadowPlan")
local Motion=require("../src/shared/MeadowMotion")
local Factory=require("../src/shared/Config")
local Plan=require("../src/shared/EnvironmentPlan")
local Config=require("../src/shared/EnvironmentConfig")
return function(T:any)
	T.test("19c: deterministic finite pilot meadow, unique grass sites and closed catalog",function()
		local plants=Meadow.build(); T.same(plants,Meadow.build()); T.truthy(#plants>300 and #plants<=456)
		local seen={}; for _,p in ipairs(plants) do
			T.truthy(Plan.catalog[p.template]); local key=p.x..":"..p.z; T.falsy(seen[key]); seen[key]=true
			T.truthy(p.x>=-59 and p.x<=44 and p.z>=-70 and p.z<=39)
		end
	end)
	T.test("19c: all future station bodies and purchase pads have full mesh clearance",function()
		for _,p in ipairs(Meadow.build()) do for _,s in pairs(Factory.stations) do
			local x,z=s.offset[1],s.offset[3]
			T.truthy(math.abs(p.x-x)>4+p.radius or math.abs(p.z-z)>3.5+p.radius,s.id)
			T.truthy(math.abs(p.x-x)>2.5+p.radius or math.abs(p.z-z-7)>2+p.radius,s.id)
		end end
	end)
	T.test("19c: spawn and central walking corridor stay open",function()
		for _,p in ipairs(Meadow.build()) do
			if p.z>-29 and p.z<30 then T.truthy(math.abs(p.x)>3+p.radius) end
			T.truthy(math.abs(p.x)>4+p.radius or p.z<18)
		end
	end)
	T.test("19c: varied height and tint, clover and wildflowers replace repeated bushes",function()
		local heights,tints,types={},{},{}; local lo,hi=10,0
		for _,p in ipairs(Meadow.build()) do
			tints[table.concat(p.tint,",")]=true; types[p.template]=(types[p.template] or 0)+1
			if string.find(p.template,"Grass") then
				local h=p.scale*p.flatten*(p.template=="Grass_Wispy_Tall" and 1.8 or 1.1)
				lo=math.min(lo,h); hi=math.max(hi,h); heights[h]=true
			end
		end
		local n=0; for _ in pairs(tints) do n+=1 end
		T.truthy(n>=5 and hi-lo>.4 and lo>=.65 and hi<=1.3)
		T.truthy(types.Clover_2>=30 and types.Flower_3_Group>=15)
		T.falsy(types.Bush_Common_Flowers)
	end)
	T.test("19c: geometry and texture budgets remain inherited; Reduced retains meadow volume",function()
		local plan=Plan.build(Config,1); T.truthy(plan.metrics.parts<=650 and plan.metrics.triangles<=150000)
		T.equal(plan.metrics.externalTextures,12)
		local counts={0,0,0}; for _,p in ipairs(Meadow.build()) do for tier=p.detail,3 do counts[tier]+=1 end end
		T.truthy(counts[1]>180); T.truthy(counts[2]>counts[3]*.8)
	end)
	T.test("19c: wind continuous, bounded, spatial and responds to weather",function()
		local changing=false
		for i=0,1000 do
			local a=Meadow.angle(i*.01,12,30,1); T.truthy(math.abs(a)<=.175)
			T.truthy(math.abs(a-Meadow.angle(i*.01+.001,12,30,1))<.001)
			if math.abs(a-Meadow.angle(i*.01,20,20,1))>.04 then changing=true end
			T.near(a,Meadow.angle(i*.01,12,30,0)*(.175/.075))
		end
		T.truthy(changing)
	end)
	for _,cap in ipairs({32,64}) do
		T.test("19c: camera turns include fading plants in hard motion cap / "..cap,function()
			local entries={}; for i=1,150 do entries[i]={visible=true,weight=0} end
			for frame=1,200 do
				if frame%13==0 then table.insert(entries,1,table.remove(entries)) end
				local n=Motion.step(entries,cap,1/30); T.truthy(n<=cap)
				local actual=0; for _,p in ipairs(entries) do if p.weight>0 then actual+=1 end end
				T.equal(actual,n)
			end
		end)
	end
	T.test("19c: quality downgrade and Reduce Motion restore zero slots immediately",function()
		local entries={}; for i=1,100 do entries[i]={visible=true,weight=1} end
		T.equal(Motion.step(entries,32,.03),32); T.equal(Motion.step(entries,0,.03),0)
		for _,p in ipairs(entries) do T.equal(p.weight,0) end
	end)
	T.test("19c: motion resumes gradually and offscreen plants finish fading",function()
		local entries={{visible=true,weight=0}}
		Motion.step(entries,32,.03); T.truthy(entries[1].weight>0 and entries[1].weight<.1)
		entries[1].visible=false; Motion.step(entries,32,.1); T.equal(entries[1].weight,0)
	end)
end
