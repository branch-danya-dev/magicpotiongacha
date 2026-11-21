--!nonstrict
-- P0: do not fade entire trunk/crown meshes because the camera briefly
-- intersects a bounds volume. This caused full-mesh visibility thrashing.
local M={}
function M.target(_part,_camera)
 return 0
end
return M
