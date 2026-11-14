--!nonstrict
local M=require("../src/shared/ui/Arcade")
local Legacy=require("../src/shared/ui/Landscape")
local Layout=require("../src/shared/ui/Layout")
local Config=require("../src/shared/Config")
return function(T)
 local function state()
  return {gold=1000,essence=25,writable=true,stations={crystal={level=1}},longTerm={manualClickEssence=5},
   starter={claimed=false,legacyGrant=false},tutorial={id="familiar",text="Server tutorial",step=1,total=10},
   builds={crystal={cost=900,available=true}},presentation={essenceClick={sequence=1,plotIndex=2}}}
 end
 T.test("AG71 release, missing assets, explicit rollback and portrait fail closed",function()
  T.equal(M.enabled(true,nil,true,844,390),true)
  for _,c in ipairs({{false,true,true,844,390},{true,false,true,844,390},{true,true,false,844,390},{true,true,true,390,844}}) do T.equal(M.enabled(table.unpack(c)),false) end
  T.equal(M.releaseEnabled,false)
 end)
 T.test("AG71 uses server balance, level, cost and manual amount without mutation",function()
  local s=state(); s.longTerm.manualClickEssence=13; s.gold=1234; s.builds.crystal.cost=321
  local p=M.present(s,false,Config); T.equal(p.gold,Legacy.present(s,false).gold); T.equal(p.amount,"13"); T.equal(p.level,"1")
  T.equal(p.upgradeText,"321 · Улучшить"); T.equal(s.gold,1234); T.equal(s.essence,25)
 end)
 T.test("AG71 chooser is one-time and excludes legacy grants",function()
  local s=state(); T.equal(M.present(s,false,Config).canChoose,true)
  s.starter.claimed=true; T.equal(M.present(s,false,Config).intro,false)
  s.starter.claimed=false; s.starter.legacyGrant=true; T.equal(M.present(s,false,Config).intro,false)
  T.equal(M.choice("farmer").icon,"owl"); T.equal(M.choice("brewer").icon,"cat"); T.equal(M.choice("slime").icon,"slime"); T.equal(M.choice("forged"),nil)
 end)
 T.test("AG71 loading pending readonly unavailable and max retain safety",function()
  T.equal(M.present(nil,false,Config).canCollect,false)
  local s=state(); local p=M.present(s,true,Config); T.equal(p.canChoose,false); T.equal(p.canCollect,false); T.equal(p.upgrade.enabled,false)
  s.writable=false; p=M.present(s,false,Config); T.equal(p.canChoose,false); T.equal(p.canCollect,false); T.equal(p.upgrade.enabled,false)
  s.writable=true; s.gold=899; T.equal(M.present(s,false,Config).upgrade.enabled,false)
  s.builds.crystal.cost=nil; T.equal(M.present(s,false,Config).upgradeText,"MAX LEVEL")
 end)
 T.test("AG71 preserves all seven destinations",function()
  local count=0; for k,v in pairs(M.routes) do T.equal(v,Legacy.routes[k]); count+=1 end; T.equal(count,7)
 end)
 for _,size in ipairs({{844,390},{740,360},{1024,768},{1366,768},{1920,1080},{780,360}}) do
  for _,touch in ipairs({false,true}) do
   T.test("AG71 B safe layout "..size[1].."x"..size[2].." touch="..tostring(touch),function()
    local w,h=size[1],size[2]-58; local p=M.layout(w,h,touch,nil); local safe={x=0,y=0,w=w,h=h}
    for _,key in ipairs({"goal","gold","essence","nav","page","more","chooser"}) do
     local r=p[key]; T.equal(Layout.inside(safe,r),true,key.." bounds")
     if touch then T.equal(Layout.overlaps(r,p.touchLeft),false,key.." joystick"); T.equal(Layout.overlaps(r,p.touchRight),false,key.." jump") end
    end
    T.equal(p.nav.w/5>=44,true); T.equal(p.nav.h>=44,true); T.equal(p.more.h/3>=44,true)
    T.equal(p.chooserFits,true); T.equal(Layout.overlaps(p.chooser,p.nav),false); T.equal(Layout.overlaps(p.goal,p.gold),false)
   end)
  end
 end
 T.test("AG71 chat may return chooser to inherited safe coaching",function()
  local p=M.layout(844,332,true,360); T.equal(p.chooserFits,false)
 end)
 T.test("AG71 receipt semantics reject replay rejection passive and foreign income",function()
  local s=state(); local cursor,amount=Legacy.feedback(nil,s,2,1e9); T.equal(amount,nil)
  s.essence+=100; cursor,amount=Legacy.feedback(cursor,s,2,1e9); T.equal(amount,nil)
  s.presentation.essenceClick.sequence=2; cursor,amount=Legacy.feedback(cursor,s,2,1e9); T.equal(amount,5)
  local _,replay=Legacy.feedback(cursor,s,2,1e9); T.equal(replay,nil)
  s.presentation.essenceClick.sequence=3; _,amount=Legacy.feedback(cursor,s,3,1e9); T.equal(amount,nil)
 end)
end
