--!nonstrict
-- Finite motion slots include plants fading out; never double the cap on a turn.
local Motion={}
function Motion.step(entries,limit,elapsed)
	local occupied=0; local speed=math.clamp(elapsed,0,.1)*2
	for i,w in ipairs(entries) do
		w.wanted=i<=limit and w.visible
		w.weight=w.weight or 0
		if w.weight>0 then
			if occupied>=limit then w.weight=0
			elseif w.wanted then w.weight=math.min(1,w.weight+speed)
			else w.weight=math.max(0,w.weight-speed) end
			if w.weight>0 then occupied+=1 end
		end
	end
	for _,w in ipairs(entries) do
		if w.wanted and w.weight==0 and occupied<limit then w.weight=math.min(1,speed); occupied+=1 end
	end
	return occupied
end
return Motion
