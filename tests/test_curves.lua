-- standalone luajit test: the pure distance maths, asserted against the real measurements.
local Curves = dofile("mods/Signal Repeater/scripts/mods/Signal Repeater/core/Curves.lua")

local function close(a, b, tol, what)
	assert(math.abs(a - b) <= tol, string.format("%s: got %.4f want %.4f (tol %.4f)", what, a, b, tol))
end

-- The poxburster tick delay, read verbatim out of the beep's own Wwise bank: a Linear RTPC
-- curve (0m, 0.030s) -> (50m, 1.500s). These asserts pin OUR reading of the bank against the
-- timings stopwatched in-game, so a mistranscribed point cannot slip through.
local RAMP = { points = { { 0, 0.03 }, { 50, 1.5 } }, min_interval = 0.12 }
local MEASURED = {
	-- distance, seconds-per-tick. Counts are ticks-spanning-time, so N ticks = N-1 intervals.
	{ 38.8, 10.00 / 9 },
	{ 14.3, 8.38 / 19 },
	{ 12.4, 8.38 / 19 },
	{ 9.1, 6.02 / 19 },
	{ 6.0, 4.15 / 19 },
}
for _, m in ipairs(MEASURED) do
	local d, want = m[1], m[2]
	local got = Curves.interval_at(RAMP, d)
	assert(math.abs(got - want) / want <= 0.12,
		string.format("bank tick curve at %.1fm: got %.3fs vs measured %.3fs (>12%% off)", d, got, want))
end

-- Exact endpoints of the bank curve.
close(Curves.interval_at(RAMP, 50), 1.5, 1e-9, "bank far endpoint")
close(Curves.interval_at(RAMP, 25), 0.765, 1e-6, "linear interpolation mid-curve")

-- Clamps: the fast end holds at the constant-tone spacing (the loop takes over there), and
-- the curve is flat beyond its last point rather than running away.
close(Curves.interval_at(RAMP, 1), 0.12, 1e-9, "min clamp near zero")
assert(Curves.interval_at(RAMP, 0) == 0.12, "zero distance is safe")
close(Curves.interval_at(RAMP, 500), 1.5, 1e-9, "flat beyond the last point")

-- Monotonic: further away must never tick faster.
local prev = 0
for d = 1, 60 do
	local i = Curves.interval_at(RAMP, d)
	assert(i >= prev - 1e-9, "interval must not decrease with distance at " .. d .. "m")
	prev = i
end

-- The constant-tone loop takes over where its own 0.12s spacing matches the curve, so the
-- handover does not audibly change speed.
close(Curves.interval_at(RAMP, 3.0), 0.12, 0.008, "loop handover distance matches loop spacing")

-- Piecewise pitch curve, straight from the bank.
local PITCH = { { 0, 400 }, { 8, 115 }, { 50, -200 } }
close(Curves.piecewise(PITCH, 0), 400, 1e-9, "pitch at 0m")
close(Curves.piecewise(PITCH, 8), 115, 1e-9, "pitch at 8m")
close(Curves.piecewise(PITCH, 50), -200, 1e-9, "pitch at 50m")
close(Curves.piecewise(PITCH, 4), 257.5, 0.01, "pitch interpolates mid-segment")
close(Curves.piecewise(PITCH, -5), 400, 1e-9, "pitch flat below the first point")
close(Curves.piecewise(PITCH, 999), -200, 1e-9, "pitch flat beyond the last point")

-- Cents -> playback rate (quantised, so a walking enemy does not respin the FFmpeg graph).
close(Curves.pitch_rate(0), 1.0, 1e-9, "0 cents = unity rate")
close(Curves.pitch_rate(1200), 2.0, 1e-9, "+1200 cents = one octave up")
close(Curves.pitch_rate(-1200), 0.5, 1e-9, "-1200 cents = one octave down")
close(Curves.pitch_rate(400), 1.26, 0.005, "+400 cents (burster at 0m)")
close(Curves.pitch_rate(-200), 0.89, 0.005, "-200 cents (burster at 50m)")
assert(Curves.pitch_filter_string(1.26) == "asetrate=48000*1.26,aresample=48000", "filter string shape")

print("test_curves OK")
