--!nonstrict
-- One client scheduler. Only AG01-ready visuals may own effects; no intent sends.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game.ReplicatedStorage.PotionTycoon.Shared
local Policy=require(Shared.SpellbookEffectsPolicy)
local Feedback=require(Shared.SpellbookFeedback)
local Lifecycle=require(Shared.SpellbookEffectLifecycle)
local PaperBurst=require(Shared.SpellbookPaperBurst)
local Controller=require(script.Parent.EnvironmentController)
local Effects={current=nil}
local black,white=Color3.new(0,0,0),Color3.new(1,1,1)
local runeBlue=Color3.fromRGB(138,161,255)
local glowNames={ ["Rune0.001"]=true, RingOuter=true, Crystal=true, Paw04=true, Page03=true, Cover5=true }

function Effects.start()
	if Effects.current then return Effects.current end
	local player=Players.LocalPlayer
	local time, elapsed, lastSettings=0,0,""
	local cursor, connection, stateConnection, inspect
	local config=Policy.quality(Controller.quality,Controller.reduceMotion)
	local tokens,lastBurst=config.burst,0
	local measurements={updates=0,totalMs=0,maxMs=0,feedback=0,emitted=0,errors=0}
	local active={}
	local localLight,lightOwner
	local paper=PaperBurst.new({
		allocate=function() return Instance.new("Part") end,
		setup=function(part,model,index)
			part.Name="SpellbookPaper_"..index
			part.Size=Vector3.new(0.45,0.025,0.65); part.Transparency=1
			part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
			part.CastShadow=false; part.Material=Enum.Material.Neon
			part.Color=Color3.fromRGB(218,226,241)
			part.Parent=model
		end,
		pose=function(part,origin,s)
			if not part.Parent then error("Transient paper removed") end
			part.CFrame=CFrame.new(origin+Vector3.new(s.x,s.y,s.z))*CFrame.Angles(s.pitch,s.yaw,s.roll)
			part.Transparency=s.transparency
		end,
		destroy=function(part) part:Destroy() end,
		failed=function(err) measurements.errors+=1; warn("[AG62A] Paper burst removed: "..tostring(err)) end,
	})
	local function clearLight(model)
		if model==nil or lightOwner==model then
			if localLight then localLight:Destroy(); localLight=nil end
			lightOwner=nil
		end
	end
	local function valid(model)
		local back=model:FindFirstChild("LecternAnchor")
		local anchor=back and back.Value
		local link=anchor and anchor:FindFirstChild("SpellbookVisual")
		return model:IsDescendantOf(workspace) and model:GetAttribute("SpellbookLoadState")=="ready"
			and anchor and anchor.Parent==model.Parent and link and link.Value==model
	end
	local function capture(model)
		local source=model:FindFirstChild("SpellbookLectern")
		if not source then return nil end
		local runes,pages=source:FindFirstChild("FloatingRunes"),source:FindFirstChild("LoosePages")
		local cover=source:FindFirstChild("Spellbook") and source.Spellbook:FindFirstChild("Cover")
		local energy=cover and cover:FindFirstChild("EnergyPoint")
		local particle=cover and cover:FindFirstChild("ParticlePoint")
		if not runes or not pages or not energy or not particle then return nil end
		local runeBox=runes:GetBoundingBox(); local pageBox=pages:GetBoundingBox()
		local record={model=model,parts={},emitters={},energy=energy,particle=particle,
			runeCenter=CFrame.new(runeBox.Position),pageCenter=CFrame.new(pageBox.Position),
			created=time,phase=(model:GetAttribute("PlotIndex") or 0)*0.73,active=false,feedback=0}
		for _,part in ipairs(model:GetDescendants()) do
			if part:IsA("MeshPart") then
				table.insert(record.parts,{part=part,frame=part.CFrame,color=part.Color,material=part.Material,
					group=if part.Parent==runes then "runes" else if part.Parent==pages then "pages" else nil,
					glow=glowNames[part.Name],flame=part.Name=="CandleFlame"})
			end
		end
		return record
	end
	local function reset(record)
		paper.cancel(record.model); clearLight(record.model); record.pendingPaper=nil
		for _,entry in ipairs(record.parts) do
			if entry.part.Parent then
				if entry.group then entry.part.CFrame=entry.frame end
				if entry.glow or entry.flame then entry.part.Color=entry.color end
				if entry.group=="runes" then entry.part.Material=entry.material end
			end
		end
		for _,emitter in ipairs(record.emitters) do emitter.Enabled=false; emitter:Clear() end
		record.pulse=nil; record.active=false
		record.model:SetAttribute("SpellbookEffectActive",false)
	end
	local function dispose(record)
		reset(record)
		for _,emitter in ipairs(record.emitters) do emitter:Destroy() end
		table.clear(record.emitters)
	end
	local function emitter(record,parent,name,burst)
		local e=Instance.new("ParticleEmitter")
		table.insert(record.emitters,e) -- cleanup owns it before any property setup can fail
		e.Name=name; e.Enabled=false; e.Rate=0
		-- Bundled Roblox sprite, not a downloaded/paid/third-party asset.
		e.Texture="rbxasset://textures/particles/sparkles_main.dds"
		e.Color=ColorSequence.new(Color3.fromRGB(153,222,242),Color3.fromRGB(187,168,237))
		e.LightEmission=0.65; e.LightInfluence=0.15; e.Brightness=1.1
		e.Lifetime=NumberRange.new(if burst then 0.65 else 1.8,if burst then 0.9 else 2.4)
		e.Speed=NumberRange.new(if burst then 1.1 else 0.45,if burst then 1.8 else 0.8)
		e.Acceleration=Vector3.new(0,0.25,0); e.EmissionDirection=Enum.NormalId.Top
		e.SpreadAngle=Vector2.new(18,18); e.Drag=0.4
		e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.10),NumberSequenceKeypoint.new(0.4,0.26),NumberSequenceKeypoint.new(1,0)})
		e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.8),NumberSequenceKeypoint.new(0.20,0.15),NumberSequenceKeypoint.new(1,1)})
		e.Parent=parent
		return e
	end
	local function aura(record)
		local e=emitter(record,record.energy,"SpellbookAura",false)
		e.Texture="rbxasset://textures/particles/smoke_main.dds"
		e.Color=ColorSequence.new(Color3.fromRGB(114,145,255),Color3.fromRGB(172,126,234))
		e.Lifetime=NumberRange.new(1.8,2); e.Speed=NumberRange.new(0.02,0.08)
		e.Acceleration=Vector3.zero; e.LockedToPart=true
		e.Rotation=NumberRange.new(-180,180); e.RotSpeed=NumberRange.new(-8,8)
		e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.8),NumberSequenceKeypoint.new(0.5,3.1),NumberSequenceKeypoint.new(1,3.4)})
		e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.3,0.82),NumberSequenceKeypoint.new(0.7,0.88),NumberSequenceKeypoint.new(1,1)})
	end
	local function update(record,now,dt,cfg)
		if not active[record.model] then if record.active then reset(record) end; return end
		record.active=true; record.model:SetAttribute("SpellbookEffectActive",true)
		local sample=Policy.sample(now-record.created,record.phase,cfg.motion)
		local pulse=Policy.pulse(now,record.pulse,cfg.pulseSeconds)
		for _,entry in ipairs(record.parts) do
			local part=entry.part
			if not part.Parent then error("Visual part removed") end
			if entry.group then
				local center=if entry.group=="runes" then record.runeCenter else record.pageCenter
				local delta=if entry.group=="runes" then CFrame.new(0,sample.runeY,0)*CFrame.Angles(0,sample.runeYaw,0)
					else CFrame.new(0,sample.pageY,0)*CFrame.Angles(0,0,sample.pageRoll)
				part.CFrame=center*delta*center:Inverse()*entry.frame
			end
			if entry.group=="runes" then
				part.Material=Enum.Material.Neon
				part.Color=runeBlue:Lerp(black,(1-sample.glow)*0.4):Lerp(white,pulse*0.65)
			elseif entry.glow then part.Color=entry.color:Lerp(black,1-sample.glow):Lerp(white,pulse*0.20)
			elseif entry.flame then part.Color=entry.color:Lerp(black,1-sample.flame) end
		end
		if cfg.idleRate>0 and #record.emitters==0 then
			emitter(record,record.particle,"SpellbookIdle",false)
			emitter(record,record.energy,"SpellbookFeedback",true)
			aura(record)
		end
		if record.emitters[1] then record.emitters[1].Rate=cfg.idleRate; record.emitters[1].Enabled=cfg.idleRate>0 end
		if record.emitters[3] then record.emitters[3].Rate=cfg.auraRate; record.emitters[3].Enabled=cfg.auraRate>0 end
		local owned=record.model.Parent:GetAttribute("OwnerUserId")==player.UserId
		if not owned then paper.cancel(record.model); clearLight(record.model); record.pendingPaper=nil end
		if cfg.light and owned then
			if lightOwner~=record.model then clearLight(); localLight=Instance.new("PointLight"); lightOwner=record.model end
			localLight.Name="SpellbookLocalLight"; localLight.Shadows=false; localLight.Range=8
			localLight.Color=runeBlue; localLight.Brightness=cfg.lightBrightness+pulse*0.35
			localLight.Parent=record.energy
		end
		if record.pendingPaper then
			record.pendingPaper=nil
			paper.trigger(record.model,now,cfg,record.energy.WorldPosition)
		end
	end
	local registry=Lifecycle.new({valid=valid,capture=capture,dispose=dispose,update=update,
		failed=function(err) measurements.errors+=1; warn("[AG62A] Cosmetic layer removed: "..tostring(err)) end},Policy.maxBooks)
	local self={}
	function self.attach(model) registry.add(model) end
	function self.detach(model) active[model]=nil; registry.remove(model) end
	function self.stats()
		local books,emitters,enabled=0,0,0
		for _,r in pairs(registry.records) do
			if r.active then books+=1 end
			emitters+=#r.emitters
			for _,e in ipairs(r.emitters) do if e.Enabled then enabled+=1 end end
		end
		return {tracked=registry.count,active=books,emitters=emitters,enabled=enabled,
			sheets=#paper.items,paperBursts=paper.bursts,peakSheets=paper.peak,lights=if localLight then 1 else 0,
			feedback=measurements.feedback,emitted=measurements.emitted,errors=measurements.errors,
			updates=measurements.updates,averageMs=measurements.totalMs/math.max(1,measurements.updates),maxMs=measurements.maxMs}
	end
	function self.stop()
		if connection then connection:Disconnect(); connection=nil end
		if stateConnection then stateConnection:Disconnect(); stateConnection=nil end
		if inspect then inspect:Destroy(); inspect=nil end
		registry.stop(); paper.cancel(); clearLight(); table.clear(active)
		if Effects.current==self then Effects.current=nil end
	end
	local remotes=game.ReplicatedStorage.PotionTycoon:WaitForChild("Remotes")
	stateConnection=remotes:WaitForChild("State").OnClientEvent:Connect(function(snapshot)
		local owned=player:GetAttribute("PotionPlotIndex")
		local confirmed
		cursor,confirmed=Feedback.consume(cursor,snapshot.presentation and snapshot.presentation.essenceClick,owned)
		if not confirmed or snapshot.writable~=true then return end
		for model,r in pairs(registry.records) do
			if model:GetAttribute("PlotIndex")==owned and model.Parent:GetAttribute("OwnerUserId")==player.UserId
				and valid(model) and r.active then
				r.pulse=time; r.feedback+=1; measurements.feedback+=1
				r.pendingPaper=true
				model:SetAttribute("SpellbookFeedbackCount",r.feedback)
				local count; tokens,count=Policy.take(tokens,time-lastBurst,config); lastBurst=time
				if r.emitters[2] and count>0 then r.emitters[2]:Emit(count); measurements.emitted+=count end
				break
			end
		end
	end)
	connection=RunService.Heartbeat:Connect(function(dt)
		time+=dt; elapsed+=dt
		local signature=Controller.quality..tostring(Controller.reduceMotion)
		if signature~=lastSettings then
			lastSettings=signature; config=Policy.quality(Controller.quality,Controller.reduceMotion)
			for _,r in pairs(registry.records) do
				reset(r)
				for _,e in ipairs(r.emitters) do e:Destroy() end
				table.clear(r.emitters)
			end
			tokens=config.burst; lastBurst=time; elapsed=1
		end
		if elapsed<1/config.hz then return end
		local started=os.clock(); debug.profilebegin("AG62A Spellbook effects")
		local camera=workspace.CurrentCamera
		local candidates={}
		for model,r in pairs(registry.records) do
			if camera and valid(model) then
				local distance=(camera.CFrame.Position-r.energy.WorldPosition).Magnitude
				if distance<=config.range then table.insert(candidates,{model=model,distance=distance,
					owned=model.Parent:GetAttribute("OwnerUserId")==player.UserId}) end
			end
		end
		table.sort(candidates,function(a,b) if a.owned~=b.owned then return a.owned end; return a.distance<b.distance end)
		table.clear(active)
		for i=1,math.min(#candidates,config.active) do active[candidates[i].model]=true end
		registry.step(time,math.min(elapsed,0.1),config); elapsed=0
		paper.step(time)
		debug.profileend()
		local cost=(os.clock()-started)*1000
		measurements.updates+=1; measurements.totalMs+=cost; measurements.maxMs=math.max(measurements.maxMs,cost)
	end)
	-- Studio Command Bar has a separate ModuleScript cache. Read-only local bridge
	-- reports the running controller, rather than creating a second controller.
	if RunService:IsStudio() then
		inspect=Instance.new("BindableFunction"); inspect.Name="Inspect"
		inspect.OnInvoke=function() return self.stats(),Controller.quality,Controller.reduceMotion end
		inspect.Parent=script
	end
	Effects.current=self
	return self
end
return Effects
