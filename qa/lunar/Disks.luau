--!nonstrict
-- One bounded texture set, constructed once by EnvironmentView. No events/loops/Lighting writes.
local Run=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Cycle=require(Shared.LunarCycle)
local Data=require(Shared.LunarPixels)
local Presentation=require(Shared.LunarPresentation)
local M={}
function M.create(moon,baseSize)
	assert(Run:IsStudio(),"Local lunar textures are Studio QA only")
	local self={images={},labels={},ready=false,error=nil,alpha=0,weights={1,0,0},destroyed=false,
		style="after",scale=Presentation.candidateScale,pixelWrites=0}
	local function write(image,size,pixels)
		image:WritePixelsBuffer(Vector2.zero,Vector2.new(size,size),pixels);self.pixelWrites+=1
	end
	local function editable(size,pixels)
		local image=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(size,size)})
		assert(image,"EditableImage memory budget exhausted")
		table.insert(self.images,image)
		write(image,size,pixels)
		return image
	end
	local function label(image,name,scale)
		local v=Instance.new("ImageLabel");v.Name=name;v.BackgroundTransparency=1;v.ImageTransparency=1
		v.Size=UDim2.fromScale(scale,scale);v.Position=UDim2.fromScale(.5,.5);v.AnchorPoint=Vector2.new(.5,.5)
		v.ImageContent=Content.fromObject(image);v.Parent=moon.gui;table.insert(self.labels,v);return v
	end
	local function haloPixels(style)
		local size=64;local pixels=buffer.create(size*size*4)
		for y=0,size-1 do for x=0,size-1 do
			local r=math.sqrt(((x+.5-size/2)/(size/2))^2+((y+.5-size/2)/(size/2))^2)
			local alpha=Presentation.haloAlpha(r,style)*255;local at=(y*size+x)*4
			buffer.writeu8(pixels,at,255);buffer.writeu8(pixels,at+1,255);buffer.writeu8(pixels,at+2,255);buffer.writeu8(pixels,at+3,math.floor(alpha))
		end end
		return pixels
	end
	local ok,err=pcall(function()
		for i=1,3 do
			local pixels=game:GetService("EncodingService"):Base64Decode(buffer.fromstring(Data.disks[i]))
			assert(buffer.len(pixels)==Data.size*Data.size*4,"Lunar pixel length mismatch")
			label(editable(Data.size,pixels),Cycle.names[i],1)
		end
		self.halo=label(editable(64,haloPixels(self.style)),"LunarHalo",Presentation.haloScale);self.halo.ZIndex=1
		for i=1,3 do self.labels[i].ZIndex=2 end
	end)
	self.ready=ok;self.error=not ok and tostring(err) or nil
	if ok then moon.gui.Size=UDim2.fromScale(baseSize*2.5*self.scale,baseSize*2.5*self.scale)
	else
		for _,v in ipairs(self.labels) do v:Destroy() end;table.clear(self.labels)
		for _,v in ipairs(self.images) do v:Destroy() end;table.clear(self.images)
		warn("R4B_LOCAL_TEXTURE_BLOCKED",err)
	end
	function self.setScale(scale)
		if self.destroyed or not Presentation.scaleValid(scale) then return false end
		self.scale=scale
		if self.ready then moon.gui.Size=UDim2.fromScale(baseSize*2.5*scale,baseSize*2.5*scale) end
		return true
	end
	function self.setStyle(style)
		if self.destroyed or not self.ready or (style~="before" and style~="after") then return false end
		if self.style==style then return true end
		-- Explicit QA A/B command only; reuse four images. Never called by update().
		local sources=style=="before" and Data.before or Data.disks
		for i=1,3 do write(self.images[i],Data.size,game:GetService("EncodingService"):Base64Decode(buffer.fromstring(sources[i]))) end
		write(self.images[4],64,haloPixels(style));self.style=style
		local scale=style=="before" and 1.22 or Presentation.haloScale
		self.halo.Size=UDim2.fromScale(scale,scale)
		return true
	end
	function self.update(sample,weights,direction,quality)
		self.weights=table.clone(weights);self.alpha=Cycle.alpha(sample,direction.Y)
		if not self.ready then moon.image.ImageTransparency=1-self.alpha;return end
		moon.gui.Enabled=true;moon.image.ImageTransparency=1
		for i=1,3 do self.labels[i].ImageTransparency=1-self.alpha*weights[i] end
		self.halo.ImageColor3=Color3.fromRGB(table.unpack(Cycle.palette(weights,"halo")))
		local strength=self.style=="before" and (quality=="full" and .16 or quality=="reduced" and .08 or 0) or Cycle.halo(quality)
		self.halo.ImageTransparency=1-self.alpha*strength
	end
	function self.stats()
		local bounds
		local camera=workspace.CurrentCamera
		if camera and self.ready then
			local center=moon.attachment.WorldPosition;local half=baseSize*2.5*self.scale/2
			local top=camera:WorldToViewportPoint(center+camera.CFrame.UpVector*half)
			local bottom=camera:WorldToViewportPoint(center-camera.CFrame.UpVector*half)
			local left=camera:WorldToViewportPoint(center-camera.CFrame.RightVector*half)
			local right=camera:WorldToViewportPoint(center+camera.CFrame.RightVector*half)
			bounds={top=top.Y,bottom=bottom.Y,left=left.X,right=right.X,viewportX=camera.ViewportSize.X,viewportY=camera.ViewportSize.Y,
				fullyFramed=top.Z>0 and top.Y>=0 and bottom.Y<=camera.ViewportSize.Y and left.X>=0 and right.X<=camera.ViewportSize.X}
		end
		return {ready=self.ready,error=self.error,editableImages=#self.images,labels=#self.labels,bounds=bounds,
			style=self.style,scale=self.scale,pixelWrites=self.pixelWrites,
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
