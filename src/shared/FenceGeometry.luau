--!nonstrict
-- These are low decorative fences that stop walking, not outer ridge walls.
-- Jumping over their 3.2-stud post tops is intentional; the island edge is separate.
local Fence={bottom=.2,top=3.2,depth=.5,endpointOverlap=.1}
function Fence.size(length,roll)
	return {length*math.abs(math.cos(math.rad(roll or 0)))+Fence.endpointOverlap*2,Fence.top-Fence.bottom,Fence.depth}
end
return Fence
