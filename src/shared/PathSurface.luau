--!nonstrict
-- Separate the thin imported stone patches in XZ. RenderFidelity is already
-- Precise: increasing it cannot fix intersecting flattened surfaces.
local Path={gap=.20,radius=.968,template="RockPath_Round_Small_1"}
function Path.fit(parts)
	local result={}
	for i,d in ipairs(parts) do
		if d.template~=Path.template then result[i]=d; continue end
		local radius=d.scale*Path.radius
		for j,other in ipairs(parts) do if i~=j and other.template==Path.template then
			local dx,dz=d.position[1]-other.position[1],d.position[3]-other.position[3]
			radius=math.min(radius,math.max(0,(math.sqrt(dx*dx+dz*dz)-Path.gap)/2))
		end end
		assert(radius>0,"Coincident path patch centers")
		local copy=table.clone(d); copy.scale=radius/Path.radius
		-- Keep authored vertical thickness, ground offset, id, yaw and collision.
		copy.flatten=d.flatten*d.scale/copy.scale
		result[i]=copy
	end
	return result
end
return Path
