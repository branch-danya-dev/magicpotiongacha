--!nonstrict
local A = require(game.ReplicatedStorage.PotionTycoon.Shared.SpellbookSoulAssets)
local V = {}
V.cyan = Color3.fromRGB(105, 221, 255)
V.violet = Color3.fromRGB(174, 125, 255)
V.white = Color3.fromRGB(242, 250, 255)
V.ember = Color3.fromRGB(255, 156, 69)
function V.part(parent, name, size)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Transparency = 1
	p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
	p.Parent = parent
	return p
end
function V.surface(parent, face)
	local gui = Instance.new("SurfaceGui"); gui.Face = face; gui.CanvasSize = Vector2.new(512, 512)
	gui.LightInfluence = 0; gui.Brightness = 1.4; gui.AlwaysOnTop = false; gui.Parent = parent
	return gui
end
function V.image(parent, texture, color, x, y, width, height)
	local im = Instance.new("ImageLabel"); im.BackgroundTransparency = 1; im.Size = UDim2.fromScale(1, 1)
	im.Image = texture; im.ImageColor3 = color; im.ImageTransparency = 1
	if width then im.ImageRectOffset = Vector2.new(x, y); im.ImageRectSize = Vector2.new(width, height) end
	im.Parent = parent
	return im
end
function V.rune(parent, index)
	local p = V.part(parent, "OrbitRune" .. index, Vector3.new(.05, .05, .05))
	local gui = Instance.new("BillboardGui"); gui.Name = "ReadableGlyph"; gui.Size = UDim2.fromScale(1.45, 1.85)
	gui.LightInfluence = 0; gui.Brightness = 1.45; gui.AlwaysOnTop = false; gui.MaxDistance = 110; gui.Parent = p
	local glyph = index % 4
	return {part = p, image = V.image(gui, A.sigil, V.cyan, 512 + glyph % 2 * 256, 512 + math.floor(glyph / 2) * 256, 256, 256)}
end
function V.attachment(parent, name)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = parent; return a
end
function V.emitter(parent, name, color)
	local e = Instance.new("ParticleEmitter"); e.Name = name; e.Enabled = false; e.Rate = 0; e.Parent = parent
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color, V.white); e.LightEmission = .8; e.LightInfluence = 0
	e.Lifetime = NumberRange.new(.35, .6); e.Speed = NumberRange.new(2, 3.5)
	e.EmissionDirection = Enum.NormalId.Front; e.SpreadAngle = Vector2.new(12, 12)
	e.Drag = 1.5; e.Acceleration = Vector3.new(0, .65, 0)
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, .16), NumberSequenceKeypoint.new(.4, .09), NumberSequenceKeypoint.new(1, 0)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .2), NumberSequenceKeypoint.new(.3, .05), NumberSequenceKeypoint.new(1, 1)})
	return e
end
function V.pool(parent, config)
	local pool = {pages = {}, streams = {}, emitters = {}, sector = 0}
	pool.root = Instance.new("Folder"); pool.root.Name = "RitualPool"; pool.root.Parent = parent
	-- Publish partial ownership before constructing, so the caller can clean up on error.
	return pool
end
function V.populate(pool, config)
	pool.carrier = V.part(pool.root, "BeamCarrier", Vector3.new(.05, .05, .05))
	for i = 1, config.pages do
		local page = {panels = {}}; table.insert(pool.pages, page)
		for side = 0, 1 do
			local p = V.part(pool.root, "FoldedPage" .. i .. "_" .. side, Vector3.new(.38, .88, .01))
			local panel = {part = p, side = side, images = {}, edges = {}}; table.insert(page.panels, panel)
			for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
				local gui = V.surface(p, face); gui.Brightness = 1.15
				table.insert(panel.images, V.image(gui, A.pages, V.white, side * 128, 0, 128, 256))
				local edge = V.image(gui, A.pages, V.white, side * 128, 512, 128, 256); edge.ZIndex = 2
				table.insert(panel.edges, edge)
			end
		end
	end
	for i = 1, config.streams do
		local stream = {nodes = {}, beams = {}}; table.insert(pool.streams, stream)
		for j = 1, 4 do table.insert(stream.nodes, V.attachment(pool.carrier, "Soul" .. i .. "Node" .. j)) end
		for j = 1, 3 do for layer = 1, 2 do
			local b = Instance.new("Beam"); b.Name = layer == 1 and "SoulHalo" or "SoulCore"; b.Parent = pool.carrier
			b.Attachment0 = stream.nodes[j]; b.Attachment1 = stream.nodes[j + 1]; b.Segments = 8; b.FaceCamera = true
			b.Texture = A.wisp; b.TextureMode = Enum.TextureMode.Stretch; b.TextureSpeed = .65
			b.Color = ColorSequence.new(layer == 1 and (i % 2 == 0 and V.violet or V.cyan) or V.white)
			b.LightEmission = 1; b.LightInfluence = 0; b.Width0 = layer == 1 and .7 or .25; b.Width1 = b.Width0 * .65
			b.Enabled = false; table.insert(stream.beams, b)
		end end
	end
	if not config.calm then
		pool.ash = V.attachment(pool.carrier, "AshOrigin"); pool.chest = V.attachment(pool.carrier, "AbsorptionOrigin")
		table.insert(pool.emitters, V.emitter(pool.ash, "FallingEmbers", V.ember))
		table.insert(pool.emitters, V.emitter(pool.chest, "AbsorptionFlash", V.cyan))
		pool.emitters[1].Acceleration = Vector3.new(0, -2.5, 0)
		pool.emitters[2].Speed = NumberRange.new(.15, .5); pool.emitters[2].Lifetime = NumberRange.new(.2, .4)
		pool.emitters[2].Size = NumberSequence.new({NumberSequenceKeypoint.new(0, .65), NumberSequenceKeypoint.new(.35, .32), NumberSequenceKeypoint.new(1, 0)})
	end
end
return V
