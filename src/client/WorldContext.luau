--!nonstrict
-- One local presentation owner. Never sends an economic intent or changes a callback.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Shared=game.ReplicatedStorage.PotionTycoon.Shared
local Policy=require(Shared.ContextUI)
local Config=require(Shared.Config)
local Context={}
function Context.start(onChanged,isPanelOpen,blockedRects,currentState)
	local player=Players.LocalPlayer
	local root=workspace:WaitForChild("PotionTycoonWorld")
	assert(not root:GetAttribute("WorldContextOwned"),"Duplicate world context owner")
	root:SetAttribute("WorldContextOwned",true)
	local affordance=require(script.Parent.FarmAffordance).new(root,player)
	local prompts,labels,pads,signs={},{},{},{}
	local current,candidates=nil,{}
	local pinned,pinnedUntil=nil,0
	local stopped=false
	local highlight=Instance.new("Highlight")
	highlight.Name="ContextFocus"; highlight.FillTransparency=1; highlight.OutlineTransparency=.25
	highlight.OutlineColor=Color3.fromRGB(229,211,157); highlight.DepthMode=Enum.HighlightDepthMode.Occluded
	highlight.Parent=player.PlayerGui
	local function register(object)
		if object:IsA("BillboardGui") then
			labels[object]=object.Enabled; object.Enabled=false
		elseif object:IsA("ProximityPrompt") and object.Parent:IsA("BasePart") then
			local anchor=object.Parent; local plot=anchor.Parent
			local record={enabled=object.Enabled,objectText=object.ObjectText,actionText=object.ActionText,
				anchor=anchor,plot=plot,id=anchor:GetFullName(),station=anchor:GetAttribute("StationId") or string.gsub(anchor.Name,"^Buy_",""),
				upgrade=string.sub(anchor.Name,1,4)=="Buy_",public=anchor.Name=="TradePost"}
			prompts[object]=record
			object.Enabled=false
		elseif object:IsA("BasePart") then
			if string.sub(object.Name,1,4)=="Buy_" then
				pads[object]={color=object.Color,material=object.Material,transparency=object.LocalTransparencyModifier}
				object.Material=Enum.Material.SmoothPlastic; object.Color=Color3.fromRGB(123,143,122)
			elseif object.Name=="Sign" and object.Parent:GetAttribute("PlotIndex") then
				signs[object]=object.LocalTransparencyModifier; object.LocalTransparencyModifier=1
			end
		end
	end
	for _,object in ipairs(root:GetDescendants()) do register(object) end
	local added=root.DescendantAdded:Connect(register)
	local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Exclude
	local elapsed=0
	local function update(cycle)
		local cam=workspace.CurrentCamera; local character=player.Character
		local hrp=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local entries={}
		local region=nil
		if hrp then
			for _,plot in ipairs(root:GetChildren()) do
				local floor=plot:FindFirstChild("Floor")
				if plot:GetAttribute("PlotIndex") and floor then
					local p=floor.CFrame:PointToObjectSpace(hrp.Position)
					if math.abs(p.X)<=floor.Size.X/2 and math.abs(p.Z)<=floor.Size.Z/2 then
						local owner=plot:GetAttribute("OwnerUserId")
						region=owner==player.UserId and "Моя ферма" or (owner and "Чужая ферма · только осмотр" or "Свободный участок")
						break
					end
				end
			end
		end
		if cam and hrp and humanoid and humanoid.Health>0 and not isPanelOpen() and not GuiService.MenuIsOpen and not Input:GetFocusedTextBox() then
			local ignored={character}
			for sign in pairs(signs) do if sign.Parent then table.insert(ignored,sign) end end
			ray.FilterDescendantsInstances=ignored
			for prompt,record in pairs(prompts) do
				local anchor=record.anchor
				if prompt.Parent and anchor:IsDescendantOf(root) and (record.public or anchor:GetAttribute("FirstSessionHidden")==false) then
					local distance=(anchor.Position-hrp.Position).Magnitude
					local point,visible=cam:WorldToViewportPoint(anchor.Position)
					local clear=false
					if distance<=prompt.MaxActivationDistance and visible then
						local hit=workspace:Raycast(cam.CFrame.Position,anchor.Position-cam.CFrame.Position,ray)
						clear=not hit or hit.Instance==anchor
					end
					table.insert(entries,{id=record.id,station=record.station,upgrade=record.upgrade,public=record.public,
						owner=record.plot:GetAttribute("OwnerUserId"),enabled=record.enabled,visible=visible,clear=clear,
						distance=distance,maximum=prompt.MaxActivationDistance,x=point.X,y=point.Y,z=point.Z,
						aim=math.abs(point.X/cam.ViewportSize.X-.5),prompt=prompt,anchor=anchor})
				end
			end
			candidates=Policy.candidates(entries,player.UserId,cam.ViewportSize.X,cam.ViewportSize.Y,blockedRects and blockedRects())
		else candidates={} end
		current=Policy.choose(candidates,current and current.id,cycle)
		if cycle and current then pinned,pinnedUntil=current.id,os.clock()+8 end
		if pinned and os.clock()<pinnedUntil then
			for _,entry in ipairs(candidates) do if entry.id==pinned then current=entry; break end end
		end
		local snapshot=currentState and currentState()
		local clickEssence=snapshot and snapshot.starter and snapshot.starter.legacyGrant~=true and Config.economyV2 and Config.economyV2.clickEssence
		for prompt,record in pairs(prompts) do
			if prompt.Parent then
				local hidden=not record.public and record.anchor:GetAttribute("FirstSessionHidden")~=false
				prompt.Enabled=not hidden and current~=nil and current.prompt==prompt
				if not record.upgrade and record.anchor.Parent then record.anchor.LocalTransparencyModifier=hidden and 1 or 0 end
				-- Keep Roblox's native keyboard/gamepad/touch control and hold semantics.
				prompt.ObjectText=Policy.description(record,Config)
				prompt.ActionText=record.upgrade and "Улучшить" or (record.station=="crystal" and (clickEssence and ("+"..clickEssence.." Essence") or "Собрать") or "Открыть")
			end
		end
		for gui in pairs(labels) do if gui.Parent then gui.Enabled=false end end
		local integrated=root:GetAttribute("FarmGroundVersion")==1
		for pad,record in pairs(pads) do if pad.Parent then pad.LocalTransparencyModifier=(pad:GetAttribute("FirstSessionHidden")~=false or integrated) and 1 or record.transparency end end
		highlight.Adornee=current and not (integrated and current.upgrade) and current.anchor or nil
		-- Task 07: highlight the visible authored model; retain the original
		-- invisible anchor for distance, raycast, ownership and native prompts.
		if highlight.Adornee then
			local lectern=highlight.Adornee:FindFirstChild("SpellbookVisual")
			local presentation=highlight.Adornee:FindFirstChild("PresentationModel")
			if lectern and lectern.Value then highlight.Adornee=lectern.Value
			elseif presentation and presentation.Value then highlight.Adornee=presentation.Value end
		end
		affordance.update(current,currentState and currentState(),hrp and hrp.Position)
		onChanged(current,#candidates,region)
	end
	local heartbeat=RunService.Heartbeat:Connect(function(dt) elapsed+=dt; if elapsed>=.1 then elapsed=0; update(false) end end)
	local input=Input.InputBegan:Connect(function(key,handled)
		if not handled and not Input:GetFocusedTextBox() and (key.KeyCode==Enum.KeyCode.X or key.KeyCode==Enum.KeyCode.ButtonR1) then update(true) end
	end)
	local self={}
	function self.next() update(true) end
	function self.current() return current end
	function self.refresh() update(false) end
	function self.stop()
		if stopped then return end; stopped=true; heartbeat:Disconnect(); added:Disconnect(); input:Disconnect(); highlight:Destroy(); affordance.stop()
		for prompt,record in pairs(prompts) do if prompt.Parent then prompt.Enabled=record.enabled; prompt.ObjectText=record.objectText; prompt.ActionText=record.actionText end end
		for gui,enabled in pairs(labels) do if gui.Parent then gui.Enabled=enabled end end
		for pad,record in pairs(pads) do if pad.Parent then pad.Color=record.color; pad.Material=record.material; pad.LocalTransparencyModifier=record.transparency end end
		for sign,transparency in pairs(signs) do if sign.Parent then sign.LocalTransparencyModifier=transparency end end
		root:SetAttribute("WorldContextOwned",nil)
	end
	update(false)
	return self
end
return Context
