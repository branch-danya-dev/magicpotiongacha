--!nonstrict
local T=require("./Test")
local Island=require("../src/shared/PersonalIsland")
local Session=require("../src/shared/IslandSession")
local Config=require("../src/shared/Config")
local Factory=require("../src/shared/Factory").new(Config)
local Props=require("../src/shared/PropPlan")
T.test("AG76 fixed QA owner rejects first-arrival takeover",function()
	local s=Session.new(42,true,true)
	T.equal(s:admit(7,{}),nil);T.equal(s.current,nil)
	local owner={};local token=s:admit(42,owner)
	T.equal(token.ownerUserId,42);T.equal(token.phase,"loading");T.equal(token.islandId,"u:42:primary")
end)
T.test("AG76 test context cannot operate live or use a malformed owner",function()
	T.throws(function() Session.new(42,false,true) end)
	T.throws(function() Session.new(42,true,false) end)
	for _,id in ipairs({0,1.5,math.huge,0/0,"42"}) do T.throws(function() Session.new(id,true,true) end) end
	T.truthy(Island.validOwner(-1,true));T.falsy(Island.validOwner(-1,false))
end)
T.test("AG76 duplicate callbacks are idempotent but another Player cannot replace owner",function()
	local s=Session.new(42,true,true);local a,b={},{}
	local token=s:admit(42,a);T.equal(s:admit(42,a),token)
	T.equal(s:admit(42,b),nil);T.equal(s.current,token);T.equal(s.generation,1)
end)
T.test("AG76 profile owner and actor must both match before activation",function()
	local s=Session.new(42,true,true);local a={};local token=s:admit(42,a)
	T.falsy(s:activate({},token,42));T.falsy(s:activate(a,token,43));T.equal(token.phase,"loading")
	T.truthy(s:activate(a,token,42));T.truthy(s:matches(a,token,"active"))
	T.falsy(s:activate(a,token,42))
end)
T.test("AG76 cancelled load cannot activate after a reconnect",function()
	local s=Session.new(42,true,true);local old,new={},{}
	local before=s:admit(42,old);T.truthy(s:release(old,before))
	local after=s:admit(42,new);T.truthy(after.generation>before.generation)
	T.falsy(s:activate(old,before,42));T.falsy(s:release(old,before))
	T.truthy(s:activate(new,after,42));T.equal(s.current,after)
end)
T.test("AG76 stale cleanup cannot close a successor session",function()
	local s=Session.new(42,true,true);local a,b={},{};local one=s:admit(42,a)
	T.truthy(s:activate(a,one,42));T.falsy(s:release(b,one));T.truthy(s:release(a,one))
	local two=s:admit(42,b);T.truthy(s:activate(b,two,42))
	T.falsy(s:release(a,one));T.truthy(s:matches(b,two,"active"))
end)
T.test("AG76 unrelated owners have distinct canonical identities",function()
	local a,b=Session.new(42,true,true),Session.new(43,true,true)
	T.truthy(a.islandId~=b.islandId);T.equal(a:admit(43,{}),nil);T.equal(b:admit(42,{}),nil)
end)
T.test("AG76 preserves all thirteen station and service anchors inside core",function()
	T.equal(#Config.stationOrder,13)
	for _,id in ipairs(Config.stationOrder) do
		local p=Island.offset(Config,id);T.equal(p,Config.stations[id].offset)
		T.truthy(Island.contains(p[1],p[3],4))
		for _,q in pairs(Config.stations[id].waypoints) do T.truthy(Island.contains(q[1],q[3],1)) end
	end
	for id in pairs(Island.serviceOffsets) do local p=Island.offset(Config,id);T.truthy(Island.contains(p[1],p[3],4)) end
	T.truthy(Island.contains(0,20,4));T.equal(Island.offset(Config,"forged"),nil)
end)
T.test("AG76 safe bounds reject the old neighbouring plots and invalid coordinates",function()
	T.falsy(Island.contains(95,0));T.falsy(Island.contains(0,150));T.falsy(Island.contains(math.huge,0))
	T.falsy(Island.contains(0/0,0));T.falsy(Island.contains("0",0))
	T.truthy(Island.contains(0,-8));T.falsy(Island.contains(42.5,0,1))
end)
T.test("AG76 remote Market allowlist never opens production paid or P2P actions",function()
	for _,id in ipairs({"buySeed","shopFamiliar","buyEventGold"}) do
		T.truthy(Island.marketAllowed(true,true,id));T.falsy(Island.marketAllowed(false,true,id));T.falsy(Island.marketAllowed(true,false,id))
	end
	for _,id in ipairs({"exchangeEssence","summon","fuse","requestPurchase","build","acceptOrder","tradeConfirm","click"}) do
		T.falsy(Island.marketAllowed(true,true,id))
	end
end)
T.test("AG76 haul endpoints preserve logical stock destinations without changing job",function()
	local job={kind="haul",sourceKind="inventory",destinationKind="questStock",duration=4,amount=2,itemId="healing"}
	local a,b=Island.haulEndpoints(job);T.equal(a,"warehouse");T.equal(b,"orders")
	T.equal(job.duration,4);T.equal(job.amount,2)
	job.sourceKind="output";job.sourceStationId="garden2";job.destinationKind="input";job.destinationStationId="cauldron2"
	a,b=Island.haulEndpoints(job);T.equal(a,"garden2");T.equal(b,"cauldron2")
	job.destinationKind="inventory";a,b=Island.haulEndpoints(job);T.equal(b,"warehouse")
	T.equal(Island.haulEndpoints(nil),nil)
end)
T.test("AG76 admission does not mint island data or alter V8 factory state",function()
	local profile=Factory.newProfile(42,1000);local before=Factory.newProfile(42,1000)
	local s=Session.new(42,true,true);local actor={};local token=s:admit(42,actor)
	T.truthy(s:activate(actor,token,profile.userId));T.truthy(s:release(actor,token))
	T.equal(profile.schemaVersion,8);T.equal(profile.island,nil);T.equal(profile.gold,before.gold);T.equal(profile.essence,before.essence)
	T.truthy(Factory.validate(profile));T.equal(profile.lastSimulatedAt,before.lastSimulatedAt)
	T.equal(profile.starter.claimed,before.starter.claimed)
end)
T.test("AG76 does not revive the rejected Essence exchange",function()
	local p=Factory.newProfile(42,1000);local gold,essence=p.gold,p.essence
	local ok=Factory.act(p,"exchangeEssence",{gold=1},1000)
	T.falsy(ok);T.equal(p.gold,gold);T.equal(p.essence,essence)
end)
T.test("AG76 bounded prop reuse stays under inherited budget at all stations",function()
	local count,triangles=0,0
	for _,id in ipairs(Config.stationOrder) do if id~="crystal" then
		local n,t=Props.metrics(Props.station(Config,id));count+=n;triangles+=t
	end end
	local n,t=Props.metrics(Props.lantern());count+=n*4;triangles+=t*4
	T.truthy(count<=Props.maxParts);T.truthy(triangles<=Props.maxTriangleCharge)
	T.truthy(count+Island.maxSceneryParts+12<=Props.combinedPartLimit)
end)
T.finish()
return true
