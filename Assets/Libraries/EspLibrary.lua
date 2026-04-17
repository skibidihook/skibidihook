local Workspace = cloneref(game:GetService("Workspace"))
local Camera = Workspace.CurrentCamera
local WorldToViewportPoint = Camera.WorldToViewportPoint

local DrawingNew = Drawing.new
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local Color3New = Color3.new
local CFrameNew = CFrame.new

local StringLower = string.lower
local MathFloor = math.floor
local MathClamp = math.clamp
local MathRound = math.round
local MathMax = math.max
local MathMin = math.min
local MathAbs = math.abs

local TableInsert = table.insert
local TableRemove = table.remove
local TableClear = table.clear

local Pairs = pairs
local IPairs = ipairs
local Ypcall = ypcall
local Typeof = typeof

local ColorBlack = Color3New(0, 0, 0)
local ColorWhite = Color3New(1, 1, 1)
local ColorGreen = Color3New(0, 1, 0)
local ColorRed = Color3New(1, 0, 0)
local ColorBackground = Color3New(0.239215, 0.239215, 0.239215)
local ColorLerp = ColorBlack.Lerp

local GlobalFont = (getgenv().GLOBAL_FONT or _G.GLOBAL_FONT) or 1
local GlobalSize = (getgenv().GLOBAL_SIZE or _G.GLOBAL_SIZE) or 13

local EspLibrary = {
    Enabled = true,
    Config = {
        Font = GlobalFont,
        TextSize = GlobalSize,
        FlagSize = MathClamp(GlobalSize - 2, 11, 13),
        BoxCornerWidthScale = 0.25,
        BoxCornerHeightScale = 0.25,
        PixelSnap = true,
        NameMode = "Username",
    },
    CharacterWhitelist = nil,
}

local FlagsBuffer = {}

local function CreateDrawing(DrawingType, Properties, Storage)
    local DrawingObject = DrawingNew(DrawingType)
    for Key, Value in Pairs(Properties) do
        DrawingObject[Key] = Value
    end
    if Storage then
        TableInsert(Storage, DrawingObject)
    end
    return DrawingObject
end

local function GetBoundingBox(Target, IsCharacter)
    if not Target or not IsCharacter then
        return nil, nil
    end

    if EspLibrary.CharacterWhitelist then
        local Min = Vector3New(1e9, 1e9, 1e9)
        local Max = Vector3New(-1e9, -1e9, -1e9)
        local Found = false

        for _, Part in IPairs(Target:GetChildren()) do
            if Part:IsA("BasePart") and EspLibrary.CharacterWhitelist[Part.Name] then
                local Size = Part.Size
                local Position = Part.CFrame.Position
                local HalfSize = Size * 0.5

                Min = Vector3New(
                    MathMin(Min.X, Position.X - HalfSize.X),
                    MathMin(Min.Y, Position.Y - HalfSize.Y),
                    MathMin(Min.Z, Position.Z - HalfSize.Z)
                )
                Max = Vector3New(
                    MathMax(Max.X, Position.X + HalfSize.X),
                    MathMax(Max.Y, Position.Y + HalfSize.Y),
                    MathMax(Max.Z, Position.Z + HalfSize.Z)
                )
                Found = true
            end
        end

        if Found then
            return CFrameNew((Min + Max) * 0.5), Max - Min
        end
    end

    local Success, CF, Size = Ypcall(function()
        return Target:ComputeR15BodyBoundingBox()
    end)
    if Success and CF and Size then
        return CF, Size
    end

    if Target:IsA("Model") then
        local Success, TmpCF, TmpSize = Ypcall(Target.GetBoundingBox, Target)
        if Success and TmpCF and TmpSize then
            return TmpCF, TmpSize
        end
    end

    return nil, nil
end

local function ProjectToScreen(WorldPosition)
    local ScreenPosition, OnScreen = WorldToViewportPoint(WorldPosition)
    if not OnScreen or ScreenPosition.Z <= 0 then
        return nil, nil, ScreenPosition.Z
    end
    return ScreenPosition.X, ScreenPosition.Y, ScreenPosition.Z
end

local function Get2DBoxFrom3DBounds(CF, Size)
    local HalfX, HalfY, HalfZ = Size.X * 0.5, Size.Y * 0.5, Size.Z * 0.5
    local MinX, MinY, MaxX, MaxY = 1e9, 1e9, -1e9, -1e9
    local AnyInFront, MinZ = false, 1e9

    for IX = -1, 1, 2 do
        for IY = -1, 1, 2 do
            for IZ = -1, 1, 2 do
                local Corner = CF * Vector3New(HalfX * IX, HalfY * IY, HalfZ * IZ)
                local X, Y, Z = ProjectToScreen(Corner)

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
    if Typeof(Player) == "table" and Player.Name then
        return Player.Name
    end
    return EspLibrary.Config.NameMode == "DisplayName" and Player.DisplayName or Player.Name
end

local Base = {}

function Base:HideDrawings()
    if self.Hidden then return end
    self.Hidden = true
    for i = 1, #self.AllDrawings do
        self.AllDrawings[i].Visible = false
    end
end

function Base:RenderBox(BoxPosition2D, BoxSize2D, Settings)
    local Drawings = self.Drawings
    local CornersLines = Drawings.Corners[1]
    local CornersOutlines = Drawings.Corners[2]
    local FullLines = Drawings.Full[1]
    local FullOutlines = Drawings.Full[2]

    local Enabled, Mode = false, "corner"
    if Typeof(Settings) == "table" then
        Enabled = Settings.Enabled == true
        Mode = Settings.Mode and Settings.Mode:lower() or "corner"
    elseif Typeof(Settings) == "boolean" then
        Enabled = Settings
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

    local Left = BoxPosition2D.X
    local Top = BoxPosition2D.Y
    local Right = BoxPosition2D.X + BoxSize2D.X
    local Bottom = BoxPosition2D.Y + BoxSize2D.Y

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

        local P1X, P1Y = Left, Top
        local P2X, P2Y = Right, Top
        local P3X, P3Y = Right, Bottom
        local P4X, P4Y = Left, Bottom

        for i = 1, 4 do
            local Outline = FullOutlines[i]
            local Line = FullLines[i]
            if i == 1 then
                Outline.From, Outline.To = Vector2New(P1X, P1Y), Vector2New(P2X, P2Y)
                Line.From, Line.To = Outline.From, Outline.To
            elseif i == 2 then
                Outline.From, Outline.To = Vector2New(P2X, P2Y), Vector2New(P3X, P3Y)
                Line.From, Line.To = Outline.From, Outline.To
            elseif i == 3 then
                Outline.From, Outline.To = Vector2New(P3X, P3Y), Vector2New(P4X, P4Y)
                Line.From, Line.To = Outline.From, Outline.To
            else
                Outline.From, Outline.To = Vector2New(P4X, P4Y), Vector2New(P1X, P1Y)
                Line.From, Line.To = Outline.From, Outline.To
            end
            Outline.Visible = true
            Line.Visible = true
        end
        return
    end

    for i = 1, 4 do
        FullLines[i].Visible = false
        FullOutlines[i].Visible = false
    end

    local HorizontalLength = MathFloor(BoxSize2D.X * EspLibrary.Config.BoxCornerWidthScale)
    local VerticalLength = MathFloor(BoxSize2D.Y * EspLibrary.Config.BoxCornerHeightScale)

    for i = 1, 8 do
        local Outline = CornersOutlines[i]
        local Line = CornersLines[i]
        local StartX, StartY, EndX, EndY

        if i == 1 then
            StartX, StartY, EndX, EndY = Left, Top, Left + HorizontalLength, Top
        elseif i == 2 then
            StartX, StartY, EndX, EndY = Left, Top, Left, Top + VerticalLength
        elseif i == 3 then
            StartX, StartY, EndX, EndY = Right - HorizontalLength, Top, Right, Top
        elseif i == 4 then
            StartX, StartY, EndX, EndY = Right, Top, Right, Top + VerticalLength
        elseif i == 5 then
            StartX, StartY, EndX, EndY = Left, Bottom, Left + HorizontalLength, Bottom
        elseif i == 6 then
            StartX, StartY, EndX, EndY = Left, Bottom - VerticalLength, Left, Bottom
        elseif i == 7 then
            StartX, StartY, EndX, EndY = Right - HorizontalLength, Bottom, Right, Bottom
        else
            StartX, StartY, EndX, EndY = Right, Bottom - VerticalLength, Right, Bottom
        end

        Outline.From, Outline.To = Vector2New(StartX, StartY), Vector2New(EndX, EndY)
        Line.From, Line.To = Outline.From, Outline.To
        Outline.Visible = true
        Line.Visible = true
    end
end

function Base:RenderFlags(Settings, Center2D, Offset, BottomYOffset)
    local FlagTexts = self.Drawings.Flags
    for i = 1, #FlagTexts do
        FlagTexts[i].Visible = false
    end

    if not Settings or not Settings.Enabled then
        return 0
    end

    local Items
    if Typeof(Settings.Builder) == "function" then
        local Success, Result = Ypcall(Settings.Builder, self)
        if Success and Typeof(Result) == "table" then
            Items = Result
        end
    end

    if not Items then
        return 0
    end

    local Mode = Settings.Mode and Settings.Mode:lower() or "normal"
    TableClear(FlagsBuffer)

    if Mode == "always" then
        for i = 1, #Items do
            TableInsert(FlagsBuffer, Items[i])
        end
    else
        for i = 1, #Items do
            if Items[i] and Items[i].State then
                TableInsert(FlagsBuffer, Items[i])
            end
        end
    end

    local Count = #FlagsBuffer
    if Count == 0 then
        return 0
    end

    Count = MathMin(Count, #FlagTexts)
    local LineHeight = EspLibrary.Config.TextSize + 1
    local PositionX = Center2D.X
    local ConfigPixelSnap = EspLibrary.Config.PixelSnap
    local ConfigFont = EspLibrary.Config.Font
    local ConfigTextSize = EspLibrary.Config.TextSize

    for i = 1, Count do
        local Item = FlagsBuffer[i]
        local TextObject = FlagTexts[i]

        local PositionY = Center2D.Y + Offset.Y + BottomYOffset + (i - 1) * LineHeight

        if ConfigPixelSnap then
            PositionX = MathFloor(PositionX + 0.5)
            PositionY = MathFloor(PositionY + 0.5)
        end

        TextObject.Visible = true
        TextObject.Center = true
        TextObject.Font = ConfigFont
        TextObject.Size = ConfigTextSize
        TextObject.Outline = true
        TextObject.OutlineColor = ColorBlack
        TextObject.Transparency = 1
        TextObject.Text = Item and Item.Text or ""
        TextObject.Position = Vector2New(PositionX, PositionY)

        if Mode == "always" then
            TextObject.Color = (Item and Item.State and Item.ColorTrue) or (Item and not Item.State and Item.ColorFalse) or ColorGreen
        else
            TextObject.Color = (Item and Item.ColorTrue) or ColorGreen
        end
    end

    return Count * LineHeight
end

local PlayerESP = {
    Cache = {},
    DrawingCache = {},
    ChildAddedConnections = {},
    ChildRemovedConnections = {},
    DrawingAddedConnections = {},
}

PlayerESP.__index = PlayerESP
setmetatable(PlayerESP, { __index = Base })

function PlayerESP.OnChildAdded(Callback)
    TableInsert(PlayerESP.ChildAddedConnections, Callback)
end

function PlayerESP.OnChildRemoved(Callback)
    TableInsert(PlayerESP.ChildRemovedConnections, Callback)
end

function PlayerESP.OnDrawingAdded(Callback)
    TableInsert(PlayerESP.DrawingAddedConnections, Callback)
end

function PlayerESP.New(Player)
    local Self = setmetatable({
        Player = Player,
        Connections = {},
        Hidden = false,
        AllDrawings = nil,
        Drawings = nil,
        Current = nil,
    }, PlayerESP)

    local CachedDrawings = PlayerESP.DrawingCache[1]
    if CachedDrawings then
        TableRemove(PlayerESP.DrawingCache, 1)
        CachedDrawings.Name.Text = GetPlayerName(Player)
        Self.AllDrawings = CachedDrawings.AllDrawings
        Self.Drawings = CachedDrawings
    else
        Self.Drawings, Self.AllDrawings = Self:CreateDrawings()
    end

    for i = 1, #PlayerESP.DrawingAddedConnections do
        PlayerESP.DrawingAddedConnections[i](Self)
    end

    if Typeof(Player) == "Instance" then
        TableInsert(Self.Connections, Player.CharacterAdded:Connect(function(Character)
            Self:OnCharacterAdded(Character)
        end))
        TableInsert(Self.Connections, Player.CharacterRemoving:Connect(function()
            Self:OnCharacterRemoved()
        end))
        if Player.Character then
            Self:OnCharacterAdded(Player.Character, true)
        end
    elseif Typeof(Player) == "table" then
        if Player.CharacterAdded then
            TableInsert(Self.Connections, Player.CharacterAdded:Connect(function(Character)
                Self:OnCharacterAdded(Character)
            end))
        end
        if Player.CharacterRemoving then
            TableInsert(Self.Connections, Player.CharacterRemoving:Connect(function()
                Self:OnCharacterRemoved()
            end))
        end
        local Character = Player.Character or Player.model or Player.Model
        if Character then
            Self:OnCharacterAdded(Character, true)
        end
    end

    PlayerESP.Cache[Player] = Self
    return Self
end

function PlayerESP.Remove(Player)
    local Cache = PlayerESP.Cache[Player]
    if not Cache then return end

    PlayerESP.Cache[Player] = nil
    for i = 1, #Cache.Connections do
        Cache.Connections[i]:Disconnect()
    end

    if Cache.Drawings then
        TableInsert(PlayerESP.DrawingCache, Cache.Drawings)
    end
end

function PlayerESP:CreateDrawings()
    local AllDrawings = {}
    local Config = EspLibrary.Config
    local ZIndex = 1

    local CornersLines = {}
    local CornersOutlines = {}
    for i = 1, 8 do
        CornersOutlines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 2,
            Color = ColorBlack,
            ZIndex = ZIndex,
        }, AllDrawings)
        CornersLines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 1,
            Color = ColorWhite,
            ZIndex = ZIndex + 1,
        }, AllDrawings)
    end

    local FullLines = {}
    local FullOutlines = {}
    for i = 1, 4 do
        FullOutlines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 2,
            Color = ColorBlack,
            ZIndex = ZIndex,
        }, AllDrawings)
        FullLines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 1,
            Color = ColorWhite,
            ZIndex = ZIndex + 1,
        }, AllDrawings)
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
            Size = Config.FlagSize,
            Text = "",
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings)
    end

    local Drawings = {
        Corners = { CornersLines, CornersOutlines },
        Full = { FullLines, FullOutlines },
        Flags = FlagTexts,
        Name = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            OutlineColor = ColorBlack,
            Color = ColorWhite,
            Transparency = 1,
            Size = Config.TextSize,
            Text = GetPlayerName(self.Player),
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
        Weapon = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            OutlineColor = ColorBlack,
            Color = ColorWhite,
            Transparency = 1,
            Size = Config.TextSize,
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
        Distance = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            OutlineColor = ColorBlack,
            Color = ColorWhite,
            Transparency = 1,
            Size = Config.TextSize,
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
        HealthBar = CreateDrawing("Square", {
            Visible = false,
            Thickness = 1,
            Filled = true,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
        HealthBackground = CreateDrawing("Square", {
            Visible = false,
            Color = ColorBackground,
            Transparency = 0.7,
            Thickness = 1,
            Filled = true,
            ZIndex = ZIndex,
        }, AllDrawings),
    }

    return Drawings, AllDrawings
end

function PlayerESP:OnCharacterAdded(Character, FirstTime)
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    self.Current = {
        Character = Character,
        Humanoid = Humanoid,
        RootPart = Character:FindFirstChild("HumanoidRootPart") or Character.PrimaryPart,
        Health = 0,
        MaxHealth = 0,
        HealthPercentage = 0,
        Weapon = nil,
    }

    TableInsert(self.Connections, Character:GetPropertyChangedSignal("PrimaryPart"):Connect(function()
        if self.Current then
            self.Current.RootPart = Character.PrimaryPart
        end
    end))
    TableInsert(self.Connections, Character.ChildAdded:Connect(function(Child)
        self:OnChildAdded(Child)
    end))
    TableInsert(self.Connections, Character.ChildRemoved:Connect(function(Child)
        self:OnChildRemoved(Child)
    end))

    if Humanoid then
        TableInsert(self.Connections, Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if self.Current then
                self.Current.Health = Humanoid.Health
                self.Current.MaxHealth = Humanoid.MaxHealth
                self.Current.HealthPercentage = Humanoid.MaxHealth > 0 and (Humanoid.Health / Humanoid.MaxHealth) or 0
                self.Drawings.HealthBar.Color = ColorLerp(ColorRed, ColorGreen, self.Current.HealthPercentage)
            end
        end))

        if FirstTime then
            for _, Child in IPairs(Character:GetChildren()) do
                for j = 1, #PlayerESP.ChildAddedConnections do
                    PlayerESP.ChildAddedConnections[j](self, Child)
                end
            end
        end
    end
end

function PlayerESP:OnCharacterRemoved()
    self.Current = nil
    self:HideDrawings()
end

function PlayerESP:OnChildAdded(Child)
    if Child:IsA("Humanoid") then
        self.Current.Humanoid = Child
    end
    for i = 1, #PlayerESP.ChildAddedConnections do
        PlayerESP.ChildAddedConnections[i](self, Child)
    end
end

function PlayerESP:OnChildRemoved(Child)
    if not self.Current then return end
    if Child == self.Current.Humanoid then
        self.Current.Humanoid = nil
    elseif Child == self.Current.RootPart then
        self.Current.RootPart = nil
    end
    for i = 1, #PlayerESP.ChildRemovedConnections do
        PlayerESP.ChildRemovedConnections[i](self, Child)
    end
end

function PlayerESP:RenderName(Position2D, Offset, Enabled)
    local NameText = self.Drawings.Name
    if not Enabled then
        NameText.Visible = false
        return
    end
    NameText.Visible = true
    NameText.Text = GetPlayerName(self.Player)
    NameText.Position = Position2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
end

function PlayerESP:RenderWeapon(Center2D, Offset, Enabled, BottomYOffset)
    local WeaponText = self.Drawings.Weapon
    if not Enabled then
        WeaponText.Visible = false
        return 0
    end
    WeaponText.Visible = true
    WeaponText.Position = Center2D + Vector2New(0, Offset.Y + BottomYOffset)
    WeaponText.Text = self.Current.Weapon and StringLower(self.Current.Weapon.Name) or "none"
    return EspLibrary.Config.TextSize + 1
end

function PlayerESP:RenderDistance(Center2D, Offset, Enabled, BottomYOffset, DistanceOverride)
    local DistanceText = self.Drawings.Distance
    local RootPart = self.Current and self.Current.RootPart

    if not Enabled or not RootPart then
        DistanceText.Visible = false
        return 0
    end

    local PositionX = Center2D.X
    local PositionY = Center2D.Y + Offset.Y + BottomYOffset

    if EspLibrary.Config.PixelSnap then
        PositionX = MathFloor(PositionX + 0.5)
        PositionY = MathFloor(PositionY + 0.5)
    end

    DistanceText.Visible = true
    DistanceText.Center = true
    DistanceText.Size = EspLibrary.Config.TextSize
    DistanceText.Font = EspLibrary.Config.Font
    DistanceText.Position = Vector2New(PositionX, PositionY)
    DistanceText.Text = `[{MathRound(DistanceOverride or (Camera.CFrame.Position - RootPart.Position).Magnitude)}]`

    return EspLibrary.Config.TextSize + 1
end

function PlayerESP:RenderHealthbar(Position2D, Offset, Enabled)
    local HealthBar = self.Drawings.HealthBar
    local HealthBackground = self.Drawings.HealthBackground

    if not Enabled then
        HealthBar.Visible = false
        HealthBackground.Visible = false
        return
    end

    HealthBar.Visible = true
    HealthBackground.Visible = true

    local BasePosition = Position2D - Offset - Vector2New(5, 0)
    local BaseSize = Vector2New(3, Offset.Y * 2)
    local HealthPercentage = self.Current.HealthPercentage or 0
    local HealthLength = MathMax(0, (BaseSize.Y - 2) * HealthPercentage)

    HealthBackground.Position = BasePosition
    HealthBackground.Size = BaseSize
    HealthBar.Position = BasePosition + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLength))
    HealthBar.Size = Vector2New(1, HealthLength)
end

function PlayerESP:Loop(Settings, DistanceOverride)
    if not EspLibrary.Enabled then
        return self:HideDrawings()
    end

    local Current = self.Current
    if not Current then
        return self:HideDrawings()
    end

    local Character = Current.Character
    local Humanoid = Current.Humanoid
    local RootPart = Current.RootPart

    if not Character or not Humanoid or not RootPart then
        return self:HideDrawings()
    end

    local BoxCF, Size3D = GetBoundingBox(Character, true)
    if not Size3D then
        return self:HideDrawings()
    end

    local GoalPosition = BoxCF.Position
    local ScreenPosition, OnScreen = WorldToViewportPoint(GoalPosition)
    if not OnScreen then
        return self:HideDrawings()
    end

    self.Hidden = false

    local Center2D = Vector2New(ScreenPosition.X, ScreenPosition.Y)
    local BoxCFrame = CFrameNew(GoalPosition, GoalPosition + Camera.CFrame.LookVector)

    local X, Y = -Size3D.X / 2, Size3D.Y / 2
    local TopRight = WorldToViewportPoint((BoxCFrame * CFrameNew(X, Y, 0)).Position)
    local BottomRight = WorldToViewportPoint((BoxCFrame * CFrameNew(X, -Y, 0)).Position)

    local Offset = Vector2New(
        MathMax(MathAbs(TopRight.X - Center2D.X), MathAbs(BottomRight.X - Center2D.X)),
        MathMax(MathAbs(Center2D.Y - TopRight.Y), MathAbs(BottomRight.Y - Center2D.Y))
    )

    local BoxPosition2D = Center2D - Offset
    local BoxSize2D = Offset * 2

    self:RenderBox(BoxPosition2D, BoxSize2D, Settings.Box)
    self:RenderName(Center2D, Offset, Settings.Name)

    local BottomYOffset = 0

    if Settings.Healthbar then
        self:RenderHealthbar(Center2D, Offset, true)
        BottomYOffset = Offset.Y * 2 + 5
    else
        self:RenderHealthbar(Center2D, Offset, false)
    end

    BottomYOffset = BottomYOffset + self:RenderWeapon(Center2D, Offset, Settings.Weapon, BottomYOffset)
    BottomYOffset = BottomYOffset + self:RenderDistance(Center2D, Offset, Settings.Distance, BottomYOffset, DistanceOverride)

    self:RenderFlags(Settings.Flags, Center2D, Offset, BottomYOffset)
end

EspLibrary.PlayerESP = PlayerESP

local EntityESP = {
    Cache = {},
    DrawingCache = {},
    DrawingAddedConnections = {},
}

EntityESP.__index = EntityESP
setmetatable(EntityESP, { __index = Base })

function EntityESP.OnDrawingAdded(Callback)
    TableInsert(EntityESP.DrawingAddedConnections, Callback)
end

function EntityESP.New(Entity, Color, Name)
    local Self = setmetatable({
        Entity = Entity,
        Color = Color or ColorWhite,
        Name = Name or Entity.Name,
        Connections = {},
        Hidden = false,
        AllDrawings = nil,
        Drawings = nil,
    }, EntityESP)

    local CachedDrawings = EntityESP.DrawingCache[1]
    if CachedDrawings then
        TableRemove(EntityESP.DrawingCache, 1)
        CachedDrawings.Name.Text = Self.Name
        CachedDrawings.Name.Color = Self.Color
        for i = 1, 4 do
            CachedDrawings.Full[1][i].Color = Self.Color
        end
        for i = 1, 8 do
            CachedDrawings.Corners[1][i].Color = Self.Color
        end
        CachedDrawings.Distance.Color = Self.Color
        Self.AllDrawings = CachedDrawings.AllDrawings
        Self.Drawings = CachedDrawings
    else
        Self.Drawings, Self.AllDrawings = Self:CreateDrawings()
    end

    for i = 1, #EntityESP.DrawingAddedConnections do
        EntityESP.DrawingAddedConnections[i](Self)
    end

    EntityESP.Cache[Entity] = Self
    TableInsert(Self.Connections, Entity.AncestryChanged:Connect(function(_, Parent)
        if not Parent then
            EntityESP.Remove(Entity)
        end
    end))

    return Self
end

function EntityESP.Remove(Entity)
    local Cache = EntityESP.Cache[Entity]
    if not Cache then return end

    EntityESP.Cache[Entity] = nil
    for i = 1, #Cache.Connections do
        Cache.Connections[i]:Disconnect()
    end

    if Cache.Drawings then
        for i = 1, #Cache.AllDrawings do
            Cache.AllDrawings[i].Visible = false
        end
        TableInsert(EntityESP.DrawingCache, Cache.Drawings)
    end
end

function EntityESP:CreateDrawings()
    local AllDrawings = {}
    local Config = EspLibrary.Config
    local ZIndex = 1

    local FullLines = {}
    local FullOutlines = {}
    for i = 1, 4 do
        FullOutlines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 2,
            Color = ColorBlack,
            ZIndex = ZIndex,
        }, AllDrawings)
        FullLines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 1,
            Color = self.Color,
            ZIndex = ZIndex + 1,
        }, AllDrawings)
    end

    local CornersLines = {}
    local CornersOutlines = {}
    for i = 1, 8 do
        CornersOutlines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 2,
            Color = ColorBlack,
            ZIndex = ZIndex,
        }, AllDrawings)
        CornersLines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 1,
            Color = self.Color,
            ZIndex = ZIndex + 1,
        }, AllDrawings)
    end

    local Drawings = {
        Corners = { CornersLines, CornersOutlines },
        Full = { FullLines, FullOutlines },
        Name = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            OutlineColor = ColorBlack,
            Color = self.Color,
            Transparency = 1,
            Size = Config.TextSize,
            Text = self.Name,
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
        Distance = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            OutlineColor = ColorBlack,
            Color = self.Color,
            Transparency = 1,
            Size = Config.TextSize,
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
    }

    return Drawings, AllDrawings
end

function EntityESP:Loop(Settings, DistanceOverride)
    if not EspLibrary.Enabled then
        return self:HideDrawings()
    end

    local Entity = self.Entity
    if not Entity or not Entity.Parent then
        return EntityESP.Remove(Entity)
    end

    local Success, BoxCF, BoxSize = Ypcall(Entity.GetBoundingBox, Entity)
    if not Success or not BoxCF or not BoxSize then
        return self:HideDrawings()
    end

    local MinX, MinY, MaxX, MaxY, AnyInFront, MinZ = Get2DBoxFrom3DBounds(BoxCF, BoxSize)

    if not AnyInFront or MinZ <= 0 then
        return self:HideDrawings()
    end

    local Width = MaxX - MinX
    local Height = MaxY - MinY
    if Width <= 1 or Height <= 1 or Width ~= Width or Height ~= Height then
        return self:HideDrawings()
    end

    self.Hidden = false

    if EspLibrary.Config.PixelSnap then
        MinX = MathFloor(MinX + 0.5)
        MinY = MathFloor(MinY + 0.5)
        MaxX = MathFloor(MaxX + 0.5)
        MaxY = MathFloor(MaxY + 0.5)
    end

    Width = MaxX - MinX
    Height = MaxY - MinY
    local BoxPosition2D = Vector2New(MinX, MinY)
    local BoxSize2D = Vector2New(Width, Height)
    local Center2D = BoxPosition2D + BoxSize2D * 0.5
    local Offset = BoxSize2D * 0.5

    self:RenderBox(BoxPosition2D, BoxSize2D, Settings.Box)

    local Drawings = self.Drawings

    if Settings.Name then
        Drawings.Name.Visible = true
        Drawings.Name.Position = Center2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
    else
        Drawings.Name.Visible = false
    end

    if Settings.Distance then
        Drawings.Distance.Visible = true
        Drawings.Distance.Position = Center2D + Vector2New(0, Offset.Y)
        Drawings.Distance.Text = `[{MathRound(DistanceOverride or (Camera.CFrame.Position - BoxCF.Position).Magnitude)}]`
    else
        Drawings.Distance.Visible = false
    end
end

EspLibrary.EntityESP = EntityESP

local NPC_ESP = {
    Cache = {},
    DrawingCache = {},
    DrawingAddedConnections = {},
}

NPC_ESP.__index = NPC_ESP
setmetatable(NPC_ESP, { __index = Base })

function NPC_ESP.OnDrawingAdded(Callback)
    TableInsert(NPC_ESP.DrawingAddedConnections, Callback)
end

function NPC_ESP.New(Model, Color, Name)
    local Self = setmetatable({
        Model = Model,
        Humanoid = nil,
        Color = Color or ColorWhite,
        Name = Name or Model.Name,
        Connections = {},
        Hidden = false,
        HealthPercentage = 1,
        AllDrawings = nil,
        Drawings = nil,
    }, NPC_ESP)

    local CachedDrawings = NPC_ESP.DrawingCache[1]
    if CachedDrawings then
        TableRemove(NPC_ESP.DrawingCache, 1)
        CachedDrawings.Name.Text = Self.Name
        CachedDrawings.Name.Color = Self.Color
        for i = 1, 4 do
            CachedDrawings.Full[1][i].Color = Self.Color
        end
        for i = 1, 8 do
            CachedDrawings.Corners[1][i].Color = Self.Color
        end
        CachedDrawings.Distance.Color = Self.Color
        Self.AllDrawings = CachedDrawings.AllDrawings
        Self.Drawings = CachedDrawings
    else
        Self.Drawings, Self.AllDrawings = Self:CreateDrawings()
    end

    for i = 1, #NPC_ESP.DrawingAddedConnections do
        NPC_ESP.DrawingAddedConnections[i](Self)
    end

    local function SetupHumanoid(Humanoid)
        if Self.Humanoid then return end
        Self.Humanoid = Humanoid
        local function UpdateHealth()
            Self.HealthPercentage = Humanoid.MaxHealth > 0 and (Humanoid.Health / Humanoid.MaxHealth) or 0
        end
        UpdateHealth()
        TableInsert(Self.Connections, Humanoid:GetPropertyChangedSignal("Health"):Connect(UpdateHealth))
        TableInsert(Self.Connections, Humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(UpdateHealth))
    end

    local InitialHumanoid = Model:FindFirstChildOfClass("Humanoid")
    if InitialHumanoid then
        SetupHumanoid(InitialHumanoid)
    else
        TableInsert(Self.Connections, Model.ChildAdded:Connect(function(Child)
            if Child:IsA("Humanoid") then
                SetupHumanoid(Child)
            end
        end))
    end

    TableInsert(Self.Connections, Model.AncestryChanged:Connect(function(_, Parent)
        if not Parent then
            NPC_ESP.Remove(Model)
        end
    end))

    NPC_ESP.Cache[Model] = Self
    return Self
end

function NPC_ESP.Remove(Model)
    local Cache = NPC_ESP.Cache[Model]
    if not Cache then return end

    NPC_ESP.Cache[Model] = nil
    for i = 1, #Cache.Connections do
        Cache.Connections[i]:Disconnect()
    end

    if Cache.Drawings then
        for i = 1, #Cache.AllDrawings do
            Cache.AllDrawings[i].Visible = false
        end
        TableInsert(NPC_ESP.DrawingCache, Cache.Drawings)
    end
end

function NPC_ESP:CreateDrawings()
    local AllDrawings = {}
    local Config = EspLibrary.Config
    local ZIndex = 1

    local FullLines = {}
    local FullOutlines = {}
    for i = 1, 4 do
        FullOutlines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 2,
            Color = ColorBlack,
            ZIndex = ZIndex,
        }, AllDrawings)
        FullLines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 1,
            Color = self.Color,
            ZIndex = ZIndex + 1,
        }, AllDrawings)
    end

    local CornersLines = {}
    local CornersOutlines = {}
    for i = 1, 8 do
        CornersOutlines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 2,
            Color = ColorBlack,
            ZIndex = ZIndex,
        }, AllDrawings)
        CornersLines[i] = CreateDrawing("Line", {
            Visible = false,
            Thickness = 1,
            Color = self.Color,
            ZIndex = ZIndex + 1,
        }, AllDrawings)
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
            Size = Config.FlagSize,
            Text = "",
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings)
    end

    local Drawings = {
        Corners = { CornersLines, CornersOutlines },
        Full = { FullLines, FullOutlines },
        Flags = FlagTexts,
        Name = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            OutlineColor = ColorBlack,
            Color = self.Color,
            Transparency = 1,
            Size = Config.TextSize,
            Text = self.Name,
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
        Distance = CreateDrawing("Text", {
            Visible = false,
            Center = true,
            Outline = true,
            OutlineColor = ColorBlack,
            Color = self.Color,
            Transparency = 1,
            Size = Config.TextSize,
            Font = Config.Font,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
        HealthBar = CreateDrawing("Square", {
            Visible = false,
            Thickness = 1,
            Filled = true,
            ZIndex = ZIndex + 1,
        }, AllDrawings),
        HealthBackground = CreateDrawing("Square", {
            Visible = false,
            Color = ColorBackground,
            Transparency = 0.7,
            Thickness = 1,
            Filled = true,
            ZIndex = ZIndex,
        }, AllDrawings),
    }

    return Drawings, AllDrawings
end

function NPC_ESP:RenderName(Center2D, Offset, Enabled)
    local NameText = self.Drawings.Name
    if not Enabled then
        NameText.Visible = false
        return
    end
    NameText.Visible = true
    NameText.Position = Center2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
    NameText.Text = self.Name or "NPC"
end

function NPC_ESP:RenderDistance(Center2D, Offset, Enabled, BottomYOffset, DistanceOverride)
    local DistanceText = self.Drawings.Distance
    if not Enabled then
        DistanceText.Visible = false
        return 0
    end

    DistanceText.Visible = true
    DistanceText.Position = Center2D + Vector2New(0, Offset.Y + BottomYOffset)
    DistanceText.Text = `[{MathRound(DistanceOverride or (Camera.CFrame.Position - self.Model:GetPivot().Position).Magnitude)}]`
    return EspLibrary.Config.TextSize + 1
end

function NPC_ESP:Loop(Settings, DistanceOverride)
    if not EspLibrary.Enabled then
        return self:HideDrawings()
    end

    local Model = self.Model
    local Humanoid = self.Humanoid
    if not Model or not Model.Parent or not Humanoid then
        return NPC_ESP.Remove(Model)
    end

    local BoxCF, Size3D = GetBoundingBox(Model, true)
    if not BoxCF or not Size3D then
        return self:HideDrawings()
    end

    local GoalPosition = BoxCF.Position
    local ScreenPosition, OnScreen = WorldToViewportPoint(GoalPosition)
    if not OnScreen then
        return self:HideDrawings()
    end

    self.Hidden = false

    local Center2D = Vector2New(ScreenPosition.X, ScreenPosition.Y)
    local BoxCFrame = CFrameNew(GoalPosition, GoalPosition + Camera.CFrame.LookVector)

    local X, Y = -Size3D.X / 2, Size3D.Y / 2
    local TopRight = WorldToViewportPoint((BoxCFrame * CFrameNew(X, Y, 0)).Position)
    local BottomRight = WorldToViewportPoint((BoxCFrame * CFrameNew(X, -Y, 0)).Position)

    local Offset = Vector2New(
        MathMax(MathAbs(TopRight.X - Center2D.X), MathAbs(BottomRight.X - Center2D.X)),
        MathMax(MathAbs(Center2D.Y - TopRight.Y), MathAbs(BottomRight.Y - Center2D.Y))
    )

    local BoxPosition2D = Center2D - Offset
    local BoxSize2D = Offset * 2

    self:RenderBox(BoxPosition2D, BoxSize2D, Settings.Box)
    self:RenderName(Center2D, Offset, Settings.Name)

    local BottomYOffset = self:RenderDistance(Center2D, Offset, Settings.Distance, 0, DistanceOverride)
    BottomYOffset = BottomYOffset + self:RenderFlags(Settings.Flags, Center2D, Offset, BottomYOffset)

    if Settings.Healthbar then
        local HealthBar = self.Drawings.HealthBar
        local HealthBackground = self.Drawings.HealthBackground

        HealthBar.Visible = true
        HealthBackground.Visible = true

        local BasePosition = Center2D - Offset - Vector2New(5, 0)
        local BaseSize = Vector2New(3, Offset.Y * 2)
        local HealthPercentage = self.HealthPercentage or 0
        local HealthLength = MathMax(0, (BaseSize.Y - 2) * HealthPercentage)

        HealthBackground.Position = BasePosition
        HealthBackground.Size = BaseSize
        HealthBar.Position = BasePosition + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLength))
        HealthBar.Size = Vector2New(1, HealthLength)
        HealthBar.Color = ColorLerp(ColorRed, ColorGreen, HealthPercentage)
    else
        self.Drawings.HealthBar.Visible = false
        self.Drawings.HealthBackground.Visible = false
    end
end

EspLibrary.NPC_ESP = NPC_ESP

function EspLibrary:Unload()
    for _, PlayerEspInstance in Pairs(PlayerESP.Cache) do
        PlayerESP.Remove(PlayerEspInstance.Player)
    end
    for _, EntityEspInstance in Pairs(EntityESP.Cache) do
        EntityESP.Remove(EntityEspInstance.Entity)
    end
    for _, NpcEspInstance in Pairs(NPC_ESP.Cache) do
        NPC_ESP.Remove(NpcEspInstance.Model)
    end

    local function ClearCache(Cache)
        for _, CachedDrawings in IPairs(Cache) do
            for _, DrawingObject in IPairs(CachedDrawings.AllDrawings) do
                DrawingObject:Remove()
            end
        end
        TableClear(Cache)
    end

    ClearCache(PlayerESP.DrawingCache)
    ClearCache(EntityESP.DrawingCache)
    ClearCache(NPC_ESP.DrawingCache)
end

return EspLibrary, 3
