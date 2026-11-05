--!nonstrict
-- Actual replicated Terrain occupancy, not a guessed analytic height. One 32 KiB
-- solid-cell cache, refreshed only after 16 studs of subject travel/teleport.
-- Water is not an obstacle. Native Spherecast still performs the final sweep.
local Geometry=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.CameraGeometry)
local Cache={}
function Cache.new(terrain)
	local self={solid=buffer.create(Geometry.terrainCells),minimum=nil,center=nil,reads=0}
	function self.ensure(focus)
		if self.center then
			local d=focus-self.center
			if math.max(math.abs(d.X),math.abs(d.Y),math.abs(d.Z))<=Geometry.cacheMargin then return end
		end
		local a=Vector3.new(math.floor((focus.X-64)/4)*4,math.floor((focus.Y-64)/4)*4,math.floor((focus.Z-64)/4)*4)
		local materials,occupancy=terrain:ReadVoxels(Region3.new(a,a+Vector3.one*128),4)
		for x=1,32 do for y=1,32 do for z=1,32 do
			local m=materials[x][y][z]
			buffer.writeu8(self.solid,Geometry.index(x,y,z),occupancy[x][y][z]>0 and m~=Enum.Material.Water and m~=Enum.Material.Air and 1 or 0)
		end end end
		self.minimum=a; self.center=a+Vector3.one*64; self.reads+=1
	end
	function self.lift(position,radius)
		local a=self.minimum
		if not a then return position,false end
		local y,inCache=Geometry.terrainLift(self.solid,{a.X,a.Y,a.Z},{position.X,position.Y,position.Z},radius)
		return Vector3.new(position.X,y,position.Z),inCache
	end
	return self
end
return Cache
