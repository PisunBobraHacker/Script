-- =============================================
-- ЕБАНУТАЯ КРЫТИЛКА v1.0
-- F2 - Вкл/Выкл
-- =============================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- =============================================
-- НАСТРОЙКИ
-- =============================================
local mode = "Chaos"  -- Chaos, Spin, Twitch, Random
local speed = 15
local intensity = 90

-- =============================================
-- ПЕРЕМЕННЫЕ
-- =============================================
local enabled = false
local connection = nil

-- =============================================
-- КРЫТИЛКА
-- =============================================
local function applyAntiAim()
    if not enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LowerTorso")
    local head = char:FindFirstChild("Head")
    
    if not root then return end
    
    local pos = root.Position
    local t = tick() * speed * 0.1
    local maxAngle = math.rad(intensity)
    
    if mode == "Chaos" then
        local angleX = math.sin(t * 0.7) * maxAngle
        local angleY = math.cos(t * 1.3) * maxAngle * 1.5
        local angleZ = math.sin(t * 2.1) * maxAngle * 0.5
        
        if math.sin(t * 0.5) > 0.8 then
            angleY = angleY + maxAngle
        end
        
        root.CFrame = CFrame.new(pos) * CFrame.Angles(angleX, angleY, angleZ)
        
    elseif mode == "Spin" then
        local angleY = t * 2
        local angleX = math.sin(t * 0.3) * maxAngle * 0.3
        local angleZ = math.cos(t * 0.4) * maxAngle * 0.2
        
        root.CFrame = CFrame.new(pos) * CFrame.Angles(angleX, angleY, angleZ)
        
    elseif mode == "Twitch" then
        local twitch = math.floor(t / 0.2) % 2 == 0 and 1 or -1
        local angleX = twitch * maxAngle * 0.5
        local angleY = math.sin(t * 0.5) * maxAngle * 1.5
        local angleZ = twitch * maxAngle * 0.2
        
        root.CFrame = CFrame.new(pos) * CFrame.Angles(angleX, angleY, angleZ)
        
    elseif mode == "Random" then
        local seed = tick() * 0.1
        local angleX = math.sin(seed * 1.3) * maxAngle
        local angleY = math.cos(seed * 2.7) * maxAngle * 1.5
        local angleZ = math.sin(seed * 0.9) * maxAngle * 0.4
        
        root.CFrame = CFrame.new(pos) * CFrame.Angles(angleX, angleY, angleZ)
    end
    
    if head then
        head.CFrame = head.CFrame * CFrame.Angles(
            math.sin(t * 1.7) * 0.3,
            math.cos(t * 0.9) * 0.3,
            math.sin(t * 2.3) * 0.2
        )
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
        print("🌀 КРЫТИЛКА ВКЛЮЧЕНА!")
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

print("🔥 ЕБАНУТАЯ КРЫТИЛКА ЗАГРУЖЕНА!")
print("🎯 F2 - Вкл/Выкл")
print("💀 Читеры и обычные игроки НЕ ПОПАДУТ!")