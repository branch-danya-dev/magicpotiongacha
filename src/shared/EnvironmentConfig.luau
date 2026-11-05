--!nonstrict
-- Presentation only. No economy, ownership or saved profile fields.
return {
	version=3,pilotPlot=1,cycleSeconds=1500,weatherSeconds=2100,
	weather={start=900,rise=90,finish=1470,fall=90},previewSeconds=45,
	palette={grass={141,166,107},sage={99,135,119},leaf={56,92,80},leafLight={153,180,113},
		stone={186,166,138},wood={153,114,77},bark={103,82,61},cream={239,215,170},
		flower={188,159,198},blue={145,189,191},amber={247,197,116},earth={114,115,80}},
	quality={full={distance=240,detail=3,lights=6,rain=60,motion=12,motes=24,shadows=true,bloom=.045,rays=.025,haze=1},
		reduced={distance=145,detail=2,lights=3,rain=24,motion=4,motes=9,shadows=false,bloom=.015,rays=0,haze=.8},
		minimal={distance=95,detail=1,lights=0,rain=0,motion=0,motes=0,shadows=false,bloom=0,rays=0,haze=.55}},
	keys={
		{phase=0,clock=13.2,brightness=2.7,ambient={136,149,169},outdoor={164,177,187},tint={255,253,244},sky={194,222,238},decay={135,166,191},sun={255,221,170},density=.26,haze=1.2,exposure=.1,night=0},
		{phase=.30,clock=16.7,brightness=3.0,ambient={170,137,153},outdoor={212,167,140},tint={255,239,222},sky={255,200,185},decay={210,153,167},sun={255,162,78},density=.25,haze=1.0,exposure=.3,night=.15},
		{phase=.51,clock=21.5,brightness=1.8,ambient={157,177,221},outdoor={176,195,231},tint={231,241,255},sky={128,167,223},decay={99,130,191},sun={145,179,249},density=.34,haze=2.0,exposure=.4,night=1},
		{phase=.79,clock=30.2,brightness=2.4,ambient={171,155,184},outdoor={206,176,196},tint={255,237,248},sky={246,199,220},decay={198,164,200},sun={255,203,174},density=.31,haze=1.7,exposure=.3,night=.12},
		{phase=1,clock=37.2,brightness=2.7,ambient={136,149,169},outdoor={164,177,187},tint={255,253,244},sky={194,222,238},decay={135,166,191},sun={255,221,170},density=.26,haze=1.2,exposure=.1,night=0},
	},
	poses={day={phase=0,rain=0},sunset={phase=.30,rain=0},night={phase=.51,rain=0},dawn={phase=.79,rain=0},rain={phase=.08,rain=1}},
	cameras={overview={position={-175,39,-7},target={-145,9,-83}},spawn={position={-141,9,-36},target={-143,7,-96}},
		bazaar={position={-35,20,28},target={0,3,-13}},
		foliage={position={-178,7,-63},target={-191,6,-87}}},
	budgets={parts=650,palette=12,lights=6,rain=60,motion=12,motes=24,triangles=150000,textureMiB=32},
}
