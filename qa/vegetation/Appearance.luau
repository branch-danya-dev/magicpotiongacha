--!strict
-- Independent material channels; no species admission or gameplay values.
local M={}
M.palettes=({
	Natural={BarkColor={.88,.77,.65},LeafColor={.38,.78,.38},LeafSecondaryColor={.24,.57,.43},MagicGlowColor={.43,.85,1},MagicGlowIntensity=.25},
	Enchanted={BarkColor={.68,.67,.79},LeafColor={.34,.84,.81},LeafSecondaryColor={.66,.42,.83},MagicGlowColor={.40,.70,1},MagicGlowIntensity=.4},
	Blossom={BarkColor={.83,.70,.66},LeafColor={1,.58,.75},LeafSecondaryColor={.76,.35,.60},MagicGlowColor={.86,.57,1},MagicGlowIntensity=.3},
} :: {[string]:any})
function M.resolve(palette:string, overrides:any?):any
	local p:any=assert(M.palettes[palette],"Unknown vegetation palette")
	local out:{[string]:any}={GeometryVariant="Natural",WindStrength=1}
	for k,v in pairs(p)do out[k]=if type(v)=="table" then table.clone(v) else v end
	local changes:{[string]:any}=overrides or {}
	for k,v in pairs(changes)do
		assert(out[k]~=nil,"Unknown appearance control: "..k)
		if string.sub(k,-5)=="Color"then
			assert(type(v)=="table" and #v==3,"RGB triple required")
			for _,n in ipairs(v :: {any})do assert(type(n)=="number" and n==n and n>=0 and n<=1,"Invalid color")end
			out[k]=table.clone(v)
		elseif k=="GeometryVariant"then assert(v=="Natural" or v=="Windswept");out[k]=v
		else assert(type(v)=="number" and v==v and v>=0 and v<=1.5,"Invalid visual strength");out[k]=v end
	end
	return out
end
function M.colorKey(role:string):string?
	return ({Bark="BarkColor",Leaf="LeafColor",LeafSecondary="LeafSecondaryColor",Magic="MagicGlowColor"})[role]
end
return M
