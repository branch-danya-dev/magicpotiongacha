--!nonstrict
-- Pure task-06 art layer consumed by EnvironmentState; no owner or clock source.
local Style={skyPrefix="rbxasset://m7task07a-v1/",sunPools={{-171,-88},{-120,-54}},
	pollenAnchors={{-174,-52},{-164,-94},{-118,-58},{-138,-89}}}
local function mix(a,b,t) return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t} end
function Style.apply(r)
	local day=(1-r.night)*(1-r.dawn)*(1-r.warm)
	r.sunlight=(1-r.night)*(1-r.cloud*.9)*(1-r.rain)*(.7+.3*day)
	r.ambient=mix(r.ambient,{112,148,151},day*.5)
	r.outdoor=mix(r.outdoor,{165,185,168},day*.55)
	r.tint=mix(r.tint,{155,181,224},r.night*.60)
	r.brightness=math.min(3,r.brightness*(1+.045*day*(1-r.cloud)))
	r.density=math.clamp(r.density-.035*day*(1-r.cloud)+.02*r.night,.12,.34)
	r.haze=math.max(0,r.haze-.15*day+.18*r.night)
	r.cloudColor=mix(r.cloudColor,{92,118,153},r.night*.72)
	r.fog=math.max(r.fog,.11*r.sunlight)
	r.glint=math.max(r.glint,.22*r.sunlight)
	r.pollen=(.18+.12*r.dawn+.10*r.warm)*(1-r.night)*(1-r.cloud*.55)*(1-r.rain*.9)
	r.diffuse=.46-.08*r.cloud; r.specular=.08+.08*r.wet*(1-r.night)
	r.shadowSoftness=.85; r.saturation=.055-.13*r.cloud-.035*r.night
	return r
end
function Style.wind(sample,time,reduceMotion)
	if reduceMotion then return {strength=0,x=0,z=0} end
	local strength=sample.wind*(.90+.10*math.sin(time*.19))
	local angle=.12*math.sin(time*.027)
	local x,z=4+strength*8,2+strength*3
	return {strength=strength,x=x*math.cos(angle)-z*math.sin(angle),z=x*math.sin(angle)+z*math.cos(angle)}
end
function Style.pollen(index,time,sample,flow)
	local anchor=Style.pollenAnchors[(index-1)%#Style.pollenAnchors+1]
	local firefly=index%3~=0
	local alpha=(sample.pollen*(firefly and .65 or 1)+sample.night*(firefly and .6 or 0))*(1-sample.rain*.9)
	return {x=anchor[1]+math.sin(time*.23+index)*2.2+math.sin(time*.07+index)*flow.x*.12,
		z=anchor[2]+math.cos(time*.19+index)*2+math.sin(time*.07+index)*flow.z*.12,
		y=1.8+(index%5)*.55+math.sin(time*.31+index)*.35,
		alpha=alpha*(.85+.15*math.sin(time*.45+index)),firefly=firefly,anchor=(index-1)%#Style.pollenAnchors+1}
end
function Style.sunSlots(tier) return tier=="full" and 2 or (tier=="minimal" and 0 or 1) end
function Style.sunVisibility(sample,elevation) return sample.sunlight*math.clamp((elevation-.04)/.20,0,1) end
return Style
