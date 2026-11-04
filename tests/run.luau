--!strict
local Test = require("./Test")
local selected = ...

assert(selected == nil or selected == "protocol" or selected == "profile_store" or selected == "factory" or selected == "acceptance" or selected == "m1", "Unknown test suite")

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

Test.finish()
