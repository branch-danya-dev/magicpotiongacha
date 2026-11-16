--!nonstrict
-- One bounded texture set, constructed once by EnvironmentView. No events/loops/Lighting writes.
local Run=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Cycle=require(Shared.LunarCycle)
local Data=require(Shared.LunarPixels)
local M={}
function M.create(moon,baseSize)
	assert(Run:IsStudio(),"Local lunar textures are Studio QA only")
	local self={images={},labels={},ready=false,error=nil,alpha=0,weights={1,0,0},destroyed=false}
	local function editable(size,pixels)
		local image=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(size,size)})
		assert(image,"EditableImage memory budget exhausted")
		table.insert(self.images,image)
		image:WritePixelsBuffer(Vector2.zero,Vector2.new(size,size),pixels)
		return image
	end
	local function label(image,name,scale)
		local v=Instance.new("ImageLabel");v.Name=name;v.BackgroundTransparency=1;v.ImageTransparency=1
		v.Size=UDim2.fromScale(scale,scale);v.Position=UDim2.fromScale(.5,.5);v.AnchorPoint=Vector2.new(.5,.5)
		v.ImageContent=Content.fromObject(image);v.Parent=moon.gui;table.insert(self.labels,v);return v
	end
	local ok,err=pcall(function()
		for i=1,3 do
			local pixels=game:GetService("EncodingService"):Base64Decode(buffer.fromstring(Data.disks[i]))
			assert(buffer.len(pixels)==Data.size*Data.size*4,"Lunar pixel length mismatch")
			label(editable(Data.size,pixels),Cycle.names[i],1)
		end
		local size=64;local pixels=buffer.create(size*size*4)
		for y=0,size-1 do for x=0,size-1 do
			local r=math.sqrt(((x+.5-size/2)/(size/2))^2+((y+.5-size/2)/(size/2))^2)
			local alpha=(1-Cycle.smooth((r-.35)/.65))^2*255;local at=(y*size+x)*4
			buffer.writeu8(pixels,at,255);buffer.writeu8(pixels,at+1,255);buffer.writeu8(pixels,at+2,255);buffer.writeu8(pixels,at+3,math.floor(alpha))
		end end
		self.halo=label(editable(size,pixels),"LunarHalo",1.22);self.halo.ZIndex=1
		for i=1,3 do self.labels[i].ZIndex=2 end
	end)
	self.ready=ok;self.error=not ok and tostring(err) or nil
	if ok then moon.gui.Size=UDim2.fromScale(baseSize*2.5,baseSize*2.5)
	else
		for _,v in ipairs(self.labels) do v:Destroy() end;table.clear(self.labels)
		for _,v in ipairs(self.images) do v:Destroy() end;table.clear(self.images)
		warn("R4B_LOCAL_TEXTURE_BLOCKED",err)
	end
	function self.update(sample,weights,direction,quality)
		self.weights=table.clone(weights);self.alpha=Cycle.alpha(sample,direction.Y)
		if not self.ready then moon.image.ImageTransparency=1-self.alpha;return end
		moon.gui.Enabled=true;moon.image.ImageTransparency=1
		for i=1,3 do self.labels[i].ImageTransparency=1-self.alpha*weights[i] end
		self.halo.ImageColor3=Color3.fromRGB(table.unpack(Cycle.palette(weights,"halo")))
		self.halo.ImageTransparency=1-self.alpha*Cycle.halo(quality)
	end
	function self.stats()
		return {ready=self.ready,error=self.error,editableImages=#self.images,labels=#self.labels,
			pixelBytes=Data.size*Data.size*12+64*64*4,alpha=self.alpha,weights=table.clone(self.weights),
			halo=self.halo and self.halo.ImageTransparency<1 or false,consumer="BillboardGui/EditableImage",destroyed=self.destroyed}
	end
	function self.destroy()
		if self.destroyed then return end;self.destroyed=true
		for _,v in ipairs(self.labels) do v:Destroy() end;table.clear(self.labels)
		for _,v in ipairs(self.images) do v:Destroy() end;table.clear(self.images);self.ready=false
	end
	return self
end
return M
