local CloneRef = cloneref or function(...) return ... end
local Workspace = CloneRef(game:GetService("Workspace"))
local CurrentCamera = CloneRef(Workspace.CurrentCamera)
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint

local DrawingNew    = Drawing.new
local Vector2New    = Vector2.new
local Vector3New    = Vector3.new
local Color3New     = Color3.new
local TableRemove   = table.remove
local MathFloor     = math.floor
local MathRound     = math.round
local MathHuge      = math.huge
local MathMax       = math.max
local MathAbs       = math.abs
local CFrameNew     = CFrame.new
local Type          = type

local ColorBlack     = Color3New(0, 0, 0)
local ColorWhite     = Color3New(1, 1, 1)
local ColorGreen     = Color3New(0, 1, 0)
local ColorRed       = Color3New(1, 0, 0)
local ColorBackground = Color3New(0.239215, 0.239215, 0.239215)

local VisibleItemsBuffer = {}

local function CreateDrawing(DrawingType, Properties, Container)
    local DrawingObject = DrawingNew(DrawingType)
    for Key, Value in next, Properties do
        DrawingObject[Key] = Value
    end
    if Container then
        Container[#Container + 1] = DrawingObject
    end
    return DrawingObject
end

local GlobalFont = (getgenv and getgenv().GLOBAL_FONT) or _G.GLOBAL_FONT or 0
local GlobalSize = (getgenv and getgenv().GLOBAL_SIZE) or _G.GLOBAL_SIZE or 13
local BaseZIndex = 1

local EspLibrary = {}

EspLibrary.Enabled = true

EspLibrary.Config = {
    Font               = GlobalFont,
    TextSize           = GlobalSize,
    FlagSize           = GlobalSize,
    FlagLinePadding    = 2,
    FlagXPadding       = 6,
    BoxCornerWidthScale  = 0.25,
    BoxCornerHeightScale = 0.25,
    PixelSnap          = true,
    NameMode           = "Username",
}

do
    local PlayerEsp = {
        PlayerCache = {},
        DrawingCache = {},
        ChildAddedConnections = {},
        ChildRemovedConnections = {},
        DrawingAddedConnections = {},
    }
    PlayerEsp.__index = PlayerEsp

    PlayerEsp.OnChildAdded = function(Callback)
        local Conns = PlayerEsp.ChildAddedConnections
        Conns[#Conns + 1] = Callback
    end
    PlayerEsp.OnChildRemoved = function(Callback)
        local Conns = PlayerEsp.ChildRemovedConnections
        Conns[#Conns + 1] = Callback
    end
    PlayerEsp.OnDrawingAdded = function(Callback)
        local Conns = PlayerEsp.DrawingAddedConnections
        Conns[#Conns + 1] = Callback
    end
    local function GetBoundingBoxSafe(Target, _, IsCharacter)
        if not Target then return nil, nil end
        local Min = Vector3New(MathHuge,  MathHuge,  MathHuge)
        local Max = Vector3New(-MathHuge, -MathHuge, -MathHuge)
        local Found = false
        local Whitelist = IsCharacter and EspLibrary.CharacterWhitelist
        for _, Part in next, Target:GetChildren() do
            if not Part:IsA("BasePart") then continue end
            if Whitelist and not Whitelist[Part.Name] then continue end
            local P  = Part.CFrame.Position
            local HX = Part.Size.X * 0.5
            local HY = Part.Size.Y * 0.5
            local HZ = Part.Size.Z * 0.5
            if P.X - HX < Min.X then Min = Vector3New(P.X - HX, Min.Y, Min.Z) end
            if P.Y - HY < Min.Y then Min = Vector3New(Min.X, P.Y - HY, Min.Z) end
            if P.Z - HZ < Min.Z then Min = Vector3New(Min.X, Min.Y, P.Z - HZ) end
            if P.X + HX > Max.X then Max = Vector3New(P.X + HX, Max.Y, Max.Z) end
            if P.Y + HY > Max.Y then Max = Vector3New(Max.X, P.Y + HY, Max.Z) end
            if P.Z + HZ > Max.Z then Max = Vector3New(Max.X, Max.Y, P.Z + HZ) end
            Found = true
        end
        if not Found then return nil, nil end
        local Center = (Min + Max) * 0.5
        return CFrameNew(Center), Max - Min
    end

    local function ProjectPointToScreen(WorldPosition)
        local ScreenPos, OnScreen = WorldToViewportPoint(CurrentCamera, WorldPosition)
        if not OnScreen or ScreenPos.Z <= 0 then
            return nil, nil, ScreenPos.Z
        end
        return ScreenPos.X, ScreenPos.Y, ScreenPos.Z
    end

    local function Get2DBoxFrom3DBounds(CF, Size)
        local HX, HY, HZ = Size.X * 0.5, Size.Y * 0.5, Size.Z * 0.5
        local MinX, MinY = MathHuge, MathHuge
        local MaxX, MaxY = -MathHuge, -MathHuge
        local AnyInFront = false
        local MinZ = MathHuge
        for IX = -1, 1, 2 do
            for IY = -1, 1, 2 do
                for IZ = -1, 1, 2 do
                    local X, Y, Z = ProjectPointToScreen(CF * Vector3New(HX * IX, HY * IY, HZ * IZ))
                    if Z then
                        if Z > 0 then
                            AnyInFront = true
                            if Z < MinZ then MinZ = Z end
                        end
                        if X and Y then
                            if X < MinX then MinX = X end
                            if Y < MinY then MinY = Y end
                            if X > MaxX then MaxX = X end
                            if Y > MaxY then MaxY = Y end
                        end
                    end
                end
            end
        end
        return MinX, MinY, MaxX, MaxY, AnyInFront, MinZ
    end

    local function GetPlayerName(Player)
        if Type(Player) == "table" then
            return Player.Name
        end
        if EspLibrary.Config.NameMode == "Username" then
            return Player.Name
        end
        return Player.DisplayName
    end

    function PlayerEsp:CreateDrawingCache()
        local AllDrawings = {}
        local Cfg = EspLibrary.Config
        local Corners = { Lines = {}, Outlines = {} }
        for i = 1, 8 do
            Corners.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Corners.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        local FullBox = { Lines = {}, Outlines = {} }
        for i = 1, 4 do
            FullBox.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            FullBox.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        local FlagTexts = {}
        for i = 1, 6 do
            FlagTexts[i] = CreateDrawing("Text", {
                Visible = false,
                Center = false,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.FlagSize,
                Text = "",
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
        end
        local Drawings = {
            Corners = Corners,
            FullBox = FullBox,
            Name = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.TextSize,
                Text = self and self.Player and GetPlayerName(self.Player) or "",
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            Weapon = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.TextSize,
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            Distance = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = ColorBlack,
                Color = ColorWhite,
                Transparency = 1,
                Size = Cfg.TextSize,
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HealthBar = CreateDrawing("Square", {
                Visible = false,
                Thickness = 1,
                Filled = true,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HealthBackground = CreateDrawing("Square", {
                Visible = false,
                Color = ColorBackground,
                Transparency = 0.7,
                Thickness = 1,
                Filled = true,
                ZIndex = BaseZIndex,
            }, AllDrawings),
            FlagTexts = FlagTexts,
        }
        Drawings.All = AllDrawings
        self.Drawings = Drawings
        self.AllDrawings = AllDrawings
    end

    PlayerEsp.New = function(Player)
        local Self = setmetatable({
            Player = Player,
            Connections = {},
            Hidden = false,
            AllDrawings = nil,
            Drawings = nil,
            Current = nil,
        }, PlayerEsp)
        local Cache = PlayerEsp.DrawingCache[1]
        if Cache then
            TableRemove(PlayerEsp.DrawingCache, 1)
            Cache.Name.Text = GetPlayerName(Player)
            Self.AllDrawings = Cache.All
            Self.Drawings = Cache
        else
            Self:CreateDrawingCache()
        end
        local Conns = PlayerEsp.DrawingAddedConnections
        for i = 1, #Conns do
            Conns[i](Self)
        end
        if Type(Player) == "userdata" then
            Self.Connections[#Self.Connections + 1] = Player.CharacterAdded:Connect(function(...) return Self:CharacterAdded(...) end)
            Self.Connections[#Self.Connections + 1] = Player.CharacterRemoving:Connect(function(...) return Self:CharacterRemoved(...) end)
            if Player.Character then
                Self:CharacterAdded(Player.Character, true)
            end
        elseif Type(Player) == "table" then
            if Player.CharacterAdded then
                Self.Connections[#Self.Connections + 1] = Player.CharacterAdded:Connect(function(...) return Self:CharacterAdded(...) end)
            end
            if Player.CharacterRemoving then
                Self.Connections[#Self.Connections + 1] = Player.CharacterRemoving:Connect(function(...) return Self:CharacterRemoved(...) end)
            end
            local Character = Player.Character or Player.model or Player.Model
            if Character then
                Self:CharacterAdded(Character, true)
            end
        end
        PlayerEsp.PlayerCache[Player] = Self
        return Self
    end

    PlayerEsp.Remove = function(Player)
        local Cache = PlayerEsp.PlayerCache[Player]
        if Type(Cache) ~= "table" then return end
        PlayerEsp.PlayerCache[Player] = nil
        for i = 1, #Cache.Connections do
            Cache.Connections[i]:Disconnect()
        end
        if Cache.Drawings then
            PlayerEsp.DrawingCache[#PlayerEsp.DrawingCache + 1] = Cache.Drawings
        end
    end

    function PlayerEsp:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function PlayerEsp:HumanoidHealthChanged()
        local Humanoid = self.Current and self.Current.Humanoid
        if not Humanoid then return end
        local Health = Humanoid.Health
        local MaxHealth = Humanoid.MaxHealth
        local Pct = (MaxHealth > 0 and (Health / MaxHealth)) or 0
        self.Current.Health = Health
        self.Current.MaxHealth = MaxHealth
        self.Current.HealthPercentage = Pct
        self.Drawings.HealthBar.Color = ColorRed:Lerp(ColorGreen, Pct)
    end

    function PlayerEsp:SetupHumanoid(Humanoid, FirstTime)
        self:HumanoidHealthChanged()
        self.Connections[#self.Connections + 1] = Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            self:HumanoidHealthChanged()
        end)
        if FirstTime then
            local Conns = self.ChildAddedConnections
            local Children = self.Current.Character:GetChildren()
            for i = 1, #Children do
                for j = 1, #Conns do
                    Conns[j](self, Children[i])
                end
            end
        end
    end

    function PlayerEsp:ChildAdded(Child)
        if Child.ClassName == "Humanoid" then
            self.Current.Humanoid = Child
            self:SetupHumanoid(Child)
        end
        local Conns = self.ChildAddedConnections
        for i = 1, #Conns do
            Conns[i](self, Child)
        end
    end

    function PlayerEsp:ChildRemoved(Child)
        if not self.Current then return end
        if Child == self.Current.Humanoid then
            self.Current.Humanoid = nil
        elseif Child == self.Current.RootPart then
            self.Current.RootPart = nil
        end
        local Conns = self.ChildRemovedConnections
        for i = 1, #Conns do
            Conns[i](self, Child)
        end
    end

    function PlayerEsp:PrimaryPartAdded()
        local Character = self.Current and self.Current.Character
        if not Character then return end
        local PrimaryPart = Character.PrimaryPart
        if PrimaryPart then
            self.Current.RootPart = PrimaryPart
        end
    end

    function PlayerEsp:CharacterAdded(Character, FirstTime)
        self.Current = {
            Character = Character,
            Humanoid = Character:FindFirstChildOfClass("Humanoid"),
            RootPart = Character:FindFirstChild("HumanoidRootPart") or Character.PrimaryPart,
            Health = 0,
            MaxHealth = 0,
            HealthPercentage = 0,
            Weapon = nil,
            Visible = false,
        }
        self.Connections[#self.Connections + 1] = Character:GetPropertyChangedSignal("PrimaryPart"):Connect(function() self:PrimaryPartAdded() end)
        self.Connections[#self.Connections + 1] = Character.ChildAdded:Connect(function(...) return self:ChildAdded(...) end)
        self.Connections[#self.Connections + 1] = Character.ChildRemoved:Connect(function(...) return self:ChildRemoved(...) end)
        if self.Current.Humanoid then
            self:SetupHumanoid(self.Current.Humanoid, FirstTime)
        end
    end

    function PlayerEsp:CharacterRemoved()
        self.Current = nil
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function PlayerEsp:RenderBox(BoxPos2D, BoxSize2D, BoxSettings)
        local Corners = self.Drawings.Corners
        local FullBox = self.Drawings.FullBox
        local CornersLines = Corners.Lines
        local CornersOutlines = Corners.Outlines
        local FullLines = FullBox.Lines
        local FullOutlines = FullBox.Outlines
        local Enabled = false
        local Mode = "corner"
        if Type(BoxSettings) == "table" then
            Enabled = not not BoxSettings.Enabled
            Mode = BoxSettings.Mode and string.lower(BoxSettings.Mode) or "corner"
        else
            Enabled = not not BoxSettings
        end
        if not Enabled then
            for i = 1, 8 do
                CornersLines[i].Visible = false
                CornersOutlines[i].Visible = false
            end
            for i = 1, 4 do
                FullLines[i].Visible = false
                FullOutlines[i].Visible = false
            end
            return
        end
        local Left = BoxPos2D.X
        local Top = BoxPos2D.Y
        local Right = Left + BoxSize2D.X
        local Bottom = Top + BoxSize2D.Y
        if EspLibrary.Config.PixelSnap then
            Left = MathFloor(Left + 0.5)
            Top = MathFloor(Top + 0.5)
            Right = MathFloor(Right + 0.5)
            Bottom = MathFloor(Bottom + 0.5)
        end
        if Mode == "full" then
            for i = 1, 8 do
                CornersLines[i].Visible = false
                CornersOutlines[i].Visible = false
            end
            local P1 = Vector2New(Left, Top)
            local P2 = Vector2New(Right, Top)
            local P3 = Vector2New(Right, Bottom)
            local P4 = Vector2New(Left, Bottom)
            for i = 1, 4 do
                local NextIdx = i % 4 + 1
                local Points = {P1, P2, P3, P4}
                FullOutlines[i].Visible, FullLines[i].Visible = true, true
                FullOutlines[i].From, FullOutlines[i].To = Points[i], Points[NextIdx]
                FullLines[i].From, FullLines[i].To = Points[i], Points[NextIdx]
            end
            return
        end
        for i = 1, 4 do
            FullLines[i].Visible = false
            FullOutlines[i].Visible = false
        end
        local Cfg = EspLibrary.Config
        local HLen = MathFloor(BoxSize2D.X * Cfg.BoxCornerWidthScale)
        local VLen = MathFloor(BoxSize2D.Y * Cfg.BoxCornerHeightScale)
        local CornerPoints = {
            { Vector2New(Left, Top),              Vector2New(Left + HLen, Top) },
            { Vector2New(Left, Top),              Vector2New(Left, Top + VLen) },
            { Vector2New(Right - HLen, Top),      Vector2New(Right, Top) },
            { Vector2New(Right, Top),             Vector2New(Right, Top + VLen) },
            { Vector2New(Left, Bottom),           Vector2New(Left + HLen, Bottom) },
            { Vector2New(Left, Bottom - VLen),    Vector2New(Left, Bottom) },
            { Vector2New(Right - HLen, Bottom),   Vector2New(Right, Bottom) },
            { Vector2New(Right, Bottom - VLen),   Vector2New(Right, Bottom) },
        }
        for i = 1, 8 do
            local O, L = CornersOutlines[i], CornersLines[i]
            O.Visible, L.Visible = true, true
            O.From, O.To = CornerPoints[i][1], CornerPoints[i][2]
            L.From, L.To = CornerPoints[i][1], CornerPoints[i][2]
        end
    end
    function PlayerEsp:RenderName(Center2D, Offset, NameSettings)
        local NameText = self.Drawings.Name
        local Enabled  = false
        if Type(NameSettings) == "table" then
            Enabled = not not NameSettings.Enabled
        else
            Enabled = not not NameSettings
        end
        if not Enabled then
            NameText.Visible = false
            return
        end
        NameText.Visible  = true
        NameText.Text     = GetPlayerName(self.Player)
        NameText.Position = Center2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
    end
    function PlayerEsp:RenderWeapon(Center2D, Offset, Enabled, BottomYOffset)
        local WeaponText = self.Drawings.Weapon
        if not Enabled then
            WeaponText.Visible = false
            return 0
        end
        WeaponText.Visible = true
        WeaponText.Position = Center2D + Vector2New(0, Offset.Y + BottomYOffset)
        WeaponText.Text = self.Current.Weapon and string.lower(self.Current.Weapon.Name) or "none"
        return EspLibrary.Config.TextSize + 1
    end

    function PlayerEsp:RenderDistance(Center2D, Offset, Enabled, BottomYOffset, DistanceOverride)
        local DistanceText = self.Drawings.Distance
        if not Enabled then
            DistanceText.Visible = false
            return 0
        end
        local RootPart = self.Current and self.Current.RootPart
        if not RootPart then
            DistanceText.Visible = false
            return 0
        end
        local Cfg = EspLibrary.Config
        local Magnitude = MathRound(DistanceOverride or (CurrentCamera.CFrame.Position - RootPart.Position).Magnitude)
        local PosX = Center2D.X
        local PosY = Center2D.Y + Offset.Y + BottomYOffset
        if Cfg.PixelSnap then
            PosX = MathFloor(PosX + 0.5)
            PosY = MathFloor(PosY + 0.5)
        end
        DistanceText.Visible = true
        DistanceText.Position = Vector2New(PosX, PosY)
        DistanceText.Text = `[{Magnitude}]`
        return Cfg.TextSize + 1
    end

    function PlayerEsp:RenderHealthbar(Center2D, Offset, Enabled)
        if not Enabled then
            self.Drawings.HealthBar.Visible = false
            self.Drawings.HealthBackground.Visible = false
            return
        end
        local HealthBar = self.Drawings.HealthBar
        local HealthBackground = self.Drawings.HealthBackground
        HealthBar.Visible = true
        HealthBackground.Visible = true
        local BasePos = Center2D - Offset - Vector2New(5, 0)
        local BaseSize = Vector2New(3, Offset.Y * 2)
        local Pct = self.Current.HealthPercentage or 0
        local HealthLen = (BaseSize.Y - 2) * Pct
        HealthBackground.Position = BasePos
        HealthBackground.Size = BaseSize
        HealthBar.Position = BasePos + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLen))
        HealthBar.Size = Vector2New(1, HealthLen)
    end

    function PlayerEsp:RenderFlags(Center2D, Offset, FlagsSettings)
        local FlagTexts = self.Drawings.FlagTexts
        for i = 1, #FlagTexts do
            FlagTexts[i].Visible = false
        end
        if not FlagsSettings or not FlagsSettings.Enabled then return end
        table.clear(VisibleItemsBuffer)
        local Items
        if Type(FlagsSettings.Builder) == "function" then
            local Ok, Result = pcall(FlagsSettings.Builder, self)
            if Ok and Type(Result) == "table" then Items = Result end
        end
        if not Items then return end
        local Mode = FlagsSettings.Mode and string.lower(FlagsSettings.Mode) or "normal"
        for i = 1, #Items do
            local Item = Items[i]
            if Mode == "always" or (Item and Item.State) then
                VisibleItemsBuffer[#VisibleItemsBuffer + 1] = Item
            end
        end
        local Count = #VisibleItemsBuffer
        if Count == 0 then return end
        local Cfg = EspLibrary.Config
        local MaxFlags = #FlagTexts
        if Count > MaxFlags then Count = MaxFlags end
        local FlagSize = Cfg.FlagSize
        local LineHeight = FlagSize + Cfg.FlagLinePadding
        local BaseX = Center2D.X + Offset.X + Cfg.FlagXPadding
        local BaseY = Center2D.Y - Offset.Y
        for i = 1, Count do
            local Item = VisibleItemsBuffer[i]
            local TextObj = FlagTexts[i]
            local PosX = BaseX
            local PosY = BaseY + (i - 1) * LineHeight
            if Cfg.PixelSnap then
                PosX = MathFloor(PosX + 0.5)
                PosY = MathFloor(PosY + 0.5)
            end
            local State = not not (Item and Item.State)
            TextObj.Visible = true
            TextObj.Center = false
            TextObj.Font = Cfg.Font
            TextObj.Size = FlagSize
            TextObj.Outline = true
            TextObj.OutlineColor = ColorBlack
            TextObj.Transparency = 1
            TextObj.Text = tostring(Item and Item.Text or "")
            TextObj.Position = Vector2New(PosX, PosY)
            if Mode == "always" then
                TextObj.Color = State and ((Item and Item.ColorTrue) or ColorGreen) or ((Item and Item.ColorFalse) or ColorRed)
            else
                TextObj.Color = (Item and Item.ColorTrue) or ColorGreen
            end
        end
    end

    function PlayerEsp:Loop(Settings, DistanceOverride)
        if not EspLibrary.Enabled then return self:HideDrawings() end
        local Current = self.Current
        if not Current then return self:HideDrawings() end
        local Character = Current.Character
        local Humanoid = Current.Humanoid
        local RootPart = Current.RootPart
        if not Character or not Humanoid or not RootPart then return self:HideDrawings() end
        local CF, Size3D = GetBoundingBoxSafe(Character, Humanoid, true)
        if not Size3D then return self:HideDrawings() end
        local GoalPos = CF.Position
        local ScreenPos, OnScreen = WorldToViewportPoint(CurrentCamera, GoalPos)
        if not OnScreen then return self:HideDrawings() end
        self.Hidden = false
        local Center2D = Vector2New(ScreenPos.X, ScreenPos.Y)
        local CameraCF = CurrentCamera.CFrame
        local BoxCF = CFrameNew(GoalPos, GoalPos + CameraCF.LookVector)
        local HX, HY = -Size3D.X / 2, Size3D.Y / 2
        local TopRight2D_Obj = WorldToViewportPoint(CurrentCamera, (BoxCF * CFrame.new(HX, HY, 0)).Position)
        local BottomRight2D_Obj = WorldToViewportPoint(CurrentCamera, (BoxCF * CFrame.new(HX, -HY, 0)).Position)
        local TopRight2D = Vector2New(TopRight2D_Obj.X, TopRight2D_Obj.Y)
        local BottomRight2D = Vector2New(BottomRight2D_Obj.X, BottomRight2D_Obj.Y)
        local Offset = Vector2New(
            MathMax(MathAbs(TopRight2D.X - Center2D.X), MathAbs(BottomRight2D.X - Center2D.X)),
            MathMax(MathAbs(Center2D.Y - TopRight2D.Y), MathAbs(BottomRight2D.Y - Center2D.Y))
        )
        self:RenderBox(Center2D - Offset, Offset * 2, Settings.Box)
        self:RenderName(Center2D, Offset, Settings.Name)
        self:RenderHealthbar(Center2D, Offset, Settings.Healthbar)
        local BottomY = self:RenderWeapon(Center2D, Offset, Settings.Weapon, 0)
        BottomY = BottomY + self:RenderDistance(Center2D, Offset, Settings.Distance, BottomY, DistanceOverride)
        self:RenderFlags(Center2D, Offset, Settings.Flags)
    end

    EspLibrary.PlayerEsp = PlayerEsp
    EspLibrary.PlayerESP = PlayerEsp

    local EntityEsp = {
        EntityCache = {},
        DrawingCache = {},
        DrawingAddedConnections = {},
    }
    EntityEsp.__index = EntityEsp

    EntityEsp.OnDrawingAdded = function(Callback)
        local Conns = EntityEsp.DrawingAddedConnections
        Conns[#Conns + 1] = Callback
    end

    function EntityEsp:CreateDrawingCache()
        local AllDrawings = {}
        local Cfg = EspLibrary.Config
        local Drawings = {
            FullBox = { Lines = {}, Outlines = {} },
            Name = CreateDrawing("Text", {
                Visible = false, Center = true, Outline = true,
                OutlineColor = ColorBlack, Color = self.Color or ColorWhite,
                Transparency = 1, Size = Cfg.TextSize, Text = self.Name or "",
                Font = Cfg.Font, ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            Distance = CreateDrawing("Text", {
                Visible = false, Center = true, Outline = true,
                OutlineColor = ColorBlack, Color = self.Color or ColorWhite,
                Transparency = 1, Size = Cfg.TextSize, Font = Cfg.Font, ZIndex = BaseZIndex + 1,
            }, AllDrawings),
        }
        for i = 1, 4 do
            Drawings.FullBox.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Drawings.FullBox.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        Drawings.Corners = { Lines = {}, Outlines = {} }
        for i = 1, 16 do
            Drawings.Corners.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Drawings.Corners.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        Drawings.All = AllDrawings
        self.Drawings = Drawings
        self.AllDrawings = AllDrawings
    end

    EntityEsp.New = function(Entity, Color, Name)
        local Self = setmetatable({
            Entity = Entity,
            Color = Color or ColorWhite,
            Name = Name or Entity.Name,
            Connections = {},
            Hidden = false,
        }, EntityEsp)
        local Cache = EntityEsp.DrawingCache[1]
        if Cache then
            TableRemove(EntityEsp.DrawingCache, 1)
            Cache.Name.Text = Self.Name
            Cache.Name.Color = Self.Color
            Cache.Distance.Color = Self.Color
            for i = 1, 4 do Cache.FullBox.Lines[i].Color = Self.Color end
            for i = 1, 16 do Cache.Corners.Lines[i].Color = Self.Color end
            Self.AllDrawings = Cache.All
            Self.Drawings = Cache
        else
            Self:CreateDrawingCache()
        end
        local Conns = EntityEsp.DrawingAddedConnections
        for i = 1, #Conns do Conns[i](Self) end
        Self.Connections[#Self.Connections + 1] = Entity.AncestryChanged:Connect(function(_, Parent)
            if not Parent then EntityEsp.Remove(Entity) end
        end)
        EntityEsp.EntityCache[Entity] = Self
        return Self
    end

    EntityEsp.Remove = function(Entity)
        local Cache = EntityEsp.EntityCache[Entity]
        if not Cache then return end
        EntityEsp.EntityCache[Entity] = nil
        for i = 1, #Cache.Connections do
            Cache.Connections[i]:Disconnect()
        end
        if Cache.Drawings then
            for i = 1, #Cache.AllDrawings do
                Cache.AllDrawings[i].Visible = false
            end
            EntityEsp.DrawingCache[#EntityEsp.DrawingCache + 1] = Cache.Drawings
        end
    end

    function EntityEsp:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function EntityEsp:Loop(Settings, DistanceOverride)
        if not EspLibrary.Enabled then return self:HideDrawings() end
        local Entity = self.Entity
        if not Entity or not Entity.Parent then return EntityEsp.Remove(Entity) end
        local BoxCF, BoxSize3 = Entity:GetBoundingBox()
        local MinX, MinY, MaxX, MaxY, AnyInFront, MinZ = Get2DBoxFrom3DBounds(BoxCF, BoxSize3)
        if not AnyInFront or MinZ <= 0 then return self:HideDrawings() end
        local W = MaxX - MinX
        local H = MaxY - MinY
        if W <= 1 or H <= 1 or W ~= W or H ~= H then return self:HideDrawings() end
        self.Hidden = false
        if EspLibrary.Config.PixelSnap then
            MinX = MathFloor(MinX + 0.5)
            MinY = MathFloor(MinY + 0.5)
            MaxX = MathFloor(MaxX + 0.5)
            MaxY = MathFloor(MaxY + 0.5)
        end
        W = MaxX - MinX
        H = MaxY - MinY
        local Center2D = Vector2New(MinX + W * 0.5, MinY + H * 0.5)
        local Offset = Vector2New(W * 0.5, H * 0.5)
        local Drawings = self.Drawings
        local BoxSettings = Settings.Box
        local BoxEnabled = Type(BoxSettings) == "table" and BoxSettings.Enabled or (Type(BoxSettings) == "boolean" and BoxSettings)
        local BoxMode = Type(BoxSettings) == "table" and BoxSettings.Mode or "Full"
        local FullLines = Drawings.FullBox.Lines
        local FullOutlines = Drawings.FullBox.Outlines
        local CornerLines = Drawings.Corners.Lines
        local CornerOutlines = Drawings.Corners.Outlines
        if BoxEnabled and BoxMode == "Full" then
            local Points = { Vector2New(MinX, MinY), Vector2New(MaxX, MinY), Vector2New(MaxX, MaxY), Vector2New(MinX, MaxY) }
            for i = 1, 4 do
                local NextIdx = i % 4 + 1
                FullOutlines[i].Visible, FullLines[i].Visible = true, true
                FullOutlines[i].From, FullOutlines[i].To = Points[i], Points[NextIdx]
                FullLines[i].From, FullLines[i].To = Points[i], Points[NextIdx]
            end
        else
            for i = 1, 4 do
                FullOutlines[i].Visible = false
                FullLines[i].Visible = false
            end
        end
        if BoxEnabled and BoxMode == "Corner" then
            local Cfg = EspLibrary.Config
            local HLen = MathFloor(W * Cfg.BoxCornerWidthScale)
            local VLen = MathFloor(H * Cfg.BoxCornerHeightScale)
            local CornerPoints = {
                { Vector2New(MinX, MinY),        Vector2New(MinX + HLen, MinY) },
                { Vector2New(MinX, MinY),        Vector2New(MinX, MinY + VLen) },
                { Vector2New(MaxX, MinY),        Vector2New(MaxX - HLen, MinY) },
                { Vector2New(MaxX, MinY),        Vector2New(MaxX, MinY + VLen) },
                { Vector2New(MinX, MaxY),        Vector2New(MinX + HLen, MaxY) },
                { Vector2New(MinX, MaxY),        Vector2New(MinX, MaxY - VLen) },
                { Vector2New(MaxX, MaxY),        Vector2New(MaxX - HLen, MaxY) },
                { Vector2New(MaxX, MaxY),        Vector2New(MaxX, MaxY - VLen) },
            }
            for i = 1, 8 do
                CornerOutlines[i].Visible, CornerLines[i].Visible = true, true
                CornerOutlines[i].From, CornerOutlines[i].To = CornerPoints[i][1], CornerPoints[i][2]
                CornerLines[i].From, CornerLines[i].To = CornerPoints[i][1], CornerPoints[i][2]
            end
        else
            for i = 1, 16 do
                if CornerLines[i] then
                    CornerLines[i].Visible = false
                    CornerOutlines[i].Visible = false
                end
            end
        end
        if Settings.Name then
            Drawings.Name.Visible = true
            Drawings.Name.Position = Center2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
        else
            Drawings.Name.Visible = false
        end
        if Settings.Distance then
            local Magnitude = MathRound(DistanceOverride or (CurrentCamera.CFrame.Position - BoxCF.Position).Magnitude)
            Drawings.Distance.Visible = true
            Drawings.Distance.Position = Center2D + Vector2New(0, Offset.Y)
            Drawings.Distance.Text = `[{Magnitude}]`
        else
            Drawings.Distance.Visible = false
        end
    end

    EspLibrary.EntityEsp = EntityEsp

    local NpcEsp = {
        NpcCache = {},
        DrawingCache = {},
        DrawingAddedConnections = {},
    }
    NpcEsp.__index = NpcEsp

    NpcEsp.OnDrawingAdded = function(Callback)
        local Conns = NpcEsp.DrawingAddedConnections
        Conns[#Conns + 1] = Callback
    end

    function NpcEsp:CreateDrawingCache()
        local AllDrawings = {}
        local Cfg = EspLibrary.Config
        local Drawings = {
            FullBox = { Lines = {}, Outlines = {} },
            Corners = { Lines = {}, Outlines = {} },
            FlagTexts = {},
            Name = CreateDrawing("Text", {
                Visible = false, Center = true, Outline = true,
                OutlineColor = ColorBlack, Color = self.Color or ColorWhite,
                Transparency = 1, Size = Cfg.TextSize, Text = self.Name or "",
                Font = Cfg.Font, ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            Distance = CreateDrawing("Text", {
                Visible = false, Center = true, Outline = true,
                OutlineColor = ColorBlack, Color = self.Color or ColorWhite,
                Transparency = 1, Size = Cfg.TextSize, Font = Cfg.Font, ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HealthBar = CreateDrawing("Square", {
                Visible = false, Thickness = 1, Filled = true, ZIndex = BaseZIndex + 1,
            }, AllDrawings),
            HealthBackground = CreateDrawing("Square", {
                Visible = false, Color = ColorBackground, Transparency = 0.7,
                Thickness = 1, Filled = true, ZIndex = BaseZIndex,
            }, AllDrawings),
        }
        for i = 1, 6 do
            Drawings.FlagTexts[i] = CreateDrawing("Text", {
                Visible = false, Center = false, Outline = true,
                OutlineColor = ColorBlack, Color = ColorWhite,
                Transparency = 1, Size = Cfg.FlagSize, Text = "",
                Font = Cfg.Font, ZIndex = BaseZIndex + 1,
            }, AllDrawings)
        end
        for i = 1, 4 do
            Drawings.FullBox.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Drawings.FullBox.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        for i = 1, 8 do
            Drawings.Corners.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Drawings.Corners.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        Drawings.All = AllDrawings
        self.Drawings = Drawings
        self.AllDrawings = AllDrawings
    end

    NpcEsp.New = function(Model, Color, Name)
        local Self = setmetatable({
            Model = Model,
            Humanoid = nil,
            Color = Color or ColorWhite,
            Name = Name or Model.Name,
            Connections = {},
            Hidden = false,
            HealthPercentage = 1,
        }, NpcEsp)
        local Cache = NpcEsp.DrawingCache[1]
        if Cache then
            TableRemove(NpcEsp.DrawingCache, 1)
            Cache.Name.Text = Self.Name
            Cache.Name.Color = Self.Color
            Cache.Distance.Color = Self.Color
            for i = 1, 4 do Cache.FullBox.Lines[i].Color = Self.Color end
            if Cache.Corners then
                for i = 1, 8 do Cache.Corners.Lines[i].Color = Self.Color end
            end
            Self.AllDrawings = Cache.All
            Self.Drawings = Cache
        else
            Self:CreateDrawingCache()
        end
        local Conns = NpcEsp.DrawingAddedConnections
        for i = 1, #Conns do Conns[i](Self) end
        local function SetupHumanoid(Humanoid)
            if Self.Humanoid then return end
            Self.Humanoid = Humanoid
            local function UpdateHealth()
                Self.HealthPercentage = (Humanoid.MaxHealth > 0 and (Humanoid.Health / Humanoid.MaxHealth)) or 0
            end
            UpdateHealth()
            Self.Connections[#Self.Connections + 1] = Humanoid:GetPropertyChangedSignal("Health"):Connect(UpdateHealth)
            Self.Connections[#Self.Connections + 1] = Humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(UpdateHealth)
        end
        local InitialHumanoid = Model:FindFirstChildOfClass("Humanoid")
        if InitialHumanoid then
            SetupHumanoid(InitialHumanoid)
        else
            Self.Connections[#Self.Connections + 1] = Model.ChildAdded:Connect(function(Child)
                if Child:IsA("Humanoid") then SetupHumanoid(Child) end
            end)
        end
        Self.Connections[#Self.Connections + 1] = Model.AncestryChanged:Connect(function(_, Parent)
            if not Parent then NpcEsp.Remove(Model) end
        end)
        NpcEsp.NpcCache[Model] = Self
        return Self
    end

    NpcEsp.Remove = function(Model)
        local Cache = NpcEsp.NpcCache[Model]
        if not Cache then return end
        NpcEsp.NpcCache[Model] = nil
        for i = 1, #Cache.Connections do
            Cache.Connections[i]:Disconnect()
        end
        if Cache.Drawings then
            for i = 1, #Cache.AllDrawings do
                Cache.AllDrawings[i].Visible = false
            end
            NpcEsp.DrawingCache[#NpcEsp.DrawingCache + 1] = Cache.Drawings
        end
    end

    function NpcEsp:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function NpcEsp:RenderBox(BoxPos2D, BoxSize2D, BoxSettings)
        local Corners = self.Drawings.Corners
        local FullBox = self.Drawings.FullBox
        local CornersLines = Corners.Lines
        local CornersOutlines = Corners.Outlines
        local FullLines = FullBox.Lines
        local FullOutlines = FullBox.Outlines
        local Enabled = false
        local Mode = "corner"
        if Type(BoxSettings) == "table" then
            Enabled = not not BoxSettings.Enabled
            Mode = BoxSettings.Mode and string.lower(BoxSettings.Mode) or "corner"
        else
            Enabled = not not BoxSettings
        end
        if not Enabled then
            for i = 1, 8 do
                CornersLines[i].Visible = false
                CornersOutlines[i].Visible = false
            end
            for i = 1, 4 do
                FullLines[i].Visible = false
                FullOutlines[i].Visible = false
            end
            return
        end
        local Left = BoxPos2D.X
        local Top = BoxPos2D.Y
        local Right = Left + BoxSize2D.X
        local Bottom = Top + BoxSize2D.Y
        if EspLibrary.Config.PixelSnap then
            Left = MathFloor(Left + 0.5)
            Top = MathFloor(Top + 0.5)
            Right = MathFloor(Right + 0.5)
            Bottom = MathFloor(Bottom + 0.5)
        end
        if Mode == "full" then
            for i = 1, 8 do
                CornersLines[i].Visible = false
                CornersOutlines[i].Visible = false
            end
            local Points = { Vector2New(Left, Top), Vector2New(Right, Top), Vector2New(Right, Bottom), Vector2New(Left, Bottom) }
            for i = 1, 4 do
                local NextIdx = i % 4 + 1
                FullOutlines[i].Visible, FullLines[i].Visible = true, true
                FullOutlines[i].From, FullOutlines[i].To = Points[i], Points[NextIdx]
                FullLines[i].From, FullLines[i].To = Points[i], Points[NextIdx]
            end
            return
        end
        for i = 1, 4 do
            FullLines[i].Visible = false
            FullOutlines[i].Visible = false
        end
        local Cfg = EspLibrary.Config
        local HLen = MathFloor(BoxSize2D.X * Cfg.BoxCornerWidthScale)
        local VLen = MathFloor(BoxSize2D.Y * Cfg.BoxCornerHeightScale)
        local CornerPoints = {
            { Vector2New(Left, Top),           Vector2New(Left + HLen, Top) },
            { Vector2New(Left, Top),           Vector2New(Left, Top + VLen) },
            { Vector2New(Right - HLen, Top),   Vector2New(Right, Top) },
            { Vector2New(Right, Top),          Vector2New(Right, Top + VLen) },
            { Vector2New(Left, Bottom),        Vector2New(Left + HLen, Bottom) },
            { Vector2New(Left, Bottom - VLen), Vector2New(Left, Bottom) },
            { Vector2New(Right - HLen, Bottom),Vector2New(Right, Bottom) },
            { Vector2New(Right, Bottom - VLen),Vector2New(Right, Bottom) },
        }
        for i = 1, 8 do
            local O, L = CornersOutlines[i], CornersLines[i]
            O.Visible, L.Visible = true, true
            O.From, O.To = CornerPoints[i][1], CornerPoints[i][2]
            L.From, L.To = CornerPoints[i][1], CornerPoints[i][2]
        end
    end

    function NpcEsp:RenderName(Center2D, Offset, NameSettings)
        local NameText = self.Drawings.Name
        local Enabled  = false
        if Type(NameSettings) == "table" then
            Enabled = not not NameSettings.Enabled
        else
            Enabled = not not NameSettings
        end
        if not Enabled then
            NameText.Visible = false
            return
        end
        NameText.Visible  = true
        NameText.Position = Center2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
        NameText.Text     = self.Name or "NPC"
    end

    function NpcEsp:RenderDistance(Center2D, Offset, Enabled, BottomYOffset, DistanceOverride)
        local DistanceText = self.Drawings.Distance
        if not Enabled then
            DistanceText.Visible = false
            return 0
        end
        local Magnitude = MathRound(DistanceOverride or (CurrentCamera.CFrame.Position - self.Model:GetPivot().Position).Magnitude)
        DistanceText.Visible = true
        DistanceText.Position = Center2D + Vector2New(0, Offset.Y + BottomYOffset)
        DistanceText.Text = `[{Magnitude}]`
        return EspLibrary.Config.TextSize + 1
    end

    function NpcEsp:RenderFlags(Center2D, Offset, FlagsSettings)
        local FlagTexts = self.Drawings.FlagTexts
        for i = 1, #FlagTexts do
            FlagTexts[i].Visible = false
        end
        if not FlagsSettings or not FlagsSettings.Enabled then return end
        table.clear(VisibleItemsBuffer)
        local Items
        if Type(FlagsSettings.Builder) == "function" then
            local Ok, Result = pcall(FlagsSettings.Builder, self)
            if Ok and Type(Result) == "table" then Items = Result end
        end
        if not Items then return end
        local Mode = FlagsSettings.Mode and string.lower(FlagsSettings.Mode) or "normal"
        for i = 1, #Items do
            local Item = Items[i]
            if Mode == "always" or (Item and Item.State) then
                VisibleItemsBuffer[#VisibleItemsBuffer + 1] = Item
            end
        end
        local Count = #VisibleItemsBuffer
        if Count == 0 then return end
        local Cfg = EspLibrary.Config
        local MaxFlags = #FlagTexts
        if Count > MaxFlags then Count = MaxFlags end
        local FlagSize = Cfg.FlagSize
        local LineHeight = FlagSize + Cfg.FlagLinePadding
        local BaseX = Center2D.X + Offset.X + Cfg.FlagXPadding
        local BaseY = Center2D.Y - Offset.Y
        for i = 1, Count do
            local Item = VisibleItemsBuffer[i]
            local TextObj = FlagTexts[i]
            local PosX = BaseX
            local PosY = BaseY + (i - 1) * LineHeight
            if Cfg.PixelSnap then
                PosX = MathFloor(PosX + 0.5)
                PosY = MathFloor(PosY + 0.5)
            end
            local State = not not (Item and Item.State)
            TextObj.Visible = true
            TextObj.Center = false
            TextObj.Font = Cfg.Font
            TextObj.Size = FlagSize
            TextObj.Outline = true
            TextObj.OutlineColor = ColorBlack
            TextObj.Transparency = 1
            TextObj.Text = tostring(Item and Item.Text or "")
            TextObj.Position = Vector2New(PosX, PosY)
            if Mode == "always" then
                TextObj.Color = State and ((Item and Item.ColorTrue) or ColorGreen) or ((Item and Item.ColorFalse) or ColorRed)
            else
                TextObj.Color = (Item and Item.ColorTrue) or ColorGreen
            end
        end
    end

    function NpcEsp:Loop(Settings, DistanceOverride)
        if not EspLibrary.Enabled then return self:HideDrawings() end
        local Model = self.Model
        local Humanoid = self.Humanoid
        if not Model or not Model.Parent or not Humanoid then return NpcEsp.Remove(Model) end
        local CF, Size3D = GetBoundingBoxSafe(Model, Humanoid, true)
        if not CF or not Size3D then return self:HideDrawings() end
        local GoalPos = CF.Position
        local ScreenPos, OnScreen = WorldToViewportPoint(CurrentCamera, GoalPos)
        if not OnScreen then return self:HideDrawings() end
        self.Hidden = false
        local Center2D = Vector2New(ScreenPos.X, ScreenPos.Y)
        local CameraCF = CurrentCamera.CFrame
        local BoxCF = CFrameNew(GoalPos, GoalPos + CameraCF.LookVector)
        local HX, HY = -Size3D.X / 2, Size3D.Y / 2
        local TopRight2D_Obj = WorldToViewportPoint(CurrentCamera, (BoxCF * CFrame.new(HX, HY, 0)).Position)
        local BottomRight2D_Obj = WorldToViewportPoint(CurrentCamera, (BoxCF * CFrame.new(HX, -HY, 0)).Position)
        local TopRight2D = Vector2New(TopRight2D_Obj.X, TopRight2D_Obj.Y)
        local BottomRight2D = Vector2New(BottomRight2D_Obj.X, BottomRight2D_Obj.Y)
        local Offset = Vector2New(
            MathMax(MathAbs(TopRight2D.X - Center2D.X), MathAbs(BottomRight2D.X - Center2D.X)),
            MathMax(MathAbs(Center2D.Y - TopRight2D.Y), MathAbs(BottomRight2D.Y - Center2D.Y))
        )
        self:RenderBox(Center2D - Offset, Offset * 2, Settings.Box)
        self:RenderName(Center2D, Offset, Settings.Name)
        local BottomY = self:RenderDistance(Center2D, Offset, Settings.Distance, 0, DistanceOverride)
        self:RenderFlags(Center2D, Offset, Settings.Flags)
        if Settings.Healthbar then
            local Drawings = self.Drawings
            local HealthBar = Drawings.HealthBar
            local HealthBackground = Drawings.HealthBackground
            local BasePos = Center2D - Offset - Vector2New(5, 0)
            local BaseSize = Vector2New(3, Offset.Y * 2)
            local Pct = self.HealthPercentage or (Humanoid.Health / Humanoid.MaxHealth)
            local HealthLen = (BaseSize.Y - 2) * Pct
            HealthBar.Visible = true
            HealthBackground.Visible = true
            HealthBackground.Position = BasePos
            HealthBackground.Size = BaseSize
            HealthBar.Position = BasePos + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLen))
            HealthBar.Size = Vector2New(1, HealthLen)
            HealthBar.Color = ColorRed:Lerp(ColorGreen, Pct)
        else
            self.Drawings.HealthBar.Visible = false
            self.Drawings.HealthBackground.Visible = false
        end
    end

    EspLibrary.NpcEsp = NpcEsp

    function EspLibrary:Unload()
        for _, EspInstance in next, PlayerEsp.PlayerCache do
            PlayerEsp.Remove(EspInstance.Player)
        end
        for _, EspInstance in next, EntityEsp.EntityCache do
            EntityEsp.Remove(EspInstance.Entity)
        end
        for _, EspInstance in next, NpcEsp.NpcCache do
            NpcEsp.Remove(EspInstance.Model)
        end
        local function ClearCache(Cache)
            for i = 1, #Cache do
                for _, DrawingObject in next, Cache[i].All do
                    DrawingObject:Remove()
                end
            end
            table.clear(Cache)
        end
        ClearCache(PlayerEsp.DrawingCache)
        ClearCache(EntityEsp.DrawingCache)
        ClearCache(NpcEsp.DrawingCache)
    end
end

return EspLibrary, 3
