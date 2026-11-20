--!nonstrict
-- Studio-only policy: no save-schema, purchase or client-authoritative changes.
local Policy = {}
function Policy.active(config, profile)
 return type(config)=="table" and config.alchemyFirstQA==true
  and type(profile)=="table" and type(profile.starter)=="table"
  and profile.starter.legacyGrant~=true
end
function Policy.received(profile, gain)
 if gain>0 and profile.starter.claimed==true then
  profile.tutorial.crystal=true
  profile.tutorial.essence=true
 end
end
return Policy
