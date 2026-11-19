--!strict
local M={}
function M.summary(values:{number})
	assert(#values>0);local sorted=table.clone(values);table.sort(sorted)
	local sum=0;local stalls,stallMs,over33=0,0,0
	for _,v in ipairs(values)do sum+=v;if v>100 then stalls+=1;stallMs+=v end;if v>33.333 then over33+=1 end end
	return {n=#values,median=sorted[math.ceil(#values*.5)],p95=sorted[math.ceil(#values*.95)],p99=sorted[math.ceil(#values*.99)],max=sorted[#sorted],mean=sum/#values,
		stallsOver100=stalls,stallMs=stallMs,framesOver33=over33}
end
return M
