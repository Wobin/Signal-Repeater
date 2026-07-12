--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 11/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local math_floor = math.floor
local string_format = string.format

local Curves = {}

function Curves.interval_at(curve, distance)
	local interval = Curves.piecewise(curve.points, distance)

	if curve.min_interval and interval < curve.min_interval then
		return curve.min_interval
	elseif curve.max_interval and interval > curve.max_interval then
		return curve.max_interval
	end
	return interval
end

function Curves.piecewise(points, distance)
	local n = #points
	if distance <= points[1][1] then return points[1][2] end
	if distance >= points[n][1] then return points[n][2] end

	for i = 1, n - 1 do
		local a, b = points[i], points[i + 1]
		if distance >= a[1] and distance <= b[1] then
			local span = b[1] - a[1]
			local t = span > 0 and (distance - a[1]) / span or 0
			return a[2] + (b[2] - a[2]) * t
		end
	end
	return points[n][2]
end

function Curves.pitch_rate(cents)
	local rate = 2 ^ (cents / 1200)
	return math_floor(rate * 100 + 0.5) / 100
end

function Curves.pitch_filter_string(rate)
	return string_format("asetrate=48000*%.2f,aresample=48000", rate)
end

return Curves
