--!nonstrict
-- Client presentation owner. Only accepted State receipts may start a ritual.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.PotionTycoon.Shared
local P = require(Shared.SpellbookSoulPolicy)
local A = require(Shared.SpellbookSoulAssets)
local Feedback = require(Shared.SpellbookFeedback)
local Controller = require(script.Parent.Parent.EnvironmentController)
local V = require(script.Parent.Primitives)
local View = {}
local function valid(model)
	local back = model:FindFirstChild("LecternAnchor")
	local anchor = back and back.Value
	local link = anchor and anchor:FindFirstChild("SpellbookVisual")
	return model:IsDescendantOf(workspace) and model:GetAttribute("SpellbookLoadState") == "ready"
		and anchor and anchor.Parent == model.Parent and link and link.Value == model
end
function View.start()
	local player = Players.LocalPlayer
	local records, tracked, connections = {}, {}, {}
	local time, elapsed, signature = 0, 0, ""
	local config = P.quality(Controller.quality, Controller.reduceMotion)
	local ritual = P.new()
	local ritualBook, cursor, pool, lastCharacter
	local stopped = false
	local folder = Instance.new("Folder"); folder.Name = "SpellbookSoulVFX"; folder.Parent = workspace
	local stats = {updates = 0, totalMs = 0, maxMs = 0, errors = 0, emitted = 0, bursts = 0, peakInstances = 0}
	local function emit(emitter, count)
		if emitter and count > 0 then emitter:Emit(count); stats.emitted += count end
	end
	local function hideRitual()
		if not pool then return end
		for _, page in ipairs(pool.pages) do for _, panel in ipairs(page.panels) do
			for _, im in ipairs(panel.images) do im.ImageTransparency = 1 end
			for _, im in ipairs(panel.edges) do im.ImageTransparency = 1 end
		end end
		for _, stream in ipairs(pool.streams) do for _, beam in ipairs(stream.beams) do beam.Enabled = false end end
		for _, emitter in ipairs(pool.emitters) do emitter:Clear() end
	end
	local function cancel()
		ritual.cancel(); ritualBook = nil; hideRitual()
	end
	local function clearPool()
		cancel()
		if pool then pool.root:Destroy(); pool = nil end
	end
	local function remove(model)
		local r = records[model]; if not r then return end
		-- An owned model owns even a currently inactive ritual pool.
		if r.owned or ritualBook == model then clearPool() end
		for _, entry in ipairs(r.hidden) do if entry.part.Parent then entry.part.LocalTransparencyModifier = entry.alpha end end
		for _, entry in ipairs(r.pages) do if entry.part.Parent then entry.part.CFrame = entry.frame end end
		r.root:Destroy(); records[model] = nil
	end
	local function clearVisuals()
		clearPool()
		for model in pairs(records) do remove(model) end
	end
	local function chestPart()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local chest = P.chest(character)
		return humanoid and humanoid.Health > 0 and chest and chest:IsDescendantOf(workspace) and chest or nil
	end
	local function add(model, owned)
		local source = model:FindFirstChild("SpellbookLectern")
		local book = source and source:FindFirstChild("Spellbook")
		local cover = book and book:FindFirstChild("Cover")
		local energy = cover and cover:FindFirstChild("EnergyPoint")
		if not energy then return end
		local root = Instance.new("Folder"); root.Name = "SigilAndRunes"; root.Parent = folder
		local r = {root = root, owned = owned, energy = energy, hidden = {}, pages = {}, runes = {}, sectors = {}, emitters = {}, phase = 0, boost = 0, ambientAt = time}
		records[model] = r
		for _, part in ipairs(source:GetDescendants()) do if part:IsA("MeshPart") then
			if part.Name == "Rune0.001" or part.Name == "RingOuter" then
				table.insert(r.hidden, {part = part, alpha = part.LocalTransparencyModifier}); part.LocalTransparencyModifier = 1
			end
			if part.Parent.Name == "LoosePages" then table.insert(r.pages, {part = part, frame = part.CFrame}) end
		end end
		r.plane = V.part(root, "SoulAbsorptionSigil", Vector3.new(10.5, .015, 10.5))
		local pivot = model:GetPivot().Position
		-- One floor sample per allocation, never one raycast per rendered frame.
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {model, folder, player.Character}
		local floor = workspace:Raycast(pivot + Vector3.new(0, 1, 0), Vector3.new(0, -4, 0), params)
		local y = floor and math.max(pivot.Y + .06, floor.Position.Y + .045) or pivot.Y + .32
		r.plane.CFrame = CFrame.new(pivot.X, y, pivot.Z)
		local gui = V.surface(r.plane, Enum.NormalId.Top)
		for i = 1, 6 do
			local im = V.image(gui, A.sigil, V.cyan, 0, 0, 512, 512); im.Rotation = (i - 1) * 60
			table.insert(r.sectors, im)
		end
		r.inner = V.image(gui, A.sigil, V.violet, 512, 0, 512, 512)
		r.channels = V.image(gui, A.sigil, V.cyan, 0, 512, 512, 512)
		for i = 1, config.runes do table.insert(r.runes, V.rune(root, i)) end
		if owned and config.light then
			r.lightOrigin = V.attachment(r.plane, "LocalLightOrigin")
			r.light = Instance.new("PointLight"); r.light.Name = "SpellbookSoulLight"; r.light.Shadows = false; r.light.Range = 7
			r.light.Color = V.cyan; r.light.Brightness = .18; r.light.Parent = r.lightOrigin
		end
		if owned and config.ambient then
			r.orbits = {}
			for i = 1, 2 do
				local attachment = V.attachment(r.plane, "OrbitSparkOrigin" .. i)
				local emitter = V.emitter(attachment, "DirectedSigilSparks" .. i, i == 1 and V.cyan or V.violet)
				table.insert(r.orbits, attachment); table.insert(r.emitters, emitter)
			end
			r.core = V.attachment(r.plane, "CoreGlowOrigin")
			local aura = V.emitter(r.core, "SoftVolume", V.violet); table.insert(r.emitters, aura)
			aura.Texture = "rbxasset://textures/particles/smoke_main.dds"; aura.Speed = NumberRange.new(.04, .1)
			aura.Lifetime = NumberRange.new(1.2, 1.6); aura.EmissionDirection = Enum.NormalId.Top; aura.Acceleration = Vector3.new(0, .1, 0)
			aura.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.5, 2.4), NumberSequenceKeypoint.new(1, 2.8)})
			aura.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.3, .86), NumberSequenceKeypoint.new(1, 1)})
			local motes = V.emitter(r.core, "RisingEssence", V.cyan); table.insert(r.emitters, motes)
			motes.Speed = NumberRange.new(.6, 1); motes.EmissionDirection = Enum.NormalId.Top; motes.Lifetime = NumberRange.new(1.2, 1.8)
		end
	end
	local function pointEmitter(r, index, angle, burst)
		local center = r.plane.Position + Vector3.new(0, .22, 0)
		local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local tangent = Vector3.new(-radial.Z, .2, radial.X)
		local origin = center + radial * 4.15
		local direction = burst and (tangent * .8 - radial * .65 + Vector3.new(0, .6, 0)) or tangent
		r.orbits[index].WorldCFrame = CFrame.lookAt(origin, origin + direction)
	end
	local function ambient(r, now, step)
		local flash = P.flash(now, r.pulse, config.calm)
		r.boost += (flash * 1.7 - r.boost) * math.min(1, step * 5); r.phase += r.boost * step
		for i, im in ipairs(r.sectors) do
			local wave = r.pulse and P.flash(now, r.pulse + (config.calm and 0 or (i - 1) * .075), config.calm) or 0
			local idle = config.motion and .5 + .5 * math.sin(now * 1.1 - i * 1.05) or .5
			im.ImageTransparency = .28 - wave * .24 - idle * .09
			im.ImageColor3 = (i % 2 == 0 and V.violet or V.cyan):Lerp(V.white, wave * .75 + idle * .12)
			im.Rotation = (i - 1) * 60 + (config.motion and now * 1.7 + r.phase * 12 or 0)
		end
		r.inner.Rotation = config.motion and -now * 3.1 - r.phase * 14 or 0
		r.channels.Rotation = config.motion and now * .9 or 0
		r.inner.ImageTransparency = .23 - flash * .17 + (config.motion and math.sin(now * .77) * .06 or 0)
		r.channels.ImageTransparency = .24 - flash * .18 + (config.motion and math.sin(now * 1.13 + 1.8) * .06 or 0)
		for i, glyph in ipairs(r.runes) do
			local s = P.rune(now, i, config.motion, r.phase)
			glyph.part.Position = r.energy.WorldPosition + Vector3.new(s.x, s.y, s.z)
			glyph.image.Rotation = s.rotation
			glyph.image.ImageTransparency = math.max(.02, 1 - s.glow - flash * .2)
			glyph.image.ImageColor3 = (i % 2 == 0 and V.cyan or V.violet):Lerp(V.white, flash * .8)
		end
		for i, entry in ipairs(r.pages) do
			entry.part.CFrame = entry.frame * (config.motion and CFrame.new(0, math.sin(now * .8 + i) * .10, 0) * CFrame.Angles(0, 0, math.sin(now * .63 + i) * .04) or CFrame.identity)
		end
		if r.light then r.lightOrigin.WorldPosition = r.energy.WorldPosition; r.light.Brightness = .18 + flash * (config.calm and .3 or .65) end
		if r.core then r.core.WorldPosition = r.plane.Position + Vector3.new(0, .55, 0) end
		if r.orbits and now >= r.ambientAt then
			-- No catch-up loop after stalls: idle emissions stay bounded at every quality.
			r.ambientAt = now + config.ambientInterval
			for i = 1, 2 do pointEmitter(r, i, now * .28 + i * math.pi, false); emit(r.emitters[i], 1) end
			emit(r.emitters[3], 1); emit(r.emitters[4], 1)
		end
	end
	local function ritualStep(now)
		if not ritualBook or not ritual.started or not pool then return end
		local r, chest = records[ritualBook], chestPart()
		if not r or not chest or not valid(ritualBook) or ritualBook.Parent:GetAttribute("OwnerUserId") ~= player.UserId then clearPool(); return end
		local age = now - ritual.started
		if age >= P.seconds then cancel(); return end
		local origin, target = r.energy.WorldPosition, chest.Position
		if r.light and not config.calm then
			local absorb = P.flash(age, 1.03, false)
			r.lightOrigin.WorldPosition = age < .8 and origin or target
			r.light.Brightness += absorb * .9
		end
		if r.orbits then
			local due = P.sectorsDue(age)
			for sector = pool.sector + 1, due do
				local index = sector % 2 + 1
				pointEmitter(r, index, (sector - 1) * math.pi / 3 + math.rad(now * 1.7 + r.phase * 12), true)
				local count = P.sectorCount(config.sparks, sector); emit(r.emitters[index], count); stats.bursts += count
			end
			pool.sector = due
			if not pool.surged and age >= .12 then pool.surged = true; emit(r.emitters[3], 2); emit(r.emitters[4], 3) end
		end
		for i, page in ipairs(pool.pages) do
			local s = P.page(age, i)
			local cf = CFrame.new(origin + Vector3.new(s.x, s.y, s.z)) * CFrame.Angles(s.pitch, s.yaw, s.roll)
			local frame = P.burnFrame(s.burn)
			for _, panel in ipairs(page.panels) do
				local sign = panel.side == 0 and -1 or 1
				panel.part.Size = Vector3.new(.38, .88, .01) * s.scale
				panel.part.CFrame = cf * CFrame.Angles(0, sign * s.fold, 0) * CFrame.new(sign * .19 * s.scale, 0, 0)
				local x, y = P.pageRect(frame, panel.side, false)
				for _, im in ipairs(panel.images) do im.ImageRectOffset = Vector2.new(x, y); im.ImageTransparency = 1 - s.alpha end
				for _, im in ipairs(panel.edges) do im.ImageRectOffset = Vector2.new(x, y + 512); im.ImageTransparency = 1 - s.alpha * (.88 + .12 * math.sin(age * 8 + i)) end
			end
		end
		for i, stream in ipairs(pool.streams) do
			local head = (age - .2 - (i - 1) * .07) / .85
			local opacity = P.smooth(head / .15) * (1 - P.smooth((head - 1) / .18))
			local points = {}
			for j = 1, 4 do
				local p = P.soul(math.clamp(head - (4 - j) * .085, 0, 1), i)
				points[j] = origin:Lerp(target, p.blend) + Vector3.new(p.x, p.y, p.z)
			end
			for j = 1, 4 do
				local tangent = points[math.min(4, j + 1)] - points[math.max(1, j - 1)]
				local x = tangent.Magnitude > .001 and tangent.Unit or Vector3.xAxis
				local z = x:Cross(math.abs(x.Y) < .95 and Vector3.yAxis or Vector3.zAxis).Unit
				stream.nodes[j].WorldCFrame = CFrame.fromMatrix(points[j], x, z:Cross(x), z)
			end
			for k, beam in ipairs(stream.beams) do
				local j = math.ceil(k / 2); local length = (points[j + 1] - points[j]).Magnitude
				beam.Enabled = opacity > .01 and length > .003; beam.CurveSize0 = length / 3; beam.CurveSize1 = length / 3
				beam.Transparency = NumberSequence.new(1 - opacity * (k % 2 == 1 and .75 or 1))
			end
		end
		if pool.ash then
			pool.ash.WorldPosition = origin + Vector3.new(0, 1.2, 0); pool.chest.WorldPosition = target
			if age > .75 and not pool.burned then pool.burned = true; emit(pool.emitters[1], config.pages == 22 and 6 or 3) end
			if age > 1.03 and not pool.absorbed then pool.absorbed = true; emit(pool.emitters[2], config.streams == 3 and 6 or 3) end
		end
	end
	local self = {}
	function self.attach(model)
		if stopped or tracked[model] then return end
		local count = 0; for _ in pairs(tracked) do count += 1 end
		if count < P.maxTracked then tracked[model] = true end
	end
	function self.detach(model) tracked[model] = nil; remove(model) end
	function self.stats()
		local books, count, lights, emitters = 0, 0, 0, pool and #pool.emitters or 0
		for _, r in pairs(records) do books += 1; lights += r.light and 1 or 0; emitters += #r.emitters end
		for _ in pairs(tracked) do count += 1 end
		local instances = #folder:GetDescendants(); stats.peakInstances = math.max(stats.peakInstances, instances)
		return {mode = "soul", tracked = count, active = books, sheets = pool and #pool.pages or 0,
			beams = pool and #pool.streams * 6 or 0, runes = books * config.runes, lights = lights, emitters = emitters,
			instances = instances, peakInstances = stats.peakInstances, feedback = ritual.confirmed, batches = ritual.batches,
			activeRitual = ritual.started ~= nil, emitted = stats.emitted, sigilSparks = stats.bursts,
			errors = stats.errors, updates = stats.updates, averageMs = stats.totalMs / math.max(1, stats.updates), maxMs = stats.maxMs, connections = #connections}
	end
	function self.stop()
		if stopped then return end; stopped = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		clearVisuals(); table.clear(tracked); folder:Destroy()
	end
	table.insert(connections, player.CharacterRemoving:Connect(clearVisuals))
	table.insert(connections, game.ReplicatedStorage.PotionTycoon.Remotes.State.OnClientEvent:Connect(function(snapshot)
		local owned = player:GetAttribute("PotionPlotIndex")
		local confirmed; cursor, confirmed = Feedback.consume(cursor, snapshot.presentation and snapshot.presentation.essenceClick, owned)
		if not confirmed or snapshot.writable ~= true or not chestPart() then return end
		for model, r in pairs(records) do
			if valid(model) and model:GetAttribute("PlotIndex") == owned and model.Parent:GetAttribute("OwnerUserId") == player.UserId then
				local ok, err = pcall(function()
					local fresh = ritual.trigger(time); ritualBook = model; r.pulse = time
					if fresh then
						if not pool then pool = V.pool(folder, config); V.populate(pool, config) end
						hideRitual(); pool.sector = 0; pool.surged = false; pool.burned = false; pool.absorbed = false
					end
					model:SetAttribute("AG67BConfirmedFeedback", ritual.confirmed)
				end)
				if not ok then stats.errors += 1; clearVisuals(); warn("[AG67B] Ritual removed: " .. tostring(err)) end
				break
			end
		end
	end))
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		time += dt; elapsed += dt
		local nextSignature = Controller.quality .. tostring(Controller.reduceMotion)
		if signature ~= nextSignature then
			signature = nextSignature; clearVisuals(); config = P.quality(Controller.quality, Controller.reduceMotion); elapsed = 1
		end
		if lastCharacter ~= player.Character or not chestPart() then clearVisuals(); lastCharacter = player.Character end
		if elapsed < 1 / config.hz then return end
		local step = math.min(elapsed, .1); elapsed = 0; local started = os.clock()
		debug.profilebegin("AG67B Soul presentation")
		local ok, err = pcall(function()
			if not chestPart() then return end
			local camera, candidates = workspace.CurrentCamera, {}
			for model in pairs(tracked) do
				if valid(model) and camera then
					local distance = (camera.CFrame.Position - model:GetPivot().Position).Magnitude
					if distance <= config.range then table.insert(candidates, {model = model, distance = distance, owned = model.Parent:GetAttribute("OwnerUserId") == player.UserId}) end
				else remove(model) end
			end
			table.sort(candidates, function(a, b) if a.owned ~= b.owned then return a.owned end; return a.distance < b.distance end)
			local active = {}
			for i = 1, math.min(config.books, #candidates) do active[candidates[i].model] = candidates[i] end
			for model, r in pairs(records) do if not active[model] or r.owned ~= active[model].owned then remove(model) end end
			for model, candidate in pairs(active) do
				if not records[model] then add(model, candidate.owned) end
				if records[model] then ambient(records[model], time, step) end
			end
			ritualStep(time)
		end)
		if not ok then stats.errors += 1; clearVisuals(); table.clear(tracked); warn("[AG67B] Visuals removed: " .. tostring(err)) end
		debug.profileend()
		local ms = (os.clock() - started) * 1000; stats.updates += 1; stats.totalMs += ms; stats.maxMs = math.max(stats.maxMs, ms)
	end))
	return self
end
return View
