--!nonstrict
-- Presentation only. No economy, ownership or saved profile fields.
return {
	version=2,pilotPlot=1,cycleSeconds=1500,weatherSeconds=2100,
	palette={grass={141,166,107},sage={99,135,119},leaf={56,92,80},leafLight={153,180,113},
		stone={186,166,138},wood={153,114,77},bark={103,82,61},cream={239,215,170},
		flower={188,159,198},blue={145,189,191},amber={247,197,116},earth={114,115,80}},
	quality={full={distance=240,detail=3,lights=6,rain=60,motion=12,shadows=true,bloom=0.12},
		reduced={distance=145,detail=2,lights=3,rain=24,motion=4,shadows=false,bloom=0.06},
		minimal={distance=95,detail=1,lights=0,rain=0,motion=0,shadows=false,bloom=0}},
	keys={
		{phase=0,clock=13.2,brightness=2.5,ambient={123,133,139},outdoor={154,169,164},tint={255,249,234},sky={190,218,225},density=.22,haze=.8,bloom=.10},
		{phase=.30,clock=17.4,brightness=2.1,ambient={139,119,126},outdoor={180,151,124},tint={255,231,205},sky={237,196,164},density=.29,haze=1.5,bloom=.14},
		{phase=.51,clock=21.5,brightness=1.2,ambient={98,113,143},outdoor={119,137,163},tint={213,227,255},sky={117,146,182},density=.27,haze=1.1,bloom=.16},
		{phase=.79,clock=30.2,brightness=1.8,ambient={141,125,143},outdoor={173,159,164},tint={255,229,232},sky={223,198,208},density=.30,haze=1.3,bloom=.12},
		{phase=1,clock=37.2,brightness=2.5,ambient={123,133,139},outdoor={154,169,164},tint={255,249,234},sky={190,218,225},density=.22,haze=.8,bloom=.10},
	},
	poses={day={phase=0,rain=0},sunset={phase=.30,rain=0},night={phase=.51,rain=0},dawn={phase=.79,rain=0},rain={phase=.08,rain=1}},
	cameras={overview={position={-175,39,-7},target={-145,9,-83}},spawn={position={-141,9,-36},target={-143,7,-96}},
		bazaar={position={-35,20,28},target={0,3,-13}},
		foliage={position={-178,7,-63},target={-191,6,-87}}},
	budgets={parts=650,palette=12,lights=6,rain=60,motion=12,triangles=150000,textureMiB=32},
}
