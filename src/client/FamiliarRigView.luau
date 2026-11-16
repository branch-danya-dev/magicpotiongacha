--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local Idle = require(ReplicatedStorage.PotionTycoon.Shared.FamiliarIdle)
local Registry = require(script.Parent.FamiliarVisualRegistry)
local Environment = require(script.Parent.EnvironmentController)
local View = { count = 0, limit = 10 }
function View.enabled()
	return RunService:IsStudio() and workspace:GetAttribute("GreenSlimeRigPreviewEnabled") == true
end
function View.create(species, parent, seed)
	local spec = Registry[species]
	if not View.enabled() or not spec or View.count >= View.limit then return nil end
	local templates = ReplicatedStorage:FindFirstChild("FamiliarTemplates")
	local template = templates and templates:FindFirstChild(spec.template)
	if not template then return nil end
	local model = template:Clone()
	local animator = model:FindFirstChildWhichIsA("Animator", true)
	local mesh = model:FindFirstChildWhichIsA("MeshPart", true)
	if not animator or not mesh then model:Destroy(); return nil end
	View.count += 1
	model.Name = "GreenSlimeVisual"
	model:ScaleTo(spec.scale)
	mesh.Transparency = 1
	model.Parent = parent
	local self = {model = model, ready = false, failed = false, disposed = false, tracks = {}, animations = {}, fetch = {}, driver = nil}
	local random = Random.new(seed)
	local loader, watchdog
	local function dispose()
		if self.disposed then return end
		self.disposed = true; self.ready = false
		if watchdog then watchdog:Disconnect(); watchdog = nil end
		if self.removal then self.removal:Disconnect(); self.removal = nil end
		if self.policy then self.policy:Disconnect(); self.policy = nil end
		if loader and coroutine.status(loader) ~= "dead" and loader ~= coroutine.running() then pcall(task.cancel, loader) end
		if self.driver then self.driver.destroy(); self.driver = nil
		else for _, track in ipairs(self.tracks) do track:Stop(0); track:Destroy() end end
		for _, animation in ipairs(self.animations) do animation:Destroy() end
		table.clear(self.tracks); table.clear(self.animations)
		View.count -= 1
		model:Destroy()
	end
	self.destroy = dispose
	local function fail(reason)
		if self.disposed then return end
		self.failed = true
		warn("AG74 Green Slime fallback: " .. reason)
		dispose()
	end
	self.removal = model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then dispose() end
	end)
	self.policy = workspace:GetAttributeChangedSignal("GreenSlimeRigPreviewEnabled"):Connect(function()
		if not View.enabled() then dispose() end
	end)
	local deadline = os.clock() + 12
	watchdog = RunService.Heartbeat:Connect(function()
		if self.disposed then return end
		if not View.enabled() then dispose()
		elseif not self.ready and os.clock() >= deadline then fail("asset load timeout") end
	end)
	loader = task.defer(function()
		local ok, problem = pcall(function()
			for _, id in ipairs(spec.animations) do
				local animation = Instance.new("Animation"); animation.AnimationId = id
				table.insert(self.animations, animation)
			end
			local loaded = true
			-- Mesh instances preserve content type; passing a mesh ID string requests an image.
			ContentProvider:PreloadAsync({mesh, spec.textureId, self.animations[1], self.animations[2]}, function(id, status)
				self.fetch[id] = status.Name
				if status ~= Enum.AssetFetchStatus.Success then loaded = false end
			end)
			if self.disposed then return end
			assert(loaded, "asset unavailable")
			for _, animation in ipairs(self.animations) do
				local track = animator:LoadAnimation(animation)
				track.Priority = Enum.AnimationPriority.Idle
				table.insert(self.tracks, track)
			end
			while not self.disposed and (self.tracks[1].Length == 0 or self.tracks[2].Length == 0) do RunService.Heartbeat:Wait() end
			if self.disposed then return end
			for i, track in ipairs(self.tracks) do assert(math.abs(track.Length-spec.lengths[i]) < 0.05, "unexpected clip length") end
			self.driver = Idle.new(self.tracks, function() return random:NextNumber() end, os.clock, spec.weights)
			self.ready = true
			model:SetAttribute("AG74Loaded", true)
			print("AG74_READY", model:GetFullName(), self.tracks[1].Length, self.tracks[2].Length)
		end)
		if not ok and not self.disposed then fail(tostring(problem)) end
	end)
	function self.update(pivot, idle)
		if self.disposed then return false end
		if not View.enabled() then dispose(); return false end
		model:PivotTo(pivot)
		if not self.ready then return false end
		mesh.Transparency = 0
		self.driver.setIdle(idle and Environment.quality ~= "minimal" and not Environment.reduceMotion)
		model:SetAttribute("AG74CurrentIdle", self.driver.current or 0)
		model:SetAttribute("AG74Selections", self.driver.selections)
		return true
	end
	return self
end
return View
