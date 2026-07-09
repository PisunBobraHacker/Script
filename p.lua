-- =============================================
-- АБСОЛЮТНЫЙ ИМБА-СКРИПТ
-- F2 - Вкл/Выкл
-- ESP + Silent Aim сквозь стены + Хитбокс за картой
-- =============================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- =============================================
-- ПЕРЕМЕННЫЕ
-- =============================================
local enabled = false
local connection = nil
local espConnection = nil
local silentConnection = nil
local espObjects = {}

-- =============================================
-- ФУНКЦИЯ 1: ХИТБОКС ЗА КАРТОЙ
-- =============================================
local function hideHitbox()
    if not enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Прячем все части тела
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.CanCollide = false
            part.CastShadow = false
        end
    end
    
    -- Создаём фейк за картой
    local fakeRoot = char:FindFirstChild("FakeRoot")
    if not fakeRoot then
        fakeRoot = Instance.new("Part")
        fakeRoot.Name = "FakeRoot"
        fakeRoot.Size = Vector3.new(5, 5, 5)
        fakeRoot.Transparency = 1
        fakeRoot.CanCollide = false
        fakeRoot.Anchored = true
        fakeRoot.Parent = char
    end
    
    -- Отправляем за карту
    fakeRoot.Position = Vector3.new(99999, 99999, 99999)
end

-- =============================================
-- ФУНКЦИЯ 2: ESP (ВСЕХ ВИДНО)
-- =============================================
local function updateESP()
    if not enabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if root then
                -- Создаём ESP объекты
                if not espObjects[player] then
                    -- Коробка
                    local box = Drawing.new("Box")
                    box.Thickness = 2
                    box.Color = Color3.fromRGB(255, 0, 0)
                    box.Transparency = 0.5
                    box.Visible = true
                    
                    -- Имя
                    local name = Drawing.new("Text")
                    name.Size = 14
                    name.Center = true
                    name.Color = Color3.fromRGB(255, 255, 255)
                    name.Outline = true
                    name.Font = 2
                    name.Visible = true
                    
                    -- Дистанция
                    local dist = Drawing.new("Text")
                    dist.Size = 12
                    dist.Center = true
                    dist.Color = Color3.fromRGB(0, 255, 0)
                    dist.Outline = true
                    dist.Font = 2
                    dist.Visible = true
                    
                    espObjects[player] = {box = box, name = name, dist = dist}
                end
                
                -- Получаем позицию на экране
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                
                if onScreen and screenPos.Z > 0 then
                    local distance = (Camera.CFrame.Position - root.Position).Magnitude
                    local boxSize = 1000 / screenPos.Z
                    
                    -- Обновляем коробку
                    espObjects[player].box.Position = Vector2.new(
                        screenPos.X - boxSize / 2,
                        screenPos.Y - boxSize
                    )
                    espObjects[player].box.Size = Vector2.new(boxSize, boxSize * 2)
                    espObjects[player].box.Visible = true
                    espObjects[player].box.Color = player.TeamColor and player.TeamColor.Color or Color3.fromRGB(255, 0, 0)
                    
                    -- Обновляем имя
                    espObjects[player].name.Position = Vector2.new(screenPos.X, screenPos.Y - boxSize - 15)
                    espObjects[player].name.Text = player.Name
                    espObjects[player].name.Visible = true
                    
                    -- Обновляем дистанцию
                    espObjects[player].dist.Position = Vector2.new(screenPos.X, screenPos.Y + boxSize + 5)
                    espObjects[player].dist.Text = string.format("%.0fm", distance)
                    espObjects[player].dist.Visible = true
                    
                    -- Линия до врага (для читеров)
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    if espObjects[player].line then
                        espObjects[player].line.Position = center
                        espObjects[player].line.Point = Vector2.new(screenPos.X, screenPos.Y)
                    else
                        local line = Drawing.new("Line")
                        line.Thickness = 1
                        line.Color = Color3.fromRGB(255, 0, 0)
                        line.Transparency = 0.3
                        line.Visible = true
                        line.Position = center
                        line.Point = Vector2.new(screenPos.X, screenPos.Y)
                        espObjects[player].line = line
                    end
                else
                    -- Скрываем если не на экране
                    espObjects[player].box.Visible = false
                    espObjects[player].name.Visible = false
                    espObjects[player].dist.Visible = false
                    if espObjects[player].line then
                        espObjects[player].line.Visible = false
                    end
                end
            end
        end
    end
    
    -- Удаляем ESP для игроков, которых больше нет
    for player, obj in pairs(espObjects) do
        if not player or not player.Parent then
            obj.box:Remove()
            obj.name:Remove()
            obj.dist:Remove()
            if obj.line then obj.line:Remove() end
            espObjects[player] = nil
        end
    end
end

-- =============================================
-- ФУНКЦИЯ 3: SILENT AIM СКВОЗЬ СТЕНЫ (ИМБА)
-- =============================================
local function setupSilentAim()
    if not enabled then return end
    
    local mt = getrawmetatable(game)
    if mt then
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "CFrame" and enabled then
                local origin = self.Position
                
                -- Находим ближайшего врага (по центру экрана)
                local closest = nil
                local closestDist = math.huge
                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local root = player.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closest = root
                                end
                            end
                        end
                    end
                end
                
                if closest then
                    -- Целимся в голову (с упреждением)
                    local target = closest.Parent:FindFirstChild("Head") or closest
                    local targetPos = target.Position
                    
                    -- Упреждение (для движущихся целей)
                    local velocity = closest.Velocity or Vector3.new(0, 0, 0)
                    local distance = (origin - targetPos).Magnitude
                    local bulletSpeed = 3000
                    local travelTime = distance / bulletSpeed
                    targetPos = targetPos + (velocity * travelTime * 0.5)
                    
                    -- НЕТ ПРОВЕРКИ НА СТЕНЫ! (имба)
                    return CFrame.new(origin, targetPos)
                end
            end
            return oldIndex(self, key)
        end)
    end
end

-- =============================================
-- ВКЛ/ВЫКЛ
-- =============================================
local function toggleAntiAim()
    enabled = not enabled
    
    if enabled then
        -- Хитбокс за картой
        if not connection then
            connection = RunService.Heartbeat:Connect(hideHitbox)
        end
        
        -- ESP
        if not espConnection then
            espConnection = RunService.RenderStepped:Connect(updateESP)
        end
        
        -- Silent Aim сквозь стены
        setupSilentAim()
        
        print("💀 ИМБА-РЕЖИМ ВКЛЮЧЕН!")
        print("🔥 Хитбокс ЗА КАРТОЙ!")
        print("👁️ ESP ВКЛЮЧЕН!")
        print("🔫 Silent Aim СКВОЗЬ СТЕНЫ!")
        print("🎯 Ты неуязвим и видишь всех!")
    else
        -- Выключаем всё
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        
        -- Удаляем ESP
        for player, obj in pairs(espObjects) do
            obj.box:Remove()
            obj.name:Remove()
            obj.dist:Remove()
            if obj.line then obj.line:Remove() end
        end
        espObjects = {}
        
        -- Возвращаем хитбокс
        local char = LocalPlayer.Character
        if char then
            local fake = char:FindFirstChild("FakeRoot")
            if fake then fake:Destroy() end
            
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                    part.CanCollide = true
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
        toggleAntiAim()
    end
end)

-- =============================================
-- ОБРАБОТЧИК РЕСПАВНА
-- =============================================
LocalPlayer.CharacterAdded:Connect(function()
    if enabled then
        task.wait(0.5)
        toggleAntiAim()
        toggleAntiAim()
    end
end)

print("🔥 АБСОЛЮТНЫЙ ИМБА-СКРИПТ ЗАГРУЖЕН!")
print("🎯 F2 - Вкл/Выкл")
print("💀 Ты неуязвим, видишь всех, стреляешь сквозь стены!")
print("🚀 БАН? ПОХУЙ!")