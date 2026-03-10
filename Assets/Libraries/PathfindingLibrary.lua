local PathfindingLibrary = {}

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local DEFAULT_CONFIG = {
	StepSize = 3,
	MaxSearchDepth = 5000,
	MaxSlopeHeight = 6,
	MaxDropHeight = 8,
	AgentRadius = 2.5, 
	AgentHeight = 5,
	YieldInterval = 200,
	RaycastFilter = nil,
	SmoothPath = true,
}

local Heap = {}
Heap.__index = Heap

function Heap.new()
	return setmetatable({ _data = {}, _size = 0 }, Heap)
end

function Heap:Push(node)
	self._size = self._size + 1
	self._data[self._size] = node
	local i = self._size
	local data = self._data
	while i > 1 do
		local parent = math.floor(i / 2)
		if data[i].F < data[parent].F then
			data[i], data[parent] = data[parent], data[i]
			i = parent
		else
			break
		end
	end
end

function Heap:Pop()
	local data = self._data
	local top = data[1]
	data[1] = data[self._size]
	data[self._size] = nil
	self._size = self._size - 1
	local i = 1
	while true do
		local left = 2 * i
		local right = left + 1
		local smallest = i
		if left <= self._size and data[left].F < data[smallest].F then
			smallest = left
		end
		if right <= self._size and data[right].F < data[smallest].F then
			smallest = right
		end
		if smallest == i then break end
		data[i], data[smallest] = data[smallest], data[i]
		i = smallest
	end
	return top
end

function Heap:IsEmpty()
	return self._size == 0
end

local function MergeConfig(overrides)
	if not overrides then return DEFAULT_CONFIG end
	local cfg = {}
	for k, v in pairs(DEFAULT_CONFIG) do
		cfg[k] = v
	end
	for k, v in pairs(overrides) do
		cfg[k] = v
	end
	return cfg
end

local function GetKey(pos)
	return math.round(pos.X) .. "," .. math.round(pos.Y) .. "," .. math.round(pos.Z)
end

local function CreateNode(pos, g, h, parent)
	return {
		Position = pos,
		G = g,
		H = h,
		F = g + h,
		Parent = parent,
	}
end

local SQRT2 = math.sqrt(2)
local function OctileH(a, b, stepSize)
	local dx = math.abs(a.X - b.X)
	local dy = math.abs(a.Y - b.Y)
	local dz = math.abs(a.Z - b.Z)
	local dFlat1 = math.min(dx, dz)
	local dFlat2 = math.max(dx, dz)
	return (SQRT2 * dFlat1 + (dFlat2 - dFlat1) + dy)
end

local function MakeRayParams(cfg)
	if cfg.RaycastFilter then return cfg.RaycastFilter end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	return rp
end

local function FindGround(x, z, refY, cfg, rayParams)
	local roofY = refY + cfg.MaxSlopeHeight + 2
	local origin = Vector3.new(x, roofY, z)
	local dir = Vector3.new(0, -(cfg.MaxDropHeight + cfg.MaxSlopeHeight + 4), 0)
	local result = Workspace:Raycast(origin, dir, rayParams)
	if result and result.Instance and result.Instance.CanCollide then
		return result.Position
	end
	return nil
end

local function HasClearance(from, to, cfg, rayParams)
	local highY = math.max(from.Y, to.Y) + 2.5
	local dir2D = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local mag = dir2D.Magnitude
	if mag < 0.01 then return true end

	local forward = dir2D.Unit
	local right = Vector3.new(forward.Z, 0, -forward.X)

	local offsets = {
		Vector3.zero,
		right * (cfg.AgentRadius * 0.8),
		right * (-cfg.AgentRadius * 0.8),
	}

	for _, offset in ipairs(offsets) do
		local origin = Vector3.new(from.X, highY, from.Z) + offset
		local target = Vector3.new(to.X, highY, to.Z) + offset
		local losDir = target - origin
		local losResult = Workspace:Raycast(origin, losDir, rayParams)
		if losResult and losResult.Instance.CanCollide then
			return false
		end
	end
	return true
end

local NEIGHBOR_OFFSETS_UNIT = {
	Vector3.new(1, 0, 0),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(0, 0, -1),
	Vector3.new(1, 0, 1).Unit,
	Vector3.new(-1, 0, 1).Unit,
	Vector3.new(1, 0, -1).Unit,
	Vector3.new(-1, 0, -1).Unit,
}

local function GetNeighbors(pos, cfg, rayParams)
	local neighbors = {}
	local step = cfg.StepSize

	for _, unitDir in ipairs(NEIGHBOR_OFFSETS_UNIT) do
		local offset = unitDir * step
		local targetX = pos.X + offset.X
		local targetZ = pos.Z + offset.Z

		local ground = FindGround(targetX, targetZ, pos.Y, cfg, rayParams)
		if ground then
			local heightDiff = ground.Y - pos.Y
			if heightDiff <= cfg.MaxSlopeHeight and heightDiff >= -cfg.MaxDropHeight then
				if HasClearance(pos, ground, cfg, rayParams) then
					table.insert(neighbors, ground)
				end
			end
		end
	end
	return neighbors
end

local function SmoothPath(pathArray, cfg, rayParams)
	if not pathArray or #pathArray <= 2 then return pathArray end

	local smoothed = { pathArray[1] }
	local cur = 1

	while cur < #pathArray do
		local best = cur + 1

		for i = #pathArray, cur + 2, -1 do
			local p1 = pathArray[cur]
			local p2 = pathArray[i]

			if not HasClearance(p1, p2, cfg, rayParams) then
				continue
			end
			local dist = (Vector3.new(p2.X, 0, p2.Z) - Vector3.new(p1.X, 0, p1.Z)).Magnitude
			local steps = math.ceil(dist / cfg.StepSize)
			local valid = true

			for s = 1, steps - 1 do
				local frac = s / steps
				local interp = p1:Lerp(p2, frac)
				local ground = FindGround(interp.X, interp.Z, math.max(p1.Y, p2.Y), cfg, rayParams)
				if not ground then
					valid = false
					break
				end
				local expectedY = p1.Y + (p2.Y - p1.Y) * frac
				if math.abs(ground.Y - expectedY) > cfg.MaxSlopeHeight + 1 then
					valid = false
					break
				end
			end

			if valid then
				best = i
				break
			end
		end

		table.insert(smoothed, pathArray[best])
		cur = best
	end

	return smoothed
end

function PathfindingLibrary.ComputePath(startPos, endPos, config)
	local cfg = MergeConfig(config)
	local rayParams = MakeRayParams(cfg)

	local startGround = FindGround(startPos.X, startPos.Z, startPos.Y, cfg, rayParams)
	local endGround = FindGround(endPos.X, endPos.Z, endPos.Y, cfg, rayParams)
	if not startGround then
		warn("PathfindingLibrary: Could not find ground at start position.")
		return nil
	end
	if not endGround then
		warn("PathfindingLibrary: Could not find ground at end position.")
		return nil
	end

	local openHeap = Heap.new()
	local nodeMap = {}
	local closedSet = {}

	local startH = OctileH(startGround, endGround, cfg.StepSize)
	local startNode = CreateNode(startGround, 0, startH, nil)
	local startKey = GetKey(startGround)

	openHeap:Push(startNode)
	nodeMap[startKey] = startNode

	local iterations = 0
	local goalRadius = cfg.StepSize * 1.5

	while not openHeap:IsEmpty() do
		iterations = iterations + 1
		if iterations > cfg.MaxSearchDepth then
			warn("PathfindingLibrary: Max search depth reached (" .. cfg.MaxSearchDepth .. " iterations).")
			return nil
		end

		if cfg.YieldInterval > 0 and iterations % cfg.YieldInterval == 0 then
			if RunService:IsClient() then
				RunService.Heartbeat:Wait()
			else
				task.wait()
			end
		end

		local current = openHeap:Pop()
		local currentKey = GetKey(current.Position)

		if closedSet[currentKey] then continue end
		closedSet[currentKey] = true
		nodeMap[currentKey] = nil

		if (current.Position - endGround).Magnitude <= goalRadius then
			local path = {}
			local trace = current
			while trace do
				table.insert(path, 1, trace.Position)
				trace = trace.Parent
			end
			if (path[#path] - endGround).Magnitude > 0.5 then
				table.insert(path, endGround)
			end
			if cfg.SmoothPath then
				path = SmoothPath(path, cfg, rayParams)
			end
			return path
		end
		for _, neighborPos in ipairs(GetNeighbors(current.Position, cfg, rayParams)) do
			local nKey = GetKey(neighborPos)
			if closedSet[nKey] then continue end

			local gScore = current.G + (neighborPos - current.Position).Magnitude

			local existing = nodeMap[nKey]
			if existing then
				if gScore < existing.G then
					existing.G = gScore
					existing.F = gScore + existing.H
					existing.Parent = current
					openHeap:Push(existing)
				end
			else
				local hScore = OctileH(neighborPos, endGround, cfg.StepSize)
				local newNode = CreateNode(neighborPos, gScore, hScore, current)
				openHeap:Push(newNode)
				nodeMap[nKey] = newNode
			end
		end
	end

	warn("PathfindingLibrary: No valid path found.")
	return nil
end

function PathfindingLibrary.VisualizePath(pathArray, duration, color)
	if not pathArray or #pathArray < 2 then return end
	duration = duration or 5
	color = color or Color3.new(1, 0, 0)

	local cache = {}

	for i = 1, #pathArray - 1 do
		local a = pathArray[i]
		local b = pathArray[i + 1]
		local dist = (a - b).Magnitude

		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Size = Vector3.new(0.5, 0.5, dist)
		part.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -dist / 2)
		part.Parent = Workspace

		table.insert(cache, part)

		local sphere = Instance.new("Part")
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.Material = Enum.Material.Neon
		sphere.Color = color
		sphere.Shape = Enum.PartType.Ball
		sphere.Size = Vector3.new(1.2, 1.2, 1.2)
		sphere.CFrame = CFrame.new(a)
		sphere.Parent = Workspace
		table.insert(cache, sphere)
	end

	task.spawn(function()
		task.wait(duration)
		for _, obj in ipairs(cache) do
			if obj and obj.Parent then
				obj:Destroy()
			end
		end
	end)

	return cache
end

return PathfindingLibrary
