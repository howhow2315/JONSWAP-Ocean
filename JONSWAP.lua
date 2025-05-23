--!native
--!optimize 2
--!strict

--[[
	JONSWAP.lua
    MIT License 
    
    	- Howhow, 2025 @ https://github.com/howhow2315
    		"A wave field generator using the JONSWAP spectral model"
]]

-- Mapped functions
local sin, cos = math.sin, math.cos
local exp, sqrt = math.exp, math.sqrt
local abs = math.abs

-- Constants
local pi = math.pi
local TAU = 2 * pi
local g = 9.81

local g2 = g * g

local B = 4 / pi
local C = -4 / (pi * pi)

-- Types
export type Wave = {number} -- {k: number, omega: number, A: number, phase: number, dx: number, dz: number}

export type WaveMap = {
	Waves: {Wave},
	PeakHeight: number,
	Sample: (self: WaveMap, t: number, pos: Vector2) -> Vector3
}

export type WaveConfig = {
	count: number,
	deltaF: number,
	peakFrequency: number,
	alpha: number,
	gamma: number,
	scale: number
}

-- ^ runs math.pow which is slower than direct multiplication, technically this isn't full efficiency
local function pow2(n: number): number
	return n * n
end

-- The biggest cost in sampling is using sin, this is 
-- Approximate sine using a cubic (faster than Taylor and decent quality)
local function fastSin(x: number): number
	x = x % TAU
	if x > pi then
		x = x - TAU
	end

	local y = B * x + C * x * abs(x)

	-- Optional smoothing (adds cost, improves quality. Not required here)
	--local P = 0.225
	--y = P * (y * math.abs(y) - y) + y

	return y
end

local function fastCos(x: number): number
	return fastSin(x + pi / 2)
end

-- Calculates spectral energy density for a given frequency using the JONSWAP formula.
-- Returns the energy magnitude at that frequency, modulated by peak sharpening factor (gamma).
local function jonswap(frequency: number, peakFrequency: number, gamma: number, alpha: number): number
	local sigma = frequency <= peakFrequency and 0.07 or 0.09
	local r = exp(-pow2(frequency - peakFrequency) / (2 * pow2(sigma) * pow2(peakFrequency)))

	local S_pm = alpha * g2 * (TAU)^(-4) * frequency^(-5) * exp(-1.25 * (peakFrequency / frequency)^4)
	return S_pm * gamma^r
end

-- Evaluates the displacement vector at a given position and time by summing the contribution of all waves.
-- Each wave uses its direction, amplitude, and phase to influence the local surface height and normal.
local function sampleDisplacement(waves: {Wave}, t: number, pos: Vector2): Vector3
	local sx, sy, sz = 0, 0, 0

	local x, z = pos.X, pos.Y

	for i = 1, #waves do
		local w = waves[i]
		local k, omega, A, phase, dx, dz = w[1], w[2], w[3], w[4], w[5], w[6]

		-- Project the world position onto the wave direction vector
		local dot = dx * x + dz * z

		-- Compute the phase offset for this wave at (x, z, t)
		local phi = k * dot - omega * t + phase

		local sinF = fastSin(phi)
		local cosF = fastCos(phi)

		-- Lateral displacement magnitude along x/z direction
		local AcosF = A * cosF

		sx += dx * AcosF
		sy += A * sinF
		sz += dz * AcosF
	end

	return Vector3.new(sx, sy, sz)
end

-- Generates a WaveMap using randomized wave directions and parameters derived from the JONSWAP spectrum.
-- Returns a list of waves and a sampling function for evaluating displacement at any position and time.
local function generateWaves(config: WaveConfig, seed: number?, scale: number?): WaveMap
	local rng = Random.new(seed or os.clock())

	local count = config.count or 32
	local deltaF = config.deltaF or 0.02
	local fp = config.peakFrequency or 0.13
	local alpha = config.alpha or 0.0081
	local gamma = config.gamma or 3.3
	local s = config.scale or 1

	local waves: {Wave} = table.create(count)
	local totalAmplitude = 0

	for i = 1, count do
		local f = i * deltaF
		local omega = TAU * f
		local S = jonswap(f, fp, gamma, alpha)
		local A = sqrt(2 * S * deltaF) * s
		totalAmplitude += A

		-- Random wave direction angle (in radians)
		local theta = rng:NextNumber(0, TAU)

		local dx = cos(theta)
		local dz = sin(theta)
		local phase = rng:NextNumber(0, TAU)

		-- Compute wave number k using the deep water dispersion relation
		local k = pow2(TAU * f) / g

		waves[i] = {k, omega, A * (scale or 1), phase, dx, dz}
	end

	return {
		Waves = waves,
		PeakHeight = totalAmplitude / 2, -- Should be tA but for visuals I recommend tweaking this
		Sample = function(self: WaveMap, t: number, pos: Vector2): Vector3
			return sampleDisplacement(waves, t, pos)
		end
	}
end

return {
	JONSWAP = jonswap,
	SampleDisplacement = sampleDisplacement,
	new = generateWaves,
}
