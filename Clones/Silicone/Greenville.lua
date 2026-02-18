local Players = game:GetService("Players")
local player = Players.LocalPlayer

local executorName = "Unknown"

pcall(function()
    if identifyexecutor then
        executorName = identifyexecutor()
    end
end)

local allowedExecutors = {
    ["Volt"] = true,
    ["Seliware"] = true,
	["Volcano"] = true,
	["Potassium"] = true,
	["Wave"] = true,
	["Cryptic"] = true,
    ["Bunni"] = true,
    ["ChocoSploit"] = true,
    ["Velocity"] = true,
    ["SirHurt"] = true,
    ["Hydrogen"] = true,
    ["MacSploit"] = true,
    ["Delta"] = true,
    ["Ronix"] = true
}

if not allowedExecutors[executorName] then
    player:Kick("Bad Executor, please get a better one.\nhttps://siliconxploits.xyz/#/executors")
end	

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
    Title = "Silicon for Greenville",
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
        Anonymous = true,
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
    Title = "v0.1.9",
    Color = Color3.fromHex("#0097d7"),
    Radius = 13,
})

Silicon:Notify({Title = "Welcome!", Content = "Enjoy your experience!"})

local UserTab = Window:Tab({ 
    Title = "User",
    Icon = "user", 
    Locked = false,
})

UserTab:Section({ 
    Title = "Extras",
})

UserTab:Input({
    Title = "Fake Money",
    Type = "Input",
    Placeholder = "Enter Amount",
    Callback = function(text)
        local number = text:gsub("%D", "")
        if number == "" then return end

        local formatted = number
        while true do
            formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
            if k == 0 then break end
            task.wait()
        end

        local label
        local success = pcall(function()
            label = LocalPlayer.PlayerGui.UI.Uni.Hud.Money.Label
        end)
        if success and label and label:IsA("TextLabel") then
            label.Text = formatted
            Silicon:Notify({
                Title = "Fake Money",
                Content = "Set your bank balance to: " .. formatted
            })
        else
            Silicon:Notify({
                Title = "Error",
                Content = "Could not find the money label."
            })
        end
    end
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

UserTab:Divider()

UserTab:Input({
    Title = "Nametag Editor",
    Type = "Input",
    Placeholder = "",
    Callback = function(text)
        if text == "" then return end 
        
        local label
        local success = pcall(function()
            label = LocalPlayer.Character.HumanoidRootPart.CNametag.TextLabel
        end)
        if success and label and label:IsA("TextLabel") then
            if not label:GetAttribute("OriginalText") then
                label:SetAttribute("OriginalText", label.Text)
            end

            label.Text = text

            Silicon:Notify({
                Title = "Nametag Editor",
                Content = "Set your nametag to " .. label.Text
            })
        else
            Silicon:Notify({
                Title = "Error",
                Content = "Nametags are not enabled in this server."
            })
        end
    end
})

local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local hideConnection
UserTab:Toggle({
    Title = "Hide Roleplay Nametag",
    Type = "Toggle",
    Value = false,
    Callback = function(value)
        if value then
            Silicon:Notify({
                Title = "Nametags",
                Content = "Your nametag has been removed."
            })

            if hideConnection then 
                hideConnection:Disconnect() 
            end

            hideConnection = RunService.Heartbeat:Connect(function()
                local character = player.Character or player.CharacterAdded:Wait()
                local head = character:FindFirstChild("Head")
                local hrp = character:FindFirstChild("HumanoidRootPart")

                for _, part in ipairs({head, hrp}) do
                    if part then
                        local tag = part:FindFirstChild("CNametag", true)
                        if tag and tag:IsA("GuiBase2d") then
                            tag.Enabled = false
                        end
                    end
                end
            end)

        else
            if hideConnection then 
                hideConnection:Disconnect() 
                hideConnection = nil 
            end

            local character = player.Character
            if character then
                for _, part in ipairs({character:FindFirstChild("Head"), character:FindFirstChild("HumanoidRootPart")}) do
                    if part then
                        local tag = part:FindFirstChild("CNametag", true)
                        if tag and tag:IsA("GuiBase2d") then
                            tag.Enabled = true
                        end
                    end
                end
            end

            Silicon:Notify({
                Title = "Nametags",
                Content = "Your nametag has been restored."
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

local rs = game:GetService("ReplicatedStorage")
VehicleTab:Button({
    Title = "Refuel Vehicle",
    Callback = function()
        Silicon:Notify({
            Title = "Vehicle Refuel",
            Content = "Your vehicle has been successfully refueled."
        })
        rs.Remote.Refuel:FireServer(1, os.time())
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
                        vim:SendKeyEvent(true, Enum.KeyCode.RightBracket, false, game)
                        task.wait(0.02)
                        vim:SendKeyEvent(false, Enum.KeyCode.RightBracket, false, game)
                        task.wait(0.1)
                    end
                end)
                coroutine.resume(strobeThread)
            end
        end
    end
})

VehicleTab:Toggle({
    Title = "Vehicle Tire-Mark Spam",
    Type = "Toggle",
    Value = false,
    Callback = function(enabled)
        Silicon:Notify({
            Title = "Tire Spam",
            Content = enabled and "Spamming has now been activated." or "Spamming has now been deactivated."
        })
        local player = game.Players.LocalPlayer
        local carName = player.Name .. "-Car"
        local sessionVehicles = workspace:WaitForChild("SessionVehicles")

        if getgenv().tireSpamThread then
            getgenv().tireSpamThread = nil
        end

        if enabled then
            getgenv().tireSpamThread = true
            local args = {
                "Update",
                {
                    WheelIntensities = {
                        RL = {Intensity = 5, Surface = "Asphalt"},
                        RR = {Intensity = 5, Surface = "Asphalt"},
                        FR = {Intensity = 5, Surface = "Asphalt"},
                        FL = {Intensity = 5, Surface = "Asphalt"}
                    },
                    Rain = 0,
                    SoundVolumes = {
                        SnowSound = 0,
                        GravelSound = 0,
                        AsphaltSound = 0,
                        RimsSound = 0,
                        SquealSound = 0
                    }
                }
            }
            task.spawn(function()
                while getgenv().tireSpamThread and enabled do
                    local car = sessionVehicles:FindFirstChild(carName)
                    if car and car:FindFirstChild("TireEvent") then
                        car.TireEvent:FireServer(unpack(args))
                    end
                    task.wait(0.001)
                end
            end)
        else
            getgenv().tireSpamThread = nil
        end
    end
})

VehicleTab:Toggle({
    Title = "Vehicle Snow Spam",
    Type = "Toggle",
    Value = false,
    Callback = function(enabled)
        Silicon:Notify({
            Title = "Snow Spam",
            Content = enabled and "Spamming has now been activated." or "Spamming has now been deactivated."
        })
        local player = game.Players.LocalPlayer
        local carName = player.Name .. "-Car"
        local sessionVehicles = workspace:WaitForChild("SessionVehicles")

        if getgenv().tireSpamThread then
            getgenv().tireSpamThread = nil
        end

        if enabled then
            getgenv().tireSpamThread = true
            local args = {
                "Update",
                {
                    WheelIntensities = {
                        RL = {Intensity = 5, Surface = "Snow"},
                        RR = {Intensity = 5, Surface = "Snow"},
                        FR = {Intensity = 5, Surface = "Snow"},
                        FL = {Intensity = 5, Surface = "Snow"}
                    },
                    Rain = 0,
                    SoundVolumes = {
                        SnowSound = 0,
                        GravelSound = 0,
                        AsphaltSound = 0,
                        RimsSound = 0,
                        SquealSound = 0
                    }
                }
            }
            task.spawn(function()
                while getgenv().tireSpamThread and enabled do
                    local car = sessionVehicles:FindFirstChild(carName)
                    if car and car:FindFirstChild("TireEvent") then
                        car.TireEvent:FireServer(unpack(args))
                    end
                    task.wait(0.001)
                end
            end)
        else
            getgenv().tireSpamThread = nil
        end
    end
})

local lowriderToggle = false
local cycleState = 0
local originalSpringValues = {}

local function getPlayerCar()
    local player = game.Players.LocalPlayer
    local carName = player.Name .. "-Car"
    local sessionVehicles = workspace:FindFirstChild("SessionVehicles")
    if not sessionVehicles then return nil end
    return sessionVehicles:FindFirstChild(carName)
end

local function getPlayerCarWheels()
    local car = getPlayerCar()
    if not car then return nil end
    return car:FindFirstChild("Wheels")
end

local function getFrontWheels()
    local Wheels = getPlayerCarWheels()
    if not Wheels then return {} end
    local front = {}
    local FL = Wheels:FindFirstChild("FL")
    local FR = Wheels:FindFirstChild("FR")
    if FL then table.insert(front, FL) end
    if FR then table.insert(front, FR) end
    return front
end

local function getBackWheels()
    local Wheels = getPlayerCarWheels()
    if not Wheels then return {} end
    local back = {}
    local BL = Wheels:FindFirstChild("BL")
    local BR = Wheels:FindFirstChild("BR")
    if BL then table.insert(back, BL) end
    if BR then table.insert(back, BR) end
    return back
end

local function getAllWheels()
    local Wheels = getPlayerCarWheels()
    if not Wheels then return {} end
    local all = {}
    for _, wheel in ipairs(Wheels:GetChildren()) do
        table.insert(all, wheel)
    end
    return all
end

local function storeOriginalSprings()
    local Wheels = getPlayerCarWheels()
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

local function animateToOriginal()
    local Wheels = getPlayerCarWheels()
    if not Wheels then return end
    for _, wheel in ipairs(Wheels:GetChildren()) do
        local spring = wheel:FindFirstChild("Spring")
        local orig = originalSpringValues[wheel.Name]
        if spring and orig then
            local steps, duration = 30, 0.4
            local interval = duration / steps
            local startMin, startMax = spring.MinLength, spring.MaxLength
            local diffMin, diffMax = orig.MinLength - startMin, orig.MaxLength - startMax
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

local function animateWheelSet(wheels, targetSize, duration)
    local steps = 30
    local interval = duration / steps
    for _, wheel in ipairs(wheels) do
        local spring = wheel:FindFirstChild("Spring")
        if spring then
            local startMin, startMax = spring.MinLength, spring.MaxLength
            local diffMin, diffMax = targetSize - startMin, targetSize - startMax
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

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local carFolder = workspace:WaitForChild("SessionVehicles")

local antiFlipEnabled = false
local attached = false
local tiltGyro

local function attachToCar()
	local car = carFolder:FindFirstChild(player.Name .. "-Car")
	if not car or not car.PrimaryPart then return nil end

	if not attached then
		attached = true
		Silicon:Notify({
			Title = "Anti-Flip",
			Content = "Anti-Flip has attached successfully."
		})
	end

	return car
end

local function applyGyro(car)
	if tiltGyro then tiltGyro:Destroy() end

	tiltGyro = Instance.new("BodyGyro")
	tiltGyro.MaxTorque = Vector3.new(4e5, 0, 4e5)
	tiltGyro.P = 6e4
	tiltGyro.CFrame = CFrame.new()
	tiltGyro.Parent = car.PrimaryPart
end

local function enableAntiFlipLoop()
	task.spawn(function()
		while antiFlipEnabled do
			local car = attachToCar()
			if car and car.PrimaryPart then
				if not tiltGyro or tiltGyro.Parent ~= car.PrimaryPart then
					applyGyro(car)
				end

				local cf = car.PrimaryPart.CFrame
				local pos = cf.Position

				local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
				local up = Vector3.new(0,1,0)
				local right = look:Cross(up)

				tiltGyro.CFrame = CFrame.fromMatrix(pos, right, up, look)
			end

			task.wait()
		end

		if tiltGyro then
			tiltGyro:Destroy()
			tiltGyro = nil
		end
	end)
end

VehicleTab:Toggle({
	Title = "Anti-Flip Vehicle",
    Type = "Toggle",
	Value = false,
	Callback = function(Value)
		antiFlipEnabled = Value

		if Value then
			attached = false
			enableAntiFlipLoop()
		else
			if tiltGyro then tiltGyro:Destroy() tiltGyro = nil end
            Silicon:Notify({
			    Title = "Anti-Flip",
			    Content = "Anti-Flip has disconnected successfully."
		    })
		end
	end,
})

local VehicleShaker = {
	running = false,
	thread = nil,
	gyro = nil,
	targetPart = nil,
	originalGyroProps = {},
}

VehicleTab:Toggle({
	Title = "Vehicle Shaker",
    Type = "Toggle",
	Value = false,
	Callback = function(isOn)
		local player = game.Players.LocalPlayer
		local car = workspace.SessionVehicles:FindFirstChild(player.Name .. "-Car")
		if not car then
			VehicleShaker.running = false
			return
		end

		local body = car:FindFirstChild("Body") or car
		local targetPart
		if body:IsA("Model") then
			targetPart = body.PrimaryPart or body:FindFirstChildWhichIsA("BasePart")
		elseif body:IsA("BasePart") then
			targetPart = body
		end
		if not targetPart then
			VehicleShaker.running = false
			return
		end

		local gyro = targetPart:FindFirstChild("VehicleShakerGyro")
		if not gyro then
			gyro = Instance.new("BodyGyro")
			gyro.Name = "VehicleShakerGyro"
			gyro.Parent = targetPart
			gyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
			gyro.P = 1e4
			gyro.D = 500
		end

		if isOn then
			if VehicleShaker.running then return end
			VehicleShaker.running = true
			VehicleShaker.gyro = gyro
			VehicleShaker.targetPart = targetPart
			VehicleShaker.originalGyroProps = {
				CFrame = gyro.CFrame,
				MaxTorque = gyro.MaxTorque,
				P = gyro.P,
				D = gyro.D,
			}

			local baseCF = targetPart.CFrame
			VehicleShaker.thread = task.spawn(function()
				while VehicleShaker.running and gyro.Parent do
					local rx = math.rad(math.random(-5, 5))
					local ry = math.rad(math.random(-5, 5))
					local rz = math.rad(math.random(-5, 5))
					gyro.CFrame = baseCF * CFrame.Angles(rx, ry, rz)
					task.wait(0.05)
				end
			end)
		else
			VehicleShaker.running = false
			if VehicleShaker.gyro then
				local g = VehicleShaker.gyro
				local props = VehicleShaker.originalGyroProps
				if props then
					g.CFrame = props.CFrame
					g.MaxTorque = props.MaxTorque
					g.P = props.P
					g.D = props.D
				end
				g:Destroy()
			end
			VehicleShaker.gyro = nil
			VehicleShaker.targetPart = nil
		end
	end
})

VehicleTab:Toggle({
    Title = "Lowrider Bounce",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        if state then
            Silicon:Notify({
                Title = "Lowrider Bounce",
                Content = "Lowrider Bounce has been enabled."
            })
        else
            Silicon:Notify({
                Title = "Lowrider Bounce",
                Content = "Lowrider Bounce has been disabled."
            })
        end
        local Wheels = getPlayerCarWheels()
        if not Wheels then return end
        if state then
            squattingToggle = false
            vehicleBounceToggle = false
            storeOriginalSprings()
            lowriderToggle = true
            cycleState = 0
            task.spawn(function()
                while lowriderToggle do
                    if cycleState == 0 then
                        animateWheelSet(getFrontWheels(), 3.0, 0.25)
                        cycleState = 1
                    elseif cycleState == 1 then
                        animateWheelSet(getFrontWheels(), 2.0, 0.25)
                        cycleState = 2
                    elseif cycleState == 2 then
                        animateWheelSet(getFrontWheels(), 3.0, 0.25)
                        cycleState = 1
                    end
                    task.wait(0.5)
                end
                animateToOriginal()
            end)
        else
            lowriderToggle = false
            animateToOriginal()
        end
    end
})

local autoSeatEnabled = false
VehicleTab:Toggle({
    Title = "Vehicle Unlocker",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        autoSeatEnabled = state
        if state then
            Silicon:Notify({
                Title = "Vehicle Unlocker",
                Content = "Vehicle Unlocker has been enabled, don't get caught!"
            })
        else
            Silicon:Notify({
                Title = "Vehicle Unlocker",
                Content = "Vehicle Unlocker has been disabled."
            })
        end
    end,
})

local function TrySitVehicleSeat()
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end
    if Humanoid.Sit then return end

    local sessionVehicles = workspace:FindFirstChild("SessionVehicles")
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
            Content = "Are- you in someones car? Is it yours?"
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
    ["Fox Valley Metro Police Department"] = true,
    ["Outagamie County Sheriff's Office"] = true,
    ["Wisconsin State Patrol"] = true,
    ["Outagamie County Communications"] = true,
    ["National Park Service"] = true,
    ["Greenville Fire Rescue"] = true,
    ["Security Guard"] = true
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
        Content = "Radar has been activated.",
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
            Content = "Radar has been deactivated.",
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

            local camerasFolder = workspace:FindFirstChild("_TrafficCameras")
            if camerasFolder then
                for _, cam in pairs(camerasFolder:GetChildren()) do
                    if cam:IsA("BasePart") or cam:IsA("Model") then
                        local camPos = cam:IsA("Model") and cam:GetPivot().Position or cam.Position
                        local distance = (camPos - localHRP.Position).Magnitude
                        if distance <= DetectionDistance then
                            Silicon:Notify({
                                Title = "Radar Alert!",
                                Content = "Traffic Camera detected within " .. math.floor(distance) .. " studs! (K BAND)",
                                Mute = true
                            })
                            soundK:Play()
                        end
                    end
                end
            end

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

VehicleTab:Section({ 
    Title = "Vehicle Radar",
})

VehicleTab:Toggle({
	Title = "Radar Detector",
	Value = false,
	Callback = function(Value)
		ToggleRadar(Value)
	end,
})

VehicleTab:Slider({
    Title = "Detection Distance",
    Step = 5,
    Value = {
        Min = 5,
        Max = 800,
        Default = 100,
    },
    Callback = function(value)
        DetectionDistance = value
    end
})

VehicleTab:Slider({
    Title = "Radar Volume",
    Step = 1,
    Value = {
        Min = 0,
        Max = 5,
        Default = RadarVolume,
    },
    Callback = function(value)
        UpdateRadarVolume(value)
    end
})

VehicleTab:Toggle({
	Title = "Highway Mode",
    Type = "Toggle",
	Value = false,
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

VehicleTab:Section({ 
    Title = "Vehicle Stability",
})

local driftEnabled = false
local driftFriction = 0.1
local angleTweakerEnabled = false
local angleTweakerValue = 1000
local customAngleEnabled = false
local customAngleValue = 30

local function setFriction(part, value)
    if not part or not part:IsA("BasePart") then return false end
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
end

local function modifySteeringD(wheel, value)
    local arm = wheel:FindFirstChild("Arm")
    if arm then
        local steer = arm:FindFirstChildWhichIsA("BodyGyro")
        if steer then steer.D = value end
    end
end

local function modifySteeringAngle(wheel, angle)
    local arm = wheel:FindFirstChild("Arm")
    if arm then
        local hinge = arm:FindFirstChildWhichIsA("HingeConstraint")
        if hinge then hinge.TargetAngle = angle end
    end
end

local function getNearestCarWithin10Studs()
    local player = game.Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local rootPos = player.Character.HumanoidRootPart.Position
    local nearestCar, shortestDistance = nil, 10
    for _, car in pairs(workspace:WaitForChild("SessionVehicles"):GetChildren()) do
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
    for _, wheel in pairs(wheels:GetChildren()) do
        setFriction(wheel, friction)
        if wheel.Name == "FL" or wheel.Name == "FR" then
            modifySteeringD(wheel, angleTweakerEnabled and steerValue or 1000)
            modifySteeringAngle(wheel, customAngleEnabled and customAngleValue or 0)
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

VehicleTab:Toggle({
    Title = "Custom Grip Value",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        driftEnabled = state
        updateVehicleFrictionAndSteering(angleTweakerEnabled and angleTweakerValue or 1000, state and driftFriction or 0.7)
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
        Default = driftFriction,
    },
    Callback = function(val)
        driftFriction = val
        if driftEnabled then
            updateVehicleFrictionAndSteering(angleTweakerEnabled and angleTweakerValue or 1000, driftFriction)
        end
    end
})

VehicleTab:Toggle({
    Title = "AngleTweaker",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        angleTweakerEnabled = state
        updateVehicleFrictionAndSteering(state and angleTweakerValue or 1000, driftFriction)
        Silicon:Notify({
            Title = "AngleTweaker",
            Content = state and "AngleTweaker has been enabled." or "AngleTweaker has been disabled."
        })
    end
})

VehicleTab:Slider({
    Title = "AngleTweaker Value",
    Step = 100,
    Value = {
        Min = 500,
        Max = 8000,
        Default = angleTweakerValue,
    },
    Callback = function(val)
        angleTweakerValue = val
        if angleTweakerEnabled then
            updateVehicleFrictionAndSteering(angleTweakerValue, driftFriction)
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
    local carName = player.Name .. "-Car"
    local sessionVehicles = workspace:FindFirstChild("SessionVehicles")
    if not sessionVehicles then return nil end
    return sessionVehicles:FindFirstChild(carName)
end

local function getPlayerCarWheels()
    local car = getPlayerCar()
    if not car then return nil end
    return car:FindFirstChild("Wheels")
end

local function storeOriginalSprings()
    local Wheels = getPlayerCarWheels()
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

local function animateToOriginal()
    local Wheels = getPlayerCarWheels()
    if not Wheels then return end
    for _, wheel in ipairs(Wheels:GetChildren()) do
        local spring = wheel:FindFirstChild("Spring")
        local orig = originalSpringValues[wheel.Name]
        if spring and orig then
            local steps, duration = 30, 0.4
            local interval = duration / steps
            local startMin, startMax = spring.MinLength, spring.MaxLength
            local diffMin, diffMax = orig.MinLength - startMin, orig.MaxLength - startMax
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
    local Wheels = getPlayerCarWheels()
    if Wheels then
        for _, name in ipairs(wheelNames) do
            local wheel = Wheels:FindFirstChild(name)
            if wheel then
                local spring = wheel:FindFirstChild("Spring")
                if spring then
                    spring.MinLength = size
                    spring.MaxLength = size
                end
            end
        end
    end
end

local function setAllSprings(size)
    local Wheels = getPlayerCarWheels()
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

VehicleTab:Toggle({
    Title = "Custom Suspension",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        suspensionSliderEnabled = state

        if suspensionSliderEnabled then
            local Wheels = getPlayerCarWheels()
            if not Wheels then
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
        Default = 2,
    },
    Callback = function(value)
        if suspensionSliderEnabled then
            setSpringsFor({"FR", "FL"}, value)
        end
    end
})

VehicleTab:Slider({
    Title = "Rear Wheels",
    Step = 0.01,
    Value = {
        Min = 0.7,
        Max = 10,
        Default = 2,
    },
    Callback = function(value)
        if suspensionSliderEnabled then
            setSpringsFor({"RR", "RL"}, value)
        end
    end
})

VehicleTab:Slider({
    Title = "All Wheels",
    Step = 0.01,
    Value = {
        Min = 0.7,
        Max = 10,
        Default = 2,
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

local ECUTab = Window:Tab({
    Title = "ECU",
    Icon = "cpu", 
    Locked = true,
})

ECUTab:Section({ 
    Title = "Tuning",
})

ECUTab:Paragraph({
    Title = "Not supported on Volcano or Solara!",
    Color = "Red",
    ThumbnailSize = 80,
    Locked = false,
})

ECUTab:Paragraph({
    Title = "To apply, jump out and back in of your Vehicle.",
    Color = "Red",
    ThumbnailSize = 80,
    Locked = false,
})

local currentDrivetrain = nil
local ecuDefaultDrivetrain = nil
local ecuDefaultHorsepower
local ecuDefaultFinalDrive
local ecuDefaultRedline
local ecuDefaultPeakRPM
local ecuDefaultWeight

ECUTab:Dropdown({
    Title = "Drivetrain",
    Items = { "RWD", "AWD", "FWD" },
    Default = 1,
    Callback = function(selected)
        local carName = LocalPlayer.Name .. "-Car"
        local sessionVehicles = workspace:FindFirstChild("SessionVehicles")
        if not sessionVehicles then
            Silicon:Notify({Title = "Error", Content = "SessionVehicles not found."})
            return
        end

        local car = sessionVehicles:FindFirstChild(carName)
        if not car then
            return
        end

        local tune = car:FindFirstChild("A-Chassis Tune")
        if not tune then
            Silicon:Notify({Title = "Error", Content = "A-Chassis Tune not found."})
            return
        end

        local success, module = pcall(require, tune)
        if success and module and module.Config then
            if ecuDefaultDrivetrain == nil then
                ecuDefaultDrivetrain = module.Config.Drivetrain
            end

            module.Config.Drivetrain = selected
            currentDrivetrain = selected

            Silicon:Notify({
                Title = "Drivetrain Changed",
                Content = "Drivetrain set to " .. selected .. "."
            })
        else
            Silicon:Notify({Title = "Error", Content = "Failed to set drivetrain."})
        end
    end
})

local ecuHorsepowerInput = nil
ECUTab:Input({
    Title = "Horsepower",
    Placeholder = "",
    Callback = function(text)
        local num = tonumber(text)
        if num and num > 0 then
            ecuHorsepowerInput = num

            local carName = LocalPlayer.Name .. "-Car"
            local sessionVehicles = workspace:FindFirstChild("SessionVehicles")
            if not sessionVehicles then
                Silicon:Notify({Title = "Error", Content = "SessionVehicles not found."})
                return
            end
            local car = sessionVehicles:FindFirstChild(carName)
            if not car then
                return
            end
            local tune = car:FindFirstChild("A-Chassis Tune")
            if not tune then
                Silicon:Notify({Title = "Error", Content = "A-Chassis Tune not found."})
                return
            end

            local success, module = pcall(require, tune)
            if success and module then
                if ecuDefaultHorsepower == nil then
                    ecuDefaultHorsepower = module.Horsepower
                end
                module.Horsepower = ecuHorsepowerInput
                module.E_Horsepower = ecuHorsepowerInput
                Silicon:Notify({Title = "Success", Content = "Horsepower set to: " .. ecuHorsepowerInput})
            else
                Silicon:Notify({Title = "Error", Content = "Failed to require A-Chassis Tune."})
            end
        end
    end
})

local ecuFinalDriveInput = nil
ECUTab:Input({
    Title = "Final Drive",
    Placeholder = "",
    Callback = function(text)
        local numValue = tonumber(text)
        if not numValue or numValue < 0.01 or numValue > 5 then
            return
        end

        ecuFinalDriveInput = numValue

        local carName = LocalPlayer.Name .. "-Car"
        local sessionVehicles = workspace:FindFirstChild("SessionVehicles")
        if not sessionVehicles then
            Silicon:Notify({Title = "Error", Content = "SessionVehicles not found."})
            return
        end
        local car = sessionVehicles:FindFirstChild(carName)
        if not car then
            return
        end
        local tune = car:FindFirstChild("A-Chassis Tune")
        if not tune then
            Silicon:Notify({Title = "Error", Content = "A-Chassis Tune not found."})
            return
        end

        local success, module = pcall(require, tune)
        if success and module then
            if ecuDefaultFinalDrive == nil then
                ecuDefaultFinalDrive = module.FinalDrive
            end
            module.FinalDrive = ecuFinalDriveInput
            Silicon:Notify({Title = "Success", Content = "Final Drive set to: " .. string.format("%.3f", ecuFinalDriveInput)})
        else
            Silicon:Notify({Title = "Error", Content = "Failed to require A-Chassis Tune."})
        end
    end
})

local ecuRedlineInput = nil
ECUTab:Slider({
    Title = "Redline",
    Desc = "",
    Step = 1000,
    Value = {
        Min = 1000,
        Max = 50000,
        Default = 1000,
    },
    Callback = function(value)
        ecuRedlineInput = value
        local carName = LocalPlayer.Name .. "-Car"
        local sessionVehicles = workspace:FindFirstChild("SessionVehicles")
        if not sessionVehicles then
            Silicon:Notify({Title = "Error", Content = "SessionVehicles not found."})
            return
        end
        local car = sessionVehicles:FindFirstChild(carName)
        if not car then
            return
        end
        local tune = car:FindFirstChild("A-Chassis Tune")
        if not tune then
            Silicon:Notify({Title = "Error", Content = "A-Chassis Tune not found."})
            return
        end
        local success, module = pcall(require, tune)
        if success and module then
            if ecuDefaultRedline == nil then
                ecuDefaultRedline = module.Redline
            end
            module.Redline = ecuRedlineInput
        else
            Silicon:Notify({Title = "Error", Content = "Failed to require A-Chassis Tune."})
        end
    end
})

local ecuPeakRPMInput = nil
ECUTab:Slider({
    Title = "RPM",
    Desc = "",
    Step = 1000,
    Value = {
        Min = 1000,
        Max = 50000,
        Default = 1000,
    },
    Callback = function(value)
        ecuPeakRPMInput = value
        local carName = LocalPlayer.Name .. "-Car"
        local sessionVehicles = workspace:FindFirstChild("SessionVehicles")
        if not sessionVehicles then
            Silicon:Notify({Title = "Error", Content = "SessionVehicles not found."})
            return
        end
        local car = sessionVehicles:FindFirstChild(carName)
        if not car then
            return
        end
        local tune = car:FindFirstChild("A-Chassis Tune")
        if not tune then
            Silicon:Notify({Title = "Error", Content = "A-Chassis Tune not found."})
            return
        end
        local success, module = pcall(require, tune)
        if success and module then
            if ecuDefaultPeakRPM == nil then
                ecuDefaultPeakRPM = module.PeakRPM
            end
            module.PeakRPM = ecuPeakRPMInput
        else
            Silicon:Notify({Title = "Error", Content = "Failed to require A-Chassis Tune."})
        end
    end
})

ECUTab:Section({ 
    Title = "Gearbox",
})

ECUTab:Button({
    Title = "Unlock Gearbox",
    Callback = function()
        local carName=LocalPlayer.Name.."-Car"
        local sessionVehicles=workspace:FindFirstChild("SessionVehicles")
        if not sessionVehicles then
            Silicon:Notify({Title="Error",Content="SessionVehicles not found."})
            return
        end
        local car=sessionVehicles:FindFirstChild(carName)
        if not car then
            return
        end
        local tune=car:FindFirstChild("A-Chassis Tune")
        if not tune then
            Silicon:Notify({Title="Error",Content="A-Chassis Tune not found."})
            return
        end
        local success,module=pcall(require,tune)
        if success and module and module.TransModes then
            if module.TransModes[1]=="Auto" and module.TransModes[2]=="Semi" and module.TransModes[3]=="Manual" then
                Silicon:Notify({Title="Gearbox Unlocker",Content="The gearbox is already unlocked."})
            else
                module.TransModes={"Auto","Semi","Manual"}
                Silicon:Notify({Title="Gearbox Unlocker",Content="Gearbox unlocked successfully."})
            end
        else
            Silicon:Notify({Title="Error",Content="Failed to unlock gearbox."})
        end
    end
})

local VisualTab = Window:Tab({
    Title = "Visuals",
    Icon = "eye", 
    Locked = false,
})

VisualTab:Section({ 
    Title = "Camera",
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
local locked = false
local storedCFrame
local connection

VisualTab:Toggle({
    Title = "Camera Lock",
    Type = "Toggle",
    Value = false,
    Callback = function(value)
        Silicon:Notify({
            Title = "Camera Lock",
            Content = value and "Please don't leave me here :(" or "Camera Lock has been disabled."
        })
        locked = value
        if locked then
            storedCFrame = cam.CFrame
            connection = RunService.RenderStepped:Connect(function()
                cam.CFrame = storedCFrame
            end)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
            cam.CameraType = Enum.CameraType.Custom
        end
    end
})

VisualTab:Section({ 
    Title = "Timer",
})

VisualTab:Toggle({
    Title = "Show 0-60 MPH Timer",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        if _G.ZeroToSixtyUI then
            _G.ZeroToSixtyUI.Enabled = state
            return
        end
        if not state then return end

        local CoreGui = game:GetService("CoreGui")
        local lp = Players.LocalPlayer
        local SPEED_MULTIPLIER = 0.56

        local gui = Instance.new("ScreenGui")
        gui.Name = "ZeroToSixtyUI"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 999
        gui.Parent = CoreGui
        _G.ZeroToSixtyUI = gui

        local Frame = Instance.new("Frame", gui)
        Frame.Size = UDim2.new(0, 400, 0, 150)
        Frame.AnchorPoint = Vector2.new(1, 1)
        Frame.Position = UDim2.new(1, -10, 1, -10)
        Frame.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
        Frame.BackgroundTransparency = 0.2
        Frame.BorderSizePixel = 0
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)
        local stroke = Instance.new("UIStroke", Frame)
        stroke.Color = Color3.fromRGB(60, 160, 255)
        stroke.Thickness = 2
        stroke.Transparency = 0.3

        local Title = Instance.new("TextLabel", Frame)
        Title.Size = UDim2.new(0.5, 0, 0.26, 0)
        Title.Position = UDim2.new(0, 22, 0, 14)
        Title.BackgroundTransparency = 1
        Title.Text = "0-60 Timer"
        Title.TextColor3 = Color3.fromRGB(120, 200, 255)
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 24
        Title.TextXAlignment = Enum.TextXAlignment.Left

        local TimerLabel = Instance.new("TextLabel", Frame)
        TimerLabel.Size = UDim2.new(0.48, -10, 0.45, 0)
        TimerLabel.Position = UDim2.new(0.52, -15, 0.15, 0)
        TimerLabel.BackgroundTransparency = 1
        TimerLabel.Text = "0.00s"
        TimerLabel.TextColor3 = Color3.new(1, 1, 1)
        TimerLabel.Font = Enum.Font.GothamBold
        TimerLabel.TextSize = 68
        TimerLabel.TextXAlignment = Enum.TextXAlignment.Right

        local Status = Instance.new("TextLabel", Frame)
        Status.Size = UDim2.new(0.48, 0, 0.22, 0)
        Status.Position = UDim2.new(0, 22, 0.36, 0)
        Status.BackgroundTransparency = 1
        Status.Text = "Ready"
        Status.TextColor3 = Color3.fromRGB(100, 255, 140)
        Status.Font = Enum.Font.GothamBold
        Status.TextSize = 20
        Status.TextXAlignment = Enum.TextXAlignment.Left

        local StartButton = Instance.new("TextButton", Frame)
        StartButton.Size = UDim2.new(0, 160, 0, 38)
        StartButton.Position = UDim2.new(0, 22, 1, -56)
        StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        StartButton.TextColor3 = Color3.new(1, 1, 1)
        StartButton.Font = Enum.Font.GothamBold
        StartButton.TextSize = 18
        StartButton.Text = "START"
        Instance.new("UICorner", StartButton).CornerRadius = UDim.new(0, 10)

        local ResetButton = Instance.new("TextButton", Frame)
        ResetButton.Size = UDim2.new(0, 160, 0, 38)
        ResetButton.Position = UDim2.new(1, -182, 1, -56)
        ResetButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        ResetButton.TextColor3 = Color3.new(1, 1, 1)
        ResetButton.Font = Enum.Font.GothamBold
        ResetButton.TextSize = 18
        ResetButton.Text = "RESET"
        Instance.new("UICorner", ResetButton).CornerRadius = UDim.new(0, 10)

        local dragging = false
        local dragInput, mousePos, framePos

        Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                mousePos = input.Position
                framePos = Frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)

        Frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)

        RunService.RenderStepped:Connect(function()
            if dragging and dragInput then
                local delta = dragInput.Position - mousePos
                Frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            end
        end)

        local timing = false
        local startTime = 0
        local recordedTime = "0.00s"
        local runCompleted = false
        local armed = false

        local function getCar()
            return workspace.SessionVehicles:FindFirstChild(lp.Name .. "-Car")
        end

        local function getSpeed()
            local car = getCar()
            if not car then return 0 end
            local root = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart")
            if not root then return 0 end
            return math.floor(root.Velocity.Magnitude * SPEED_MULTIPLIER + 0.5)
        end

        StartButton.MouseButton1Click:Connect(function()
            local speed = getSpeed()
            if not getCar() then
                Status.Text = "Car Disconnected"
                Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                return
            end
            if speed > 2 then
                Status.Text = "Stop first!"
                Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                task.wait(1.2)
                Status.Text = "Ready"
                Status.TextColor3 = Color3.fromRGB(100, 255, 140)
                return
            end
            armed = true
            Status.Text = "Armed - Go!"
            Status.TextColor3 = Color3.fromRGB(0, 255, 150)
            StartButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            StartButton.Text = "ARMED"
        end)

        ResetButton.MouseButton1Click:Connect(function()
            timing = false
            runCompleted = false
            armed = false
            Status.Text = "Ready"
            Status.TextColor3 = Color3.fromRGB(100, 255, 140)
            TimerLabel.Text = recordedTime
            TimerLabel.TextColor3 = Color3.new(1, 1, 1)
            StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            StartButton.Text = "START"
        end)

        RunService.Heartbeat:Connect(function()
            local speed = getSpeed()
            if not getCar() then
                Status.Text = "No car spawned"
                Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                return
            end
            if runCompleted then
                TimerLabel.Text = recordedTime
                return
            end
            if armed and speed > 2 and not timing then
                timing = true
                startTime = tick()
                Status.Text = "Timing..."
                Status.TextColor3 = Color3.fromRGB(255, 200, 80)
                TimerLabel.Text = "0.00s"
            end
            if timing then
                local elapsed = tick() - startTime
                TimerLabel.Text = string.format("%.2fs", elapsed)
                if speed >= 60 then
                    timing = false
                    runCompleted = true
                    armed = false
                    recordedTime = string.format("%.2fs", elapsed)
                    TimerLabel.Text = recordedTime
                    Status.Text = "Complete!"
                    Status.TextColor3 = Color3.fromRGB(0, 255, 150)
                    TimerLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
                    for i = 1, 6 do
                        TimerLabel.TextColor3 = Color3.new(1, 1, 1)
                        task.wait(0.1)
                        TimerLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
                        task.wait(0.1)
                    end
                    TimerLabel.TextColor3 = Color3.new(1, 1, 1)
                    StartButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
                    StartButton.Text = "START"
                end
            end
        end)
    end
})

VisualTab:Section({ 
    Title = "Vehicle Tricks",
})

local tiltLeftEnabled, tiltRightEnabled, wheelieEnabled = false, false, false
local tiltGyro, tiltAngle = nil, 25

local function getNearestCar()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest, dist = nil, math.huge
    for _, car in pairs(workspace.SessionVehicles:GetChildren()) do
        if car:IsA("Model") and car.PrimaryPart then
            local d = (car.PrimaryPart.Position - root.Position).Magnitude
            if d < dist then nearest, dist = car, d end
        end
    end
    return nearest
end

local function setCarTiltGyro(car, dir)
    if tiltGyro then tiltGyro:Destroy() tiltGyro = nil end
    if dir ~= 0 then
        tiltGyro = Instance.new("BodyGyro", car.PrimaryPart)
        tiltGyro.MaxTorque = Vector3.new(0, 0, 4e4)
        tiltGyro.P = 8e3
        tiltGyro.CFrame = car.PrimaryPart.CFrame * CFrame.Angles(0, 0, math.rad(tiltAngle * dir))
    end
end

local function setCarWheelieGyro(car, enabled)
    if tiltGyro then tiltGyro:Destroy() tiltGyro = nil end
    if enabled then
        tiltGyro = Instance.new("BodyGyro", car.PrimaryPart)
        tiltGyro.MaxTorque = Vector3.new(4e4, 0, 0)
        tiltGyro.P = 8e3
        tiltGyro.CFrame = car.PrimaryPart.CFrame * CFrame.Angles(math.rad(tiltAngle), 0, 0)
    end
end

VisualTab:Toggle({
    Title = "Wheelie",
    Type = "Toggle",
    Value = false,
    Callback = function(s)
        Silicon:Notify({
            Title = "Wheelie Mode",
            Content = s and "Wheelier is now active." or "Wheelier has been disabled."
        })
        wheelieEnabled = s
        tiltLeftEnabled = false
        tiltRightEnabled = false
        local car = getNearestCar()
        if car then setCarWheelieGyro(car, s) end
    end
})

VisualTab:Toggle({
    Title = "Tilt Left",
    Type = "Toggle",
    Value = false,
    Callback = function(s)
        Silicon:Notify({
            Title = "Tilt Mode",
            Content = s and "Tilt Left is now active." or "Tilt Left has been disabled."
        })
        tiltLeftEnabled = s
        tiltRightEnabled = false
        wheelieEnabled = false
        local car = getNearestCar()
        if car then setCarTiltGyro(car, s and 1 or 0) end
    end
})

VisualTab:Toggle({
    Title = "Tilt Right",
    Type = "Toggle",
    Value = false,
    Callback = function(s)
        Silicon:Notify({
            Title = "Tilt Mode",
            Content = s and "Tilt Right is now active." or "Tilt Right has been disabled."
        })
        tiltRightEnabled = s
        tiltLeftEnabled = false
        wheelieEnabled = false
        local car = getNearestCar()
        if car then setCarTiltGyro(car, s and -1 or 0) end
    end
})

VisualTab:Slider({
    Title = "Tilt Angle",
    Value = {Min = 5, Max = 60, Default = 25},
    Step = 1,
    Callback = function(v)
        tiltAngle = v
        local car = getNearestCar()
        if car then
            if tiltLeftEnabled then setCarTiltGyro(car, 1)
            elseif tiltRightEnabled then setCarTiltGyro(car, -1)
            elseif wheelieEnabled then setCarWheelieGyro(car, true) end
        end
    end
})

local AutofarmTab = Window:Tab({
    Title = "Autofarm",
    Icon = "pound-sterling", 
    Locked = false,
})

AutofarmTab:Section({ 
    Title = "Farms",
})

local OLD_PAD_WAIT = 3
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Remote              = ReplicatedStorage:WaitForChild("Remote")

local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remote")
local ChangeJob = Remotes:WaitForChild("ChangeJob")
local AmazonJob = Remotes:WaitForChild("AmazonJob")

getgenv().AmazonDelivery = getgenv().AmazonDelivery or false
getgenv().SaharaRunId = getgenv().SaharaRunId or 0

local deliveredPads, badPads, BAD_TTL = {}, {}, 120

local function bwait(t, runId)
    local deadline = os.clock() + (t or 0)
    while os.clock() < deadline do
        if not getgenv().AmazonDelivery or getgenv().SaharaRunId ~= runId then return false end
        task.wait(math.min(0.1, deadline - os.clock()))
    end
    return true
end

local function pressKey(keyCode, runId)
    if not (getgenv().AmazonDelivery and getgenv().SaharaRunId == runId) then return end
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    bwait(0.05, runId)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function navClick(btn, runId)
    if not btn then return end
    if not (getgenv().AmazonDelivery and getgenv().SaharaRunId == runId) then return end
    GuiService.SelectedObject = btn
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.ButtonA, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.ButtonA, false, game)
    GuiService.SelectedObject = nil
end

local function clearState()
    table.clear(deliveredPads)
    table.clear(badPads)
end

local function isBad(pad)
    local t = badPads[pad]
    if not t then return false end
    if os.clock() - t > BAD_TTL then
        badPads[pad] = nil
        return false
    end
    return true
end

local function markDelivered(pad)
    if pad then deliveredPads[pad] = true end
end

local function markBad(pad)
    if pad then badPads[pad] = os.clock() end
end

local function goToConveyor(runId)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(1328.5792236328125, -73.70349884033203, -9965.841796875)
    task.wait(2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    bwait(0.01, runId)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local BOX_NAMES = {"Large","Long","Medium","Small","SmallLong"}

local function getCount(frame)
    local val = frame:FindFirstChildWhichIsA("IntValue", true)
        or frame:FindFirstChildWhichIsA("NumberValue", true)

    if val then
        return val.Value
    end

    for _, v in ipairs(frame:GetChildren()) do
        if v:IsA("TextLabel") or v:IsA("TextBox") then
            local n = tonumber(v.Text)
            if n then return n end
        end
    end

    return 0
end

local function restockBoxesOnce(runId)
    local gui = LocalPlayer.PlayerGui:FindFirstChild("UI")
    if not gui then return false end

    bwait(0.25, runId)

    local ints = gui:FindFirstChild("Uni")
    ints = ints and ints:FindFirstChild("Interfaces")
    if not ints then return false end

    local checklist = ints:FindFirstChild("AmazonChecklist")
    checklist = checklist and checklist:FindFirstChild("List")

    local buttons = ints:FindFirstChild("BoxSelection")
    buttons = buttons and buttons:FindFirstChild("Buttons")

    if not checklist or not buttons then return false end

    local any = false

    for _, name in ipairs(BOX_NAMES) do
        local frame = checklist:FindFirstChild(name)
        local btn = buttons:FindFirstChild(name)

        if frame and btn then
            local cnt = getCount(frame)
            if cnt > 0 then
                any = true

                for i = 1, cnt do
                    if not (getgenv().AmazonDelivery and getgenv().SaharaRunId == runId) then
                        return any
                    end

                    navClick(btn, runId)
                    bwait(0.03, runId)
                end
            end
        end
    end

    return any
end

local function ensureStock(runId)
    if not restockBoxesOnce(runId) then
        goToConveyor(runId)
        bwait(0.2, runId)
        restockBoxesOnce(runId)
    end
end

local padCache = {}
local padCacheLastRefresh = 0
local PAD_CACHE_TTL = 3

local function refreshPadsCache()
    table.clear(padCache)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "BoxPad" then
            table.insert(padCache, obj)
        end
    end
    padCacheLastRefresh = os.clock()
end

local function getNextPad()
    if os.clock() - padCacheLastRefresh > PAD_CACHE_TTL or #padCache == 0 then
        refreshPadsCache()
    end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local best, minD = nil, math.huge
    for _, obj in ipairs(padCache) do
        if obj:IsDescendantOf(workspace) and not deliveredPads[obj] and not isBad(obj) then
            local d = (hrp.Position - obj.Position).Magnitude
            if d < minD then
                best, minD = obj, d
            end
        end
    end
    return best
end

local function spawnVan(runId)
    local ok = pcall(function()
        SpawnJobVehicle:InvokeServer({ ID = "4548" })
    end)

    local session = workspace:FindFirstChild("SessionVehicles")
    local carName = LocalPlayer.Name .. "-Car"

    if session then
        for _ = 1, 50 do
            local car = session:FindFirstChild(carName)
            if car then
                return true
            end

            if not bwait(0.03, runId) then 
                return false 
            end
        end
    end
    return ok
end

local function deliverAt(pad, runId)
    if not pad or not pad:IsA("BasePart") then return false end
    if getgenv().SaharaRunId ~= runId then return false end

    local player = LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local pos = pad.Position + Vector3.new(0, 4, 0)
    local _, y, _ = hrp.CFrame:ToEulerAnglesYXZ()

    hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, y, 0)

    hrp.Anchored = true
    task.wait(5)
    hrp.Anchored = false

    if getgenv().SaharaRunId ~= runId then return false end

    spawnVan(runId)
    pressKey(Enum.KeyCode.E)

    local AmazonJob = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("AmazonJob")
    local args = { { "C", pad.Position } }

    AmazonJob:InvokeServer(unpack(args));

    return true
end

local function deliverAllPads(runId)
    local emptyTicks = 0
    while getgenv().AmazonDelivery and getgenv().SaharaRunId == runId do
        local pad = getNextPad()
        if not pad then
            emptyTicks += 1
            if emptyTicks >= 12 then return true end
            bwait(0.01, runId)
        else
            emptyTicks = 0
            local delivered = deliverAt(pad, runId)
            if not (getgenv().AmazonDelivery and getgenv().SaharaRunId == runId) then return false end
            if delivered then
                markDelivered(pad)
                bwait(OLD_PAD_WAIT, runId)
            else
                markBad(pad)
                bwait(0.1, runId)
            end
        end
    end
    return false
end

local function hardStop()
    getgenv().AmazonDelivery = false
    getgenv().SaharaRunId = (getgenv().SaharaRunId or 0) + 1
    GuiService.SelectedObject = nil
    clearState()
    pcall(function()
        ChangeJob:InvokeServer("Unemployed")
    end)
end

local function doJobCycle(runId)
    ChangeJob:InvokeServer("Sahara Delivery Worker")
    bwait(0.1, runId)
    AmazonJob:InvokeServer()
    bwait(2, runId)
    goToConveyor(runId)
    bwait(0.1, runId)
    ensureStock(runId)
    clearState()
    deliverAllPads(runId)
end

AutofarmTab:Toggle({
    Title = "Sahara Delivery Worker",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        Silicon:Notify({
            Title = "Sahara Autofarm",
            Content = state and "Autofarm has been started successfully." or "Autofarm has been disabled."
        })

        if not state then
            hardStop()
            return
        end

        getgenv().AmazonDelivery = true
        getgenv().SaharaRunId = getgenv().SaharaRunId + 1
        local runId = getgenv().SaharaRunId
        clearState()

        task.spawn(function()
            while getgenv().AmazonDelivery and getgenv().SaharaRunId == runId do
                doJobCycle(runId)
            end

            if getgenv().SaharaRunId == runId then
                hardStop()
            end
        end)
    end
})

local Amounts = {
    ["250K"]  = 250000,
    ["500K"]  = 500000,
    ["1M"]    = 1000000,
    ["2.5M"]  = 2500000,
    ["5M"]    = 5000000,
    ["7.5M"]  = 7500000,
    ["10M"]   = 10000000,
    ["15M"]   = 15000000,
}

local SelectedAmount = nil
local Checking = false

local function parseMoney(text)
    text = text:gsub(",", "")
    return tonumber(text) or 0
end

local function getPlayerMoney()
    local label = LocalPlayer.PlayerGui
        :WaitForChild("UI")
        :WaitForChild("Uni")
        :WaitForChild("Hud")
        :WaitForChild("Money")
        :WaitForChild("Label")

    return parseMoney(label.Text)
end

local function startChecking()
    if Checking or not SelectedAmount then return end
    Checking = true

    task.spawn(function()
        while Checking do
            local money = getPlayerMoney()

            if money >= SelectedAmount then
                getgenv().AmazonDelivery = false
                getgenv().RoadmapRunning = false
                player:Kick("Silicon | Farming Finished")
                Checking = false
                break
            end

            task.wait(5)
        end
    end)
end

AutofarmTab:Dropdown({
    Title = "Stop Farming At",
    Values = {
        "250K",
        "500K",
        "1M",
        "2.5M",
        "5M",
        "7.5M",
        "10M",
        "15M"
    },
    Callback = function(value)
        SelectedAmount = Amounts[value]
        startChecking()
    end
})

AutofarmTab:Toggle({
   Title = "Private Server Protection",
   Type = "Toggle",
   Value = false,
   Callback = function(Value)
       
       if Value then
           if #Players:GetPlayers() > 1 then
               LocalPlayer:Kick("Silicon Protect | Another User Joined.")
           end

           Players.PlayerAdded:Connect(function(player)
               if AutoKickToggle.CurrentValue then
                   LocalPlayer:Kick("Silicon Protect | Another User Joined.")
               end
           end)
       end
   end,
})

AutofarmTab:Divider()

AutofarmTab:Paragraph({
    Title = "Make sure to start the event first!",
    Color = "Red",
    ThumbnailSize = 80,
    Locked = false,
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local scanning = false

AutofarmTab:Toggle({
    Title = "Lunar New Year | Autocomplete",
    Type = "Toggle",
    Value = false,
    Callback = function(Value)
        scanning = Value
        
        if not Value then return end
        
        while scanning do
            local character = player.Character or player.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local folder = workspace:FindFirstChild("LunarNewYearItems")
                
                if folder then
                    for _, model in ipairs(folder:GetDescendants()) do
                        if not scanning then break end
                        
                        if model:IsA("ProximityPrompt") then
                            local parentModel = model:FindFirstAncestorOfClass("Model")
                            
                            if parentModel then
                                local part = parentModel:FindFirstChildWhichIsA("BasePart", true)
                                
                                if part then
                                    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                                    
                                    task.wait(0.2)
                                    
                                    fireproximityprompt(model)
                                    
                                    task.wait(1.81)
                                end
                            end
                        end
                    end
                end
            end
            
            task.wait(1.8)
        end
    end,
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
                    VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.1)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)

                    for _ = 1, 300 do
                        if not enabled then break end
                        task.wait(1)
                    end
                end
                VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                thread = nil
            end)
        else
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
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