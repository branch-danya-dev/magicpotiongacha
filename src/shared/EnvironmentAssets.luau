--!strict
-- Original CC0 images, Restricted to addout studio; see ag69-delivery.json.
-- No network or engine dependency. Loading belongs to EnvironmentView only.
local Assets={}
Assets.keys=table.freeze({"sky_bk","sky_dn","sky_ft","sky_lf","sky_rt","sky_up","sun","moon","mist","rainbow","meadow","star"})
Assets.ids=table.freeze({
	sky_bk="130725840424597",sky_dn="83662321011462",sky_ft="87150286021124",
	sky_lf="106481090533297",sky_rt="96243370555026",sky_up="127569253577461",
	sun="127279777775296",moon="120296233207649",mist="106126272501921",
	rainbow="96590033453082",meadow="104321131031052",star="99406398694311",
})
function Assets.uri(key:string):string
	return "rbxassetid://"..assert((Assets.ids :: {[string]:string})[key],"Unknown environment image")
end
export type Delivery={complete:boolean,status:{[string]:string}}
function Assets.new():Delivery
	local state:Delivery={complete=false,status={}}
	for _,key in ipairs(Assets.keys) do state.status[key]="pending" end
	return state
end
function Assets.record(state:Delivery,uri:string,success:boolean)
	if state.complete then return end
	for _,key in ipairs(Assets.keys) do
		if uri==Assets.uri(key) then
			-- Failure is terminal even if duplicate callbacks arrive later.
			if state.status[key]~="failed" then state.status[key]=success and "success" or "failed" end
			return
		end
	end
end
function Assets.finish(state:Delivery)
	for _,key in ipairs(Assets.keys) do if state.status[key]=="pending" then state.status[key]="failed" end end
	state.complete=true
end
function Assets.ready(state:Delivery,key:string):boolean
	return state.complete and state.status[key]=="success"
end
function Assets.skyReady(state:Delivery):boolean
	for i=1,6 do if not Assets.ready(state,Assets.keys[i]) then return false end end
	return true
end
function Assets.failures(state:Delivery):number
	local count=0
	for _,key in ipairs(Assets.keys) do if state.status[key]=="failed" then count+=1 end end
	return count
end
return table.freeze(Assets)
