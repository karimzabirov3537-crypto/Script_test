--[[
    Скрипт полёта для Roblox
    Тип: LocalScript
    Куда положить: StarterPlayer -> StarterPlayerScripts

    Возможности:
    - Кнопка "Летать" (вкл/выкл режим полёта)
    - Кнопка "Перевернуться" (переворачивает персонажа животом вниз, спиной вверх / обратно)
    - Управление стрелочками на клавиатуре (Up/Down/Left/Right)
    - Встроенный джойстик (для мобильных устройств / тач-экрана)
    - Кнопки "Вверх" и "Вниз" для вертикального перемещения
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =========================
-- Настройки
-- =========================
local FLY_SPEED = 50
local VERTICAL_SPEED = 40

-- =========================
-- Состояние
-- =========================
local flying = false
local flipped = false
local bodyVelocity = nil
local bodyGyro = nil
local flyConnection = nil

local moveInput = Vector3.new(0, 0, 0) -- x = влево/вправо, y = вверх/вниз, z = вперёд/назад

-- =========================
-- Интерфейс (ScreenGui)
-- =========================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyControlGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local function makeButton(text, size, position, anchorPoint)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = size
    btn.Position = position
    btn.AnchorPoint = anchorPoint or Vector2.new(0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.3
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.AutoButtonColor = true
    btn.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.7
    stroke.Thickness = 1.5
    stroke.Parent = btn

    return btn
end

-- Кнопка "Летать"
local flyButton = makeButton(
    "Летать",
    UDim2.new(0, 110, 0, 45),
    UDim2.new(1, -20, 1, -20),
    Vector2.new(1, 1)
)

-- Кнопка "Перевернуться"
local flipButton = makeButton(
    "Перевернуться",
    UDim2.new(0, 110, 0, 45),
    UDim2.new(1, -20, 1, -75),
    Vector2.new(1, 1)
)

-- Кнопка "Вверх"
local upButton = makeButton(
    "▲ Вверх",
    UDim2.new(0, 90, 0, 45),
    UDim2.new(1, -20, 1, -160),
    Vector2.new(1, 1)
)

-- Кнопка "Вниз"
local downButton = makeButton(
    "▼ Вниз",
    UDim2.new(0, 90, 0, 45),
    UDim2.new(1, -20, 1, -210),
    Vector2.new(1, 1)
)

-- =========================
-- Встроенный джойстик (для тач-экрана)
-- Расположен слева от кнопок, справа внизу экрана — не мешает системному джойстику Roblox (тот слева)
-- =========================
local joystickFrame = Instance.new("Frame")
joystickFrame.Name = "JoystickBase"
joystickFrame.Size = UDim2.new(0, 130, 0, 130)
joystickFrame.Position = UDim2.new(1, -270, 1, -170)
joystickFrame.AnchorPoint = Vector2.new(0, 1)
joystickFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
joystickFrame.BackgroundTransparency = 0.85
joystickFrame.Visible = UserInputService.TouchEnabled
joystickFrame.Parent = screenGui

local joyCorner = Instance.new("UICorner")
joyCorner.CornerRadius = UDim.new(1, 0)
joyCorner.Parent = joystickFrame

local joyStroke = Instance.new("UIStroke")
joyStroke.Color = Color3.fromRGB(255, 255, 255)
joyStroke.Transparency = 0.5
joyStroke.Thickness = 2
joyStroke.Parent = joystickFrame

local joyKnob = Instance.new("Frame")
joyKnob.Name = "JoystickKnob"
joyKnob.Size = UDim2.new(0, 55, 0, 55)
joyKnob.AnchorPoint = Vector2.new(0.5, 0.5)
joyKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
joyKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
joyKnob.BackgroundTransparency = 0.3
joyKnob.Parent = joystickFrame

local joyKnobCorner = Instance.new("UICorner")
joyKnobCorner.CornerRadius = UDim.new(1, 0)
joyKnobCorner.Parent = joyKnob

local joyActive = false
local joyCenter = Vector2.new(0, 0)
local joyRadius = 65

local function updateJoystickInput(inputPosition)
    local delta = Vector2.new(inputPosition.X, inputPosition.Y) - joyCenter
    local distance = math.min(delta.Magnitude, joyRadius)
    local direction = distance > 0 and (delta.Unit * distance) or Vector2.new(0, 0)

    joyKnob.Position = UDim2.new(0.5, direction.X, 0.5, direction.Y)

    -- Нормализуем в диапазон -1..1
    local normX = direction.X / joyRadius
    local normY = direction.Y / joyRadius

    -- normY: вниз на экране = положительный, вверх = отрицательный.
    -- Джойстик вперёд (вверх) должен давать движение вперёд, поэтому используем normY напрямую (без инверсии)
    moveInput = Vector3.new(normX, moveInput.Y, normY)
end

local function resetJoystick()
    joyActive = false
    joyKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
    moveInput = Vector3.new(0, moveInput.Y, 0)
end

joystickFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        joyActive = true
        local absPos = joystickFrame.AbsolutePosition
        local absSize = joystickFrame.AbsoluteSize
        joyCenter = Vector2.new(absPos.X + absSize.X / 2, absPos.Y + absSize.Y / 2)
        updateJoystickInput(Vector2.new(input.Position.X, input.Position.Y))
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if joyActive and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateJoystickInput(Vector2.new(input.Position.X, input.Position.Y))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if joyActive then
            resetJoystick()
        end
    end
end)

-- =========================
-- Управление стрелочками
-- =========================
local keysHeld = {
    Up = false,
    Down = false,
    Left = false,
    Right = false,
}

local function updateKeyboardMoveInput()
    local x = 0
    local z = 0

    if keysHeld.Left then x -= 1 end
    if keysHeld.Right then x += 1 end
    if keysHeld.Up then z -= 1 end
    if keysHeld.Down then z += 1 end

    moveInput = Vector3.new(x, moveInput.Y, z)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Up then
        keysHeld.Up = true
    elseif input.KeyCode == Enum.KeyCode.Down then
        keysHeld.Down = true
    elseif input.KeyCode == Enum.KeyCode.Left then
        keysHeld.Left = true
    elseif input.KeyCode == Enum.KeyCode.Right then
        keysHeld.Right = true
    end

    updateKeyboardMoveInput()
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Up then
        keysHeld.Up = false
    elseif input.KeyCode == Enum.KeyCode.Down then
        keysHeld.Down = false
    elseif input.KeyCode == Enum.KeyCode.Left then
        keysHeld.Left = false
    elseif input.KeyCode == Enum.KeyCode.Right then
        keysHeld.Right = false
    end

    updateKeyboardMoveInput()
end)

-- =========================
-- Кнопки вверх/вниз (удержание)
-- =========================
local function bindHoldButton(button, onDown, onUp)
    button.MouseButton1Down:Connect(onDown)
    button.MouseButton1Up:Connect(onUp)
    button.MouseLeave:Connect(onUp)
end

bindHoldButton(upButton, function()
    moveInput = Vector3.new(moveInput.X, 1, moveInput.Z)
end, function()
    moveInput = Vector3.new(moveInput.X, 0, moveInput.Z)
end)

bindHoldButton(downButton, function()
    moveInput = Vector3.new(moveInput.X, -1, moveInput.Z)
end, function()
    moveInput = Vector3.new(moveInput.X, 0, moveInput.Z)
end)

-- =========================
-- Логика полёта
-- =========================
local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function startFlying()
    local character = getCharacter()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")

    humanoid.PlatformStand = false
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.D = 500
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart

    flying = true
    flyButton.Text = "Приземлиться"

    flyConnection = RunService.RenderStepped:Connect(function()
        if not rootPart or not rootPart.Parent then
            return
        end

        local camera = workspace.CurrentCamera
        local camCFrame = camera.CFrame

        -- Направление движения относительно камеры (без наклона по вертикали)
        local flatLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
        if flatLook.Magnitude > 0 then
            flatLook = flatLook.Unit
        end
        local flatRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z)
        if flatRight.Magnitude > 0 then
            flatRight = flatRight.Unit
        end

        local horizontalMove = (flatLook * -moveInput.Z) + (flatRight * moveInput.X)
        local verticalMove = Vector3.new(0, moveInput.Y, 0)

        local finalDirection = horizontalMove
        if finalDirection.Magnitude > 0 then
            finalDirection = finalDirection.Unit
        end

        bodyVelocity.Velocity = (finalDirection * FLY_SPEED) + (verticalMove * VERTICAL_SPEED)

        -- Базовая ориентация: смотрим в сторону движения (или сохраняем текущий взгляд, если стоим на месте)
        local lookDirection
        if horizontalMove.Magnitude > 0.05 then
            lookDirection = horizontalMove
        else
            lookDirection = bodyGyro.CFrame.LookVector
            local flatCurrentLook = Vector3.new(lookDirection.X, 0, lookDirection.Z)
            if flatCurrentLook.Magnitude > 0.001 then
                lookDirection = flatCurrentLook.Unit
            else
                lookDirection = flatLook
            end
        end

        local ok, baseCFrame = pcall(function()
            return CFrame.lookAt(rootPart.Position, rootPart.Position + lookDirection, Vector3.new(0, 1, 0))
        end)

        if ok then
            if flipped then
                -- Наклон на 180° вокруг оси X (Right): переводит персонажа в положение
                -- лицом/животом вниз к земле, спиной вверх, сохраняя направление движения
                bodyGyro.CFrame = baseCFrame * CFrame.Angles(math.pi, 0, 0)
            else
                bodyGyro.CFrame = baseCFrame
            end
        end
    end)
end

local function stopFlying()
    flying = false
    flyButton.Text = "Летать"

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end

flyButton.MouseButton1Click:Connect(function()
    if flying then
        stopFlying()
    else
        startFlying()
    end
end)

-- =========================
-- Переворот (животом вниз, спиной вверх)
-- =========================
flipButton.MouseButton1Click:Connect(function()
    flipped = not flipped
    flipButton.Text = flipped and "Вернуть" or "Перевернуться"
end)

-- =========================
-- Сброс при смерти / респауне
-- =========================
player.CharacterAdded:Connect(function()
    flying = false
    flipped = false
    flyButton.Text = "Летать"
    flipButton.Text = "Перевернуться"
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    bodyVelocity = nil
    bodyGyro = nil
end)
