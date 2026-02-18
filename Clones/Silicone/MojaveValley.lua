local Silicon = loadstring(game:HttpGet("https://api.siliconxploits.xyz/notify"))()

local parentGui = gethui and gethui() or game:GetService("CoreGui")
for _, gui in ipairs(parentGui:GetChildren()) do
    if gui:IsA("ScreenGui") then
        if gui.Name == "WindUI"
        or gui.Name == "WindUI/Notifications"
        or gui.Name == "WindUI/Dropdowns"
        or gui.Name == "WindUI/Tooltips" then
            gui:Destroy()
        end
    end
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "Silicon for Mojave Valley",
    Author = "by 5xy",
    Folder = "nil",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = false,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,  
    NewElements = true,     
    
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("fuck did you click this for? - 5xy")
        end,
    },
})

Window:SetToggleKey(Enum.KeyCode.K)

Window:EditOpenButton({
    Title = "Silicon",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("0097D7")
    ),
    OnlyMobile = true,
    Enabled = true,
    Draggable = true,
})

Window:Tag({
    Title = "v0.0.2",
    Color = Color3.fromHex("#0097d7"),
    Radius = 13,
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Silicon:Notify({
    Title = "Welcome, " .. LocalPlayer.Name,
    Content = "Enjoy your experience!"
})

local UserTab = Window:Tab({ 
    Title = "User",
    Icon = "user", 
    Locked = false,
})

UserTab:Section({ 
    Title = "Trolling",
})

local noclipEnabled = false
UserTab:Toggle({
    Title = "NoClip",
    Type = "Toggle",
    Value = false,
    Callback = function(Value)
        noclipEnabled = Value
        Silicon:Notify({
            Title = "NoClip",
            Content = Value and "NoClip has been enabled." or "NoClip has been disabled."
        })
    end
})

game:GetService("RunService").Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    end
end)

local VehicleTab = Window:Tab({
    Title = "Vehicle",
    Icon = "car", 
    Locked = false,
})

VehicleTab:Section({ 
    Title = "Vehicle Modules",
})

VehicleTab:Button({
    Title = "Speed Controller",
    Locked = false,
    Callback = function()
        Silicon:Notify({
            Title = "Speed Controller",
            Content = Value and "Speed Panel has been initiated." or "Speed Panel has been initiated."
        })
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sxytdi/Silicon/refs/heads/main/Scripts/speeduni.lua"))()
    end
})

VehicleTab:Section({ 
    Title = "Vehicle Features",
})

local strobeActive = false
local strobeThread
VehicleTab:Toggle({
    Title = "Vehicle Strobes",
    Type = "Toggle",
    Value = false, 
    Callback = function(enabled)
        Silicon:Notify({
            Title = "Strobes",
            Content = enabled and "Strobes have now been activated." or "Strobes have now been deactivated."
        })
        strobeActive = enabled
        local vim = game:GetService("VirtualInputManager")
        if enabled then
            if not strobeThread or coroutine.status(strobeThread) == "dead" then
                strobeThread = coroutine.create(function()
                    while strobeActive do
                        vim:SendKeyEvent(true, Enum.KeyCode.J, false, game)
                        vim:SendKeyEvent(true, Enum.KeyCode.X, false, game)
                        task.wait(0.02)
                        vim:SendKeyEvent(false, Enum.KeyCode.J, false, game)
                        vim:SendKeyEvent(false, Enum.KeyCode.X, false, game)
                        task.wait(0.1)
                    end
                end)
                coroutine.resume(strobeThread)
            end
        end
    end
})

VehicleTab:Section({ 
    Title = "Vehicle Stability",
})

local driftEnabled = false
local driftFriction = 0.1

local function getPlayerCar()
    local player = game.Players.LocalPlayer
    local vehicles = workspace:FindFirstChild("PlayerVehicles")
    if not vehicles then return nil end
    return vehicles:FindFirstChild(player.Name .. "'s Car")
end

local function setFriction(part, value)
    if not part or not part:IsA("BasePart") then return end
    local props = part.CustomPhysicalProperties
    if not props then return end
    if math.abs(props.Friction - value) < 0.01 then return end
    part.CustomPhysicalProperties = PhysicalProperties.new(
        props.Density,
        value,
        props.Elasticity,
        props.FrictionWeight,
        props.ElasticityWeight
    )
end

local function applyFriction(value)
    local car = getPlayerCar()
    if not car then return end
    local wheels = car:FindFirstChild("Wheels")
    if not wheels then return end
    for _, wheel in ipairs(wheels:GetChildren()) do
        setFriction(wheel, value)
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if driftEnabled then
        applyFriction(driftFriction)
    end
end)

VehicleTab:Toggle({
    Title = "Custom Grip Value",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        driftEnabled = state
        applyFriction(state and driftFriction or 0.7)
        Silicon:Notify({
            Title = "Custom Grip",
            Content = state and "Custom Grip has been enabled." or "Custom Grip has been disabled."
        })
    end
})

VehicleTab:Slider({
    Title = "Grip Value",
    Step = 0.01,
    Value = {
        Min = 0,
        Max = 2,
        Default = driftFriction
    },
    Callback = function(value)
        driftFriction = value
        if driftEnabled then
            applyFriction(driftFriction)
        end
    end
})

VehicleTab:Section({ 
    Title = "Suspension",
})

local suspensionSliderEnabled = false
local originalSpringValues = {}

local function getPlayerCar()
    local player = game.Players.LocalPlayer
    local vehicles = workspace:FindFirstChild("PlayerVehicles")
    if not vehicles then return nil end
    return vehicles:FindFirstChild(player.Name .. "'s Car")
end

local function getPlayerCarWheels()
    local car = getPlayerCar()
    if not car then return nil end
    return car:FindFirstChild("Wheels")
end

local function storeOriginalSprings()
    local wheels = getPlayerCarWheels()
    if not wheels then return end
    originalSpringValues = {}
    for _, wheel in ipairs(wheels:GetChildren()) do
        local spring = wheel:FindFirstChild("Spring")
        if spring then
            originalSpringValues[wheel.Name] = {
                MinLength = spring.MinLength,
                MaxLength = spring.MaxLength
            }
        end
    end
end

local function animateToOriginal()
    local wheels = getPlayerCarWheels()
    if not wheels then return end
    for _, wheel in ipairs(wheels:GetChildren()) do
        local spring = wheel:FindFirstChild("Spring")
        local orig = originalSpringValues[wheel.Name]
        if spring and orig then
            local steps = 30
            local duration = 0.4
            local interval = duration / steps
            local startMin = spring.MinLength
            local startMax = spring.MaxLength
            local diffMin = orig.MinLength - startMin
            local diffMax = orig.MaxLength - startMax
            task.spawn(function()
                for i = 1, steps do
                    local t = i / steps
                    local ease = math.sin((t * math.pi) / 2)
                    spring.MinLength = startMin + diffMin * ease
                    spring.MaxLength = startMax + diffMax * ease
                    task.wait(interval)
                end
            end)
        end
    end
end

local function setSpringsFor(wheelNames, size)
    local wheels = getPlayerCarWheels()
    if not wheels then return end
    for _, name in ipairs(wheelNames) do
        local wheel = wheels:FindFirstChild(name)
        if wheel then
            local spring = wheel:FindFirstChild("Spring")
            if spring then
                spring.MinLength = size
                spring.MaxLength = size
            end
        end
    end
end

local function setAllSprings(size)
    local wheels = getPlayerCarWheels()
    if not wheels then return end
    for _, wheel in ipairs(wheels:GetChildren()) do
        local spring = wheel:FindFirstChild("Spring")
        if spring then
            spring.MinLength = size
            spring.MaxLength = size
        end
    end
end

VehicleTab:Toggle({
    Title = "Custom Suspension",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        suspensionSliderEnabled = state
        if state then
            local wheels = getPlayerCarWheels()
            if not wheels then
                Silicon:Notify({
                    Title = "No Vehicle Found",
                    Content = "Please spawn your vehicle first."
                })
                return
            end
            storeOriginalSprings()
            setAllSprings(2)
            Silicon:Notify({
                Title = "Suspension Enabled",
                Content = "Use the sliders to adjust your suspension."
            })
        else
            Silicon:Notify({
                Title = "Suspension Disabled",
                Content = "Suspension has been successfully disabled."
            })
            animateToOriginal()
        end
    end
})

VehicleTab:Slider({
    Title = "Front Wheels",
    Step = 0.01,
    Value = {
        Min = 0.7,
        Max = 10,
        Default = 2
    },
    Callback = function(value)
        if suspensionSliderEnabled then
            setSpringsFor({ "FR", "FL" }, value)
        end
    end
})

VehicleTab:Slider({
    Title = "Rear Wheels",
    Step = 0.01,
    Value = {
        Min = 0.7,
        Max = 10,
        Default = 2
    },
    Callback = function(value)
        if suspensionSliderEnabled then
            setSpringsFor({ "RR", "RL" }, value)
        end
    end
})

VehicleTab:Slider({
    Title = "All Wheels",
    Step = 0.01,
    Value = {
        Min = 0.7,
        Max = 10,
        Default = 2
    },
    Callback = function(value)
        if suspensionSliderEnabled then
            setAllSprings(value)
        end
    end
})

VehicleTab:Button({
    Title = "Reset All Suspension",
    Locked = false,
    Callback = function()
        if suspensionSliderEnabled then
            animateToOriginal()
            Silicon:Notify({
                Title = "Suspension Reset",
                Content = "All wheels restored to original."
            })
        end
    end
})

local AutofarmTab = Window:Tab({
    Title = "Autofarm",
    Icon = "pound-sterling", 
    Locked = false,
})

AutofarmTab:Paragraph({
    Title = "Set your job as Raygun Cafe then start the farm, to earn 2x more cash! Enjoy!",
    Locked = false,
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

AutofarmTab:Button({
    Title = "Drive-To-Earn",
    Locked = false,
    Callback = function()
        local character = player.Character
        if not character then return end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local seat = humanoid.SeatPart
        if not seat or not seat:IsA("VehicleSeat") then
            Silicon:Notify({
                Title = "Error",
                Content = "You are not in a vehicle!"
            })
            return
        end

        local car =
            workspace:FindFirstChild("PlayerVehicles")
            and workspace.PlayerVehicles:FindFirstChild(player.Name .. "'s Car")
            or seat:FindFirstAncestorOfClass("Model")

        if not car or not car.PrimaryPart then
            Silicon:Notify({
                Title = "Error",
                Content = "Vehicle not found!"
            })
            return
        end

        local forward = seat.CFrame.LookVector
        local flatForward = Vector3.new(forward.X, 0, forward.Z).Unit
        local rotationCFrame = CFrame.lookAt(Vector3.zero, flatForward)

        local platformCenterPos = car.PrimaryPart.Position + Vector3.new(0, 100, 0)
        local platformCenterCFrame = CFrame.new(platformCenterPos) * rotationCFrame

        local PLATFORM_SIZE = Vector3.new(10, 2, 1050)
        local DRIVE_SPEED = 98

        local carHalfLength = car:GetExtentsSize().Z / 2
        local platformHalfLength = PLATFORM_SIZE.Z / 2

        local resetZOffset = -(platformHalfLength - 3 - carHalfLength)

        local function getResetCFrame()
            return platformCenterCFrame * CFrame.new(0, 0, resetZOffset)
        end

        car:SetPrimaryPartCFrame(getResetCFrame())

        local platform = Instance.new("Part")
        platform.Size = PLATFORM_SIZE
        platform.Anchored = true
        platform.Color = Color3.new(1, 1, 1)
        platform.Material = Enum.Material.SmoothPlastic
        platform.CFrame = platformCenterCFrame * CFrame.new(0, -5, 0)
        platform.Parent = workspace

        local lockConnection
        lockConnection = RunService.RenderStepped:Connect(function()
            if car and car.PrimaryPart then
                car:SetPrimaryPartCFrame(getResetCFrame())
            end
        end)

        task.delay(2, function()
            if lockConnection then
                lockConnection:Disconnect()
                lockConnection = nil
            end
        end)

        local velocityConnection
        local alignConnection
        local boundaryConnection
        local seatConnection
        local resetCooldown = false

        local function cleanup()
            if lockConnection then lockConnection:Disconnect() end
            if velocityConnection then velocityConnection:Disconnect() end
            if alignConnection then alignConnection:Disconnect() end
            if boundaryConnection then boundaryConnection:Disconnect() end
            if seatConnection then seatConnection:Disconnect() end
            if platform then platform:Destroy() end
            if car and car.PrimaryPart then
                car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
            end
        end

        velocityConnection = RunService.Heartbeat:Connect(function()
            if not seat or seat.Occupant == nil then
                cleanup()
                return
            end

            local f = seat.CFrame.LookVector
            local ff = Vector3.new(f.X, 0, f.Z).Unit
            local currentVel = car.PrimaryPart.AssemblyLinearVelocity
            local newVel = ff * DRIVE_SPEED
            car.PrimaryPart.AssemblyLinearVelocity =
                Vector3.new(newVel.X, currentVel.Y, newVel.Z)
        end)

        alignConnection = RunService.Heartbeat:Connect(function()
            if not seat or seat.Occupant == nil then return end
            if not car or not car.PrimaryPart then return end

            local localPos = platform.CFrame:PointToObjectSpace(car.PrimaryPart.Position)
            local correctedLocal = Vector3.new(0, localPos.Y, localPos.Z)
            local correctedWorld = platform.CFrame:PointToWorldSpace(correctedLocal)
            local lookDir = platform.CFrame.LookVector

            car:SetPrimaryPartCFrame(
                CFrame.new(correctedWorld, correctedWorld + lookDir)
            )
        end)

        boundaryConnection = RunService.Heartbeat:Connect(function()
            if not seat or seat.Occupant == nil then
                cleanup()
                return
            end

            if resetCooldown then return end

            local localPos = platform.CFrame:PointToObjectSpace(car.PrimaryPart.Position)
            local frontZ = localPos.Z + carHalfLength
            local backZ = localPos.Z - carHalfLength

            if frontZ >= platformHalfLength - 1 or backZ <= -(platformHalfLength - 1) then
                resetCooldown = true
                car:SetPrimaryPartCFrame(getResetCFrame())
                task.delay(0.3, function()
                    resetCooldown = false
                end)
            end
        end)

        seatConnection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
            if seat.Occupant == nil then
                cleanup()
            end
        end)
    end
})

local OtherTab = Window:Tab({
    Title = "Other",
    Icon = "ellipsis", 
    Locked = false,
})

OtherTab:Section({ 
    Title = "Other",
})

OtherTab:Toggle({
    Title = "Notification Sound",
    Type = "Toggle",
    Value = true,
    Callback = function(Value)
        Silicon.NotificationSoundEnabled = Value
        Silicon:Notify({
            Title = "Notify System",
            Content = Value and "You will now recieve notification sounds." or "You will not recieve notification sounds.",
        })
    end,
})

local hiddenGUIs = {}
local function isRayfieldGui(gui)
    return gui.Name:lower():find("rayfield") or gui:FindFirstChild("Topbar") or gui:FindFirstChild("Container")
end

OtherTab:Toggle({
    Title = "Hide UIs",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        if state then
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled and not isRayfieldGui(gui) then
                    gui.Enabled = false
                    table.insert(hiddenGUIs, gui)
                end
            end
            Silicon:Notify({
                Title = "UI Hidden",
                Content = "All non-Rayfield UI elements have been hidden."
            })
        else
            for _, gui in ipairs(hiddenGUIs) do
                if gui and gui.Parent == playerGui then
                    gui.Enabled = true
                end
            end
            hiddenGUIs = {}
            Silicon:Notify({
                Title = "UI Restored",
                Content = "Previously hidden UIs have been re-enabled."
            })
        end
    end
})

local VIM = game:GetService("VirtualInputManager")
local enabled = false
local thread
OtherTab:Toggle({
    Title = "Anti-AFK",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        enabled = state

        if enabled then
            if thread then return end
            thread = task.spawn(function()
                while enabled do
                    VIM:SendKeyEvent(true, Enum.KeyCode.K, false, game)
                    task.wait(0.1)
                    VIM:SendKeyEvent(false, Enum.KeyCode.K, false, game)

                    for _ = 1, 300 do
                        if not enabled then break end
                        task.wait(1)
                    end
                end
                VIM:SendKeyEvent(false, Enum.KeyCode.K, false, game)
                thread = nil
            end)
        else
            VIM:SendKeyEvent(false, Enum.KeyCode.K, false, game)
        end
    end
})

OtherTab:Section({ 
    Title = "Performance",
})

OtherTab:Toggle({
    Title = "FPS Unlocker",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        Silicon:Notify({
            Title = "FPS",
            Content = state and "FPS Unlocker has been enabled." or "FPS Unlocker has been disabled."
        })
        if state then
            setfpscap(9999)
        else
            setfpscap(60)
        end
    end,
})

local fpsFrame = Instance.new("ScreenGui")
fpsFrame.Name = "FPS_UI"
fpsFrame.ResetOnSpawn = false
fpsFrame.IgnoreGuiInset = true
fpsFrame.Enabled = false
fpsFrame.Parent = game:GetService("CoreGui")

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0,120,0,30)
fpsLabel.AnchorPoint = Vector2.new(1,0)
fpsLabel.Position = UDim2.new(1,-10,0,10)
fpsLabel.BackgroundTransparency = 0.3
fpsLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
fpsLabel.TextColor3 = Color3.fromRGB(0,255,120)
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.TextSize = 20
fpsLabel.Text = "FPS: 0"
fpsLabel.Parent = fpsFrame

local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local last = tick()
local dragging = false
local dragInput, mousePos, framePos

local function updatePosition()
    if not dragging then
        fpsLabel.Position = UDim2.new(1,-10,0,10)
    end
end

fpsLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = fpsLabel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

fpsLabel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - mousePos
        fpsLabel.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

UIS.WindowFocused:Connect(updatePosition)
fpsFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)

RunService.Heartbeat:Connect(function()
    local now = tick()
    local fps = math.floor(1/(now-last))
    last = now
    if fpsFrame.Enabled then
        fpsLabel.Text = "FPS: "..fps
    end
end)

OtherTab:Toggle({
    Title = "Show FPS",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        Silicon:Notify({
            Title = "FPS",
            Content = state and "FPS Visuals has been enabled." or "FPS Visuals has been disabled."
        })
        fpsFrame.Enabled = state
    end,
})

Window:Divider()

local InfoTab = Window:Tab({
    Title = "Script Info",
    Icon = "info",
    Locked = true,
})