--!nonstrict
local HUD=require("../src/shared/ui/Landscape")
local Layout=require("../src/shared/ui/Layout")
local Theme=require("../src/shared/ui/Theme")
local Context=require("../src/shared/ContextUI")
return function(T)
 local function state()
  return {gold=945,essence=37,writable=true,stations={crystal={level=2}},longTerm={manualClickEssence=7},
   tutorial={step=3,total=12,text="Server instruction",complete=false},builds={crystal={cost=900,available=true}},
   presentation={essenceClick={sequence=1,plotIndex=2}}}
 end
 T.test("AG64 data comes from snapshot, including non-demo amounts and tutorial total",function()
  local s=state(); local v=HUD.present(s,false)
  T.equal(v.gold,"945"); T.equal(v.essence,"37"); T.equal(v.level,"2"); T.equal(v.amount,"7")
  T.equal(v.quest,"Server instruction"); T.equal(v.steps,"03 / 12"); T.equal(v.progress,2/12)
  s.tutorial.complete=true; T.equal(HUD.present(s,false).progress,1)
 end)
 T.test("AG64 loading fails closed without invented prices or grants",function()
  local v=HUD.present(nil,false); T.equal(v.upgrade.enabled,false); T.equal(v.level,"—"); T.equal(v.amount,"—")
 end)
 T.test("AG64 upgrade respects server availability, price, writable state and pending",function()
  local s=state(); T.equal(HUD.upgrade(s,false).enabled,true)
  T.equal(HUD.upgrade(s,true).enabled,false)
  s.gold=899; T.equal(HUD.upgrade(s,false).enabled,false)
  s.gold=950; s.builds.crystal.available=false; T.equal(HUD.upgrade(s,false).enabled,false)
  s.builds.crystal.available=true; s.writable=false; T.equal(HUD.upgrade(s,false).enabled,false)
 end)
 T.test("AG64 maximum and malformed offers cannot be purchased",function()
  local s=state(); s.builds.crystal.cost=nil; T.equal(HUD.upgrade(s,false).label,"MAX LEVEL")
  for _,cost in ipairs({-1,0/0,math.huge,"100"}) do s.builds.crystal.cost=cost; T.equal(HUD.upgrade(s,false).enabled,false) end
 end)
 T.test("AG64 price and expected level change with a new server snapshot",function()
  local s=state(); s.stations.crystal.level=3; s.builds.crystal.cost=2200
  local v=HUD.upgrade(s,false); T.equal(v.level,3); T.equal(v.cost,2200); T.equal(v.enabled,false)
 end)
 T.test("AG64 first snapshot, passive income, rejected and replayed clicks do not show grants",function()
  local s=state(); local cursor,amount=HUD.feedback(nil,s,2,10000); T.equal(cursor,1); T.equal(amount,nil)
  s.essence=73; cursor,amount=HUD.feedback(cursor,s,2,10000); T.equal(amount,nil)
  s.presentation.essenceClick.sequence=2; cursor,amount=HUD.feedback(cursor,s,2,10000); T.equal(amount,7)
  cursor,amount=HUD.feedback(cursor,s,2,10000); T.equal(amount,nil)
  s.presentation.essenceClick.sequence=1; local nextCursor; nextCursor,amount=HUD.feedback(cursor,s,2,10000); T.equal(nextCursor,2); T.equal(amount,nil)
 end)
 T.test("AG64 receipt requires owned plot and excludes partial cap grants",function()
  local s=state(); local _,amount=HUD.feedback(0,s,3,10000); T.equal(amount,nil)
  s.essence=10000; _,amount=HUD.feedback(0,s,2,10000); T.equal(amount,nil)
  s.essence=10; s.writable=false; _,amount=HUD.feedback(0,s,2,10000); T.equal(amount,nil)
 end)
 T.test("AG64 rollback and portrait retain the legacy HUD",function()
  T.equal(HUD.enabled(nil,844,390),true); T.equal(HUD.enabled(false,844,390),false)
  T.equal(HUD.enabled(true,390,844),false); T.equal(HUD.enabled(true,1024,768),true)
 end)
 T.test("AG64 approved palette is isolated from foundation tokens",function()
  local before=Theme.resolve("Soul"); local custom=HUD.tokens()
  T.equal(custom.color.surface[1],27); T.equal(Theme.resolve("Soul").color.surface[1],before.color.surface[1])
 end)
 T.test("AG64 routes reuse existing menus",function()
  T.equal(HUD.routes.Book,"crystal"); T.equal(HUD.routes.Familiars,"altar"); T.equal(HUD.routes.Brew,"cauldron")
  T.equal(HUD.routes.Lab,"blueprint"); T.equal(HUD.routes.Shop,"supplies"); T.equal(HUD.routes.Rewards,"dailies"); T.equal(HUD.routes.Settings,"quality")
 end)
 for _,size in ipairs({{844,390},{740,360},{1024,768},{1366,768},{1920,1080}}) do
  for _,touch in ipairs({false,true}) do
   T.test("AG64 safe layout "..size[1].."x"..size[2].." touch="..tostring(touch),function()
    local w,h=size[1],size[2]-58; local p=HUD.layout(w,h,touch,nil); local safe={x=0,y=0,w=w,h=h}
    local boxes={p.gold,p.essence,p.settings,p.quest,p.shop,p.rewards,p.book,p.dock}
    for i,a in ipairs(boxes) do
     T.equal(Layout.inside(safe,a),true)
     if i>=3 then T.equal(a.w>=44 and a.h>=44,true) end
     if touch then T.equal(Layout.overlaps(a,p.touchLeft),false); T.equal(Layout.overlaps(a,p.touchRight),false) end
     for j,b in ipairs(boxes) do if j>i then T.equal(Layout.overlaps(a,b),false) end end
    end
    T.equal(p.dock.h/4-4>=44,true)
    T.equal(Layout.inside(safe,p.panel),true)
   end)
  end
 end
 T.test("AG64 desktop chat reservation moves left panels away from chat",function()
  local p=HUD.layout(1920,1022,false,620); T.equal(p.quest.x>=632,true); T.equal(p.book.x>=632,true)
 end)
 T.test("AG64 mobile center retains the native book interaction clearance",function()
  for _,size in ipairs({{750,332},{740,302}}) do
   local w,h=size[1],size[2]; local p=HUD.layout(w,h,true,nil); local blocked={}
   for _,r in ipairs({p.title,p.gold,p.essence,p.settings,p.quest,p.shop,p.rewards,p.book,p.dock}) do
    table.insert(blocked,{x=r.x,y=r.y+58,w=r.w,h=r.h})
   end
   -- Native prompt clearance is 240x100, larger than its visible icon.
   local candidates=Context.candidates({{id="book",enabled=true,visible=true,clear=true,owner=1,
    distance=5,maximum=16,z=24,x=w/2+5,y=200}},1,w,h+58,blocked)
   T.equal(#candidates,1)
  end
 end)
 for _,size in ipairs({{750,332},{646,302}}) do
  T.test("AG64 notched phone safe area "..size[1].."x"..size[2],function()
   local p=HUD.layout(size[1],size[2],true,nil)
   T.equal(Layout.inside({x=0,y=0,w=size[1],h=size[2]},p.rail),true)
   T.equal(p.rail.w>=104 and p.rail.h>=52,true)
   for _,r in ipairs({p.quest,p.book,p.dock,p.shop,p.rewards,p.gold,p.essence,p.touchLeft,p.touchRight}) do
    T.equal(Layout.overlaps(p.rail,r),false)
   end
  end)
 end
end
