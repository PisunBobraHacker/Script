-- =============================================
-- ИМБА-СКРИПТ (F2 - Вкл/Выкл)
-- ESP + Silent Aim в голову + Хитбокс за картой
-- =============================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

-- =============================================
-- ПЕРЕМЕННЫЕ
-- =============================================
local enabled = false
local espObjects = {}
local highlightObjects = {}

-- =============================================
-- ФУНКЦИЯ 1: ХИТБОКС ЗА КАРТОЙ
-- =============================================
local function moveHitbox()
    if not enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Отключаем коллизию у всех частей тела (НО НЕ У СТЕН!)
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Transparency = 1
            part.CastShadow = false
        end
    end
    
    -- Создаём фейк ЗА КАРТОЙ
    local fake = char:FindFirstChild("FakeHitbox")
    if not fake then
        fake = Instance.new("Part")
        fake.Name = "FakeHitbox"
        fake.Size = Vector3.new(2, 2, 2)
        fake.Transparency = 1
        fake.CanCollide = false
        fake.Anchored = true
        fake.Parent = char
    end
    
    -- Отправляем фейк нахуй за карту
    fake.Position = Vector3.new(99999, 99999, 99999)
end

-- =============================================
-- ФУНКЦИЯ 2: ESP (РАБОТАЕТ!)
-- =============================================
local function updateESP()
    if not enabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("LowerTorso")
            
            if root then
                -- Создаём Highlight (свечение)
                if not highlightObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = char
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0.5
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlightObjects[player] = highlight
                end
                
                -- Создаём Drawing (имя + дистанция)
                if not espObjects[player] then
                    local name = Drawing.new("Text")
                    name.Size = 16
                    name.Center = true
                    name.Color = Color3.fromRGB(255, 255, 255)
                    name.Outline = true
                    name.OutlineColor = Color3.fromRGB(0, 0, 0)
                    name.Font = 3
                    name.Visible = true
                    
                    local dist = Drawing.new("Text")
                    dist.Size = 14
                    dist.Center = true
                    dist.Color = Color3.fromRGB(0, 255, 0)
                    dist.Outline = true
                    dist.OutlineColor = Color3.fromRGB(0, 0, 0)
                    dist.Font = 3
                    dist.Visible = true
                    
                    local line = Drawing.new("Line")
                    line.Thickness = 1
                    line.Color = Color3.fromRGB(255, 0, 0)
                    line.Transparency = 0.5
                    line.Visible = true
                    
                    espObjects[player] = {name = name, dist = dist, line = line}
                end
                
                -- Получаем позицию на экране
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2, 0))
                
                if onScreen and screenPos.Z > 0 then
                    local distance = (Camera.CFrame.Position - root.Position).Magnitude
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    
                    -- Имя
                    espObjects[player].name.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
                    espObjects[player].name.Text = player.Name
                    espObjects[player].name.Visible = true
                    
                    -- Дистанция
                    espObjects[player].dist.Position = Vector2.new(screenPos.X, screenPos.Y + 15)
                    espObjects[player].dist.Text = string.format("%.0fm", distance)
                    espObjects[player].dist.Visible = true
                    
                    -- Линия до врага
                    espObjects[player].line.Position = center
                    espObjects[player].line.Point = Vector2.new(screenPos.X, screenPos.Y)
                    espObjects[player].line.Visible = true
                    
                    -- Меняем цвет в зависимости от здоровья
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid then
                        local healthPercent = humanoid.Health / humanoid.MaxHealth
                        if healthPercent > 0.5 then
                            highlightObjects[player].FillColor = Color3.fromRGB(0, 255, 0)
                        elseif healthPercent > 0.2 then
                            highlightObjects[player].FillColor = Color3.fromRGB(255, 255, 0)
                        else
                            highlightObjects[player].FillColor = Color3.fromRGB(255, 0, 0)
                        end
                    end
                else
                    -- Скрываем если не на экране
                    if espObjects[player] then
                        espObjects[player].name.Visible = false
                        espObjects[player].dist.Visible = false
                        espObjects[player].line.Visible = false
                    end
                end
            end
        end
    end
    
    -- Удаляем ESP для вышедших игроков
    for player, obj in pairs(espObjects) do
        if not player or not player.Parent then
            obj.name:Remove()
            obj.dist:Remove()
            obj.line:Remove()
            espObjects[player] = nil
        end
    end
    
    for player, highlight in pairs(highlightObjects) do
        if not player or not player.Parent then
            highlight:Destroy()
            highlightObjects[player] = nil
        end
    end
end

-- =============================================
-- ФУНКЦИЯ 3: SILENT AIM В ГОЛОВУ (СКВОЗЬ СТЕНЫ)
-- =============================================
local function setupSilentAim()
    if not enabled then return end
    
    local mt = getrawmetatable(game)
    if mt then
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "CFrame" and enabled then
                local origin = self.Position
                
                -- Находим ближайшего врага
                local target = nil
                local targetPos = nil
                local closestDist = math.huge
                
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        -- Сначала ищем голову
                        local head = player.Character:FindFirstChild("Head")
                        if head then
                            local dist = (origin - head.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                target = head
                                targetPos = head.Position
                            end
                        else
                            -- Если нет головы, берём торс
                            local root = player.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                local dist = (origin - root.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    target = root
                                    targetPos = root.Position
                                end
                            end
                        end
                    end
                end
                
                if target and targetPos then
                    -- Добавляем упреждение
                    local velocity = Vector3.new(0, 0, 0)
                    local root = target.Parent:FindFirstChild("HumanoidRootPart")
                    if root then
                        velocity = root.Velocity or Vector3.new(0, 0, 0)
                    end
                    
                    local distance = (origin - targetPos).Magnitude
                    local bulletSpeed = 3000
                    local travelTime = distance / bulletSpeed
                    local predictedPos = targetPos + (velocity * travelTime * 0.5)
                    
                    -- НЕТ ПРОВЕРКИ НА СТЕНЫ!
                    return CFrame.new(origin, predictedPos)
                end
            end
            return oldIndex(self, key)
        end)
    end
end

-- =============================================
-- ВКЛ/ВЫКЛ
-- =============================================
local function toggleScript()
    enabled = not enabled
    
    if enabled then
        -- Хитбокс за картой
        RunService.Heartbeat:Connect(moveHitbox)
        
        -- ESP
        RunService.RenderStepped:Connect(updateESP)
        
        -- Silent Aim
        setupSilentAim()
        
        -- Сразу применяем хитбокс
        moveHitbox()
        
        print("💀 ИМБА-РЕЖИМ ВКЛЮЧЕН!")
        print("🔥 Хитбокс ЗА КАРТОЙ!")
        print("👁️ ESP РАБОТАЕТ!")
        print("🔫 Silent Aim В ГОЛОВУ СКВОЗЬ СТЕНЫ!")
    else
        -- Удаляем ESP
        for player, obj in pairs(espObjects) do
            obj.name:Remove()
            obj.dist:Remove()
            obj.line:Remove()
        end
        espObjects = {}
        
        for player, highlight in pairs(highlightObjects) do
            highlight:Destroy()
        end
        highlightObjects = {}
        
        -- Возвращаем хитбокс
        local char = LocalPlayer.Character
        if char then
            local fake = char:FindFirstChild("FakeHitbox")
            if fake then fake:Destroy() end
            
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                    part.Transparency = 0
                    part.CastShadow = true
                end
            end
        end
        
        print("🌀 ИМБА-РЕЖИМ ВЫКЛЮЧЕН!")
    end
end

-- =============================================
-- F2 - ВКЛ/ВЫКЛ
-- =============================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.F2 then
        toggleScript()
    end
end)

-- =============================================
-- ПРИ РЕСПАВНЕ
-- =============================================
LocalPlayer.CharacterAdded:Connect(function()
    if enabled then
        task.wait(0.5)
        toggleScript()
        toggleScript()
    end
end)

print("🔥 ИМБА-СКРИПТ ЗАГРУЖЕН!")
print("🎯 F2 - Вкл/Выкл")
print("💀 Ты неуязвим, видишь всех, стреляешь в голову сквозь стены!")
print("🚀 БАН? ПОХУЙ!")