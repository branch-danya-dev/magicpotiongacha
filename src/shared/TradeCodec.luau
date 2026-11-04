--!nonstrict
-- Canonical server snapshots and SHA-256 labels. Full canonical equality, not just
-- a client hash, is checked before reservation. No secret/client authority here.
local Codec={}
function Codec.copy(v: any): any
	if type(v)~="table" then return v end
	local r={}; for k,x in pairs(v) do r[k]=Codec.copy(x) end; return r
end
function Codec.encode(v: any): string
	local t=type(v)
	if t=="nil" then return "n" elseif t=="boolean" then return v and "t" or "f"
	elseif t=="number" then assert(v==v and math.abs(v)<math.huge); return "d"..string.format("%.17g",v)..";"
	elseif t=="string" then return "s"..#v..":"..v end
	assert(t=="table" and getmetatable(v)==nil,"invalid snapshot")
	local keys={}; for k in pairs(v) do assert(type(k)=="string" or type(k)=="number"); table.insert(keys,k) end
	table.sort(keys,function(a,b) return Codec.encode(a)<Codec.encode(b) end)
	local result={"{"}; for _,k in ipairs(keys) do table.insert(result,Codec.encode(k)..Codec.encode(v[k])) end
	table.insert(result,"}"); return table.concat(result)
end
local K={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
local xor,band,ror,rshift=bit32.bxor,bit32.band,bit32.rrotate,bit32.rshift
local function bytes(n) return string.char(rshift(n,24),band(rshift(n,16),255),band(rshift(n,8),255),band(n,255)) end
function Codec.sha256(message)
	local length=#message*8
	message=message.."\128"..string.rep("\0",(55-#message)%64)..bytes(math.floor(length/2^32))..bytes(length%2^32)
	local h={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
	for base=1,#message,64 do
		local w={}
		for i=0,15 do local a,b,c,d=string.byte(message,base+i*4,base+i*4+3); w[i+1]=a*2^24+b*2^16+c*256+d end
		for i=17,64 do
			local a,b=w[i-15],w[i-2]
			w[i]=(w[i-16]+xor(ror(a,7),ror(a,18),rshift(a,3))+w[i-7]+xor(ror(b,17),ror(b,19),rshift(b,10)))%2^32
		end
		local a,b,c,d,e,f,g,j=table.unpack(h)
		for i=1,64 do
			local t1=(j+xor(ror(e,6),ror(e,11),ror(e,25))+xor(band(e,f),band(bit32.bnot(e),g))+K[i]+w[i])%2^32
			local t2=(xor(ror(a,2),ror(a,13),ror(a,22))+xor(band(a,b),band(a,c),band(b,c)))%2^32
			j,g,f,e,d,c,b,a=g,f,e,(d+t1)%2^32,c,b,a,(t1+t2)%2^32
		end
		for i,v in ipairs({a,b,c,d,e,f,g,j}) do h[i]=(h[i]+v)%2^32 end
	end
	local result={}; for _,v in ipairs(h) do table.insert(result,string.format("%08x",v)) end; return table.concat(result)
end
function Codec.hash(v) return Codec.sha256(Codec.encode(v)) end
return Codec
