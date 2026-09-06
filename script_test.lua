local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

if UserInputService.TouchEnabled then
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local touchGui = playerGui:WaitForChild("TouchGui", 10)
    if touchGui then
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 10)
        if touchControlFrame then
            local jumpButton = touchControlFrame:WaitForChild("JumpButton", 10)
            if jumpButton then
                -- Умеренный размер кнопки (170x170 вместо 240x240)
                jumpButton.Size = UDim2.new(0, 170, 0, 170)
                
                -- Подгоняем позицию ближе к краю
                jumpButton.Position = UDim2.new(1, -190, 1, -190)
                
                jumpButton.ImageTransparency = 0.1
                print("Кнопка прыжка уменьшена до оптимального размера!")
            end
        end
    end
end
