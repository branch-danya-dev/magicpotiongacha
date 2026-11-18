--!nonstrict
-- Client terrain can arrive after the server's ready attributes. Bounded startup
-- only; allocate no tree resources until every authored root has native support.
local R={}
function R.wait(trees,probe,pause,clock,alive,timeout)
	local deadline=clock()+timeout
	while true do
		assert(alive(),"Forest removed during terrain load")
		local hits,missing={},nil
		for _,t in ipairs(trees)do if t.source then
			local hit=probe(t);if hit then hits[t.id]=hit else missing=t.id end
		end end
		if not missing then return hits end
		assert(clock()<deadline,"Forest terrain unavailable: "..missing)
		pause(.1)
	end
end
return R
