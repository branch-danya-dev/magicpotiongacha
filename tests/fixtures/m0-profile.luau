-- Captured/validated with Factory from PR #3 a72ef9e; prepared regression fixture, not player data.
return {
	["discoveredRecipes"] = {
		["healing"] = true,
	},
	["entitlements"] = {
	},
	["essence"] = 118,
	["gold"] = 760,
	["inventory"] = {
	},
	["lastSimulatedAt"] = 100023,
	["manualReadyAt"] = {
		["garden"] = 100000,
		["mine"] = 100000,
	},
	["nextPetSerial"] = 1,
	["order"] = {
		["acceptedAt"] = 100000,
		["count"] = 5,
		["expiresAt"] = 100600,
		["id"] = "healing_small",
		["itemId"] = "healing",
		["recipeId"] = "healing",
		["rewardGold"] = 110,
	},
	["pets"] = {
		["123:starter_brewer"] = {
			["id"] = "123:starter_brewer",
			["name"] = "Magic cat",
			["paidOrigin"] = false,
			["species"] = "brewer",
			["stats"] = {
				["Brewing"] = 25,
				["Farming"] = 3,
				["Hauling"] = 2,
			},
		},
		["123:starter_farmer"] = {
			["id"] = "123:starter_farmer",
			["name"] = "Sprout owl",
			["paidOrigin"] = false,
			["species"] = "farmer",
			["stats"] = {
				["Brewing"] = 2,
				["Farming"] = 12,
				["Hauling"] = 2,
			},
		},
		["123:starter_slime"] = {
			["id"] = "123:starter_slime",
			["name"] = "Green slime",
			["paidOrigin"] = false,
			["species"] = "slime",
			["stats"] = {
				["Brewing"] = 1,
				["Farming"] = 2,
				["Hauling"] = 10,
			},
		},
	},
	["pipes"] = false,
	["questStock"] = {
		["healing"] = 2,
	},
	["rebirths"] = 0,
	["receipts"] = {
	},
	["rngState"] = 124,
	["schemaVersion"] = 1,
	["slimeWorkSeconds"] = {
		["123:starter_slime"] = 23,
	},
	["stations"] = {
		["cauldron"] = {
			["auto"] = true,
			["input"] = {
				["mandrake"] = 1,
			},
			["level"] = 1,
			["output"] = {
			},
			["progress"] = 0,
			["recipeId"] = "healing",
			["workerId"] = "123:starter_brewer",
		},
		["crystal"] = {
			["auto"] = false,
			["input"] = {
			},
			["level"] = 2,
			["output"] = {
			},
			["progress"] = 0,
		},
		["distillery"] = {
			["auto"] = false,
			["input"] = {
			},
			["job"] = {
				["doubleChance"] = 0,
				["duration"] = 8,
				["kind"] = "brew",
				["recipeId"] = "fire_extract",
			},
			["level"] = 1,
			["output"] = {
			},
			["progress"] = 0,
			["recipeId"] = "fire_extract",
		},
		["garden"] = {
			["auto"] = false,
			["input"] = {
			},
			["level"] = 1,
			["output"] = {
				["mandrake"] = 1,
			},
			["progress"] = 5,
			["workerId"] = "123:starter_farmer",
		},
		["logistics"] = {
			["auto"] = false,
			["input"] = {
			},
			["job"] = {
				["amount"] = 2,
				["destinationKind"] = "inventory",
				["duration"] = 3.2,
				["itemId"] = "fire_extract",
				["kind"] = "haul",
				["sourceKind"] = "output",
				["sourceStationId"] = "distillery",
			},
			["level"] = 1,
			["output"] = {
			},
			["progress"] = 1,
			["routeCursor"] = 3,
			["workerId"] = "123:starter_slime",
		},
		["mine"] = {
			["auto"] = false,
			["input"] = {
			},
			["level"] = 0,
			["output"] = {
			},
			["progress"] = 0,
		},
	},
	["tutorialGranted"] = true,
	["userId"] = 123,
	["warehouseLevel"] = 0,
}
