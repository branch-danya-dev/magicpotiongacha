--!nonstrict
-- Visual-only placeholders attached to the existing authoritative garden and cauldron anchors.
-- No collisions, scripts, economy or new interactive remotes.
local Props = {}
local function piece(parent, name, size, position, color, material)
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.Position=position;p.Anchored=true
 p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=material;p.Color=color;p.Parent=parent
 return p
end
local function tag(part, message)
 local gui=Instance.new("BillboardGui")
 gui.Name="AlchemyLabel";gui.Size=UDim2.fromOffset(200,42)
 gui.StudsOffsetWorldSpace=Vector3.new(0,3.2,0)
 gui.AlwaysOnTop=false;gui.MaxDistance=48;gui.Parent=part
 local text=Instance.new("TextLabel")
 text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1
 text.TextColor3=Color3.fromRGB(243,228,199);text.TextStrokeTransparency=.45
 text.Font=Enum.Font.GothamMedium;text.TextScaled=true;text.Text=message;text.Parent=gui
end
function Props.attach(plot)
 local crystal=assert(plot.anchors.crystal,"Missing crystal/extractor logical anchor")
 local cauldron=assert(plot.anchors.cauldron,"Missing cauldron anchor")
 local garden=assert(plot.anchors.garden,"Missing garden anchor")
 local root=Instance.new("Model");root.Name="AlchemyFirstPlaceholders"
 root:SetAttribute("StudioOnly",true);root:SetAttribute("VisualOnly",true);root.Parent=plot.model
 -- Temporary geometric proof of the extractor; GLB integration is a separate art gate.
 -- Keep the internal station id 'crystal' for V8 saves. No new resource or timer exists.
 local extractor=piece(root,"ExtractorPlaceholder",Vector3.new(3.9,1.1,3),
  crystal.Position+Vector3.new(0,-2.15,0),Color3.fromRGB(84,62,49),Enum.Material.Wood)
 extractor:SetAttribute("StationId","crystal");extractor:SetAttribute("ModelPending",true)
 local boiler=piece(root,"ExtractorBoiler",Vector3.new(2.1,2.1,2.1),
  crystal.Position+Vector3.new(-.7,-.7,0),Color3.fromRGB(125,72,43),Enum.Material.Metal)
 boiler.Shape=Enum.PartType.Ball
 local flask=piece(root,"ExtractorGlassPreview",Vector3.new(1.5,1.8,1.5),
  crystal.Position+Vector3.new(1,-.6,0),Color3.fromRGB(194,154,213),Enum.Material.Glass)
 flask.Shape=Enum.PartType.Ball;flask.Transparency=.32
 piece(root,"ExtractorCopperPipe",Vector3.new(2.3,.3,.3),
  crystal.Position+Vector3.new(.3,.24,0),Color3.fromRGB(166,102,57),Enum.Material.Metal)
 tag(extractor,"Экстрактор Essence")
 local cube=piece(root,"BrewingCube",Vector3.new(4.5,3.5,4.5),
  cauldron.Position+Vector3.new(0,.35,0),Color3.fromRGB(72,65,93),Enum.Material.SmoothPlastic)
 cube:SetAttribute("StationId","cauldron")
 tag(cube,"Варка зелий")
 local soil=piece(root,"HerbGarden",Vector3.new(12,.24,8),
  garden.Position+Vector3.new(0,-.86,0),Color3.fromRGB(67,49,39),Enum.Material.Ground)
 soil:SetAttribute("StationId","garden")
 for lane=-1,1 do
  piece(root,"GardenRow_"..(lane+2),Vector3.new(2.4,.21,6),
   soil.Position+Vector3.new(lane*3,0.22,0),
   Color3.fromRGB(99,73,52),Enum.Material.Ground)
 end
 tag(soil,"Огород")
 return root
end
return Props
