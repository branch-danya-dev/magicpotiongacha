--!nocheck
-- Optional F5 CLIENT diagnostics after AG69-R1. Never mapped into the game.
local q=assert(_G.AG70QA)
local root=workspace.PotionTycoonWorld
local L=game:GetService("Lighting")
local H=game:GetService("HttpService")
local book=game.Players.LocalPlayer.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
local function report(tag,v) print("AG70_R1 "..tag.." "..H:JSONEncode(v)) end
local function same(a,b)
	if type(a)~=type(b) then return false end
	if type(a)=="number" then return math.abs(a-b)<1e-6 end
	if type(a)~="table" then return a==b end
	for k,v in pairs(a) do if not same(v,b[k]) then return false end end
	for k in pairs(b) do if a[k]==nil then return false end end
	return true
end
local function inspect() return workspace.M7ClientWeather.PostFXInspect:Invoke() end
function q.coverage()
	task.spawn(function()
		q.camera("near");q.placeAvatar();q.pose("night");task.wait(9)
		local switches=0
		local expected=require(game.ReplicatedStorage.PotionTycoon.Shared.EnvironmentClock).weather
		for _,weather in ipairs({"clear","buildup","rain","clearing","afterrain"}) do
			q.pose("weather:"..weather);task.wait(9)
			for _,tier in ipairs({"full","reduced","minimal"}) do for _,motion in ipairs({false,true}) do
				q.quality(tier);q.motion(motion);q.look("OFF");task.wait(3)
				local before=q.snapshot();local refs=L:GetChildren();local n=#workspace:GetDescendants()
				local pool=workspace.M7ClientWeather.SunPool_1;local pos=pool.Position
				for _=1,2 do q.look("AG70");task.wait(.15);q.look("OFF");task.wait(.15);switches+=2 end
				local restored=same(before,q.snapshot());local identities=#refs==#L:GetChildren()
				for _,v in ipairs(refs) do identities=identities and v.Parent==L end
				local counts=inspect();local b=book:Invoke()
				local actual=counts.worldLookSample;local weatherVerified=true
				for _,key in ipairs({"rain","cloud","wet","afterRain"}) do
					weatherVerified=weatherVerified and math.abs(actual[key]-expected[weather][key])<1e-6
				end
				local ok=restored and identities and pool.Position==pos and n==#workspace:GetDescendants()
					and weatherVerified and b.errors==0 and counts.assetComplete and counts.assetFailures==0 and counts.lights<=({full=6,reduced=3,minimal=0})[tier]
				report("COVERAGE",{weather=weather,tier=tier,motion=motion,restored=restored,sameInstances=identities,
					countBefore=n,countAfter=#workspace:GetDescendants(),poolRestored=pool.Position==pos,lights=counts.lights,
					weatherVerified=weatherVerified,sample=actual,bookErrors=b.errors,ok=ok,switches=switches})
				assert(ok,"Weather/tier/motion restoration")
			end end
		end
		q.quality("reduced");q.motion(false);q.look("AG70");report("COVERAGE_COMPLETE",switches)
	end)
end
function q.fallbackCheck()
	task.spawn(function()
		q.look("AG70");q.pose("night");task.wait(9)
		local refs=L:GetChildren();local before=q.snapshot()
		for i=1,3 do
			book:Invoke("fallback",true);task.wait(.5)
			local legacy=book:Invoke();assert(legacy.mode=="original" and not workspace:FindFirstChild("SpellbookSoulVFX"))
			book:Invoke("fallback",false);task.wait(2)
			local soul=book:Invoke();assert(soul.mode=="soul" and soul.tracked==8 and soul.errors==0)
			local folders=0;for _,v in ipairs(workspace:GetChildren()) do if v.Name=="SpellbookSoulVFX" then folders+=1 end end
			assert(folders==1 and #refs==#L:GetChildren());for _,v in ipairs(refs) do assert(v.Parent==L) end
			assert(same(before,q.snapshot()))
			report("FALLBACK",{cycle=i,legacy=legacy.mode,soul=soul.mode,tracked=soul.tracked,errors=soul.errors,folders=folders,lightingPreserved=true})
		end
	end)
end
if _G.AG70StateConnection then _G.AG70StateConnection:Disconnect() end
_G.AG70StateConnection=game.ReplicatedStorage.PotionTycoon.Remotes.State.OnClientEvent:Connect(function(s)
	q.latest=s;report("ECONOMY",{essence=s.essence,gold=s.gold})
end)
print("AG70_R1_RESUME_QA_READY")
