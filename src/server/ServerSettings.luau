--!strict
-- Never switch a published server to an in-memory fallback after a load failure.
return {
	TradingEnabled = false,
	TradingQAPlaceId = 0, -- Explicit private QA allowlist; Studio also requires TradingEnabled.
	TradeJournalName = "PotionTycoon_M4_trade_journal_v1",
	UseMemoryInStudio = true,
	DataStoreName = "PotionTycoon_M0_dev_v1",
	PlotCount = 8,
	AutosaveSeconds = 30,
	LeaseSeconds = 120,
	InteractDistance = 24,
}
