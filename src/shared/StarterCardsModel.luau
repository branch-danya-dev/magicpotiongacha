--!nonstrict
-- AG75: pure first-session presentation; never decides or grants a familiar.
local Model={}
local labels={farmer="ВЫРАЩИВАНИЕ",slime="ПЕРЕНОСКА",brewer="АЛХИМИЯ"}
local descriptions={farmer="Помогает выращивать ингредиенты",slime="Переносит ресурсы между станциями",brewer="Ускоряет приготовление зелий"}
local icons={farmer="owl",slime="slime",brewer="cat"}
local colors={farmer={161,218,159},slime={120,219,179},brewer={202,166,245}}
function Model.intro(snapshot)
	return type(snapshot)=="table" and type(snapshot.starter)=="table"
		and snapshot.starter.legacyGrant~=true and snapshot.starter.claimed~=true
end
function Model.ready(snapshot,pending)
	return Model.intro(snapshot) and snapshot.writable==true and pending~=true
end
function Model.cards(config)
	local cards={}
	for _,pet in ipairs(config.starterPets) do
		assert(labels[pet.species] and icons[pet.species],"Unknown canonical starter")
		table.insert(cards,{id=pet.species,name=pet.name,title=labels[pet.species],
			description=descriptions[pet.species],icon=icons[pet.species],
			color=colors[pet.species],stats=pet.stats})
	end
	return cards
end
function Model.layout(width,height,confirmation)
	local portrait=width<height
	local small=height<460
	local gap=small and 12 or 22
	local w=math.max(220,math.min(284,(width-46-gap*2)/3))
	local h=math.min(420,math.max(200,height-(small and 104 or 176)))
	if portrait then w=math.min(340,width-36); h=math.max(310,math.min(390,height*.63)) end
	if confirmation then w=math.min(340,width-36); h=math.max(200,math.min(435,height-(small and 100 or 156))) end
	local scrollHorizontal=not portrait and not confirmation and 3*w+2*gap>width-24
	return {portrait=portrait,small=small,width=w,height=h,gap=gap,
		top=small and 64 or math.max(110,(height-h)*.40),scroll=(portrait or scrollHorizontal) and not confirmation,
		scrollHorizontal=scrollHorizontal}
end
return Model
