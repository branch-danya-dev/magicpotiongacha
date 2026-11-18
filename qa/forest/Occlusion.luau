--!nonstrict
-- Same existing visibility owners/polls; never writes the player camera.
local O={}
function O.alpha(eye:{number},focus:{number},half:{number}):number
	local near,far=0,1
	for axis=1,3 do
		local d=focus[axis]-eye[axis];local h=half[axis]+1
		if math.abs(d)<1e-6 then if math.abs(eye[axis])>h then return 0 end
		else
			local a,b=(-h-eye[axis])/d,(h-eye[axis])/d;if a>b then a,b=b,a end
			near=math.max(near,a);far=math.min(far,b);if near>far then return 0 end
		end
	end
	return .96
end
function O.target(part:any,camera:any):number
	if not part:GetAttribute("ForestOccluder")then return 0 end
	local scale=part:GetAttribute("ForestScale") or 1
	local centre=part:GetAttribute("ForestBoundCenter")
	local half=part:GetAttribute("ForestBoundHalf")
	half=half and half*scale or part.Size*.5
	local eye=part.CFrame:PointToObjectSpace(camera.CFrame.Position)
	local focus=part.CFrame:PointToObjectSpace(camera.Focus.Position)
	if centre then eye-=centre*scale;focus-=centre*scale end
	return O.alpha({eye.X,eye.Y,eye.Z},{focus.X,focus.Y,focus.Z},{half.X,half.Y,half.Z})
end
return O
