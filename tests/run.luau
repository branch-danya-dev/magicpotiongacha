--!strict
local Test = require("./Test")
local selected = ...

assert(selected == nil or selected == "protocol" or selected == "profile_store" or selected == "factory" or selected == "acceptance" or selected == "m1" or selected == "m2" or selected == "m3" or selected == "m4" or selected == "m5" or selected == "m6" or selected == "m7", "Unknown test suite")

if selected == nil or selected == "protocol" then
	require("./protocol.spec")(Test)
end
if selected == nil or selected == "profile_store" then
	require("./profile_store.spec")(Test)
end
if selected == nil or selected == "factory" then
	require("./factory.spec")(Test)
end
if selected == nil or selected == "acceptance" then
	require("./acceptance.spec")(Test)
end

if selected == nil or selected == "m1" then
	require("./m1.spec")(Test)
	require("./migration.spec")(Test)
end

if selected == nil or selected == "m2" then
	require("./collection.spec")(Test)
	require("./policy.spec")(Test)
	require("./collection_store.spec")(Test)
	require("./m2.spec")(Test)
end

if selected == nil or selected == "m3" then
	require("./m3_progression.spec")(Test)
	require("./m3_factory.spec")(Test)
	require("./m3_store.spec")(Test)
	require("./m3_acceptance.spec")(Test)
end

if selected == nil or selected == "m4" then
	require("./trade_durable.spec")(Test)
	require("./trade_model.spec")(Test)
	require("./trade_session.spec")(Test)
	require("./trade_migration.spec")(Test)
end

if selected==nil or selected=="m5" then
	require("./m5_model.spec")(Test)
	require("./m5_daily.spec")(Test)
	require("./m5_store.spec")(Test)
	require("./m5_trade.spec")(Test)
	require("./m5_ui.spec")(Test)
	require("./m5_acceptance.spec")(Test)
end
if selected==nil or selected=="m6" then
	require("./m6_receipt.spec")(Test)
	require("./m6_model.spec")(Test)
	require("./m6_interop.spec")(Test)
	require("./m6_acceptance.spec")(Test)
	require("./m6_ui.spec")(Test)
end
if selected==nil or selected=="m7" then
	require("./environment.spec")(Test)
	require("./context_ui.spec")(Test)
	require("./safety18a.spec")(Test)
	require("./island19a.spec")(Test)
	require("./farm19b.spec")(Test)
	require("./meadow19c.spec")(Test)
	require("./forest19d.spec")(Test)
	require("./atmosphere19e.spec")(Test)
	require("./props19f.spec")(Test)
end
Test.finish()
