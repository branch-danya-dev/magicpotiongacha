--!strict
-- One resolution order for every interactive control.
local Interact = {}

export type Flags = {
	disabled: boolean?,
	pressed: boolean?,
	hover: boolean?,
	focused: boolean?,
	selected: boolean?,
}
export type Visual = { state: string, scale: number, textTransparency: number }
export type Marks = { selected: boolean, focused: boolean, selectable: boolean }
export type Target = {
	id: any,
	disabled: boolean?,
	present: boolean?,
	mounted: boolean?,
	visible: boolean?,
	ancestorsVisible: boolean?,
	selectable: boolean?,
	window: string?,
	prefer: boolean?,
}

function Interact.resolve(flags: Flags): string
	if flags.disabled == true then
		return "Disabled"
	end
	if flags.pressed == true then
		return "Pressed"
	end
	if flags.focused == true then
		return "Focused"
	end
	if flags.selected == true then
		return "Selected"
	end
	if flags.hover == true then
		return "Hover"
	end
	return "Default"
end

function Interact.marks(flags: Flags): Marks
	local disabled = flags.disabled == true
	return {
		selected = flags.selected == true and not disabled,
		focused = flags.focused == true and not disabled,
		selectable = not disabled,
	}
end

function Interact.selectable(flags: Flags): boolean
	return Interact.marks(flags).selectable
end

function Interact.inputKind(name: string): string
	if string.sub(name, 1, 7) == "Gamepad" then
		return "Gamepad"
	end
	if name == "Touch" then
		return "Touch"
	end
	return "Mouse"
end

function Interact.claimsFocus(kind: string): boolean
	return kind == "Gamepad"
end

function Interact.available(candidate: Target?, openWindow: string?): boolean
	if type(candidate) ~= "table" then
		return false
	end
	if candidate.present == false or candidate.mounted == false then
		return false
	end
	if candidate.visible == false or candidate.ancestorsVisible == false then
		return false
	end
	if candidate.disabled == true or candidate.selectable == false then
		return false
	end
	if candidate.window ~= nil and candidate.window ~= openWindow then
		return false
	end
	return true
end

function Interact.handoff(order: { Target }, current: any, openWindow: string?): any
	local index = 0
	for cursor, item in ipairs(order) do
		if item.id == current then
			index = cursor
			break
		end
	end
	local function enabled(item: Target): boolean
		return Interact.available(item, openWindow)
	end
	if index == 0 then
		for _, item in ipairs(order) do
			if enabled(item) then
				return item.id
			end
		end
		return nil
	end
	for cursor = index + 1, #order do
		if enabled(order[cursor]) then
			return order[cursor].id
		end
	end
	for cursor = index - 1, 1, -1 do
		if enabled(order[cursor]) then
			return order[cursor].id
		end
	end
	return nil
end

function Interact.restore(previous: Target?, order: { Target }, openWindow: string?): any
	if previous == nil then
		return nil
	end
	if Interact.available(previous, openWindow) then
		return previous.id
	end
	for _, item in ipairs(order) do
		if Interact.available(item, openWindow) then
			return item.id
		end
	end
	return nil
end

function Interact.firstInside(order: { Target }, windowId: string): any
	local reserve = nil
	for _, item in ipairs(order) do
		if item.window == windowId and Interact.available(item, windowId) then
			if item.prefer == false then
				if reserve == nil then
					reserve = item.id
				end
			else
				return item.id
			end
		end
	end
	return reserve
end

function Interact.visual(state: string, reduceMotion: boolean?): Visual
	local scale = 1
	if state == "Pressed" and reduceMotion ~= true then
		scale = 0.97
	end
	return {
		state = state,
		scale = scale,
		textTransparency = state == "Disabled" and 0.4 or 0,
	}
end

return Interact
