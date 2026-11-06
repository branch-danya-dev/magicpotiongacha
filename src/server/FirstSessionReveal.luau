--!nonstrict
-- Hides greybox stations the first cycle has not opened. Rewards stay in Factory.
local Shared = game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Guide = require(Shared.FirstSessionView)
local Reveal = {}

local function applyPhysical(part, policy, hidden)
	if not part then return end
	part:SetAttribute("FirstSessionHidden", hidden)
	part.CanCollide = policy.collide
	part.CanQuery = policy.query
	part.CanTouch = policy.touch
	if hidden then part.Transparency = 1 end
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Enabled = not hidden end
	local billboard = part:FindFirstChildOfClass("BillboardGui")
	if billboard then billboard.Enabled = not hidden end
end

function Reveal.apply(world, plot, profile)
	local config = world.config
	local _, done = Guide.step(profile, config)
	for id, anchor in pairs(plot.anchors) do
		local visible = Guide.stationVisible(profile, config, id)
		local station = profile.stations and profile.stations[id]
		local built = type(station) == "table" and (tonumber(station.level) or 0) > 0
		local kind = type(station) == "table" and "station" or "marker"
		applyPhysical(anchor, Guide.collision(kind, visible, built), not visible)
		local pad = plot.pads[id]
		local showPad = Guide.padVisible(profile, config, id)
		applyPhysical(pad, Guide.collision("pad", showPad, false), not showPad)
		if pad and showPad then pad.Transparency = 0 end
	end
	for _, module in ipairs(plot.architecture) do
		local policy = Guide.collision("marker", false, false)
		module.part.CanCollide = policy.collide
		module.part.CanQuery = false
		module.part.CanTouch = policy.touch
		if not done then module.part.Transparency = 1 end
	end
	local crystal = plot.anchors.crystal
	local prompt = crystal and crystal:FindFirstChildOfClass("ProximityPrompt")
	if prompt and type(profile.starter) == "table" and profile.starter.legacyGrant ~= true and config.economyV2 then
		prompt.ActionText = "+" .. tostring(config.economyV2.clickEssence) .. " Essence"
	end
end

return Reveal
