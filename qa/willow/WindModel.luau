--!strict
-- Pure wind response. Reads are supplied by the client; no Workspace writes.
local M={}
type Budget={hz:number,distance:number,trees:number,scale:number}
local budgets:{[string]:Budget}={full={hz=30,distance=220,trees=20,scale=1},reduced={hz=15,distance=150,trees=12,scale=.8},minimal={hz=6,distance=90,trees=6,scale=.4}}
function M.budget(quality:string):Budget
	return budgets[quality] or budgets.reduced
end
local function finite(x:number):number return if x==x and math.abs(x)<1e6 then x else 0 end
function M.sample(time:number,phase:number,x:number,z:number,quality:string,reduceMotion:boolean):(number,number)
	if reduceMotion then return 0,0 end
	x=finite(x);z=finite(z);phase=finite(phase)
	-- GetServerTimeNow is Unix time (~1.8e9), not a small elapsed duration.
	-- Reject non-finite time without applying the wind-input magnitude guard.
	if time~=time or math.abs(time)==math.huge then time=0 end
	local speed=math.sqrt(x*x+z*z)
	if speed<.001 then return 0,0 end
	local strength=math.min(speed/20,1)*M.budget(quality).scale
	local wave=.60+.30*math.sin(time*.82+phase)+.10*math.sin(time*1.63+phase*1.7)
	local angle=.055*strength*wave
	return x/speed*angle,z/speed*angle
end
return M
