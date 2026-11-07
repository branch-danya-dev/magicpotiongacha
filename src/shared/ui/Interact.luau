--!strict
-- One resolution order for every interactive control.
local Interact = {}

export type Flags = { disabled: boolean?, pressed: boolean?, hover: boolean?, focused: boolean? }
export type Visual = { state: string, scale: number, textTransparency: number }

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
	if flags.hover == true then
		return "Hover"
	end
	return "Default"
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
