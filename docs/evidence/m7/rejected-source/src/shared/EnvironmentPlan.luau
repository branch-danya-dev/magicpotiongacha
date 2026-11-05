--!nonstrict
-- Original native fallback. External CC0 import is a separate, still blocked gate.
local Plan={}
function Plan.origin(index) return {((index-1)%4-1.5)*95,0,index<=4 and -65 or 85} end
function Plan.build(config,index)
	assert(index==config.pilotPlot,"Gate B requires owner visual approval")
	local o=Plan.origin(index); local parts={}; local serial=0
	local function add(kind,size,pos,color,detail,rotation,extra,world)
		serial+=1
		local d={id="Decor_"..serial,kind=kind,size=size,position=world and pos or {o[1]+pos[1],pos[2],o[3]+pos[3]},
			color=color,detail=detail or 1,rotation=rotation or {0,0,0},material=(kind=="trunk" or kind=="beam") and "Wood" or "SmoothPlastic"}
		for k,v in pairs(extra or {}) do d[k]=v end; table.insert(parts,d); return d
	end
	local function stone(x,y,z,s,detail) add("ball",{s,math.max(.3,s*.35),s*.8},{x,y,z},"stone",detail) end
	local function tree(x,z,s,style,n)
		add("trunk",{s*9,s*1.3,s*1.3},{x,s*4.3,z},style=="birch" and "cream" or "bark",1,{0,0,85})
		add("beam",{s*.7,s*5,s*.7},{x+s*1.8,s*7,z},"bark",1,{0,0,-35})
		for i,p in ipairs({{0,10,0,10,9,9},{-3,8.5,1,7,6,7},{3,10,-1,8,7,7},{0,13,0,7,6,7}}) do
			add("ball",{p[4]*s,p[5]*s,p[6]*s},{x+p[1]*s,p[2]*s,z+p[3]*s},i==4 and "leafLight" or (style=="birch" and "sage" or "leaf"),1,nil,{wind=n<=3 and i==4})
		end
		stone(x+2*s,.65,z+1.4*s,2.2*s,2)
	end
	for n,t in ipairs({{-43,-36,1.2},{-46,-11,1.1},{-43,17,1},{-28,-52,1.2},{-7,-54,1.35},{18,-53,1.15},{41,-40,1.25},{44,-15,.95},{44,13,1.15}}) do tree(t[1],t[2],t[3],n%3==0 and "birch" or "oak",n) end
	-- Outer hills never intersect the work floor or central public passage.
	for _,h in ipairs({{-57,-47,28,10,32},{-25,-66,43,12,28},{22,-68,45,16,30},{62,-40,32,13,38}}) do
		add("ball",{h[3],h[4],h[5]},{h[1],-1,h[2]},"grass",1,nil,{material="Grass"})
	end
	-- Readable paths, all thin and noncolliding. Anchor pads stay at their original height.
	for i=0,8 do add("ball",{8.4,.16,6.3},{math.sin(i*.6)*1.2,.56,27-i*5.1},"stone",1) end
	for i=0,7 do add("ball",{7.5,.16,6},{math.sin(i*.4),-.3,32+i*4.6},"stone",1) end
	for _,side in ipairs({-1,1}) do for i=1,5 do add("ball",{6.4,.14,5.2},{side*i*5,.55,-6-math.sin(i)*1.4},"stone",1) end end
	for i=0,5 do add("ball",{6,.16,5},{-4+i*5.2,.55,-30},"stone",1) end
	for _,side in ipairs({-1,1}) do
		for i=0,4 do
			add("beam",{.65,3.8,.65},{side*35,2,22-i*9},"wood",1)
			if i<4 then for _,y in ipairs({1.1,2.6}) do add("beam",{.45,.5,8.6},{side*35,y,17.5-i*9},"wood",1) end end
		end
	end
	local function lantern(x,z,world)
		add("beam",{.6,6,.6},{x,3,z},"wood",1,nil,nil,world)
		add("beam",{2.2,.4,.5},{x+.7,6,z},"wood",1,nil,nil,world)
		add("block",{1.1,1.8,1.1},{x+1.4,5,z},"amber",1,nil,{material="Neon",light=true},world)
		add("ball",{1.6,.35,1.6},{x+1.4,6,z},"bark",1,nil,nil,world)
	end
	lantern(-7,28); lantern(7,28); lantern(-33,-28); lantern(32,-28)
	-- Seeded small detail stays in outside planting strips, never covers a purchase pad.
	for i=1,32 do
		local side=i%2==0 and 1 or -1; local x=side*(37+(i*7%6)); local z=-45+(i*13%69)
		add("ball",{2.8,1.6,2.3},{x,.9,z},i%3==0 and "sage" or "leaf",2)
		for j=1,3 do add("ball",{.7,.35,.7},{x+(j-2)*.6,1.8+(j%2)*.2,z+(j%2)*.5},i%3==0 and "flower" or "cream",3) end
	end
	for i=1,30 do
		local side=i%2==0 and 1 or -1; local x=side*(38+(i*11%5)); local z=-43+(i*17%66)
		for j=1,2 do add("ball",{.35,1.8,.8},{x+j*.5,.8,z},"sage",3,{0,i*27,j==1 and 22 or -25}) end
	end
	for _,p in ipairs({{-30,26},{25,24},{-39,-4},{37,-22},{-18,-47},{31,-47}}) do stone(p[1],.55,p[2],3.2,2) end
	-- Small Bazaar sample only: a clear 24-stud-wide road still carries the old gate.
	for _,x in ipairs({-12,12}) do
		lantern(x,-15,true)
		for _,z in ipairs({-18,-23}) do add("beam",{.7,7,.7},{x,3.5,z},"wood",1,nil,nil,true) end
		add("block",{11,.3,7},{x,7,-20.5},"cream",1,{0,0,x<0 and 5 or -5},nil,true)
		add("beam",{9,2,3},{x,1,-22},"wood",1,nil,nil,true)
		for j=1,3 do add("ball",{1.5,1.5,1.5},{x+j*2-4,2.7,-22},j==1 and "flower" or "sage",2,nil,nil,true) end
	end
	local metrics={parts=#parts,lights=0,motion=0,palette=0,externalTextures=0,serverParticles=0,decoratedPlots=1}
	local colors={}; for _,d in ipairs(parts) do colors[d.color]=true; if d.light then metrics.lights+=1 end; if d.wind then metrics.motion+=1 end end
	for _ in pairs(colors) do metrics.palette+=1 end
	return {version=config.version,pilot=index,parts=parts,metrics=metrics}
end
return Plan
