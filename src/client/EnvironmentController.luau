--!nonstrict
-- Shared local controller, used by the UI and bootstrap. No save or server call.
local Controller={view=nil,quality="reduced",reduceMotion=false}
function Controller.setQuality(name)
	if not ({full=true,reduced=true,minimal=true})[name] then return end
	Controller.quality=name; if Controller.view then Controller.view.setQuality(name) end
end
function Controller.setReduceMotion(value)
	Controller.reduceMotion=value==true; if Controller.view then Controller.view.setReduceMotion(Controller.reduceMotion) end
end
return Controller
