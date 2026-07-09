-- =============================================
-- ЕБАНУТАЯ КРЫТИЛКА v1.0
-- Меняет только твой хитбокс
-- Чужие хитбоксы не трогает
-- Камера не трогается
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
local connection = nil
local mode = "Chaos"  -- "Chaos", "Spin", "Twitch", "Random"
local speed = 15
local intensity = 90

-- =============================================
-- ФУНКЦИЯ КРЫТИЛКИ (Меняет только твой хитбокс)
-- =============================================
local function applyAntiAim()
    if not antiAimEnabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- БЕРЁМ ТОЛЬКО СВОЙ ХИТБОКС
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LowerTorso")
    local head = char:FindFirstChild("Head")
    
    if not root then return end
    
    local t = tick() * speed * 0.1
    local pos = root.Position
    local maxAngle = math.rad(intensity)
    
    -- =============================================
    -- РЕЖИМЫ КРЫТИЛКИ
    -- =============================================
    
    if mode == "Chaos" then
        -- Полный хаос (меняет всё рандомно)
        local angleX = math.sin(t * 0.7) * maxAngle
        local angleY = math.cos(t * 1.3) * maxAngle * 1.5
        local angleZ = math.sin(t * 2.1) * maxAngle * 0.5
        
        -- Резкие скачки
        if math.sin(t * 0.5) > 0.8 then
            angleY = angleY + maxAngle
        end
        
        local offset = CFrame.Angles(angleX, angleY, angleZ)
        root.CFrame = CFrame.new(pos) * offset
        
    elseif mode == "Spin" then
        -- Бесконечное вращение
        local angleY = t * 2
        local angleX = math.sin(t * 0.3) * maxAngle * 0.3
        local angleZ = math.cos(t * 0.4) * maxAngle * 0.2
        
        local offset = CFrame.Angles(angleX, angleY, angleZ)
        root.CFrame = CFrame.new(pos) * offset
        
    elseif mode == "Twitch" then
        -- Резкие дёрганья
        local twitch = math.floor(t / 0.2) % 2 == 0 and 1 or -1
        local angleX = twitch * maxAngle * 0.5
        local angleY = math.sin(t * 0.5) * maxAngle * 1.5
        local angleZ = twitch * maxAngle * 0.2
        
        local offset = CFrame.Angles(angleX, angleY, angleZ)
        root.CFrame = CFrame.new(pos) * offset
        
    elseif mode == "Random" then
        -- Абсолютный рандом
        local seed = tick() * 0.1
        local angleX = math.sin(seed * 1.3) * maxAngle
        local angleY = math.cos(seed * 2.7) * maxAngle * 1.5
        local angleZ = math.sin(seed * 0.9) * maxAngle * 0.4
        
        local offset = CFrame.Angles(angleX, angleY, angleZ)
        root.CFrame = CFrame.new(pos) * offset
    end
    
    -- Дёргаем голову (тоже только свою)
    if head then
        head.CFrame = head.CFrame * CFrame.Angles(
            math.sin(t * 1.7) * 0.3,
            math.cos(t * 0.9) * 0.3,
            math.sin(t * 2.3) * 0.2
        )
    end
end

-- =============================================
-- ФУНКЦИЯ ВКЛЮЧЕНИЯ
-- =============================================
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
            local head = char:FindFirstChild("Head")
            if head then
                head.CFrame = CFrame.new(head.Position) * CFrame.Angles(0, 0, 0)
            end
        end
        print("🌀 Ебанутая крытилка ВЫКЛЮЧЕНА!")
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
    frame.Size = UDim2.new(0, 280, 0, 320)
    frame.Position = UDim2.new(0.5, -140, 0.5, -160)
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

        -- Эффекты
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

    -- Создаём выпадающий список (Dropdown)
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

    -- Toggle кнопка
    local toggleButton = createButton("🌀 ВКЛЮЧИТЬ КРЫТИЛКУ", function()
        toggleAntiAim()
        toggleButton.Text = antiAimEnabled and "🌀 ВЫКЛЮЧИТЬ КРЫТИЛКУ" or "🌀 ВКЛЮЧИТЬ КРЫТИЛКУ"
        toggleButton.BackgroundColor3 = antiAimEnabled and Color3.fromRGB(100, 0, 0) or Color3.fromRGB(30, 30, 50)
    end, Color3.fromRGB(30, 30, 50))

    -- Выбор режима
    createDropdown({"Chaos", "Spin", "Twitch", "Random"}, function(value)
        mode = value
        print("🌀 Режим изменён на: " .. value)
    end)

    -- Ползунок скорости
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, 0, 0, 20)
    speedLabel.Position = UDim2.new(0, 0, 0, #container:GetChildren() * 40 + 10)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "Скорость: " .. speed
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    speedLabel.TextScaled = true
    speedLabel.Font = Enum.Font.GothamMedium
    speedLabel.Parent = container

    local speedSlider = Instance.new("Frame")
    speedSlider.Size = UDim2.new(1, 0, 0, 20)
    speedSlider.Position = UDim2.new(0, 0, 0, #container:GetChildren() * 40 + 32)
    speedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    speedSlider.BackgroundTransparency = 0.5
    speedSlider.BorderSizePixel = 0
    speedSlider.Parent = container

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((speed - 5) / 25, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = speedSlider

    speedSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local mousePos = UserInputService:GetMouseLocation()
                local sliderPos = speedSlider.AbsolutePosition
                local percent = math.clamp((mousePos.X - sliderPos.X) / speedSlider.AbsoluteSize.X, 0, 1)
                speed = math.floor(percent * 25 + 5)
                sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                speedLabel.Text = "Скорость: " .. speed
                task.wait()
            end
        end
    end)

    -- Ползунок интенсивности
    local intensityLabel = Instance.new("TextLabel")
    intensityLabel.Size = UDim2.new(1, 0, 0, 20)
    intensityLabel.Position = UDim2.new(0, 0, 0, #container:GetChildren() * 40 + 55)
    intensityLabel.BackgroundTransparency = 1
    intensityLabel.Text = "Интенсивность: " .. intensity
    intensityLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    intensityLabel.TextScaled = true
    intensityLabel.Font = Enum.Font.GothamMedium
    intensityLabel.Parent = container

    local intensitySlider = Instance.new("Frame")
    intensitySlider.Size = UDim2.new(1, 0, 0, 20)
    intensitySlider.Position = UDim2.new(0, 0, 0, #container:GetChildren() * 40 + 77)
    intensitySlider.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    intensitySlider.BackgroundTransparency = 0.5
    intensitySlider.BorderSizePixel = 0
    intensitySlider.Parent = container

    local intensityFill = Instance.new("Frame")
    intensityFill.Size = UDim2.new((intensity - 30) / 150, 0, 1, 0)
    intensityFill.BackgroundColor3 = Color3.fromRGB(255, 0, 200)
    intensityFill.BorderSizePixel = 0
    intensityFill.Parent = intensitySlider

    intensitySlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local mousePos = UserInputService:GetMouseLocation()
                local sliderPos = intensitySlider.AbsolutePosition
                local percent = math.clamp((mousePos.X - sliderPos.X) / intensitySlider.AbsoluteSize.X, 0, 1)
                intensity = math.floor(percent * 150 + 30)
                intensityFill.Size = UDim2.new(percent, 0, 1, 0)
                intensityLabel.Text = "Интенсивность: " .. intensity
                task.wait()
            end
        end
    end)

    -- Обновляем размер контейнера
    container.Size = UDim2.new(1, -20, 0, #container:GetChildren() * 40 + 100)
    frame.Size = UDim2.new(0, 280, 0, #container:GetChildren() * 40 + 150)

    -- =============================================
    -- ПЕРЕТАСКИВАНИЕ МЕНЮ
    -- =============================================
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- =============================================
    -- ГОРЯЧИЕ КЛАВИШИ
    -- =============================================
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        -- F1 - Вкл/Выкл крытилку
        if input.KeyCode == Enum.KeyCode.F1 then
            toggleAntiAim()
            toggleButton.Text = antiAimEnabled and "🌀 ВЫКЛЮЧИТЬ КРЫТИЛКУ" or "🌀 ВКЛЮЧИТЬ КРЫТИЛКУ"
            toggleButton.BackgroundColor3 = antiAimEnabled and Color3.fromRGB(100, 0, 0) or Color3.fromRGB(30, 30, 50)
        end
        
        -- F2 - Скрыть/Показать меню
        if input.KeyCode == Enum.KeyCode.F2 then
            frame.Visible = not frame.Visible
        end
    end)

    print("✅ Меню создано!")
    print("🔄 F1 - Вкл/Выкл крытилку")
    print("🔄 F2 - Скрыть/Показать меню")
end

-- =============================================
-- ЗАПУСК
-- =============================================
task.wait(1)
createMenu()

print("🔥 ЕБАНУТАЯ КРЫТИЛКА ЗАГРУЖЕНА!")
print("💀 Твой хитбокс теперь НЕПРЕДСКАЗУЕМ!")
print("🎯 Читеры и обычные игроки НЕ ПОПАДУТ!")