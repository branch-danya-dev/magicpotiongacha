--!nonstrict
return function(T)
 local P=require("../qa/ag67/Policy")
 local Feedback=require("../src/shared/SpellbookFeedback")
 T.test("AG67 quality pools are bounded and meet art ranges",function()
  for _,quality in ipairs({"full","reduced","minimal"}) do
   local c=P.quality(quality,false)
   T.truthy(c.pages<=P.maxPages and c.streams<=P.maxStreams and c.books<=P.maxBooks)
   T.equal(c.pages,quality=="full" and 22 or quality=="reduced" and 12 or 4)
  end
 end)
 T.test("AG67 Reduce Motion excludes flight and ribbons",function()
  for _,quality in ipairs({"full","reduced","minimal"}) do
   local c=P.quality(quality,true);T.equal(c.pages,0);T.equal(c.streams,0);T.equal(c.sparks,0);T.equal(c.motion,false)
  end
 end)
 T.test("AG67 confirmed spam coalesces without extending the batch",function()
  local r=P.new();T.truthy(r.trigger(0))
  for i=1,200 do T.equal(r.trigger(i/100),false) end
  T.equal(r.started,0);T.equal(r.confirmed,201);T.equal(r.batches,1)
  T.truthy(r.trigger(2.4));T.equal(r.batches,2)
 end)
 T.test("AG67 cancel removes pending feedback and ritual",function()
  local r=P.new();r.trigger(1);r.cancel();T.equal(r.started,nil);T.equal(r.lastPulse,nil)
 end)
 T.test("AG67 ritual terminates within 2.4 seconds",function()
  T.equal(P.envelope(0),0);T.equal(P.envelope(2.4),0);T.truthy(P.envelope(.5)>.99)
 end)
 T.test("AG67 pages fade before the pool lifetime ends",function()
  for i=1,24 do local s=P.page(2.4,i,24,false);T.equal(s.alpha,0);T.truthy(s.y>=.2) end
 end)
 T.test("AG67 trajectories remain finite and bounded",function()
  for i=1,24 do for frame=0,144 do
   local s=P.page(frame/60,i,24,false)
   for _,v in pairs(s) do T.truthy(v==v and math.abs(v)<100) end
   T.truthy(s.alpha>=0 and s.alpha<=1 and s.scale>=.2 and s.burn<=1)
  end end
 end)
 T.test("AG67 different pages have distinct trajectories",function()
  local a,b=P.page(.8,1,22,false),P.page(.8,2,22,false);T.truthy(math.abs(a.x-b.x)>.1 or math.abs(a.z-b.z)>.1)
 end)
 T.test("AG67 rune orbits are independent and deterministic",function()
  local a,b,c=P.rune(8,1,true,0),P.rune(8,2,true,0),P.rune(8,1,true,0)
  T.equal(a.x,c.x);T.truthy(math.abs(a.y-b.y)>.1);T.truthy(a.yaw~=b.yaw)
 end)
 T.test("AG67 calm runes do not orbit or spin",function()
  local a,b=P.rune(1,2,false,0),P.rune(100,2,false,0);T.equal(a.x,b.x);T.equal(a.y,b.y);T.equal(a.yaw,b.yaw)
 end)
 T.test("AG67 souls start at book and converge to current chest",function()
  for i=1,3 do
   local a,b=P.soul(0,i),P.soul(1,i);T.equal(a.blend,0);T.equal(b.blend,1)
   T.truthy(math.abs(a.x)+math.abs(a.y)+math.abs(a.z)<.00001)
   T.truthy(math.abs(b.x)+math.abs(b.y)+math.abs(b.z)<.00001)
  end
 end)
 T.test("AG67 chest lookup supports R6 R15 and missing rigs",function()
  local function rig(parts) return {FindFirstChild=function(_,n)return parts[n]end} end
  T.equal(P.chest(rig({UpperTorso=15,HumanoidRootPart=1})),15)
  T.equal(P.chest(rig({Torso=6,HumanoidRootPart=1})),6)
  T.equal(P.chest(rig({HumanoidRootPart=1})),1);T.equal(P.chest(nil),nil)
 end)
 T.test("AG67 inherited receipt rejects duplicates and wrong plots",function()
  local cursor,accepted=Feedback.consume(nil,{sequence=5,plotIndex=1},1);T.equal(accepted,false)
  cursor,accepted=Feedback.consume(cursor,{sequence=5,plotIndex=1},1);T.equal(accepted,false)
  cursor,accepted=Feedback.consume(cursor,{sequence=6,plotIndex=2},1);T.equal(accepted,false)
  cursor,accepted=Feedback.consume(cursor,{sequence=7,plotIndex=1},1);T.equal(accepted,true)
 end)
 T.test("AG67 sequential pulse waits for each sector",function()
  T.equal(P.flash(1,1.2),0);T.truthy(P.flash(1.25,1.2)>.5);T.truthy(P.flash(4,1.2)<.001)
 end)
end
