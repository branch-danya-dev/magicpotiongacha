-- Captured and validated on M5 9da973f221ee162660184ae7da80953631c5b5b7, before V7 changes.
return {
	["journal"] = {
		["applied"] = {
		},
		["cleared"] = {
		},
		["coordinator"] = "server:A",
		["createdAt"] = 100000,
		["deadline"] = 100120,
		["decision"] = "COMMIT",
		["hash"] = "952981a48723c744242c03e7d50af6d6b29d7ea42fc72d140f74a97e0f1d1bf7",
		["id"] = "trade-uuid-1",
		["prepared"] = {
			["1"] = true,
			["2"] = true,
		},
		["schemaVersion"] = 1,
		["sides"] = {
			[1] = {
				["items"] = {
					[1] = {
						["data"] = {
							["evolution"] = 0,
							["id"] = "101:pet:1",
							["locked"] = false,
							["name"] = "Green slime",
							["paidOrigin"] = false,
							["provenance"] = {
								["paidDerived"] = false,
								["parents"] = {
								},
								["source"] = "shop",
								["tradeKnown"] = true,
							},
							["rarity"] = "Common",
							["species"] = "slime",
							["stats"] = {
								["Brewing"] = 1,
								["Farming"] = 2,
								["Hauling"] = 10,
							},
						},
						["id"] = "101:pet:1",
						["kind"] = "pet",
					},
				},
				["sequence"] = 1,
				["userId"] = 101,
			},
			[2] = {
				["items"] = {
					[1] = {
						["data"] = {
							["bonus"] = 0.05,
							["id"] = "202:cauldron:1",
							["locked"] = false,
							["ownerId"] = 202,
							["provenance"] = {
								["paidDerived"] = false,
								["source"] = "phase3",
							},
							["type"] = "resonant",
						},
						["id"] = "202:cauldron:1",
						["kind"] = "cauldron",
					},
				},
				["sequence"] = 1,
				["userId"] = 202,
			},
		},
		["state"] = "COMMIT",
		["version"] = 1,
	},
	["other"] = {
		["cauldrons"] = {
			["202:cauldron:1"] = {
				["bonus"] = 0.05,
				["id"] = "202:cauldron:1",
				["locked"] = false,
				["ownerId"] = 202,
				["provenance"] = {
					["paidDerived"] = false,
					["source"] = "phase3",
				},
				["type"] = "resonant",
			},
		},
		["collection"] = {
			["sequence"] = 0,
		},
		["currencyPaid"] = {
			["essence"] = false,
			["gold"] = false,
		},
		["discoveredRecipes"] = {
		},
		["entitlements"] = {
		},
		["essence"] = 0,
		["gold"] = 0,
		["inputCursors"] = {
		},
		["inventory"] = {
		},
		["lastSimulatedAt"] = 100000,
		["longTerm"] = {
			["calendar"] = {
				["delivered"] = false,
				["lastDay"] = -1,
				["pendingPet"] = false,
				["series"] = 0,
				["step"] = 0,
				["uniqueAwarded"] = false,
			},
			["cycle"] = {
				["finalProduced"] = false,
				["id"] = 0,
			},
			["daily"] = {
				["claimed"] = {
				},
				["day"] = -1,
				["progress"] = {
					["brew"] = 0,
					["essence"] = 0,
					["orders"] = 0,
				},
			},
			["earned"] = 0,
			["milestoneClaimed"] = true,
			["perks"] = {
				["essence"] = 0,
				["industry"] = 0,
				["title"] = 0,
			},
			["sequence"] = 0,
			["shards"] = 0,
			["shardsPaid"] = false,
			["spent"] = 0,
		},
		["manualReadyAt"] = {
			["berries"] = 100000,
			["garden"] = 100000,
			["garden2"] = 100000,
			["mine"] = 100000,
			["mushrooms"] = 100000,
		},
		["nextCauldronSerial"] = 2,
		["nextPetSerial"] = 3,
		["pets"] = {
			["202:pet:1"] = {
				["evolution"] = 0,
				["id"] = "202:pet:1",
				["locked"] = false,
				["name"] = "Green slime",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "shop",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "slime",
				["stats"] = {
					["Brewing"] = 1,
					["Farming"] = 2,
					["Hauling"] = 10,
				},
			},
			["202:pet:2"] = {
				["evolution"] = 0,
				["id"] = "202:pet:2",
				["locked"] = false,
				["name"] = "Magic cat",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "shop",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "brewer",
				["stats"] = {
					["Brewing"] = 25,
					["Farming"] = 3,
					["Hauling"] = 2,
				},
			},
			["202:starter_brewer"] = {
				["evolution"] = 0,
				["id"] = "202:starter_brewer",
				["locked"] = false,
				["name"] = "Magic cat",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "brewer",
				["stats"] = {
					["Brewing"] = 25,
					["Farming"] = 3,
					["Hauling"] = 2,
				},
			},
			["202:starter_farmer"] = {
				["evolution"] = 0,
				["id"] = "202:starter_farmer",
				["locked"] = false,
				["name"] = "Sprout owl",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "farmer",
				["stats"] = {
					["Brewing"] = 2,
					["Farming"] = 12,
					["Hauling"] = 2,
				},
			},
			["202:starter_slime"] = {
				["evolution"] = 0,
				["id"] = "202:starter_slime",
				["locked"] = false,
				["name"] = "Green slime",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "slime",
				["stats"] = {
					["Brewing"] = 1,
					["Farming"] = 2,
					["Hauling"] = 10,
				},
			},
		},
		["phase"] = 1,
		["pipeCursor"] = 1,
		["pipes"] = false,
		["progression"] = {
			["sequence"] = 0,
		},
		["questStock"] = {
		},
		["rebirths"] = 0,
		["receipts"] = {
		},
		["rngState"] = 203,
		["schemaVersion"] = 6,
		["slimeWorkSeconds"] = {
		},
		["stations"] = {
			["berries"] = {
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
			["cauldron"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
				["recipeId"] = "healing",
			},
			["cauldron2"] = {
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
			["centrifuge"] = {
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
			["crystal"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
			},
			["distillery"] = {
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
			["distillery2"] = {
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
			["garden"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
			},
			["garden2"] = {
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
			["logistics"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
				["routeCursor"] = 1,
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
			["mushrooms"] = {
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
			["press"] = {
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
			},
			["stalls"] = {
			},
		},
		["trade"] = {
			["pending"] = {
				["hash"] = "952981a48723c744242c03e7d50af6d6b29d7ea42fc72d140f74a97e0f1d1bf7",
				["id"] = "trade-uuid-1",
				["sequence"] = 1,
				["stage"] = "prepared",
			},
			["sequence"] = 1,
		},
		["tutorial"] = {
		},
		["tutorialGranted"] = true,
		["userId"] = 202,
		["warehouseLevel"] = 0,
	},
	["pending"] = {
		["cauldrons"] = {
			["101:cauldron:1"] = {
				["bonus"] = 0.05,
				["id"] = "101:cauldron:1",
				["locked"] = false,
				["ownerId"] = 101,
				["provenance"] = {
					["paidDerived"] = false,
					["source"] = "phase3",
				},
				["type"] = "resonant",
			},
		},
		["collection"] = {
			["sequence"] = 0,
		},
		["currencyPaid"] = {
			["essence"] = false,
			["gold"] = false,
		},
		["discoveredRecipes"] = {
		},
		["entitlements"] = {
		},
		["essence"] = 0,
		["gold"] = 0,
		["inputCursors"] = {
		},
		["inventory"] = {
		},
		["lastSimulatedAt"] = 100000,
		["longTerm"] = {
			["calendar"] = {
				["delivered"] = false,
				["lastDay"] = -1,
				["pendingPet"] = false,
				["series"] = 0,
				["step"] = 0,
				["uniqueAwarded"] = false,
			},
			["cycle"] = {
				["finalProduced"] = false,
				["id"] = 0,
			},
			["daily"] = {
				["claimed"] = {
				},
				["day"] = -1,
				["progress"] = {
					["brew"] = 0,
					["essence"] = 0,
					["orders"] = 0,
				},
			},
			["earned"] = 0,
			["milestoneClaimed"] = true,
			["perks"] = {
				["essence"] = 0,
				["industry"] = 0,
				["title"] = 0,
			},
			["sequence"] = 0,
			["shards"] = 0,
			["shardsPaid"] = false,
			["spent"] = 0,
		},
		["manualReadyAt"] = {
			["berries"] = 100000,
			["garden"] = 100000,
			["garden2"] = 100000,
			["mine"] = 100000,
			["mushrooms"] = 100000,
		},
		["nextCauldronSerial"] = 2,
		["nextPetSerial"] = 3,
		["pets"] = {
			["101:pet:1"] = {
				["evolution"] = 0,
				["id"] = "101:pet:1",
				["locked"] = false,
				["name"] = "Green slime",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "shop",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "slime",
				["stats"] = {
					["Brewing"] = 1,
					["Farming"] = 2,
					["Hauling"] = 10,
				},
			},
			["101:pet:2"] = {
				["evolution"] = 0,
				["id"] = "101:pet:2",
				["locked"] = false,
				["name"] = "Magic cat",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "shop",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "brewer",
				["stats"] = {
					["Brewing"] = 25,
					["Farming"] = 3,
					["Hauling"] = 2,
				},
			},
			["101:starter_brewer"] = {
				["evolution"] = 0,
				["id"] = "101:starter_brewer",
				["locked"] = false,
				["name"] = "Magic cat",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "brewer",
				["stats"] = {
					["Brewing"] = 25,
					["Farming"] = 3,
					["Hauling"] = 2,
				},
			},
			["101:starter_farmer"] = {
				["evolution"] = 0,
				["id"] = "101:starter_farmer",
				["locked"] = false,
				["name"] = "Sprout owl",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "farmer",
				["stats"] = {
					["Brewing"] = 2,
					["Farming"] = 12,
					["Hauling"] = 2,
				},
			},
			["101:starter_slime"] = {
				["evolution"] = 0,
				["id"] = "101:starter_slime",
				["locked"] = false,
				["name"] = "Green slime",
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "slime",
				["stats"] = {
					["Brewing"] = 1,
					["Farming"] = 2,
					["Hauling"] = 10,
				},
			},
		},
		["phase"] = 1,
		["pipeCursor"] = 1,
		["pipes"] = false,
		["progression"] = {
			["sequence"] = 0,
		},
		["questStock"] = {
		},
		["rebirths"] = 0,
		["receipts"] = {
		},
		["rngState"] = 102,
		["schemaVersion"] = 6,
		["slimeWorkSeconds"] = {
		},
		["stations"] = {
			["berries"] = {
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
			["cauldron"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
				["recipeId"] = "healing",
			},
			["cauldron2"] = {
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
			["centrifuge"] = {
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
			["crystal"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
			},
			["distillery"] = {
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
			["distillery2"] = {
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
			["garden"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
			},
			["garden2"] = {
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
			["logistics"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
				["routeCursor"] = 1,
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
			["mushrooms"] = {
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
			["press"] = {
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
			},
			["stalls"] = {
			},
		},
		["trade"] = {
			["pending"] = {
				["hash"] = "952981a48723c744242c03e7d50af6d6b29d7ea42fc72d140f74a97e0f1d1bf7",
				["id"] = "trade-uuid-1",
				["sequence"] = 1,
				["stage"] = "prepared",
			},
			["sequence"] = 1,
		},
		["tutorial"] = {
		},
		["tutorialGranted"] = true,
		["userId"] = 101,
		["warehouseLevel"] = 0,
	},
	["progressed"] = {
		["cauldrons"] = {
			["123:cauldron:1"] = {
				["bonus"] = 0.05,
				["id"] = "123:cauldron:1",
				["locked"] = false,
				["ownerId"] = 123,
				["provenance"] = {
					["paidDerived"] = false,
					["source"] = "phase3",
				},
				["type"] = "resonant",
			},
		},
		["collection"] = {
			["sequence"] = 0,
		},
		["currencyPaid"] = {
			["essence"] = false,
			["gold"] = false,
		},
		["discoveredRecipes"] = {
			["ascension"] = true,
			["flare"] = true,
			["focus"] = true,
			["healing"] = true,
			["rage"] = true,
		},
		["entitlements"] = {
		},
		["essence"] = 0,
		["gold"] = 30,
		["inputCursors"] = {
		},
		["inventory"] = {
		},
		["lastSimulatedAt"] = 100033,
		["longTerm"] = {
			["calendar"] = {
				["delivered"] = false,
				["lastDay"] = 1,
				["pendingPet"] = false,
				["series"] = 0,
				["step"] = 1,
				["uniqueAwarded"] = false,
			},
			["cycle"] = {
				["finalProduced"] = false,
				["id"] = 1,
			},
			["daily"] = {
				["claimed"] = {
				},
				["day"] = 1,
				["progress"] = {
					["brew"] = 1,
					["essence"] = 0,
					["orders"] = 0,
				},
			},
			["earned"] = 1,
			["last"] = {
				["action"] = "claimCalendar",
				["fingerprint"] = "{s6:actions13:claimCalendars7:payload{s11:expectedDayd1;s9:requestIdd3;}}",
				["requestId"] = 3,
				["result"] = {
					["message"] = "Награда календаря: день 1",
				},
			},
			["milestoneClaimed"] = true,
			["perks"] = {
				["essence"] = 0,
				["industry"] = 1,
				["title"] = 0,
			},
			["sequence"] = 3,
			["shards"] = 0,
			["shardsPaid"] = false,
			["spent"] = 1,
		},
		["manualReadyAt"] = {
			["berries"] = 100033,
			["garden"] = 100033,
			["garden2"] = 100033,
			["mine"] = 100033,
			["mushrooms"] = 100033,
		},
		["nextCauldronSerial"] = 2,
		["nextPetSerial"] = 1,
		["pets"] = {
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
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
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
				["paidOrigin"] = false,
				["provenance"] = {
					["paidDerived"] = false,
					["parents"] = {
					},
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "farmer",
				["stats"] = {
					["Brewing"] = 2,
					["Farming"] = 12,
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
					["source"] = "starter",
					["tradeKnown"] = true,
				},
				["rarity"] = "Common",
				["species"] = "slime",
				["stats"] = {
					["Brewing"] = 1,
					["Farming"] = 2,
					["Hauling"] = 10,
				},
			},
		},
		["phase"] = 1,
		["pipeCursor"] = 1,
		["pipes"] = false,
		["progression"] = {
			["last"] = {
				["action"] = "advancePhase",
				["fingerprint"] = "advancePhase|expectedPhase=3|requestId=3",
				["requestId"] = 3,
				["result"] = {
					["message"] = "Opened Кибер-алхимический комплекс",
				},
			},
			["sequence"] = 3,
		},
		["questStock"] = {
		},
		["rebirths"] = 1,
		["receipts"] = {
		},
		["rngState"] = 1168281987,
		["schemaVersion"] = 6,
		["slimeWorkSeconds"] = {
		},
		["stations"] = {
			["berries"] = {
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
			["cauldron"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
				["recipeId"] = "healing",
			},
			["cauldron2"] = {
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
			["centrifuge"] = {
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
			["crystal"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
			},
			["distillery"] = {
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
			["distillery2"] = {
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
			["garden"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
			},
			["garden2"] = {
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
			["logistics"] = {
				["auto"] = false,
				["essence"] = 0,
				["input"] = {
				},
				["level"] = 1,
				["output"] = {
				},
				["progress"] = 0,
				["questQueue"] = {
				},
				["routeCursor"] = 1,
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
			["mushrooms"] = {
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
			["press"] = {
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
				["berries"] = {
					["unbuilt"] = 33,
				},
				["cauldron"] = {
					["no_hauler"] = 32,
					["waiting_essence"] = 1,
				},
				["cauldron2"] = {
					["manual_first"] = 3,
					["no_hauler"] = 11,
				},
				["centrifuge"] = {
					["unbuilt"] = 33,
				},
				["distillery"] = {
					["no_hauler"] = 31,
					["waiting_essence"] = 2,
				},
				["distillery2"] = {
					["no_hauler"] = 31,
					["waiting_essence"] = 2,
				},
				["garden"] = {
					["no_master"] = 33,
				},
				["garden2"] = {
					["unbuilt"] = 33,
				},
				["logistics"] = {
					["no_hauler"] = 33,
				},
				["mine"] = {
					["unbuilt"] = 33,
				},
				["mushrooms"] = {
					["unbuilt"] = 33,
				},
				["press"] = {
					["no_hauler"] = 32,
					["waiting_essence"] = 1,
				},
			},
		},
		["trade"] = {
			["sequence"] = 0,
		},
		["tutorial"] = {
			["pipes"] = true,
			["upgrade"] = true,
		},
		["tutorialGranted"] = true,
		["userId"] = 123,
		["warehouseLevel"] = 0,
	},
}
