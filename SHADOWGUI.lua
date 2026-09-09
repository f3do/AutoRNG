Change all branding “ambitious” to SHADOW

local cloneref = cloneref or function(object) return object end
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TweenService = cloneref(game:GetService("TweenService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local env = type(getgenv) == "function" and getgenv() or _G

local CARPET_TOOLS = {
	["Flying Carpet"] = true,
	["Cupid's Wings"] = true,
	["Santa's Sleigh"] = true,
	["Witch's Broom"] = true,
	["Waverider"] = true,
}

local BRAINROT_LIST = {
	"Bandito Axolito",
	"Pi pi Watermelon",
	"Los Noobinis",
	"Toiletto Focaccino",
	"Tic Tic Ribbit",
	"Brainrot God Lucky Block",
	"Matteo",
	"Espresso Signora",
	"Pakrahmatmamat",
	"Pakrahmatmatina",
	"Quackalena",
	"Brasilini Berimbini",
	"Secret Lucky Block",
	"La Vacca Saturno Saturnita",
	"Dul Dul Dul",
	"Guerriro Digitale",
	"Fishboard",
	"Gelatina Volatina",
	"Rocketini Frostini",
	"Chicleteira Bicicleteira",
	"Chicleteirina Bicicleteirina",
	"Pogo Pogo Penguin",
	"Peschito Machito",
	"Money Money Puggy",
	"Ketupat Kepat",
	"Scorpino Coasterino",
	"Garama and Madundung",
	"Candini Fluffini",
	"Yetimatic",
	"La Fuse Machine",
	"La Breakfast Combinasion",
	"Dragon Cannelloni"
}

local DEFAULT_WHITELIST = table.concat({
	"Money Money Puggy",
	"Ketupat Kepat",
	"Scorpino Coasterino",
	"Garama and Madundung",
	"Candini Fluffini",
	"Yetimatic",
	"La Fuse Machine",
	"La Breakfast Combinasion",
	"Dragon Cannelloni"
}, "\n")

if env.ShadowAutoRNGShutdown then
	pcall(env.ShadowAutoRNGShutdown)
end

local CONFIG_FILE = "ShadowAutoRNGConfig.json"
local config = {
	enabled = true,
	speed = 100,
	whitelist = DEFAULT_WHITELIST
}

pcall(function()
	if type(isfile) == "function" and type(readfile) == "function" and isfile(CONFIG_FILE) then
		local loaded = HttpService:JSONDecode(readfile(CONFIG_FILE))
		if type(loaded) == "table" then
			if type(loaded.enabled) == "boolean" then config.enabled = loaded.enabled end
			if type(loaded.speed) == "number" then config.speed = math.clamp(math.floor(loaded.speed), 10, 500) end
			if type(loaded.whitelist) == "string" then config.whitelist = loaded.whitelist end
		end
	end
end)

local function saveConfig()
	if type(writefile) ~= "function" then return end
	pcall(function()
		writefile(CONFIG_FILE, HttpService:JSONEncode(config))
	end)
end

local function normalizeKey(value)
	return tostring(value or ""):lower():match("^%s*(.-)%s*$") or ""
end

local brainrotKeys = {}
for _, name in ipairs(BRAINROT_LIST) do
	brainrotKeys[normalizeKey(name)] = true
end

local whitelistSet = {}
local whitelistExtras = {}
do
	local seenExtra = {}
	for entry in tostring(config.whitelist):gmatch("[^,;\n\r]+") do
		local trimmed = entry:match("^%s*(.-)%s*$")
		local key = normalizeKey(trimmed)
		if key ~= "" then
			if brainrotKeys[key] then
				whitelistSet[key] = true
			elseif not seenExtra[key] then
				seenExtra[key] = true
				whitelistExtras[#whitelistExtras + 1] = trimmed
			end
		end
	end
end

local function rebuildWhitelist()
	local parts = {}
	for _, name in ipairs(BRAINROT_LIST) do
		if whitelistSet[normalizeKey(name)] then
			parts[#parts + 1] = name
		end
	end
	for _, extra in ipairs(whitelistExtras) do
		parts[#parts + 1] = extra
	end
	config.whitelist = table.concat(parts, "\n")
end

local function isBrainrotEnabled(name)
	return whitelistSet[normalizeKey(name)] == true
end

local state = {
	enabled = false,
	alive = true,
	token = 0,
	fired = 0,
	cycles = 0,
	movingRoot = nil,
	connections = {}
}

local COLORS = {
	Window = Color3.fromRGB(6, 6, 7),
	Row = Color3.fromRGB(15, 15, 17),
	Control = Color3.fromRGB(35, 35, 39),
	Log = Color3.fromRGB(10, 10, 12),
	White = Color3.fromRGB(245, 245, 245),
	Text = Color3.fromRGB(190, 190, 196),
	Dim = Color3.fromRGB(120, 120, 130),
	Green = Color3.fromRGB(105, 190, 132),
	Red = Color3.fromRGB(218, 105, 105),
	Amber = Color3.fromRGB(214, 158, 92),
	Cyan = Color3.fromRGB(101, 174, 183)
}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function makeLabel(parent, name, text, size, position, textSize, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.Font = font or Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local oldGui = CoreGui:FindFirstChild("ShadowAutoRNG") or playerGui:FindFirstChild("ShadowAutoRNG")
if oldGui then oldGui:Destroy() end

local GUI = Instance.new("ScreenGui")
GUI.Name = "ShadowAutoRNG"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999
if not pcall(function() GUI.Parent = CoreGui end) then GUI.Parent = playerGui end

local WINDOW_WIDTH = 310
local MAIN_HEIGHT = 244
local WHITELIST_HEIGHT = 183

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.fromOffset(WINDOW_WIDTH, MAIN_HEIGHT)
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.Position = UDim2.fromScale(0.5, 0.5)
Window.BackgroundColor3 = COLORS.Window
Window.BorderSizePixel = 0
Window.ClipsDescendants = true
Window.Parent = GUI
addCorner(Window, 14)
addStroke(Window, COLORS.White, 1, 0.58)

local InterfaceScale = Instance.new("UIScale")
InterfaceScale.Scale = 0.92
InterfaceScale.Parent = Window

local viewportConnection
local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local fit = math.min((viewport.X - 16) / WINDOW_WIDTH, (viewport.Y - 16) / MAIN_HEIGHT)
	InterfaceScale.Scale = UserInputService.TouchEnabled and math.max(0.45, math.min(0.72, fit)) or math.max(0.65, math.min(0.92, fit))
end

local function watchCamera()
	if viewportConnection then viewportConnection:Disconnect() end
	local camera = workspace.CurrentCamera
	if camera then viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end
	updateScale()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

local BackgroundImage = Instance.new("ImageLabel")
BackgroundImage.Size = UDim2.fromScale(1, 1)
BackgroundImage.BackgroundTransparency = 1
BackgroundImage.Image = "rbxassetid://121965938312103"
BackgroundImage.ImageTransparency = 0
BackgroundImage.ScaleType = Enum.ScaleType.Stretch
BackgroundImage.ZIndex = 1
BackgroundImage.Parent = Window
addCorner(BackgroundImage, 14)

local Shade = Instance.new("Frame")
Shade.Size = UDim2.fromScale(1, 1)
Shade.BackgroundColor3 = COLORS.Window
Shade.BackgroundTransparency = 0.35
Shade.BorderSizePixel = 0
Shade.ZIndex = 2
Shade.Parent = Window
addCorner(Shade, 14)

local AnimatedGradient = Instance.new("UIGradient")
AnimatedGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 4, 5)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(42, 42, 47)),
	ColorSequenceKeypoint.new(0.68, Color3.fromRGB(9, 9, 11)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(57, 57, 63))
})
AnimatedGradient.Rotation = 32
AnimatedGradient.Parent = Shade

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 64)
Header.BackgroundTransparency = 1
Header.Active = true
Header.ZIndex = 3
Header.Parent = Window

makeLabel(Header, "Title", "SHADOW AUTO RNG", UDim2.fromOffset(210, 25), UDim2.fromOffset(17, 17), 15, COLORS.White, Enum.Font.GothamBold).ZIndex = 4

local MasterToggle = Instance.new("TextButton")
MasterToggle.Size = UDim2.fromOffset(50, 26)
MasterToggle.Position = UDim2.new(1, -66, 0, 19)
MasterToggle.BackgroundColor3 = COLORS.Control
MasterToggle.BorderSizePixel = 0
MasterToggle.AutoButtonColor = false
MasterToggle.Text = ""
MasterToggle.ZIndex = 5
MasterToggle.Parent = Header
addCorner(MasterToggle, 13)
local MasterStroke = addStroke(MasterToggle, COLORS.White, 1, 0.88)

local MasterKnob = Instance.new("Frame")
MasterKnob.Size = UDim2.fromOffset(22, 22)
MasterKnob.Position = UDim2.new(0, 2, 0.5, -11)
MasterKnob.BackgroundColor3 = COLORS.White
MasterKnob.BorderSizePixel = 0
MasterKnob.ZIndex = 6
MasterKnob.Parent = MasterToggle
addCorner(MasterKnob, 11)

local HeaderAccent = Instance.new("Frame")
HeaderAccent.Size = UDim2.new(1, -34, 0, 1)
HeaderAccent.Position = UDim2.fromOffset(17, 54)
HeaderAccent.BackgroundColor3 = COLORS.White
HeaderAccent.BackgroundTransparency = 0.72
HeaderAccent.BorderSizePixel = 0
HeaderAccent.ZIndex = 4
HeaderAccent.Parent = Header

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -34, 0, 28)
TabBar.Position = UDim2.fromOffset(17, 65)
TabBar.BackgroundColor3 = COLORS.Log
TabBar.BackgroundTransparency = 0.15
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 4
TabBar.Parent = Window
addCorner(TabBar, 8)
addStroke(TabBar, COLORS.White, 1, 0.86)

local function makeTab(text, position)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.5, -3, 1, -4)
	button.Position = position
	button.BackgroundColor3 = COLORS.Control
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = text
	button.TextSize = 9
	button.TextColor3 = COLORS.Dim
	button.Font = Enum.Font.GothamBold
	button.ZIndex = 5
	button.Parent = TabBar
	addCorner(button, 6)
	return button
end

local MainTabButton = makeTab("MAIN", UDim2.fromOffset(2, 2))
local WhitelistTabButton = makeTab("WHITELIST", UDim2.new(0.5, 1, 0, 2))

local Settings = Instance.new("Frame")
Settings.Size = UDim2.new(1, 0, 0, 126)
Settings.Position = UDim2.fromOffset(0, 102)
Settings.BackgroundTransparency = 1
Settings.ZIndex = 3
Settings.Parent = Window

local function makeCard(name, position, size)
	local card = Instance.new("Frame")
	card.Name = name
	card.Position = position
	card.Size = size
	card.BackgroundColor3 = COLORS.Row
	card.BackgroundTransparency = 0.58
	card.BorderSizePixel = 0
	card.ZIndex = 3
	card.Parent = Settings
	addCorner(card, 9)
	addStroke(card, COLORS.White, 1, 0.76)
	return card
end

local SpeedCard = makeCard("Speed", UDim2.fromOffset(17, 0), UDim2.fromOffset(276, 58))
makeLabel(SpeedCard, "Title", "Velocity speed", UDim2.fromOffset(150, 58), UDim2.fromOffset(14, 0), 12, COLORS.White).ZIndex = 4

local SpeedShell = Instance.new("Frame")
SpeedShell.Size = UDim2.fromOffset(110, 38)
SpeedShell.Position = UDim2.new(1, -122, 0.5, -19)
SpeedShell.BackgroundColor3 = COLORS.Window
SpeedShell.BackgroundTransparency = 0.05
SpeedShell.BorderSizePixel = 0
SpeedShell.ZIndex = 4
SpeedShell.Parent = SpeedCard
addCorner(SpeedShell, 8)
addStroke(SpeedShell, COLORS.White, 1, 0.86)

local function makeCounterButton(parent, text, position)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(30, 30)
	button.Position = position
	button.BackgroundColor3 = COLORS.Control
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = text
	button.TextSize = 17
	button.TextColor3 = COLORS.Text
	button.Font = Enum.Font.GothamBold
	button.ZIndex = 5
	button.Parent = parent
	addCorner(button, 6)
	return button
end

local Minus = makeCounterButton(SpeedShell, "-", UDim2.fromOffset(4, 4))
local SpeedValue = makeLabel(SpeedShell, "Value", tostring(config.speed), UDim2.fromOffset(38, 30), UDim2.fromOffset(36, 4), 15, COLORS.White, Enum.Font.GothamBold)
SpeedValue.TextXAlignment = Enum.TextXAlignment.Center
SpeedValue.ZIndex = 5
local Plus = makeCounterButton(SpeedShell, "+", UDim2.fromOffset(76, 4))

local CycleCard = makeCard("Cycles", UDim2.fromOffset(17, 68), UDim2.fromOffset(276, 58))
makeLabel(CycleCard, "Title", "Cycles", UDim2.fromOffset(120, 58), UDim2.fromOffset(14, 0), 12, COLORS.White).ZIndex = 4
local CycleValue = makeLabel(CycleCard, "Value", "0", UDim2.fromOffset(140, 58), UDim2.new(1, -154, 0, 0), 17, COLORS.White, Enum.Font.GothamBold)
CycleValue.TextXAlignment = Enum.TextXAlignment.Right
CycleValue.ZIndex = 4

local WhitelistPage = Instance.new("Frame")
WhitelistPage.Size = UDim2.fromOffset(276, 76)
WhitelistPage.Position = UDim2.fromOffset(17, 102)
WhitelistPage.BackgroundTransparency = 1
WhitelistPage.Visible = false
WhitelistPage.ZIndex = 3
WhitelistPage.Parent = Window

local OpenWhitelist = Instance.new("TextButton")
OpenWhitelist.Size = UDim2.fromOffset(276, 48)
OpenWhitelist.Position = UDim2.fromOffset(0, 0)
OpenWhitelist.BackgroundColor3 = COLORS.White
OpenWhitelist.BorderSizePixel = 0
OpenWhitelist.AutoButtonColor = false
OpenWhitelist.Text = "OPEN WHITELIST MENU"
OpenWhitelist.TextColor3 = COLORS.Window
OpenWhitelist.TextSize = 11
OpenWhitelist.Font = Enum.Font.GothamBold
OpenWhitelist.ZIndex = 4
OpenWhitelist.Parent = WhitelistPage
addCorner(OpenWhitelist, 10)

local WhitelistCount = makeLabel(WhitelistPage, "Count", "", UDim2.fromOffset(276, 20), UDim2.fromOffset(0, 56), 9, COLORS.Dim, Enum.Font.GothamBold)
WhitelistCount.TextXAlignment = Enum.TextXAlignment.Center
WhitelistCount.ZIndex = 4

local function updateWhitelistCount()
	local count = 0
	for _, name in ipairs(BRAINROT_LIST) do
		if isBrainrotEnabled(name) then count += 1 end
	end
	WhitelistCount.Text = string.format("%d / %d BRAINROTS SELECTED", count, #BRAINROT_LIST)
end

local function setBrainrotEnabled(name, enabled)
	local key = normalizeKey(name)
	if enabled then whitelistSet[key] = true else whitelistSet[key] = nil end
	rebuildWhitelist()
	saveConfig()
	updateWhitelistCount()
end

local WhitelistOverlay = Instance.new("TextButton")
WhitelistOverlay.Name = "WhitelistOverlay"
WhitelistOverlay.Size = UDim2.fromScale(1, 1)
WhitelistOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
WhitelistOverlay.BackgroundTransparency = 0.45
WhitelistOverlay.BorderSizePixel = 0
WhitelistOverlay.AutoButtonColor = false
WhitelistOverlay.Text = ""
WhitelistOverlay.Visible = false
WhitelistOverlay.ZIndex = 20
WhitelistOverlay.Parent = GUI

local WhitelistModal = Instance.new("Frame")
WhitelistModal.Name = "WhitelistModal"
WhitelistModal.Size = UDim2.fromOffset(280, 340)
WhitelistModal.AnchorPoint = Vector2.new(0.5, 0.5)
WhitelistModal.Position = UDim2.fromScale(0.5, 0.5)
WhitelistModal.BackgroundColor3 = COLORS.Window
WhitelistModal.BorderSizePixel = 0
WhitelistModal.Active = true
WhitelistModal.ZIndex = 21
WhitelistModal.Parent = WhitelistOverlay
addCorner(WhitelistModal, 14)
addStroke(WhitelistModal, COLORS.White, 1, 0.58)

makeLabel(WhitelistModal, "Title", "BRAINROT WHITELIST", UDim2.fromOffset(190, 22), UDim2.fromOffset(16, 14), 12, COLORS.White, Enum.Font.GothamBold).ZIndex = 22
makeLabel(WhitelistModal, "Hint", "Tap a row to toggle it", UDim2.fromOffset(190, 16), UDim2.fromOffset(16, 34), 9, COLORS.Dim, Enum.Font.GothamMedium).ZIndex = 22

local ModalClose = Instance.new("TextButton")
ModalClose.Size = UDim2.fromOffset(28, 28)
ModalClose.Position = UDim2.new(1, -40, 0, 12)
ModalClose.BackgroundColor3 = COLORS.Control
ModalClose.BorderSizePixel = 0
ModalClose.AutoButtonColor = false
ModalClose.Text = "X"
ModalClose.TextSize = 11
ModalClose.TextColor3 = COLORS.Text
ModalClose.Font = Enum.Font.GothamBold
ModalClose.ZIndex = 22
ModalClose.Parent = WhitelistModal
addCorner(ModalClose, 8)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -24, 1, -108)
Scroll.Position = UDim2.fromOffset(12, 56)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = COLORS.Dim
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ZIndex = 22
Scroll.Parent = WhitelistModal

local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.Padding = UDim.new(0, 6)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScrollLayout.Parent = Scroll

local rowRefreshers = {}
for index, name in ipairs(BRAINROT_LIST) do
	local row = Instance.new("TextButton")
	row.Name = "Row" .. index
	row.Size = UDim2.new(1, -6, 0, 32)
	row.BackgroundColor3 = COLORS.Row
	row.BackgroundTransparency = 0.35
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = index
	row.ZIndex = 23
	row.Parent = Scroll
	addCorner(row, 8)
	local nameLabel = makeLabel(row, "Name", name, UDim2.new(1, -56, 1, 0), UDim2.fromOffset(10, 0), 11, COLORS.Text, Enum.Font.GothamMedium)
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 24
	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromOffset(36, 18)
	pill.Position = UDim2.new(1, -46, 0.5, -9)
	pill.BackgroundColor3 = COLORS.Control
	pill.BorderSizePixel = 0
	pill.ZIndex = 24
	pill.Parent = row
	addCorner(pill, 9)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.Position = UDim2.new(0, 2, 0.5, -7)
	knob.BackgroundColor3 = COLORS.White
	knob.BorderSizePixel = 0
	knob.ZIndex = 25
	knob.Parent = pill
	addCorner(knob, 7)
	local brainrotName = name
	local function refresh(animate)
		local on = isBrainrotEnabled(brainrotName)
		pill.BackgroundColor3 = on and COLORS.White or COLORS.Control
		knob.BackgroundColor3 = on and COLORS.Window or COLORS.White
		nameLabel.TextColor3 = on and COLORS.White or COLORS.Dim
		local target = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
		if animate then
			TweenService:Create(knob, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { Position = target }):Play()
		else
			knob.Position = target
		end
	end
	rowRefreshers[#rowRefreshers + 1] = refresh
	row.Activated:Connect(function()
		setBrainrotEnabled(brainrotName, not isBrainrotEnabled(brainrotName))
		refresh(true)
	end)
	refresh(false)
end

local function makeFooterButton(text, position)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(124, 34)
	button.Position = position
	button.BackgroundColor3 = COLORS.Control
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = text
	button.TextSize = 9
	button.TextColor3 = COLORS.Text
	button.Font = Enum.Font.GothamBold
	button.ZIndex = 22
	button.Parent = WhitelistModal
	addCorner(button, 8)
	addStroke(button, COLORS.White, 1, 0.86)
	return button
end

local SelectAllButton = makeFooterButton("SELECT ALL", UDim2.fromOffset(12, 294))
local ClearButton = makeFooterButton("CLEAR", UDim2.fromOffset(144, 294))

SelectAllButton.Activated:Connect(function()
	for _, name in ipairs(BRAINROT_LIST) do
		whitelistSet[normalizeKey(name)] = true
	end
	rebuildWhitelist()
	saveConfig()
	updateWhitelistCount()
	for _, refresh in ipairs(rowRefreshers) do refresh(true) end
end)

ClearButton.Activated:Connect(function()
	for _, name in ipairs(BRAINROT_LIST) do
		whitelistSet[normalizeKey(name)] = nil
	end
	rebuildWhitelist()
	saveConfig()
	updateWhitelistCount()
	for _, refresh in ipairs(rowRefreshers) do refresh(true) end
end)

OpenWhitelist.Activated:Connect(function()
	WhitelistOverlay.Visible = true
end)
ModalClose.Activated:Connect(function()
	WhitelistOverlay.Visible = false
end)
WhitelistOverlay.Activated:Connect(function()
	WhitelistOverlay.Visible = false
end)

updateWhitelistCount()

local function setTab(name)
	local main = name == "MAIN"
	Settings.Visible = main
	WhitelistPage.Visible = not main
	MainTabButton.BackgroundColor3 = main and COLORS.White or COLORS.Control
	MainTabButton.TextColor3 = main and COLORS.Window or COLORS.Dim
	WhitelistTabButton.BackgroundColor3 = main and COLORS.Control or COLORS.White
	WhitelistTabButton.TextColor3 = main and COLORS.Dim or COLORS.Window
	TweenService:Create(Window, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(WINDOW_WIDTH, main and MAIN_HEIGHT or WHITELIST_HEIGHT)
	}):Play()
end

MainTabButton.Activated:Connect(function() setTab("MAIN") end)
WhitelistTabButton.Activated:Connect(function() setTab("WHITELIST") end)
setTab("MAIN")
Window.Size = UDim2.fromOffset(WINDOW_WIDTH, MAIN_HEIGHT)

local function setToggleVisual(enabled)
	MasterToggle.BackgroundColor3 = enabled and COLORS.White or COLORS.Control
	MasterStroke.Transparency = enabled and 0.62 or 0.88
	MasterKnob.BackgroundColor3 = enabled and COLORS.Window or COLORS.White
	TweenService:Create(MasterKnob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), {
		Position = enabled and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
	}):Play()
end

local function characterParts()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	return character, humanoid, root
end

local function equipCarpetInactive()
	local character, humanoid = characterParts()
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not character or not humanoid or not backpack then return false end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and CARPET_TOOLS[child.Name] then
			return true
		end
	end
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") and CARPET_TOOLS[child.Name] then
			local tool = child
			tool.ManualActivationOnly = true
			humanoid:EquipTool(tool)
			task.wait(0.12)
			return tool.Parent == character
		end
	end
	return false
end

local function promptPosition(prompt)
	if not prompt or not prompt.Parent then return nil end
	local parent = prompt.Parent
	if parent:IsA("Attachment") then return parent.WorldPosition end
	if parent:IsA("BasePart") then return parent.Position end
	local part = parent:FindFirstChildWhichIsA("BasePart", true)
	if part then return part.Position end
	local model = parent:FindFirstAncestorOfClass("Model")
	local modelPart = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
	return modelPart and modelPart.Position
end

local function findRNGPrompt()
	local machine = workspace:FindFirstChild("RNGMachine")
	local folder = machine and machine:FindFirstChild("Prompt")
	local prompt = folder and folder:FindFirstChild("RNGMachinePrompt")
	if prompt and prompt:IsA("ProximityPrompt") then return prompt, machine end
end

local function machinePosition(machine, rngPrompt)
	local promptOrigin = promptPosition(rngPrompt)
	if promptOrigin then return promptOrigin end
	if machine and machine:IsA("BasePart") then return machine.Position end
	if machine then
		local part = machine:IsA("Model") and (machine.PrimaryPart or machine:FindFirstChildWhichIsA("BasePart", true)) or machine:FindFirstChildWhichIsA("BasePart", true)
		if part then return part.Position end
	end
	return nil
end

local function promptAttachmentPosition(attachment)
	if attachment:IsA("Attachment") then return attachment.WorldPosition end
	local spawn = attachment.Parent
	if spawn and spawn:IsA("BasePart") then return spawn.Position end
	return nil
end

local function normalizeNameForMatch(value)
	return tostring(value or ""):lower():match("^%s*(.-)%s*$") or ""
end

local function whitelistEntries()
	local entries = {}
	for entry in tostring(config.whitelist):gmatch("[^,;\n\r]+") do
		local normalized = normalizeNameForMatch(entry)
		if normalized ~= "" then entries[#entries + 1] = normalized end
	end
	return entries
end

local function displayBrainrotIdentity(prompt, display)
	local names = {}
	if prompt.ObjectText ~= "" then names[#names + 1] = prompt.ObjectText end
	local current = prompt.Parent
	while current and current ~= display do
		names[#names + 1] = current.Name
		for _, attribute in ipairs({"Index", "AnimalName", "DisplayName", "BrainrotName"}) do
			local value = current:GetAttribute(attribute)
			if value then names[#names + 1] = tostring(value) end
		end
		current = current.Parent
	end
	return table.concat(names, " ")
end

local function isWhitelistedBrainrot(identity)
	local normalizedIdentity = normalizeNameForMatch(identity)
	if normalizedIdentity == "" then return false end
	for _, entry in ipairs(whitelistEntries()) do
		if normalizedIdentity:find(entry, 1, true) or entry:find(normalizedIdentity, 1, true) then
			return true
		end
	end
	return false
end

local function findDisplayPurchase(excluded)
	local display = game.Workspace:FindFirstChild("RNGMachineDisplay")
	if not display then return nil, nil, false end
	local blockedName
	local occupied = false
	for _, item in ipairs(display:GetDescendants()) do
		if item:IsA("ProximityPrompt") and item.Enabled and item ~= excluded then
			local identity = (item.Name .. " " .. item.ActionText .. " " .. item.ObjectText):lower()
			if identity:find("purchase", 1, true) or identity:find("buy", 1, true) then
				occupied = true
				local brainrotIdentity = displayBrainrotIdentity(item, display)
				if isWhitelistedBrainrot(brainrotIdentity) then
					return item, brainrotIdentity, true
				end
				blockedName = blockedName or brainrotIdentity
			end
		end
	end
	return nil, blockedName, occupied
end

local getConnections = getconnections or (debug and debug.getconnections)
local promptCallbackCache = setmetatable({}, {__mode = "k"})

local function promptCallbacks(prompt)
	local cached = promptCallbackCache[prompt]
	if cached then return cached end
	local data = {hold = {}, trigger = {}}
	if type(getConnections) == "function" then
		pcall(function()
			for _, connection in ipairs(getConnections(prompt.PromptButtonHoldBegan)) do
				if type(connection.Function) == "function" then data.hold[#data.hold + 1] = connection.Function end
			end
			for _, connection in ipairs(getConnections(prompt.Triggered)) do
				if type(connection.Function) == "function" then data.trigger[#data.trigger + 1] = connection.Function end
			end
		end)
	end
	promptCallbackCache[prompt] = data
	return data
end

local function haltVelocity()
	local root = state.movingRoot
	if root and root.Parent then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	state.movingRoot = nil
end

local function flyToPrompt(prompt, token, label)
	local _, humanoid, root = characterParts()
	local position = promptPosition(prompt)
	if not humanoid or not root or humanoid.Health <= 0 or not position then return false end
	local destination = position + Vector3.new(0, 2.5, 0)
	local range = 1.25
	local startingDistance = (destination - root.Position).Magnitude
	local deadline = os.clock() + math.max(startingDistance / config.speed * 3 + 2, 5)
	state.movingRoot = root
	while state.enabled and state.token == token and prompt.Parent and humanoid.Health > 0 and os.clock() < deadline do
		local displacement = destination - root.Position
		if displacement.Magnitude <= range then
			haltVelocity()
			return true
		end
		root.AssemblyLinearVelocity = displacement.Unit * config.speed
		root.AssemblyAngularVelocity = Vector3.zero
		RunService.Heartbeat:Wait()
	end
	haltVelocity()
	return false
end

local function firePrompt(prompt, name, useCallbacks)
	if not prompt or not prompt.Parent or not prompt.Enabled then return false end
	local triggered = false
	local triggerConnection = prompt.Triggered:Connect(function()
		triggered = true
	end)
	local callbackFired = false
	if useCallbacks then
		local callbacks = promptCallbacks(prompt)
		for _, fn in ipairs(callbacks.hold) do
			if pcall(fn) then callbackFired = true end
		end
		for _, fn in ipairs(callbacks.trigger) do
			if pcall(fn) then callbackFired = true end
		end
	end
	if callbackFired then task.wait(0.04) end
	local oldDuration = prompt.HoldDuration
	local oldDistance = prompt.MaxActivationDistance
	local oldLineOfSight = prompt.RequiresLineOfSight
	local inputFired = false
	if not triggered and prompt.Parent and prompt.Enabled then
		inputFired = pcall(function()
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = math.max(oldDistance, 20)
			prompt.RequiresLineOfSight = false
			prompt:InputHoldBegin()
			RunService.Heartbeat:Wait()
			prompt:InputHoldEnd()
		end)
	end
	task.wait(0.08)
	local executorFired = false
	if not triggered and prompt.Parent and prompt.Enabled and type(fireproximityprompt) == "function" then
		executorFired = pcall(function()
			fireproximityprompt(prompt, 0)
		end)
		task.wait(0.08)
	end
	triggerConnection:Disconnect()
	if prompt.Parent then
		prompt.HoldDuration = oldDuration
		prompt.MaxActivationDistance = oldDistance
		prompt.RequiresLineOfSight = oldLineOfSight
	end
	local changed = not prompt.Parent or not prompt.Enabled
	local activated = callbackFired or inputFired or executorFired or triggered or changed
	if activated then
		state.fired += 1
	end
	return activated
end

local function stopAutomation(message)
	state.enabled = false
	state.token += 1
	config.enabled = false
	haltVelocity()
	setToggleVisual(false)
	saveConfig()
end

local function runAutomation()
	if state.enabled then return end
	state.enabled = true
	state.token += 1
	config.enabled = true
	local token = state.token
	setToggleVisual(true)
	saveConfig()
	task.spawn(function()
		local previousPurchase
		local function purchaseDisplay(prompt, brainrotName)
			if not prompt or not prompt.Parent then return false end
			if not flyToPrompt(prompt, token, "flying to display Purchase") then return false end
			local purchased = firePrompt(prompt, "RNG display Purchase", true)
			if purchased then
				state.cycles += 1
				CycleValue.Text = tostring(state.cycles)
			end
			return purchased
		end
		local existing, existingName, displayOccupied = findDisplayPurchase(nil)
		while displayOccupied and state.enabled and state.token == token do
			if existing and equipCarpetInactive() and purchaseDisplay(existing, existingName) then
				previousPurchase = existing
				break
			end
			if not existing then break end
			task.wait(0.15)
			existing, existingName, displayOccupied = findDisplayPurchase(nil)
		end
		while state.enabled and state.token == token do
			local rngPrompt, machine = findRNGPrompt()
			if not rngPrompt then
				task.wait(0.15)
				continue
			end
			if not equipCarpetInactive() then
				task.wait(0.5)
				continue
			end
			if not flyToPrompt(rngPrompt, token, "flying to RNG machine") then
				task.wait(0.15)
				continue
			end
			if not firePrompt(rngPrompt, "RNG prompt", false) then
				task.wait(0.2)
				continue
			end
			local purchase
			local purchaseName
			local rejectedDisplay = false
			local waitStarted = os.clock()
			while state.enabled and state.token == token and rngPrompt.Parent do
				local excluded = os.clock() - waitStarted < 1.25 and previousPurchase or nil
				local occupied
				purchase, purchaseName, occupied = findDisplayPurchase(excluded)
				if purchase then break end
				if occupied then
					rejectedDisplay = true
					break
				end
				task.wait(0.05)
			end
			if not state.enabled or state.token ~= token then break end
			if purchase then
				while purchase and state.enabled and state.token == token do
					if purchaseDisplay(purchase, purchaseName) then
						previousPurchase = purchase
						break
					end
					task.wait(0.15)
					purchase, purchaseName = findDisplayPurchase(nil)
				end
			end
			if rejectedDisplay then task.wait(0.15) end
			task.wait(0.08)
		end
		haltVelocity()
	end)
end

local function toggleAutomation()
	if state.enabled then stopAutomation("auto RNG paused") else runAutomation() end
end

MasterToggle.Activated:Connect(toggleAutomation)

Minus.Activated:Connect(function()
	config.speed = math.max(10, config.speed - 10)
	SpeedValue.Text = tostring(config.speed)
	saveConfig()
end)

Plus.Activated:Connect(function()
	config.speed = math.min(500, config.speed + 10)
	SpeedValue.Text = tostring(config.speed)
	saveConfig()
end)

do
	local dragging = false
	local activeInput
	local dragStart
	local startPosition
	Header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local position = input.Position
		local togglePosition = MasterToggle.AbsolutePosition
		local toggleSize = MasterToggle.AbsoluteSize
		if position.X >= togglePosition.X - 8 and position.X <= togglePosition.X + toggleSize.X + 8 then return end
		dragging = true
		activeInput = input
		dragStart = Vector2.new(position.X, position.Y)
		startPosition = Window.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
				dragging = false
				activeInput = nil
			end
		end)
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging or not activeInput then return end
		local validTouch = activeInput.UserInputType == Enum.UserInputType.Touch and input == activeInput
		local validMouse = activeInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement
		if not validTouch and not validMouse then return end
		local current = Vector2.new(input.Position.X, input.Position.Y)
		local delta = current - dragStart
		Window.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
	end)
end

table.insert(state.connections, RunService.RenderStepped:Connect(function()
	AnimatedGradient.Offset = Vector2.new(math.sin(os.clock() * 0.55) * 0.3, math.cos(os.clock() * 0.38) * 0.08)
end))

local function shutdown()
	state.alive = false
	state.enabled = false
	state.token += 1
	haltVelocity()
	for _, connection in ipairs(state.connections) do
		pcall(function() connection:Disconnect() end)
	end
	if viewportConnection then viewportConnection:Disconnect() end
	if GUI then GUI:Destroy() end
end

env.AmbitiousAutoRNGShutdown = shutdown
setToggleVisual(false)

if config.enabled then
	task.defer(runAutomation)
end
