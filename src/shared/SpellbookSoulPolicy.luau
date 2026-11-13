--!nonstrict
-- Deterministic presentation only. A batch consumes an already accepted receipt.
local P = {seconds = 2.4, maxTracked = 8, releaseEnabled = false, preloadSeconds = 15}
local tau = 2 * math.pi
function P.smooth(x)
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end
function P.enabled(studio, override)
	return (studio or P.releaseEnabled) and override ~= false
end
function P.quality(name, reduceMotion)
	local full, minimal = name == "full", name == "minimal"
	local calm = reduceMotion == true or minimal
	return {pages = calm and 0 or (full and 22 or 12), streams = calm and 0 or (full and 3 or 2),
		runes = full and 6 or minimal and 2 or 4, books = full and 2 or 1,
		range = full and 100 or minimal and 32 or 72, hz = full and 60 or minimal and 20 or 30,
		motion = not calm, calm = calm, sparks = calm and 0 or (full and 32 or 16),
		light = not minimal, ambientInterval = full and .45 or .9, ambient = not calm}
end
function P.new()
	local self = {started = nil, lastPulse = nil, confirmed = 0, batches = 0}
	function self.trigger(now)
		self.confirmed += 1
		self.lastPulse = now
		if self.started and now - self.started < P.seconds then return false end
		self.started = now
		self.batches += 1
		return true
	end
	function self.cancel() self.started = nil; self.lastPulse = nil end
	return self
end
function P.flash(now, last, calm)
	if not last then return 0 end
	local age = now - last
	if age < 0 then return 0 end
	return P.smooth(age / (calm and .18 or .04)) * math.exp(-age * (calm and 2.3 or 5))
end
function P.envelope(age)
	return P.smooth(age / .07) * (1 - P.smooth((age - 1.45) / .95))
end
function P.sectorCount(total, sector)
	return math.floor(total * sector / 6) - math.floor(total * (sector - 1) / 6)
end
function P.sectorsDue(age)
	return math.clamp(math.floor((age - .06) / .075) + 1, 0, 6)
end
function P.burnFrame(burn)
	return math.clamp(math.floor(burn * 7.999), 0, 7)
end
function P.pageRect(frame, side, edge)
	frame = math.clamp(math.floor(frame), 0, 7)
	return (frame % 4) * 256 + side * 128, math.floor(frame / 4) * 256 + (edge and 512 or 0)
end
function P.rune(t, index, motion, velocity)
	local phase = index * 2.39996323
	local a = phase + (motion and t * (.32 + .045 * (index % 3)) * (index % 2 == 0 and -1 or 1) + velocity * (.8 + .1 * index) or 0)
	local radius = 1.8 + (index % 3) * .32 + (motion and math.sin(t * .67 + phase) * .15 or 0)
	return {x = math.cos(a) * radius, z = math.sin(a) * radius,
		y = .5 + (index % 3) * .48 + (motion and math.sin(t * .9 + phase) * .23 or 0),
		rotation = motion and math.sin(t * .43 + phase) * 18 + t * (index % 2 == 0 and 4 or -5) or 0,
		glow = .77 + .12 * math.sin(t * .75 + phase)}
end
function P.page(age, index)
	local delay = .08 + (index % 6) * .045
	local u = math.clamp((age - delay) / 2.04, 0, 1)
	local a = index * 2.39996323
	local spin = a + u * (index % 3 == 0 and 5.8 or 2.3) * (index % 2 == 0 and 1 or -1)
	local radius = .2 + (1.2 + (index % 5) * .32) * P.smooth(u / .6)
	return {x = math.cos(spin) * radius, z = math.sin(spin) * radius,
		y = math.max(.2, .3 + (2.8 + (index % 4) * .48) * math.sin(u * math.pi * .89) - 1.7 * u),
		pitch = -.3 + u * (2.2 + index % 3) * .7, yaw = spin, roll = a + math.sin(u * 11 + index) * .5,
		fold = math.sin(u * 8 + index) * .36, burn = P.smooth((u - .22) / .68),
		alpha = age < delay and 0 or P.smooth(u / .055) * (1 - P.smooth((u - .85) / .15)),
		scale = 1 - .42 * P.smooth((u - .68) / .32)}
end
function P.soul(u, index)
	u = math.clamp(u, 0, 1)
	-- Reach the moving chest early, then wrap around it while the spiral contracts.
	local blend = P.smooth(math.min(1, u / .72))
	local a = index * tau / 3 + u * tau * 1.8
	local radius = math.sin(u * math.pi) * (1.2 + .24 * index)
	return {blend = blend, x = math.cos(a) * radius, z = math.sin(a) * radius,
		y = math.sin(u * math.pi) * .9 + math.sin(a) * radius * .35}
end
function P.chest(character)
	return character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"))
end
return P
