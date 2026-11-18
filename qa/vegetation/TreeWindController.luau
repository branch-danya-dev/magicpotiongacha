--!nonstrict
-- One scheduler for all species/instances. No Lighting or GlobalWind ownership.
local Run=game:GetService("RunService")
local Config=require(script.Parent.TreeVisualConfig)
local Math=require(script.Parent.TreeWindModel)
local Policy=require(script.Parent.TreeWindPolicy)
local Controller={}
function Controller.start(trees, speciesCatalog)
	assert(Run:IsClient(),"Tree motion is client-only")
	local self={quality="full",reduceMotion=false,updates=0,boneWrites=0,lastMs=0,activeTrees=0,connections=1}
	local entries={};local elapsed=0;local dead=false;local restored=0
	for _,tree in ipairs(trees)do
		local species=tree:GetAttribute("TreeSpecies")
		local c=assert((speciesCatalog or Config.species)[species],"Missing species")
		local bones={}
		for _,b in ipairs(tree:GetDescendants())do
			if b:IsA("Bone") and (c.rig and c.rig[b.Name] or not c.rig and string.sub(b.Name,1,#c.bonePrefix)==c.bonePrefix) then table.insert(bones,b)end
		end
		table.sort(bones,function(a,b)return a:GetFullName()<b:GetFullName() end)
		if c.rig then
			for name,role in pairs(c.rig)do
				assert(Policy.roles[role],"Unknown bone role")
				local found=false;for _,b in ipairs(bones)do if b.Name==name then found=true end end
				assert(found,"Missing rig bone: "..name)
			end
		else assert(#bones==c.bones) end
		local frames,indices,unique={},{},{}
		local names={};for _,b in ipairs(bones)do if not unique[b.Name] then unique[b.Name]=true;table.insert(names,b.Name)end end
		table.sort(names);for i,name in ipairs(names)do unique[name]=i end
		for i,b in ipairs(bones)do frames[i]=b.WorldCFrame.Rotation;indices[i]=c.phaseIndices and c.phaseIndices[b.Name] or unique[b.Name] end
		entries[#entries+1]={tree=tree,config=c,bones=bones,frames=frames,indices=indices,phase=tree:GetAttribute("WindPhase") or 0,active=false,blend=0,due=0,wx=workspace.GlobalWind.X,wz=workspace.GlobalWind.Z}
	end
	local function reset(e)
		for _,b in ipairs(e.bones)do if b.Parent then b.Transform=CFrame.identity end end
		e.active=false;e.blend=0;e.due=0;restored+=1
	end
	local connection=Run.Heartbeat:Connect(function(dt)
		elapsed+=dt
		local hz=0;for _,e in ipairs(entries)do hz=math.max(hz,e.config.wind.budgets[self.quality].hz)end
		if hz==0 or elapsed<1/hz then return end
		local step=elapsed;elapsed%=1/hz;local started=os.clock()
		local wind=workspace.GlobalWind
		local camera=workspace.CurrentCamera;local candidates={}
		for _,e in ipairs(entries)do
			if e.tree:IsDescendantOf(workspace) and camera and not self.reduceMotion then
				local distance=(e.tree:GetPivot().Position-camera.CFrame.Position).Magnitude
				if Policy.strength(e.tree:GetAttribute("WindStrength"))>0 then
					table.insert(candidates,{e=e,distance=distance,id=e.tree:GetAttribute("StableTreeId") or e.tree.Name,species=e.tree:GetAttribute("TreeSpecies"),budget=e.config.wind.budgets[self.quality]})
				end
			end
		end
		local selected={};self.activeTrees=0
		for _,v in ipairs(Policy.select(candidates,self.quality))do
			selected[v.e]=Policy.rate(v.budget,v.distance);self.activeTrees+=1
		end
		local t=workspace:GetServerTimeNow()
		for _,e in ipairs(entries)do
			e.wx=Math.smooth(e.wx,wind.X,step,e.config.wind.smoothing);e.wz=Math.smooth(e.wz,wind.Z,step,e.config.wind.smoothing)
			if selected[e]then
				e.blend=math.min(1,e.blend+step/.45)
				e.due+=step
				if not e.active or e.due>=1/selected[e] then
					e.due%=1/selected[e]
					local strength=Policy.strength(e.tree:GetAttribute("WindStrength"))
					for i,b in ipairs(e.bones)do if b.Parent then
						local role=e.config.rig and Policy.roles[e.config.rig[b.Name]]
						local index=e.indices[i]
						local x,z=Math.sample(e.config.wind,t-(role and role.delay or 0),e.phase,index,e.tree:GetAttribute("BranchFactor"..index) or 1,e.wx,e.wz,self.quality,false)
						local scale=e.blend*strength*(role and role.strength or 1)
						local frame=e.frames[i]
						b.Transform=if scale==0 then CFrame.identity else frame:Inverse()*CFrame.Angles(-z*scale,0,x*scale)*frame;self.boneWrites+=1
					end end
				end
				e.active=true
			elseif e.active then reset(e)end
		end
		self.updates+=1;self.lastMs=(os.clock()-started)*1000
	end)
	function self.setQuality(q)
		assert(q=="full" or q=="reduced" or q=="minimal");self.quality=q
		for _,e in ipairs(entries)do reset(e)end;self.activeTrees=0
	end
	function self.setReduceMotion(v)
		self.reduceMotion=v==true
		if self.reduceMotion then for _,e in ipairs(entries)do reset(e)end;self.activeTrees=0 end
	end
	function self.stop()
		if dead then return end;dead=true;connection:Disconnect();self.connections=0
		for _,e in ipairs(entries)do reset(e)end;table.clear(entries);self.activeTrees=0
	end
	function self.stats()return {connections=self.connections,updates=self.updates,boneWrites=self.boneWrites,lastMs=self.lastMs,activeTrees=self.activeTrees,resets=restored,entries=#entries}end
	return self
end
return Controller
