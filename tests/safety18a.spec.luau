--!nonstrict
local Transition=require("../src/shared/EnvironmentTransition")
local State=require("../src/shared/EnvironmentState")
local Config=require("../src/shared/EnvironmentConfig")
local Plan=require("../src/shared/EnvironmentPlan")
local Recovery=require("../src/shared/CharacterRecovery")
local UI=require("../src/shared/ContextUI")
return function(T:any)
	T.test("18a: diagnostic transitions begin at the displayed frame, settle exactly",function()
		local d=Transition.new(); local a=State.sample(Config,0,"day"); local b=State.sample(Config,0,"night")
		T.same(d.sample(a,0),a); d.begin(1); T.same(d.sample(b,1),a)
		T.same(d.sample(b,10),b); T.equal(d.from,nil)
	end)
	T.test("18a: repeated weather retarget has no discontinuity or second owner",function()
		local d=Transition.new(); d.sample(State.sample(Config,0,"day"),0); d.begin(0)
		local current=d.sample(State.sample(Config,0,"rain"),4); d.begin(4)
		T.same(d.sample(State.sample(Config,0,"afterrain"),4),current)
	end)
	T.test("18a: clock and phase wrap through their seam instead of noon",function()
		local mid=Transition.blend({clock=23.9,phase=.99},{clock=.1,phase=.01},.5)
		T.truthy(mid.clock<.001 or mid.clock>23.999); T.truthy(mid.phase<.001 or mid.phase>.999)
	end)
	for _,pose in ipairs({"day","sunset","night","dawn","rain","afterrain"}) do
		T.test("18a: bounded 30fps transition into "..pose,function()
			local a=State.sample(Config,0,"night"); local b=State.sample(Config,0,pose); local last=a
			for i=1,240 do
				local s=Transition.blend(a,b,i/240)
				T.truthy(math.abs((s.clock-last.clock+12)%24-12)<.08)
				T.truthy(math.abs(s.brightness-last.brightness)<.03)
				T.truthy(math.abs(s.rain-last.rain)<.007); last=s
			end
		end)
	end
	T.test("18a: finite decorative fence collisions leave the entrance open",function()
		local count=0; local o=Plan.origin(1)
		for _,d in ipairs(Plan.build(Config,1).parts) do if d.barrier then
			count+=1; T.equal(d.detail,1); T.equal(d.position[3],o[3]+28)
			T.truthy(math.abs(d.position[1]-o[1])-d.size[1]/2>=12.7)
		end end
		T.equal(count,10)
	end)
	T.test("18a: recovery precedes the kill plane including a fast fall",function()
		T.truthy(Recovery.needed(-46,-10,.1,-500,-100,0))
		T.truthy(Recovery.needed(-30,-200,.1,-500,-100,0))
		T.truthy(not Recovery.needed(3,0,.1,-500,-100,0))
		T.truthy(not Recovery.needed(-10,15,.1,-500,-100,0))
	end)
	T.test("18a: recovery cooldown and invalid coordinates do not loop",function()
		T.truthy(not Recovery.needed(-46,-10,.1,-500,0,1))
		T.truthy(not Recovery.needed(0/0,0,.1,-500,-100,0))
		T.truthy(not Recovery.needed(-math.huge,0,.1,-500,-100,0))
	end)
	for _,size in ipairs({{402,720},{750,324},{320,490}}) do
		T.test("18a: factory entry clears native list and touch corners "..size[1],function()
			local l=UI.layout(size[1],size[2],true); local f=l.factory
			T.truthy(f.x>=96); T.truthy(f.x+f.w<=size[1]-96)
			T.truthy(f.y>=150 and f.y+f.h<=size[2]-48)
		end)
	end
end
