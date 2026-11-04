-- Captured/validated using M2 Factory/Config at PR #7 f9c34c8; prepared fixture, not player data.
return {
	["collection"] = {
		["last"] = {
			["action"] = "petLock",
			["at"] = 100031,
			["fingerprint"] = "petLock|locked=true|petId=123:pet:7|requestId=8",
			["requestId"] = 8,
			["result"] = {
				["consumedIds"] = {
				},
				["createdIds"] = {
				},
				["message"] = "Familiar locked",
			},
		},
		["sequence"] = 8,
	},
	["currencyPaid"] = {
		["essence"] = false,
		["gold"] = true,
	},
	["discoveredRecipes"] = {
		["healing"] = true,
	},
	["entitlements"] = {
	},
	["essence"] = 99950,
	["gold"] = 99400,
	["inventory"] = {
	},
	["lastSimulatedAt"] = 100023,
	["manualReadyAt"] = {
		["garden"] = 100000,
		["mine"] = 100000,
	},
	["nextPetSerial"] = 8,
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
		["123:pet:6"] = {
			["evolution"] = 1,
			["id"] = "123:pet:6",
			["locked"] = false,
			["name"] = "Golden slime",
			["paidOrigin"] = true,
			["provenance"] = {
				["paidDerived"] = true,
				["parents"] = {
					[1] = "123:pet:1",
					[2] = "123:pet:2",
					[3] = "123:pet:3",
					[4] = "123:pet:4",
					[5] = "123:pet:5",
				},
				["source"] = "fuse",
			},
			["rarity"] = "Rare",
			["species"] = "golden_slime",
			["stats"] = {
				["Brewing"] = 6,
				["Farming"] = 7,
				["Hauling"] = 15,
			},
		},
		["123:pet:7"] = {
			["evolution"] = 0,
			["id"] = "123:pet:7",
			["locked"] = true,
			["name"] = "Aether sprite",
			["paidOrigin"] = false,
			["provenance"] = {
				["paidDerived"] = false,
				["parents"] = {
				},
				["source"] = "gacha",
			},
			["rarity"] = "Secret",
			["species"] = "aether_sprite",
			["stats"] = {
				["Brewing"] = 100,
				["Farming"] = 100,
				["Hauling"] = 100,
			},
		},
		["123:starter_brewer"] = {
			["evolution"] = 0,
			["id"] = "123:starter_brewer",
			["locked"] = false,
			["name"] = "Magic cat",
			["paidOrigin"] = false,
			["provenance"] = {
				["paidDerived"] = false,
				["parents"] = {
				},
				["source"] = "legacy",
			},
			["rarity"] = "Legacy",
			["species"] = "brewer",
			["stats"] = {
				["Brewing"] = 25,
				["Farming"] = 3,
				["Hauling"] = 2,
			},
		},
		["123:starter_farmer"] = {
			["evolution"] = 0,
			["id"] = "123:starter_farmer",
			["locked"] = false,
			["name"] = "Sprout owl",
			["paidOrigin"] = true,
			["provenance"] = {
				["paidDerived"] = true,
				["parents"] = {
				},
				["source"] = "legacy",
			},
			["rarity"] = "Legacy",
			["species"] = "farmer",
			["stats"] = {
				["Brewing"] = 2,
				["Farming"] = 500,
				["Hauling"] = 2,
			},
		},
		["123:starter_slime"] = {
			["evolution"] = 0,
			["id"] = "123:starter_slime",
			["locked"] = false,
			["name"] = "Green slime",
			["paidOrigin"] = false,
			["provenance"] = {
				["paidDerived"] = false,
				["parents"] = {
				},
				["source"] = "legacy",
			},
			["rarity"] = "Legacy",
			["species"] = "slime",
			["stats"] = {
				["Brewing"] = 1,
				["Farming"] = 2,
				["Hauling"] = 10,
			},
		},
	},
	["pipeCursor"] = 1,
	["pipes"] = false,
	["questStock"] = {
		["healing"] = 2,
	},
	["rebirths"] = 0,
	["receipts"] = {
	},
	["rngState"] = 124,
	["schemaVersion"] = 3,
	["slimeWorkSeconds"] = {
		["123:starter_slime"] = 23,
	},
	["stations"] = {
		["cauldron"] = {
			["auto"] = true,
			["essence"] = 7,
			["input"] = {
				["mandrake"] = 1,
			},
			["level"] = 1,
			["output"] = {
			},
			["progress"] = 0,
			["questQueue"] = {
				["healing"] = 2,
			},
			["recipeId"] = "healing",
			["workerId"] = "123:starter_brewer",
		},
		["crystal"] = {
			["auto"] = false,
			["essence"] = 0,
			["input"] = {
			},
			["level"] = 2,
			["output"] = {
			},
			["progress"] = 0,
			["questQueue"] = {
			},
		},
		["distillery"] = {
			["auto"] = false,
			["essence"] = 9,
			["input"] = {
			},
			["job"] = {
				["automatic"] = false,
				["doubleChance"] = 0,
				["duration"] = 8,
				["kind"] = "brew",
				["recipeId"] = "fire_extract",
			},
			["level"] = 1,
			["output"] = {
			},
			["progress"] = 0,
			["questQueue"] = {
			},
			["recipeId"] = "fire_extract",
		},
		["garden"] = {
			["auto"] = false,
			["essence"] = 0,
			["input"] = {
			},
			["level"] = 1,
			["output"] = {
				["mandrake"] = 1,
			},
			["progress"] = 5,
			["questQueue"] = {
			},
			["workerId"] = "123:starter_farmer",
		},
		["logistics"] = {
			["auto"] = false,
			["essence"] = 0,
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
			["questQueue"] = {
			},
			["routeCursor"] = 3,
			["workerId"] = "123:pet:6",
		},
		["mine"] = {
			["auto"] = false,
			["essence"] = 0,
			["input"] = {
			},
			["level"] = 0,
			["output"] = {
			},
			["progress"] = 0,
			["questQueue"] = {
			},
		},
	},
	["telemetry"] = {
		["first"] = {
			["manual_brew"] = 100023,
		},
		["stalls"] = {
		},
	},
	["tutorial"] = {
		["manual"] = true,
		["orderAccepted"] = true,
		["upgrade"] = true,
	},
	["tutorialGranted"] = true,
	["userId"] = 123,
	["warehouseLevel"] = 0,
}
