local PathfindingLibrary = {}

local Workspace = game:GetService("Workspace")

local PATH_STEP_SIZE = 4
local MAX_SEARCH_DEPTH = 1500
local MAX_SLOPE_HEIGHT = 4
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

    for _, offset in ipairs(Offsets) do
        local TargetPos = Position + offset
        
        local RayOrigin = TargetPos + Vector3.new(0, MAX_SLOPE_HEIGHT + 2, 0)
        local RayParams = RaycastParams.new()
        RayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local GroundResult = Workspace:Raycast(RayOrigin, Vector3.new(0, -MAX_DROP_HEIGHT - MAX_SLOPE_HEIGHT - 4, 0), RayParams)
        
        if GroundResult and GroundResult.Instance and GroundResult.Instance.CanCollide then
            local GroundHit = GroundResult.Position
            local HeightDiff = GroundHit.Y - Position.Y
            
            if HeightDiff <= MAX_SLOPE_HEIGHT and HeightDiff >= -MAX_DROP_HEIGHT then
                
                local LosOrigin = Position + Vector3.new(0, 2, 0)
                local LosDirection = (GroundHit + Vector3.new(0, 2, 0)) - LosOrigin
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

function PathfindingLibrary.ComputePath(StartPos, EndPos)
    local OpenList = {}
    local ClosedList = {}
    
    local StartG = 0
    local StartH = CalculateH(StartPos, EndPos)
    local StartNode = CreateNode(StartPos, StartG, StartH, nil)
    
    table.insert(OpenList, StartNode)
    
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
            return Path
        end
        
        table.remove(OpenList, CurrentIndex)
        ClosedList[tostring(Vector3.new(math.round(CurrentNode.Position.X), math.round(CurrentNode.Position.Y), math.round(CurrentNode.Position.Z)))] = true
        
        for _, NeighborPos in ipairs(GetNeighbors(CurrentNode.Position)) do
            local RoundedPosStr = tostring(Vector3.new(math.round(NeighborPos.X), math.round(NeighborPos.Y), math.round(NeighborPos.Z)))
            
            if not ClosedList[RoundedPosStr] then
                local GScore = CurrentNode.G + (NeighborPos - CurrentNode.Position).Magnitude
                local HScore = CalculateH(NeighborPos, EndPos)
                
                local InOpenList = false
                local OpenIndex = -1
                for i, OpenNode in ipairs(OpenList) do
                    if tostring(Vector3.new(math.round(OpenNode.Position.X), math.round(OpenNode.Position.Y), math.round(OpenNode.Position.Z))) == RoundedPosStr then
                        InOpenList = true
                        OpenIndex = i
                        break
                    end
                end
                
                if InOpenList then
                    if GScore < OpenList[OpenIndex].G then
                        OpenList[OpenIndex].G = GScore
                        OpenList[OpenIndex].F = GScore + OpenList[OpenIndex].H
                        OpenList[OpenIndex].Parent = CurrentNode
                    end
                else
                    local NewNode = CreateNode(NeighborPos, GScore, HScore, CurrentNode)
                    table.insert(OpenList, NewNode)
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
