local Silicon = loadstring(game:HttpGet("https://api.siliconxploits.xyz/notify"))()

loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Anti-Kick/main/Anti-Kick.lua"))()

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
    Title = "Silicon for Murder Mystery 2",
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
    Title = "v0.0.3",
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

local walkspeedEnabled = false
local originalWalkSpeed = 16
local currentWalkSpeed = 16
local walkspeedConnection
UserTab:Toggle({
    Title = "WalkSpeed",
    Type = "Toggle",
    Value = false,  
    Callback = function(Value)
        walkspeedEnabled = Value
        
        Silicon:Notify({
            Title = "WalkSpeed",
            Content = Value and "WalkSpeed has been enabled." or "WalkSpeed has been disabled."
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

UserTab:Slider({
    Title = "WalkSpeed Value",
    Step = 1, 
    Value = {
        Min = 16,
        Max = 500,
        Default = 16
    },
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

UserTab:Divider()

local jumppowerEnabled = false
local originalJumpPower = 50
local currentJumpPower = 50
local jumppowerConnection
UserTab:Toggle({
    Title = "JumpPower",
    Type = "Toggle",
    Value = false,  
    Callback = function(state)
        jumppowerEnabled = state

        Silicon:Notify({
            Title = "JumpPower",
            Content = state and "JumpPower has been enabled." or "JumpPower has been disabled."
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

UserTab:Slider({
    Title = "JumpPower Value",
    Step = 1,
    Value = {
        Min = 50,
        Max = 500,
        Default = 50
    },
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

UserTab:Divider()

local flyEnabled = false
local flySpeed = 100
local flyBV = nil
UserTab:Toggle({
    Title = "Fly",
    Type = "Toggle",
    Value = false,  
    Callback = function(state)
        flyEnabled = state

        Silicon:Notify({
            Title = "Fly",
            Content = state and "Fly has been enabled." or "Fly has been disabled."
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

UserTab:Slider({
    Title = "Fly Speed",
    Step = 5,
    Value = { Min = 16, Max = 500, Default = 100 },
    Callback = function(value)
        flySpeed = value
    end
})

UserTab:Divider()

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

UserTab:Divider()

UserTab:Button({
    Title = "Jerk Off (R15)",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))()
        Silicon:Notify({
            Title = "Trolling",
            Content = "R15 Animation has been given."
        })
    end,
})

UserTab:Button({
    Title = "Jerk Off (R6)",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/wa3v2Vgm/raw"))()
        Silicon:Notify({
            Title = "Trolling",
            Content = "R6 Animation has been given."
        })
    end,
})

UserTab:Divider()

local infiniteJumpEnabled = false
local infiniteJumpConnection = nil
UserTab:Toggle({
    Title = "Infinite Jump",
    Type = "Toggle",
    Value = false,  
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
            Silicon:Notify({
                Title = "Infinite Jump",
                Content = "Infinite Jump has been enabled."
            })
        else
            if infiniteJumpConnection then
                infiniteJumpConnection:Disconnect()
                infiniteJumpConnection = nil
            end
            Silicon:Notify({
                Title = "Infinite Jump",
                Content = "Infinite Jump has been disabled."
            })
        end
    end
})

UserTab:Button({
    Title = "Respawn",
    Locked = false,
    Callback = function()
        LocalPlayer.Character:FindFirstChild("Humanoid").Health = 0
        Silicon:Notify({
            Title = "Respawn",
            Content = "Respawning in 1 second..."
        })
    end
})

local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "blend", 
    Locked = false,
})

TeleportTab:Button({
    Title = "Teleport to Spawn",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.CFrame = CFrame.new(5.512490272521973, 511.2376403808594, -16.91254425048828)
        Silicon:Notify({
            Title = "Teleport",
            Content = "You have been teleported to spawn."
        })
    end,
})

TeleportTab:Button({
    Title = "Teleport to Voting Room",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.CFrame = CFrame.new(13.602983474731445, 511.2393798828125, 35.73230743408203)
        Silicon:Notify({
            Title = "Teleport",
            Content = "You have been teleported to the voting room."
        })
    end,
})

TeleportTab:Button({
    Title = "Teleport to Secret Room",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.CFrame = CFrame.new(-28.42108917236328, 525.165283203125, 64.25765228271484)
        Silicon:Notify({
            Title = "Teleport",
            Content = "You have been teleported to the secret room."
        })
    end,
})

TeleportTab:Divider()

TeleportTab:Button({
    Title = "TP to Murderer",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local murderer = nil
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local team = p:FindFirstChild("Team")
                if team and team.Name == "Murderer" then
                    murderer = p
                    break
                end
                if p.Character:FindFirstChildOfClass("Tool") then
                    murderer = p
                    break
                end
            end
        end
        
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            humanoidRootPart.CFrame = murderer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
            Silicon:Notify({
                Title = "Teleport",
                Content = "You have been teleported to Murderer."
            })
        else
            Silicon:Notify({
                Title = "Error",
                Content = "Murderer not found!"
            })
        end
    end,
})

TeleportTab:Button({
    Title = "TP to Sheriff",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        local sheriff = nil
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local team = p:FindFirstChild("Team")
                if team and team.Name == "Sheriff" then
                    sheriff = p
                    break
                end
                local tool = p.Character:FindFirstChildOfClass("Tool")
                if tool and (tool.Name:lower():find("gun") or tool.Name:lower():find("sheriff")) then
                    sheriff = p
                    break
                end
            end
        end
        
        if sheriff and sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart") then
            humanoidRootPart.CFrame = sheriff.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
            Silicon:Notify({
                Title = "Teleport",
                Content = "You have been teleported to Sheriff."
            })
        else
            Silicon:Notify({
                Title = "Error",
                Content = "Sheriff not found!"
            })
        end
    end,
})

TeleportTab:Button({
    Title = "TP to Random Player",
    Locked = false,
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        local validPlayers = {}
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(validPlayers, p)
            end
        end
        
        if #validPlayers > 0 then
            local randomPlayer = validPlayers[math.random(1, #validPlayers)]
            humanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
            Silicon:Notify({
                Title = "Teleport",
                Content = "You have been teleported to " .. randomPlayer.Name .. "."
            })
        else
            Silicon:Notify({
                Title = "Error",
                Content = "No other players found!"
            })
        end
    end,
})

local CombatTab = Window:Tab({
    Title = "Combat",
    Icon = "crosshair", 
    Locked = false,
})

CombatTab:Section({ 
    Title = "Sherrif",
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local AimbotEnabled = false
local TargetPart = "Head"

local function hasKnife(plr)
    for _, tool in pairs(plr.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("knife") then return true end
    end
    for _, tool in pairs(plr.Character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("knife") then return true end
    end
    return false
end

local function GetMurderer()
    for _, plr in Players:GetPlayers() do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(TargetPart) and hasKnife(plr) then
            return plr
        end
    end
    return nil
end

RunService.Heartbeat:Connect(function()
    if not AimbotEnabled then return end
    
    local murderer = GetMurderer()
    if murderer and murderer.Character then
        local headPos = murderer.Character[TargetPart].Position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, headPos)
    end
end)

CombatTab:Toggle({
    Title = "Aimbot",
    Default = false,
    Callback = function(state)
        Silicon:Notify({
            Title = "Aimbot",
            Content = state and "Aimbot has been enabled." or "Aimbot has been disabled."
        })
        AimbotEnabled = state
    end
})

local ESPTab = Window:Tab({
    Title = "ESP",
    Icon = "brick-wall", 
    Locked = false,
})

local espHighlights = {}
local espEnabled = {murderer = false, sheriff = false, innocent = false}

local function clearAllESP()
    for player, highlight in pairs(espHighlights) do
        if highlight then highlight:Destroy() end
    end
    espHighlights = {}
end

local function hasKnife(player)
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("knife") then return true end
    end
    for _, tool in pairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("knife") then return true end
    end
    return false
end

local function hasGun(player)
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("gun") then return true end
    end
    for _, tool in pairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("gun") then return true end
    end
    return false
end

local function backpackEmpty(player)
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then return false end
    end
    for _, tool in pairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") then return false end
    end
    return true
end

local function updateESP()
    clearAllESP()
    local player = game.Players.LocalPlayer
    
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if espEnabled.murderer and hasKnife(p) then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.new(1, 0, 0)
                highlight.OutlineColor = Color3.new(1, 1, 1)
                highlight.FillTransparency = 0.3
                highlight.OutlineTransparency = 0
                highlight.Adornee = p.Character
                highlight.Parent = p.Character
                espHighlights[p] = highlight
            elseif espEnabled.sheriff and hasGun(p) then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.new(0, 0.5, 1)
                highlight.OutlineColor = Color3.new(1, 1, 1)
                highlight.FillTransparency = 0.3
                highlight.OutlineTransparency = 0
                highlight.Adornee = p.Character
                highlight.Parent = p.Character
                espHighlights[p] = highlight
            elseif espEnabled.innocent and backpackEmpty(p) then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.new(0, 1, 0)
                highlight.OutlineColor = Color3.new(1, 1, 1)
                highlight.FillTransparency = 0.3
                highlight.OutlineTransparency = 0
                highlight.Adornee = p.Character
                highlight.Parent = p.Character
                espHighlights[p] = highlight
            end
        end
    end
end

ESPTab:Toggle({
    Title = "Murderer ESP",
    Type = "Toggle",
    Value = false,  
    Callback = function(state)
        Silicon:Notify({
            Title = "ESP",
            Content = state and "ESP has been enabled." or "ESP has been disabled."
        })
        espEnabled.murderer = state
        updateESP()
    end
})

ESPTab:Toggle({
    Title = "Sheriff ESP",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        Silicon:Notify({
            Title = "ESP",
            Content = state and "ESP has been enabled." or "ESP has been disabled."
        })
        espEnabled.sheriff = state
        updateESP()
    end
})

ESPTab:Toggle({
    Title = "Innocent ESP",
    Type = "Toggle",
    Value = false,  
    Callback = function(state)
        Silicon:Notify({
            Title = "ESP",
            Content = state and "ESP has been enabled." or "ESP has been disabled."
        })
        espEnabled.innocent = state
        updateESP()
    end
})

spawn(function()
    while wait(1) do
        if espEnabled.murderer or espEnabled.sheriff or espEnabled.innocent then
            updateESP()
        end
    end
end)

game.Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        wait(0.5)
        updateESP()
    end)
end)

local nameESPEnabled = false
local nameBillboards = {}

local function clearNameESP()
    for _, billboard in pairs(nameBillboards) do
        pcall(function() billboard:Destroy() end)
    end
    nameBillboards = {}
end

local function updateNameESP()
    if not nameESPEnabled then return end
    
    clearNameESP()
    local player = game.Players.LocalPlayer
    
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "NameESP"
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 120, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.Parent = head
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = p.Name
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.TextScaled = true
            label.Font = Enum.Font.SourceSansBold
            label.Parent = billboard
            
            table.insert(nameBillboards, billboard)
        end
    end
end

ESPTab:Toggle({
    Title = "Name ESP",
    Default = false,
    Callback = function(state)
        Silicon:Notify({
            Title = "ESP",
            Content = state and "ESP has been enabled." or "ESP has been disabled."
        })
        nameESPEnabled = state
        if state then
            updateNameESP()
            spawn(function()
                while nameESPEnabled do
                    wait(1)
                    pcall(updateNameESP)
                end
            end)
        else
            clearNameESP()
        end
    end
})

game.Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        wait(0.5)
        if nameESPEnabled then
            updateNameESP()
        end
    end)
end)

local ServerTab = Window:Tab({
    Title = "Server",
    Icon = "server", 
    Locked = false,
})

ServerTab:Button({
    Title = "Rejoin",
    Locked = false,
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        Silicon:Notify({
            Title = "Rejoin",
            Content = "Rejoining server in 1 second..."
        })
    end
})

ServerTab:Button({
    Title = "Server Hop",
    Locked = false,
    Callback = function()
        local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        local bestServer = nil
        local highestPlayerCount = 0
        
        for _, server in pairs(servers.data) do
            if server.playing > highestPlayerCount and server.id ~= game.JobId then
                highestPlayerCount = server.playing
                bestServer = server.id
            end
        end
        
        if bestServer then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, bestServer, LocalPlayer)
            Silicon:Notify({
                Title = "Server Hop",
                Content = "Hopping to a different server."
            })
        else
            Silicon:Notify({
                Title = "Server Hop",
                Content = "No good servers have been found!",
                Duration = 5
            })
        end
    end
})

local AutofarmTab = Window:Tab({
    Title = "Autofarm",
    Icon = "pound-sterling",
    Locked = false,
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local running = false
local TELEPORT_DELAY = 3
local RESCAN_DELAY = 0.5 -- how often to check when no coins exist

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoidRootPart()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

local function getAllCoins()
    local coins = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
            table.insert(coins, obj)
        end
    end

    return coins
end

local function teleportLoop()
    while running do
        local hrp = getHumanoidRootPart()
        local coins = getAllCoins()

        -- If no coins exist (between rounds), just wait and keep scanning
        if #coins == 0 then
            task.wait(RESCAN_DELAY)
        else
            for _, coin in ipairs(coins) do
                if not running then return end

                -- coin might despawn mid-loop
                if coin and coin.Parent then
                    hrp.CFrame = coin.CFrame + Vector3.new(0, 3, 0)
                    task.wait(TELEPORT_DELAY)
                end
            end
        end
    end
end

AutofarmTab:Toggle({
    Title = "Coin Autofarm",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        running = state

        if state then
            task.spawn(teleportLoop)
        end
    end
})

local VIM = game:GetService("VirtualInputManager")
local enabled = false
local thread
AutofarmTab:Toggle({
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

Window:Divider()

local InfoTab = Window:Tab({
    Title = "Script Info",
    Icon = "info",
    Locked = true,
})