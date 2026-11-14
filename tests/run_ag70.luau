--!strict
local Test=require("./Test")
require("./arcane_forest.spec")(Test)
require("./path_surface.spec")(Test)
Test.finish()
