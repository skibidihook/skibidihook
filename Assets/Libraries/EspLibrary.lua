local CloneRef = cloneref or function(...) return ... end
local Workspace = CloneRef(game:GetService("Workspace"))
local CurrentCamera = Workspace.CurrentCamera
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint

local DrawingNew = Drawing.new
local Vector2New = Vector2.new
local Vector3New = Vector3.new
local Color3New = Color3.new
local MathFloor = math.floor
local MathClamp = math.clamp
local MathRound = math.round
local MathHuge = math.huge
local MathMin = math.min
local MathMax = math.max
local CFrameNew = CFrame.new
local TableRemove = table.remove

local EnumHumanoidRigTypeR15 = Enum.HumanoidRigType.R15

local ColorBlack = Color3New(0, 0, 0)
local ColorWhite = Color3New(1, 1, 1)
local ColorGreen = Color3New(0, 1, 0)
local ColorRed = Color3New(1, 0, 0)
local ColorBackground = Color3New(0.239215, 0.239215, 0.239215)

local VisibleItemsBuffer = {}

local function CreateDrawing(DrawingType, Properties, ...)
	local DrawingObject = DrawingNew(DrawingType)
	for Key, Value in next, Properties do
		DrawingObject[Key] = Value
	end
	for i = 1, select("#", ...) do
		local T = select(i, ...)
		T[#T + 1] = DrawingObject
	end
	return DrawingObject
end

local GlobalFont = (getgenv and getgenv().GLOBAL_FONT) or _G.GLOBAL_FONT or 1
local GlobalSize = (getgenv and getgenv().GLOBAL_SIZE) or _G.GLOBAL_SIZE or 13
local BaseZIndex = 1

local EspLibrary = {}
EspLibrary.Enabled = true
EspLibrary.Config = {
	Font = GlobalFont,
	TextSize = GlobalSize,
	FlagSize = MathClamp(GlobalSize - 2, 11, 13),
	FlagLinePadding = 2,
	FlagXPadding = 6,
	BoxCornerWidthScale = 0.25,
	BoxCornerHeightScale = 0.25,
	PixelSnap = true,
	NameMode = "Username",
	HeadDotRadius = 4,
}

local function GetBoundingBoxSafe(Character, _Humanoid)
	local Whitelist = EspLibrary.CharacterWhitelist
	local Min = Vector3New(MathHuge, MathHuge, MathHuge)
	local Max = Vector3New(-MathHuge, -MathHuge, -MathHuge)
	local Found = false
	local Children = Character:GetChildren()
	for i = 1, #Children do
		local Part = Children[i]
		if Part:IsA("BasePart") and (not Whitelist or Whitelist[Part.Name]) then
			local P = Part.Position
			local H = Part.Size * 0.5
			Min = Vector3New(MathMin(Min.X, P.X - H.X), MathMin(Min.Y, P.Y - H.Y), MathMin(Min.Z, P.Z - H.Z))
			Max = Vector3New(MathMax(Max.X, P.X + H.X), MathMax(Max.Y, P.Y + H.Y), MathMax(Max.Z, P.Z + H.Z))
			Found = true
		end
	end
	if not Found then return nil, nil end
	local Center = (Min + Max) * 0.5
	return CFrameNew(Center), Max - Min
end

local function Get2DBoxFrom3DBounds(CF, Size)
	local HX, HY, HZ = Size.X * 0.5, Size.Y * 0.5, Size.Z * 0.5
	local MinX, MinY = MathHuge, MathHuge
	local MaxX, MaxY = -MathHuge, -MathHuge
	local AnyInFront = false
	for IX = -1, 1, 2 do
		for IY = -1, 1, 2 do
			for IZ = -1, 1, 2 do
				local ScreenPos = WorldToViewportPoint(CurrentCamera, CF * Vector3New(HX * IX, HY * IY, HZ * IZ))
				if ScreenPos.Z > 0 then
					AnyInFront = true
					local X, Y = ScreenPos.X, ScreenPos.Y
					if X < MinX then MinX = X end
					if Y < MinY then MinY = Y end
					if X > MaxX then MaxX = X end
					if Y > MaxY then MaxY = Y end
				end
			end
		end
	end
	return MinX, MinY, MaxX, MaxY, AnyInFront
end

local function GetPlayerName(Player)
	if type(Player) == "table" then return Player.Name or "" end
	return EspLibrary.Config.NameMode == "Username" and Player.Name or Player.DisplayName
end

local function SetLine(O, L, A, B)
	O.Visible, L.Visible = true, true
	O.From, O.To = A, B
	L.From, L.To = A, B
end

local function SharedRenderBox(Drawings, BoxPos2D, BoxSize2D, BoxSettings)
	local Corners = Drawings.Corners
	local FullBox = Drawings.FullBox
	local CornersLines = Corners.Lines
	local CornersOutlines = Corners.Outlines
	local FullLines = FullBox.Lines
	local FullOutlines = FullBox.Outlines

	local Enabled, Mode
	if type(BoxSettings) == "table" then
		Enabled = not not BoxSettings.Enabled
		Mode = BoxSettings.Mode and string.lower(BoxSettings.Mode) or "corner"
	else
		Enabled = not not BoxSettings
		Mode = "corner"
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

	if Mode == "full" then
		for i = 1, 8 do
			CornersLines[i].Visible = false
			CornersOutlines[i].Visible = false
		end
		local P1, P2 = Vector2New(Left, Top), Vector2New(Right, Top)
		local P3, P4 = Vector2New(Right, Bottom), Vector2New(Left, Bottom)
		SetLine(FullOutlines[1], FullLines[1], P1, P2)
		SetLine(FullOutlines[2], FullLines[2], P2, P3)
		SetLine(FullOutlines[3], FullLines[3], P3, P4)
		SetLine(FullOutlines[4], FullLines[4], P4, P1)
		return
	end

	for i = 1, 4 do
		FullLines[i].Visible = false
		FullOutlines[i].Visible = false
	end

	local Cfg = EspLibrary.Config
	local HLen = MathFloor(BoxSize2D.X * Cfg.BoxCornerWidthScale)
	local VLen = MathFloor(BoxSize2D.Y * Cfg.BoxCornerHeightScale)

	local TL = Vector2New(Left, Top)
	local TR = Vector2New(Right, Top)
	local BL = Vector2New(Left, Bottom)
	local BR = Vector2New(Right, Bottom)

	SetLine(CornersOutlines[1], CornersLines[1], TL, Vector2New(Left + HLen, Top))
	SetLine(CornersOutlines[2], CornersLines[2], TL, Vector2New(Left, Top + VLen))
	SetLine(CornersOutlines[3], CornersLines[3], Vector2New(Right - HLen, Top), TR)
	SetLine(CornersOutlines[4], CornersLines[4], TR, Vector2New(Right, Top + VLen))
	SetLine(CornersOutlines[5], CornersLines[5], BL, Vector2New(Left + HLen, Bottom))
	SetLine(CornersOutlines[6], CornersLines[6], Vector2New(Left, Bottom - VLen), BL)
	SetLine(CornersOutlines[7], CornersLines[7], Vector2New(Right - HLen, Bottom), BR)
	SetLine(CornersOutlines[8], CornersLines[8], Vector2New(Right, Bottom - VLen), BR)
end

local function SharedRenderFlags(FlagTexts, Center2D, Offset, FlagsSettings, BottomYOffset, EspSelf)
	for i = 1, #FlagTexts do
		FlagTexts[i].Visible = false
	end
	if not FlagsSettings or not FlagsSettings.Enabled then return 0 end

	table.clear(VisibleItemsBuffer)
	if type(FlagsSettings.Builder) == "function" then
		local Ok, Result = pcall(FlagsSettings.Builder, EspSelf)
		if Ok and type(Result) == "table" then
			local AlwaysMode = FlagsSettings.Mode and string.lower(FlagsSettings.Mode) == "always"
			for i = 1, #Result do
				local Item = Result[i]
				if AlwaysMode or (Item and Item.State) then
					VisibleItemsBuffer[#VisibleItemsBuffer + 1] = Item
				end
			end
		end
	end

	local Count = MathMin(#VisibleItemsBuffer, #FlagTexts)
	if Count == 0 then return 0 end

	local Cfg = EspLibrary.Config
	local AlwaysMode = FlagsSettings.Mode and string.lower(FlagsSettings.Mode) == "always"
	local TextSize = Cfg.TextSize
	local LineHeight = TextSize + 1

	for i = 1, Count do
		local Item = VisibleItemsBuffer[i]
		local TextObj = FlagTexts[i]
		local PosX = Center2D.X
		local PosY = Center2D.Y + Offset.Y + BottomYOffset + (i - 1) * LineHeight
		if Cfg.PixelSnap then
			PosX = MathFloor(PosX + 0.5)
			PosY = MathFloor(PosY + 0.5)
		end
		TextObj.Visible = true
		TextObj.Center = true
		TextObj.Font = Cfg.Font
		TextObj.Size = TextSize
		TextObj.Outline = true
		TextObj.OutlineColor = ColorBlack
		TextObj.Transparency = 1
		TextObj.Text = tostring(Item and Item.Text or "")
		TextObj.Position = Vector2New(PosX, PosY)
		if AlwaysMode then
			TextObj.Color = (Item and Item.State) and ((Item and Item.ColorTrue) or ColorGreen) or ((Item and Item.ColorFalse) or ColorRed)
		else
			TextObj.Color = (Item and Item.ColorTrue) or ColorGreen
		end
	end
	return Count * LineHeight
end

do
	local PlayerEsp = {
		PlayerCache = {},
		DrawingCache = {},
		ChildAddedConnections = {},
		ChildRemovedConnections = {},
		DrawingAddedConnections = {},
	}
	PlayerEsp.__index = PlayerEsp

	function PlayerEsp.OnChildAdded(Callback)
		PlayerEsp.ChildAddedConnections[#PlayerEsp.ChildAddedConnections + 1] = Callback
	end
	function PlayerEsp.OnChildRemoved(Callback)
		PlayerEsp.ChildRemovedConnections[#PlayerEsp.ChildRemovedConnections + 1] = Callback
	end
	function PlayerEsp.OnDrawingAdded(Callback)
		PlayerEsp.DrawingAddedConnections[#PlayerEsp.DrawingAddedConnections + 1] = Callback
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
				Visible = false, Center = false, Outline = true, OutlineColor = ColorBlack,
				Color = ColorWhite, Transparency = 1, Size = Cfg.FlagSize, Text = "", Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings)
		end
		local Drawings = {
			Corners = Corners,
			FullBox = FullBox,
			FlagTexts = FlagTexts,
			Name = CreateDrawing("Text", {
				Visible = false, Center = true, Outline = true, OutlineColor = ColorBlack,
				Color = ColorWhite, Transparency = 1, Size = Cfg.TextSize,
				Text = self and self.Player and GetPlayerName(self.Player) or "",
				Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
			Weapon = CreateDrawing("Text", {
				Visible = false, Center = true, Outline = true, OutlineColor = ColorBlack,
				Color = ColorWhite, Transparency = 1, Size = Cfg.TextSize, Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
			Distance = CreateDrawing("Text", {
				Visible = false, Center = true, Outline = true, OutlineColor = ColorBlack,
				Color = ColorWhite, Transparency = 1, Size = Cfg.TextSize, Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
			HealthBar = CreateDrawing("Square", {
				Visible = false, Thickness = 1, Filled = true, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
			HealthBackground = CreateDrawing("Square", {
				Visible = false, Color = ColorBackground, Transparency = 0.7, Thickness = 1, Filled = true, ZIndex = BaseZIndex,
			}, AllDrawings),
			HeadDot = CreateDrawing("Circle", {
				Visible = false, Radius = 4, Thickness = 1, Filled = false, NumSides = 16, Color = ColorWhite, ZIndex = BaseZIndex + 2,
			}, AllDrawings),
			HeadDotOutline = CreateDrawing("Circle", {
				Visible = false, Radius = 5, Thickness = 1, Filled = false, NumSides = 16, Color = ColorBlack, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
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
		for i = 1, #PlayerEsp.DrawingAddedConnections do
			PlayerEsp.DrawingAddedConnections[i](Self)
		end
		if typeof(Player) == "Instance" then
			Self.Connections[#Self.Connections + 1] = Player.CharacterAdded:Connect(function(...) return Self:CharacterAdded(...) end)
			Self.Connections[#Self.Connections + 1] = Player.CharacterRemoving:Connect(function(...) return Self:CharacterRemoved(...) end)
			if Player.Character then Self:CharacterAdded(Player.Character, true) end
		elseif type(Player) == "table" then
			if Player.CharacterAdded then
				Self.Connections[#Self.Connections + 1] = Player.CharacterAdded:Connect(function(...) return Self:CharacterAdded(...) end)
			end
			if Player.CharacterRemoving then
				Self.Connections[#Self.Connections + 1] = Player.CharacterRemoving:Connect(function(...) return Self:CharacterRemoved(...) end)
			end
			local Character = Player.Character or Player.model or Player.Model
			if Character then Self:CharacterAdded(Character, true) end
		end
		PlayerEsp.PlayerCache[Player] = Self
		return Self
	end

	PlayerEsp.Remove = function(Player)
		local Cache = PlayerEsp.PlayerCache[Player]
		if type(Cache) ~= "table" then return end
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
		local Pct = MaxHealth > 0 and (Health / MaxHealth) or 0
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
			local Children = self.Current.Character:GetChildren()
			for i = 1, #Children do
				local Child = Children[i]
				for j = 1, #self.ChildAddedConnections do
					self.ChildAddedConnections[j](self, Child)
				end
			end
		end
	end

	function PlayerEsp:ChildAdded(Child)
		if Child.ClassName == "Humanoid" then
			self.Current.Humanoid = Child
			self:SetupHumanoid(Child)
		end
		for i = 1, #self.ChildAddedConnections do
			self.ChildAddedConnections[i](self, Child)
		end
	end

	function PlayerEsp:ChildRemoved(Child)
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

	function PlayerEsp:PrimaryPartAdded()
		local Character = self.Current and self.Current.Character
		if not Character then return end
		local PrimaryPart = Character.PrimaryPart
		if PrimaryPart then self.Current.RootPart = PrimaryPart end
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

	function PlayerEsp:RenderName(Center2D, Offset, Enabled)
		local Name = self.Drawings.Name
		if not Enabled then
			Name.Visible = false
			return
		end
		local Cfg = EspLibrary.Config
		local PosX = Center2D.X
		local PosY = Center2D.Y - Offset.Y - Cfg.TextSize
		if Cfg.PixelSnap then
			PosX = MathFloor(PosX + 0.5)
			PosY = MathFloor(PosY + 0.5)
		end
		Name.Visible = true
		Name.Text = GetPlayerName(self.Player)
		Name.Position = Vector2New(PosX, PosY)
	end

	function PlayerEsp:RenderWeapon(Center2D, Offset, Enabled, BottomYOffset)
		local WeaponText = self.Drawings.Weapon
		if not Enabled then
			WeaponText.Visible = false
			return 0
		end
		local Cfg = EspLibrary.Config
		local PosX = Center2D.X
		local PosY = Center2D.Y + Offset.Y + BottomYOffset
		if Cfg.PixelSnap then
			PosX = MathFloor(PosX + 0.5)
			PosY = MathFloor(PosY + 0.5)
		end
		WeaponText.Visible = true
		WeaponText.Position = Vector2New(PosX, PosY)
		WeaponText.Text = self.Current.Weapon and string.lower(self.Current.Weapon.Name) or "none"
		return Cfg.TextSize + 1
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
		DistanceText.Center = true
		DistanceText.Size = Cfg.TextSize
		DistanceText.Font = Cfg.Font
		DistanceText.Position = Vector2New(PosX, PosY)
		DistanceText.Text = `[{Magnitude}]`
		return Cfg.TextSize + 1
	end

	function PlayerEsp:RenderHealthbar(Center2D, Offset, Enabled)
		local HealthBar = self.Drawings.HealthBar
		local HealthBackground = self.Drawings.HealthBackground
		if not Enabled then
			HealthBar.Visible = false
			HealthBackground.Visible = false
			return
		end
		local BasePos = Center2D - Offset - Vector2New(5, 0)
		local BaseSize = Vector2New(3, Offset.Y * 2)
		local Pct = self.Current.HealthPercentage or 0
		local HealthLen = (BaseSize.Y - 2) * Pct
		HealthBar.Visible = true
		HealthBackground.Visible = true
		HealthBackground.Position = BasePos
		HealthBackground.Size = BaseSize
		HealthBar.Position = BasePos + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLen))
		HealthBar.Size = Vector2New(1, HealthLen)
	end

	function PlayerEsp:RenderHeadDot(Character, Enabled)
		local HeadDot = self.Drawings.HeadDot
		local HeadDotOutline = self.Drawings.HeadDotOutline
		if not Enabled then
			HeadDot.Visible = false
			HeadDotOutline.Visible = false
			return
		end
		local Head = Character:FindFirstChild("Head")
		if not Head then
			HeadDot.Visible = false
			HeadDotOutline.Visible = false
			return
		end
		local ScreenPos, OnScreen = WorldToViewportPoint(CurrentCamera, Head.Position)
		if not OnScreen or ScreenPos.Z <= 0 then
			HeadDot.Visible = false
			HeadDotOutline.Visible = false
			return
		end
		local Pos = Vector2New(ScreenPos.X, ScreenPos.Y)
		local Radius = EspLibrary.Config.HeadDotRadius
		HeadDot.Visible = true
		HeadDot.Position = Pos
		HeadDot.Radius = Radius
		HeadDotOutline.Visible = true
		HeadDotOutline.Position = Pos
		HeadDotOutline.Radius = Radius + 1
	end

	function PlayerEsp:Loop(Settings, DistanceOverride)
		if not EspLibrary.Enabled then return self:HideDrawings() end
		local Current = self.Current
		if not Current then return self:HideDrawings() end
		local Character = Current.Character
		local Humanoid = Current.Humanoid
		if not Character or not Humanoid then return self:HideDrawings() end

		local CF, Size3D = GetBoundingBoxSafe(Character, Humanoid)
		if not CF then return self:HideDrawings() end

		local MinX, MinY, MaxX, MaxY, AnyInFront = Get2DBoxFrom3DBounds(CF, Size3D)
		if not AnyInFront then return self:HideDrawings() end

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

		local BoxPos2D = Vector2New(MinX, MinY)
		local BoxSize2D = Vector2New(W, H)
		local Center2D = BoxPos2D + BoxSize2D * 0.5
		local Offset = BoxSize2D * 0.5

		SharedRenderBox(self.Drawings, BoxPos2D, BoxSize2D, Settings.Box)
		self:RenderName(Center2D, Offset, Settings.Name)
		self:RenderHealthbar(Center2D, Offset, Settings.Healthbar)
		self:RenderHeadDot(Character, Settings.HeadDot)

		local BottomYOffset = self:RenderWeapon(Center2D, Offset, Settings.Weapon, 0)
		BottomYOffset = BottomYOffset + self:RenderDistance(Center2D, Offset, Settings.Distance, BottomYOffset, DistanceOverride)
		SharedRenderFlags(self.Drawings.FlagTexts, Center2D, Offset, Settings.Flags, BottomYOffset, self)
	end

	EspLibrary.PlayerEsp = PlayerEsp
	EspLibrary.PlayerESP = PlayerEsp
end

do
	local EntityEsp = {
		EntityCache = {},
		DrawingCache = {},
		DrawingAddedConnections = {},
	}
	EntityEsp.__index = EntityEsp

	function EntityEsp.OnDrawingAdded(Callback)
		EntityEsp.DrawingAddedConnections[#EntityEsp.DrawingAddedConnections + 1] = Callback
	end

	function EntityEsp:CreateDrawingCache()
		local AllDrawings = {}
		local Cfg = EspLibrary.Config
		local FullBox = { Lines = {}, Outlines = {} }
		for i = 1, 4 do
			FullBox.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
			FullBox.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
		end
		local Corners = { Lines = {}, Outlines = {} }
		for i = 1, 8 do
			Corners.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
			Corners.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
		end
		local Drawings = {
			FullBox = FullBox,
			Corners = Corners,
			Name = CreateDrawing("Text", {
				Visible = false, Center = true, Outline = true, OutlineColor = ColorBlack,
				Color = self.Color or ColorWhite, Transparency = 1, Size = Cfg.TextSize,
				Text = self.Name or "", Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
			Distance = CreateDrawing("Text", {
				Visible = false, Center = true, Outline = true, OutlineColor = ColorBlack,
				Color = self.Color or ColorWhite, Transparency = 1, Size = Cfg.TextSize,
				Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
		}
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
			for i = 1, 8 do Cache.Corners.Lines[i].Color = Self.Color end
			Self.AllDrawings = Cache.All
			Self.Drawings = Cache
		else
			Self:CreateDrawingCache()
		end
		for i = 1, #EntityEsp.DrawingAddedConnections do
			EntityEsp.DrawingAddedConnections[i](Self)
		end
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
		for i = 1, #Cache.AllDrawings do
			Cache.AllDrawings[i].Visible = false
		end
		EntityEsp.DrawingCache[#EntityEsp.DrawingCache + 1] = Cache.Drawings
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
		local MinX, MinY, MaxX, MaxY, AnyInFront = Get2DBoxFrom3DBounds(BoxCF, BoxSize3)
		if not AnyInFront then return self:HideDrawings() end

		local W = MaxX - MinX
		local H = MaxY - MinY
		if W <= 1 or H <= 1 or W ~= W or H ~= H then return self:HideDrawings() end

		self.Hidden = false

		local Cfg = EspLibrary.Config
		if Cfg.PixelSnap then
			MinX = MathFloor(MinX + 0.5)
			MinY = MathFloor(MinY + 0.5)
			MaxX = MathFloor(MaxX + 0.5)
			MaxY = MathFloor(MaxY + 0.5)
			W = MaxX - MinX
			H = MaxY - MinY
		end

		local BoxPos2D = Vector2New(MinX, MinY)
		local BoxSize2D = Vector2New(W, H)
		local Center2D = BoxPos2D + BoxSize2D * 0.5
		local Offset = BoxSize2D * 0.5

		SharedRenderBox(self.Drawings, BoxPos2D, BoxSize2D, Settings.Box)

		local Drawings = self.Drawings
		if Settings.Name then
			local PosX = Center2D.X
			local PosY = Center2D.Y - Offset.Y - Cfg.TextSize
			if Cfg.PixelSnap then
				PosX = MathFloor(PosX + 0.5)
				PosY = MathFloor(PosY + 0.5)
			end
			Drawings.Name.Visible = true
			Drawings.Name.Position = Vector2New(PosX, PosY)
		else
			Drawings.Name.Visible = false
		end

		if Settings.Distance then
			local Magnitude = MathRound(DistanceOverride or (CurrentCamera.CFrame.Position - BoxCF.Position).Magnitude)
			local PosX = Center2D.X
			local PosY = Center2D.Y + Offset.Y
			if Cfg.PixelSnap then
				PosX = MathFloor(PosX + 0.5)
				PosY = MathFloor(PosY + 0.5)
			end
			Drawings.Distance.Visible = true
			Drawings.Distance.Position = Vector2New(PosX, PosY)
			Drawings.Distance.Text = `[{Magnitude}]`
		else
			Drawings.Distance.Visible = false
		end
	end

	EspLibrary.EntityEsp = EntityEsp
end

do
	local NpcEsp = {
		NpcCache = {},
		DrawingCache = {},
		DrawingAddedConnections = {},
	}
	NpcEsp.__index = NpcEsp

	function NpcEsp.OnDrawingAdded(Callback)
		NpcEsp.DrawingAddedConnections[#NpcEsp.DrawingAddedConnections + 1] = Callback
	end

	function NpcEsp:CreateDrawingCache()
		local AllDrawings = {}
		local Cfg = EspLibrary.Config
		local FullBox = { Lines = {}, Outlines = {} }
		for i = 1, 4 do
			FullBox.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
			FullBox.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
		end
		local Corners = { Lines = {}, Outlines = {} }
		for i = 1, 8 do
			Corners.Outlines[i] = CreateDrawing("Line", { Visible = false, Thickness = 2, Color = ColorBlack, ZIndex = BaseZIndex }, AllDrawings)
			Corners.Lines[i] = CreateDrawing("Line", { Visible = false, Thickness = 1, Color = self.Color or ColorWhite, ZIndex = BaseZIndex + 1 }, AllDrawings)
		end
		local FlagTexts = {}
		for i = 1, 6 do
			FlagTexts[i] = CreateDrawing("Text", {
				Visible = false, Center = false, Outline = true, OutlineColor = ColorBlack,
				Color = ColorWhite, Transparency = 1, Size = Cfg.FlagSize, Text = "", Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings)
		end
		local Drawings = {
			FullBox = FullBox,
			Corners = Corners,
			FlagTexts = FlagTexts,
			Name = CreateDrawing("Text", {
				Visible = false, Center = true, Outline = true, OutlineColor = ColorBlack,
				Color = self.Color or ColorWhite, Transparency = 1, Size = Cfg.TextSize,
				Text = self.Name or "", Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
			Distance = CreateDrawing("Text", {
				Visible = false, Center = true, Outline = true, OutlineColor = ColorBlack,
				Color = self.Color or ColorWhite, Transparency = 1, Size = Cfg.TextSize,
				Font = Cfg.Font, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
			HealthBar = CreateDrawing("Square", {
				Visible = false, Thickness = 1, Filled = true, ZIndex = BaseZIndex + 1,
			}, AllDrawings),
			HealthBackground = CreateDrawing("Square", {
				Visible = false, Color = ColorBackground, Transparency = 0.7, Thickness = 1, Filled = true, ZIndex = BaseZIndex,
			}, AllDrawings),
		}
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
			for i = 1, 8 do Cache.Corners.Lines[i].Color = Self.Color end
			Self.AllDrawings = Cache.All
			Self.Drawings = Cache
		else
			Self:CreateDrawingCache()
		end
		for i = 1, #NpcEsp.DrawingAddedConnections do
			NpcEsp.DrawingAddedConnections[i](Self)
		end
		local function SetupHumanoid(Humanoid)
			if Self.Humanoid then return end
			Self.Humanoid = Humanoid
			local function UpdateHealth()
				Self.HealthPercentage = Humanoid.MaxHealth > 0 and (Humanoid.Health / Humanoid.MaxHealth) or 0
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
		for i = 1, #Cache.AllDrawings do
			Cache.AllDrawings[i].Visible = false
		end
		NpcEsp.DrawingCache[#NpcEsp.DrawingCache + 1] = Cache.Drawings
	end

	function NpcEsp:HideDrawings()
		if self.Hidden then return end
		self.Hidden = true
		for i = 1, #self.AllDrawings do
			self.AllDrawings[i].Visible = false
		end
	end

	function NpcEsp:Loop(Settings, DistanceOverride)
		if not EspLibrary.Enabled then return self:HideDrawings() end
		local Model = self.Model
		local Humanoid = self.Humanoid
		if not Model or not Model.Parent or not Humanoid then return NpcEsp.Remove(Model) end

		local CF, Size3D = GetBoundingBoxSafe(Model, Humanoid)
		if not CF then return self:HideDrawings() end

		local MinX, MinY, MaxX, MaxY, AnyInFront = Get2DBoxFrom3DBounds(CF, Size3D)
		if not AnyInFront then return self:HideDrawings() end

		local W = MaxX - MinX
		local H = MaxY - MinY
		if W <= 1 or H <= 1 or W ~= W or H ~= H then return self:HideDrawings() end

		self.Hidden = false

		local Cfg = EspLibrary.Config
		if Cfg.PixelSnap then
			MinX = MathFloor(MinX + 0.5)
			MinY = MathFloor(MinY + 0.5)
			MaxX = MathFloor(MaxX + 0.5)
			MaxY = MathFloor(MaxY + 0.5)
			W = MaxX - MinX
			H = MaxY - MinY
		end

		local BoxPos2D = Vector2New(MinX, MinY)
		local BoxSize2D = Vector2New(W, H)
		local Center2D = BoxPos2D + BoxSize2D * 0.5
		local Offset = BoxSize2D * 0.5

		SharedRenderBox(self.Drawings, BoxPos2D, BoxSize2D, Settings.Box)

		local Drawings = self.Drawings
		if Settings.Name then
			local PosX = Center2D.X
			local PosY = Center2D.Y - Offset.Y - Cfg.TextSize
			if Cfg.PixelSnap then
				PosX = MathFloor(PosX + 0.5)
				PosY = MathFloor(PosY + 0.5)
			end
			Drawings.Name.Visible = true
			Drawings.Name.Text = self.Name or "NPC"
			Drawings.Name.Position = Vector2New(PosX, PosY)
		else
			Drawings.Name.Visible = false
		end

		local BottomYOffset = 0
		if Settings.Distance then
			local Magnitude = MathRound(DistanceOverride or (CurrentCamera.CFrame.Position - Model:GetPivot().Position).Magnitude)
			local PosX = Center2D.X
			local PosY = Center2D.Y + Offset.Y
			if Cfg.PixelSnap then
				PosX = MathFloor(PosX + 0.5)
				PosY = MathFloor(PosY + 0.5)
			end
			Drawings.Distance.Visible = true
			Drawings.Distance.Position = Vector2New(PosX, PosY)
			Drawings.Distance.Text = `[{Magnitude}]`
			BottomYOffset = Cfg.TextSize + 1
		else
			Drawings.Distance.Visible = false
		end

		BottomYOffset = BottomYOffset + SharedRenderFlags(Drawings.FlagTexts, Center2D, Offset, Settings.Flags, BottomYOffset, self)

		if Settings.Healthbar then
			local BasePos = Center2D - Offset - Vector2New(5, 0)
			local BaseSize = Vector2New(3, Offset.Y * 2)
			local Pct = self.HealthPercentage
			local HealthLen = (BaseSize.Y - 2) * Pct
			Drawings.HealthBar.Visible = true
			Drawings.HealthBackground.Visible = true
			Drawings.HealthBackground.Position = BasePos
			Drawings.HealthBackground.Size = BaseSize
			Drawings.HealthBar.Position = BasePos + Vector2New(1, 1 + (BaseSize.Y - 2 - HealthLen))
			Drawings.HealthBar.Size = Vector2New(1, HealthLen)
			Drawings.HealthBar.Color = ColorRed:Lerp(ColorGreen, Pct)
		else
			Drawings.HealthBar.Visible = false
			Drawings.HealthBackground.Visible = false
		end
	end

	EspLibrary.NpcEsp = NpcEsp
end

function EspLibrary:Unload()
	for Player in next, EspLibrary.PlayerEsp.PlayerCache do
		EspLibrary.PlayerEsp.Remove(Player)
	end
	for Entity in next, EspLibrary.EntityEsp.EntityCache do
		EspLibrary.EntityEsp.Remove(Entity)
	end
	for Model in next, EspLibrary.NpcEsp.NpcCache do
		EspLibrary.NpcEsp.Remove(Model)
	end
	local function ClearDrawingCache(Cache)
		for i = 1, #Cache do
			local All = Cache[i].All
			for j = 1, #All do
				All[j]:Remove()
			end
		end
		table.clear(Cache)
	end
	ClearDrawingCache(EspLibrary.PlayerEsp.DrawingCache)
	ClearDrawingCache(EspLibrary.EntityEsp.DrawingCache)
	ClearDrawingCache(EspLibrary.NpcEsp.DrawingCache)
end

return EspLibrary, 3
