-- =============================================
-- ЕБАНУТАЯ КРЫТИЛКА + ПОЛЁТ v2.0
-- Крытилка и полёт работают отдельно
-- =============================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- =============================================
-- ПЕРЕМЕННЫЕ
-- =============================================
local antiAimEnabled = false
local flyEnabled = false
local connection = nil
local flyConnection = nil
local mode = "Chaos"
local speed = 15
local intensity = 90
local flySpeed = 50

-- =============================================
-- ФУНКЦИЯ КРЫТИЛКИ (ТОЛЬКО ХИТБОКС)
-- =============================================
local function applyAntiAim()
    if not antiAimEnabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LowerTorso")
    local head = char:FindFirstChild("Head")
    
    if not root then return end
    
    -- СОХРАНЯЕМ ПОЗИЦИЮ (НЕ МЕНЯЕМ!)
    local pos = root.Position
    local t = tick() * speed * 0.1
    local maxAngle = math.rad(intensity)
    
    -- МЕНЯЕМ ТОЛЬКО УГЛЫ (НЕ ПОЗИЦИЮ!)
    if mode == "Chaos" then
        local angleX = math.sin(t * 0.7) * maxAngle
        local angleY = math.cos(t * 1.3) * maxAngle * 1.5
        local angleZ = math.sin(t * 2.1) * maxAngle * 0.5
        
        if math.sin(t * 0.5) > 0.8 then
            angleY = angleY + maxAngle
        end
        
        local offset = CFrame.Angles(angleX, angleY, angleZ)
        root.CFrame = CFrame.new(pos) * offset
        
    elseif mode == "Spin" then
        local angleY = t * 2
        local angleX = math.sin(t * 0.3) * maxAngle * 0.3
        local angleZ = math.cos(t * 0.4) * maxAngle * 0.2
        
        local offset = CFrame.Angles(angleX, angleY, angleZ)
        root.CFrame = CFrame.new(pos) * offset
        
    elseif mode == "Twitch" then
        local twitch = math.floor(t / 0.2) % 2 == 0 and 1 or -1
        local angleX = twitch * maxAngle * 0.5
        local angleY = math.sin(t * 0.5) * maxAngle * 1.5
        local angleZ = twitch * maxAngle * 0.2
        
        local offset = CFrame.Angles(angleX, angleY, angleZ)
        root.CFrame = CFrame.new(pos) * offset
        
    elseif mode == "Random" then
        local seed = tick() * 0.1
        local angleX = math.sin(seed * 1.3) * maxAngle
        local angleY = math.cos(seed * 2.7) * maxAngle * 1.5
        local angleZ = math.sin(seed * 0.9) * maxAngle * 0.4
        
        local offset = CFrame.Angles(angleX, angleY, angleZ)
        root.CFrame = CFrame.new(pos) * offset
    end
    
    -- Дёргаем голову
    if head then
        head.CFrame = head.CFrame * CFrame.Angles(
            math.sin(t * 1.7) * 0.3,
            math.cos(t * 0.9) * 0.3,
            math.sin(t * 2.3) * 0.2
        )
    end
end

-- =============================================
-- ФУНКЦИЯ ПОЛЁТА (ТОЛЬКО ПОЗИЦИЯ)
-- =============================================
local function applyFly()
    if not flyEnabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LowerTorso")
    if not root then return end
    
    -- Отключаем гравитацию
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
    
    -- Управление полётом
    local moveVector = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
        moveVector = moveVector + (Camera.CFrame.LookVector * flySpeed)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then 
        moveVector = moveVector - (Camera.CFrame.LookVector * flySpeed)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then 
        moveVector = moveVector - (Camera.CFrame.RightVector * flySpeed)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then 
        moveVector = moveVector + (Camera.CFrame.RightVector * flySpeed)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then 
        moveVector = moveVector + Vector3.new(0, flySpeed, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then 
        moveVector = moveVector + Vector3.new(0, -flySpeed, 0)
    end
    
    -- Передвигаем (НЕ МЕНЯЕМ УГЛЫ!)
    root.CFrame = root.CFrame + (moveVector * 0.1)
    root.Velocity = Vector3.new(0, 0, 0) -- Убираем инерцию
end

-- =============================================
-- ФУНКЦИИ ВКЛЮЧЕНИЯ
-- =============================================

-- Вкл/Выкл крытилку
local function toggleAntiAim()
    antiAimEnabled = not antiAimEnabled
    
    if antiAimEnabled then
        if not connection then
            connection = RunService.Heartbeat:Connect(applyAntiAim)
        end
        print("🌀 Ебанутая крытилка ВКЛЮЧЕНА!")
    else
        if connection then
            connection:Disconnect()
            connection = nil
        end
        -- Возвращаем хитбокс в норму
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LowerTorso")
            if root then
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, 0)
            end
        end
        print("🌀 Ебанутая крытилка ВЫКЛЮЧЕНА!")
    end
end

-- Вкл/Выкл полёт
local function toggleFly()
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        if not flyConnection then
            flyConnection = RunService.RenderStepped:Connect(applyFly)
        end
        -- Отключаем гравитацию
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = true
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.Anchored = false
            end
        end
        print("✈️ Полёт ВКЛЮЧЕН!")
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        -- Включаем гравитацию
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
        end
        print("✈️ Полёт ВЫКЛЮЧЕН!")
    end
end

-- =============================================
-- МЕНЮ
-- =============================================
local function createMenu()
    -- Создаём ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiAimMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    -- Главная рамка
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 420)
    frame.Position = UDim2.new(0.5, -140, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 100)
    frame.ClipsDescendants = true
    frame.Parent = screenGui

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
    title.BackgroundTransparency = 0.3
    title.Text = "🔥 ЕБАНУТАЯ КРЫТИЛКА"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    -- Контейнер для кнопок
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 1, -50)
    container.Position = UDim2.new(0, 10, 0, 45)
    container.BackgroundTransparency = 1
    container.Parent = frame

    -- Создаём кнопку
    local function createButton(text, callback, color)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 35)
        button.Position = UDim2.new(0, 0, 0, #container:GetChildren() * 40)
        button.BackgroundColor3 = color or Color3.fromRGB(30, 30, 50)
        button.BackgroundTransparency = 0.2
        button.BorderSizePixel = 1
        button.BorderColor3 = Color3.fromRGB(255, 0, 100)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.GothamMedium
        button.AutoButtonColor = false
        button.Parent = container

        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.3), {
                BackgroundTransparency = 0.1,
                BackgroundColor3 = Color3.fromRGB(60, 30, 80)
            }):Play()
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.3), {
                BackgroundTransparency = 0.2,
                BackgroundColor3 = color or Color3.fromRGB(30, 30, 50)
            }):Play()
        end)

        button.MouseButton1Click:Connect(function()
            callback()
            TweenService:Create(button, TweenInfo.new(0.1), {
                BackgroundTransparency = 0.5
            }):Play()
            task.wait(0.1)
            TweenService:Create(button, TweenInfo.new(0.1), {
                BackgroundTransparency = 0.2
            }):Play()
        end)

        return button
    end

    -- Создаём выпадающий список
    local function createDropdown(options, callback)
        local dropdown = Instance.new("Frame")
        dropdown.Size = UDim2.new(1, 0, 0, 35)
        dropdown.Position = UDim2.new(0, 0, 0, #container:GetChildren() * 40 + 5)
        dropdown.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
        dropdown.BackgroundTransparency = 0.2
        dropdown.BorderSizePixel = 1
        dropdown.BorderColor3 = Color3.fromRGB(100, 100, 200)
        dropdown.Parent = container

        local currentText = Instance.new("TextLabel")
        currentText.Size = UDim2.new(1, -10, 1, 0)
        currentText.Position = UDim2.new(0, 5, 0, 0)
        currentText.BackgroundTransparency = 1
        currentText.Text = options[1]
        currentText.TextColor3 = Color3.fromRGB(255, 255, 255)
        currentText.TextScaled = true
        currentText.TextXAlignment = Enum.TextXAlignment.Left
        currentText.Font = Enum.Font.GothamMedium
        currentText.Parent = dropdown

        local dropdownActive = false
        local optionContainer = Instance.new("Frame")
        optionContainer.Size = UDim2.new(1, 0, 0, 0)
        optionContainer.Position = UDim2.new(0, 0, 1, 0)
        optionContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
        optionContainer.BackgroundTransparency = 0.9
        optionContainer.BorderSizePixel = 1
        optionContainer.BorderColor3 = Color3.fromRGB(100, 100, 200)
        optionContainer.ClipsDescendants = true
        optionContainer.Visible = false
        optionContainer.Parent = dropdown

        dropdown.MouseButton1Click:Connect(function()
            dropdownActive = not dropdownActive
            optionContainer.Visible = dropdownActive
            if dropdownActive then
                optionContainer.Size = UDim2.new(1, 0, 0, #options * 35)
            else
                optionContainer.Size = UDim2.new(1, 0, 0, 0)
            end
        end)

        for i, option in ipairs(options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Size = UDim2.new(1, 0, 0, 35)
            optionButton.Position = UDim2.new(0, 0, 0, (i - 1) * 35)
            optionButton.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            optionButton.BackgroundTransparency = 0.2
            optionButton.BorderSizePixel = 0
            optionButton.Text = option
            optionButton.TextColor3 = Color3.fromRGB(200, 200, 255)
            optionButton.TextScaled = true
            optionButton.Font = Enum.Font.GothamMedium
            optionButton.Parent = optionContainer

            optionButton.MouseEnter:Connect(function()
                optionButton.BackgroundTransparency = 0.1
            end)

            optionButton.MouseLeave:Connect(function()
                optionButton.BackgroundTransparency = 0.2
            end)

            optionButton.MouseButton1Click:Connect(function()
                currentText.Text = option
                callback(option)
                dropdownActive = false
                optionContainer.Visible = false
                optionContainer.Size = UDim2.new(1, 0, 0, 0)
            end)
        end

        return dropdown
    end

    -- =============================================
    -- СОЗДАЁМ ЭЛЕМЕНТЫ МЕНЮ
    -- =============================================

    -- Кнопка крытилки
    local antiButton = createButton("🌀 КРЫТИЛКА (F1)", function()
        toggleAntiAim()
        antiButton.Text = antiAimEnabled and "🌀 КРЫТИЛКА ВЫКЛ (F1)" or "🌀 КРЫТИЛКА (F1)"
        antiButton.BackgroundColor3 = antiA