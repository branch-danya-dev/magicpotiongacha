--!strict
-- Tracks one mounted surface so a second open cannot stack listeners.
local Host = {}

export type Surface = {
	mount: () -> boolean,
	track: (release: () -> ()) -> boolean,
	unmount: () -> boolean,
	mounted: () -> boolean,
	listeners: () -> number,
}

function Host.new(): Surface
	local mounted = false
	local releases: { () -> () } = {}
	local surface = {} :: Surface
	function surface.mount(): boolean
		if mounted then
			return false
		end
		mounted = true
		return true
	end
	function surface.track(release: () -> ()): boolean
		if not mounted then
			return false
		end
		table.insert(releases, release)
		return true
	end
	function surface.unmount(): boolean
		if not mounted then
			return false
		end
		for index = #releases, 1, -1 do
			local release = releases[index]
			releases[index] = nil
			release()
		end
		mounted = false
		return true
	end
	function surface.mounted(): boolean
		return mounted
	end
	function surface.listeners(): number
		return #releases
	end
	return surface
end

return Host
