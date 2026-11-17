--!nonstrict
-- Pure local optical layer plan. Never owns time, Lighting or wind.
local M={candidateScale=1.5,haloScale=1.75}
local function smooth(x) x=math.clamp(x,0,1);return x*x*(3-2*x) end
function M.scaleValid(n) return n==1 or n==1.35 or n==1.5 end
function M.haloAlpha(radius,style)
	if style=="before" then return (1-smooth((radius-.35)/.65))^2 end
	-- Strictly decreasing radial scattering, no bright annulus.
	return math.exp(-4*radius*radius)*(1-smooth((radius-.75)/.25))
end
return M
