--!nonstrict
-- V1-03 catalog. All economy values are QA-only provisional; never activate for live V8.
-- Every recipe has one named base, required core, and zero-or-one optional modifier.
return {
 classes = {
  {id="novice",name="Новичок",minXP=0},
  {id="apprentice",name="Подмастерье",minXP=3},
  {id="adept",name="Адепт",minXP=10},
  {id="expert",name="Эксперт",minXP=25},
  {id="master",name="Мастер",minXP=60},
  {id="grandmaster",name="Грандмастер",minXP=120},
 },
 quality = {
  {id="awful",name="Отвратительная",factor=55},
  {id="simple",name="Простая",factor=100},
  {id="decent",name="Добротная",factor=120},
  {id="excellent",name="Превосходная",factor=150},
  {id="ideal",name="Идеальная",factor=180},
  {id="masterwork",name="Мастерская",factor=220},
 },
 rarity = {"Обычное","Необычное","Редкое","Эпическое","Легендарное","Мифическое"},
 maxOwned = 80,
 maxSupplies = 200,
 supplies = {
  water={name="Чистая вода",gold=5,kind="base"},
  fire_salt={name="Огненная соль",gold=15,kind="reagent"},
  frost_salt={name="Морозная соль",gold=25,kind="reagent"},
  moon_dew={name="Лунная роса",gold=40,kind="additive"},
  bayun_whisker={name="Усы Баюна",gold=45,kind="additive"},
 },
 recipeOrder={"healing","fire_dance","frost_tincture","moon_echo"},
 recipes={
  healing={
   id="healing",name="Настойка исцеления",class=1,minCauldron=1,
   base={id="water",amount=1},core={mandrake=2},
   optional={id="moon_dew",amount=1,suffix="Лунная роса",effectId="healing_moon_stub",effectDuration=60},
   essence=15,duration=6,goldValue=250,baseEffectId="healing_stub",
   visual={bottle="round",liquid={100,200,145},spark={225,245,192},flash="gentle_glow"},
  },
  fire_dance={
   id="fire_dance",name="Настойка Огненного танца",class=1,minCauldron=1,
   base={id="water",amount=1},core={mandrake=1,fire_salt=1},
   optional={id="bayun_whisker",amount=1,suffix="Искра Баюна",effectId="fire_bayun_stub",effectDuration=80},
   essence=18,duration=10,goldValue=180,baseEffectId="fire_dance_stub",
   visual={bottle="round",liquid={220,133,76},spark={255,190,65},flash="fire_sparks"},
  },
  frost_tincture={
   id="frost_tincture",name="Настойка Северного укуса",class=1,minCauldron=1,
   base={id="water",amount=1},core={antarctic_biter=1,frost_salt=1},
   optional={id="moon_dew",amount=1,suffix="Морозное сияние",effectId="frost_moon_stub",effectDuration=90},
   essence=28,duration=14,goldValue=270,baseEffectId="frost_stub",
   visual={bottle="conical",liquid={110,195,223},spark={198,234,255},flash="ice_shimmer"},
  },
  moon_echo={
   id="moon_echo",name="Настойка Лунного эха",class=2,minCauldron=2,
   base={id="water",amount=2},core={mandrake=1,antarctic_biter=1,moon_dew=1},
   optional={id="bayun_whisker",amount=1,suffix="Голос Баюна",effectId="moon_bayun_stub",effectDuration=120},
   essence=45,duration=28,goldValue=430,baseEffectId="moon_echo_stub",
   visual={bottle="tall",liquid={158,137,213},spark={224,217,255},flash="moon_pulse"},
  },
 },
}