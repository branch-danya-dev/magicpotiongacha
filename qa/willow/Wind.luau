--!nonstrict
-- Client-only consumer of the existing GlobalWind owner, one bounded scheduler.
local Run=game:GetService("RunService")
local Model=require(script.Parent.WindModel)
local Wind={}
function Wind.start(trees)
	assert(Run:IsClient(),"Willow wind must run on the client")
	local self={quality="full",reduceMotion=false,updates=0,boneWrites=0,lastMs=0,enabled=true,time=nil}
	local entries={}; local dead=false;local elapsed=0
	for index,tree in ipairs(trees) do
		local bones={}
		for _,b in ipairs(tree:GetDescendants()) do
			if b:IsA("Bone") and string.match(b.Name,"^Crown_%d%d$") then table.insert(bones,b) end
		end
		table.sort(bones,function(a,b)return a.Name<b.Name end)
		assert(#bones==8,"Expected eight crown controls")
		entries[index]={tree=tree,bones=bones,phase=index*.613,active=false}
	end
	local function reset(entry)
		for _,b in ipairs(entry.bones) do if b.Parent then b.Transform=CFrame.identity end end
		entry.active=false
	end
	local connection=Run.Heartbeat:Connect(function(dt)
		local budget=Model.budget(self.quality);elapsed+=dt
		if elapsed<1/budget.hz then return end
		elapsed%=1/budget.hz
		local started=os.clock();local cam=workspace.CurrentCamera;local wind=workspace.GlobalWind
		local t=self.time or workspace:GetServerTimeNow();local candidates={}
		for _,entry in ipairs(entries) do
			if entry.tree.Parent and cam and self.enabled and not self.reduceMotion then
				local d=(entry.tree:GetPivot().Position-cam.CFrame.Position).Magnitude
				if d<=budget.distance then table.insert(candidates,{entry=entry,distance=d}) end
			end
		end
		table.sort(candidates,function(a,b)return a.distance<b.distance end)
		local selected={}
		for n=1,math.min(#candidates,budget.trees) do selected[candidates[n].entry]=true end
		for _,entry in ipairs(entries) do
			if selected[entry] then
				for i,b in ipairs(entry.bones) do
					local x,z=Model.sample(t,entry.phase+i*.79,wind.X,wind.Z,self.quality,false)
					local rotation=b.WorldCFrame.Rotation
					b.Transform=rotation:Inverse()*CFrame.Angles(-z,0,x)*rotation
					self.boneWrites+=1
				end
				entry.active=true
			elseif entry.active then reset(entry) end
		end
		self.updates+=1;self.lastMs=(os.clock()-started)*1000
	end)
	function self.setQuality(q)
		assert(q=="full" or q=="reduced" or q=="minimal");self.quality=q
	end
	function self.setReduceMotion(value)
		self.reduceMotion=value==true
		if self.reduceMotion then for _,e in ipairs(entries)do reset(e)end end
	end
	function self.stop()
		if dead then return end;dead=true;connection:Disconnect()
		for _,e in ipairs(entries)do reset(e)end;table.clear(entries)
	end
	return self
end
return Wind
