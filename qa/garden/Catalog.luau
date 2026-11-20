--!nonstrict
-- V1-02 Studio-only crop registry. New species require configuration, not a new simulator.
-- Prices and durations are provisional for gameplay QA, NOT approved release balance.
return {
 beds = {"legacy:garden", "garden:2", "garden:3"},
 bedPrices = {0, 400, 950},
 sprinklerCost = 300,
 crops = {
  mandrake = {
   name = "Мандрагора", growthSeconds = 90, wateringAt = {0},
   harvestSeconds = 2, yieldAmount = 2, seedCost = 20, requiredGardenLevel = 1,
   stages = {0.15, 0.7, 1},
  },
  antarctic_biter = {
   name = "Антарктическая кусака", growthSeconds = 250, wateringAt = {0, 125},
   harvestSeconds = 5, yieldAmount = 3, seedCost = 45, requiredGardenLevel = 1,
   stages = {0.15, 0.5, 0.8, 1},
  },
 }
}
