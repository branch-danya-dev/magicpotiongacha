--!strict
-- Durations stay in one place. Reduce Motion collapses them to an instant change.
local Motion = {}

export type Track = { generation: number, kind: string, duration: number }

local seconds: { [string]: number } = {
	hover = 0.15,
	press = 0.10,
	open = 0.22,
	close = 0.15,
}

function Motion.seconds(kind: string, reduceMotion: boolean?): number
	if reduceMotion == true then
		return 0
	end
	return seconds[kind] or 0
end

function Motion.track(): Track
	return { generation = 0, kind = "idle", duration = 0 }
end

function Motion.begin(track: Track, kind: string, reduceMotion: boolean?): number
	track.generation += 1
	track.kind = kind
	track.duration = Motion.seconds(kind, reduceMotion)
	return track.generation
end

function Motion.current(track: Track, generation: number): boolean
	return track.generation == generation
end

return Motion
