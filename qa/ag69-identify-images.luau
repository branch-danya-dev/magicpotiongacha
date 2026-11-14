--!nocheck
-- Studio EDIT Command Bar only, in the existing private Experience.
-- Read existing assets, hash decoded RGBA8, destroy temporary image buffers.
-- Does not upload, edit assets, change permissions, save or publish the place.
assert(game:GetService("RunService"):IsStudio())
assert(game.GameId==10776120489 and game.PlaceId==125724638469407)
local ids={83662321011462,106481090533297,120296233207649,106126272501921,99406398694311,87150286021124,104321131031052,130725840424597,127569253577461,96590033453082,96243370555026,127279777775296}
for _,id in ipairs(ids) do
	local image
	local ok,err=pcall(function()
		image=game:GetService("AssetService"):CreateEditableImageAsync(Content.fromUri("rbxassetid://"..id))
		assert(image,"nil image")
		local size=image.Size
		local hash=game:GetService("EncodingService"):ComputeBufferHash(image:ReadPixelsBuffer(Vector2.zero,size),Enum.HashAlgorithm.Sha256)
		local hex=""
		for i=0,buffer.len(hash)-1 do hex..=string.format("%02x",buffer.readu8(hash,i)) end
		print("AG69_PIXELS",id,size.X,size.Y,hex)
	end)
	if image then image:Destroy() end
	if not ok then warn("AG69_PROBE_ERROR",id,err) end
end
print("AG69_IDENTIFY_COMPLETE",game.GameId,game.PlaceId)
