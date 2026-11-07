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
export type Target = { id: any, disabled: boolean? }

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

function Interact.handoff(order: { Target }, current: any): any
	local index = 0
	for cursor, item in ipairs(order) do
		if item.id == current then
			index = cursor
			break
		end
	end
	local function enabled(item: Target): boolean
		return item.disabled ~= true
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
