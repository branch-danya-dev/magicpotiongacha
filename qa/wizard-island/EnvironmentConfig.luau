--!nonstrict
-- QA-only configuration. The production module and EnvironmentView are unchanged.
local function copy(t)
	local r={}; for k,v in pairs(t) do r[k]=type(v)=="table" and copy(v) or v end; return r
end
local C=copy(require(script.Parent.EnvironmentBase))
C.celestial.moonSize=22
for _,q in pairs(C.quality) do q.fog=0 end
for _,k in ipairs(C.keys) do
	local n=k.night
	k.ambient={66+13*n,82+13*n,91+31*n}
	k.outdoor={120-20*n,137-17*n,134+23*n}
	k.tint={255,250,243}; k.exposure=.05+.12*n
	k.brightness=2.4-.25*n; k.density=.22-.065*n; k.haze=.35-.16*n
end
-- A sun still above the horizon makes actual shadows, then readable blue moonlight.
C.keys[2].clock=17.6; C.keys[2].sun={246,193,148}
C.keys[2].ambient={95,112,131};C.keys[2].outdoor={123,136,151};C.keys[2].brightness=2.7;C.keys[2].exposure=.18
C.keys[2].density=.16;C.keys[2].sky={166,182,201};C.keys[2].decay={117,103,139}
C.keys[3].clock=18.2; C.keys[3].sun={249,172,136}
C.keys[4].clock=0; C.keys[4].sun={175,201,255}
C.keys[4].ambient={147,166,192};C.keys[4].outdoor={162,182,211};C.keys[4].density=.10
C.keys[4].brightness=2.6;C.keys[4].exposure=.38
C.poses.dusk={phase=.30,rain=0,cloud=.12}
C.poses.night={phase=.51,rain=0,cloud=.08}
return C
