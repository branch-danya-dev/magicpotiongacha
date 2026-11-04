--!nonstrict
local H=require("./M4Harness")
local C=require("../src/shared/TradeCodec")
local Config=require("../src/shared/Config")
local fixture=require("./fixtures/m3-profile")
return function(T: any)
	T.test("M4 migration: genuine V4 retains every old field, equipped item, job and receipts",function()
		local h=H.new(); local p,reason=h.engine.migrate(C.copy(fixture)); T.truthy(p,reason)
		for key,value in pairs(fixture) do if key~="schemaVersion" then T.same(p[key],value,key) end end
		T.equal(p.schemaVersion,Config.schemaVersion); T.same(p.trade,{sequence=0}); T.same(h.engine.migrate(C.copy(p)),p)
	end)
	for _,defect in ipairs({"future","old-trade","bad-sequence","missing-receipt","bad-pending-hash","bad-stage"}) do
		T.test("M4 persistence: malformed migration/reservation fails closed / "..defect,function()
			local h=H.new(); local p=C.copy(fixture)
			if defect=="future" then p.schemaVersion=Config.schemaVersion+1
			elseif defect=="old-trade" then p.trade={sequence=0}
			else
				p=assert(h.engine.migrate(p))
				if defect=="bad-sequence" then p.trade.sequence=-1 elseif defect=="missing-receipt" then p.trade.sequence=1
				else p.trade.sequence=1; p.trade.pending={id="abc",hash=defect=="bad-pending-hash" and "bad" or string.rep("a",64),sequence=1,stage=defect=="bad-stage" and "unlocked" or "prepared"} end
			end
			T.equal(h.engine.migrate(C.copy(p)),nil)
			h.records["p:123"]={schemaVersion=1,revision=1,profile=p}; local before=C.copy(h.records["p:123"])
			T.equal(h.newStore("migration"):loadExisting(123,function() return h.engine.newProfile(123,h.now) end),nil)
			T.same(h.records["p:123"],before)
		end)
	end
end
