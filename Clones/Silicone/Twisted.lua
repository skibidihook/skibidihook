local Silicon = loadstring(game:HttpGet("https://api.siliconxploits.xyz/notify"))()

local coreGui = game:GetService("CoreGui")
local ui = coreGui:FindFirstChild("SiliconUI")

if ui then
    ui:Destroy()
end

local SiliconUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/sxytdi/Silicon/refs/heads/main/UI/SiliconUI/main.lua"))()

local Window = SiliconUI:CreateWindow({
    Name            = "Silicon for Twisted",
    LoadingTitle    = "Silicon",
    LoadingSubtitle = "v0.0.2",
    ToggleKey       = Enum.KeyCode.K,
})

Window:Notify({
    Title    = "Welcome!",
    Content  = "Enjoy your experience.",
    Duration = 5,
    Type     = "Success",
})

local ESPTab = Window:CreateTab({ Name = "ESP" })

ESPTab:CreateSection("Sight")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local espEnabled = false
local espHighlights = {}

local function clearAllESP()
    for _, highlight in pairs(espHighlights) do
        if highlight then highlight:Destroy() end
    end
    espHighlights = {}
end

local function updateESP()
    clearAllESP()
    if not espEnabled then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.new(1, 0, 0)
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 0
            highlight.Adornee = player.Character
            highlight.Parent = player.Character
            espHighlights[player] = highlight
        end
    end
end

ESPTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Callback = function(state)
        Window:Notify({
            Title = "ESP",
            Content = state and "ESP has been enabled." or "ESP has been disabled.",
            Duration = 5,
            Type = "Success",
        })

        espEnabled = state
        updateESP()
    end
})

task.spawn(function()
    while task.wait(1) do
        if espEnabled then
            updateESP()
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
end)

local HumanoidTab = Window:CreateTab({ Name = "Humanoid" })

HumanoidTab:CreateSection("Abilites")

local walkspeedEnabled = false
local originalWalkSpeed = 16
local currentWalkSpeed = 16
local walkspeedConnection
HumanoidTab:CreateToggle({
    Name = "WalkSpeed",
    CurrentValue = false,  
    Callback = function(Value)
        walkspeedEnabled = Value
        
        Window:Notify({
            Title = "WalkSpeed",
            Content = Value and "WalkSpeed has been enabled." or "WalkSpeed has been disabled.",
            Duration = 5,
            Type = "Success",
        })

        if Value then
            walkspeedConnection = RunService.Heartbeat:Connect(function()
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = currentWalkSpeed
                    end
                end
            end)
        else
            if walkspeedConnection then
                walkspeedConnection:Disconnect()
                walkspeedConnection = nil
            end
            
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = originalWalkSpeed
                end
            end
        end
    end
})

HumanoidTab:CreateSlider({
    Title = "WalkSpeed Value",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 16,
    Suffix = "",
    Callback = function(Value)
        currentWalkSpeed = Value
        if walkspeedEnabled and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Value
            end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1) 
    originalWalkSpeed = 16 
    
    if walkspeedEnabled then
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = currentWalkSpeed
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    local humanoid = character:WaitForChild("Humanoid")
    originalWalkSpeed = humanoid.WalkSpeed
end)

local jumppowerEnabled = false
local originalJumpPower = 50
local currentJumpPower = 50
local jumppowerConnection
HumanoidTab:CreateToggle({
    Name = "JumpPower",
    CurrentValue = false,  
    Callback = function(state)
        jumppowerEnabled = state

        Window:Notify({
            Title = "JumpPower",
            Content = state and "JumpPower has been enabled." or "JumpPower has been disabled.",
            Duration = 5,
            Type = "Success",
        })

        if state then
            jumppowerConnection = RunService.Heartbeat:Connect(function()
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.JumpPower = currentJumpPower
                    end
                end
            end)
        else
            if jumppowerConnection then
                jumppowerConnection:Disconnect()
                jumppowerConnection = nil
            end
            
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.JumpPower = originalJumpPower
                end
            end
        end
    end
})

HumanoidTab:CreateSlider({
    Name = "JumpPower Value",
    Range = {50, 500},
    Increment = 1,
    CurrentValue = 50,
    Suffix = "",
    Callback = function(value)
        currentJumpPower = value
        if jumppowerEnabled and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.JumpPower = value
            end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1) 
    originalJumpPower = 50 
    
    if jumppowerEnabled then
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.JumpPower = currentJumpPower
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.1)
    local humanoid = character:WaitForChild("Humanoid")
    originalJumpPower = humanoid.JumpPower
end)

HumanoidTab:CreateSection("Flying")

local flyEnabled = false
local flySpeed = 100
local flyBV = nil
HumanoidTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,  
    Callback = function(state)
        flyEnabled = state

        Window:Notify({
            Title = "Fly",
            Content = state and "Fly has been enabled." or "Fly has been disabled.",
            Duration = 5,
            Type = "Success",
        })

        if state then
            local character = game.Players.LocalPlayer.Character
            if not character or not character:FindFirstChild("HumanoidRootPart") then return end

            flyBV = Instance.new("BodyVelocity")
            flyBV.Name = "WindUIFly"
            flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBV.Velocity = Vector3.new(0, 0, 0)
            flyBV.Parent = character.HumanoidRootPart

            spawn(function()
                while flyEnabled and task.wait() do
                    local uis = game:GetService("UserInputService")
                    if uis:GetFocusedTextBox() then
                        flyBV.Velocity = Vector3.new(0, 0, 0)
                        continue
                    end

                    local cam = workspace.CurrentCamera
                    local move = Vector3.new(
                        (uis:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (uis:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                        (uis:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (uis:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
                        (uis:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (uis:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
                    )

                    if move.Magnitude > 0 then
                        flyBV.Velocity = cam.CFrame:VectorToWorldSpace(move.Unit) * flySpeed
                    else
                        flyBV.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end)
        else
            if flyBV and flyBV.Parent then
                flyBV:Destroy()
                flyBV = nil
            end
        end
    end
})

HumanoidTab:CreateSlider({
    Name = "Fly Speed",
    Range = {16, 500},
    Increment = 5,
    CurrentValue = 100,
    Suffix = "",
    Callback = function(value)
        flySpeed = value
    end
})

HumanoidTab:CreateSection("Clipping")

local noclipEnabled = false
HumanoidTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,  
    Callback = function(Value)
        noclipEnabled = Value
        Window:Notify({
            Title = "NoClip",
            Content = Value and "NoClip has been enabled." or "NoClip has been disabled.",
            Duration = 5,
            Type = "Success",
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

HumanoidTab:CreateSection("Trolling")

HumanoidTab:CreateButton({
    Name = "Jerk Off (R15)",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))()
        Window:Notify({
            Title = "Trolling",
            Content = "R15 Animation has been given.",
            Duration = 5,
            Type = "Success",
        })
    end,
})

HumanoidTab:CreateButton({
    Name = "Jerk Off (R6)",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/wa3v2Vgm/raw"))()
        Window:Notify({
            Title = "Trolling",
            Content = "R6 Animation has been given.",
            Duration = 5,
            Type = "Success",
        })
    end,
})

HumanoidTab:CreateSection("Jumping")

local infiniteJumpEnabled = false
local infiniteJumpConnection = nil
HumanoidTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,  
    Callback = function(Value)
        infiniteJumpEnabled = Value
        
        if Value then
            infiniteJumpConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.Space then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
            Window:Notify({
                Title = "Infinite Jump",
                Content = "Infinite Jump has been enabled."
            })
        else
            if infiniteJumpConnection then
                infiniteJumpConnection:Disconnect()
                infiniteJumpConnection = nil
            end
            Window:Notify({
                Title = "Infinite Jump",
                Content = "Infinite Jump has been disabled.",
                Duration = 5,
                Type = "Success",
            })
        end
    end
})

HumanoidTab:CreateSection("Spawning")

HumanoidTab:CreateButton({
    Name = "Respawn",
    Callback = function()
        LocalPlayer.Character:FindFirstChild("Humanoid").Health = 0
        Window:Notify({
            Title = "Respawn",
            Content = "Respawning in 1 second...",
            Duration = 5,
            Type = "Success",
        })
    end
})

local ViewTab = Window:CreateTab({ Name = "View" })

ViewTab:CreateSection("Lighting")

local Lighting = game:GetService("Lighting")

local Original = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
	FogColor = Lighting.FogColor,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ExposureCompensation = Lighting.ExposureCompensation,
}

local FullbrightEnabled = false

local function ApplyFullbright()
	Lighting.Brightness = 3
	Lighting.ClockTime = 14
	Lighting.FogStart = 0
	Lighting.FogEnd = 1e9
	Lighting.GlobalShadows = false
	Lighting.Ambient = Color3.fromRGB(255, 255, 255)
	Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	Lighting.ExposureCompensation = 0
end

local function RestoreLighting()
	for k, v in pairs(Original) do
		Lighting[k] = v
	end
end

local conn
local function Hook()
	if conn then conn:Disconnect() end
	conn = Lighting.Changed:Connect(function()
		if FullbrightEnabled then
			ApplyFullbright()
		end
	end)
end

ViewTab:CreateToggle({
	Name = "Fullbright",
	CurrentValue = false,
	Callback = function(Value)
		FullbrightEnabled = Value
		if Value then
			Original.Brightness = Lighting.Brightness
			Original.ClockTime = Lighting.ClockTime
			Original.FogEnd = Lighting.FogEnd
			Original.FogStart = Lighting.FogStart
			Original.FogColor = Lighting.FogColor
			Original.GlobalShadows = Lighting.GlobalShadows
			Original.Ambient = Lighting.Ambient
			Original.OutdoorAmbient = Lighting.OutdoorAmbient
			Original.ExposureCompensation = Lighting.ExposureCompensation

			ApplyFullbright()
			Hook()
		else
			if conn then conn:Disconnect() conn = nil end
			RestoreLighting()
		end
	end
})

local AutofarmTab = Window:CreateTab({ Name = "Autofarm" })

AutofarmTab:CreateSection("wadafak")

AutofarmTab:CreateParagraph({
    Title = "Notice",
    Content = "Autofarm will come in a later update, while waiting, suggest some fire features."
})

task.wait(2)

Window:Notify({
    Title    = "Tip",
    Content  = "Press K to toggle the UI.",
    Duration = 4,
    Type     = "Info",
})