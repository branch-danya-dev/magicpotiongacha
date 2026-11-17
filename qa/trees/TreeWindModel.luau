--!strict
-- Portable math only. GlobalWind is supplied by the existing environment owner.
local M={}
function M.finite(n:number):number return if n==n and math.abs(n)<1e6 then n else 0 end
function M.smooth(current:number,target:number,dt:number,seconds:number):number
	return current+(M.finite(target)-current)*(1-math.exp(-math.max(0,math.min(dt,1))/math.max(.05,seconds)))
end
function M.sample(c:any,time:number,phase:number,branch:number,length:number,x:number,z:number,quality:string,reduce:boolean):(number,number)
	if reduce then return 0,0 end
	x=M.finite(x);z=M.finite(z)
	if time~=time or math.abs(time)==math.huge then time=0 end
	local speed=math.sqrt(x*x+z*z)
	if speed<.001 then return 0,0 end
	local b=c.budgets[quality] or c.budgets.reduced
	local t=time-branch*c.branchDelay
	local p=phase+branch*c.phaseSpread
	-- Small actual wind remains legible; zero wind remains physically still.
	local strength=math.min(1,speed/20)^.65
	local wave=.60+.30*math.sin(t*c.speed+p)+.10*math.sin(t*c.speed*1.987+p*1.7)
	local gust=1+c.gustResponse*math.min(1,speed/35)*(.5+.5*math.sin(t*.29+phase))
	local angle=c.amplitude*b.scale*strength*wave*gust*math.clamp(length,.5,1.35)
	return x/speed*angle,z/speed*angle
end
return M
