--!nonstrict
-- One owner at a time. Ordinary Studio builds opt in; published clients stay OFF.
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local Shared = game.ReplicatedStorage.PotionTycoon.Shared
local Policy = require(Shared.SpellbookSoulPolicy)
local Assets = require(Shared.SpellbookSoulAssets)
local Gate = require(Shared.SpellbookSoulGate)
local Legacy = require(script.Parent.LegacySpellbookEffects)
local Controller = require(script.Parent.EnvironmentController)
local Effects = {current = nil}
function Effects.start()
	if Effects.current then return Effects.current end
	local studio = RunService:IsStudio()
	if not Policy.enabled(studio, nil) then return Legacy.start() end
	local models, connections, probes = {}, {}, {}
	local gate, owner, mode, bridge = Gate.new(), nil, nil, nil
	local self = {}
	local function clearProbes()
		for _, probe in ipairs(probes) do probe:Destroy() end
		table.clear(probes)
	end
	local function switch()
		if gate.stopped then return end
		local wanted = Policy.enabled(studio, workspace:GetAttribute("SpellbookSoulEnabled"))
			and gate.status == "ready" and workspace:GetAttribute("AG67BForceFallback") ~= true
		local nextMode = wanted and "soul" or "original"
		if nextMode == mode then return end
		if owner then owner.stop(); owner = nil end
		mode = nextMode
		owner = wanted and require(script.Parent.SpellbookSoul.View).start() or Legacy.start()
		for model in pairs(models) do owner.attach(model) end
	end
	function self.attach(model)
		if models[model] then return end
		local count = 0; for _ in pairs(models) do count += 1 end
		if count >= Policy.maxTracked then return end
		models[model] = true; owner.attach(model)
	end
	function self.detach(model) models[model] = nil; if owner then owner.detach(model) end end
	function self.stats()
		local result = owner and owner.stats() or {}
		result.mode = mode; result.content = gate.status; result.releaseEnabled = Policy.releaseEnabled
		return result
	end
	function self.stop()
		if gate.stopped then return end
		gate.stop()
		clearProbes()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		if bridge then bridge:Destroy() end
		if owner then owner.stop(); owner = nil end
		table.clear(models)
		if Effects.current == self then Effects.current = nil end
	end
	Effects.current = self
	switch()
	table.insert(connections, workspace:GetAttributeChangedSignal("SpellbookSoulEnabled"):Connect(switch))
	if studio then
		table.insert(connections, workspace:GetAttributeChangedSignal("AG67BForceFallback"):Connect(switch))
		bridge = Instance.new("BindableFunction"); bridge.Name = "Inspect"
		bridge.OnInvoke = function(command, value)
			if command == "mode" then workspace:SetAttribute("SpellbookSoulEnabled", value ~= "original"); switch()
			elseif command == "quality" then Controller.setQuality(value)
			elseif command == "motion" then Controller.setReduceMotion(value)
			elseif command == "fallback" then workspace:SetAttribute("AG67BForceFallback", value == true); switch() end
			return self.stats(), Controller.quality, Controller.reduceMotion
		end
		bridge.Parent = script
	end
	-- Only one bounded preload job, independent of clicks and quality switches.
	task.spawn(function()
		local count, failed = 0, false
		local ok = pcall(function()
			if gate.stopped then return end
			-- Typed image probes select Roblox's texture loader. Bare asset strings
			-- can fail the generic content route even when the image is permitted.
			for _, id in ipairs({Assets.sigil, Assets.pages, Assets.wisp}) do
				local probe = Instance.new("ImageLabel"); probe.Image = id; table.insert(probes, probe)
			end
			ContentProvider:PreloadAsync(probes, function(_, status)
				count += 1
				if status ~= Enum.AssetFetchStatus.Success then failed = true end
			end)
		end)
		clearProbes()
		if gate.finish(ok and not failed and count == 3) then switch() end
	end)
	task.delay(Policy.preloadSeconds, function()
		if gate.finish(false) then clearProbes(); switch() end
	end)
	return self
end
return Effects
