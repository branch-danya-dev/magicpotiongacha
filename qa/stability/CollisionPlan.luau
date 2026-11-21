--!nonstrict
-- Pure physical proxy descriptors: colliders follow authored positions, not camera LOD.
local M={}
function M.build(plan)
 local result,seen={},{}
 for _,t in ipairs(plan.trees or {}) do
  assert(type(t.id)=="string" and not seen[t.id],"Duplicate tree collider")
  seen[t.id]=true
  local scale=t.scale or 1
  local radius=math.clamp((t.radius or 7)*.16,.55,2.25)
  result[#result+1]={
   id="TreeTrunk_"..t.id,x=t.x,z=t.z,
   width=2*radius,height=math.clamp(13*scale,5,16),kind="trunk",
  }
 end
 for n,stone in ipairs(plan.stones or {}) do
  local template=stone[1]
  if template=="Rock_Medium_1" or template=="Pebble_Round_1" then
   local scale=stone[4] or 1
   local size=math.clamp(2.5*scale,.8,4.5)
   result[#result+1]={id="Rock_"..n,x=stone[2],z=stone[3],width=size,
    height=math.clamp(1.5*scale,.5,2.8),kind="rock"}
  end
 end
 return result
end
return M
