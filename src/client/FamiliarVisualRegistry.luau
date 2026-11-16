--!nonstrict
-- AG74: asset references only. No grants, stats, server RNG or save data.
return {
	slime = {
		template = "GreenSlime",
		meshId = "rbxassetid://76181395589964",
		textureId = "rbxassetid://107809848451619",
		animations = {"rbxassetid://73712172546084", "rbxassetid://89284758082218"},
		lengths = {3.6, 3.0},
		weights = {0.5, 0.5},
		-- AG75: visible at the actual game camera distance; keep uniform rig scaling.
		scale = 1.65,
	},
}
