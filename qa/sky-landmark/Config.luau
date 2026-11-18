--!strict
return {
	revision=3,
	-- Fixed world coordinates. Sizes are studs AFTER the alpha-aware UV crops.
	-- No camera/FOV change or screen-following position.
	offset={510,1150,-5175},canvas={9000,8000},maxDistance=16000,
	tree={size={6400,2920},offset={0,0},scale=1,atmosphericFade=.12},
	cloud={size={6750,2500},offset={0,-2070},scale=1,density=.94,opacity=.96,
		sectors=8,radius=5200,driftX=65,driftY=10,edgeBankOpacity=.82},
	glow={size={7350,3520},offset={0,130},scale=1,intensity=.72},
	haze={size={6900,1600},offset={0,-1320},opacity=.065},
	-- Three masks reuse the existing Tree image; only the upper mask survives Minimal.
	quality={full={hz=30,layers=15},reduced={hz=15,layers=13},minimal={hz=5,layers=10}},
	textureBytes=6553600,imageCount=4,maxInstances=45,
}
