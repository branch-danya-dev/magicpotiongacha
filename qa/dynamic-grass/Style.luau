--!nonstrict
-- Lighting, clouds, weather and palette remain the R3 implementation verbatim.
local Style=table.clone(require(script.Parent.RomanticAtmosphereStyle))
Style.wind=require(script.Parent.GrassWind).sample
return Style
