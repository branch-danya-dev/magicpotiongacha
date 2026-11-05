--!nonstrict
-- ISOLATED VISUAL HARNESS: never included in default.project.json, no DataStore/payment/trade runtime.
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.Config)
local Factory=require(Shared.Factory).new(Config)
local Progression=require(Shared.Progression).new(Config)
local World=require(script.Parent.World)
local world=World.new(Config,8,{production=Factory.productionState,buildState=Progression.buildState,
	phaseState=Progression.phaseState,orderProgress=Factory.orderState,action=function() end,focus=function() end},true)
local owner={UserId=1,DisplayName="Honeyglade · Pilot",SetAttribute=function() end}
world:claim(owner); world:update(owner,Factory.newProfile(1,0))
world.root:SetAttribute("VisualHarness",true)
local count=0
for _,p in ipairs(world.root.EnvironmentArt:GetChildren()) do
	assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,"Unsafe decoration")
	assert(not p:FindFirstChildWhichIsA("ProximityPrompt",true),"Art contains a prompt")
	count+=1
end
assert(#world.plots==8 and count<=650,"Pilot topology/budget violated")
print("M7_VISUAL_HARNESS parts="..count.." plots=8 decorated=1 collisionGuards=PASS; no gameplay/backend acceptance")
