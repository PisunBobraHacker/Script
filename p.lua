-- =============================================
-- ЕБАНУТАЯ КРЫТИЛКА С РАЗРЫВОМ ХИТБОКСА
-- F2 - Вкл/Выкл
-- Твоя модель крутится, хитбокс в другом месте
-- =============================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- =============================================
-- НАСТРОЙКИ
-- =============================================
local mode = "Spin"  -- Spin, Jitter, Desync, Chaos
local speed = 20
local offsetDistance = 5  -- На сколько хитбокс отрывается от модели

-- =============================================
-- ПЕРЕМЕННЫЕ
-- =============================================
local enabled = false
local connection = nil

-- =============================================
-- КРЫТИЛКА С РАЗРЫВОМ
-- =============================================
local function applyAntiAim()
    if not enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Основные части
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    
    if not root then return end
    
    local t = tick() * speed * 0.1
    local pos = root.Position
    
    -- =============================================
    -- КРУТИМ МОДЕЛЬ (она ебануто вращается)
    -- =============================================
    
    if mode == "Spin" then
        -- Бесконечное вращение как юла
        local angleY = t * 3
        local angleX = math.sin(t * 0.5) * 0.3
        local angleZ = math.cos(t * 0.7) * 0.2
        
        root.CFrame = CFrame.new(pos) * CFrame.Angles(angleX, angleY, angleZ)
        
        -- Голова крутится в другую сторону (для эффекта)
        if head then
            head.CFrame = head.CFrame * CFrame.Angles(0, math.sin(t * 2) * 0.5, 0)
        end
        
    elseif mode == "Jitter" then
        -- Резкие дёрганья + вращение
        local twitch = math.floor(t / 0.15) % 2 == 0 and 1 or -1
        local angleY = t * 5 + twitch * 0.5
        local angleX = twitch * 0.5 + math.sin(t * 0.7) * 0.3
        local angleZ = twitch * 0.3 + math.cos(t * 0.5) * 0.2
        
        root.CFrame = CFrame.new(pos) * CFrame.Angles(angleX, angleY, angleZ)
        
    elseif mode == "Desync" then
        -- Разрыв между головой и телом (десинхрон)
        local angleY = t * 2
        local angleX = math.sin(t * 0.3) * 0.5
        local angleZ = math.cos(t * 0.4) * 0.3
        
        root.CFrame = CFrame.new(pos) * CFrame.Angles(angleX, angleY, angleZ)
        
        -- Голова смотрит в другую сторону
        if head then
            local headAngle = t * 1.5 + math.pi
            head.CFrame = head.CFrame * CFrame.Angles(0, headAngle, 0)
        end
        
        -- Торс тоже дёргается отдельно
        if torso then
            torso.CFrame = torso.CFrame * CFrame.Angles(
                math.sin(t * 0.7) * 0.3,
                math.cos(t * 0.5) * 0.3,
                math.sin(t * 0.9) * 0.2
            )
        end
        
    elseif mode == "Chaos" then
        -- Полный хаос (всё крутится рандомно)
        local angleX = math.sin(t * 0.7) * 1.5
        local angleY = math.cos(t * 1.3) * 3
        local angleZ = math.sin(t * 2.1) * 0.5
        
        root.CFrame = CFrame.new(pos) * CFrame.Angles(angleX, angleY, angleZ)
        
        if head then
            head.CFrame = head.CFrame * CFrame.Angles(
                math.sin(t * 1.7) * 0.5,
                math.cos(t * 0.9) * 0.5,
                math.sin(t * 2.3) * 0.3
            )
        end
        
        if torso then
            torso.CFrame = torso.CFrame * CFrame.Angles(
                math.sin(t * 1.1) * 0.4,
                math.cos(t * 0.8) * 0.4,
                math.sin(t * 1.5) * 0.3
            )
        end
    end
    
    -- =============================================
    -- РАЗРЫВ ХИТБОКСА (хитбокс в другом месте)
    -- =============================================
    
    -- Создаём невидимую часть, которая будет хитбоксом
    local fakeHitbox = char:FindFirstChild("FakeHitbox")
    if not fakeHitbox then
        fakeHitbox = Instance.new("Part")
        fakeHitbox.Name = "FakeHitbox"
        fakeHitbox.Size = Vector3.new(2, 2, 2)
        fakeHitbox.Transparency = 1
        fakeHitbox.CanCollide = false
        fakeHitbox.Anchored = true
        fakeHitbox.Parent = char
    end
    
    -- Хитбокс летает вокруг модели
    local angle = t * 2
    local radius = offsetDistance
    fakeHitbox.Position = pos + Vector3.new(
        math.cos(angle) * radius,
        math.sin(angle * 0.5) * 2,
        math.sin(angle) * radius
    )
    
    -- =============================================
    -- ПЕРЕНАПРАВЛЯЕМ УРОН НА ФЕЙКОВЫЙ ХИТБОКС
    -- =============================================
    
    -- Отключаем коллизию у реальных частей
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "FakeHitbox" then
            part.CanCollide = false
        end
    end
    
    -- У реальных частей делаем прозрачность (для эффекта)
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "FakeHitbox" then
            part.Transparency = 0.3
        end
    end
end

-- =============================================
-- ВКЛ/ВЫКЛ
-- =============================================
local function toggleAntiAim()
    enabled = not enabled
    
    if enabled then
        if not connection then
            connection = RunService.Heartbeat:Connect(applyAntiAim)
        end
        print("🌀 ЕБАНУТАЯ КРЫТИЛКА ВКЛЮЧЕНА!")
        print("💀 Ты крутишься, хитбокс в другом месте!")
    else
        if connection then
            connection:Disconnect()
            connection = nil
        end
        -- Возвращаем всё в норму
        local char = LocalPlayer.Character
        if char then
            -- Удаляем фейковый хитбокс
            local fake = char:FindFirstChild("FakeHitbox")
            if fake then fake:Destroy() end
            
            -- Возвращаем коллизию и прозрачность
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                    part.Transparency = 0
                end
            end
            
            -- Возвращаем нормальное положение
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, 0, 0)
            end
        end
        print("🌀 КРЫТИЛКА ВЫКЛЮЧЕНА!")
    end
end

-- =============================================
-- F2 - ВКЛ/ВЫКЛ
-- =============================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.F2 then
        toggleAntiAim()
    end
end)

print("🔥 ЕБАНУТАЯ КРЫТИЛКА С РАЗРЫВОМ ЗАГРУЖЕНА!")
print("🎯 F2 - Вкл/Выкл")
print("💀 Ты крутишься как юла, хитбокс отдельно!")