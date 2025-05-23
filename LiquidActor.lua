--!strict

--[[
	LiquidActor.lua
    MIT License 
    
    	- Howhow, 2025 @ https://github.com/howhow2315
    		"A Roblox Actor that animates an MeshPart to simulate water surface displacement.
				Uses a JONSWAP spectrum for wave motion and a gradient map to visualize wave height."
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Imports
local JONSWAP = require(ReplicatedStorage:WaitForChild("JONSWAP"))
local PixelMap = require(ReplicatedStorage:WaitForChild("PixelMap"))
local GradientMap = require(ReplicatedStorage:WaitForChild("GradientMap"))

-- Types
export type BoneData = {
	Bone: Bone,
	WorldPosition: Vector3
}

export type RiggedPlane = {
	Part: MeshPart, 
	Bones: {[number]: BoneData},
	Texture: Texture
}

type WaveConfig = {
	count: number,
	deltaF: number,
	peakFrequency: number,
	alpha: number,
	gamma: number,
	scale: number
}

type LiquidConfig = {
	Colors: {Color3},
	Position: Vector3,
	Plane: RiggedPlane,
	WaveConfig: WaveConfig,
	Seed: number?,
	WaveScale: number?,
}

-- References
local actor = script:GetActor()

-- Constants
local RENDER_RATE = 1 / (30)

local VERTEX_BASE_ID = 2^32
local NORMAL_BASE_ID = 2 * VERTEX_BASE_ID
local COLOR_BASE_ID = 3 * VERTEX_BASE_ID

-- Initializes the liquid simulation with wave and mesh configuration.
-- This binds the actor to follow a target part and continuously deform the mesh surface.
actor:BindToMessage("Initialize", function(config: LiquidConfig)
	local follow: BasePart
	local waveScale = config.WaveScale or 1

	local plane = config.Plane
	local position = config.Position
	
	local part = plane.Part
	local bones = plane.Bones
	local boneCount = #bones
	local texture = plane.Texture
	
	local width = math.sqrt(boneCount)
	local colorMap = PixelMap.new(Vector2.new(width, width))
	texture.TextureContent = colorMap:GetContent()
	
	local BlendedColor = GradientMap.new(config.Colors)

	local WaveSpectrum = JONSWAP.new(config.WaveConfig, config.Seed, waveScale)
	local peakHeight = WaveSpectrum.PeakHeight * waveScale
	
	-- Transform is faster than setting the position. Convert all bones to transform into local space.
	for _, d in bones do d.Bone.Position = Vector3.zero end

	task.desynchronize()
	
	-- EditableImages use the top-left as 0,0 instead of bottom-left
	local remapped = {}
	for i0 = 0, boneCount do
		local x = i0 % width
		local y = math.floor(i0 / width)

		local flippedY = width - 1 - y
		local index = flippedY * width + x
		
		remapped[i0 + 1] = index
	end
		
	local results: {[number]: Vector3} = table.create(boneCount)
	local colors: {[number]: Color3} = table.create(boneCount)

	local function Update(t: number)
		local ax, az = position.X, position.Z
		if follow then
			local fPos = follow.Position
			ax, az = ax + fPos.X, az + fPos.Z
		end
		
		local partPos = Vector3.new(ax, 0, az)
		if part.Position ~= partPos then -- We should be using welds with counter rotated C0s each RenderStepped but syncing the position update to the compute is a good idea
			part.Position = partPos
		end
		
		task.desynchronize()

		for i = 1, boneCount do
			local d: BoneData = bones[i]
			local pos = d.WorldPosition
			local x, z = pos.X, pos.Z
			
			-- Interpolate vertex displacement and compute world position
			local disp = WaveSpectrum:Sample(t, Vector2.new(x + ax, z + az))
			local height = disp.Y
			local worldPos = Vector3.new(x, 0, z) + disp
			
			local color = BlendedColor:Get(height, peakHeight)
			
			results[i] = worldPos
			colors[i] = color
		end
				
		task.synchronize()
		
		for i = 1, boneCount do
			local d: BoneData = bones[i]
			local bone: Bone = d.Bone
			
			local goal, color = results[i], colors[i]
			bone.Transform = CFrame.new(results[i])
			
			colorMap:WriteColor(remapped[i], color)
		end
		
		colorMap:Refresh()
	end
	
	-- Periodically update the mesh every RENDER_RATE
	local lastUpdate = 0
	local function RenderStep()
		local timestamp = os.clock()
		if timestamp - lastUpdate > RENDER_RATE then
			lastUpdate = timestamp
			--debug.profilebegin("Liquid")
			Update(timestamp)
			--debug.profileend()
		end
	end
	
	-- Allows external scripts to connect, disconnect, or set follow target dynamically
	local connection: RBXScriptConnection?
	local function Connect()
		if not connection then
			connection = RunService.RenderStepped:Connect(RenderStep)
		end
	end

	local function Disconnect()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end
	
	-- Sets a new part for the mesh to follow cause its cool
	local function SetFollowPart(part: BasePart)
		follow = part
	end

	task.synchronize()

	actor:BindToMessage("Connect", Connect)
	actor:BindToMessage("Disconnect", Disconnect)
	actor:BindToMessage("SetFollowPart", SetFollowPart)

	actor:SetAttribute("Ready", true)
end)
actor:SetAttribute("Loaded", true)