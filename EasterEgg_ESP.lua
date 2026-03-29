repeat wait() until game:IsLoaded() and game.Players.LocalPlayer 

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggESP_GUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = CoreGui

local espLabels = {}

local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function getEggPosition(eggInstance)
    local cf = eggInstance:GetAttribute("CFrame")
    if typeof(cf) == "CFrame" then
        return cf.Position
    end

    if eggInstance:IsA("Model") and eggInstance.PrimaryPart then
        return eggInstance.PrimaryPart.Position
    elseif eggInstance:IsA("BasePart") then
        return eggInstance.Position
    end

    return nil
end

local function createLabel(egg)
    if espLabels[egg] then return espLabels[egg] end

    local label = Instance.new("TextLabel")
    label.Name = "EggESP"
    label.Size = UDim2.new(0, 200, 0, 40)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 0)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true
    label.Visible = false
    label.Parent = screenGui

    espLabels[egg] = label
    return label
end

local function removeMissingEggs(currentEggs)
    local currentMap = {}
    for _, egg in ipairs(currentEggs) do
        currentMap[egg] = true
    end

    for egg, label in pairs(espLabels) do
        if not currentMap[egg] or not egg.Parent then
            label:Destroy()
            espLabels[egg] = nil
        end
    end
end

RunService.RenderStepped:Connect(function()
    local root = getRoot()
    local eggs = CollectionService:GetTagged("EasterEgg26")

    removeMissingEggs(eggs)

    for _, egg in ipairs(eggs) do
        local eggPos = getEggPosition(egg)
        local eggName = egg:GetAttribute("EggName") or egg.Name or "Unknown Egg"
        local label = createLabel(egg)

        if eggPos then
            local distance = (root.Position - eggPos).Magnitude
            local screenPos, onScreen = camera:WorldToViewportPoint(eggPos)

            if onScreen and screenPos.Z > 0 then
                label.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                label.Text = string.format("%s\n[%d studs]", eggName, math.floor(distance))
                label.Visible = true

                if distance < 50 then
                    label.TextColor3 = Color3.fromRGB(0, 255, 0)
                elseif distance < 150 then
                    label.TextColor3 = Color3.fromRGB(255, 255, 0)
                else
                    label.TextColor3 = Color3.fromRGB(255, 80, 80)
                end
            else
                label.Visible = false
            end
        else
            label.Visible = false
        end
    end
end)
