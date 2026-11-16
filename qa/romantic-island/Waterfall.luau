--!nonstrict
-- Native, bounded QA waterfall. No textures/uploads or global Lighting writes.
local W={}
function W.create(root,origin,mistTexture)
	local folder=Instance.new("Folder");folder.Name="RomanticWaterfall";folder.Parent=root
	local function slab(name,size,pos,color,alpha,material)
		local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=origin+pos
		p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
		p.Color=color;p.Transparency=alpha;p.Material=material or Enum.Material.SmoothPlastic;p.Parent=folder;return p
	end
	local blue=Color3.fromRGB(96,193,218)
	-- A shallow lip at the owner's (+55,+11) marker runs beyond the outer cliff edge.
	slab("WaterLip",Vector3.new(9,.09,4.2),Vector3.new(58,.68,11),blue,.35)
	local host=slab("WaterHost",Vector3.one,Vector3.new(63,-.1,11),blue,1)
	local beams,emitters={},{}
	for i=1,3 do
		local top=Instance.new("Attachment");top.Position=Vector3.new(0,0,(i-2)*1.3);top.Parent=host
		local bottom=Instance.new("Attachment");bottom.Position=Vector3.new(1.8,-69,(i-2)*1.5);bottom.Parent=host
		local b=Instance.new("Beam");b.Name="WaterRibbon";b.Attachment0=top;b.Attachment1=bottom
		b.Width0=i==2 and 2 or .8;b.Width1=i==2 and 2.3 or .65;b.FaceCamera=true;b.Segments=10
		b.CurveSize0=1.6;b.CurveSize1=2.2;b.Color=ColorSequence.new(blue,Color3.fromRGB(185,220,235))
		b.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(.8,.5),NumberSequenceKeypoint.new(1,.98)})
		b.LightEmission=.35;b.LightInfluence=.25;b.Parent=host;table.insert(beams,b)
		local e=Instance.new("ParticleEmitter");e.Name="FallingDroplets";e.Texture=mistTexture
		e.Lifetime=NumberRange.new(1.8,2.2);e.Speed=NumberRange.new(18,25);e.Acceleration=Vector3.new(0,-12,0)
		e.EmissionDirection=Enum.NormalId.Bottom;e.SpreadAngle=Vector2.new(2,2);e.Size=NumberSequence.new(.24)
		e.Color=b.Color;e.Transparency=NumberSequence.new(.38,1);e.LightEmission=.25;e.Rate=0;e.Parent=top
		table.insert(emitters,e)
	end
	local pool=Instance.new("Attachment");pool.Position=Vector3.new(2,-69,0);pool.Parent=host
	local spray=Instance.new("ParticleEmitter");spray.Name="WaterMist";spray.Texture=mistTexture
	spray.Lifetime=NumberRange.new(2,3);spray.Speed=NumberRange.new(.5,1.5);spray.SpreadAngle=Vector2.new(90,90)
	spray.Size=NumberSequence.new(5,11);spray.Color=ColorSequence.new(Color3.fromRGB(155,193,225))
	spray.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.8),NumberSequenceKeypoint.new(1,1)})
	spray.LightEmission=.12;spray.Rate=0;spray.Parent=pool
	local state={quality="full",motion=false}
	local function set(quality,motion)
		state.quality=quality;state.motion=motion
		for i,b in ipairs(beams) do b.Enabled=quality=="full" or i==2 end
		for _,e in ipairs(emitters) do e:Clear();e.Rate=(quality=="minimal" or motion) and 0 or (quality=="full" and 5 or 2) end
		spray:Clear();spray.Rate=(quality=="minimal" or motion) and 0 or (quality=="full" and 3 or 1)
	end
	local function stats()
		local n,rate=0,spray.Rate;for _,b in ipairs(beams) do if b.Enabled then n+=1 end end
		for _,e in ipairs(emitters) do rate+=e.Rate end
		return {beams=n,particleRate=rate,localLights=0,quality=state.quality,reduceMotion=state.motion}
	end
	return {set=set,stats=stats,destroy=function() folder:Destroy() end}
end
return W
