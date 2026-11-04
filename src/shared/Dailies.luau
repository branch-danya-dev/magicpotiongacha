--!nonstrict
-- UTC days and real server events only; neither method awards a claim reward.
local Dailies={}
function Dailies.day(now) return math.floor(now/86400) end
function Dailies.empty() return {day=-1,progress={essence=0,brew=0,orders=0},claimed={}} end
function Dailies.sync(p,now)
	local day=Dailies.day(now); local d=p.longTerm.daily
	if day<d.day then return false,"Server day moved backwards" end
	if day>d.day then d=Dailies.empty(); d.day=day; p.longTerm.daily=d end
	return true,d
end
function Dailies.record(config,p,event,amount,now)
	if not p.longTerm or not config.longTerm.daily[event] then return end
	local ok,d=Dailies.sync(p,now); if not ok then return end
	local target=config.longTerm.daily[event].targets[d.day%3+1]
	d.progress[event]=math.min(target,d.progress[event]+amount)
end
return Dailies
