local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera

local flying = false
local speed = 50

local bodyVelocity = nil
local bodyGyro = nil

-- Обновление персонажа при респавне
localPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	hrp = character:WaitForChild("HumanoidRootPart")
	flying = false
	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
end)

-- Создание GUI элементов для телефона
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyGui"
screenGui.ResetOnSpawn = false

if gethui then
	screenGui.Parent = gethui()
elseif CoreGui:FindFirstChild("FlyGui") then
	CoreGui.FlyGui:Destroy()
	screenGui.Parent = CoreGui
else
	screenGui.Parent = CoreGui
end

local btnFly = Instance.new("TextButton")
btnFly.Size = UDim2.new(0, 130, 0, 50)
btnFly.Position = UDim2.new(0.02, 0, 0.45, 0)
btnFly.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
btnFly.TextColor3 = Color3.fromRGB(255, 255, 255)
btnFly.TextSize = 16
btnFly.Font = Enum.Font.SourceSansBold
btnFly.Text = "🚀 Включить Флай"
btnFly.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = btnFly

-- Включение / Выключение полета
local function toggleFly()
	flying = not flying
	
	if flying then
		btnFly.Text = "❌ Выключить Флай"
		btnFly.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
		
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.Parent = hrp
		
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
		bodyGyro.CFrame = hrp.CFrame
		bodyGyro.Parent = hrp
	else
		btnFly.Text = "🚀 Включить Флай"
		btnFly.BackgroundColor3 = Color3.fromRGB(0, 150, 75)
		
		if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
		if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	end
end

btnFly.MouseButton1Click:Connect(toggleFly)

-- Управление полетом по направлению камеры
RunService.RenderStepped:Connect(function()
	if flying and hrp and bodyVelocity and bodyGyro then
		-- Направляем тело персонажа туда, куда смотрит камера
		bodyGyro.CFrame = camera.CFrame
		
		-- Берем движение с джойстика/кнопок персонажа
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local moveDirection = humanoid.MoveDirection
			if moveDirection.Magnitude > 0 then
				-- Летим в сторону движения джойстика относительно камеры
				local flyVector = camera.CFrame:VectorToWorldSpace(CFrame.new(moveDirection).LookVector)
				bodyVelocity.Velocity = camera.CFrame.LookVector * (moveDirection.Magnitude * speed)
			else
				bodyVelocity.Velocity = Vector3.new(0, 0, 0)
			end
		end
	end
end)
