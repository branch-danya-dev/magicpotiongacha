--!nonstrict
-- Presentation only. No economy, ownership or saved profile fields.
return {
	version=5,pilotPlot=1,cycleSeconds=1500,weatherSeconds=2100,
	weather={start=900,rise=90,finish=1470,fall=90,buildup=240,clearing=180,afterRain=210},previewSeconds=45,
	-- Original CC0 faces, assigned once; local draft only until experience permissions are verified.
	skyPrefix="rbxasset://m7a2b-v4/",
	polishPrefix="rbxasset://m7a2c-v2/",
	celestial={distance=420,moonSize=44,stars=48},
	palette={grass={141,166,107},sage={99,135,119},leaf={56,92,80},leafLight={153,180,113},
		stone={186,166,138},wood={153,114,77},bark={103,82,61},cream={239,215,170},
		flower={188,159,198},blue={145,189,191},amber={247,197,116},earth={114,115,80}},
	quality={full={distance=240,detail=3,lights=6,rain=60,motion=12,motes=24,shadows=true,bloom=.04,rays=.02,haze=1,fog=3,glints=6,rainbow=1,stars=48},
		reduced={distance=145,detail=2,lights=3,rain=24,motion=4,motes=9,shadows=false,bloom=.012,rays=0,haze=1,fog=2,glints=3,rainbow=1,stars=24},
		minimal={distance=95,detail=1,lights=0,rain=0,motion=0,motes=0,shadows=false,bloom=0,rays=0,haze=1,fog=0,glints=0,rainbow=0,stars=12}},
	keys={
		{phase=0,clock=13.2,brightness=2.6,ambient={122,153,161},outdoor={153,178,182},tint={248,255,247},sky={168,219,218},decay={103,166,181},sun={255,229,183},density=.23,haze=.8,exposure=.05,night=0,dawn=0,warm=0},
		{phase=.30,clock=17.65,brightness=3,ambient={153,140,170},outdoor={195,171,170},tint={255,242,235},sky={255,184,198},decay={232,151,130},sun={255,188,123},density=.28,haze=1.2,exposure=.2,night=.08,dawn=0,warm=1},
		{phase=.39,clock=18.65,brightness=1.9,ambient={111,121,159},outdoor={145,143,186},tint={242,225,255},sky={176,145,203},decay={101,110,161},sun={243,156,182},density=.29,haze=1.0,exposure=.18,night=.6,dawn=0,warm=.35},
		{phase=.51,clock=22.5,brightness=1.45,ambient={97,120,163},outdoor={113,143,183},tint={213,230,255},sky={77,118,169},decay={47,69,120},sun={137,173,236},density=.14,haze=.05,exposure=.2,night=1,dawn=0,warm=0},
		{phase=.70,clock=28.6,brightness=1.5,ambient={100,124,153},outdoor={126,147,172},tint={224,234,255},sky={134,158,193},decay={89,113,156},sun={179,188,231},density=.27,haze=.9,exposure=.2,night=.8,dawn=.25,warm=0},
		{phase=.79,clock=30.15,brightness=2.25,ambient={118,165,157},outdoor={157,192,179},tint={249,239,248},sky={249,207,222},decay={166,200,190},sun={255,217,188},density=.24,haze=.85,exposure=.12,night=.06,dawn=1,warm=.12},
		{phase=1,clock=37.2,brightness=2.6,ambient={122,153,161},outdoor={153,178,182},tint={248,255,247},sky={168,219,218},decay={103,166,181},sun={255,229,183},density=.23,haze=.8,exposure=.05,night=0,dawn=0,warm=0},
	},
	poses={day={phase=0,rain=0},sunset={phase=.30,rain=0},dusk={phase=.39,rain=0},night={phase=.51,rain=0},dawn={phase=.79,rain=0},rain={phase=.08,rain=1},afterrain={phase=.12,rain=0,cloud=.15,wet=.85,afterRain=1}},
	cameras={overview={position={-175,39,-7},target={-145,9,-83}},spawn={position={-141,9,-36},target={-143,7,-96}},
		bazaar={position={-35,20,28},target={0,3,-13}},
		foliage={position={-178,7,-63},target={-191,6,-87}},
		-- Additional diagnostic views only; inherited review cameras stay exact.
		sunset={position={-108,9,-65},target={-220,20,-65}},
		rainbow={position={-175,9,-65},target={-40,35,-65}},
		sky={position={-142,9,-65},target={-142,65,-115}}},
	budgets={parts=850,palette=12,lights=6,rain=60,motion=12,motes=24,fog=3,glints=6,rainbow=1,stars=48,triangles=300000,textureMiB=32},
}
