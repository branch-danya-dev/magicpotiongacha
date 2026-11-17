--!nonstrict
local T=require("./Test")
local W=require("../qa/willow/WindModel")
T.test("Willow calm and Reduce Motion do not deform foliage",function()
	for _,q in ipairs({"full","reduced","minimal"})do
		local x,z=W.sample(3,1,0,0,q,false);T.equal(x,0);T.equal(z,0)
		x,z=W.sample(3,1,30,20,q,true);T.equal(x,0);T.equal(z,0)
	end
end)
T.test("Willow follows wind direction and clamps storms",function()
	for i=0,300 do
		local x,z=W.sample(i*.13,1,300,400,"full",false)
		T.truthy(x>=0 and z>=0 and math.sqrt(x*x+z*z)<=.055001)
		T.truthy(math.abs(x*4-z*3)<1e-6)
		local a,b=W.sample(i*.13,1,-300,-400,"full",false)
		T.truthy(math.abs(x+a)<1e-9 and math.abs(z+b)<1e-9)
	end
end)
T.test("Willow quality caps reduce CPU and motion without changing shape",function()
	T.equal(W.budget("full").trees,20);T.equal(W.budget("reduced").trees,12);T.equal(W.budget("minimal").trees,6)
	T.truthy(W.budget("full").hz>W.budget("reduced").hz and W.budget("reduced").hz>W.budget("minimal").hz)
	local full=W.sample(1,2,10,0,"full",false)
	local reduced=W.sample(1,2,10,0,"reduced",false)
	local minimal=W.sample(1,2,10,0,"minimal",false)
	T.truthy(full>reduced and reduced>minimal and minimal>0)
end)
T.test("Willow phases differ but response is continuous and bounded",function()
	local first=W.sample(3,0,10,1,"full",false)
	local other=W.sample(3,2.5,10,1,"full",false);T.truthy(math.abs(first-other)>.001)
	for i=0,100 do local a=W.sample(i,0,10,1,"full",false);local b=W.sample(i+.001,0,10,1,"full",false);T.truthy(math.abs(a-b)<.0001)end
end)
T.test("Willow invalid wind stays finite",function()
	for _,v in ipairs({0/0,math.huge,-math.huge})do local a,b=W.sample(1,1,v,v,"full",false);T.equal(a,0);T.equal(b,0)end
end)
T.test("Willow live Unix server time animates continuously instead of freezing at zero",function()
	local epoch=1794888000
	local start=W.sample(epoch,1,10,1,"full",false)
	local later=W.sample(epoch+2,1,10,1,"full",false)
	T.truthy(math.abs(start-later)>.001)
	for i=0,100 do
		local a=W.sample(epoch+i,0,10,1,"full",false)
		local b=W.sample(epoch+i+.001,0,10,1,"full",false)
		T.truthy(math.abs(a-b)<.0001)
	end
	for _,v in ipairs({0/0,math.huge,-math.huge})do
		local a,b=W.sample(v,1,10,1,"full",false)
		T.truthy(a==a and b==b and math.abs(a)<.056 and math.abs(b)<.056)
	end
end)
T.finish()
