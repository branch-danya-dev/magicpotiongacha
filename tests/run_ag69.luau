--!strict
local Test=require("./Test")
require("./environment_assets.spec")(Test)
require("./environment_celestial.spec")(Test)
Test.finish()
