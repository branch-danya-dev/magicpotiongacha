--!nonstrict
-- Studio-only expanded woodland. Fixed authored banks, no random runtime scatter.
local F={width=184,depth=172,rx=87,rz=81,centerZ=-8}
function F.margin(x,z)
	local a=math.atan2((z+8)/F.rz,x/F.rx)
	return (1+.10*math.sin(a*5)+.035*math.cos(a*7)-math.sqrt((x/F.rx)^2+((z+8)/F.rz)^2))*math.min(F.rx,F.rz)
end
function F.island(base)
	local i=table.clone(base);i.surface=table.clone(base.surface)
	i.surface.width=F.width;i.surface.depth=F.depth
	function i.surfaceContains(x,z,m)
		m=m or 0
		if type(x)~="number" or type(z)~="number" or type(m)~="number" or x~=x or z~=z or m~=m or m<0 then return false end
		if math.abs(x)==math.huge or math.abs(z)==math.huge then return false end
		return F.margin(x,z)>=m
	end
	return i
end
F.routes={{{-39,20},{-69,20}},{{39,14},{77,14}},{{0,30},{0,62}},{{8,-46},{8,-74}}}
local function segment(x,z,a,b)
	local dx,dz=b[1]-a[1],b[2]-a[2]
	local t=math.clamp(((x-a[1])*dx+(z-a[2])*dz)/(dx*dx+dz*dz),0,1)
	return math.sqrt((x-a[1]-t*dx)^2+(z-a[2]-t*dz)^2)
end
function F.path(x,z,r)
	for _,s in ipairs(F.routes)do if segment(x,z,s[1],s[2])<3+(r or 0)then return true end end
	return false
end
-- Species code, X, Z, scale, yaw. Two staggered depths, interrupted by paths
-- and the northern World Tree view. Crowns may overlap each other, never the core.
F.rows={
	{"N",-54,-47,.78,22},{"W",-60,-30,.84,133},{"N",-57,-9,.88,238},
	{"P",-54,8,.65,41},{"W",-57,32,.79,72},{"C",-43,44,.82,163},
	{"N",-72,-46,1.00,67},{"P",-69,-28,.88,161},{"W",-77,-8,.98,291},
	{"M",-77,10,.64,34},{"N",-72,35,.94,212},{"P",-63,33,.72,84},
	{"W",-34,53,.90,321},{"N",-20,51,.81,170},{"P",-23,67,.70,12},
	{"C",-9,48,.77,246},{"W",13,49,.86,109},{"M",27,63,.58,267},
	{"N",43,48,.95,61},{"P",34,54,.68,154},{"W",60,39,.94,225},
	{"N",55,27,.80,31},{"P",57,0,.71,116},{"W",57,-19,.85,281},
	{"N",55,-42,.84,199},{"M",65,-32,.61,111},{"W",78,-13,1.02,8},
	{"N",77,3,.94,178},{"P",78,28,.77,69},{"N",64,-58,.91,147},
	{"P",48,-69,.92,297},{"W",42,-58,.83,202},{"N",42,-76,.98,38},
	{"C",36,-58,.72,141},{"P",-16,-65,.76,92},{"W",-31,-62,.84,312},
	{"N",-23,-80,.96,122},{"M",-46,-73,.58,258},{"P",-57,-63,.83,4},
	{"C",-67,3,.73,192},{"C",66,-6,.78,44},{"N",-41,-82,.83,277},
	{"N",55,-75,.86,63},{"C",-40,-62,.74,188},{"P",66,-42,.77,251},
	{"C",-66,-56,.72,50},{"W",-48,36,.77,119},{"C",34,43,.76,303},
}
function F.apply(P,config,island,geometry,legacyLayout)
	-- The base instance is private to this candidate; its audits close over P.
	local formerCover=P.cover
	P.trees={};P.cover={};P.stones={};P.groveRoute={{-39,20},{-69,20}}
	P.terrainMargin=F.margin
	function P.inPilot(x,z)
		for _,t in ipairs(P.trees)do if (t.x-x)^2+(t.z-z)^2<(t.radius+1)^2 then return true end end
		return false
	end
	-- The authored 48-tree stand replaces the former canopy, not all low plants.
	P.keepTrees=function()return {} end
	P.tones.shade={bark={.62,.58,.49},leaf={.24,.48,.29},secondary={.20,.39,.28},flower={.69,.73,.70}}
	P.tones.edge={bark={.72,.64,.51},leaf={.35,.56,.29},secondary={.26,.44,.25},flower={.84,.78,.60}}
	P.tones.arcane={bark={.58,.57,.62},leaf={.32,.52,.51},secondary={.36,.40,.56},flower={.64,.72,.83}}
	P.budgets={full={hz=24,distance=155,trees=8,scale=1},reduced={hz=12,distance=110,trees=4,scale=.7},minimal={hz=5,distance=65,trees=1,scale=.3}}
	function P.windBudgets(source)
		local out={};for q,b in pairs(P.budgets)do out[q]=table.clone(b)
			out[q].trees=source=="magic_igor" and (q=="full" and 2 or q=="reduced" and 1 or 0) or (q=="full" and 6 or q=="reduced" and 3 or 1)
		end;return out
	end
	for n,v in ipairs(F.rows)do
		local t={id=string.format("forest-%02d",n),x=v[2],z=v[3],scale=v[4],yaw=v[5],tone=n%3==0 and "edge" or "shade",wind=.48+(n%4)*.10}
		if v[1]=="P" or v[1]=="C" then
			t.template=v[1]=="P" and "Pine_2" or "CommonTree_5";t.radius=geometry[t.template].radius*t.scale+.12
		else
			t.source=v[1]=="M" and "magic_igor" or "stylized_stefan";t.variant=v[1]=="W" and "Windswept" or "Natural"
			t.radius=(v[1]=="M" and 22.4 or v[1]=="W" and 14.0 or 11.0)*t.scale+.12
			if v[1]=="M"then t.magic=true;t.tone="arcane"end
		end
		table.insert(P.trees,t)
	end
	local function add(list,v)
		local r=geometry[v[1]].radius*v[4]
		if F.path(v[2],v[3],r)then return end
		local a=P.auditDressing(config,island,geometry,list==P.cover and {v} or {},list==P.stones and {v} or {})
		if a.ok then table.insert(list,v)end
	end
	-- Understory follows each fixed bank in asymmetric pockets. Every accepted
	-- footprint is tested against the core, stations, paths and irregular shore.
	for n,t in ipairs(P.trees)do
		for j,offset in ipairs({{-4,-2},{3,-4},{-1,5},{5,2}})do
			local x,z=t.x+offset[1],t.z+offset[2]
			local name=j==1 and "Bush_Common_Flowers" or j==2 and "Fern_1" or j==3 and "Grass_Common_Short" or "Flower_3_Group"
			local scale=j==1 and (.80+(n%3)*.11) or j==2 and (.62+(n%3)*.08) or j==3 and 1.1 or .85
			add(P.cover,{name,x,z,scale,(n*47+j*71)%360,t.tone,j<=2 and 1 or 2})
		end
		if n%2==0 then add(P.stones,{"Rock_Medium_1",t.x+3,t.z+1,.6+(n%3)*.12,n*37%360,"mossStone",1,-.18})end
	end
	P.legacyCover={}
	local dressingBudget=P.auditDressing(config,island,geometry)
	local function restore(v)
		local g=geometry[v[1]];local r=g.radius*v[4]
		if dressingBudget.parts+#g.parts>300 or dressingBudget.triangles+g.triangles>70000 then return end
		if F.path(v[2],v[3],r)then return end
		for _,t in ipairs(P.trees)do if (v[2]-t.x)^2+(v[3]-t.z)^2<(r+1.4)^2 then return end end
		for _,p in ipairs(P.cover)do
			local gap=(r+geometry[p[1]].radius*p[4])*.7
			if (v[2]-p[2])^2+(v[3]-p[3])^2<gap*gap then return end
		end
		local before=#P.cover;add(P.cover,v)
		if #P.cover>before then
			table.insert(P.legacyCover,v);dressingBudget.parts+=#g.parts;dressingBudget.triangles+=g.triangles
		end
	end
	for _,v in ipairs(formerCover)do restore(v)end
	-- Preserve eligible old cluster positions, then validate each child footprint.
	-- The build adapter removes their old writer; Setup owns each survivor once.
	for n,c in ipairs(P.keepClusters(legacyLayout and legacyLayout.clusters or {}))do
		restore({"Bush_Common_Flowers",c[1],c[2],.90+(n%3)*.13,n*41,"shade",1})
		for j=1,5 do
			local a=j*2.39996;local r=1.8+j*.65
			local name=j%3==0 and "Fern_1" or (j%2==0 and "Grass_Wispy_Tall" or "Clover_2")
			restore({name,c[1]+math.cos(a)*r,c[2]+math.sin(a)*r,name=="Clover_2" and 2.7 or .8,n*27+j*29,"shade",2})
		end
	end
	return P
end
return F
