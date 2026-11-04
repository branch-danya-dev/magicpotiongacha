--!strict
local Test = require("./Test")
local selected = ...

assert(selected == nil or selected == "protocol" or selected == "profile_store" or selected == "factory" or selected == "acceptance" or selected == "m1" or selected == "m2" or selected == "m3", "Unknown test suite")

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

Test.finish()
