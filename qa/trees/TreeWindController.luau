--!nonstrict
-- One scheduler for all species/instances. No Lighting or GlobalWind ownership.
local Run=game:GetService("RunService")
local Config=require(script.Parent.TreeVisualConfig)
local Math=require(script.Parent.TreeWindModel)
local Controller={}
function Controller.start(trees)
	assert(Run:IsClient(),"Tree motion is client-only")
	local self={quality="full",reduceMotion=false,updates=0,boneWrites=0,lastMs=0,activeTrees=0,connections=1}
	local entries={};local elapsed=0;local dead=false;local restored=0
	for _,tree in ipairs(trees)do
		local c=assert(Config.species[tree:GetAttribute("TreeSpecies")],"Missing species")
		local bones={}
		for _,b in ipairs(tree:GetDescendants())do if b:IsA("Bone") and string.sub(b.Name,1,#c.bonePrefix)==c.bonePrefix then table.insert(bones,b)end end
		table.sort(bones,function(a,b)return a.Name<b.Name end);assert(#bones==c.bones)
		local frames={};for i,b in ipairs(bones)do frames[i]=b.WorldCFrame.Rotation end
		entries[#entries+1]={tree=tree,config=c,bones=bones,frames=frames,phase=tree:GetAttribute("WindPhase"),active=false,blend=0,wx=workspace.GlobalWind.X,wz=workspace.GlobalWind.Z}
	end
	local function reset(e)
		for _,b in ipairs(e.bones)do if b.Parent then b.Transform=CFrame.identity end end
		e.active=false;e.blend=0;restored+=1
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
				if distance<=e.config.wind.budgets[self.quality].distance then table.insert(candidates,{e=e,d=distance})end
			end
		end
		table.sort(candidates,function(a,b)if a.d==b.d then return a.e.tree.Name<b.e.tree.Name end;return a.d<b.d end)
		local selected={};local speciesCounts={};self.activeTrees=0
		local totalCap=({full=20,reduced=12,minimal=6})[self.quality]
		for _,v in ipairs(candidates)do
			local s=v.e.tree:GetAttribute("TreeSpecies");local n=speciesCounts[s] or 0
			if self.activeTrees<totalCap and n<v.e.config.wind.budgets[self.quality].trees then selected[v.e]=true;speciesCounts[s]=n+1;self.activeTrees+=1 end
		end
		local t=workspace:GetServerTimeNow()
		for _,e in ipairs(entries)do
			e.wx=Math.smooth(e.wx,wind.X,step,e.config.wind.smoothing);e.wz=Math.smooth(e.wz,wind.Z,step,e.config.wind.smoothing)
			if selected[e]then
				e.blend=math.min(1,e.blend+step/.45)
				for i,b in ipairs(e.bones)do
					local x,z=Math.sample(e.config.wind,t,e.phase,i,e.tree:GetAttribute("BranchFactor"..i) or 1,e.wx,e.wz,self.quality,false)
					local frame=e.frames[i]
					b.Transform=frame:Inverse()*CFrame.Angles(-z*e.blend,0,x*e.blend)*frame;self.boneWrites+=1
				end
				e.active=true
			elseif e.active then reset(e)end
		end
		self.updates+=1;self.lastMs=(os.clock()-started)*1000
	end)
	function self.setQuality(q)assert(q=="full" or q=="reduced" or q=="minimal");self.quality=q end
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
