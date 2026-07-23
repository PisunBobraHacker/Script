local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local NoClipEnabled = false
local Speed = 3
local StepDelay = 0.01 -- Задержка между рывками (чем меньше, тем быстрее)

-- Создаём GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 130)
MainFrame.Position = UDim2.new(1, -210, 0.5, -65)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Position = UDim2.new(0, 0, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "⚡ NoClip Rush"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Кнопка Toggle
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(1, -20, 0, 35)
ToggleButton.Position = UDim2.new(0, 10, 0, 35)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 18
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = MainFrame
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 6)

-- Текст скорости
local SpeedText = Instance.new("TextLabel")
SpeedText.Size = UDim2.new(1, 0, 0, 20)
SpeedText.Position = UDim2.new(0, 0, 0, 80)
SpeedText.BackgroundTransparency = 1
SpeedText.Text = "Скорость: 3"
SpeedText.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedText.TextSize = 14
SpeedText.Font = Enum.Font.Gotham
SpeedText.Parent = MainFrame

-- Подсказка
local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1, 0, 0, 20)
Hint.Position = UDim2.new(0, 0, 0, 105)
Hint.BackgroundTransparency = 1
Hint.Text = "WASD / Колёсико ± скорость"
Hint.TextColor3 = Color3.fromRGB(150, 150, 150)
Hint.TextSize = 11
Hint.Font = Enum.Font.Gotham
Hint.Parent = MainFrame

-- Переменные движения
local MoveDirection = Vector3.zero
local KeysPressed = {}

-- Отслеживание WASD
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then KeysPressed.W = true
    elseif input.KeyCode == Enum.KeyCode.A then KeysPressed.A = true
    elseif input.KeyCode == Enum.KeyCode.S then KeysPressed.S = true
    elseif input.KeyCode == Enum.KeyCode.D then KeysPressed.D = true
    end
    
    -- Колёсико мыши для скорости
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Speed = math.clamp(Speed + 1, 1, 50)
        SpeedText.Text = "Скорость: " .. Speed
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
        Speed = math.clamp(Speed - 1, 1, 50)
        SpeedText.Text = "Скорость: " .. Speed
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then KeysPressed.W = false
    elseif input.KeyCode == Enum.KeyCode.A then KeysPressed.A = false
    elseif input.KeyCode == Enum.KeyCode.S then KeysPressed.S = false
    elseif input.KeyCode == Enum.KeyCode.D then KeysPressed.D = false
    end
end)

-- Расчёт направления движения
local function UpdateMoveDirection()
    local Camera = workspace.CurrentCamera
    local Direction = Vector3.zero
    
    if KeysPressed.W then Direction = Direction + Camera.CFrame.LookVector end
    if KeysPressed.S then Direction = Direction - Camera.CFrame.LookVector end
    if KeysPressed.A then Direction = Direction - Camera.CFrame.RightVector end
    if KeysPressed.D then Direction = Direction + Camera.CFrame.RightVector end
    
    if Direction.Magnitude > 0 then
        MoveDirection = Direction.Unit * Speed
    else
        MoveDirection = Vector3.zero
    end
end

-- Основная механика: рагдолл -> рывок -> анрагдолл
local function NoClipRush()
    local Character = LocalPlayer.Character
    if not Character then return end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HRP then return end
    
    UpdateMoveDirection()
    if MoveDirection.Magnitude == 0 then return end
    
    -- 1. Рагдолл
    Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    
    -- 2. Мгновенный рывок через CFrame
    task.wait(0.001) -- Микро-задержка для рагдолла
    HRP.CFrame = HRP.CFrame + MoveDirection * 0.5
    
    -- 3. Анрагдолл (возвращаем в нормальное состояние)
    task.wait(0.001)
    Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

-- Цикл NoClip
local LastStep = 0
RunService.Heartbeat:Connect(function(deltaTime)
    if not NoClipEnabled then return end
    
    if tick() - LastStep >= StepDelay then
        NoClipRush()
        LastStep = tick()
    end
end)

-- Toggle кнопка
ToggleButton.MouseButton1Click:Connect(function()
    NoClipEnabled = not NoClipEnabled
    if NoClipEnabled then
        ToggleButton.Text = "⚡ ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    else
        ToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        MoveDirection = Vector3.zero
    end
end)