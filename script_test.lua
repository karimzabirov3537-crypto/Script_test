local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local safeZonePosition = nil
local targetPlayer = nil
local isCarrying = false
local flyBodyVelocity = nil
local flyBodyGyro = nil

local FLY_SPEED = 60
local PICKUP_RADIUS = 25

-- Обновление персонажа при спавне
localPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	hrp = character:WaitForChild("HumanoidRootPart")
	isCarrying = false
	targetPlayer = nil
end)

-- Поиск ближайшего игрока
local function getClosestPlayer()
	local closestPlayer = nil
	local shortestDistance = PICKUP_RADIUS

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local targetHrp = player.Character.HumanoidRootPart
			local distance = (hrp.Position - targetHrp.Position).Magnitude
			if distance < shortestDistance then
				closestPlayer = player
				shortestDistance = distance
			end
		end
	end
	return closestPlayer
end

-- Включение/Выключение полета
local function setFly(enabled)
	if enabled then
		if not flyBodyVelocity then
			flyBodyVelocity = Instance.new("BodyVelocity")
			flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
			flyBodyVelocity.Parent = hrp
		end
		if not flyBodyGyro then
			flyBodyGyro = Instance.new("BodyGyro")
			flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
			flyBodyGyro.CFrame = hrp.CFrame
			flyBodyGyro.Parent = hrp
		end
	else
		if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
		if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
	end
end

-- Создание GUI элементов
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RescueGui"
screenGui.ResetOnSpawn = false
-- Защита от обнаружения и удаление старого GUI
if gethui then
	screenGui.Parent = gethui()
elseif CoreGui:FindFirstChild("RescueGui") then
	CoreGui.RescueGui:Destroy()
	screenGui.Parent = CoreGui
else
	screenGui.Parent = CoreGui
end

-- Кнопка 1: Установка базы
local btnSetBase = Instance.new("TextButton")
btnSetBase.Size = UDim2.new(0, 140, 0, 45)
btnSetBase.Position = UDim2.new(0.02, 0, 0.4, 0)
btnSetBase.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
btnSetBase.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSetBase.TextSize = 14
btnSetBase.Font = Enum.Font.SourceSansBold
btnSetBase.Text = "📍 Задать базу"
btnSetBase.Parent = screenGui

-- Кнопка 2: Спасти / Отпустить
local btnRescue = Instance.new("TextButton")
btnRescue.Size = UDim2.new(0, 140, 0, 45)
btnRescue.Position = UDim2.new(0.02, 0, 0.5, 0)
btnRescue.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
btnRescue.TextColor3 = Color3.fromRGB(255, 255, 255)
btnRescue.TextSize = 14
btnRescue.Font = Enum.Font.SourceSansBold
btnRescue.Text = "🆘 Спасти игрока"
btnRescue.Parent = screenGui

-- Скругление углов
local corner1 = Instance.new("UICorner") corner1.CornerRadius = UDim.new(0, 8) corner1.Parent = btnSetBase
local corner2 = Instance.new("UICorner") corner2.CornerRadius = UDim.new(0, 8) corner2.Parent = btnRescue

-- Логика нажатия кнопок
btnSetBase.MouseButton1Click:Connect(function()
	if hrp then
		safeZonePosition = hrp.Position
		btnSetBase.Text = "✅ База сохранена!"
		task.wait(1.5)
		btnSetBase.Text = "📍 Задать базу"
	end
end)

btnRescue.MouseButton1Click:Connect(function()
	if isCarrying then
		isCarrying = false
		targetPlayer = nil
		setFly(false)
		btnRescue.Text = "🆘 Спасти игрока"
		btnRescue.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
	else
		if not safeZonePosition then
			btnRescue.Text = "⚠️ Сначала задай базу!"
			task.wait(1.5)
			btnRescue.Text = "🆘 Спасти игрока"
			return
		end

		local target = getClosestPlayer()
		if target then
			targetPlayer = target
			isCarrying = true
			setFly(true)
			btnRescue.Text = "❌ Отпустить"
			btnRescue.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
		else
			btnRescue.Text = "❓ Нет никого рядом"
			task.wait(1.5)
			btnRescue.Text = "🆘 Спасти игрока"
		end
	end
end)

-- Цикл переноса
RunService.Heartbeat:Connect(function()
	if isCarrying and targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local targetHrp = targetPlayer.Character.HumanoidRootPart
		targetHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -4)

		if safeZonePosition then
			local direction = (safeZonePosition - hrp.Position).Unit
			local distance = (safeZonePosition - hrp.Position).Magnitude

			if distance > 6 then
				flyBodyVelocity.Velocity = direction * FLY_SPEED
				flyBodyGyro.CFrame = CFrame.new(hrp.Position, safeZonePosition)
			else
				flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
				isCarrying = false
				targetPlayer = nil
				setFly(false)
				btnRescue.Text = "🆘 Спасти игрока"
				btnRescue.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
			end
		end
	end
end)

