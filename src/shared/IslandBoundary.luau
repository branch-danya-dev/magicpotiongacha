--!nonstrict
-- Technical traversal boundary, not art rollout. The contour leaves the padded
-- eight-plot/road/bazaar footprint open and stops traversal into outer ridges.
local Boundary={bottom=-48,top=80,thickness=2,
	points={{-222,-98},{-202,-128},{202,-128},{222,-98},{222,118},{202,150},{-202,150},{-222,118}}}
function Boundary.segments()
	local result={}
	for i,a in ipairs(Boundary.points) do
		local b=Boundary.points[i%#Boundary.points+1]
		table.insert(result,{a=a,b=b,length=math.sqrt((b[1]-a[1])^2+(b[2]-a[2])^2)})
	end
	return result
end
function Boundary.contains(x,z,margin)
	margin=margin or 0
	for _,s in ipairs(Boundary.segments()) do
		if ((s.b[1]-s.a[1])*(z-s.a[2])-(s.b[2]-s.a[2])*(x-s.a[1]))/s.length<margin then return false end
	end
	return true
end
return Boundary
