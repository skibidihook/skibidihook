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
    Title = "Silicon for Central Kansas",
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

Silicon:Notify({Title = "Welcome!", Content = "Enjoy your experience!"})

local UserTab = Window:Tab({ 
    Title = "User",
    Icon = "user", 
    Locked = false,
})

UserTab:Section({ 
    Title = "Humanoid",
})

local noclipEnabled = false
UserTab:Toggle({
    Title = "NoClip",
    Type = "Toggle";
    Value = false,
    Callback = function(Value)
        noclipEnabled = Value
        Silicon:Notify({
            Title = "NoClip",
            Content = Value and "NoClip has been enabled." or "NoClip has been disabled."
        })
    end,
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

VehicleTab:Button({
    Title = "Toggle All Vehicle-Doors",
    Locked = false,
    Callback = function()
        Silicon:Notify({
            Title = "Toggle Doors",
            Content = "All Vehicle-Doors have been toggled."
        })
        local folder = workspace:WaitForChild("PlayerVehicles")

        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("ClickDetector") then
                pcall(function()
                    fireclickdetector(obj)
                end)
            end
        end
    end
})

VehicleTab:Section({ 
    Title = "Vehicle Features",
})

local clickSpamActive = false
local clickSpamThread
VehicleTab:Toggle({
    Title = "Spam Vehicle-Doors",
    Type = "Toggle",
    Value = false,
    Callback = function(enabled)
        clickSpamActive = enabled

        if enabled then
            Silicon:Notify({
                Title = "Door Spammer",
                Content = "Door Spammer has been enabled."
            })
            if not clickSpamThread or coroutine.status(clickSpamThread) == "dead" then
                clickSpamThread = coroutine.create(function()
                    while clickSpamActive do
                        local folder = workspace:FindFirstChild("PlayerVehicles")
                        if folder then
                            for _, obj in ipairs(folder:GetDescendants()) do
                                if obj:IsA("ClickDetector") then
                                    pcall(function()
                                        fireclickdetector(obj)
                                    end)
                                end
                            end
                        end

                        task.wait(0.5)
                    end
                end)

                coroutine.resume(clickSpamThread)
            end
        else
            local clickSpamActive = false
            Silicon:Notify({
                Title = "Door Spammer",
                Content = "Door Spammer has been disabled."
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
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local launchEnabled = false
local heightConnection = nil
local velocityPower = 3000
local pushTime = 1

local savedCFrame = nil
local savedLockedY = nil

local function getVehicleSeat()
	local character = LocalPlayer.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local seat = humanoid.SeatPart
	if seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then
		return seat
	end
	return nil
end

AutofarmTab:Toggle({
	Title = "Drive-To-Earn",
    Type = "Toggle",
	Value = false,
	Callback = function(Value)
		launchEnabled = Value
		if Value then
			local seat = getVehicleSeat()
			if not seat then
				Silicon:Notify({
					Title = "Error",
					Content = "No vehicle seat found!"
				})
				launchEnabled = false
				return
			end

			savedCFrame = seat.CFrame

			savedLockedY = seat.Position.Y + 500

			if heightConnection then
				heightConnection:Disconnect()
			end

			heightConnection = RunService.RenderStepped:Connect(function()
				if not launchEnabled then
					heightConnection:Disconnect()
					heightConnection = nil
					return
				end
				local currentSeat = getVehicleSeat()
				if currentSeat and savedLockedY then
					pcall(function()
						local currentPos = currentSeat.Position
						local _, ry, _ = currentSeat.CFrame:ToEulerAnglesYXZ()
						currentSeat.CFrame = CFrame.new(currentPos.X, savedLockedY, currentPos.Z) * CFrame.Angles(0, ry, 0)
						local vel = currentSeat.AssemblyLinearVelocity
						currentSeat.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
					end)
				end
			end)

			task.spawn(function()
				while launchEnabled do
					local currentSeat = getVehicleSeat()
					if currentSeat then
						pcall(function()
							local lookVector = currentSeat.CFrame.LookVector
							currentSeat.AssemblyLinearVelocity = Vector3.new(
								lookVector.X * velocityPower,
								0,
								lookVector.Z * velocityPower
							)
						end)

						task.wait(pushTime)

						if savedCFrame and savedLockedY then
							pcall(function()
								local _, ry, _ = currentSeat.CFrame:ToEulerAnglesYXZ()
								local originalPos = savedCFrame.Position
								currentSeat.CFrame = CFrame.new(originalPos.X, savedLockedY, originalPos.Z) * CFrame.Angles(0, ry, 0)
								currentSeat.AssemblyLinearVelocity = Vector3.zero
							end)
						end
					end
					task.wait(0.05)
				end
			end)

			Silicon:Notify({
				Title = "Drive-To-Earn",
				Content = "DTE is now enabled, become rich!"
			})
		else
			if heightConnection then
				heightConnection:Disconnect()
				heightConnection = nil
			end

			local seat = getVehicleSeat()
			if seat then
				pcall(function()
					seat.AssemblyLinearVelocity = Vector3.zero
				end)

				if savedCFrame then
					pcall(function()
						seat.CFrame = savedCFrame
					end)
				end
			end

			Silicon:Notify({
				Title = "Drive-To-Earn",
				Content = "DTE is now disabled."
			})
		end
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
local function isSiliconGui(gui)
    return gui.Name:lower():find("Silicon") or gui:FindFirstChild("Topbar") or gui:FindFirstChild("Container")
end

OtherTab:Toggle({
    Title = "Hide UIs",
    Type = "Toggle",
    Value = false,
    Callback = function(state)
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        if state then
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled and not isSiliconGui(gui) then
                    gui.Enabled = false
                    table.insert(hiddenGUIs, gui)
                end
            end
            Silicon:Notify({
                Title = "UI Hidden",
                Content = "All non-Silicon UI elements have been hidden."
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