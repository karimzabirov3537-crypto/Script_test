local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Проверяем, что игра запущена на сенсорном устройстве
if UserInputService.TouchEnabled then
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Ищем стандартный интерфейс сенсорного управления
    local touchGui = playerGui:WaitForChild("TouchGui", 10)
    if touchGui then
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 10)
        if touchControlFrame then
            local jumpButton = touchControlFrame:WaitForChild("JumpButton", 10)
            if jumpButton then
                -- Увеличиваем размер кнопки (было 120x120, станет 240x240)
                jumpButton.Size = UDim2.new(0, 240, 0, 240)
                
                -- Корректируем позицию, чтобы кнопка оставалась в углу
                jumpButton.Position = UDim2.new(1, -260, 1, -260)
                
                -- Делаем кнопку чуть более видимой
                jumpButton.ImageTransparency = 0.1
                
                print("Кнопка прыжка успешно увеличена!")
            end
        end
    end
end
