local CloneRef = cloneref or function(...) return ... end
local Workspace = CloneRef(game:GetService("Workspace"))
local CurrentCamera = Workspace.CurrentCamera
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint

local DrawingNew = Drawing.new
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local Color3New = Color3.new
local TableInsert = table.insert
local TableRemove = table.remove
local MathFloor = math.floor
local MathClamp = math.clamp
local MathRound = math.round
local MathHuge = math.huge
local Pairs = pairs
local IPairs = ipairs
local ToString = tostring
local Type = type

local COLOR_BLACK = Color3New(0, 0, 0)
local COLOR_WHITE = Color3New(1, 1, 1)
local COLOR_GREEN = Color3New(0, 1, 0)
local COLOR_RED = Color3New(1, 0, 0)
local COLOR_BACKGROUND = Color3New(0.239215, 0.239215, 0.239215)

local VisibleItemsBuffer = {}

local CreateDrawing = function(Type, Properties, ...)
    local DrawingObject = DrawingNew(Type)
    for Key, Value in Pairs(Properties) do
        DrawingObject[Key] = Value
    end
    local Args = {...}
    if #Args > 0 then
        for _, TableRef in IPairs(Args) do
            TableInsert(TableRef, DrawingObject)
        end
    end
    return DrawingObject
end

local GlobalFont = (getgenv and getgenv().GLOBAL_FONT) or _G.GLOBAL_FONT or 1
local GlobalSize = (getgenv and getgenv().GLOBAL_SIZE) or _G.GLOBAL_SIZE or 13
local BaseZIndex = 1

local EspLibrary = {}

EspLibrary.Config = {
    Font = GlobalFont,
    TextSize = GlobalSize,

    FlagSize = MathClamp(GlobalSize - 2, 11, 13),
    FlagLinePadding = 2,
    FlagXPadding = 6,

    BoxCornerWidthScale = 0.25,
    BoxCornerHeightScale = 0.25,

    PixelSnap = true,

    NameMode = "DisplayName",
}

do
    local PlayerESP = {
        PlayerCache = {},
        DrawingCache = {},

        ChildAddedConnections = {},
        ChildRemovedConnections = {},
        DrawingAddedConnections = {},
    }
    PlayerESP.__index = PlayerESP

    PlayerESP.OnChildAdded = function(Callback)
        PlayerESP.ChildAddedConnections[#PlayerESP.ChildAddedConnections + 1] = Callback
    end
    PlayerESP.OnChildRemoved = function(Callback)
        PlayerESP.ChildRemovedConnections[#PlayerESP.ChildRemovedConnections + 1] = Callback
    end
    PlayerESP.OnDrawingAdded = function(Callback)
        PlayerESP.DrawingAddedConnections[#PlayerESP.DrawingAddedConnections + 1] = Callback
    end

    local function GetBoundingBoxSafe(Character, Humanoid)
        if Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R15 and Humanoid.ComputeR15BodyBoundingBox then
            local Ok, CF, Size = pcall(Humanoid.ComputeR15BodyBoundingBox, Humanoid)
            if Ok and CF and Size then
                return CF, Size
            end
        end

        if Character and Character.GetBoundingBox then
            local Ok, CF, Size = pcall(Character.GetBoundingBox, Character)
            if Ok and CF and Size then
                return CF, Size
            end
        end

        return nil, nil
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
            local OX = HX * IX
            for IY = -1, 1, 2 do
                local OY = HY * IY
                for IZ = -1, 1, 2 do
                    local OZ = HZ * IZ
                    local CornerWorld = (CF * Vector3New(OX, OY, OZ))
                    local X, Y, Z = ProjectPointToScreen(CornerWorld)

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
        if EspLibrary.Config.NameMode == "Username" then
            return Player.Name
        end
        return Player.DisplayName
    end

    function PlayerESP:CreateDrawingCache()
        local AllDrawings = {}
        local Cfg = EspLibrary.Config

        local Corners = { Lines = {}, Outlines = {} }
        for i = 1, 8 do
            Corners.Outlines[i] = CreateDrawing("Line", {
                Visible = false,
                Thickness = 2,
                Color = COLOR_BLACK,
                ZIndex = BaseZIndex,
            }, AllDrawings)
            Corners.Lines[i] = CreateDrawing("Line", {
                Visible = false,
                Thickness = 1,
                Color = COLOR_WHITE,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
        end

        local FullBox = { Lines = {}, Outlines = {} }
        for i = 1, 4 do
            FullBox.Outlines[i] = CreateDrawing("Line", {
                Visible = false,
                Thickness = 2,
                Color = COLOR_BLACK,
                ZIndex = BaseZIndex,
            }, AllDrawings)
            FullBox.Lines[i] = CreateDrawing("Line", {
                Visible = false,
                Thickness = 1,
                Color = COLOR_WHITE,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
        end

        local FlagTexts = {}
        for i = 1, 6 do
            FlagTexts[i] = CreateDrawing("Text", {
                Visible = false,
                Center = false,
                Outline = true,
                OutlineColor = COLOR_BLACK,
                Color = COLOR_WHITE,
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
                OutlineColor = COLOR_BLACK,
                Color = COLOR_WHITE,
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
                OutlineColor = COLOR_BLACK,
                Color = COLOR_WHITE,
                Transparency = 1,
                Size = Cfg.TextSize,
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),

            Distance = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = COLOR_BLACK,
                Color = COLOR_WHITE,
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
                Color = COLOR_BACKGROUND,
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

    PlayerESP.New = function(Player)
        local Self = setmetatable({
            Player = Player,
            Connections = {},
            Hidden = false,
            AllDrawings = nil,
            Drawings = nil,
            Current = nil,
        }, PlayerESP)

        local Cache = PlayerESP.DrawingCache[1]
        if Cache then
            TableRemove(PlayerESP.DrawingCache, 1)
            Cache.Name.Text = GetPlayerName(Player)
            Self.AllDrawings = Cache.All
            Self.Drawings = Cache
        else
            Self:CreateDrawingCache()
        end

        for i = 1, #PlayerESP.DrawingAddedConnections do
            PlayerESP.DrawingAddedConnections[i](Self)
        end

        Self.Connections[#Self.Connections + 1] = Player.CharacterAdded:Connect(function(...)
            return Self:CharacterAdded(...)
        end)
        Self.Connections[#Self.Connections + 1] = Player.CharacterRemoving:Connect(function(...)
            return Self:CharacterRemoved(...)
        end)

        if Player.Character then
            Self:CharacterAdded(Player.Character, true)
        end

        PlayerESP.PlayerCache[Player] = Self
        return Self
    end

    PlayerESP.Remove = function(Player)
        local Cache = PlayerESP.PlayerCache[Player]
        if Type(Cache) ~= "table" then return end

        PlayerESP.PlayerCache[Player] = nil

        if Cache.Connections then
            for i = 1, #Cache.Connections do
                Cache.Connections[i]:Disconnect()
            end
        end

        if Cache.Drawings then
            PlayerESP.DrawingCache[#PlayerESP.DrawingCache + 1] = Cache.Drawings
        end
    end

    function PlayerESP:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function PlayerESP:HumanoidHealthChanged()
        local Humanoid = self.Current and self.Current.Humanoid
        if not Humanoid then return end

        local Health = Humanoid.Health
        local MaxHealth = Humanoid.MaxHealth
        local HealthPercentage = (MaxHealth > 0 and (Health / MaxHealth)) or 0

        self.Current.Health = Health
        self.Current.MaxHealth = MaxHealth
        self.Current.HealthPercentage = HealthPercentage

        self.Drawings.HealthBar.Color = COLOR_RED:Lerp(COLOR_GREEN, HealthPercentage)
    end

    function PlayerESP:SetupHumanoid(Humanoid, FirstTime)
        self:HumanoidHealthChanged()

        self.Connections[#self.Connections + 1] = Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            self:HumanoidHealthChanged()
        end)

        if FirstTime then
            local ChildAddedConnections = self.ChildAddedConnections
            local CharacterChildren = self.Current.Character:GetChildren()
            for i = 1, #CharacterChildren do
                local Child = CharacterChildren[i]
                for j = 1, #ChildAddedConnections do
                    ChildAddedConnections[j](self, Child)
                end
            end
        end
    end

    function PlayerESP:ChildAdded(Child)
        if Child.ClassName == "Humanoid" then
            self.Current.Humanoid = Child
            self:SetupHumanoid(Child)
        end

        for i = 1, #self.ChildAddedConnections do
            self.ChildAddedConnections[i](self, Child)
        end
    end

    function PlayerESP:ChildRemoved(Child)
        if not self.Current then return end
        if Child == self.Current.Humanoid then
            self.Current.Humanoid = nil
        elseif Child == self.Current.RootPart then
            self.Current.RootPart = nil
        end

        for i = 1, #self.ChildRemovedConnections do
            self.ChildRemovedConnections[i](self, Child)
        end
    end

    function PlayerESP:PrimaryPartAdded()
        local Character = self.Current and self.Current.Character
        if not Character then return end
        local PrimaryPart = Character.PrimaryPart
        if PrimaryPart then
            self.Current.RootPart = PrimaryPart
        end
    end

    function PlayerESP:CharacterAdded(Character, FirstTime)
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

        self.Connections[#self.Connections + 1] = Character:GetPropertyChangedSignal("PrimaryPart"):Connect(function()
            self:PrimaryPartAdded()
        end)
        self.Connections[#self.Connections + 1] = Character.ChildAdded:Connect(function(...)
            return self:ChildAdded(...)
        end)
        self.Connections[#self.Connections + 1] = Character.ChildRemoved:Connect(function(...)
            return self:ChildRemoved(...)
        end)

        if self.Current.Humanoid then
            self:SetupHumanoid(self.Current.Humanoid, FirstTime)
        end
    end

    function PlayerESP:CharacterRemoved()
        self.Current = nil
        for i = 1, #self.AllDrawings do
            self.AllDrawings[i].Visible = false
        end
    end

    function PlayerESP:RenderBox(BoxPos2D, BoxSize2D, BoxSettings)
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

            local Outline1, Line1 = FullOutlines[1], FullLines[1]
            Outline1.Visible, Line1.Visible = true, true
            Outline1.From, Outline1.To = P1, P2
            Line1.From, Line1.To = P1, P2

            local Outline2, Line2 = FullOutlines[2], FullLines[2]
            Outline2.Visible, Line2.Visible = true, true
            Outline2.From, Outline2.To = P2, P3
            Line2.From, Line2.To = P2, P3

            local Outline3, Line3 = FullOutlines[3], FullLines[3]
            Outline3.Visible, Line3.Visible = true, true
            Outline3.From, Outline3.To = P3, P4
            Line3.From, Line3.To = P3, P4

            local Outline4, Line4 = FullOutlines[4], FullLines[4]
            Outline4.Visible, Line4.Visible = true, true
            Outline4.From, Outline4.To = P4, P1
            Line4.From, Line4.To = P4, P1

            return
        end

        for i = 1, 4 do
            FullLines[i].Visible = false
            FullOutlines[i].Visible = false
        end

        local Cfg = EspLibrary.Config
        local HorizontalLen = MathFloor(BoxSize2D.X * Cfg.BoxCornerWidthScale)
        local VerticalLen = MathFloor(BoxSize2D.Y * Cfg.BoxCornerHeightScale)

        local TL_H_A = Vector2New(Left, Top)
        local TL_H_B = Vector2New(Left + HorizontalLen, Top)
        local TL_V_A = Vector2New(Left, Top)
        local TL_V_B = Vector2New(Left, Top + VerticalLen)
        
        local TR_H_A = Vector2New(Right - HorizontalLen, Top)
        local TR_H_B = Vector2New(Right, Top)
        local TR_V_A = Vector2New(Right, Top)
        local TR_V_B = Vector2New(Right, Top + VerticalLen)
        
        local BL_H_A = Vector2New(Left, Bottom)
        local BL_H_B = Vector2New(Left + HorizontalLen, Bottom)
        local BL_V_A = Vector2New(Left, Bottom - VerticalLen)
        local BL_V_B = Vector2New(Left, Bottom)

        local BR_H_A = Vector2New(Right - HorizontalLen, Bottom)
        local BR_H_B = Vector2New(Right, Bottom)
        local BR_V_A = Vector2New(Right, Bottom - VerticalLen)
        local BR_V_B = Vector2New(Right, Bottom)

        local O1, L1 = CornersOutlines[1], CornersLines[1]
        O1.Visible, L1.Visible = true, true
        O1.From, O1.To = TL_H_A, TL_H_B
        L1.From, L1.To = TL_H_A, TL_H_B

        local O2, L2 = CornersOutlines[2], CornersLines[2]
        O2.Visible, L2.Visible = true, true
        O2.From, O2.To = TL_V_A, TL_V_B
        L2.From, L2.To = TL_V_A, TL_V_B

        local O3, L3 = CornersOutlines[3], CornersLines[3]
        O3.Visible, L3.Visible = true, true
        O3.From, O3.To = TR_H_A, TR_H_B
        L3.From, L3.To = TR_H_A, TR_H_B

        local O4, L4 = CornersOutlines[4], CornersLines[4]
        O4.Visible, L4.Visible = true, true
        O4.From, O4.To = TR_V_A, TR_V_B
        L4.From, L4.To = TR_V_A, TR_V_B

        local O5, L5 = CornersOutlines[5], CornersLines[5]
        O5.Visible, L5.Visible = true, true
        O5.From, O5.To = BL_H_A, BL_H_B
        L5.From, L5.To = BL_H_A, BL_H_B

        local O6, L6 = CornersOutlines[6], CornersLines[6]
        O6.Visible, L6.Visible = true, true
        O6.From, O6.To = BL_V_A, BL_V_B
        L6.From, L6.To = BL_V_A, BL_V_B

        local O7, L7 = CornersOutlines[7], CornersLines[7]
        O7.Visible, L7.Visible = true, true
        O7.From, O7.To = BR_H_A, BR_H_B
        L7.From, L7.To = BR_H_A, BR_H_B

        local O8, L8 = CornersOutlines[8], CornersLines[8]
        O8.Visible, L8.Visible = true, true
        O8.From, O8.To = BR_V_A, BR_V_B
        L8.From, L8.To = BR_V_A, BR_V_B
    end

    function PlayerESP:RenderName(Vector2Pos, Offset, Enabled)
        local Name = self.Drawings.Name
        if not Enabled then
            Name.Visible = false
            return
        end
        Name.Visible = true
        Name.Text = GetPlayerName(self.Player)
        Name.Position = Vector2Pos - Vector2New(0, Offset.Y + Name.Size)
    end

    function PlayerESP:RenderWeapon(Center2D, Offset, Enabled, BottomYOffset)
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

    function PlayerESP:RenderDistance(Center2D, Offset, Enabled, BottomYOffset, DistanceOverride)
        local Distance = self.Drawings.Distance
        if not Enabled then
            Distance.Visible = false
            return 0
        end

        local RootPart = self.Current and self.Current.RootPart
        if not RootPart then
            Distance.Visible = false
            return 0
        end

        local Cfg = EspLibrary.Config

        local Magnitude = MathRound(
            DistanceOverride or
            (CurrentCamera.CFrame.Position - RootPart.Position).Magnitude
        )

        local PosX = Center2D.X
        local PosY = Center2D.Y + Offset.Y + BottomYOffset

        if Cfg.PixelSnap then
            PosX = MathFloor(PosX + 0.5)
            PosY = MathFloor(PosY + 0.5)
        end

        Distance.Visible = true
        Distance.Center = true
        Distance.Size = Cfg.TextSize
        Distance.Font = Cfg.Font
        Distance.Position = Vector2New(PosX, PosY)
        Distance.Text = `[{Magnitude}]`

        return Cfg.TextSize + 1
    end

    function PlayerESP:RenderHealthbar(Vector2Pos, Offset, Enabled)
        if not Enabled then
            self.Drawings.HealthBar.Visible = false
            self.Drawings.HealthBackground.Visible = false
            return
        end

        local HealthBar = self.Drawings.HealthBar
        local HealthBackground = self.Drawings.HealthBackground

        HealthBar.Visible = true
        HealthBackground.Visible = true

        local BasePosition = Vector2Pos - Offset - Vector2New(5, 0)
        local BaseSize = Vector2New(3, Offset.Y * 2)

        local HealthLength = (BaseSize.Y - 2) * (self.Current.HealthPercentage or 0)
        local HealthPosition = BasePosition + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLength))
        local HealthSize = Vector2New(1, HealthLength)

        HealthBackground.Position = BasePosition
        HealthBackground.Size = BaseSize

        HealthBar.Position = HealthPosition
        HealthBar.Size = HealthSize
    end

    function PlayerESP:RenderFlags(Center2D, Offset, FlagsSettings, BottomYOffset)
        local FlagTexts = self.Drawings.FlagTexts
        for i = 1, #FlagTexts do
            FlagTexts[i].Visible = false
        end

        if not FlagsSettings or not FlagsSettings.Enabled then
            return 0
        end

        table.clear(VisibleItemsBuffer)

        local Items = nil
        if Type(FlagsSettings.Builder) == "function" then
            local Ok, Result = pcall(function()
                return FlagsSettings.Builder(self)
            end)
            if Ok and Type(Result) == "table" then
                Items = Result
            end
        end

        local Mode = FlagsSettings.Mode and string.lower(FlagsSettings.Mode) or "normal"

        if Items then
            if Mode == "always" then
                for i = 1, #Items do
                    VisibleItemsBuffer[#VisibleItemsBuffer + 1] = Items[i]
                end
            else
                for i = 1, #Items do
                    if Items[i] and Items[i].State then
                        VisibleItemsBuffer[#VisibleItemsBuffer + 1] = Items[i]
                    end
                end
            end
        end

        local Count = #VisibleItemsBuffer
        if Count == 0 then
            return 0
        end

        local Cfg = EspLibrary.Config

        local MaxFlags = #FlagTexts
        if Count > MaxFlags then
            Count = MaxFlags
        end
        if Count <= 0 then
            return 0
        end

        local TextSize = Cfg.TextSize
        local LineHeight = TextSize + 1

        for i = 1, Count do
            local Item = VisibleItemsBuffer[i]
            local TextObj = FlagTexts[i]

            local PosX = Center2D.X
            local PosY = Center2D.Y + Offset.Y + BottomYOffset + ((i - 1) * LineHeight)

            if Cfg.PixelSnap then
                PosX = MathFloor(PosX + 0.5)
                PosY = MathFloor(PosY + 0.5)
            end

            local State = not not (Item and Item.State)

            TextObj.Visible = true
            TextObj.Center = true
            TextObj.Font = Cfg.Font
            TextObj.Size = TextSize
            TextObj.Outline = true
            TextObj.OutlineColor = COLOR_BLACK
            TextObj.Transparency = 1
            TextObj.Text = ToString(Item and Item.Text or "")
            TextObj.Position = Vector2New(PosX, PosY)

            if Mode == "always" then
                local TrueColor = (Item and Item.ColorTrue) or COLOR_GREEN
                local FalseColor = (Item and Item.ColorFalse) or COLOR_RED
                TextObj.Color = State and TrueColor or FalseColor
            else
                TextObj.Color = (Item and Item.ColorTrue) or COLOR_GREEN
            end
        end

        return Count * LineHeight
    end

    function PlayerESP:Loop(Settings, DistanceOverride)
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

        local BoxCF, BoxSize3 = GetBoundingBoxSafe(Character, Humanoid)
        if not BoxCF or not BoxSize3 then
            return self:HideDrawings()
        end

        local MinX, MinY, MaxX, MaxY, AnyInFront, MinZ = Get2DBoxFrom3DBounds(BoxCF, BoxSize3)
        if not AnyInFront or MinZ <= 0 then
            Current.Visible = false
            return self:HideDrawings()
        end

        local W = MaxX - MinX
        local H = MaxY - MinY
        if W <= 1 or H <= 1 or W ~= W or H ~= H then
            return self:HideDrawings()
        end

        Current.Visible = true
        self.Hidden = false

        local BoxPos2D = Vector2New(MinX, MinY)
        local BoxSize2D = Vector2New(W, H)

        local Center2D = BoxPos2D + (BoxSize2D * 0.5)
        local Offset = BoxSize2D * 0.5

        self:RenderBox(BoxPos2D, BoxSize2D, Settings.Box)
        self:RenderName(Center2D, Offset, Settings.Name)
        self:RenderHealthbar(Center2D, Offset, Settings.Healthbar)

        local BottomYOffset = 0
        local WeaponUsed = self:RenderWeapon(Center2D, Offset, Settings.Weapon, BottomYOffset)
        BottomYOffset = BottomYOffset + WeaponUsed

        local DistanceUsed = self:RenderDistance(Center2D, Offset, Settings.Distance, BottomYOffset, DistanceOverride)
        BottomYOffset = BottomYOffset + DistanceUsed

        self:RenderFlags(Center2D, Offset, Settings.Flags, BottomYOffset)
    end

    EspLibrary.PlayerESP = PlayerESP

    function EspLibrary:Unload()
        for _, PlayerEspInstance in Pairs(PlayerESP.PlayerCache) do
            PlayerESP.Remove(PlayerEspInstance.Player)
        end
        for _, CachedDrawings in IPairs(PlayerESP.DrawingCache) do
            for _, DrawingObject in IPairs(CachedDrawings.All) do
                DrawingObject:Remove()
            end
        end
        table.clear(PlayerESP.DrawingCache)
    end
end
return EspLibrary, 3
