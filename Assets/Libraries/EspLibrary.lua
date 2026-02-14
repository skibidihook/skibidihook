local CloneRef = cloneref or function(...) return ... end
local CurrentCamera = CloneRef(workspace.CurrentCamera)

local CreateDrawing = function(Type, Properties, ...)
    local DrawingObject = Drawing.new(Type)
    for Key, Value in pairs(Properties) do
        DrawingObject[Key] = Value
    end
    for _, TableRef in {...} do
        table.insert(TableRef, DrawingObject)
    end
    return DrawingObject
end

local GlobalFont = _G.GLOBAL_FONT or 1
local GlobalSize = _G.GLOBAL_SIZE or 13
local BaseZIndex = 1

local EspLibrary = {}

EspLibrary.Config = {
    Font = GlobalFont,
    TextSize = GlobalSize,

    FlagSize = math.clamp(GlobalSize - 2, 11, 13),
    FlagLinePadding = 2,
    FlagXPadding = 6,

    BoxCornerWidthScale = 0.25,
    BoxCornerHeightScale = 0.25,

    PixelSnap = true,
}

local function SnapN(N)
    return math.floor(N + 0.5)
end

local function Snap2D(V)
    return Vector2.new(SnapN(V.X), SnapN(V.Y))
end

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
            if Ok and typeof(CF) == "CFrame" and typeof(Size) == "Vector3" then
                return CF, Size
            end
        end

        if Character and Character.GetBoundingBox then
            local Ok, CF, Size = pcall(Character.GetBoundingBox, Character)
            if Ok and typeof(CF) == "CFrame" and typeof(Size) == "Vector3" then
                return CF, Size
            end
        end

        return nil, nil
    end

    local function Get2DBoxFrom3DBounds(CF, Size)
        local SX, SY, SZ = Size.X, Size.Y, Size.Z
        local HX, HY, HZ = SX * 0.5, SY * 0.5, SZ * 0.5

        local MinX, MinY = math.huge, math.huge
        local MaxX, MaxY = -math.huge, -math.huge

        local AnyInFront = false
        local MinZ = math.huge

        for IX = -1, 1, 2 do
            local OX = HX * IX
            for IY = -1, 1, 2 do
                local OY = HY * IY
                for IZ = -1, 1, 2 do
                    local CornerWorld = (CF * CFrame.new(OX, OY, HZ * IZ)).Position
                    local P = CurrentCamera:WorldToViewportPoint(CornerWorld)
                    local X, Y, Z = P.X, P.Y, P.Z

                    if Z > 0 then
                        AnyInFront = true
                    end
                    if Z < MinZ then
                        MinZ = Z
                    end

                    if X < MinX then MinX = X end
                    if Y < MinY then MinY = Y end
                    if X > MaxX then MaxX = X end
                    if Y > MaxY then MaxY = Y end
                end
            end
        end

        return MinX, MinY, MaxX, MaxY, AnyInFront, MinZ
    end

    function PlayerESP:CreateDrawingCache()
        local AllDrawings = {}
        local Cfg = EspLibrary.Config

        local Corners = { Lines = {}, Outlines = {} }
        for i = 1, 8 do
            Corners.Outlines[i] = CreateDrawing("Line", {
                Visible = false,
                Thickness = 2,
                Color = Color3.new(0, 0, 0),
                ZIndex = BaseZIndex,
            }, AllDrawings)
            Corners.Lines[i] = CreateDrawing("Line", {
                Visible = false,
                Thickness = 1,
                Color = Color3.new(1, 1, 1),
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
        end

        local FullBox = { Lines = {}, Outlines = {} }
        for i = 1, 4 do
            FullBox.Outlines[i] = CreateDrawing("Line", {
                Visible = false,
                Thickness = 2,
                Color = Color3.new(0, 0, 0),
                ZIndex = BaseZIndex,
            }, AllDrawings)
            FullBox.Lines[i] = CreateDrawing("Line", {
                Visible = false,
                Thickness = 1,
                Color = Color3.new(1, 1, 1),
                ZIndex = BaseZIndex + 1,
            }, AllDrawings)
        end

        local FlagTexts = {}
        for i = 1, 6 do
            FlagTexts[i] = CreateDrawing("Text", {
                Visible = false,
                Center = false,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 1, 1),
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
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 1, 1),
                Transparency = 1,
                Size = Cfg.TextSize,
                Text = self and self.Player and self.Player.DisplayName or "",
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),

            Weapon = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 1, 1),
                Transparency = 1,
                Size = Cfg.TextSize,
                Font = Cfg.Font,
                ZIndex = BaseZIndex + 1,
            }, AllDrawings),

            Distance = CreateDrawing("Text", {
                Visible = false,
                Center = true,
                Outline = true,
                OutlineColor = Color3.new(0, 0, 0),
                Color = Color3.new(1, 1, 1),
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
                Color = Color3.new(0.239215, 0.239215, 0.239215),
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
            table.remove(PlayerESP.DrawingCache, 1)
            Cache.Name.Text = Player.DisplayName
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
        if type(Cache) ~= "table" then return end

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

        self.Drawings.HealthBar.Color = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), HealthPercentage)
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

        if type(BoxSettings) == "table" then
            Enabled = not not BoxSettings.Enabled
            Mode = string.lower(BoxSettings.Mode or "corner")
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
            Left = SnapN(Left)
            Top = SnapN(Top)
            Right = SnapN(Right)
            Bottom = SnapN(Bottom)
        end

        if Mode == "full" then
            for i = 1, 8 do
                CornersLines[i].Visible = false
                CornersOutlines[i].Visible = false
            end

            local P1 = Vector2.new(Left, Top)
            local P2 = Vector2.new(Right, Top)
            local P3 = Vector2.new(Right, Bottom)
            local P4 = Vector2.new(Left, Bottom)

            if EspLibrary.Config.PixelSnap then
                P1 = Snap2D(P1)
                P2 = Snap2D(P2)
                P3 = Snap2D(P3)
                P4 = Snap2D(P4)
            end

            local Seg = {
                {P1, P2},
                {P2, P3},
                {P3, P4},
                {P4, P1},
            }

            for i = 1, 4 do
                local O = FullOutlines[i]
                local L = FullLines[i]
                O.Visible = true
                L.Visible = true
                O.From = Seg[i][1]
                O.To = Seg[i][2]
                L.From = Seg[i][1]
                L.To = Seg[i][2]
            end

            return
        end

        for i = 1, 4 do
            FullLines[i].Visible = false
            FullOutlines[i].Visible = false
        end

        local Cfg = EspLibrary.Config
        local HorizontalLen = math.floor(BoxSize2D.X * Cfg.BoxCornerWidthScale)
        local VerticalLen = math.floor(BoxSize2D.Y * Cfg.BoxCornerHeightScale)

        local P = {
            {Vector2.new(Left, Top), Vector2.new(Left + HorizontalLen, Top)},
            {Vector2.new(Left, Top), Vector2.new(Left, Top + VerticalLen)},

            {Vector2.new(Right - HorizontalLen, Top), Vector2.new(Right, Top)},
            {Vector2.new(Right, Top), Vector2.new(Right, Top + VerticalLen)},

            {Vector2.new(Left, Bottom), Vector2.new(Left + HorizontalLen, Bottom)},
            {Vector2.new(Left, Bottom - VerticalLen), Vector2.new(Left, Bottom)},

            {Vector2.new(Right - HorizontalLen, Bottom), Vector2.new(Right, Bottom)},
            {Vector2.new(Right, Bottom - VerticalLen), Vector2.new(Right, Bottom)},
        }

        for i = 1, 8 do
            local Outline = CornersOutlines[i]
            local Line = CornersLines[i]

            local A = P[i][1]
            local B = P[i][2]

            if EspLibrary.Config.PixelSnap then
                A = Snap2D(A)
                B = Snap2D(B)
            end

            Outline.Visible = true
            Line.Visible = true
            Outline.From = A
            Outline.To = B
            Line.From = A
            Line.To = B
        end
    end

    function PlayerESP:RenderName(Vector2Pos, Offset, Enabled)
        local Name = self.Drawings.Name
        if not Enabled then
            Name.Visible = false
            return
        end
        Name.Visible = true
        Name.Position = Vector2Pos - Vector2.new(0, Offset.Y + Name.Size)
    end

    function PlayerESP:RenderWeapon(Vector2Pos, Offset, Enabled, BottomYOffset)
        local WeaponText = self.Drawings.Weapon
        if not Enabled then
            WeaponText.Visible = false
            return 0
        end
        WeaponText.Visible = true
        WeaponText.Position = Vector2Pos + Vector2.new(0, Offset.Y + BottomYOffset)
        WeaponText.Text = self.Current.Weapon and string.lower(self.Current.Weapon.Name) or "none"
        return EspLibrary.Config.TextSize + 1
    end

    function PlayerESP:RenderDistance(Vector2Pos, Offset, Enabled, DistanceOverride, BottomYOffset)
        local Distance = self.Drawings.Distance
        if not Enabled then
            Distance.Visible = false
            return 0
        end
        local Magnitude = math.round(DistanceOverride or (CurrentCamera.CFrame.Position - self.Current.RootPart.Position).Magnitude)
        Distance.Visible = true
        Distance.Position = Vector2Pos + Vector2.new(0, Offset.Y + BottomYOffset)
        Distance.Text = `[{Magnitude}]`
        return EspLibrary.Config.TextSize + 1
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

        local BasePosition = Vector2Pos - Offset - Vector2.new(5, 0)
        local BaseSize = Vector2.new(3, Offset.Y * 2)

        local HealthLength = (BaseSize.Y - 2) * (self.Current.HealthPercentage or 0)
        local HealthPosition = BasePosition + Vector2.new(1, 1 + (BaseSize.Y - 2 - HealthLength))
        local HealthSize = Vector2.new(1, HealthLength)

        HealthBackground.Position = BasePosition
        HealthBackground.Size = BaseSize

        HealthBar.Position = HealthPosition
        HealthBar.Size = HealthSize
    end
    function PlayerESP:RenderFlags(Center2D, Offset, FlagsSettings)
        local FlagTexts = self.Drawings.FlagTexts
        for i = 1, #FlagTexts do
            FlagTexts[i].Visible = false
        end
        if not FlagsSettings or not FlagsSettings.Enabled then
            return 0
        end
    
        local Items = {}
        if type(FlagsSettings.Builder) == "function" then
            local Ok, Result = pcall(function() return FlagsSettings.Builder(self) end)
            if Ok and type(Result) == "table" then
                Items = Result
            end
        end
    
        local VisibleItems = {}
        local Mode = string.lower(FlagsSettings.Mode or "normal")
        if Mode == "always" then
            for i = 1, #Items do
                VisibleItems[#VisibleItems + 1] = Items[i]
            end
        else
            for i = 1, #Items do
                if Items[i].State then
                    VisibleItems[#VisibleItems + 1] = Items[i]
                end
            end
        end
    
        local Count = math.min(#VisibleItems, #FlagTexts)
        if Count == 0 then
            return 0
        end
    
        local Cfg = EspLibrary.Config
        local BoxTop = Center2D.Y - Offset.Y
        
        local Padding = Cfg.FlagLinePadding
        local MaxRows = 10
        local Rows = math.min(MaxRows, Count)
        local Cols = math.ceil(Count / MaxRows)
    
        local TextSize = Cfg.FlagSize
        local LineHeight = TextSize + Padding
    
        local XStart = Center2D.X + Offset.X + 5
        local YStart = BoxTop
    
        if Cfg.PixelSnap then
            XStart = SnapN(XStart)
            YStart = SnapN(YStart)
        end
    
        local CharWidth = TextSize * 0.6
        local ColGap = TextSize
    
        local ColWidths = {}
        for Col = 1, Cols do
            local MaxLen = 0
            local StartIndex = (Col - 1) * MaxRows + 1
            local EndIndex = math.min(Col * MaxRows, Count)
            for i = StartIndex, EndIndex do
                local Len = #tostring(VisibleItems[i].Text or "")
                if Len > MaxLen then
                    MaxLen = Len
                end
            end
            ColWidths[Col] = math.ceil(MaxLen * CharWidth)
        end
    
        for i = 1, Count do
            local Item = VisibleItems[i]
            local TextObj = FlagTexts[i]
            local State = not not Item.State
    
            local Col = math.floor((i - 1) / MaxRows) + 1
            local Row = (i - 1) % MaxRows
    
            local OffsetX = 0
            for C = 1, Col - 1 do
                OffsetX = OffsetX + ColWidths[C] + ColGap
            end
    
            local PosX = XStart + OffsetX
            local PosY = YStart + Row * LineHeight
    
            if Cfg.PixelSnap then
                PosX = SnapN(PosX)
                PosY = SnapN(PosY)
            end
    
            TextObj.Visible = true
            TextObj.Font = Cfg.Font
            TextObj.Size = TextSize
            TextObj.Outline = true
            TextObj.OutlineColor = Color3.new(0, 0, 0)
            TextObj.Transparency = 1
            TextObj.Text = tostring(Item.Text or "")
            TextObj.Position = Vector2.new(PosX, PosY)
    
            if Mode == "always" then
                TextObj.Color = (State and (Item.ColorTrue or Color3.new(0, 1, 0))) or (Item.ColorFalse or Color3.new(1, 0, 0))
            else
                TextObj.Color = Item.ColorTrue or Color3.new(0, 1, 0)
            end
        end
    
        return (Rows * LineHeight) - Padding
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

        local BoxPos2D = Vector2.new(MinX, MinY)
        local BoxSize2D = Vector2.new(W, H)

        local Center2D = BoxPos2D + (BoxSize2D * 0.5)
        local Offset = BoxSize2D * 0.5

        self:RenderBox(BoxPos2D, BoxSize2D, Settings.Box)
        self:RenderName(Center2D, Offset, Settings.Name)
        self:RenderHealthbar(Center2D, Offset, Settings.Healthbar)

        local BottomYOffset = 0
        local WeaponUsed = self:RenderWeapon(Center2D, Offset, Settings.Weapon, BottomYOffset)
        BottomYOffset = BottomYOffset + WeaponUsed
        self:RenderDistance(Center2D, Offset, Settings.Distance, DistanceOverride, BottomYOffset)

        self:RenderFlags(Center2D, Offset, Settings.Flags)
    end

    EspLibrary.PlayerESP = PlayerESP
end
return EspLibrary, 3
