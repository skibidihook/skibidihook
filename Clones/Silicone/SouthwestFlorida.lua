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
    Title = "Silicon for Southwest Florida",
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
    Title = "v0.0.1",
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

local UserTab = Window:Tab({ 
    Title = "User",
    Icon = "user", 
    Locked = false,
})

UserTab:Section({ 
    Title = "Extras",
})

UserTab:Input({
    Title = "Spectate Player",
    Type = "Input",
    Placeholder = "Enter Username",
    Callback = function(Value)
        spectatePlayer = Value
        if spectatePlayer == "" then
            game.Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            return
        end
        local targetPlayer = game.Players:FindFirstChild(spectatePlayer)
        if targetPlayer then
            game.Workspace.CurrentCamera.CameraSubject = targetPlayer.Character:FindFirstChild("Humanoid")
            Silicon:Notify({
                Title = "Spectating",
                Content = "You are now spectating the chosen player."
            })
        else
            Silicon:Notify({
                Title = "Spectate Error",
                Content = "Player not found!"
            })
        end
    end
})

UserTab:Section({ 
    Title = "Trolling",
})

local noclipEnabled = false
UserTab:Toggle({
    Title = "No Clip",
    Type = "Toggle",
    Value = false,
    Callback = function(Value)
        noclipEnabled = Value
        Silicon:Notify({
            Title = "Trolling",
            Content = Value and "No Clip has been enabled." or "No Clip has been disabled."
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

--=========== VEHICLE ===========--

VehicleTab:CreateParagraph({
    Title = "Welcome to Silicon!",
    Content = "You are using Silicon for Southwest Florida."
})

VehicleTab:CreateDivider()

VehicleTab:CreateSection("Vehicle Modules")

local rs = game:GetService("ReplicatedStorage")
local carsFolder = workspace:WaitForChild("Cars")
local function getClosestCar()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    local closest, minDist = nil, math.huge
    for _, car in pairs(carsFolder:GetChildren()) do
        if car:IsA("Model") and car.PrimaryPart then
            local dist = (car.PrimaryPart.Position - root.Position).Magnitude
            if dist < minDist then
                minDist = dist
                closest = car
            end
        end
    end
    return closest
end

VehicleTab:CreateButton({
    Name = "Refuel Vehicle",
    Callback = function()
        local car = getClosestCar()
        if car then
            local args = {
                "requestPurchase",
                car,
                0.1,
                rs:WaitForChild("PetrolPrice"),
                rs:WaitForChild("DieselPrice")
            }
            rs:WaitForChild("fuelEvent"):FireServer(unpack(args))

            Silicon:Notify({
                Title = "Vehicle Refueled",
                Content = "Closest car has been successfully refueled."
            })
        else
            Silicon:Notify({
                Title = "No Vehicle Found",
                Content = "Couldn't find a nearby car to refuel."
            })
        end
    end
})

VehicleTab:CreateButton({
   Name = "Universal Speed Modifier",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/sxytdi/Silicon/refs/heads/main/Scripts/speeduni.lua"))()
    end
})

VehicleTab:CreateSection("Vehicle Features")

local autoSeatEnabled = false
VehicleTab:CreateToggle({
    Name = "Vehicle Unlocker",
    CurrentValue = false,
    Flag = "AutoVehicleSeat",
    Callback = function(Value)
        autoSeatEnabled = Value
        if Value then
            Silicon:Notify({
                Title = "Vehicle Unlocker",
                Content = "Touch a driver's seat with your character and you will enter the car"
            })
        end
    end,
})

local function TrySitVehicleSeat()
    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end
    if Humanoid.Sit then return end

    local sessionVehicles = workspace:FindFirstChild("Cars")
    if not sessionVehicles then return end

    local closestVehicleSeat, closestDist = nil, math.huge

    for _, vehicle in ipairs(sessionVehicles:GetChildren()) do
        if vehicle:IsA("Model") then
            for _, seat in ipairs(vehicle:GetDescendants()) do
                if seat:IsA("VehicleSeat") then
                    local dist = (seat.Position - HRP.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestVehicleSeat = seat
                    end
                end
            end
        end
    end

    if closestVehicleSeat and closestDist <= 3 then
        Humanoid.Sit = false
        task.wait(0.1)
        closestVehicleSeat:Sit(Humanoid)
        Silicon:Notify({
            Title = "Vehicle Unlocker",
            Content = "Successfully Stolen"
        })
    end
end

task.spawn(function()
    while true do
        if autoSeatEnabled then
            TrySitVehicleSeat()
        end
        task.wait(0.5)
    end
end)

local RadarEnabled = false
local HighwayMode = false
local DetectionDistance = 100
local RadarVolume = 1 

local DetectionTeams = {
    ["Police"] = true,
    ["Sheriff"] = true,
}

local KBand = "rbxassetid://121546586408772"
local KABand = "rbxassetid://115575798783668"
local XBand = "rbxassetid://124491561409239"
local SelfTestSoundId = "rbxassetid://140427089336506"

local function createSound(id)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = RadarVolume
    s.Looped = false
    s.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    return s
end

local soundK = createSound(KBand)
local soundKA = createSound(KABand)
local soundX = createSound(XBand)
local selfTestSound = createSound(SelfTestSoundId)

local function SelfTest()
    Silicon:Notify({
        Title = "Radar",
        Content = "Self Test Ongoing",
        Mute = true
    })
    selfTestSound.TimePosition = 0
    selfTestSound:Play()
    task.wait(9)
    Silicon:Notify({
        Title = "Radar",
        Content = "Radar Activated.",
        Mute = true
    })
end

local function ToggleRadar(enabled)
    RadarEnabled = enabled
    if RadarEnabled then
        task.spawn(SelfTest)
    else
        Silicon:Notify({
            Title = "Radar",
            Content = "Radar Deactivated.",
            Mute = true
        })
    end
end

local function UpdateRadarVolume(volume)
    RadarVolume = volume
    soundK.Volume = RadarVolume
    soundKA.Volume = RadarVolume
    soundX.Volume = RadarVolume
    selfTestSound.Volume = RadarVolume
end

task.spawn(function()
    while task.wait(1) do
        if RadarEnabled then
            local localPlayer = game.Players.LocalPlayer
            if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                continue
            end

            local localHRP = localPlayer.Character.HumanoidRootPart

            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= localPlayer and player.Team and DetectionTeams[player.Team.Name] then
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local distance = (player.Character.HumanoidRootPart.Position - localHRP.Position).Magnitude
                        if distance <= DetectionDistance then
                            Silicon:Notify({
                                Title = "Radar Alert!",
                                Content = player.Name .. " (" .. player.Team.Name .. ") detected within " .. math.floor(distance) .. " studs! (KA BAND)",
                                Mute = true
                            })
                            soundKA:Play()
                        end
                    end
                end
            end
        end
    end
end)

VehicleTab:CreateSection("Vehicle Radar")

VehicleTab:CreateToggle({
	Name = "Radar Detector",
	CurrentValue = false,
	Flag = "RadarToggle",
	Callback = function(Value)
		ToggleRadar(Value)
	end,
})

VehicleTab:CreateSlider({
	Name = "Detection Distance",
	Range = {5, 800},
	Increment = 5,
	Suffix = "Studs",
	CurrentValue = 100,
	Flag = "RadarDistance",
	Callback = function(Value)
		DetectionDistance = Value
	end,
})

VehicleTab:CreateSlider({
    Name = "Radar Volume",
    Range = {0, 5},
    Increment = 1,
    Suffix = "",
    CurrentValue = RadarVolume,
    Flag = "VolumeSlider", 
    Callback = function(value)
        UpdateRadarVolume(value)
    end
})

VehicleTab:CreateToggle({
	Name = "Highway Mode",
	CurrentValue = false,
	Flag = "HighwayMode",
	Callback = function(Value)
		HighwayMode = Value
		local msg = Value and "Highway Mode ON (X Band Disabled)" or "Highway Mode OFF (X Band Enabled)"
		Silicon:Notify({
			Title = "Radar",
			Content = msg,
            Mute = true
		})
	end,
})

VehicleTab:CreateSection("Drift & Steering")

local driftEnabled = false
local angleTweakerEnabled = false
local driftFriction = 0.1
local angleTweakerValue = 1000
local customAngleEnabled = false
local customAngleValue = 30
local playerName = game.Players.LocalPlayer.Name
local function setFriction(part, value)
    if not part or not part:IsA("BasePart") then return false end
    local success, result = pcall(function()
        local props = part.CustomPhysicalProperties
        if not props or props.Friction == value then return false end
        part.CustomPhysicalProperties = PhysicalProperties.new(
            props.Density,
            value,
            props.Elasticity,
            props.FrictionWeight,
            props.ElasticityWeight
        )
        return true
    end)
    return success and result
end

local function modifySteeringD(wheel, value)
    local arm = wheel:FindFirstChild("Arm")
    if arm then
        local steer = arm:FindFirstChild("Steer")
        if steer and steer:IsA("BodyGyro") then
            steer.D = value
        end
    end
end

local function modifySteeringAngle(wheel, angle)
    local arm = wheel:FindFirstChild("Arm")
    if arm then
        local hinge = arm:FindFirstChild("HingeConstraint")
        if hinge and hinge:IsA("HingeConstraint") then
            hinge.TargetAngle = angle
        end
    end
end

local function getNearestCarWithin10Studs()
    local player = game.Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local rootPos = player.Character.HumanoidRootPart.Position
    local nearestCar = nil
    local shortestDistance = 10
    for _, car in pairs(workspace.Cars:GetChildren()) do
        if car:IsA("Model") and car.PrimaryPart then
            local distance = (car.PrimaryPart.Position - rootPos).Magnitude
            if distance < shortestDistance then
                nearestCar = car
                shortestDistance = distance
            end
        end
    end
    return nearestCar
end

local function updateVehicleFrictionAndSteering(steerValue, friction)
    local car = getNearestCarWithin10Studs()
    if not car then return end
    local wheels = car:FindFirstChild("Wheels")
    if not wheels then return end
    local wheelNames = {"FL", "FR", "RL", "RR"}
    for _, name in ipairs(wheelNames) do
        local wheel = wheels:FindFirstChild(name)
        if wheel then
            setFriction(wheel, friction)
            if angleTweakerEnabled and (name == "FL" or name == "FR") then
                modifySteeringD(wheel, steerValue)
            elseif not angleTweakerEnabled and (name == "FL" or name == "FR") then
                modifySteeringD(wheel, 1000)
            end
            if customAngleEnabled and (name == "FL" or name == "FR") then
                modifySteeringAngle(wheel, customAngleValue)
            elseif not customAngleEnabled and (name == "FL" or name == "FR") then
                modifySteeringAngle(wheel, 0)
            end
        end
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if driftEnabled then
        updateVehicleFrictionAndSteering(angleTweakerEnabled and angleTweakerValue or 1000, driftFriction)
    end
end)

task.spawn(function()
    while true do
        if driftEnabled then
            local car = getNearestCarWithin10Studs()
            if car and car:FindFirstChild("Wheels") then
                for _, wheel in pairs(car.Wheels:GetChildren()) do
                    if wheel:IsA("BasePart") then
                        local f = wheel.CustomPhysicalProperties and wheel.CustomPhysicalProperties.Friction or -1
                        if math.abs(f - driftFriction) > 0.05 then
                            setFriction(wheel, driftFriction)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

VehicleTab:CreateToggle({
    Name = "Custom Grip Value",
    CurrentValue = false,
    Callback = function(state)
        driftEnabled = state
        if driftEnabled then
            updateVehicleFrictionAndSteering(angleTweakerEnabled and angleTweakerValue or 1000, driftFriction)
            Silicon:Notify({
                Title = "Custom Grip",
                Content = "Custom grip enabled."
            })
        else
            updateVehicleFrictionAndSteering(angleTweakerEnabled and angleTweakerValue or 1000, 0.7)
            Silicon:Notify({
                Title = "Custom Grip",
                Content = "Custom grip disabled."
            })
        end
    end
})

VehicleTab:CreateSlider({
    Name = "Grip Value",
    Range = {0, 2}, 
    Increment = 0.01,
    Suffix = "",
    CurrentValue = driftFriction,
    Callback = function(val)
        driftFriction = val
        if driftEnabled then
            updateVehicleFrictionAndSteering(angleTweakerEnabled and angleTweakerValue or 1000, driftFriction)
        end
    end
})

VehicleTab:CreateToggle({
    Name = "AngleTweaker",
    CurrentValue = false,
    Callback = function(state)
        angleTweakerEnabled = state
        updateVehicleFrictionAndSteering(angleTweakerEnabled and angleTweakerValue or 1000, driftFriction)
        Silicon:Notify({
            Title = "AngleTweaker",
            Content = state and "AngleTweaker enabled." or "AngleTweaker disabled."
        })
    end
})

VehicleTab:CreateSlider({
    Name = "AngleTweaker Value",
    Range = {500, 8000},
    Increment = 100,
    Suffix = "",
    CurrentValue = angleTweakerValue,
    Callback = function(val)
        angleTweakerValue = val
        if angleTweakerEnabled then
            updateVehicleFrictionAndSteering(angleTweakerValue, driftFriction)
        end
    end
})

VehicleTab:CreateSection("Suspension")

local suspensionSliderEnabled = false
local suspensionSpringValue = 2
local originalSpringValues = {}

local function getNearestCarWheels()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local carsFolder = workspace:FindFirstChild("Cars")
    if not carsFolder then return nil end
    local closestCar, closestDist = nil, math.huge
    for _, car in pairs(carsFolder:GetChildren()) do
        if car:IsA("Model") and car.PrimaryPart then
            local dist = (hrp.Position - car.PrimaryPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestCar = car
            end
        end
    end
    if closestCar then
        local wheels = closestCar:FindFirstChild("Wheels")
        return wheels
    end
    return nil
end

local function getPlayerCarWheels()
    return getNearestCarWheels()
end

local function storeOriginalSprings()
    local Wheels = getNearestCarWheels()
    if not Wheels then return end
    originalSpringValues = {}
    for _, wheel in ipairs(Wheels:GetChildren()) do
        local spring = wheel:FindFirstChild("Spring")
        if spring then
            originalSpringValues[wheel.Name] = {
                MinLength = spring.MinLength,
                MaxLength = spring.MaxLength
            }
        end
    end
end

local function restoreOriginalSprings()
    local Wheels = getNearestCarWheels()
    if not Wheels then return end
    for _, wheel in ipairs(Wheels:GetChildren()) do
        local spring = wheel:FindFirstChild("Spring")
        local orig = originalSpringValues[wheel.Name]
        if spring and orig then
            spring.MinLength = orig.MinLength
            spring.MaxLength = orig.MaxLength
        end
    end
end

local function animateToOriginal()
    restoreOriginalSprings()
end

local function setAllSprings(size)
    local Wheels = getNearestCarWheels()
    if Wheels then
        for _, wheel in ipairs(Wheels:GetChildren()) do
            local spring = wheel:FindFirstChild("Spring")
            if spring then
                spring.MinLength = size
                spring.MaxLength = size
            end
        end
    end
end

local function setSpringsFor(list, size)
    local Wheels = getNearestCarWheels()
    if not Wheels then return end
    for _, wheel in ipairs(Wheels:GetChildren()) do
        for _, target in ipairs(list) do
            if wheel.Name == target then
                local spring = wheel:FindFirstChild("Spring")
                if spring then
                    spring.MinLength = size
                    spring.MaxLength = size
                end
            end
        end
    end
end

VehicleTab:CreateToggle({
    Name = "Custom Suspension",
    CurrentValue = false,
    Flag = "EnableSuspensionSlider",
    Callback = function(state)
        suspensionSliderEnabled = state
        if suspensionSliderEnabled then
            local Wheels = getPlayerCarWheels()
            if not Wheels then
                Silicon:Notify({
                    Title = "No Car Found",
                    Content = "Please spawn your car first."
                })
                return
            end
            storeOriginalSprings()
            setAllSprings(2)
            Silicon:Notify({
                Title = "Suspension Enabled",
                Content = "Use the sliders to adjust front, rear, or all wheels."
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

VehicleTab:CreateSlider({
    Name = "Front Wheels Suspension",
    Range = {0.7, 10},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 2,
    Flag = "FrontSuspension",
    Callback = function(value)
        if suspensionSliderEnabled then
            setSpringsFor({"FR", "FL"}, value)
        end
    end
})

VehicleTab:CreateSlider({
    Name = "Rear Wheels Suspension",
    Range = {0.7, 10},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 2,
    Flag = "RearSuspension",
    Callback = function(value)
        if suspensionSliderEnabled then
            setSpringsFor({"RR", "RL"}, value)
        end
    end
})

VehicleTab:CreateSlider({
    Name = "All Wheels Suspension",
    Range = {0.7, 10},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 2,
    Flag = "AllSuspension",
    Callback = function(value)
        if suspensionSliderEnabled then
            setAllSprings(value)
        end
    end
})

VehicleTab:CreateButton({
    Name = "Reset All Suspension",
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

--=========== MODS TAB ===========--

ModsTab:CreateParagraph({Title = "Welcome to Silicon!", Content = "You are using Silicon for Southwest Florida."})

ModsTab:CreateDivider()

ModsTab:CreateSection("Visual Management")

local chaseEnabled = false
local chaseDistance = 15
local turnIntensity = 5
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local function getNearestCar()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local carsFolder = workspace:FindFirstChild("Cars")
    if not carsFolder then return nil end
    local closestCar, closestDist = nil, math.huge
    for _, car in pairs(carsFolder:GetChildren()) do
        if car:IsA("Model") and car.PrimaryPart then
            local dist = (hrp.Position - car.PrimaryPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestCar = car
            end
        end
    end
    return closestCar
end

local function chaseCamera(car)
    camera.CameraType = Enum.CameraType.Scriptable
    while chaseEnabled and car and car.PrimaryPart do
        local root = car.PrimaryPart
        local backOffset = root.CFrame.LookVector * -chaseDistance
        local upOffset = Vector3.new(0, 5, 0)
        local rotVelocity = root.AssemblyAngularVelocity.Y
        local sideOffset = root.CFrame.RightVector * (rotVelocity * turnIntensity * 0.5)
        local cameraPos = root.Position + backOffset + upOffset + sideOffset
        camera.CFrame = CFrame.new(cameraPos, root.Position + root.CFrame.LookVector * 50)
        task.wait()
    end
    if not chaseEnabled then
        camera.CameraType = Enum.CameraType.Custom
    end
end

ModsTab:CreateToggle({
    Name = "Chase Camera",
    CurrentValue = false,
    Flag = "ChaseCameraToggle",
    Callback = function(Value)
        chaseEnabled = Value
        if Value then
            local car = getNearestCar()
            if car then
                task.spawn(function()
                    chaseCamera(car)
                end)
                Silicon:Notify({
                    Title = "Chase Camera",
                    Content = "Chase camera enabled."
                })
            else
                Silicon:Notify({
                    Title = "Chase Camera",
                    Content = "No cars found in workspace.Cars."
                })
            end
        else
            camera.CameraType = Enum.CameraType.Custom
            Silicon:Notify({
                Title = "Chase Camera",
                Content = "Chase camera disabled."
            })
        end
    end,
})

ModsTab:CreateSlider({
    Name = "Camera Distance",
    Range = {5, 50},
    Increment = 1,
    Suffix = "",
    CurrentValue = chaseDistance,
    Flag = "ChaseDistanceSlider",
    Callback = function(Value)
        chaseDistance = Value
    end,
})

ModsTab:CreateSlider({
    Name = "Turn Camera Intensity",
    Range = {0, 20},
    Increment = 1,
    Suffix = "",
    CurrentValue = turnIntensity,
    Flag = "TurnIntensitySlider",
    Callback = function(Value)
        turnIntensity = Value
    end,
})

--=========== AUTOFARM TAB ===========--

AutofarmTab:CreateParagraph({ Title = "Welcome to Silicon!", Content = "You are using Silicon for Southwest Florida."})

AutofarmTab:CreateDivider()

AutofarmTab:CreateSection("Farms")

local toggled = false

local GuiService = game:GetService("GuiService")
local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function bwait(t)
    task.wait(t)
end

local function navClick(btn)
    if not btn then return end
    GuiService.SelectedObject = btn
    bwait(0.01)
    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    bwait(0.01)
    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    VIM:SendKeyEvent(true, Enum.KeyCode.ButtonA, false, game)
    bwait(0.01)
    VIM:SendKeyEvent(false, Enum.KeyCode.ButtonA, false, game)
    GuiService.SelectedObject = nil
end

local function startFintechFarm()
    if toggled then return end
    toggled = true

    task.spawn(function()
        while toggled do
            local pgui = player:WaitForChild("PlayerGui")

            local jobButton = pgui:WaitForChild("MenuGUI",10)
                :WaitForChild("SideButtonsFrame",10)
                :WaitForChild("SideButtons",10)
                :WaitForChild("JobButton",10)
                :WaitForChild("Button",10)

            navClick(jobButton)
            task.wait(1)

            local fintechButton = pgui:WaitForChild("MenuGUI",10)
                :WaitForChild("OpenFrames",10)
                :WaitForChild("Job",10)
                :WaitForChild("Frame",10)
                :WaitForChild("Frame",10)
                :WaitForChild("Frame",10)
                :WaitForChild("Fintech Employee",10)

            navClick(fintechButton)
            task.wait(1)

            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(8770.2333984375, 34.342464447021484, -2727.3876953125)
            end
            task.wait(0.5)

            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(8795.07421875, 27.221424102783203, -2726.961669921875)
            end
            task.wait(1)

            repeat
                if not toggled then break end
                VIM:SendMouseButtonEvent(0,0,0,true,game,0)
                task.wait(0.3)
                VIM:SendMouseButtonEvent(0,0,0,false,game,0)
                task.wait(300)
            until not toggled
        end
    end)
end

AutofarmTab:CreateButton({
    Name = "Fintech AFK Farm",
    Callback = function()
        startFintechFarm()
    end,
})

--=========== OTHER ===========--

OtherTab:CreateParagraph({
    Title = "Welcome to Silicon!",
    Content = "You are using Silicon for Southwest Florida."
})

OtherTab:CreateDivider()

OtherTab:CreateSection("Other")

OtherTab:CreateToggle({
    Name = "Notification Sound",
    CurrentValue = true,
    Flag = "NotificationSoundToggle",
    Callback = function(Value)
        Silicon.NotificationSoundEnabled = Value
        Rayfield:Notify({
            Title = "Notification Sound",
            Content = Value and "Enabled" or "Disabled",
            Duration = 3,
        })
    end,
})

local hiddenGUIs = {}
local function isRayfieldGui(gui)
    return gui.Name:lower():find("rayfield") or gui:FindFirstChild("Topbar") or gui:FindFirstChild("Container")
end

OtherTab:CreateToggle({
    Name = "Hide UIs",
    CurrentValue = false,
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

OtherTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(enabled)
        local vim = game:GetService("VirtualInputManager")
        local autoWActive = true
        if enabled then
            Silicon:Notify({ Title = "Anti-AFK", Content = "Anti-AFK Enabled."})
            task.spawn(function()
                while enabled and autoWActive do
                    vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                    task.wait(0.02)
                    vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                    task.wait(600)
                end
            end)
        else
            autoWActive = false
            Silicon:Notify({ Title = "Anti-AFK", Content = "Anti-AFK Disabled."})
        end
    end
})

OtherTab:CreateSection("Performance")

OtherTab:CreateToggle({
    Name = "FPS Unlocker",
    CurrentValue = false,
    Callback = function(state)
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

OtherTab:CreateToggle({
    Name = "Show FPS",
    CurrentValue = false,
    Callback = function(state)
        fpsFrame.Enabled = state
    end,
})