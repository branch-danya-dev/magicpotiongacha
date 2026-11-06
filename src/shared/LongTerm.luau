--!nonstrict
-- Pure candidate commands. The runtime persists the candidate before presenting success.
local runtimeScript=rawget(getfenv(),"script")
local Protocol=require(runtimeScript and runtimeScript.Parent.Protocol or "./Protocol")
local C=require(runtimeScript and runtimeScript.Parent.TradeCodec or "./TradeCodec")
local Epochs=require(runtimeScript and runtimeScript.Parent.Epochs or "./Epochs")
local Dailies=require(runtimeScript and runtimeScript.Parent.Dailies or "./Dailies")
local Familiars=require(runtimeScript and runtimeScript.Parent.Familiars or "./Familiars")
local LongTerm={}
local actions={rebirth=true,buyRebirthPerk=true,chooseRebirthPet=true,claimDaily=true,claimCalendar=true,deliverCalendarPet=true}
local function plain(v) return type(v)=="table" and getmetatable(v)==nil end
local function integer(v,lo,hi) return type(v)=="number" and v==v and v%1==0 and v>=lo and v<=hi end
local function count(t) local n=0; for _ in pairs(t) do n+=1 end; return n end
function LongTerm.isAction(action) return actions[action]==true end
function LongTerm.new(config)
	local service={}; local familiars=Familiars.new(config); local rules=config.longTerm
	function service.initial(p)
		return {sequence=0,shards=0,earned=0,spent=0,shardsPaid=false,perks={industry=0,essence=0,title=0},
			cycle={id=p.rebirths,finalProduced=false},milestoneClaimed=p.phase>=3 or p.nextCauldronSerial>1,
			daily=Dailies.empty(),calendar={lastDay=-1,step=0,series=0,uniqueAwarded=false,pendingPet=false,delivered=false}}
	end
	function service.validate(p)
		local t=p.longTerm
		if not plain(t) or not integer(t.sequence,0,config.maxBalance) or not integer(t.shards,0,config.maxBalance)
			or not integer(t.earned,0,p.rebirths) or not integer(t.spent,0,t.earned) or t.shards+t.spent~=t.earned
			or type(t.shardsPaid)~="boolean" or not plain(t.perks) or count(t.perks)~=#rules.perkOrder
			or not plain(t.cycle) or t.cycle.id~=p.rebirths or type(t.cycle.finalProduced)~="boolean"
			or type(t.milestoneClaimed)~="boolean" then return false end
		if t.cycle.finalProduced and (p.phase~=4 or not p.discoveredRecipes[Epochs.rules(config,p).finalRecipe]) then return false end
		local perkSpend=0
		for key,def in pairs(rules.perks) do
			if not integer(t.perks[key],0,def.max) then return false end
			perkSpend+=t.perks[key]*def.cost
		end
		if perkSpend>t.spent or (t.perks.title>0 and p.entitlements.chrononaut~=true) then return false end
		local last=t.last
		if t.sequence==0 then if last~=nil then return false end
		elseif not plain(last) or last.requestId~=t.sequence or not actions[last.action]
			or type(last.fingerprint)~="string" or #last.fingerprint>1024 or #last.fingerprint<1
			or not plain(last.result) or type(last.result.message)~="string" or #last.result.message>256 then return false end
		local d,cal=t.daily,t.calendar; local maxDay=math.floor(config.maxTimestamp/86400)
		if not plain(d) or not integer(d.day,-1,maxDay) or not plain(d.progress) or count(d.progress)~=3 or not plain(d.claimed) then return false end
		for key,def in pairs(rules.daily) do
			if not integer(d.progress[key],0,d.day<0 and 0 or def.targets[d.day%3+1]) then return false end
		end
		for key,value in pairs(d.claimed) do
			if not rules.daily[key] or value~=true or d.day<0 or d.progress[key]<rules.daily[key].targets[d.day%3+1] then return false end
		end
		if not plain(cal) or not integer(cal.lastDay,-1,maxDay) or not integer(cal.step,0,7) or not integer(cal.series,0,config.maxCount)
			or type(cal.uniqueAwarded)~="boolean" or type(cal.pendingPet)~="boolean" or type(cal.delivered)~="boolean"
			or (cal.lastDay==-1)~=(cal.step==0) or cal.uniqueAwarded~=(cal.series>0)
			or (cal.pendingPet and cal.delivered) or (cal.uniqueAwarded~=(cal.pendingPet or cal.delivered))
			or (cal.uniqueAwarded and p.entitlements.chronicler~=true) then return false end
		return true
	end
	function service.state(p,now)
		local t=p.longTerm; local epoch=Epochs.rules(config,p); local reasons={}
		if p.phase~=4 then table.insert(reasons,"Построй фазу 4") end
		if not t.cycle.finalProduced then table.insert(reasons,"Произведи "..config.recipes[epoch.finalRecipe].name.." в этом цикле") end
		if p.trade.pending then table.insert(reasons,"Дождись восстановления обмена") end
		if (p.currencyPaid.gold and p.gold>0) or (p.currencyPaid.essence and p.essence>0) then table.insert(reasons,"Баланс с платным происхождением: Rebirth недоступен до правил M6") end
		if p.rebirths>=config.maxCount then table.insert(reasons,"Достигнут предел циклов") end
		local preview={longTerm={daily=C.copy(t.daily)}}; local synced,d=Dailies.sync(preview,now); d=synced and d or preview.longTerm.daily
		local daily={}; for _,key in ipairs(rules.dailyOrder) do local def=rules.daily[key]; table.insert(daily,{id=key,name=def.name,target=def.targets[math.max(0,d.day)%3+1],progress=d.progress[key],claimed=d.claimed[key]==true,reward=C.copy(def.reward)}) end
		local day=Dailies.day(now); local cal=t.calendar
		local step=day<=cal.lastDay and cal.step or ((day==cal.lastDay+1 and cal.step<7) and cal.step+1 or 1)
		return {rebirths=p.rebirths,epoch=epoch.name,epochId=Epochs.id(p),nextEpoch=config.epochRules[(p.rebirths+1)%3].name,
			finalRecipe=epoch.finalRecipe,available=#reasons==0,reasons=reasons,shards=t.shards,perks=C.copy(t.perks),requestId=t.sequence+1,
			manualClickEssence=(p.starter and p.starter.legacyGrant ~= true and config.economyV2 and config.economyV2.clickEssence or config.manualClickEssence)+Epochs.essence(p),
			daily=daily,day=day,calendarStep=step,calendarClaimed=cal.lastDay>=day,calendarPending=cal.pendingPet,
			calendarSpecial=step==7 and (not cal.uniqueAwarded or (day==cal.lastDay and cal.series==1)),
			calendarUnique=cal.uniqueAwarded,calendarReward=C.copy(rules.calendar[step]),last=t.last and {requestId=t.last.requestId,action=t.last.action,result=C.copy(t.last.result)}}
	end
	local function reward(p,value)
		for key,amount in pairs(value) do if p[key]+amount>config.maxBalance then return false,"Сначала освободи место в балансе" end end
		for key,amount in pairs(value) do p[key]+=amount end
		return true
	end
	local function pet(p,species,source,paid)
		if count(p.pets)>=config.maxPets then return nil,"Коллекция заполнена: Fuse освобождает места; право на награду сохранено" end
		local id=string.format("%.0f",p.userId)..":pet:"..p.nextPetSerial
		if p.nextPetSerial>=config.maxCount or p.pets[id] then return nil,"Pet identity conflict" end
		p.pets[id]=familiars.create(id,species,config.familiarShop[species].stats,source,paid)
		p.nextPetSerial+=1; return id
	end
	function service.apply(profile,action,payload,engine,context)
		if not actions[action] or not Protocol.validate(action,payload) then return false,"Invalid long-term intent" end
		if profile.trade.pending or context.tradeActive then return false,"Finish the active trade first" end
		local now=context.now
		if not integer(now,0,config.maxTimestamp) or now<profile.lastSimulatedAt then return false,"Invalid server clock" end
		if context.guard and not context.guard() then return false,"Player session or location changed" end
		local key=C.encode({action=action,payload=payload}); local old=profile.longTerm
		if payload.requestId==old.sequence and old.last then
			if old.last.fingerprint~=key then return false,"Request ID conflict" end
			return true,C.copy(old.last.result),true
		end
		if payload.requestId~=old.sequence+1 or old.sequence>=config.maxBalance then return false,"Stale long-term request" end
		local p=C.copy(profile); local t=p.longTerm; local result={message="Прогресс сохранён"}
		local report=engine.advance(p,now,false); if not report.ok then return false,report.error end
		if action=="rebirth" then
			if payload.expectedRebirthCount~=p.rebirths then return false,"Cycle changed; review again" end
			local state=service.state(p,now); if not state.available then return false,table.concat(state.reasons,"; ") end
			local reset=engine.newProfile(p.userId,now)
			for _,field in ipairs({"gold","essence","inventory","questStock","order","phase","stations","warehouseLevel","pipes","manualReadyAt","slimeWorkSeconds","pipeCursor","inputCursors","lastSimulatedAt"}) do p[field]=reset[field] end
			-- Rebirth still restores the historical starter layout. The empty C01 plot applies only to a brand-new profile.
			for _,id in ipairs(config.stationOrder) do
				local definition=config.stations[id]
				local station=p.stations[id]
				station.level=definition.initialLevel
				station.recipeId=definition.initialLevel>0 and definition.defaultRecipe or nil
			end
			p.rebirths+=1; t.cycle={id=p.rebirths,finalProduced=false}; t.shards+=1; t.earned+=1
			p.rngState=(p.rngState*48271+p.rebirths)%2147483647; if p.rngState==0 then p.rngState=1 end
			result={message="Перерождение сохранено: +1 Time Shard",rebirths=p.rebirths,epoch=Epochs.rules(config,p).name,shards=t.shards,petsKept=count(p.pets),cauldronsKept=count(p.cauldrons)}
		elseif action=="buyRebirthPerk" then
			local def=rules.perks[payload.perkId]; if not def then return false,"Unknown perk" end
			if t.perks[payload.perkId]~=payload.expectedLevel then return false,"Perk level changed" end
			if t.perks[payload.perkId]>=def.max or (payload.perkId=="title" and p.entitlements.chrononaut) then return false,"Уже приобретено" end
			if t.shards<def.cost then return false,"Недостаточно Time Shards" end
			t.shards-=def.cost; t.spent+=def.cost; t.perks[payload.perkId]+=1
			if payload.perkId=="title" then p.entitlements.chrononaut=true end
			result.message="Постоянное улучшение: "..def.name
		elseif action=="chooseRebirthPet" then
			if not table.find(rules.choiceOrder,payload.offerId) then return false,"Unknown direct choice" end
			if t.shards<rules.choiceCost then return false,"Недостаточно Time Shards" end
			local id,reason=pet(p,payload.offerId,"rebirth_shop",t.shardsPaid); if not id then return false,reason end
			t.shards-=rules.choiceCost; t.spent+=rules.choiceCost; result.petId=id; result.message="Выбранный фамильяр получен"
		elseif action=="claimDaily" then
			if payload.expectedDay~=Dailies.day(now) then return false,"UTC day changed" end
			local ok,d=Dailies.sync(p,now); if not ok then return false,d end
			local def=rules.daily[payload.questId]; if not def then return false,"Unknown daily quest" end
			if d.claimed[payload.questId] then return false,"Уже получено сегодня" end
			if d.progress[payload.questId]<def.targets[d.day%3+1] then return false,"Задание ещё не выполнено" end
			local granted,reason=reward(p,def.reward); if not granted then return false,reason end
			d.claimed[payload.questId]=true; result.message="Награда ежедневного задания сохранена"
		elseif action=="claimCalendar" then
			local day=Dailies.day(now); local cal=t.calendar
			if payload.expectedDay~=day or day<=cal.lastDay then return false,"Calendar already claimed or UTC day changed" end
			local step=(day==cal.lastDay+1 and cal.step<7) and cal.step+1 or 1
			if step==7 and cal.series>=config.maxCount then return false,"Calendar series limit" end
			if step==7 and not cal.uniqueAwarded then
				cal.uniqueAwarded=true; cal.pendingPet=true; p.entitlements.chronicler=true
				result.message="Серия завершена: титул Летописец и право получить Moon Cat"
			else local ok,reason=reward(p,rules.calendar[step]); if not ok then return false,reason end; result.message="Награда календаря: день "..step end
			cal.lastDay,cal.step=day,step; if step==7 then cal.series+=1 end
		elseif action=="deliverCalendarPet" then
			local cal=t.calendar; if not cal.pendingPet then return false,"Нет неполученной награды" end
			local id,reason=pet(p,rules.calendarPet,"calendar",false); if not id then return false,reason end
			cal.pendingPet=false; cal.delivered=true; result.petId=id; result.message="Moon Cat из календаря получен"
		end
		t.sequence=payload.requestId; t.last={requestId=payload.requestId,action=action,fingerprint=key,result=C.copy(result)}
		if not engine.validate(p) then return false,"Invalid long-term candidate" end
		table.clear(profile); for field,value in pairs(p) do profile[field]=value end
		return true,result,false
	end
	return service
end
return LongTerm
