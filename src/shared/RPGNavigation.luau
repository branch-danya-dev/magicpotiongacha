--!nonstrict
-- AG75: cosmetic navigation grouping. Existing station/menu ids and intents stay unchanged.
local Nav={}
local groups={
 inventory={{"inventory","Рюкзак"},{"warehouse","Склад"},{"cauldron","Варка"},
  {"garden","Ферма"},{"supplies","Ресурсы"},{"orders","Заказы"},{"bazaar","Обмен"}},
 character={{"character","Обзор"},{"blueprint","Развитие"},{"rebirth","Перерождение"},
  {"dailies","Награды"},{"shards","Осколки"},{"quality","Графика"},{"shop","Событие"}},
 familiars={{"familiars","Коллекция"},{"altar","Алтарь"}},
}
local groupFor={}
for group,entries in pairs(groups) do
 for _,item in ipairs(entries) do groupFor[item[1]]=group end
end
function Nav.groupFor(id)
 return groupFor[id] or "inventory"
end
function Nav.tabs(group)
 return groups[group] or groups.inventory
end
function Nav.visible(id,selected)
 for _,item in ipairs(Nav.tabs(Nav.groupFor(selected))) do
  if item[1]==id then return true end
 end
 return false
end
function Nav.overview(snapshot)
 local pets=0
 for _ in pairs(snapshot.pets or {}) do pets+=1 end
 return {phase=snapshot.phase and snapshot.phase.name or "—",
  rebirths=snapshot.rebirths or 0,pets=pets,
  gold=math.floor(snapshot.gold or 0),essence=math.floor(snapshot.essence or 0)}
end
return Nav
