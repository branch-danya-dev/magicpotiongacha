--!strict
-- One primary window at a time. Each window owns its animation keys and close generation.
local Windows = {}

export type Keys = { group: string, scale: string }
export type Ticket = { id: string, generation: number, keys: Keys, focus: string? }

local function keys(id: string): Keys
	return { group = id .. ":group", scale = id .. ":scale" }
end

function Windows.dismiss(keyCode: string): boolean
	return keyCode == "Escape" or keyCode == "ButtonB"
end

function Windows.new()
	local generation: { [string]: number } = {}
	local savedFocus: { [string]: string? } = {}
	local openId: string? = nil
	local dismiss = 0
	local self = {}

	function self.keys(id: string): Keys
		return keys(id)
	end

	function self.isOpen(id: string): boolean
		return openId == id
	end

	function self.current(): string?
		return openId
	end

	function self.count(): number
		return if openId ~= nil then 1 else 0
	end

	function self.listeners(): number
		return dismiss
	end

	function self.close(id: string): Ticket
		generation[id] = (generation[id] or 0) + 1
		local focus = savedFocus[id]
		if openId == id then
			openId = nil
			dismiss = 0
		end
		return { id = id, generation = generation[id], keys = keys(id), focus = focus }
	end

	function self.open(id: string, focus: string?): (Ticket, Ticket?)
		local displaced: Ticket? = nil
		if openId ~= nil and openId ~= id then
			displaced = self.close(openId)
		end
		if openId ~= id then
			savedFocus[id] = focus
			openId = id
			dismiss = 1
		end
		generation[id] = (generation[id] or 0) + 1
		return {
			id = id,
			generation = generation[id],
			keys = keys(id),
			focus = savedFocus[id],
		}, displaced
	end

	function self.shouldHide(id: string, token: number): boolean
		return openId ~= id and generation[id] == token
	end

	return self
end

return Windows
