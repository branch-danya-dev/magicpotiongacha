--!strict
-- Bounded, deterministic cosmetic policy; no currency or gameplay state.
local Policy = {}
Policy.maxBooks = 8
function Policy.quality(name: string, reduceMotion: boolean): any
	local full, minimal = name == "full", name == "minimal"
	return { hz = if full then 30 else if minimal then 10 else 20,
		active = if full then 3 else if minimal then 1 else 2,
		range = if full then 100 else if minimal then 28 else 72,
		motion = not minimal and not reduceMotion,
		idleRate = if minimal or reduceMotion then 0 else if full then 0.6 else 0.2,
		burst = if minimal or reduceMotion then 0 else if full then 6 else 3,
		refill = if full then 12 else 4, pulseSeconds = if reduceMotion then 0.9 else 0.65 }
end
function Policy.sample(t: number, phase: number, motion: boolean): any
	if not motion then return { runeY=0, runeYaw=0, pageY=0, pageRoll=0, glow=1, flame=1 } end
	local ramp = math.clamp(t / 2, 0, 1)
	local pageTime = (t + phase) % 18
	-- One gentle rigid-page lift for four seconds per eighteen; not a page bend.
	local page = if pageTime < 4 then math.sin(pageTime / 4 * math.pi)^2 else 0
	return { runeY=0.10*math.sin(t*0.65+phase)*ramp,
		runeYaw=math.rad(3)*math.sin(t*0.35+phase)*ramp,
		pageY=0.035*page*ramp, pageRoll=math.rad(1.5)*page*ramp,
		glow=0.95+0.05*math.sin(t*0.7+phase),
		flame=0.965+0.02*math.sin(t*2.1)+0.015*math.sin(t*3.7) }
end
function Policy.pulse(now: number, started: number?, duration: number): number
	if not started then return 0 end
	local t = (now-started)/duration
	return if t >= 0 and t < 1 then math.sin(t*math.pi)^2 else 0
end
function Policy.take(tokens: number, elapsed: number, config: any): (number, number)
	local available = math.min(config.burst, tokens + math.max(0,elapsed)*config.refill)
	local count = math.min(config.burst, math.floor(available))
	return available-count, count
end
return Policy
