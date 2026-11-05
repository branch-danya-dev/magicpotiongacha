--!nonstrict
-- Compact-support sculpture outside the accepted traversal polygon. Startup only.
local runtimeScript=rawget(getfenv(),"script")
local Boundary=require(runtimeScript and runtimeScript.Parent.IslandBoundary or "./IslandBoundary")
local segments=Boundary.segments()
local Ridge={version=1,peaks={{-264,-51,43,31,43},{-252,-111,47,34,39},
	{-215,-166,44,38,29},{-161,-181,46,38,30},{-105,-183,42,33,28}}}
local function smooth(x) x=math.clamp(x,0,1); return x*x*(3-2*x) end
function Ridge.outside(x,z)
	local distance=math.huge
	for _,s in ipairs(segments) do
		distance=math.min(distance,((s.b[1]-s.a[1])*(z-s.a[2])-(s.b[2]-s.a[2])*(x-s.a[1]))/s.length)
	end
	return -distance
end
function Ridge.lift(x,z,height)
	-- Keep the whole playable side and a four-stud exterior margin exactly intact.
	local mask=smooth((Ridge.outside(x,z)-4)/18)
	if mask==0 then return 0 end
	local remaining,total,target=1,0,0
	for _,p in ipairs(Ridge.peaks) do
		local radius=((x-p[1])/p[4])^2+((z-p[2])/p[5])^2
		local weight=math.max(0,1-radius)^2 -- zero height and slope at support boundary
		remaining*=1-weight; total+=weight; target+=p[3]*weight
	end
	return total>0 and math.max(0,target/total-(height or 0))*(1-remaining)*mask or 0
end
function Ridge.apply(x,z,height,material)
	local lift=Ridge.lift(x,z,height)
	if lift==0 then return height,material end
	local slope=math.sqrt((Ridge.lift(x+.5,z,height)-Ridge.lift(x-.5,z,height))^2+(Ridge.lift(x,z+.5,height)-Ridge.lift(x,z-.5,height))^2)
	-- Rock shoulders break up the old carpet; quiet grassy shelves cap the ridge.
	if slope>.55 or (lift>4 and lift<7 and math.sin(x*.08+z*.11)>.25) then material="Rock" end
	return height+lift,material
end
return Ridge
