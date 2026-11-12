--!nonstrict
local Plan = require("../src/shared/SpellbookLecternPlan")
local Placement = require("../src/shared/SpellbookPlacement")
local Gate = require("../src/shared/SpellbookLoadGate")
local function parts()
	local result = {}
	for name, id in pairs(Plan.assets) do table.insert(result, {name=name,meshId=id,textureId="",anchored=true,collides=false}) end
	return result
end
local function fixture()
	local f = { template = {}, created = 0, discarded = 0, published = 0 }
	local plot = { root = {}, index = 1 }
	local anchor = { parent = plot.root, size = {4,6,4}, cframe = {7,3,9}, prompt = {}, click = {}, upgrade = {} }
	local ops = {}
	function ops.target(p,a) return p and a and a.parent == p.root end
	function ops.existing(a) return a.link end
	function ops.belongs(m,p,a) return m.parent == p.root and m.anchor == a end
	function ops.template() return f.template end
	function ops.validate(t) return t ~= nil and not t.invalid, "invalid-template" end
	function ops.clone() f.created+=1; return {} end
	function ops.prepare(m,p,a) m.anchor=a; m.prepared=true; if f.failPrepare then error("fit") end end
	function ops.publish(m,p,a) m.parent=p.root; a.link=m; f.published+=1; if f.failPublish then error("publish") end end
	function ops.discard(m,a) m.discarded=true; f.discarded+=1; if a.link == m then a.link=nil end end
	return f,ops,plot,anchor
end
return function(T)
	T.test("AG01 pinned mesh contract accepts actual names and IDs", function() T.truthy(Plan.validateParts(parts())) end)
	T.test("AG01 missing mesh cannot hide the crystal", function() local p=parts(); table.remove(p); T.falsy(Plan.validateParts(p)) end)
	T.test("AG01 duplicate mesh and unknown ID are rejected", function()
		local p=parts(); p[1]=p[2]; T.falsy(Plan.validateParts(p))
		p=parts(); p[1].meshId="rbxassetid://1"; T.falsy(Plan.validateParts(p))
	end)
	T.test("AG01 foreign texture and active physics are rejected", function()
		for _,key in ipairs({"textureId","anchored","collides"}) do
			local p=parts(); p[1][key]=({textureId="rbxassetid://1",anchored=false,collides=true})[key]
			T.falsy(Plan.validateParts(p))
		end
	end)
	T.test("AG01 invalid bounds never produce infinite scale", function()
		for _,n in ipairs({0,-1,math.huge,0/0,10000}) do T.falsy(Plan.validHeight(n)); T.equal(Plan.uniformScale(n),1) end
	end)
	T.test("AG01 absent or malformed template creates nothing", function()
		local f,ops,p,a=fixture(); f.template=nil
		T.falsy(Placement.ensure(ops,p,a)); T.equal(f.created,0); T.equal(a.link,nil)
		f.template={invalid=true}; T.falsy(Placement.ensure(ops,p,a)); T.equal(f.created,0)
	end)
	T.test("AG01 repeated placement preserves one visual and exact interaction objects", function()
		local f,ops,p,a=fixture(); local size,cf,prompt,click,upgrade=a.size,a.cframe,a.prompt,a.click,a.upgrade
		T.truthy(Placement.ensure(ops,p,a)); local model=a.link
		for _=1,20 do T.truthy(Placement.ensure(ops,p,a)); T.equal(a.link,model) end
		T.equal(f.created,1); T.equal(f.published,1)
		T.equal(a.size,size); T.equal(a.cframe,cf); T.equal(a.prompt,prompt); T.equal(a.click,click); T.equal(a.upgrade,upgrade)
	end)
	T.test("AG01 foreign plot cannot steal or destroy another visual", function()
		local f,ops,p,a=fixture(); T.truthy(Placement.ensure(ops,p,a)); local model=a.link
		local other={root={},index=2}; local b={parent=other.root,link=model}
		T.falsy(Placement.ensure(ops,other,b)); T.equal(f.created,1); T.equal(f.discarded,0); T.equal(a.link,model)
		T.falsy(Placement.ensure(ops,other,a))
	end)
	T.test("AG01 eight plots get isolated inert models", function()
		local f,ops=fixture(); local seen={}
		for i=1,8 do local p={root={},index=i}; local a={parent=p.root}; T.truthy(Placement.ensure(ops,p,a)); T.falsy(seen[a.link]); seen[a.link]=true end
		T.equal(f.created,8)
	end)
	T.test("AG01 fit failure rolls back only the new visual", function()
		local f,ops,p,a=fixture(); f.failPrepare=true
		T.falsy(Placement.ensure(ops,p,a)); T.equal(f.discarded,1); T.equal(f.published,0); T.equal(a.link,nil)
		f.failPrepare=false; T.truthy(Placement.ensure(ops,p,a))
	end)
	T.test("AG01 partial publication rolls back without losing station", function()
		local f,ops,p,a=fixture(); f.failPublish=true; local prompt=a.prompt
		T.falsy(Placement.ensure(ops,p,a)); T.equal(a.link,nil); T.equal(f.discarded,1); T.equal(a.prompt,prompt)
	end)
	T.test("AG01 all meshes must load before visual swap", function()
		T.equal(Gate.finish("loading",23,23,true),"ready")
		T.equal(Gate.finish("loading",22,23,true),"fallback")
		T.equal(Gate.finish("loading",23,23,false),"fallback")
	end)
	T.test("AG01 timeout remains fallback after late content success", function()
		local state=Gate.finish("loading",0,23,false)
		T.equal(Gate.finish(state,23,23,true),"fallback")
		T.equal(Gate.finish("ready",0,23,false),"ready")
	end)
end
