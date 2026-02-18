local Silicon = loadstring(game:HttpGet("https://api.siliconxploits.xyz/notify"))()

local Rayfield = loadstring(game:HttpGet("https://api.siliconxploits.xyz/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "Silicon for Flick",
    Icon = 124780615486303,
    LoadingTitle = "Welcome...",
    LoadingSubtitle = "by 5xy",
    Theme = {
        TextColor = Color3.fromRGB(230,230,230), Background = Color3.fromRGB(15,15,15),
        Topbar = Color3.fromRGB(18,18,18), Shadow = Color3.fromRGB(0,100,199),
        NotificationBackground = Color3.fromRGB(28,30,34), NotificationActionsBackground = Color3.fromRGB(23,25,28),
        TabBackground = Color3.fromRGB(40,45,55), TabStroke = Color3.fromRGB(50,55,65),
        TabBackgroundSelected = Color3.fromRGB(0,120,215), TabTextColor = Color3.fromRGB(180,185,195),
        SelectedTabTextColor = Color3.fromRGB(255,255,255), ElementBackground = Color3.fromRGB(28,30,35),
        ElementBackgroundHover = Color3.fromRGB(45,50,60), SecondaryElementBackground = Color3.fromRGB(0,79,144),
        ElementStroke = Color3.fromRGB(55,60,70), SecondaryElementStroke = Color3.fromRGB(50,55,65),
        SliderBackground = Color3.fromRGB(0,120,215), SliderProgress = Color3.fromRGB(0,120,215),
        SliderStroke = Color3.fromRGB(0,120,215), ToggleBackground = Color3.fromRGB(30,32,36),
        ToggleEnabled = Color3.fromRGB(0,120,215), ToggleDisabled = Color3.fromRGB(120,120,125),
        ToggleEnabledStroke = Color3.fromRGB(0,120,215), ToggleDisabledStroke = Color3.fromRGB(140,140,145),
        ToggleEnabledOuterStroke = Color3.fromRGB(0,120,215), ToggleDisabledOuterStroke = Color3.fromRGB(85,85,90),
        DropdownSelected = Color3.fromRGB(35,80,105), DropdownUnselected = Color3.fromRGB(30,35,40),
        InputBackground = Color3.fromRGB(28,28,30), InputStroke = Color3.fromRGB(50,55,65),
        PlaceholderColor = Color3.fromRGB(170,170,180)
    },
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {Enabled = false}
})

Silicon:Notify({Title = "Welcome!", Content = "Enjoy your experience!"})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local UserTab = Window:CreateTab("User", "user")
local AimTab = Window:CreateTab("Aim", "crosshair")

UserTab:CreateParagraph({
    Title = "Welcome to Silicon!", 
    Content = "You are using Silicon for Flick."
})

UserTab:CreateDivider()

UserTab:CreateSection("ESP")

local ESPEnabled = false
local BoxEnabled = false
local BoxStyle = "Full"
local TracerEnabled = false
local TracerOrigin = "Bottom"
local HealthEnabled = false
local HealthStyle = "Bar"
local SkeletonEnabled = false
local SkeletonColor = Color3.fromRGB(255,255,255)
local SkeletonThickness = 1.5
local SkeletonTransparency = 0.8
local ESP = {}

local function ClearESP(plr)
    if ESP[plr] then
        for _, obj in pairs(ESP[plr]) do
            if typeof(obj) == "table" then
                for _, v in ipairs(obj) do if v then v.Visible = false v:Remove() end end
            elseif obj then obj.Visible = false obj:Remove() end
        end
        ESP[plr] = nil
    end
end

local function CreateESP(plr)
    if plr == LocalPlayer then return end
    ClearESP(plr)
    local d = {
        BoxLines = {},
        Tracer = Drawing.new("Line"),
        HealthBG = Drawing.new("Square"),
        HealthFG = Drawing.new("Square"),
        Skeleton = {}
    }
    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        table.insert(d.BoxLines, line)
    end
    d.Tracer.Thickness = 2
    d.HealthBG.Filled = true
    d.HealthBG.Color = Color3.new(0,0,0)
    d.HealthBG.Transparency = 0.5
    d.HealthFG.Filled = true
    d.HealthFG.Color = Color3.new(0,1,0)
    for i = 1, 14 do
        local line = Drawing.new("Line")
        line.Thickness = SkeletonThickness
        line.Color = SkeletonColor
        line.Transparency = SkeletonTransparency
        table.insert(d.Skeleton, line)
    end
    ESP[plr] = d
end

local function WorldToScreen(pos)
    local s, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(s.X, s.Y), on and s.Z > 0
end

local function GetBox(char)
    local min, max = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
    local onScreen = false
    for _, p in char:GetChildren() do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            local pos, vis = WorldToScreen(p.Position)
            if vis then
                onScreen = true
                min = Vector2.new(math.min(min.X, pos.X), math.min(min.Y, pos.Y))
                max = Vector2.new(math.max(max.X, pos.X), math.max(max.Y, pos.Y))
            end
        end
    end
    if not onScreen then return nil end
    return {Pos = min, Size = max - min, Width = max.X - min.X, Height = max.Y - min.Y}
end

local function UpdateSkeleton(char, d)
    if not char then return end
    local head = char:FindFirstChild("Head")
    local upper = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local lower = char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")
    local larm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
    local lfore = char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Arm")
    local lhand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
    local rarm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    local rfore = char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Arm")
    local rhand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    local lleg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
    local lshin = char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")
    local lfoot = char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg")
    local rleg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
    local rshin = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")
    local rfoot = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg")

    local function draw(i, p1, p2)
        local line = d.Skeleton[i]
        if line and p1 and p2 and p1.Parent and p2.Parent then
            local s1, v1 = WorldToScreen(p1.Position)
            local s2, v2 = WorldToScreen(p2.Position)
            if v1 and v2 then
                line.From = s1
                line.To = s2
                line.Visible = SkeletonEnabled
                line.Color = SkeletonColor
                line.Thickness = SkeletonThickness
                line.Transparency = SkeletonTransparency
                return
            end
        end
        if line then line.Visible = false end
    end

    draw(1, head, upper)
    draw(2, upper, lower)
    draw(3, upper, larm)
    draw(4, larm, lfore)
    draw(5, lfore, lhand)
    draw(6, upper, rarm)
    draw(7, rarm, rfore)
    draw(8, rfore, rhand)
    draw(9, lower, lleg)
    draw(10, lleg, lshin)
    draw(11, lshin, lfoot)
    draw(12, lower, rleg)
    draw(13, rleg, rshin)
    draw(14, rshin, rfoot)
end

local function GetTracerOrigin()
    if TracerOrigin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif TracerOrigin == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif TracerOrigin == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

RunService.RenderStepped:Connect(function()
    if not ESPEnabled then
        for plr,_ in pairs(ESP) do ClearESP(plr) end
        return
    end
    for plr, d in pairs(ESP) do
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or not root or hum.Health <= 0 then
            ClearESP(plr) continue
        end
        local box = GetBox(char)
        if not box then
            for _, v in pairs(d) do
                if typeof(v) == "table" then for _, x in ipairs(v) do x.Visible = false end
                else v.Visible = false end
            end
            continue
        end
        local color = Color3.fromRGB(255, 0, 0)
        local hp = hum.Health / hum.MaxHealth
        local rootPos, rootVis = WorldToScreen(root.Position)
        if BoxEnabled then
            for i = 1, #d.BoxLines do d.BoxLines[i].Visible = false end
            if BoxStyle == "Corner" then
                local len = box.Width * 0.15
                local b = box.Pos
                local br = b + Vector2.new(box.Width, box.Height)
                d.BoxLines[1].From = b d.BoxLines[1].To = b + Vector2.new(len, 0) d.BoxLines[1].Visible = true
                d.BoxLines[2].From = b + Vector2.new(box.Width, 0) d.BoxLines[2].To = b + Vector2.new(box.Width - len, 0) d.BoxLines[2].Visible = true
                d.BoxLines[3].From = b + Vector2.new(0, box.Height) d.BoxLines[3].To = b + Vector2.new(len, box.Height) d.BoxLines[3].Visible = true
                d.BoxLines[4].From = br d.BoxLines[4].To = br - Vector2.new(len, 0) d.BoxLines[4].Visible = true
                d.BoxLines[5].From = b d.BoxLines[5].To = b + Vector2.new(0, len) d.BoxLines[5].Visible = true
                d.BoxLines[6].From = b + Vector2.new(box.Width, 0) d.BoxLines[6].To = b + Vector2.new(box.Width, len) d.BoxLines[6].Visible = true
                d.BoxLines[7].From = b + Vector2.new(0, box.Height) d.BoxLines[7].To = b + Vector2.new(0, box.Height - len) d.BoxLines[7].Visible = true
                d.BoxLines[8].From = br d.BoxLines[8].To = br - Vector2.new(0, len) d.BoxLines[8].Visible = true
            elseif BoxStyle == "Full" then
                local tl = box.Pos
                local tr = box.Pos + Vector2.new(box.Width, 0)
                local bl = box.Pos + Vector2.new(0, box.Height)
                local br = box.Pos + Vector2.new(box.Width, box.Height)
                d.BoxLines[1].From = tl d.BoxLines[1].To = bl d.BoxLines[1].Visible = true
                d.BoxLines[2].From = tr d.BoxLines[2].To = br d.BoxLines[2].Visible = true
                d.BoxLines[3].From = tl d.BoxLines[3].To = tr d.BoxLines[3].Visible = true
                d.BoxLines[4].From = bl d.BoxLines[4].To = br d.BoxLines[4].Visible = true
            end
            for _, line in ipairs(d.BoxLines) do
                if line.Visible then
                    line.Color = color
                    line.Thickness = 2
                end
            end
        end
        if TracerEnabled and rootVis then
            d.Tracer.From = GetTracerOrigin()
            d.Tracer.To = rootPos
            d.Tracer.Color = color
            d.Tracer.Visible = true
        else
            d.Tracer.Visible = false
        end
        if HealthEnabled then
            local barW = 3
            local barH = box.Height * 0.7
            local barX = box.Pos.X - barW - 4
            local barY = box.Pos.Y + (box.Height - barH) / 2
            d.HealthBG.Position = Vector2.new(barX, barY)
            d.HealthBG.Size = Vector2.new(barW, barH)
            d.HealthBG.Visible = true
            d.HealthFG.Position = Vector2.new(barX, barY + barH * (1 - hp))
            d.HealthFG.Size = Vector2.new(barW, barH * hp)
            d.HealthFG.Color = Color3.fromHSV(hp * 0.33, 1, 1)
            d.HealthFG.Visible = true
        else
            d.HealthBG.Visible = false
            d.HealthFG.Visible = false
        end
        UpdateSkeleton(char, d)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled and plr ~= LocalPlayer then CreateESP(plr) end
    end)
end)

Players.PlayerRemoving:Connect(ClearESP)

for _, plr in Players:GetPlayers() do
    if plr ~= LocalPlayer then
        if plr.Character then CreateESP(plr) end
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if ESPEnabled then CreateESP(plr) end
        end)
    end
end

UserTab:CreateToggle({
    Name = "ESP Enabled",
    CurrentValue = false,
    Callback = function(value)
        ESPEnabled = value
        if value then
            Silicon:Notify({
                Title = "ESP",
                Content = "ESP has been enabled."
            })
            for _, player in Players:GetPlayers() do
                if player ~= LocalPlayer and player.Character then
                    CreateESP(player)
                end
            end
        else
            Silicon:Notify({
                Title = "ESP",
                Content = "ESP has been disabled."
            })
            for plr, _ in pairs(ESP) do
                ClearESP(plr)
            end
        end
    end
})

UserTab:CreateDivider()

UserTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = false,
    Callback = function(value)
        BoxEnabled = value
    end
})

UserTab:CreateDropdown({
    Name = "Box Style",
    Options = {"Full", "Corner"},
    CurrentOption = {"Full"},
    Callback = function(option)
        BoxStyle = option[1]
    end
})

UserTab:CreateDivider()

UserTab:CreateToggle({
    Name = "Tracer ESP",
    CurrentValue = false,
    Callback = function(value)
        TracerEnabled = value
    end
})

UserTab:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Top", "Mouse", "Center"},
    CurrentOption = {"Bottom"},
    Callback = function(option)
        TracerOrigin = option[1]
    end
})

UserTab:CreateDivider()

UserTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = false,
    Callback = function(value)
        HealthEnabled = value
    end
})

UserTab:CreateDivider()

UserTab:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = false,
    Callback = function(value)
        SkeletonEnabled = value
    end
})

UserTab:CreateColorPicker({
    Name = "Skeleton Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        SkeletonColor = color
        for _, data in pairs(ESP) do
            for _, line in ipairs(data.Skeleton) do
                line.Color = color
            end
        end
    end
})

UserTab:CreateSlider({
    Name = "Skeleton Thickness",
    Range = {1, 5},
    Increment = 1,
    CurrentValue = 1,
    Callback = function(value)
        SkeletonThickness = value
        for _, data in pairs(ESP) do
            for _, line in ipairs(data.Skeleton) do
                line.Thickness = value
            end
        end
    end
})

UserTab:CreateSlider({
    Name = "Skeleton Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.8,
    Callback = function(value)
        SkeletonTransparency = value
        for _, data in pairs(ESP) do
            for _, line in ipairs(data.Skeleton) do
                line.Transparency = value
            end
        end
    end
})

AimTab:CreateParagraph({Title = "Welcome to Silicon!", Content = "You are using Silicon for Flick."})

AimTab:CreateDivider()

AimTab:CreateSection("Main Aim Settings")

local AimbotEnabled = false
local AutoHold = false
local KeybindHold = false
local TriggerbotEnabled = false
local AimbotKeybind = Enum.UserInputType.MouseButton2
local FOVRadius = 120
local TargetPart = "Head"
local Prediction = 0.135
local Smoothness = 0.18
local ESPCircleVisible = true
local LastValidTargetTime = 0

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.8
FOVCircle.NumSides = 100
FOVCircle.Radius = FOVRadius
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Color = Color3.fromRGB(255,255,255)
FOVCircle.Visible = false

local KeybindMap = {
    MouseButton1 = Enum.UserInputType.MouseButton1,
    MouseButton2 = Enum.UserInputType.MouseButton2,
    E = Enum.KeyCode.E,
    Q = Enum.KeyCode.Q,
    R = Enum.KeyCode.R,
    LeftAlt = Enum.KeyCode.LeftAlt,
    LeftControl = Enum.KeyCode.LeftControl
}

local function IsTargetVisible(plr)
    if not plr.Character or not plr.Character:FindFirstChild(TargetPart) then return false end
    local part = plr.Character[TargetPart]
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character or {}, plr.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position), rayParams)
    return result == nil or result.Instance:IsDescendantOf(plr.Character)
end

local function GetClosest()
    local closest = nil
    local shortest = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, plr in Players:GetPlayers() do
        if plr == LocalPlayer or not plr.Character or not plr.Character:FindFirstChild(TargetPart) then continue end
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local predictedPos = plr.Character[TargetPart].Position + root.Velocity * Prediction
        local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
        if onScreen then
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if distance < shortest and distance <= FOVRadius then
                shortest = distance
                closest = plr
            end
        end
    end
    return closest
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == AimbotKeybind or input.KeyCode == AimbotKeybind then
        KeybindHold = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == AimbotKeybind or input.KeyCode == AimbotKeybind then
        KeybindHold = false
    end
end)

RunService.Heartbeat:Connect(function()
    Camera = workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = FOVRadius

    if AimbotEnabled then
        FOVCircle.Visible = ESPCircleVisible

        if AutoHold or KeybindHold then
            local target = GetClosest()
            if target and target.Character then
                local root = target.Character:FindFirstChild("HumanoidRootPart")
                local targetPartObj = target.Character:FindFirstChild(TargetPart)
                if root and targetPartObj then
                    local targetPos = targetPartObj.Position + root.Velocity * Prediction
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), Smoothness)
                end
                FOVCircle.Color = Color3.fromRGB(0,255,0)
            else
                FOVCircle.Color = Color3.fromRGB(255,255,255)
            end
        else
            FOVCircle.Color = Color3.fromRGB(255,255,255)
        end
    else
        FOVCircle.Visible = false
    end

    if TriggerbotEnabled then
        local target = GetClosest()
        if target and target.Character and IsTargetVisible(target) then
            if tick() - LastValidTargetTime >= 0.1 then
                mouse1click()
                LastValidTargetTime = tick()
            end
        else
            LastValidTargetTime = tick()
        end
    end
end)

AimTab:CreateToggle({
    Name = "Aimbot Enabled",
    CurrentValue = false,
    Callback = function(value)
        Silicon:Notify({
            Title = "Aimbot",
            Content = Value and "Aimbot has been enabled." or "Aimbot has been disabled."
        })
        AimbotEnabled = value
    end
})

AimTab:CreateToggle({
    Name = "Triggerbot",
    CurrentValue = false,
    Callback = function(value)
        Silicon:Notify({
            Title = "Triggerbot",
            Content = Value and "Triggerbot has been enabled." or "Triggerbot has been disabled."
        })
        TriggerbotEnabled = value
    end
})

AimTab:CreateDivider()

AimTab:CreateToggle({
    Name = "Auto Hold",
    CurrentValue = false,
    Callback = function(value)
        Silicon:Notify({
            Title = "Auto-Hold",
            Content = Value and "Auto-Hold has been enabled." or "Auto-Hold has been disabled."
        }) 
        AutoHold = value
    end
})

AimTab:CreateToggle({
    Name = "FOV Circle Visible",
    CurrentValue = true,
    Callback = function(value)
        Silicon:Notify({
            Title = "FOV Visibility",
            Content = Value and "FOV Circle has been enabled." or "FOV Circle has been disabled."
        }) 
        ESPCircleVisible = value
    end
})

AimTab:CreateDropdown({
    Name = "Keybind",
    Options = {"MouseButton1","MouseButton2","E","Q","R","LeftAlt","LeftControl"},
    CurrentOption = {"MouseButton2"},
    Callback = function(option)
        AimbotKeybind = KeybindMap[option[1]]
    end
})

AimTab:CreateDivider()

AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
    CurrentOption = {"Head"},
    Callback = function(option)
        TargetPart = option[1]
    end
})

AimTab:CreateSlider({
    Name = "FOV Radius",
    Range = {10,600},
    Increment = 10,
    CurrentValue = 120,
    Callback = function(value)
        FOVRadius = value
    end
})

AimTab:CreateDivider()

AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.01,0.5},
    Increment = 0.01,
    CurrentValue = 0.18,
    Callback = function(value)
        Smoothness = value
    end
})

AimTab:CreateSlider({
    Name = "Prediction",
    Range = {0,0.5},
    Increment = 0.005,
    CurrentValue = 0.135,
    Callback = function(value)
        Prediction = value
    end
})