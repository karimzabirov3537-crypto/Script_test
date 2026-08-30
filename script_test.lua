local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local carryEvent = ReplicatedStorage:WaitForChild("CarryPlayerEvent", 5)

-- Настройки полёта
local isFlying = false
local flySpeed = 50
local linearVelocity = nil
local attachment = nil

--------------------------------------------------------------------------------
-- СОЗДАНИЕ ИНТЕРФЕЙСА (GUI) ДЛЯ ТЕЛЕФОНА
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileControlsGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Кнопка ПОЛЁТА
local flyButton = Instance.new("TextButton")
flyButton.Name = "FlyButton"
flyButton.Size = UDim2.new(0, 100, 0, 50)
flyButton.Position = UDim2.new(0.8, -110, 0.7, 0)
flyButton.Text = "ПОЛЁТ: ВЫКЛ"
flyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.TextSize = 14
flyButton.Font = Enum.Font.SourceSansBold
flyButton.Parent = screenGui

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 10)
flyCorner.Parent = flyButton

-- Кнопка ПОДБОРА ИГРОКА
local carryButton = Instance.new("TextButton")
carryButton.Name = "CarryButton"
carryButton.Size = UDim2.new(0, 100, 0, 50)
carryButton.Position = UDim2.new(0.8, 0, 0.7, 0)
carryButton.Text = "ВЗЯТЬ"
carryButton.BackgroundColor3 = Color3.fromRGB(50, 150, 250)
carryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
carryButton.TextSize = 14
carryButton.Font = Enum.Font.SourceSansBold
carryButton.Parent = screenGui

local carryCorner = Instance.new("UICorner")
carryCorner.CornerRadius = UDim.new(0, 10)
carryCorner.Parent = carryButton

--------------------------------------------------------------------------------
-- ЛОГИКА ПОЛЁТА И ПОДБОРА
--------------------------------------------------------------------------------

local function toggleFly()
	local character = player.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	isFlying = not isFlying
	
	if isFlying then
		flyButton.Text = "ПОЛЁТ: ВКЛ"
		flyButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		
		attachment = Instance.new("Attachment")
		attachment.Parent = humanoidRootPart
		
		linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.Attachment0 = attachment
		linearVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		linearVelocity.VectorVelocity = Vector3.zero
		linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		linearVelocity.Parent = humanoidRootPart
	else
		flyButton.Text = "ПОЛЁТ: ВЫКЛ"
		flyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		
		if linearVelocity then linearVelocity:Destroy() end
		if attachment then attachment:Destroy() end
	end
end

-- Нажатие на кнопку Полёт
flyButton.MouseButton1Click:Connect(toggleFly)

-- Нажатие на кнопку Взять / Отпустить
carryButton.MouseButton1Click:Connect(function()
	local character = player.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local closestPlayer = nil
	local shortestDistance = 12 -- Максимальная дистанция для подбора (в стюдах)
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (otherPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
			if dist < shortestDistance then
				shortestDistance = dist
				closestPlayer = otherPlayer
			end
		end
	end
	
	if closestPlayer and carryEvent then
		carryEvent:FireServer(closestPlayer)
	end
end)

-- Полет по направлению камеры при включённом режиме
RunService.RenderStepped:Connect(function()
	if isFlying and linearVelocity then
		local camera = workspace.CurrentCamera
		-- Персонаж летит вперед по направлению взгляда камеры
		linearVelocity.VectorVelocity = camera.CFrame.LookVector * flySpeed
	end
end)
