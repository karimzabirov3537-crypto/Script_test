--// Script: Get Crucifix by button click
--// Works in fan games of DOORS (Executor required)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")

--// Creating ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrucifixGUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--// Creating TextButton
local Button = Instance.new("TextButton")
Button.Name = "GetCrucifixButton"
Button.Size = UDim2.new(0, 200, 0, 50)
Button.Position = UDim2.new(0.5, -100, 0.8, 0)  -- bottom center
Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Text = "Получить Крест (Crucifix)"
Button.Font = Enum.Font.SourceSansBold
Button.TextSize = 16
Button.Parent = ScreenGui

--// Optional: adding rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Button

--// Function to give Crucifix
local function giveCrucifix()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    -- Check if already has crucifix in backpack
    local existingBackpack = Backpack:FindFirstChild("Crucifix")
    local existingCharacter = character:FindFirstChild("Crucifix")

    if existingBackpack or existingCharacter then
        print("Crucifix already exists!")
        return
    end

    -- Try to load the asset from Roblox library (common crucifix model)
    local assetId = "rbxassetid://11498423088" -- change this ID if your fan game uses a different crucifix model

    local success, result = pcall(function()
        return game:GetObjects(assetId)
    end)

    if success and result and #result > 0 then
        local model = result[1]

        if model:IsA("Tool") then
            model.Name = "Crucifix"
            model.Parent = Backpack
            print("Crucifix added to backpack!")
        else
            warn("Asset is not a Tool! Searching for Tool inside model...")
            local tool = model:FindFirstChildOfClass("Tool")
            if tool then
                tool.Name = "Crucifix"
                tool.Parent = Backpack
                print("Crucifix (from model) added to backpack!")
            else
                warn("Could not find Tool in asset!")
            end
        end
    else
        -- If asset loading fails, create a dummy crucifix
        warn("Failed to load asset. Creating dummy Crucifix...")

        local tool = Instance.new("Tool")
        tool.Name = "Crucifix"
        tool.RequiresHandle = false
        tool.Parent = Backpack

        -- Create simple handle
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = Vector3.new(0.3, 1, 0.3)
        handle.BrickColor = BrickColor.new("Dark stone grey")
        handle.Parent = tool

        print("Dummy Crucifix added!")
    end
end

--// Connect button click
Button.MouseButton1Click:Connect(giveCrucifix)

print("Script loaded! Press the button to get Crucifix.")
