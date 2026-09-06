--[[
    Скрипт выдачи предмета "Crucifix" (Doors fan-game)
    Тип: LocalScript
    Куда положить: StarterPlayer -> StarterPlayerScripts

    Добавляет кнопку на экран. По нажатию клонирует Tool "Crucifix"
    из ReplicatedStorage (проверяет несколько возможных путей) и
    кладёт его в инвентарь (Backpack) игрока.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =========================
-- Поиск предмета Crucifix
-- =========================
local function findCrucifixTemplate()
    -- Вариант 1: ItemFolder.Crucifix
    local itemFolder = ReplicatedStorage:FindFirstChild("ItemFolder")
    if itemFolder then
        local found = itemFolder:FindFirstChild("Crucifix")
        if found then
            return found
        end
    end

    -- Вариант 2: Tools.Crucifix
    local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
    if toolsFolder then
        local found = toolsFolder:FindFirstChild("Crucifix")
        if found then
            return found
        end
    end

    -- Вариант 3: общий рекурсивный поиск по имени во всей ReplicatedStorage
    for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
        if descendant.Name == "Crucifix" and (descendant:IsA("Tool") or descendant:IsA("Model")) then
            return descendant
        end
    end

    return nil
end

-- =========================
-- Интерфейс (кнопка)
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CrucifixGiverGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local giveButton = Instance.new("TextButton")
giveButton.Name = "GiveCrucifixButton"
giveButton.Text = "Крестик"
giveButton.Size = UDim2.new(0, 110, 0, 45)
giveButton.Position = UDim2.new(1, -20, 1, -265)
giveButton.AnchorPoint = Vector2.new(1, 1)
giveButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
giveButton.BackgroundTransparency = 0.3
giveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
giveButton.Font = Enum.Font.GothamBold
giveButton.TextScaled = true
giveButton.AutoButtonColor = true
giveButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = giveButton

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.7
stroke.Thickness = 1.5
stroke.Parent = giveButton

-- =========================
-- Небольшое сообщение об ошибке, если предмет не найден
-- =========================
local function showMessage(text, isError)
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(0, 220, 0, 40)
    msg.Position = UDim2.new(1, -20, 1, -320)
    msg.AnchorPoint = Vector2.new(1, 1)
    msg.BackgroundColor3 = isError and Color3.fromRGB(120, 30, 30) or Color3.fromRGB(30, 90, 40)
    msg.BackgroundTransparency = 0.2
    msg.TextColor3 = Color3.fromRGB(255, 255, 255)
    msg.Font = Enum.Font.Gotham
    msg.TextScaled = true
    msg.Text = text
    msg.Parent = screenGui

    local msgCorner = Instance.new("UICorner")
    msgCorner.CornerRadius = UDim.new(0, 8)
    msgCorner.Parent = msg

    task.delay(2.5, function()
        msg:Destroy()
    end)
end

-- =========================
-- Логика выдачи предмета
-- =========================
local function giveCrucifix()
    local template = findCrucifixTemplate()

    if not template then
        warn("[CrucifixGiver] Предмет 'Crucifix' не найден в ReplicatedStorage. Проверь путь/имя объекта.")
        showMessage("Предмет не найден", true)
        return
    end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("[CrucifixGiver] Backpack игрока не найден.")
        return
    end

    -- Проверка, чтобы не дублировать предмет, если он уже есть в инвентаре или в руках
    local existingInBackpack = backpack:FindFirstChild(template.Name)
    local character = player.Character
    local existingInHands = character and character:FindFirstChild(template.Name)

    if existingInBackpack or existingInHands then
        showMessage("Уже есть в инвентаре", false)
        return
    end

    local clone = template:Clone()
    clone.Parent = backpack

    showMessage("Крестик получен", false)
end

giveButton.MouseButton1Click:Connect(giveCrucifix)
