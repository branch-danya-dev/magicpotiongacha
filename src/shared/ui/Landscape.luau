--!nonstrict
-- AG64: snapshot projection and safe-area layout only. No intents or profile writes.
local runtimeScript=rawget(getfenv(),"script")
local Binding=require(runtimeScript and runtimeScript.Parent.Binding or "./Binding")
local Layout=require(runtimeScript and runtimeScript.Parent.Layout or "./Layout")
local Feedback=require(runtimeScript and runtimeScript.Parent.Parent.SpellbookFeedback or "../SpellbookFeedback")
local Theme=require(runtimeScript and runtimeScript.Parent.Theme or "./Theme")
local HUD={}
HUD.routes={Book="crystal",Familiars="altar",Brew="cauldron",Lab="blueprint",Shop="supplies",Rewards="dailies",Settings="quality"}
function HUD.enabled(flag,width,height) return flag~=false and width>=620 and width>=height end
local function number(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end
function HUD.upgrade(state,pending)
 local offer=state and state.builds and state.builds.crystal
 local level=state and state.stations and state.stations.crystal and state.stations.crystal.level
 if not offer or not number(level) then return {enabled=false,label="Загрузка…",reason="Ожидание профиля"} end
 if pending then return {enabled=false,label="Ожидание…",reason="Ждём сервер",level=level,cost=offer.cost} end
 if not state.writable then return {enabled=false,label="Недоступно",reason="Сохранение приостановлено",level=level,cost=offer.cost} end
 if offer.cost==nil then return {enabled=false,label="MAX LEVEL",reason="Максимальный уровень",level=level} end
 if not number(offer.cost) or offer.cost<0 then return {enabled=false,label="Недоступно",reason="Нет предложения",level=level} end
 local enough=number(state.gold) and state.gold>=offer.cost
 return {enabled=offer.available==true and enough,label="UPGRADE · "..Binding.text(offer.cost),cost=offer.cost,level=level,
  reason=offer.available~=true and (offer.reason or "Недоступно") or (not enough and "Не хватает Gold" or "Улучшение за Gold")}
end
function HUD.present(state,pending)
 local resources=Binding.resources(state)
 local tutorial=state and state.tutorial or {}
 local book=state and state.stations and state.stations.crystal
 local amount=state and state.longTerm and state.longTerm.manualClickEssence
 local total=number(tutorial.total) and math.max(1,tutorial.total) or 1
 local step=number(tutorial.step) and math.clamp(tutorial.step,0,total) or 0
 local completed=tutorial.complete and total or math.max(0,step-1)
 return {gold=resources.goldText,essence=resources.essenceText,level=book and tostring(book.level) or "—",
  amount=number(amount) and Binding.text(amount) or "—",quest=tutorial.text or "Ожидаем безопасную загрузку профиля…",
  questTitle=tutorial.complete and "Фабрика работает" or "Текущее задание",
  progress=completed/total,steps=string.format("%02d / %02d",step,total),upgrade=HUD.upgrade(state,pending)}
end
function HUD.feedback(cursor,state,owned,maxBalance)
 local nextCursor,accepted=Feedback.consume(cursor,state and state.presentation and state.presentation.essenceClick,owned)
 local amount=state and state.longTerm and state.longTerm.manualClickEssence
 -- The existing receipt has no amount. Full clicks use the server-projected amount.
 -- At the balance cap a grant may be partial; suppress the numeric popup rather
 -- than inventing an amount or interpreting passive income as a click.
 local full=state and number(state.essence) and state.essence<maxBalance
 return nextCursor,accepted and state.writable==true and full and number(amount) and amount>0 and amount or nil
end
function HUD.tokens()
 local t=Theme.resolve("Soul")
 -- Approved Figma 4Qfq1mf8p4oNLVqQH85yfI / 7:21; isolated HUD palette.
 t.color.surface={27,29,49}; t.color.raised={33,30,52}; t.color.well={20,23,40}
 t.color.ink={248,240,232}; t.color.muted={200,192,210}; t.color.line={114,98,125}
 t.color.engraving={134,122,150}; t.color.accent={163,125,177}; t.color.veil={59,49,77}
 t.font.body="GothamBold"; t.size.radius=13; t.size.text=12
 return t
end
local function rect(x,y,w,h) return {x=math.floor(x),y=math.floor(y),w=math.floor(w),h=math.floor(h)} end
function HUD.layout(width,height,touch,chatRight)
 -- Input dimensions are already CoreUISafeInsets; never subtract the top bar twice.
 local compact=height<430
 local scale=compact and 1 or math.min(1.25,height/620)
 scale=math.max(1,scale)
 local margin=compact and 12 or math.floor(math.min(44,width*.04))
 local left=math.max(margin,chatRight and chatRight+12 or 0)
 local thumb=touch and 148 or 0
 local listReserve=not touch and width>=900 and 200 or margin
 local right=math.max(margin,listReserve,compact and thumb or 0)
 local dockW=compact and 64 or 92*scale
 local dockH=compact and 192 or 288*scale
 local top=compact and 66 or 76*scale
 local dock=rect(width-right-dockW,top,dockW,math.min(dockH,height-top-(touch and not compact and 148 or 12)))
 local chipW=compact and math.clamp((width-380)/2,116,154) or 172*scale
 local chipH=compact and 52 or 58*scale
 local settings=rect(width-listReserve-Layout.touch(44*scale),8,Layout.touch(44*scale),Layout.touch(44*scale))
 local resourcesX=math.min(settings.x-20-(2*chipW+10),math.max(width*.41,left+220))
 local title=rect(left,12,math.max(0,math.min(260*scale,resourcesX-left-16)),40*scale)
 local questW=compact and math.min(238,width*.34) or 260*scale
 local questH=compact and 82 or 104*scale
 local quest=rect(left,top,questW,questH)
 local shop=rect(left,top+questH+6,48*scale,Layout.touch(45*scale))
 if compact and touch and shop.y+shop.h>height-140 then shop.x=math.max(left,thumb) end
 local rewards=rect(shop.x+shop.w+9,shop.y,shop.w,shop.h)
 local bookW=compact and 238 or 260*scale
 local bookH=compact and 90 or 101*scale
 local bookX=compact and touch and math.max(left,thumb+8) or left
 local bookY=height-bookH-(touch and not compact and 156 or 12)
 local book=rect(bookX,bookY,bookW,bookH)
 -- Existing internal sheet stays between touch controls and the navigation dock.
 local panelLeft=math.max(left,touch and 156 or left)
 local panelWidth=math.max(240,math.min(400*scale,dock.x-panelLeft-12))
 local panel=rect(panelLeft,top,panelWidth,math.min(660,height-top-12))
 local rail=rect(math.max(book.x+book.w+8,(width-250)/2),height-64,math.min(250,dock.x-book.x-book.w-20),52)
 if rail.w<104 then rail=rect(quest.x+quest.w+8,top,math.max(104,dock.x-quest.x-quest.w-16),52) end
 return {scale=scale,compact=compact,title=title,settings=settings,dock=dock,quest=quest,shop=shop,rewards=rewards,book=book,
  gold=rect(resourcesX,6,chipW,chipH),essence=rect(resourcesX+chipW+10,6,chipW,chipH),panel=panel,rail=rail,
  notice=rect(panel.x,top,math.min(400,panel.w),64),
  coach=rect(panel.x,top,math.min(450,panel.w),math.min(230,height-top-12)),
  touchLeft=rect(0,height-140,148,140),touchRight=rect(width-148,height-140,148,140)}
end
return HUD
