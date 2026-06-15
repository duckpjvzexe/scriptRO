-- Wild Pet Tracker

if _G.PetTrackerGAG2_DuckXHub_Running then
    warn("[DuckXHub] Script is already running! Duplicate execution detected.")
    return
end
_G.PetTrackerGAG2_DuckXHub_Running = true

loadstring(game:HttpGet("https://raw.githubusercontent.com/duckpjvzexe/scriptRO/refs/heads/main/PetListGAG2.lua"))()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local StarterGui = game:GetService("StarterGui")

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration or 5
        })
    end)
end

local requestFunction =
    (syn and syn.request) or
    (http and http.request) or
    http_request or
    request or
    (fluxus and fluxus.request)

assert(requestFunction, "Executor does not support HTTP requests")

local PetData = require(game:GetService("ReplicatedStorage").SharedData.PetData)

local Config = getgenv().PetTrackerGAG2_Config

assert(Config, "[Pet Tracker] Missing PetTrackerConfig")
assert(Config.Webhook, "[Pet Tracker] Missing Webhook")
assert(Config.PetNames, "[Pet Tracker] Missing PetNames")

local Whitelist = {}

for _, PetName in ipairs(Config.PetNames) do
    Whitelist[PetName] = true
end

local WildPetSpawns = workspace:WaitForChild("Map"):WaitForChild("WildPetSpawns")
local SentPets = {}

local CachedPetInfo = {}

for PetName, Info in pairs(PetData) do
    if type(Info) == "table" then
        local Rarity = Info.Rarity or "Unknown"
        local ImageUrl

        if typeof(Info.Image) == "string" then
            local AssetId = Info.Image:match("%d+")

            if AssetId then
                local Success, Response = pcall(function()
                    return game:HttpGet(
                        ("https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=512x512&format=Png&isCircular=false")
                        :format(AssetId)
                    )
                end)

                if Success then
                    local Data = HttpService:JSONDecode(Response)

                    if Data.data and Data.data[1] then
                        ImageUrl = Data.data[1].imageUrl
                    end
                end
            end
        end

        CachedPetInfo[PetName] = {
            Rarity = Rarity,
            Image = ImageUrl
        }
    end
end

local function GetPingText()
    if not Config.PingEnabled then
        return ""
    end

    if Config.PingRole == "everyone" then
        return "@everyone "
    else
        return "<@&" .. tostring(Config.PingRole) .. "> "
    end
end

local function SendWebhook(PetName, PetUID, Price, LeaveTime)
    local PetInfo = CachedPetInfo[PetName] or {}
    local PingText = GetPingText()

    local Embed = {
        title = "🐾 Pet Found !!!",
        color = 0x5eff00,

        fields = {
            {
                name = "Pet Name",
                value = tostring(PetName),
                inline = true
            },
            {
                name = "Rarity",
                value = tostring(PetInfo.Rarity or "Unknown"),
                inline = true
            },
            {
                name = "Pet UID",
                value = "`" .. tostring(PetUID) .. "`",
                inline = false
            },
            {
                name = "Price",
                value = "`" .. tostring(Price) .. "`",
                inline = true
            },
            {
                name = "Leave Time",
                value = "`" .. tostring(LeaveTime) .. "`",
                inline = true
            },
            {
                name = "Players",
                value = "`" .. tostring(#Players:GetPlayers())
                    .. " / "
                    .. tostring(Players.MaxPlayers) .. "`",
                inline = true
            },
            {
                name = "JobId",
                value = "```" .. game.JobId .. "```",
                inline = false
            }
        },

        footer = {
            text = "[DuckXHub] - Pet Tracker"
        },

        timestamp = DateTime.now():ToIsoDate()
    }

    if PetInfo.Image then
        Embed.thumbnail = {
            url = PetInfo.Image
        }
    end

    local Data = {
        content = PingText,
        username = "Pet Tracker - GAG2",
        embeds = { Embed }
    }

    local Success, Response = pcall(function()
        return requestFunction({
            Url = Config.Webhook,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(Data)
        })
    end)

    if Success then
        Notify(
            "📨 Webhook Sent",
            PetName,
            5
        )
    else
        Notify(
            "❌ Webhook Failed",
            PetName,
            5
        )
    end
end

local function CheckPet(PetModel)
    if not PetModel:IsA("Model") then
        return
    end

    if SentPets[PetModel] then
        return
    end

    local PetName = PetModel:GetAttribute("PetName")
    local PetUID = PetModel.Name:match("_WildPet_(.+)$") or "Unknown"

    if not PetName then
        return
    end

    if not Whitelist[PetName] then
        return
    end

    local RootPart = PetModel:FindFirstChild("RootPart")

    local Price = "Unknown"
    local LeaveTime = "Unknown"

    if RootPart then
        local CostGui = RootPart:FindFirstChild("PetCostTimer")

        if CostGui and CostGui:FindFirstChild("TextLabel") then
            Price = CostGui.TextLabel.Text
        end

        local LeaveGui = RootPart:FindFirstChild("PetLeaveTimer")

        if LeaveGui and LeaveGui:FindFirstChild("TextLabel") then
            LeaveTime = LeaveGui.TextLabel.Text
        end
    end

    SentPets[PetModel] = true

    local Rarity = (
        CachedPetInfo[PetName]
        and CachedPetInfo[PetName].Rarity
    ) or "Unknown"

    print(string.format(
        "[PET FOUND] %s | %s | Price: %s | Leave: %s",
        PetName,
        Rarity,
        Price,
        LeaveTime
    ))

    Notify(
        "🐾 Pet Found!",
        string.format(
            "%s (%s)\nPrice: %s",
            PetName,
            Rarity,
            Price
        ),
        10
    )

    SendWebhook(
        PetName,
        PetUID,
        Price,
        LeaveTime
    )
end

for _, Pet in ipairs(WildPetSpawns:GetChildren()) do
    task.spawn(CheckPet, Pet)

    Pet:GetAttributeChangedSignal("PetName"):Connect(function()
        CheckPet(Pet)
    end)
end

WildPetSpawns.ChildAdded:Connect(function(Pet)
    task.wait(1)

    CheckPet(Pet)

    Pet:GetAttributeChangedSignal("PetName"):Connect(function()
        CheckPet(Pet)
    end)
end)

Notify(
    "Pet Tracker",
    "Script Loaded Successfully",
    10
)

print("[Pet Tracker] Loaded")
