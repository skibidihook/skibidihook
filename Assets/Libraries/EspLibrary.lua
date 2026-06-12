local CloneRef = cloneref or function(...) return ... end
local Workspace = CloneRef(game:GetService("Workspace"))
local CurrentCamera = CloneRef(Workspace.CurrentCamera)
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint

local DrawingNew    = Drawing.new
local Vector2New    = Vector2.new
local Vector3New    = Vector3.new
local Color3New     = Color3.new
local TableRemove   = table.remove
local TableClear    = table.clear
local MathFloor     = math.floor
local MathRound     = math.round
local MathHuge      = math.huge
local MathMax       = math.max
local MathAbs       = math.abs
local CFrameNew     = CFrame.new
local StringLower   = string.lower
local Type          = type

local ColorBlack      = Color3New(0, 0, 0)
local ColorWhite      = Color3New(1, 1, 1)
local ColorGreen      = Color3New(0, 1, 0)
local ColorRed        = Color3New(1, 0, 0)
local ColorBackground = Color3New(0.239215, 0.239215, 0.239215)

local VisibleItemsBuffer = {}
local LibraryConnections = {}

LibraryConnections[#LibraryConnections + 1] = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local NewCamera = Workspace.CurrentCamera
    if NewCamera then CurrentCamera = CloneRef(NewCamera) end
end)

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

local function DisconnectAll(Connections)
    for Index = 1, #Connections do
        pcall(Connections[Index].Disconnect, Connections[Index])
    end
    TableClear(Connections)
end

local GlobalFont = (getgenv and getgenv().GLOBAL_FONT) or _G.GLOBAL_FONT or 1
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
    local function GetBoundingBoxSafe(Target, _, IsCharacter)
        if not Target then return nil, nil end
        local MinX, MinY, MinZ =  MathHuge,  MathHuge,  MathHuge
        local MaxX, MaxY, MaxZ = -MathHuge, -MathHuge, -MathHuge
        local Found = false
        local Whitelist = IsCharacter and EspLibrary.CharacterWhitelist or nil
        local Children = Target:GetChildren()
        for _ = 1, 2 do
            for Index = 1, #Children do
                local Part = Children[Index]
                if not Part:IsA("BasePart") then continue end
                if Whitelist and not Whitelist[Part.Name] then continue end
                local Position = Part.CFrame.Position
                local Size = Part.Size
                local PX, PY, PZ = Position.X, Position.Y, Position.Z
                local HX, HY, HZ = Size.X * 0.5, Size.Y * 0.5, Size.Z * 0.5
                if PX - HX < MinX then MinX = PX - HX end
                if PY - HY < MinY then MinY = PY - HY end
                if PZ - HZ < MinZ then MinZ = PZ - HZ end
                if PX + HX > MaxX then MaxX = PX + HX end
                if PY + HY > MaxY then MaxY = PY + HY end
                if PZ + HZ > MaxZ then MaxZ = PZ + HZ end
                Found = true
            end
            if Found or not Whitelist then break end
            Whitelist = nil
        end
        if not Found then return nil, nil end
        return CFrameNew((MinX + MaxX) * 0.5, (MinY + MaxY) * 0.5, (MinZ + MaxZ) * 0.5),
            Vector3New(MaxX - MinX, MaxY - MinY, MaxZ - MinZ)
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
                    local X, Y, Z = ProjectPointToScreen(CF:PointToWorldSpace(Vector3New(HX * IX, HY * IY, HZ * IZ)))
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
            return Player.Name or "Entity"
        end
        if EspLibrary.Config.NameMode ~= "Username" and Player.ClassName == "Player" then
            return Player.DisplayName or Player.Name
        end
        return Player.Name
    end

    local function SetLinePair(Outline, Line, FromV, ToV)
        Outline.Visible, Line.Visible = true, true
        Outline.From, Outline.To = FromV, ToV
        Line.From, Line.To = FromV, ToV
    end

    local function RenderCharacterBox(Drawings, BoxPos2D, BoxSize2D, BoxSettings)
        local CornersLines    = Drawings.Corners.Lines
        local CornersOutlines = Drawings.Corners.Outlines
        local FullLines       = Drawings.FullBox.Lines
        local FullOutlines    = Drawings.FullBox.Outlines
        local Enabled, Mode
        if Type(BoxSettings) == "table" then
            Enabled = not not BoxSettings.Enabled
            Mode    = BoxSettings.Mode and StringLower(BoxSettings.Mode) or "corner"
        else
            Enabled = not not BoxSettings
            Mode    = "corner"
        end
        if not Enabled then
            for Index = 1, 8 do
                CornersLines[Index].Visible    = false
                CornersOutlines[Index].Visible = false
            end
            for Index = 1, 4 do
                FullLines[Index].Visible    = false
                FullOutlines[Index].Visible = false
            end
            return
        end
        local Left   = BoxPos2D.X
        local Top    = BoxPos2D.Y
        local Right  = Left + BoxSize2D.X
        local Bottom = Top + BoxSize2D.Y
        local Cfg = EspLibrary.Config
        if Cfg.PixelSnap then
            Left   = MathFloor(Left + 0.5)
            Top    = MathFloor(Top + 0.5)
            Right  = MathFloor(Right + 0.5)
            Bottom = MathFloor(Bottom + 0.5)
        end
        if Mode == "full" then
            for Index = 1, 8 do
                CornersLines[Index].Visible    = false
                CornersOutlines[Index].Visible = false
            end
            local TopLeft     = Vector2New(Left, Top)
            local TopRight    = Vector2New(Right, Top)
            local BottomRight = Vector2New(Right, Bottom)
            local BottomLeft  = Vector2New(Left, Bottom)
            SetLinePair(FullOutlines[1], FullLines[1], TopLeft, TopRight)
            SetLinePair(FullOutlines[2], FullLines[2], TopRight, BottomRight)
            SetLinePair(FullOutlines[3], FullLines[3], BottomRight, BottomLeft)
            SetLinePair(FullOutlines[4], FullLines[4], BottomLeft, TopLeft)
            return
        end
        for Index = 1, 4 do
            FullLines[Index].Visible    = false
            FullOutlines[Index].Visible = false
        end
        local HLen = MathFloor(BoxSize2D.X * Cfg.BoxCornerWidthScale)
        local VLen = MathFloor(BoxSize2D.Y * Cfg.BoxCornerHeightScale)
        SetLinePair(CornersOutlines[1], CornersLines[1], Vector2New(Left, Top),            Vector2New(Left + HLen, Top))
        SetLinePair(CornersOutlines[2], CornersLines[2], Vector2New(Left, Top),            Vector2New(Left, Top + VLen))
        SetLinePair(CornersOutlines[3], CornersLines[3], Vector2New(Right - HLen, Top),    Vector2New(Right, Top))
        SetLinePair(CornersOutlines[4], CornersLines[4], Vector2New(Right, Top),           Vector2New(Right, Top + VLen))
        SetLinePair(CornersOutlines[5], CornersLines[5], Vector2New(Left, Bottom),         Vector2New(Left + HLen, Bottom))
        SetLinePair(CornersOutlines[6], CornersLines[6], Vector2New(Left, Bottom - VLen),  Vector2New(Left, Bottom))
        SetLinePair(CornersOutlines[7], CornersLines[7], Vector2New(Right - HLen, Bottom), Vector2New(Right, Bottom))
        SetLinePair(CornersOutlines[8], CornersLines[8], Vector2New(Right, Bottom - VLen), Vector2New(Right, Bottom))
    end

    local function RenderFlagList(EspInstance, FlagTexts, Center2D, Offset, FlagsSettings)
        for Index = 1, #FlagTexts do
            FlagTexts[Index].Visible = false
        end
        if not FlagsSettings or not FlagsSettings.Enabled then return end
        local Items
        if Type(FlagsSettings.Builder) == "function" then
            local Ok, Result = pcall(FlagsSettings.Builder, EspInstance)
            if Ok and Type(Result) == "table" then Items = Result end
        end
        if not Items then return end
        TableClear(VisibleItemsBuffer)
        local Always = (FlagsSettings.Mode and StringLower(FlagsSettings.Mode) or "normal") == "always"
        for Index = 1, #Items do
            local Item = Items[Index]
            if Item and (Always or Item.State) then
                VisibleItemsBuffer[#VisibleItemsBuffer + 1] = Item
            end
        end
        local Count = #VisibleItemsBuffer
        if Count == 0 then return end
        if Count > #FlagTexts then Count = #FlagTexts end
        local Cfg        = EspLibrary.Config
        local FlagSize   = Cfg.FlagSize
        local FlagFont   = Cfg.Font
        local LineHeight = FlagSize + Cfg.FlagLinePadding
        local PixelSnap  = Cfg.PixelSnap
        local BaseX = Center2D.X + Offset.X + Cfg.FlagXPadding
        local BaseY = Center2D.Y - Offset.Y
        if PixelSnap then BaseX = MathFloor(BaseX + 0.5) end
        for Index = 1, Count do
            local Item    = VisibleItemsBuffer[Index]
            local TextObj = FlagTexts[Index]
            local PosY = BaseY + (Index - 1) * LineHeight
            if PixelSnap then PosY = MathFloor(PosY + 0.5) end
            if TextObj.Font ~= FlagFont then TextObj.Font = FlagFont end
            if TextObj.Size ~= FlagSize then TextObj.Size = FlagSize end
            local NewText = tostring(Item.Text or "")
            if TextObj.Text ~= NewText then TextObj.Text = NewText end
            TextObj.Position = Vector2New(BaseX, PosY)
            if Always then
                TextObj.Color = Item.State and (Item.ColorTrue or ColorGreen) or (Item.ColorFalse or ColorRed)
            else
                TextObj.Color = Item.ColorTrue or ColorGreen
            end
            TextObj.Visible = true
        end
    end

    local function RenderHealthbarPair(HealthBar, HealthBackground, Center2D, Offset, Pct)
        local BasePos = Center2D - Offset - Vector2New(5, 0)
        local BaseSize = Vector2New(3, Offset.Y * 2)
        local HealthLen = (BaseSize.Y - 2) * Pct
        HealthBar.Visible = true
        HealthBackground.Visible = true
        HealthBackground.Position = BasePos
        HealthBackground.Size = BaseSize
        HealthBar.Position = BasePos + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLen))
        HealthBar.Size = Vector2New(1, HealthLen)
    end

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

    function PlayerEsp:CreateDrawingCache()
        local AllDrawings = {}
        local Cfg = EspLibrary.Config
        local Corners = { Lines = {}, Outlines = {} }
        for Index = 1, 8 do
            Corners.Outlines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Corners.Lines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        local FullBox = { Lines = {}, Outlines = {} }
        for Index = 1, 4 do
            FullBox.Outlines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            FullBox.Lines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        local FlagTexts = {}
        for Index = 1, 6 do
            FlagTexts[Index] = CreateDrawing("Text", {
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
            CharacterConnections = {},
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
        for Index = 1, #Conns do
            Conns[Index](Self)
        end
        if Type(Player) == "userdata" then
            local IsPlayerInstance = false
            pcall(function() IsPlayerInstance = Player:IsA("Player") end)
            if IsPlayerInstance then
                Self.Connections[#Self.Connections + 1] = Player.CharacterAdded:Connect(function(...) return Self:CharacterAdded(...) end)
                Self.Connections[#Self.Connections + 1] = Player.CharacterRemoving:Connect(function(...) return Self:CharacterRemoved(...) end)
                if Player.Character then
                    Self:CharacterAdded(Player.Character, true)
                end
            else
                Self:CharacterAdded(Player, true)
                Self.Connections[#Self.Connections + 1] = Player.AncestryChanged:Connect(function(_, Parent)
                    if not Parent then Self:CharacterRemoved() end
                end)
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
        DisconnectAll(Cache.Connections)
        DisconnectAll(Cache.CharacterConnections)
        if Cache.Drawings then
            for Index = 1, #Cache.AllDrawings do
                Cache.AllDrawings[Index].Visible = false
            end
            PlayerEsp.DrawingCache[#PlayerEsp.DrawingCache + 1] = Cache.Drawings
        end
    end

    function PlayerEsp:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        for Index = 1, #self.AllDrawings do
            self.AllDrawings[Index].Visible = false
        end
    end

    function PlayerEsp:SetColor(Color)
        self.Color = Color
        local Drawings = self.Drawings
        if not Drawings then return end
        Drawings.Name.Color = Color
        Drawings.Distance.Color = Color
        Drawings.Weapon.Color = Color
        local CornerLines = Drawings.Corners.Lines
        for Index = 1, 8 do CornerLines[Index].Color = Color end
        local FullLines = Drawings.FullBox.Lines
        for Index = 1, 4 do FullLines[Index].Color = Color end
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
        local CharConns = self.CharacterConnections
        CharConns[#CharConns + 1] = Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            self:HumanoidHealthChanged()
        end)
        if FirstTime then
            local Conns = self.ChildAddedConnections
            local Children = self.Current.Character:GetChildren()
            for Index = 1, #Children do
                for ConnIndex = 1, #Conns do
                    Conns[ConnIndex](self, Children[Index])
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
        for Index = 1, #Conns do
            Conns[Index](self, Child)
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
        for Index = 1, #Conns do
            Conns[Index](self, Child)
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
        DisconnectAll(self.CharacterConnections)
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
        local CharConns = self.CharacterConnections
        CharConns[#CharConns + 1] = Character:GetPropertyChangedSignal("PrimaryPart"):Connect(function() self:PrimaryPartAdded() end)
        CharConns[#CharConns + 1] = Character.ChildAdded:Connect(function(...) return self:ChildAdded(...) end)
        CharConns[#CharConns + 1] = Character.ChildRemoved:Connect(function(...) return self:ChildRemoved(...) end)
        if self.Current.Humanoid then
            self:SetupHumanoid(self.Current.Humanoid, FirstTime)
        end
    end

    function PlayerEsp:CharacterRemoved()
        DisconnectAll(self.CharacterConnections)
        self.Current = nil
        self.Hidden = true
        for Index = 1, #self.AllDrawings do
            self.AllDrawings[Index].Visible = false
        end
    end

    function PlayerEsp:RenderBox(BoxPos2D, BoxSize2D, BoxSettings)
        RenderCharacterBox(self.Drawings, BoxPos2D, BoxSize2D, BoxSettings)
    end

    function PlayerEsp:RenderName(Center2D, Offset, NameSettings)
        local NameText = self.Drawings.Name
        local Enabled
        if Type(NameSettings) == "table" then
            Enabled = not not NameSettings.Enabled
        else
            Enabled = not not NameSettings
        end
        if not Enabled then
            NameText.Visible = false
            return
        end
        local NewName = GetPlayerName(self.Player)
        if NameText.Text ~= NewName then NameText.Text = NewName end
        NameText.Position = Center2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
        NameText.Visible  = true
    end

    function PlayerEsp:RenderWeapon(Center2D, Offset, Enabled, BottomYOffset)
        local WeaponText = self.Drawings.Weapon
        if not Enabled then
            WeaponText.Visible = false
            return 0
        end
        local NewText = self.Current.Weapon and StringLower(self.Current.Weapon.Name) or "none"
        if WeaponText.Text ~= NewText then WeaponText.Text = NewText end
        WeaponText.Position = Center2D + Vector2New(0, Offset.Y + BottomYOffset)
        WeaponText.Visible = true
        return EspLibrary.Config.TextSize + 1
    end

    function PlayerEsp:RenderDistance(Center2D, Offset, Enabled, BottomYOffset, Distance)
        local DistanceText = self.Drawings.Distance
        if not Enabled or not Distance then
            DistanceText.Visible = false
            return 0
        end
        local Cfg = EspLibrary.Config
        local Magnitude = MathRound(Distance)
        local PosX = Center2D.X
        local PosY = Center2D.Y + Offset.Y + BottomYOffset
        if Cfg.PixelSnap then
            PosX = MathFloor(PosX + 0.5)
            PosY = MathFloor(PosY + 0.5)
        end
        local NewText = `[{Magnitude}]`
        if DistanceText.Text ~= NewText then DistanceText.Text = NewText end
        DistanceText.Position = Vector2New(PosX, PosY)
        DistanceText.Visible = true
        return Cfg.TextSize + 1
    end

    function PlayerEsp:RenderHealthbar(Center2D, Offset, Enabled)
        if not Enabled or not (self.Current and self.Current.Humanoid) then
            self.Drawings.HealthBar.Visible = false
            self.Drawings.HealthBackground.Visible = false
            return
        end
        RenderHealthbarPair(self.Drawings.HealthBar, self.Drawings.HealthBackground,
            Center2D, Offset, self.Current.HealthPercentage or 0)
    end

    function PlayerEsp:RenderFlags(Center2D, Offset, FlagsSettings)
        RenderFlagList(self, self.Drawings.FlagTexts, Center2D, Offset, FlagsSettings)
    end

    function PlayerEsp:Loop(Settings, DistanceOverride)
        if not EspLibrary.Enabled then return self:HideDrawings() end
        local Current = self.Current
        if not Current then return self:HideDrawings() end
        local Character = Current.Character
        if not Character then return self:HideDrawings() end
        local CF, Size3D = GetBoundingBoxSafe(Character, Current.Humanoid, true)
        if not Size3D then return self:HideDrawings() end
        local GoalPos = CF.Position
        local ScreenPos, OnScreen = WorldToViewportPoint(CurrentCamera, GoalPos)
        if not OnScreen then return self:HideDrawings() end
        self.Hidden = false
        local Center2D = Vector2New(ScreenPos.X, ScreenPos.Y)
        local CameraCF = CurrentCamera.CFrame
        local BoxCF = CFrameNew(GoalPos, GoalPos + CameraCF.LookVector)
        local HX, HY = -Size3D.X * 0.5, Size3D.Y * 0.5
        local TopRight3D    = BoxCF:PointToWorldSpace(Vector3New(HX, HY, 0))
        local BottomRight3D = BoxCF:PointToWorldSpace(Vector3New(HX, -HY, 0))
        local TopRight2D    = WorldToViewportPoint(CurrentCamera, TopRight3D)
        local BottomRight2D = WorldToViewportPoint(CurrentCamera, BottomRight3D)
        local Offset = Vector2New(
            MathMax(MathAbs(TopRight2D.X - Center2D.X), MathAbs(BottomRight2D.X - Center2D.X)),
            MathMax(MathAbs(Center2D.Y - TopRight2D.Y), MathAbs(BottomRight2D.Y - Center2D.Y))
        )
        self:RenderBox(Center2D - Offset, Offset * 2, Settings.Box)
        self:RenderName(Center2D, Offset, Settings.Name)
        self:RenderHealthbar(Center2D, Offset, Settings.Healthbar)
        local BottomY = self:RenderWeapon(Center2D, Offset, Settings.Weapon, 0)
        BottomY = BottomY + self:RenderDistance(Center2D, Offset, Settings.Distance, BottomY,
            DistanceOverride or (CameraCF.Position - GoalPos).Magnitude)
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
            Corners = { Lines = {}, Outlines = {} },
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
        for Index = 1, 4 do
            Drawings.FullBox.Outlines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Drawings.FullBox.Lines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        for Index = 1, 8 do
            Drawings.Corners.Outlines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Drawings.Corners.Lines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
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
            for Index = 1, 4 do Cache.FullBox.Lines[Index].Color = Self.Color end
            for Index = 1, 8 do Cache.Corners.Lines[Index].Color = Self.Color end
            Self.AllDrawings = Cache.All
            Self.Drawings = Cache
        else
            Self:CreateDrawingCache()
        end
        local Conns = EntityEsp.DrawingAddedConnections
        for Index = 1, #Conns do Conns[Index](Self) end
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
        DisconnectAll(Cache.Connections)
        if Cache.Drawings then
            for Index = 1, #Cache.AllDrawings do
                Cache.AllDrawings[Index].Visible = false
            end
            EntityEsp.DrawingCache[#EntityEsp.DrawingCache + 1] = Cache.Drawings
        end
    end

    function EntityEsp:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        for Index = 1, #self.AllDrawings do
            self.AllDrawings[Index].Visible = false
        end
    end

    function EntityEsp:SetColor(Color)
        self.Color = Color
        local Drawings = self.Drawings
        if not Drawings then return end
        Drawings.Name.Color = Color
        Drawings.Distance.Color = Color
        for Index = 1, 4 do Drawings.FullBox.Lines[Index].Color = Color end
        for Index = 1, 8 do Drawings.Corners.Lines[Index].Color = Color end
    end

    function EntityEsp:Loop(Settings, DistanceOverride)
        if not EspLibrary.Enabled then return self:HideDrawings() end
        local Entity = self.Entity
        if not Entity or not Entity.Parent then return EntityEsp.Remove(Entity) end
        local BoxCF, BoxSize3
        if Entity:IsA("Model") then
            BoxCF, BoxSize3 = Entity:GetBoundingBox()
        elseif Entity:IsA("BasePart") then
            BoxCF, BoxSize3 = Entity.CFrame, Entity.Size
        else
            return self:HideDrawings()
        end
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
            W = MaxX - MinX
            H = MaxY - MinY
        end
        local Center2D = Vector2New(MinX + W * 0.5, MinY + H * 0.5)
        local Offset = Vector2New(W * 0.5, H * 0.5)
        local Drawings = self.Drawings
        local BoxSettings = Settings.Box
        local BoxEnabled, BoxMode
        if Type(BoxSettings) == "table" then
            BoxEnabled = not not BoxSettings.Enabled
            BoxMode    = BoxSettings.Mode and StringLower(BoxSettings.Mode) or "full"
        else
            BoxEnabled = not not BoxSettings
            BoxMode    = "full"
        end
        local FullLines      = Drawings.FullBox.Lines
        local FullOutlines   = Drawings.FullBox.Outlines
        local CornerLines    = Drawings.Corners.Lines
        local CornerOutlines = Drawings.Corners.Outlines
        if BoxEnabled and BoxMode == "full" then
            local TopLeft     = Vector2New(MinX, MinY)
            local TopRight    = Vector2New(MaxX, MinY)
            local BottomRight = Vector2New(MaxX, MaxY)
            local BottomLeft  = Vector2New(MinX, MaxY)
            SetLinePair(FullOutlines[1], FullLines[1], TopLeft, TopRight)
            SetLinePair(FullOutlines[2], FullLines[2], TopRight, BottomRight)
            SetLinePair(FullOutlines[3], FullLines[3], BottomRight, BottomLeft)
            SetLinePair(FullOutlines[4], FullLines[4], BottomLeft, TopLeft)
        else
            for Index = 1, 4 do
                FullOutlines[Index].Visible = false
                FullLines[Index].Visible = false
            end
        end
        if BoxEnabled and BoxMode == "corner" then
            local Cfg = EspLibrary.Config
            local HLen = MathFloor(W * Cfg.BoxCornerWidthScale)
            local VLen = MathFloor(H * Cfg.BoxCornerHeightScale)
            SetLinePair(CornerOutlines[1], CornerLines[1], Vector2New(MinX, MinY),        Vector2New(MinX + HLen, MinY))
            SetLinePair(CornerOutlines[2], CornerLines[2], Vector2New(MinX, MinY),        Vector2New(MinX, MinY + VLen))
            SetLinePair(CornerOutlines[3], CornerLines[3], Vector2New(MaxX, MinY),        Vector2New(MaxX - HLen, MinY))
            SetLinePair(CornerOutlines[4], CornerLines[4], Vector2New(MaxX, MinY),        Vector2New(MaxX, MinY + VLen))
            SetLinePair(CornerOutlines[5], CornerLines[5], Vector2New(MinX, MaxY),        Vector2New(MinX + HLen, MaxY))
            SetLinePair(CornerOutlines[6], CornerLines[6], Vector2New(MinX, MaxY),        Vector2New(MinX, MaxY - VLen))
            SetLinePair(CornerOutlines[7], CornerLines[7], Vector2New(MaxX, MaxY),        Vector2New(MaxX - HLen, MaxY))
            SetLinePair(CornerOutlines[8], CornerLines[8], Vector2New(MaxX, MaxY),        Vector2New(MaxX, MaxY - VLen))
        else
            for Index = 1, 8 do
                CornerLines[Index].Visible = false
                CornerOutlines[Index].Visible = false
            end
        end
        if Settings.Name then
            Drawings.Name.Position = Center2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
            Drawings.Name.Visible = true
        else
            Drawings.Name.Visible = false
        end
        if Settings.Distance then
            local Magnitude = MathRound(DistanceOverride or (CurrentCamera.CFrame.Position - BoxCF.Position).Magnitude)
            local NewText = `[{Magnitude}]`
            if Drawings.Distance.Text ~= NewText then Drawings.Distance.Text = NewText end
            Drawings.Distance.Position = Center2D + Vector2New(0, Offset.Y)
            Drawings.Distance.Visible = true
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
        for Index = 1, 6 do
            Drawings.FlagTexts[Index] = CreateDrawing("Text", {
                Visible = false, Center = false, Outline = true,
                OutlineColor = ColorBlack, Color = ColorWhite,
                Transparency = 1, Size = Cfg.FlagSize, Text = "",
                Font = Cfg.Font, ZIndex = BaseZIndex + 1,
            }, AllDrawings)
        end
        for Index = 1, 4 do
            Drawings.FullBox.Outlines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Drawings.FullBox.Lines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
        end
        for Index = 1, 8 do
            Drawings.Corners.Outlines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
            Drawings.Corners.Lines[Index] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
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
            for Index = 1, 4 do Cache.FullBox.Lines[Index].Color = Self.Color end
            for Index = 1, 8 do Cache.Corners.Lines[Index].Color = Self.Color end
            Self.AllDrawings = Cache.All
            Self.Drawings = Cache
        else
            Self:CreateDrawingCache()
        end
        local Conns = NpcEsp.DrawingAddedConnections
        for Index = 1, #Conns do Conns[Index](Self) end
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
        DisconnectAll(Cache.Connections)
        if Cache.Drawings then
            for Index = 1, #Cache.AllDrawings do
                Cache.AllDrawings[Index].Visible = false
            end
            NpcEsp.DrawingCache[#NpcEsp.DrawingCache + 1] = Cache.Drawings
        end
    end

    function NpcEsp:HideDrawings()
        if self.Hidden then return end
        self.Hidden = true
        for Index = 1, #self.AllDrawings do
            self.AllDrawings[Index].Visible = false
        end
    end

    function NpcEsp:SetColor(Color)
        self.Color = Color
        local Drawings = self.Drawings
        if not Drawings then return end
        Drawings.Name.Color = Color
        Drawings.Distance.Color = Color
        for Index = 1, 4 do Drawings.FullBox.Lines[Index].Color = Color end
        for Index = 1, 8 do Drawings.Corners.Lines[Index].Color = Color end
    end

    function NpcEsp:RenderBox(BoxPos2D, BoxSize2D, BoxSettings)
        RenderCharacterBox(self.Drawings, BoxPos2D, BoxSize2D, BoxSettings)
    end

    function NpcEsp:RenderName(Center2D, Offset, NameSettings)
        local NameText = self.Drawings.Name
        local Enabled
        if Type(NameSettings) == "table" then
            Enabled = not not NameSettings.Enabled
        else
            Enabled = not not NameSettings
        end
        if not Enabled then
            NameText.Visible = false
            return
        end
        local NewName = self.Name or "NPC"
        if NameText.Text ~= NewName then NameText.Text = NewName end
        NameText.Position = Center2D - Vector2New(0, Offset.Y + EspLibrary.Config.TextSize)
        NameText.Visible  = true
    end

    function NpcEsp:RenderDistance(Center2D, Offset, Enabled, BottomYOffset, Distance)
        local DistanceText = self.Drawings.Distance
        if not Enabled or not Distance then
            DistanceText.Visible = false
            return 0
        end
        local Magnitude = MathRound(Distance)
        local NewText = `[{Magnitude}]`
        if DistanceText.Text ~= NewText then DistanceText.Text = NewText end
        DistanceText.Position = Center2D + Vector2New(0, Offset.Y + BottomYOffset)
        DistanceText.Visible = true
        return EspLibrary.Config.TextSize + 1
    end

    function NpcEsp:RenderFlags(Center2D, Offset, FlagsSettings)
        RenderFlagList(self, self.Drawings.FlagTexts, Center2D, Offset, FlagsSettings)
    end

    function NpcEsp:Loop(Settings, DistanceOverride)
        if not EspLibrary.Enabled then return self:HideDrawings() end
        local Model = self.Model
        if not Model or not Model.Parent then return NpcEsp.Remove(Model) end
        local CF, Size3D = GetBoundingBoxSafe(Model, self.Humanoid, true)
        if not CF or not Size3D then return self:HideDrawings() end
        local GoalPos = CF.Position
        local ScreenPos, OnScreen = WorldToViewportPoint(CurrentCamera, GoalPos)
        if not OnScreen then return self:HideDrawings() end
        self.Hidden = false
        local Center2D = Vector2New(ScreenPos.X, ScreenPos.Y)
        local CameraCF = CurrentCamera.CFrame
        local BoxCF = CFrameNew(GoalPos, GoalPos + CameraCF.LookVector)
        local HX, HY = -Size3D.X * 0.5, Size3D.Y * 0.5
        local TopRight3D    = BoxCF:PointToWorldSpace(Vector3New(HX, HY, 0))
        local BottomRight3D = BoxCF:PointToWorldSpace(Vector3New(HX, -HY, 0))
        local TopRight2D    = WorldToViewportPoint(CurrentCamera, TopRight3D)
        local BottomRight2D = WorldToViewportPoint(CurrentCamera, BottomRight3D)
        local Offset = Vector2New(
            MathMax(MathAbs(TopRight2D.X - Center2D.X), MathAbs(BottomRight2D.X - Center2D.X)),
            MathMax(MathAbs(Center2D.Y - TopRight2D.Y), MathAbs(BottomRight2D.Y - Center2D.Y))
        )
        self:RenderBox(Center2D - Offset, Offset * 2, Settings.Box)
        self:RenderName(Center2D, Offset, Settings.Name)
        self:RenderDistance(Center2D, Offset, Settings.Distance, 0,
            DistanceOverride or (CameraCF.Position - GoalPos).Magnitude)
        self:RenderFlags(Center2D, Offset, Settings.Flags)
        if Settings.Healthbar and self.Humanoid then
            local Drawings = self.Drawings
            local Pct = self.HealthPercentage or 0
            RenderHealthbarPair(Drawings.HealthBar, Drawings.HealthBackground, Center2D, Offset, Pct)
            Drawings.HealthBar.Color = ColorRed:Lerp(ColorGreen, Pct)
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
        DisconnectAll(LibraryConnections)
        local function ClearCache(Cache)
            for Index = 1, #Cache do
                for _, DrawingObject in next, Cache[Index].All do
                    DrawingObject:Remove()
                end
            end
            TableClear(Cache)
        end
        ClearCache(PlayerEsp.DrawingCache)
        ClearCache(EntityEsp.DrawingCache)
        ClearCache(NpcEsp.DrawingCache)
    end
end

return EspLibrary, 3
