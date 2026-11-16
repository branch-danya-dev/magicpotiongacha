--!nonstrict
-- Cosmetic two-track driver. Injected tracks/RNG/clock permit race/lifecycle tests.
local Idle = {}
Idle.Fade = 0.3
local function finite(n) return type(n) == "number" and n == n and math.abs(n) < math.huge end
function Idle.calmProbability(weights)
	if type(weights) ~= "table" then return 0.5 end
	local a, b = weights[1], weights[2]
	if not finite(a) or not finite(b) or a < 0 or b < 0 or a + b <= 0 or not finite(a + b) then return 0.5 end
	return a / (a + b)
end
function Idle.new(tracks, random, clock, weights)
	assert(#tracks == 2, "Exactly two preloaded tracks required")
	local self = { current = nil, disposed = false, running = false, connections = {}, transitions = {}, selections = 0 }
	local probability = Idle.calmProbability(weights)
	local eligibleAt = math.huge
	local function choose() return random() < probability and 1 or 2 end
	local function start(index, phase)
		self.current = index
		local track = tracks[index]
		track.Looped = true
		track:Play(Idle.Fade, 1, 1)
		track.TimePosition = phase * track.Length
		-- A randomized initial partial cycle is not a completed full cycle.
		eligibleAt = clock() + track.Length - 0.02
	end
	for index, track in ipairs(tracks) do
		assert(finite(track.Length) and track.Length > Idle.Fade, "Track not loaded")
		self.connections[index] = track.DidLoop:Connect(function()
			if self.disposed or not self.running or self.current ~= index or clock() < eligibleAt then return end
			local nextIndex = choose()
			self.selections += 1
			local key = tostring(index) .. "-" .. tostring(nextIndex)
			self.transitions[key] = (self.transitions[key] or 0) + 1
			eligibleAt = clock() + tracks[nextIndex].Length - 0.02
			if nextIndex ~= index then
				self.current = nil -- Outgoing callbacks cannot select again during Stop.
				track:Stop(Idle.Fade)
				start(nextIndex, 0)
			end
		end)
	end
	function self.setIdle(enabled)
		if self.disposed or self.running == enabled then return end
		self.running = enabled
		if enabled then start(choose(), math.clamp(random(), 0, 0.99))
		else
			self.current = nil; eligibleAt = math.huge
			for _, track in ipairs(tracks) do track:Stop(0.15) end
		end
	end
	function self.destroy()
		if self.disposed then return end
		self.disposed = true; self.running = false; self.current = nil
		for _, connection in ipairs(self.connections) do connection:Disconnect() end
		table.clear(self.connections)
		for _, track in ipairs(tracks) do track:Stop(0); track:Destroy() end
	end
	return self
end
return Idle
