repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remote = ReplicatedStorage
    :WaitForChild("Remotes")
    :WaitForChild("CommF_")

local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "ValentinesAutoRoll"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,240,0,90)
frame.Position = UDim2.new(0.5,-120,0,100)
frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
frame.BackgroundTransparency = 0.3

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,25)
title.BackgroundTransparency = 1
title.Text = "Auto Valentines Gacha"
title.TextColor3 = Color3.fromRGB(255,170,255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold

local text = Instance.new("TextLabel", frame)
text.Position = UDim2.new(0,0,0,25)
text.Size = UDim2.new(1,0,1,-25)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.fromRGB(255,255,255)
text.TextScaled = true
text.Font = Enum.Font.SourceSansBold
text.Text = "Loading..."

if not player.Team then
    text.Text = "Joining team..."
    remote:InvokeServer("SetTeam","Pirates")
    repeat task.wait() until player.Team
end

local function toSeconds(t)
    local m, s = t:match("(%d+):(%d+)")
    return tonumber(m) * 60 + tonumber(s)
end

local function checkRoll()
    local success, result = pcall(function()
        return remote:InvokeServer("Cousin", "CheckValentines26Time")
    end)

    if not success then
        warn("Invoke failed:", result)
        return false, "Error"
    end

    local timeLeft = string.match(tostring(result), "%d%d:%d%d")

    if timeLeft then
        return false, timeLeft
    else
        return true
    end
end

local function roll()
    local success, result = pcall(function()
        return remote:InvokeServer("Cousin", "ValentinesGacha26")
    end)

    if not success then
        warn("Roll failed:", result)
        return "ERROR"
    end

    if result == 2 then
        return "NO_HEARTS"
    end

    return "OK"
end

local function waitOneMinute()
    for i = 60,1,-1 do
        text.Text = "Not enough Hearts\nRetry in: "..i.."s"
        task.wait(1)
    end
end

while true do
    local ready, timeLeft = checkRoll()

    if not ready then
        text.Text = "Next roll: "..timeLeft

        if timeLeft ~= "Error" then
            local seconds = toSeconds(timeLeft)

            if seconds > 180 then
                task.wait(15)
            elseif seconds > 60 then
                task.wait(10)
            elseif seconds > 10 then
                task.wait(5)
            else
                task.wait(1)
            end
        else
            task.wait(5)
        end

    else
        text.Text = "ROLLING..."

        local rollResult = roll()

        if rollResult == "NO_HEARTS" then
            waitOneMinute()
        else
            task.wait(3)
        end
    end
end
