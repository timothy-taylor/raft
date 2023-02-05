local wave = {}

wave.counter = 1
wave.spd = 8

function wave.increment()
	wave.counter = (wave.counter + 1) % 5
end

function wave.randomize(max)
	wave.spd = math.random(6, max)
end

return wave
