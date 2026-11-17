--!nonstrict
local T=require("./Test")
local M=require("../qa/lunar/Cycle")
local C=require("../qa/lunar/Config").build(require("../src/shared/EnvironmentConfig"))
local Base=require("../src/shared/EnvironmentConfig")
local State=require("../src/shared/EnvironmentState")
local Clock=require("../src/shared/EnvironmentClock")
local function close(a,b,e) T.truthy(math.abs(a-b)<(e or 1e-6)) end
T.test("R4B chooses at dusk and retains the same night through dawn and invisible day",function()
	for cycle=1124000,1124100 do for _,offset in ipairs({300,674,675,1349,1499.999,1500,1799.999}) do
		T.equal(M.index(cycle*1500+offset),cycle);T.equal(M.choose(M.index(cycle*1500+offset)),M.choose(cycle))
	end end
end)
T.test("R4B deterministic 60/20/20 distribution across independent night windows",function()
	for _,start in ipairs({0,1124000,123456789}) do local counts={0,0,0}
		for cycle=start,start+9999 do local k=M.choose(cycle);counts[k]+=1;T.equal(k,M.choose(cycle)) end
		close(counts[1]/10000,.6,.025);close(counts[2]/10000,.2,.025);close(counts[3]/10000,.2,.025)
	end
end)
T.test("R4B proportions are exactly 300/375/675/150 seconds",function()
	local counts={day=0,dusk=0,night=0,dawn=0}
	for t=0,1499 do local p=M.period((t+.5)/1500);counts[p]+=1 end
	T.equal(counts.day,300);T.equal(counts.dusk,375);T.equal(counts.night,675);T.equal(counts.dawn,150)
	close((counts.dusk+counts.night)/1500,.7);T.equal(C.cycleSeconds,1500)
end)
T.test("R4B moon invisible at cycle change and visible all night",function()
	T.equal(M.envelope(0),0);T.equal(M.envelope(.2),0);close(M.envelope(.999999),0,1e-8)
	for t=675,1350 do close(M.envelope(t/1500),1) end
end)
T.test("R4B appearance and disappearance have no boundary jumps",function()
	for _,p in ipairs({0,.2,.45,.9,1}) do close(M.envelope(p-1e-7),M.envelope(p+1e-7),1e-5) end
	local prev=0;for i=0,15000 do local a=M.envelope(i/15000);T.truthy(math.abs(a-prev)<.0011);prev=a end
end)
T.test("R4B forced texture selection crossfades and interrupted fades stay continuous",function()
	local f=M.new();local first=table.clone(f.sample(0,0,"pearl"));T.equal(first[1],1)
	f.sample(0,1,"blood");local mid=table.clone(f.sample(0,5,"blood"));close(mid[1],.5);close(mid[2],.5)
	local interrupted=f.sample(0,5,"frost");for i=1,3 do close(interrupted[i],mid[i]) end
	local done=f.sample(0,13,"frost");T.equal(done[3],1);T.equal(done[1],0);T.equal(done[2],0)
end)
T.test("R4B repeated forced switches never exceed three normalized weights",function()
	local f=M.new()
	for i=1,2000 do local w=f.sample(i,i*.02,M.names[math.floor(i/7)%3+1]);close(w[1]+w[2]+w[3],1)
		for _,a in ipairs(w) do T.truthy(a>=0 and a<=1) end;T.equal(#w,3)
	end
end)
T.test("R4B config is a copy and clock traverses one monotone 24-hour cycle",function()
	T.equal(Base.keys[1].clock,13.2);T.equal(Base.keys[2].phase,.3)
	close(C.keys[#C.keys].clock-C.keys[1].clock,24)
	for i=2,#C.keys do T.truthy(C.keys[i].clock>C.keys[i-1].clock);T.truthy(C.keys[i].phase>C.keys[i-1].phase) end
	local last=Clock.at(C,0);for i=1,15000 do local n=Clock.at(C,i/15000%1);T.truthy((n-last)%24<.02);last=n end
end)
T.test("R4B weather schedule remains independent and identical to R4A",function()
	for t=0,6000,7 do local a,b=State.weather(Base,t),State.weather(C,t)
		for k,v in pairs(a) do T.equal(v,b[k]) end
	end
end)
T.test("R4B palettes have zero daytime influence and bounded night fill",function()
	local day=State.at(C,.1,0)
	for i=1,3 do local w={0,0,0};w[i]=1;local d=M.apply(day,w)
		for _,k in ipairs({"ambient","outdoor","sun","sky","decay","tint"}) do for j=1,3 do close(d[k][j],day[k][j]) end end
		local night=M.apply(State.at(C,.6,0),w);T.truthy(night.ambient[1]>=130);T.truthy(night.ambient[2]>=140)
		T.truthy(night.exposure<=.5);T.truthy(night.brightness<=3);T.truthy(night.haze<.4)
	end
end)
T.test("R4B smooth lunar overlays preserve weather and wind accounting",function()
	local s=State.at(C,.6,.8,{cloud=.85,wet=.9,afterRain=.1});local out=M.apply(s,{0,1,0})
	for _,key in ipairs({"rain","cloud","wet","afterRain","wind","phase","clock"}) do T.equal(out[key],s[key]) end
	T.equal(M.alpha(s,.6),0.95*(1-M.smooth(.85/.9)))
end)
T.test("R4B Minimal retains moon with a reduced halo",function()
	local night=State.at(C,.6,0)
	T.truthy(M.alpha(night,.5)>.9);T.truthy(M.halo("minimal")>0 and M.halo("minimal")<.05)
	T.truthy(M.halo("full")>M.halo("reduced") and M.halo("reduced")>M.halo("minimal"))
	T.equal(M.alpha(night,-.1),0);T.equal(M.alpha(State.at(C,.6,1),.7),0)
end)
T.test("R4B all lighting channels stay continuous across cycle seam",function()
	local a=M.apply(State.at(C,.9999999,0),{0,0,1});local b=M.apply(State.at(C,0,0),{0,1,0})
	for _,k in ipairs({"ambient","outdoor","tint","sky","decay","sun"}) do for j=1,3 do close(a[k][j],b[k][j],.0001) end end
	close(a.brightness,b.brightness,.0001);close(a.exposure,b.exposure,.0001)
end)
T.test("R4B rejects invalid time and unknown moon commands",function()
	T.falsy(pcall(M.index,0/0));T.falsy(pcall(M.index,math.huge));T.falsy(M.valid("reward"));T.truthy(M.valid("auto"))
end)
T.test("R4B probabilities partition exactly 100 percent without a gap",function()
	T.equal(M.weights[1]+M.weights[2]+M.weights[3],100)
	local counts={0,0,0};for roll=0,9999 do counts[M.bucket(roll)]+=1 end
	T.equal(counts[1],6000);T.equal(counts[2],2000);T.equal(counts[3],2000)
end)
T.test("R4B samples select only once each dusk, never each frame or manual mode change",function()
	local f=M.new();local first=table.clone(f.sample(300,0,"auto"))
	for t=301,1799 do f.sample(t,t/60,"auto");T.equal(f.selections,1);T.equal(f.automatic,M.choose(0)) end
	for _,name in ipairs({"pearl","blood","frost","auto"}) do f.sample(1799,100,name);T.equal(f.selections,1) end
	f.sample(1800,101,"auto");T.equal(f.selections,2);T.equal(f.nightIndex,1)
	local g=M.new();local join=g.sample(900,0,"auto");for i=1,3 do T.equal(join[i],first[i]) end
end)
T.test("R4B independent nights allow consecutive repetitions of every variant",function()
	local repeats={false,false,false}
	for n=0,10000 do local a,b=M.choose(n),M.choose(n+1);if a==b then repeats[a]=true end end
	for _,v in ipairs(repeats) do T.truthy(v) end
end)
T.test("R4B optical profiles have no bright ring and expose the two requested scales",function()
	local p=require("../qa/lunar/Presentation")
	T.truthy(p.scaleValid(1.35));T.truthy(p.scaleValid(1.5));T.falsy(p.scaleValid(2));T.falsy(p.scaleValid(0/0))
	local last=1
	for i=0,200 do local a=p.haloAlpha(i/200,"after");T.truthy(a<=last and a>=0);last=a end
	T.equal(last,0);T.truthy(p.haloAlpha(.5,"after")>p.haloAlpha(.5*p.haloScale/1.22,"before"))
end)
T.finish()
