--!nonstrict
-- Finite motion slots include plants fading out; never double the cap on a turn.
local Motion={}
function Motion.step(entries,limit,elapsed)
	local occupied,desired=0,0; local speed=math.clamp(elapsed,0,.1)*2
	for _,w in ipairs(entries) do
		local cost=w.cost or 1
		w.wanted=w.visible and desired+cost<=limit
		if w.wanted then desired+=cost end
		w.weight=w.weight or 0
		if w.weight>0 then
			if occupied+cost>limit then w.weight=0
			elseif w.wanted then w.weight=math.min(1,w.weight+speed)
			else w.weight=math.max(0,w.weight-speed) end
			if w.weight>0 then occupied+=cost end
		end
	end
	for _,w in ipairs(entries) do
		local cost=w.cost or 1
		if w.wanted and w.weight==0 and occupied+cost<=limit then w.weight=math.min(1,speed); occupied+=cost end
	end
	return occupied
end
return Motion
