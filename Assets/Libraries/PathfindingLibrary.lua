local PathfindingLibrary = {}

local Workspace = game:GetService("Workspace")

local PATH_STEP_SIZE = 3
local MAX_SEARCH_DEPTH = 3000
local MAX_SLOPE_HEIGHT = 6
local MAX_DROP_HEIGHT = 8

local function CreateNode(Position, G, H, Parent)
    return {
        Position = Position,
        G = G,
        H = H,
        F = G + H,
        Parent = Parent
    }
end

local function GetKey(Position)
    return math.round(Position.X) .. "," .. math.round(Position.Y) .. "," .. math.round(Position.Z)
end

local function GetNeighbors(Position)
    local Neighbors = {}
    local Offsets = {
        Vector3.new(PATH_STEP_SIZE, 0, 0),
        Vector3.new(-PATH_STEP_SIZE, 0, 0),
        Vector3.new(0, 0, PATH_STEP_SIZE),
        Vector3.new(0, 0, -PATH_STEP_SIZE),
        Vector3.new(PATH_STEP_SIZE, 0, PATH_STEP_SIZE),
        Vector3.new(-PATH_STEP_SIZE, 0, PATH_STEP_SIZE),
        Vector3.new(PATH_STEP_SIZE, 0, -PATH_STEP_SIZE),
        Vector3.new(-PATH_STEP_SIZE, 0, -PATH_STEP_SIZE),
    }

    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude

    for _, offset in ipairs(Offsets) do
        local TargetPos = Position + offset
        
        local RayOrigin = TargetPos + Vector3.new(0, MAX_SLOPE_HEIGHT + 2, 0)
        local RayDir = Vector3.new(0, -MAX_DROP_HEIGHT - MAX_SLOPE_HEIGHT - 4, 0)
        
        local GroundResult = Workspace:Raycast(RayOrigin, RayDir, RayParams)
        
        if GroundResult and GroundResult.Instance and GroundResult.Instance.CanCollide then
            local GroundHit = GroundResult.Position
            local HeightDiff = GroundHit.Y - Position.Y
            
            if HeightDiff <= MAX_SLOPE_HEIGHT and HeightDiff >= -MAX_DROP_HEIGHT then
                
                local HighestY = math.max(Position.Y, GroundHit.Y)
                local LosOrigin = Vector3.new(Position.X, HighestY + 2.5, Position.Z)
                local LosDirection = Vector3.new(GroundHit.X, HighestY + 2.5, GroundHit.Z) - LosOrigin
                local LosResult = Workspace:Raycast(LosOrigin, LosDirection, RayParams)
                
                if not LosResult or not LosResult.Instance.CanCollide then
                    table.insert(Neighbors, GroundHit)
                end
            end
        end
    end
    return Neighbors
end

local function CalculateH(Pos1, Pos2)
    return (Pos1 - Pos2).Magnitude
end

local function SmoothPath(PathArray)
    if not PathArray or #PathArray <= 2 then return PathArray end
    
    local SmoothedPath = {PathArray[1]}
    local CurrentIndex = 1
    
    local RayParams = RaycastParams.new()
    RayParams.FilterType = Enum.RaycastFilterType.Exclude

    while CurrentIndex < #PathArray do
        local FurthestVisibleIndex = CurrentIndex + 1
        
        for i = CurrentIndex + 2, #PathArray do
            local Pos1 = PathArray[CurrentIndex]
            local Pos2 = PathArray[i]
            
            local HighestY = math.max(Pos1.Y, Pos2.Y)
            local LosOrigin = Vector3.new(Pos1.X, HighestY + 2.5, Pos1.Z)
            local LosDirection = Vector3.new(Pos2.X, HighestY + 2.5, Pos2.Z) - LosOrigin
            
            local TargetDist = LosDirection.Magnitude
            if TargetDist > 0 then
                local LosResult = Workspace:Raycast(LosOrigin, LosDirection, RayParams)
                if not LosResult or not LosResult.Instance.CanCollide then
                    local IsValid = true
                    local Steps = math.ceil(TargetDist / PATH_STEP_SIZE)
                    for step = 1, Steps - 1 do
                        local Fraction = step / Steps
                        local Interp = Pos1:Lerp(Pos2, Fraction)
                        local CheckOrigin = Vector3.new(Interp.X, HighestY + 2.5, Interp.Z)
                        local CheckDir = Vector3.new(0, -MAX_DROP_HEIGHT - MAX_SLOPE_HEIGHT - 6, 0)
                        local CheckRay = Workspace:Raycast(CheckOrigin, CheckDir, RayParams)
                        
                        if not CheckRay or not CheckRay.Instance.CanCollide then
                            IsValid = false
                            break
                        end
                        
                        local ExpectedY = Pos1.Y + (Pos2.Y - Pos1.Y) * Fraction
                        if math.abs(CheckRay.Position.Y - ExpectedY) > MAX_SLOPE_HEIGHT + 1 then
                            IsValid = false
                            break
                        end
                    end
                    
                    if IsValid then
                        FurthestVisibleIndex = i
                    else
                        break
                    end
                else
                    break
                end
            end
        end
        
        table.insert(SmoothedPath, PathArray[FurthestVisibleIndex])
        CurrentIndex = FurthestVisibleIndex
    end
    
    return SmoothedPath
end

function PathfindingLibrary.ComputePath(StartPos, EndPos)
    local OpenList = {}
    local NodeMap = {}
    local ClosedList = {}
    
    local StartG = 0
    local StartH = CalculateH(StartPos, EndPos)
    local StartNode = CreateNode(StartPos, StartG, StartH, nil)
    
    table.insert(OpenList, StartNode)
    NodeMap[GetKey(StartPos)] = StartNode
    
    local Iterations = 0
    
    while #OpenList > 0 do
        Iterations = Iterations + 1
        if Iterations > MAX_SEARCH_DEPTH then
            warn("PathfindingLibrary: Max search depth reached.")
            return nil
        end
        
        local CurrentIndex = 1
        local CurrentNode = OpenList[1]
        
        for i = 2, #OpenList do
            if OpenList[i].F < CurrentNode.F then
                CurrentNode = OpenList[i]
                CurrentIndex = i
            end
        end
        
        if (CurrentNode.Position - EndPos).Magnitude <= PATH_STEP_SIZE * 1.5 then
            local Path = {}
            local Trace = CurrentNode
            while Trace do
                table.insert(Path, 1, Trace.Position)
                Trace = Trace.Parent
            end
            table.insert(Path, EndPos)
            return SmoothPath(Path)
        end
        
        OpenList[CurrentIndex] = OpenList[#OpenList]
        OpenList[#OpenList] = nil
        
        local CurrentKey = GetKey(CurrentNode.Position)
        NodeMap[CurrentKey] = nil
        ClosedList[CurrentKey] = true
        
        for _, NeighborPos in ipairs(GetNeighbors(CurrentNode.Position)) do
            local RoundedPosStr = GetKey(NeighborPos)
            
            if not ClosedList[RoundedPosStr] then
                local GScore = CurrentNode.G + (NeighborPos - CurrentNode.Position).Magnitude
                local OpenNode = NodeMap[RoundedPosStr]
                
                if OpenNode then
                    if GScore < OpenNode.G then
                        OpenNode.G = GScore
                        OpenNode.F = GScore + OpenNode.H
                        OpenNode.Parent = CurrentNode
                    end
                else
                    local HScore = CalculateH(NeighborPos, EndPos)
                    local NewNode = CreateNode(NeighborPos, GScore, HScore, CurrentNode)
                    table.insert(OpenList, NewNode)
                    NodeMap[RoundedPosStr] = NewNode
                end
            end
        end
    end
    
    warn("PathfindingLibrary: No valid path found.")
    return nil
end

function PathfindingLibrary.VisualizePath(PathArray, Duration, Color)
    if not PathArray or #PathArray < 2 then return end
    Duration = Duration or 5
    Color = Color or Color3.new(1, 0, 0)
    
    local VisualCache = {}
    
    for i = 1, #PathArray - 1 do
        local StartPt = PathArray[i]
        local EndPt = PathArray[i+1]
        
        local Distance = (StartPt - EndPt).Magnitude
        
        local Part = Instance.new("Part")
        Part.Anchored = true
        Part.CanCollide = false
        Part.Material = Enum.Material.Neon
        Part.Color = Color
        Part.Size = Vector3.new(0.5, 0.5, Distance)
        Part.CFrame = CFrame.lookAt(StartPt, EndPt) * CFrame.new(0, 0, -Distance / 2)
        Part.Parent = Workspace
        
        table.insert(VisualCache, Part)
    end
    
    task.spawn(function()
        task.wait(Duration)
        for _, obj in ipairs(VisualCache) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
    end)
    
    return VisualCache
end

return PathfindingLibrary
