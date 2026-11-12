--!nonstrict
local Policy=require("../src/shared/SpellbookEffectsPolicy")
local Feedback=require("../src/shared/SpellbookFeedback")
local Lifecycle=require("../src/shared/SpellbookEffectLifecycle")
local Factory=require("../src/shared/Factory")
local Config=require("../src/shared/Config")
return function(T: any)
	T.test("AG62A first snapshot seeds cursor without replaying historical feedback",function()
		local n,show=Feedback.consume(nil,{sequence=7,plotIndex=1},1)
		T.equal(n,7); T.falsy(show)
	end)
	T.test("AG62A one accepted click is acknowledged once",function()
		local seq=Feedback.accept(0,"click",true)
		local n,show=Feedback.consume(0,{sequence=seq,plotIndex=1},1)
		T.truthy(show); T.equal(n,1)
		local again,duplicate=Feedback.consume(n,{sequence=seq,plotIndex=1},1)
		T.equal(again,n); T.falsy(duplicate)
	end)
	T.test("AG62A failed/rate-limited action and passive updates cannot mint receipts",function()
		T.equal(Feedback.accept(4,"click",false),4)
		T.equal(Feedback.accept(4,"build",true),4)
		local _,show=Feedback.consume(4,{sequence=4,plotIndex=1},1); T.falsy(show)
	end)
	T.test("AG62A foreign/unowned receipt is consumed without later replay",function()
		local n,show=Feedback.consume(1,{sequence=2,plotIndex=2},1)
		T.equal(n,2); T.falsy(show)
		local _,later=Feedback.consume(n,{sequence=2,plotIndex=1},1); T.falsy(later)
		local _,unowned=Feedback.consume(n,{sequence=3,plotIndex=1},nil); T.falsy(unowned)
	end)
	T.test("AG62A malformed and stale receipts never rewind cursor",function()
		for _,n in ipairs({-1,0/0,1.5,math.huge,3}) do
			local current,show=Feedback.consume(4,{sequence=n,plotIndex=1},1)
			T.equal(current,4); T.falsy(show)
		end
		local current,show=Feedback.consume(4,nil,1); T.equal(current,4); T.falsy(show)
	end)
	T.test("AG62A server-confirmed receipt leaves real click economy unchanged",function()
		local engine=Factory.new(Config); local p=engine.newProfile(63,1000)
		local before=p.essence; local ok=engine.act(p,"click",{},1000)
		T.truthy(ok); T.equal(p.essence-before,5)
		T.equal(Feedback.accept(nil,"click",ok),1)
		T.equal(p.essenceClickSequence,nil); T.equal(p.presentation,nil)
		p.essence=Config.maxBalance
		local denied=engine.act(p,"click",{},1000)
		T.falsy(denied); T.equal(Feedback.accept(1,"click",denied),1)
	end)
	T.test("AG62A quality caps strictly decrease without hiding the book",function()
		local f,r,m=Policy.quality("full",false),Policy.quality("reduced",false),Policy.quality("minimal",false)
		T.equal(f.active,3); T.equal(r.active,2); T.equal(m.active,1)
		T.equal(f.idleRate,0.6); T.equal(r.idleRate,0.2); T.equal(m.idleRate,0)
		T.equal(f.hz,30); T.equal(r.hz,20); T.equal(m.hz,10)
		T.equal(m.burst,0); T.falsy(m.motion)
	end)
	T.test("AG62A Reduce Motion disables all idle movement, flicker and particles",function()
		for _,name in ipairs({"full","reduced","minimal"}) do
			local c=Policy.quality(name,true); T.falsy(c.motion); T.equal(c.burst,0); T.equal(c.idleRate,0)
			T.same(Policy.sample(6,2,c.motion),{runeY=0,runeYaw=0,pageY=0,pageRoll=0,glow=1,flame=1})
		end
	end)
	T.test("AG62A motion stays within measured rigid group limits over many cycles",function()
		for i=0,3600 do
			local s=Policy.sample(i/10,1.46,true)
			T.truthy(math.abs(s.runeY)<=0.1 and math.abs(s.runeYaw)<=math.rad(3))
			T.truthy(s.pageY>=0 and s.pageY<=0.035 and math.abs(s.pageRoll)<=math.rad(1.5))
			T.truthy(s.glow>=0.9 and s.glow<=1 and s.flame>=0.9299 and s.flame<=1.0001)
		end
	end)
	T.test("AG62A pages rest for most of each 18-second cycle",function()
		T.equal(Policy.sample(8,0,true).pageY,0)
		T.equal(Policy.sample(17,0,true).pageRoll,0)
		T.truthy(Policy.sample(2,0,true).pageY>0)
	end)
	T.test("AG62A feedback pulse is bounded and expires",function()
		T.equal(Policy.pulse(1,nil,0.65),0); T.equal(Policy.pulse(2,1,0.65),0)
		T.near(Policy.pulse(1.325,1,0.65),1,0.0001)
	end)
	T.test("AG62A global particle budget survives click spam and long stalls",function()
		for _,name in ipairs({"full","reduced","minimal"}) do
			local cfg=Policy.quality(name,false); local tokens,total=cfg.burst,0
			for _=1,1000 do local n; tokens,n=Policy.take(tokens,0.001,cfg); total+=n end
			T.truthy(total<=cfg.burst+cfg.refill)
			local _,n=Policy.take(tokens,100,cfg); T.truthy(n<=cfg.burst)
		end
	end)
	local function fixture()
		local allocated,disposed,updates=0,0,0
		local ops={valid=function(key) return key.ready end,
			capture=function(key) return {key=key,pose="original",allocated=false} end,
			update=function(r)
				if not r.allocated then r.allocated=true; allocated+=2 end
				r.pose="animated"; updates+=1
				if r.key.fail then error("injected engine failure") end
			end,
			dispose=function(r) if r.allocated then allocated-=2 end; r.pose="original"; disposed+=1 end}
		return Lifecycle.new(ops,8),function() return allocated,disposed,updates end
	end
	T.test("AG62A missing/fallback model cannot acquire effects",function()
		local life,stats=fixture(); T.falsy(life.add({ready=false})); life.step(0,0,{})
		T.equal(life.count,0); T.equal(stats(),0)
	end)
	T.test("AG62A eight-plot capacity and duplicate attach are bounded",function()
		local life=fixture(); local key={ready=true}; T.truthy(life.add(key)); T.falsy(life.add(key))
		for _=2,8 do T.truthy(life.add({ready=true})) end
		T.falsy(life.add({ready=true})); T.equal(life.count,8)
	end)
	T.test("AG62A fallback restores pose and disposes all effects once",function()
		local life,stats=fixture(); local key={ready=true}; life.add(key); life.step(1,0.03,{})
		local r=life.records[key]; key.ready=false; life.step(2,0.03,{})
		local live,disposed=stats(); T.equal(live,0); T.equal(disposed,1); T.equal(r.pose,"original")
		life.remove(key); T.equal(life.count,0)
	end)
	T.test("AG62A restore/reappear never duplicates objects",function()
		local life,stats=fixture(); local key={ready=true}
		for _=1,20 do life.add(key); life.step(0,0,{}); life.remove(key) end
		T.equal(stats(),0); T.truthy(life.add(key)); life.step(0,0,{})
		T.equal(stats(),2); T.equal(life.count,1)
	end)
	T.test("AG62A partial effect update failure restores only that book",function()
		local life,stats=fixture(); local bad,good={ready=true,fail=true},{ready=true}
		life.add(bad); life.add(good); local r=life.records[bad]; life.step(0,0,{})
		T.equal(r.pose,"original"); T.equal(stats(),2); T.equal(life.count,1)
	end)
	T.test("AG62A stop clears registry and prevents reconnection/reallocation",function()
		local life,stats=fixture(); life.add({ready=true}); life.step(0,0,{})
		life.stop(); life.stop(); T.equal(stats(),0); T.equal(life.count,0)
		T.falsy(life.add({ready=true}))
	end)
end
