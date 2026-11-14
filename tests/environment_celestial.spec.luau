--!strict
local C=require("../src/shared/EnvironmentCelestial")
return function(T:any)
	T.test("AG69 sun retains seven degree angular extent at any rig distance",function()
		for _,d in ipairs({210,420,840}) do T.near(math.deg(2*math.atan(C.sunDiameter(d)/(2*d))),7,1e-8) end
	end)
	T.test("AG69 sun disappears below horizon and in full rain",function()
		for _,y in ipairs({-1,-.2,-.02}) do T.equal(C.sunAlpha(y,0,0),0) end
		for _,y in ipairs({0,.3,1}) do T.equal(C.sunAlpha(y,0,1),0) end
		T.equal(C.sunAlpha(1,0,0),1)
	end)
	T.test("AG69 sun cloud buildup and clearing stay bounded and monotonic",function()
		local prev=1
		for i=0,100 do local a=C.sunAlpha(.5,i/100,i/200); T.truthy(a>=0 and a<=prev); prev=a end
		T.equal(C.sunAlpha(1,-1,-1),1); T.equal(C.sunAlpha(1,2,2),0)
	end)
	T.test("AG69 horizon fade has no temporal jump at either endpoint",function()
		for _,y in ipairs({-.02,.06}) do T.truthy(math.abs(C.sunAlpha(y-1e-5,0,0)-C.sunAlpha(y+1e-5,0,0))<1e-6) end
	end)
end
