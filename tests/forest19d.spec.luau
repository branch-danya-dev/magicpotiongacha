--!nonstrict
local Forest=require("../src/shared/ForestPlan")
local LOD=require("../src/shared/ForestLOD")
local Island=require("../src/shared/IslandTerrain")
local Ground=require("../src/shared/FarmGround")
local Plan=require("../src/shared/EnvironmentPlan")
local Config=require("../src/shared/EnvironmentConfig")
return function(T:any)
	T.test("19d: repeatable forest has depth, all five silhouettes and bounded population",function()
		local p,m=Forest.build(); local again=Forest.build(); T.same(p,again); T.truthy(m.trees>=25 and m.trees<=Forest.maxTrees)
		local layers,forms={},{}; for _,d in ipairs(p) do if d.forest=="tree" then
			layers[d.layer]=(layers[d.layer] or 0)+1; forms[d.species]=true
		end end
		for i=1,3 do T.truthy(layers[i]>=6,"Missing forest depth") end
		for kind in pairs(Forest.forms) do T.truthy(forms[kind],kind) end
	end)
	T.test("19d: complete crowns avoid all eight factory floors and their approach road",function()
		for _,p in ipairs(Forest.build()) do
			local x,z=p.x-142.5,p.z-65
			for i=1,8 do
				local ox,oz=Island.origin(i)
				local dx=math.max(math.abs(x-ox)-38.5,0); local dz=math.max(math.abs(z-oz+8)-37.5,0)
				T.truthy(math.sqrt(dx*dx+dz*dz)>=p.radius+1.5)
			end
			T.truthy(z+p.radius< -23); T.truthy(x+p.radius< -87)
		end
	end)
	T.test("19d: rooted on dry land with finite bounded scale, no coastal water planting",function()
		for _,p in ipairs(Forest.build()) do
			local h=Ground.column(p.x-142.5,p.z-65)
			T.truthy(h>Island.water+3 and h<60); T.truthy(p.scale>0 and p.scale<3.1)
			T.truthy(p.radius>0 and p.radius<20)
		end
	end)
	T.test("19d: glades retain open crown space, logs and boulders provide ground structure",function()
		local p,m=Forest.build(); T.truthy(m.logs>=3 and m.boulders>=8 and m.understory>=20)
		for _,d in ipairs(p) do for _,g in ipairs(Forest.glades) do
			T.truthy(math.sqrt((d.x-g[1])^2+(d.z-g[2])^2)>=d.radius+g[3])
		end end
	end)
	T.test("19d: all rotated crown boxes fit the advertised protective radius",function()
		for _,d in ipairs(Forest.build()) do if d.forest=="tree" then
			for _,p in ipairs(Forest.crowns(d.species,d.variant)) do
				for _,sx in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
					local x=(p.position[1]+sx*p.size[1]/2)*d.scale
					local z=(p.position[3]+sz*p.size[3]/2)*d.scale
					T.truthy(math.sqrt(x*x+z*z)<=d.radius+1e-8)
				end end
			end
		end end
	end)
	T.test("19d: admitted bark and ground mesh bounds fit reserved placement radii",function()
		-- Measured from the hash-pinned template CFrame/Size (corner radius in XZ).
		local actual={CommonTree_1=6.5652901883,CommonTree_3=3.4596957397,CommonTree_5=3.6294725991,
			Pine_2=7.6834492434,TwistedTree_1=10.8019900854,Fern_1=4.3827366075,Rock_Medium_1=3.1134353167}
		for _,d in ipairs(Forest.build()) do
			if d.template then
				local width=d.forest=="tree" and Forest.forms[d.species].stemWide or 1
				T.truthy(d.radius>=actual[d.template]*width*d.scale,d.template)
			else
				for _,p in ipairs(Forest.logPieces()) do
					local square=0; for i=1,3 do square+=(math.abs(p.position[i])+p.size[i]/2)^2 end
					T.truthy(d.radius>=math.sqrt(square)*d.scale,"Sloped log extent")
				end
			end
		end
	end)
	T.test("19d: each tree has connected multi-lobed core volume at Minimal",function()
		for kind in pairs(Forest.forms) do
			local pieces=Forest.crowns(kind,0); local core=0
			for _,p in ipairs(pieces) do
				if p.role=="core" then core+=1; T.equal(LOD.alpha(p.role,"minimal",80),0) end
				T.equal(p.shape,"Ball"); for _,v in ipairs(p.size) do T.truthy(v>1 and v<30) end
			end
			T.equal(core,3)
			-- Core lobes overlap rather than becoming isolated balls when details cull.
			for i=2,3 do
				local a,b=pieces[i-1],pieces[i]; local overlap=0
				for axis=1,3 do
					local separation=math.abs(a.position[axis]-b.position[axis])
					if separation<(a.size[axis]+b.size[axis])/2 then overlap+=1 end
				end
				T.equal(overlap,3,kind)
			end
		end
	end)
	T.test("19d: logs have two separated cut ends and ground-level moss",function()
		local p=Forest.logPieces(); T.equal(p[1].shape,"Cylinder")
		T.truthy(p[2].position[1]<-p[1].size[1]/2 and p[3].position[1]>p[1].size[1]/2)
		for i=1,3 do T.equal(p[i].role,"core") end
		for _,v in ipairs(p) do T.truthy(v.position[2]-v.size[2]/2>=-.11) end
	end)
	T.test("19d: complete forest budget includes native geometry charges and exact mesh counts",function()
		local p,m=Forest.build(); local parts,triangles=0,0
		for _,d in ipairs(p) do parts+=d.parts; triangles+=d.triangles end
		T.equal(parts,m.parts); T.equal(triangles,m.triangles)
		T.truthy(m.parts<=Forest.maxParts and m.triangles<=Forest.maxTriangleCharge)
		T.truthy(m.nativeParts>100 and m.meshTriangles>0 and m.meshTriangles<m.triangles)
		local plan=Plan.build(Config,1); T.truthy(plan.metrics.parts<=Config.budgets.parts)
		T.truthy(plan.metrics.triangles<=Config.budgets.triangles); T.equal(plan.metrics.externalTextures,12)
		local count=0; for _,d in ipairs(plan.parts) do if d.forest then count+=1 end end
		T.equal(count,#p)
	end)
	for _,quality in ipairs({"full","reduced","minimal"}) do
		T.test("19d: silhouette survives while ground detail culls / "..quality,function()
			T.equal(LOD.alpha("core",quality,100),0); T.equal(LOD.alpha("core",quality,400),1)
			T.equal(LOD.alpha("detail",quality,150),1); T.equal(LOD.alpha("ground",quality,150),1)
			for _,role in ipairs({"core","detail","ground"}) do
				local previous=0
				for d=0,400,.2 do
					local a=LOD.alpha(role,quality,d); T.truthy(a>=0 and a<=1 and a>=previous)
					if d>0 then T.truthy(a-previous<.02) end; previous=a
				end
			end
		end)
	end
	T.test("19d: unknown quality falls back to Reduced; invalid distances hide",function()
		for _,d in ipairs({0,80,150,220,240}) do T.equal(LOD.alpha("core","invalid",d),LOD.alpha("core","reduced",d)) end
		for _,d in ipairs({-1,0/0,math.huge,-math.huge}) do T.equal(LOD.alpha("core","full",d),1) end
		T.equal(LOD.alpha("unknown","full",0),1)
	end)
	T.test("19d: rapid camera and quality changes cannot overshoot or pop alpha",function()
		local alpha=0
		for i=1,300 do
			local target=i%3==0 and 0 or 1; local nextAlpha=LOD.step(alpha,target,i%17==0 and 2 or 1/30)
			T.truthy(nextAlpha>=0 and nextAlpha<=1); T.truthy(math.abs(nextAlpha-alpha)<=.200001)
			alpha=nextAlpha
		end
		for _=1,30 do alpha=LOD.step(alpha,1,1/30) end; T.equal(alpha,1)
		for _=1,30 do alpha=LOD.step(alpha,0,1/30) end; T.equal(alpha,0)
	end)
	T.test("19d: quality ordering never increases detail on weaker devices",function()
		for _,role in ipairs({"core","detail","ground"}) do for d=0,350 do
			T.truthy(LOD.alpha(role,"full",d)<=LOD.alpha(role,"reduced",d))
			T.truthy(LOD.alpha(role,"reduced",d)<=LOD.alpha(role,"minimal",d))
		end end
	end)
end
