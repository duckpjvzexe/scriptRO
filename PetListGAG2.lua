local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PetData = require(game:GetService("ReplicatedStorage").SharedData.PetData)
local WildPetSpawns = workspace:WaitForChild("Map"):WaitForChild("WildPetSpawns")

local function teleportToPet(petModel)
	local chr = player.Character
	if not chr then return end
	local hrp = chr:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local target
	if petModel:FindFirstChild("RootPart") then
		target = petModel.RootPart.CFrame + Vector3.new(0, 0, 4)
	elseif petModel.PrimaryPart then
		target = petModel.PrimaryPart.CFrame + Vector3.new(0, 0, 4)
	else
		for _, v in ipairs(petModel:GetDescendants()) do
			if v:IsA("BasePart") then
				target = v.CFrame + Vector3.new(0, 2, 4)
				break
			end
		end
	end
	if target then hrp.CFrame = target end
end

local petIconCache = {}
local function getPetIcon(petName)
	if petIconCache[petName] then return petIconCache[petName] end
	local petInfo = PetData[petName]
	if petInfo and petInfo.Image and typeof(petInfo.Image) == "string" then
		local assetId = petInfo.Image:match("%d+")
		if assetId then
			local url = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
			petIconCache[petName] = url
			return url
		end
	end
	petIconCache[petName] = ""
	return ""
end

local function parseTimeToSeconds(timeStr)
	if not timeStr or timeStr == "Unknown" then return 0 end
	timeStr = tostring(timeStr):lower():gsub(" ", "")
	local total = 0
	local h = timeStr:match("(%d+)h"); if h then total = total + tonumber(h) * 3600 end
	local m = timeStr:match("(%d+)m"); if m then total = total + tonumber(m) * 60 end
	local s = timeStr:match("(%d+)s"); if s then total = total + tonumber(s) end
	return total
end

local function formatTime(seconds)
	if seconds <= 0 then return "EXPIRED" end
	seconds = math.ceil(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then return string.format("%dh %02dm", h, m) end
	if m > 0 then return string.format("%dm %02ds", m, s) end
	return string.format("%ds", s)
end

local function getTimerColor(seconds)
	if seconds <= 0   then return Color3.fromRGB(90,  90,  100) end
	if seconds <= 30  then return Color3.fromRGB(255, 70,  70)  end
	if seconds <= 60  then return Color3.fromRGB(255, 150, 0)   end
	if seconds <= 120 then return Color3.fromRGB(255, 220, 0)   end
	return Color3.fromRGB(80, 220, 140)
end

local rarityColors = {
	Common    = Color3.fromRGB(180, 180, 190),
	Uncommon  = Color3.fromRGB(80,  200, 100),
	Rare      = Color3.fromRGB(80,  150, 255),
	Epic      = Color3.fromRGB(180, 80,  255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 80,  80),
	Super     = Color3.fromRGB(255, 100, 200),
}
local rarityIcons = {
	Common = "◇", Uncommon = "◈", Rare = "◆",
	Epic = "★", Legendary = "✦", Mythic = "⚡", Super = "👑",
}

local function makeDraggable(frame, handle)
	handle = handle or frame
	local dragging, dragInput, mousePos, framePos = false, nil, nil, nil
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			mousePos = input.Position
			framePos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - mousePos
			frame.Position = UDim2.new(
				framePos.X.Scale, framePos.X.Offset + delta.X,
				framePos.Y.Scale, framePos.Y.Offset + delta.Y
			)
		end
	end)
end

local toggleGui = Instance.new("ScreenGui")
toggleGui.Name           = "PetTrackerToggle"
toggleGui.IgnoreGuiInset = true
toggleGui.ResetOnSpawn   = false
toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
toggleGui.DisplayOrder   = 1000000
toggleGui.Parent         = playerGui

local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size             = UDim2.new(0, 54, 0, 54)
toggleBtn.Position         = UDim2.new(0, 16, 0.5, -27)
toggleBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
toggleBtn.BorderSizePixel  = 0
toggleBtn.Image            = "rbxthumb://type=GamePass&id=243367649&w=150&h=150"
toggleBtn.Draggable        = true
toggleBtn.AutoButtonColor  = false
toggleBtn.Parent           = toggleGui

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

local btnStroke = Instance.new("UIStroke", toggleBtn)
btnStroke.Color     = Color3.fromRGB(70, 70, 100)
btnStroke.Thickness = 2

local statusDot = Instance.new("Frame", toggleBtn)
statusDot.Size             = UDim2.new(0, 12, 0, 12)
statusDot.Position         = UDim2.new(1, -13, 0, 1)
statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
statusDot.BorderSizePixel  = 0
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local dotStroke = Instance.new("UIStroke", statusDot)
dotStroke.Color     = Color3.fromRGB(16, 16, 22)
dotStroke.Thickness = 2

local btnBadge = Instance.new("Frame", toggleBtn)
btnBadge.Size             = UDim2.new(0, 20, 0, 20)
btnBadge.Position         = UDim2.new(1, -20, 1, -20)
btnBadge.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
btnBadge.BorderSizePixel  = 0
btnBadge.Visible          = false
Instance.new("UICorner", btnBadge).CornerRadius = UDim.new(1, 0)

local badgeStroke = Instance.new("UIStroke", btnBadge)
badgeStroke.Color     = Color3.fromRGB(16, 16, 22)
badgeStroke.Thickness = 2

local btnBadgeText = Instance.new("TextLabel", btnBadge)
btnBadgeText.Size               = UDim2.new(1, 0, 1, 0)
btnBadgeText.BackgroundTransparency = 1
btnBadgeText.Text               = "0"
btnBadgeText.TextColor3         = Color3.fromRGB(255, 255, 255)
btnBadgeText.TextScaled         = true
btnBadgeText.Font               = Enum.Font.GothamBold

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "PetTrackerUI_v3"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

local PANEL_W = 680

local mainPanel = Instance.new("Frame")
mainPanel.Name                   = "MainPanel"
mainPanel.Size                   = UDim2.new(0, PANEL_W, 0, 54)
mainPanel.Position               = UDim2.new(0.5, -PANEL_W/2, 0, 12)
mainPanel.BackgroundColor3       = Color3.fromRGB(16, 16, 22)
mainPanel.BackgroundTransparency = 0.05
mainPanel.BorderSizePixel        = 0
mainPanel.ClipsDescendants       = true
mainPanel.Visible                = true
mainPanel.Parent                 = screenGui

Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 14)
local panelStroke = Instance.new("UIStroke", mainPanel)
panelStroke.Color     = Color3.fromRGB(60, 60, 85)
panelStroke.Thickness = 1.5

local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 48)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
header.BorderSizePixel  = 0
header.Parent           = mainPanel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local hGrad = Instance.new("UIGradient", header)
hGrad.Color    = ColorSequence.new(Color3.fromRGB(30,30,48), Color3.fromRGB(18,18,28))
hGrad.Rotation = 90

local pawLabel = Instance.new("TextLabel", header)
pawLabel.Size               = UDim2.new(0, 36, 1, 0)
pawLabel.Position           = UDim2.new(0, 10, 0, 0)
pawLabel.BackgroundTransparency = 1
pawLabel.Text               = "🐾"
pawLabel.TextScaled         = true

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size             = UDim2.new(0, 200, 1, 0)
titleLabel.Position         = UDim2.new(0, 46, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text             = "WILD PET TRACKER"
titleLabel.TextColor3       = Color3.fromRGB(210, 210, 230)
titleLabel.TextScaled       = true
titleLabel.Font             = Enum.Font.GothamBold
titleLabel.TextXAlignment   = Enum.TextXAlignment.Left

local countBadge = Instance.new("Frame", header)
countBadge.Size             = UDim2.new(0, 76, 0, 26)
countBadge.Position         = UDim2.new(0, 252, 0.5, -13)
countBadge.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
countBadge.BorderSizePixel  = 0
Instance.new("UICorner", countBadge).CornerRadius = UDim.new(0, 13)

local petCountLabel = Instance.new("TextLabel", countBadge)
petCountLabel.Size              = UDim2.new(1, 0, 1, 0)
petCountLabel.BackgroundTransparency = 1
petCountLabel.Text              = "0 pets"
petCountLabel.TextColor3        = Color3.fromRGB(120, 190, 255)
petCountLabel.TextScaled        = true
petCountLabel.Font              = Enum.Font.GothamBold

local hotkeyHint = Instance.new("TextLabel", header)
hotkeyHint.Size             = UDim2.new(0, 120, 1, 0)
hotkeyHint.Position         = UDim2.new(1, -128, 0, 0)
hotkeyHint.BackgroundTransparency = 1
hotkeyHint.Text             = "[LCtrl] toggle"
hotkeyHint.TextColor3       = Color3.fromRGB(70, 70, 95)
hotkeyHint.TextScaled       = true
hotkeyHint.Font             = Enum.Font.Gotham

makeDraggable(mainPanel, header)

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Name               = "ContentScroll"
contentScroll.Size               = UDim2.new(1, -12, 1, -56)
contentScroll.Position           = UDim2.new(0, 6, 0, 52)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel    = 0
contentScroll.ScrollBarThickness = 4
contentScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 115)
contentScroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
contentScroll.ScrollingDirection = Enum.ScrollingDirection.Y
contentScroll.Parent             = mainPanel

local grid = Instance.new("UIGridLayout", contentScroll)
grid.CellSize            = UDim2.new(0, 214, 0, 114)
grid.CellPadding         = UDim2.new(0, 7, 0, 7)
grid.SortOrder           = Enum.SortOrder.LayoutOrder
grid.FillDirection       = Enum.FillDirection.Horizontal
grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
grid.VerticalAlignment   = Enum.VerticalAlignment.Top

local gridPad = Instance.new("UIPadding", contentScroll)
gridPad.PaddingTop    = UDim.new(0, 5)
gridPad.PaddingLeft   = UDim.new(0, 4)
gridPad.PaddingRight  = UDim.new(0, 4)
gridPad.PaddingBottom = UDim.new(0, 6)

local displayedPets = {}
local petTimers     = {}

local function createPetCard(petName, petUID, rarity, leaveTime, price, petModel)
	local rc = rarityColors[rarity] or Color3.fromRGB(150,150,160)
	local ri = rarityIcons[rarity]  or "◇"

	local card = Instance.new("TextButton")
	card.Name             = "PetCard_" .. petUID
	card.BackgroundColor3 = Color3.fromRGB(26, 26, 38)
	card.BorderSizePixel  = 0
	card.Text             = ""
	card.AutoButtonColor  = false
	card.Parent           = contentScroll

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", card)
	stroke.Color     = Color3.fromRGB(50, 50, 70)
	stroke.Thickness = 1

	local accent = Instance.new("Frame", card)
	accent.Size             = UDim2.new(0, 4, 1, -14)
	accent.Position         = UDim2.new(0, 4, 0, 7)
	accent.BackgroundColor3 = rc
	accent.BorderSizePixel  = 0
	Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)

	local iconBg = Instance.new("Frame", card)
	iconBg.Size             = UDim2.new(0, 66, 0, 66)
	iconBg.Position         = UDim2.new(0, 14, 0.5, -33)
	iconBg.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	iconBg.BorderSizePixel  = 0
	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)

	local iconStroke = Instance.new("UIStroke", iconBg)
	iconStroke.Color        = rc
	iconStroke.Thickness    = 1.5
	iconStroke.Transparency = 0.5

	local iconImg = Instance.new("ImageLabel", iconBg)
	iconImg.Size               = UDim2.new(1, -8, 1, -8)
	iconImg.Position           = UDim2.new(0, 4, 0, 4)
	iconImg.BackgroundTransparency = 1
	iconImg.Image              = getPetIcon(petName)

	local info = Instance.new("Frame", card)
	info.Size               = UDim2.new(1, -90, 1, -10)
	info.Position           = UDim2.new(0, 86, 0, 5)
	info.BackgroundTransparency = 1

	local nameL = Instance.new("TextLabel", info)
	nameL.Size              = UDim2.new(1, 0, 0, 22)
	nameL.BackgroundTransparency = 1
	nameL.Text              = (PetData.GetSpeciesDisplayName and PetData.GetSpeciesDisplayName(petName)) or petName
	nameL.TextColor3        = Color3.fromRGB(225, 225, 240)
	nameL.TextScaled        = true
	nameL.Font              = Enum.Font.GothamBold
	nameL.TextXAlignment    = Enum.TextXAlignment.Left

	local rarityL = Instance.new("TextLabel", info)
	rarityL.Size            = UDim2.new(1, 0, 0, 18)
	rarityL.Position        = UDim2.new(0, 0, 0, 24)
	rarityL.BackgroundTransparency = 1
	rarityL.Text            = ri .. "  " .. tostring(rarity)
	rarityL.TextColor3      = rc
	rarityL.TextSize        = 12
	rarityL.Font            = Enum.Font.GothamSemibold
	rarityL.TextXAlignment  = Enum.TextXAlignment.Left

	local timerBg = Instance.new("Frame", info)
	timerBg.Size             = UDim2.new(1, 0, 0, 22)
	timerBg.Position         = UDim2.new(0, 0, 0, 44)
	timerBg.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
	timerBg.BorderSizePixel  = 0
	Instance.new("UICorner", timerBg).CornerRadius = UDim.new(0, 5)

	local timerL = Instance.new("TextLabel", timerBg)
	timerL.Name             = "LeaveLabel"
	timerL.Size             = UDim2.new(1, -8, 1, 0)
	timerL.Position         = UDim2.new(0, 8, 0, 0)
	timerL.BackgroundTransparency = 1
	timerL.Text             = "⏱  " .. tostring(leaveTime)
	timerL.TextColor3       = Color3.fromRGB(80, 220, 140)
	timerL.TextScaled       = true
	timerL.Font             = Enum.Font.GothamBold
	timerL.TextXAlignment   = Enum.TextXAlignment.Left

	local priceBg = Instance.new("Frame", info)
	priceBg.Size             = UDim2.new(1, 0, 0, 22)
	priceBg.Position         = UDim2.new(0, 0, 0, 68)
	priceBg.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
	priceBg.BorderSizePixel  = 0
	Instance.new("UICorner", priceBg).CornerRadius = UDim.new(0, 5)

	local priceL = Instance.new("TextLabel", priceBg)
	priceL.Size             = UDim2.new(1, -8, 1, 0)
	priceL.Position         = UDim2.new(0, 8, 0, 0)
	priceL.BackgroundTransparency = 1
	priceL.Text             = "💰 " .. tostring(price)
	priceL.TextColor3       = Color3.fromRGB(255, 210, 60)
	priceL.TextScaled       = true
	priceL.Font             = Enum.Font.GothamBold
	priceL.TextXAlignment   = Enum.TextXAlignment.Left

	local hint = Instance.new("TextLabel", card)
	hint.Size               = UDim2.new(1, -90, 0, 11)
	hint.Position           = UDim2.new(0, 86, 1, -13)
	hint.BackgroundTransparency = 1
	hint.Text               = "▶ Click to Teleport"
	hint.TextColor3         = Color3.fromRGB(60, 60, 85)
	hint.TextSize           = 10
	hint.Font               = Enum.Font.Gotham
	hint.TextXAlignment     = Enum.TextXAlignment.Left

	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(38, 38, 55)}):Play()
		stroke.Color        = rc
		stroke.Transparency = 0.4
		hint.TextColor3     = Color3.fromRGB(100, 160, 255)
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)}):Play()
		stroke.Color        = Color3.fromRGB(50, 50, 70)
		stroke.Transparency = 0
		hint.TextColor3     = Color3.fromRGB(60, 60, 85)
	end)

	card.MouseButton1Click:Connect(function()
		if petModel and petModel.Parent then
			teleportToPet(petModel)
			TweenService:Create(card, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 90, 60)}):Play()
			task.wait(0.18)
			TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(26, 26, 38)}):Play()
		end
	end)

	petTimers[petUID] = {
		leaveLabel = timerL,
		leaveTime  = parseTimeToSeconds(tostring(leaveTime)),
		createdAt  = tick(),
	}
end

local function updateBadge(count)
	btnBadgeText.Text = tostring(count)
	btnBadge.Visible  = count > 0
	statusDot.BackgroundColor3 = count > 0
		and Color3.fromRGB(80, 220, 100)
		or  Color3.fromRGB(100, 100, 120)
end

local function recalcHeight()
	local count = 0
	for _ in pairs(displayedPets) do count = count + 1 end
	local rows     = math.ceil(count / 3)
	local contentH = rows > 0 and (rows * 114 + (rows - 1) * 7 + 12) or 0
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentH)
	local totalH = math.clamp(54 + contentH + 8, 54, 500)
	TweenService:Create(mainPanel, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, PANEL_W, 0, totalH)
	}):Play()
end

local function updatePetList()
	for uid, petModel in pairs(displayedPets) do
		if not petModel.Parent or petModel.Parent ~= WildPetSpawns then
			local c = contentScroll:FindFirstChild("PetCard_" .. uid)
			if c then c:Destroy() end
			petTimers[uid]     = nil
			displayedPets[uid] = nil
		end
	end

	for _, petModel in ipairs(WildPetSpawns:GetChildren()) do
		if petModel:IsA("Model") then
			local petName = petModel:GetAttribute("PetName")
			local petUID  = petModel.Name:match("_WildPet_(.+)$") or petModel.Name

			if petName and not displayedPets[petUID] then
				displayedPets[petUID] = petModel

				local petInfo   = PetData[petName] or {}
				local rarity    = petInfo.Rarity or "Common"
				local leaveTime = "Unknown"
				local price     = "Unknown"

				local rootP = petModel:FindFirstChild("RootPart")
				if rootP then
					local lg = rootP:FindFirstChild("PetLeaveTimer")
					if lg and lg:FindFirstChild("TextLabel") then
						leaveTime = lg.TextLabel.Text
					end
					local pg = rootP:FindFirstChild("PetCostTimer")
					if pg and pg:FindFirstChild("TextLabel") then
						price = pg.TextLabel.Text
					end
				end

				createPetCard(petName, petUID, rarity, leaveTime, price, petModel)
			end
		end
	end

	local count = #WildPetSpawns:GetChildren()
	petCountLabel.Text = count .. " pet" .. (count ~= 1 and "s" or "")
	updateBadge(count)
	recalcHeight()
end

local isVisible = true

local function toggleUI()
	isVisible = not isVisible
	mainPanel.Visible = isVisible
	btnStroke.Color = isVisible
		and Color3.fromRGB(100, 180, 255)
		or  Color3.fromRGB(70, 70, 100)
end

toggleBtn.MouseButton1Click:Connect(toggleUI)

toggleBtn.MouseEnter:Connect(function()
	TweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 55)}):Play()
end)
toggleBtn.MouseLeave:Connect(function()
	TweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 22, 34)}):Play()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.LeftControl then
		toggleUI()
	end
end)

updatePetList()

WildPetSpawns.ChildAdded:Connect(function()
	task.wait(0.3)
	updatePetList()
end)
WildPetSpawns.ChildRemoved:Connect(function()
	task.wait(0.3)
	updatePetList()
end)

RunService.Heartbeat:Connect(function()
	for uid, data in pairs(petTimers) do
		if data and data.leaveLabel and data.leaveLabel.Parent then
			local rem = data.leaveTime - (tick() - data.createdAt)
			data.leaveLabel.Text       = "⏱  " .. formatTime(rem)
			data.leaveLabel.TextColor3 = getTimerColor(rem)
		end
	end
end)

local hbN = 0
RunService.Heartbeat:Connect(function()
	hbN = hbN + 1
	if hbN >= 300 then
		hbN = 0
		if screenGui.Parent then
			updatePetList()
		end
	end
end)
