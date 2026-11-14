--!nonstrict
local Path=require("../src/shared/PathSurface")
local Plan=require("../src/shared/EnvironmentPlan")
local Config=require("../src/shared/EnvironmentConfig")
local Geometry=require("../src/shared/NatureGeometry")
return function(T)
	T.test("AG70 all pilot path patches have separated footprints",function()
		local source=Plan.build(Config,1).parts
		local parts=Path.fit(source); local stones={}; local oldOverlaps=0
		for i,d in ipairs(parts) do if d.template==Path.template then
			table.insert(stones,d)
			assert(d.scale<=source[i].scale and d.scale>=2)
			assert(math.abs(d.scale*d.flatten-source[i].scale*source[i].flatten)<1e-9)
			assert(d.id==source[i].id and d.position==source[i].position and d.rotation==source[i].rotation)
			assert(not d.barrier and source[i].flatten==.3)
		else assert(d==source[i]) end end
		assert(#stones==21 and Path.radius>=Geometry[Path.template].radius)
		for i,a in ipairs(stones) do for j=i+1,#stones do local b=stones[j]
			local distance=math.sqrt((a.position[1]-b.position[1])^2+(a.position[3]-b.position[3])^2)
			assert(distance-Path.radius*(a.scale+b.scale)>=Path.gap-1e-8)
		end end
		for i,a in ipairs(source) do if a.template==Path.template then for j=i+1,#source do local b=source[j]
			if b.template==Path.template then
				local distance=math.sqrt((a.position[1]-b.position[1])^2+(a.position[3]-b.position[3])^2)
				if distance<Path.radius*(a.scale+b.scale) then oldOverlaps+=1 end
			end
		end end end
		assert(oldOverlaps>0,"Regression fixture must exercise the overlapping original layout")
	end)
	T.test("AG70 path fitting is repeatable and rejects coincident centers",function()
		local input=Plan.build(Config,1).parts; local a=Path.fit(input); local b=Path.fit(a)
		for i,d in ipairs(a) do if d.template==Path.template then assert(d.scale==b[i].scale and d.flatten==b[i].flatten) end end
		local d={template=Path.template,scale=5,flatten=.3,position={0,0,0}}
		assert(not pcall(Path.fit,{d,table.clone(d)}))
	end)
end
