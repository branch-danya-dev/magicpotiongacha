--!nonstrict
-- AG71 B: pure presentation. Authority and receipt validation remain inherited.
local runtimeScript=rawget(getfenv(),"script")
local Landscape=require(runtimeScript and runtimeScript.Parent.Landscape or "./Landscape")
local Session=require(runtimeScript and runtimeScript.Parent.Parent.FirstSessionView or "../FirstSessionView")
local M={releaseEnabled=false,routes=Landscape.routes}
M.choices={{id="farmer",icon="owl",name="Сова",confirm="Выбрать Сову"},
 {id="slime",icon="slime",name="Слайм",confirm="Выбрать Слайма"},
 {id="brewer",icon="cat",name="Кот",confirm="Выбрать Кота"}}
function M.enabled(studio,flag,loaded,width,height)
 return studio==true and flag~=false and loaded==true and width>=620 and width>=height
end
function M.present(state,pending,config)
 local p=Landscape.present(state,pending)
 p.intro=Session.intro(state); p.canChoose=p.intro and state.writable==true and not pending
 p.canCollect=state~=nil and state.writable==true and not pending
 p.goal=state and Session.line(state,config) or "Загрузка…"
 p.goal=p.goal:gsub("кристалла","книги")
 p.upgrade.reason=Session.explain(p.upgrade.reason)
 if p.goal=="" then p.goal=state and state.tutorial and state.tutorial.complete and "Фабрика работает" or p.quest end
 p.upgradeText=p.upgrade.cost and (tostring(p.upgrade.cost).." · Улучшить") or p.upgrade.label
 if pending then p.upgradeText="Ожидание…" end
 return p
end
function M.choice(id)
 for _,entry in ipairs(M.choices) do if id==entry.id then return entry end end
 return nil
end
local function rect(x,y,w,h) return {x=math.floor(x),y=math.floor(y),w=math.floor(w),h=math.floor(h)} end
function M.layout(width,height,touch,chatRight)
 -- Dimensions already exclude CoreUISafeInsets. Keep all touch corners empty.
 local compact=height<430; local scale=compact and 1 or math.min(1.25,height/620)
 local margin=compact and 12 or 28
 local reserve=touch and (compact and 148 or 220) or 0
 local right=width-margin
 local navW=280*scale; local left=math.max(margin,chatRight and chatRight+12 or margin)
 local nav=rect(right-navW,54*scale,navW,62*scale)
 local goal=rect(left,6,math.max(0,math.min(260*scale,right-236*scale-left-12)),44*scale)
 local chooser=rect(left,6,220*scale,(height<320 and 148 or 166)*scale)
 -- With chat open, move the chooser inward but never over the right dock.
 local chooserFits=chooser.x+chooser.w<=nav.x-12 and chooser.y+chooser.h<=height-reserve
 local pageW=302*scale; local pageH=246*scale
 local pageX=math.max(reserve+8,(width-pageW)*.64)
 pageX=math.min(pageX,width-math.max(reserve,margin)-pageW-8)
 local page=rect(pageX,math.max(54*scale,(height-pageH)*.35),pageW,pageH)
 local inherited=Landscape.layout(width,height,touch,chatRight)
 inherited.panel.w=math.max(240,math.min(inherited.panel.w,nav.x-inherited.panel.x-12))
 return {scale=scale,compact=compact,goal=goal,chooser=chooser,chooserFits=chooserFits,
  nav=nav,gold=rect(right-236*scale,0,116*scale,44*scale),essence=rect(right-116*scale,0,116*scale,44*scale),
  more=rect(width-math.max(reserve,margin)-166*scale,nav.y+nav.h+4,166*scale,144*scale),page=page,
  panel=inherited.panel,rail=inherited.rail,notice=inherited.notice,coach=inherited.coach,
  touchLeft=rect(0,height-reserve,reserve,reserve),touchRight=rect(width-reserve,height-reserve,reserve,reserve)}
end
return M
