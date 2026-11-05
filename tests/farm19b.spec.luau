--!nonstrict
local Ground=require("../src/shared/FarmGround")
local Island=require("../src/shared/IslandTerrain")
local Codec=require("../src/shared/TradeCodec")
local function entry() return {upgrade=true,owner=1,enabled=true,visible=true,clear=true,distance=6,maximum=8,station="mine"} end
local function state() return {writable=true,gold=60,builds={mine={cost=60,available=true}},phase={available=false,cost=400}} end
return function(T:any)
	T.test("19b: all eight visual soil clearings close the floor gap without moving origins",function()
		for i=1,8 do local x,z=Island.origin(i)
			for u=-38,38,4 do for v=-45,29,4 do
				local h=Ground.column(x+u,z+v); T.truthy(math.abs(h+1.6)<1e-9)
			end end
		end
	end)
	T.test("19b: soil joins are continuous and the distant coast is unchanged",function()
		for x=-320,320,7 do for z=-240,260,7 do
			local h=Ground.column(x,z); T.truthy(math.abs(h-Ground.column(x+.001,z))<.01)
			T.truthy(h>=-29.2 and h<50)
		end end
		for _,p in ipairs({{320,0},{-320,0},{0,260},{0,-240}}) do T.equal(Ground.column(p[1],p[2]),Island.column(p[1],p[2])) end
	end)
	T.test("19b: every entrance has a natural approach to the shared bazaar",function()
		for i=1,8 do local x,z=Island.origin(i); local a,b=z<0 and z+29.5 or 0,z<0 and 0 or z-45.5
			for along=a,b,2 do local _,m=Ground.column(x,along); T.equal(m,"Ground") end
		end
		local _,m=Ground.column(0,0); T.equal(m,"Ground")
		_,m=Ground.column(170,12); T.equal(m,"Grass")
	end)
	T.test("19b: thin rounded ownership outline follows the original plot footprint",function()
		for i=1,8 do local points=Ground.border(i); local x,z=Island.origin(i); T.equal(#points,Ground.borderParts)
			for n,p in ipairs(points) do
				T.truthy(math.abs(p[1]-x)<=38.5001 and p[2]-z>=-45.5001 and p[2]-z<=29.5001)
				local q=points[n%#points+1]; T.truthy((q[1]-p[1])^2+(q[2]-p[2])^2>.01)
			end
		end
		T.truthy(Ground.borderWidth<=.15); T.truthy(Ground.borderParts+Ground.glowParts<=24)
	end)
	T.test("19b: only an affordable selected own upgrade gets a green affordance",function()
		T.truthy(Ground.canGlow(state(),entry(),1)); T.truthy(not Ground.canGlow(state(),nil,1)); T.truthy(not Ground.canGlow(nil,entry(),1))
		local s,e=state(),entry(); local before=Codec.copy(s); local old=Codec.copy(e)
		Ground.canGlow(s,e,1); T.same(s,before); T.same(e,old)
		s.gold=59.99; T.truthy(not Ground.canGlow(s,e,1)); s.gold=60; s.builds.mine.available=false; T.truthy(not Ground.canGlow(s,e,1))
	end)
	for _,case in ipairs({"foreign","unowned","unselected","far","nan","hidden","occluded","disabled","readonly","maximum","phase"}) do
		T.test("19b: green glow fails closed / "..case,function()
			local s,e=state(),entry()
			if case=="foreign" then e.owner=2 elseif case=="unowned" then e.owner=nil elseif case=="unselected" then e.upgrade=false
			elseif case=="far" then e.distance=8.01 elseif case=="nan" then e.distance=0/0 elseif case=="hidden" then e.visible=false
			elseif case=="occluded" then e.clear=false elseif case=="disabled" then e.enabled=false elseif case=="readonly" then s.writable=false
			elseif case=="maximum" then s.builds.mine.cost=nil elseif case=="phase" then e.station="blueprint" end
			T.truthy(not Ground.canGlow(s,e,1))
		end)
	end
	T.test("19b: phase prerequisite and funds changes refresh the same affordance",function()
		local s,e=state(),entry(); e.station="blueprint"; s.gold=400
		T.truthy(not Ground.canGlow(s,e,1)); s.phase.available=true; T.truthy(Ground.canGlow(s,e,1))
		s.gold=399; T.truthy(not Ground.canGlow(s,e,1)); s.gold=400; s.phase.cost=nil; T.truthy(not Ground.canGlow(s,e,1))
	end)
end
