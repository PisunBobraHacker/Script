-- // Steal a Brainrot — Full Script v5 for Xeno
-- // Speed Hack, NoClip (walls only), Anti TP Back, ESP, Void Touch Select, AutoSteal, Lock Base

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then playerGui = game:GetService("CoreGui") end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Состояния
local invisible = false
local noclip = false
local antihit = false
local voidtouch = false
local autosteal = false
local speedhack = false
local baseLocked = false
local espEnabled = false
local selectedPlayer = nil
local speedMultiplier = 2

local noclipConn, antihitConn, voidtouchConn = nil, nil, nil
local oldWalkSpeed = 16

-- ==================== ФУНКЦИИ ====================

-- INVISIBLE
local function setInvisible(state)
    invisible = state
    if not Character then return end
    local t = state and 1 or 0
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = t
        elseif part:IsA("Decal") then
            part.Transparency = t
        end
    end
end

-- NOCLIP (только сквозь стены, не сквозь пол)
local function setNoClip(state)
    noclip = state
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if not Character or not HumanoidRootPart then return end
            
            -- Получаем направление движения
            local moveDir = Humanoid.MoveDirection
            if moveDir.Magnitude < 0.1 then return end
            
            -- Позиция перед игроком
            local rayOrigin = HumanoidRootPart.Position
            local rayDirection = moveDir * 3
            
            -- Проверяем что впереди
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {Character}
            
            local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
            
            if rayResult then
                local hitPart = rayResult.Instance
                local hitNormal = rayResult.Normal
                
                -- Если стена (вертикальная поверхность) - проходим
                if math.abs(hitNormal.Y) < 0.3 then
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                else
                    -- Пол или потолок - не проходим
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            else
                -- Нет препятствий - включаем коллизию обратно
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if Character then
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ANTI TP BACK (защита от телепорта обратно игрой)
local function antiTPBack()
    spawn(function()
        while Character and HumanoidRootPart do
            local currentPos = HumanoidRootPart.Position
            wait(0.05)
            -- Проверяем не телепортировали ли нас
            if HumanoidRootPart and (HumanoidRootPart.Position - currentPos).Magnitude > 50 then
                -- Игра пыталась телепортировать, возвращаем
                HumanoidRootPart.CFrame = CFrame.new(currentPos)
            end
        end
    end)
end

-- ANTIHIT
local function setAntiHit(state)
    antihit = state
    if state then
        antihitConn = RunService.Heartbeat:Connect(function()
            if not Character or not Humanoid or not HumanoidRootPart then return end
            
            local currentState = Humanoid:GetState()
            if currentState == Enum.HumanoidStateType.FallingDown then
                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            
            if HumanoidRootPart.Velocity.Magnitude > 100 then
                HumanoidRootPart.Velocity = Vector3.zero
                HumanoidRootPart.RotVelocity = Vector3.zero
            end
            
            pcall(function()
                if Humanoid:FindFirstChild("Ragdoll") then
                    Humanoid:FindFirstChild("Ragdoll"):Destroy()
                end
            end)
            
            for _, obj in ipairs(Character:GetChildren()) do
                if obj:IsA("Tool") or obj.Name:lower():find("brain") or obj.Name:lower():find("rot") then
                    if obj:IsA("BasePart") then
                        obj.Anchored = false
                        obj.CanCollide = false
                    end
                end
            end
            
            pcall(function()
                local tool = Character:FindFirstChildOfClass("Tool")
                if tool then
                    tool.Parent = Character
                end
            end)
        end)
    else
        if antihitConn then antihitConn:Disconnect(); antihitConn = nil end
    end
end

-- VOID TOUCH (отбрасывает врагов за карту)
local voidTouchTarget = nil -- цель для Void Touch (nil = все вокруг)

local function setVoidTouch(state)
    voidtouch = state
    if state then
        local function findEnemies()
            local enemies = {}
            if voidTouchTarget then
                -- Только выбранный игрок
                local targetChar = voidTouchTarget.Character
                if targetChar then
                    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
                    local hum = targetChar:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        table.insert(enemies, {root = hrp, humanoid = hum, character = targetChar})
                    end
                end
            else
                -- Все вокруг
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        local hum = player.Character:FindFirstChild("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            table.insert(enemies, {root = hrp, humanoid = hum, character = player.Character})
                        end
                    end
                end
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Humanoid") and obj.Health > 0 and obj.Parent and obj.Parent ~= Character then
                        local root = obj.Parent:FindFirstChild("HumanoidRootPart") or obj.Parent:FindFirstChild("Torso")
                        if root then
                            local isPlayer = false
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr.Character == obj.Parent then isPlayer = true; break end
                            end
                            if not isPlayer then
                                table.insert(enemies, {root = root, humanoid = obj, character = obj.Parent})
                            end
                        end
                    end
                end
            end
            return enemies
        end
        
        voidtouchConn = RunService.Heartbeat:Connect(function()
            if not Character or not HumanoidRootPart then return end
            
            local enemies = findEnemies()
            local myPos = HumanoidRootPart.Position
            local voidDistance = 15
            
            for _, enemy in ipairs(enemies) do
                if enemy.root and enemy.root.Parent and enemy.humanoid and enemy.humanoid.Health > 0 then
                    local dist = (enemy.root.Position - myPos).Magnitude
                    if dist <= voidDistance then
                        local direction = (enemy.root.Position - myPos).Unit
                        if direction.Magnitude < 0.1 then
                            direction = Vector3.new(math.random(-1,1), 1, math.random(-1,1)).Unit
                        end
                        enemy.root.Velocity = direction * 5000 + Vector3.new(0, 2000, 0)
                        enemy.root.RotVelocity = Vector3.new(math.random(-50,50), math.random(-50,50), math.random(-50,50))
                    end
                end
            end
        end)
    else
        if voidtouchConn then voidtouchConn:Disconnect(); voidtouchConn = nil end
    end
end

-- AUTOSTEAL (ТП к базе рандомного игрока + 5 метров за ним)
local function findRandomPlayerBase()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                table.insert(players, player)
            end
        end
    end
    if #players == 0 then return nil end
    return players[math.random(1, #players)]
end

local function findBrain()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            return obj
        end
    end
    return nil
end

local function autoStealLoop()
    while autosteal and Character and HumanoidRootPart do
        -- Сначала ТП к базе случайного игрока
        local targetPlayer = findRandomPlayerBase()
        if targetPlayer and targetPlayer.Character then
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                -- ТП за ним на 5 метров (25 studs)
                local behindPos = targetHRP.CFrame * CFrame.new(0, 0, 25)
                HumanoidRootPart.CFrame = behindPos
            end
        end
        
        wait(0.2)
        
        -- Ищем и собираем мозг
        local brain = findBrain()
        if brain then
            HumanoidRootPart.CFrame = CFrame.new(brain.Parent.Position + Vector3.new(0, 2, 0))
            fireproximityprompt(brain)
        end
        
        wait(0.3)
    end
end

local function setAutoSteal(state)
    autosteal = state
    if state then
        spawn(autoStealLoop)
    end
end

-- LOCK BASE (вызывает ProximityPrompt вместо ТП)
local function findBasePrompt()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled and obj.ActionText:lower():find("base") then
            return obj
        end
    end
    -- Ищем любой ProximityPrompt на базе
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parent = obj.Parent
            if parent and (parent.Name:lower():find("base") or parent.Name:lower():find("capture") or parent.Name:lower():find("claim")) then
                return obj
            end
        end
    end
    return nil
end

local function setBaseLock(state)
    baseLocked = state
    if state then
        spawn(function()
            while baseLocked and Character and HumanoidRootPart do
                local prompt = findBasePrompt()
                if prompt then
                    -- Телепортимся к базе чтобы достать до промпта
                    local promptPos = prompt.Parent.Position
                    HumanoidRootPart.CFrame = CFrame.new(promptPos + Vector3.new(0, 2, 0))
                    -- Активируем промпт
                    fireproximityprompt(prompt)
                end
                wait(0.5)
            end
        end)
    end
end

-- SPEED HACK
local function setSpeedHack(state)
    speedhack = state
    if Humanoid then
        if state then
            oldWalkSpeed = Humanoid.WalkSpeed
            Humanoid.WalkSpeed = oldWalkSpeed * speedMultiplier
        else
            Humanoid.WalkSpeed = oldWalkSpeed
        end
    end
end

local function updateSpeedMultiplier(mult)
    speedMultiplier = mult
    if speedhack and Humanoid then
        Humanoid.WalkSpeed = oldWalkSpeed * speedMultiplier
    end
end

-- TELEPORT TO BASE
local function findBase()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and obj.Enabled then
            return obj
        end
    end
    return nil
end

local function teleportToBase()
    local base = findBase()
    if base and HumanoidRootPart then
        HumanoidRootPart.CFrame = CFrame.new(base.Position + Vector3.new(0, 3, 0))
    end
end

-- ESP
local espObjects = {}

local function createESP(player)
    if not player.Character then return end
    
    -- Удаляем старый ESP для этого игрока
    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do
            obj:Destroy()
        end
    end
    
    local highlights = {}
    
    -- Подсветка персонажа
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = player.Character
    table.insert(highlights, highlight)
    
    -- Билборд с именем
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = player.Character:WaitForChild("Head", 5)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard
    table.insert(highlights, billboard)
    
    -- Кнопка выбора для Void Touch
    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(0, 80, 0, 20)
    selectBtn.Position = UDim2.new(0, -40, 1, 5)
    selectBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    selectBtn.Text = "VOID"
    selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectBtn.Font = Enum.Font.GothamBold
    selectBtn.TextSize = 10
    selectBtn.Parent = billboard
    
    selectBtn.MouseButton1Click:Connect(function()
        selectedPlayer = player
        voidTouchTarget = player
        -- Обновляем все ESP кнопки
        updateAllESPButtons()
    end)
    
    espObjects[player] = highlights
end

local function updateAllESPButtons()
    for player, objects in pairs(espObjects) do
        for _, obj in ipairs(objects) do
            if obj:IsA("BillboardGui") then
                local btn = obj:FindFirstChildOfClass("TextButton")
                if btn then
                    if player == selectedPlayer then
                        btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        btn.Text = "SELECTED"
                    else
                        btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        btn.Text = "VOID"
                    end
                end
            end
        end
    end
end

local function setESP(state)
    espEnabled = state
    if state then
        -- Создаем ESP для всех игроков
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createESP(player)
            end
        end
        
        -- Отслеживаем новых игроков
        Players.PlayerAdded:Connect(function(player)
            if espEnabled then
                player.CharacterAdded:Connect(function()
                    wait(0.5)
                    createESP(player)
                end)
            end
        end)
    else
        -- Удаляем весь ESP
        for player, objects in pairs(espObjects) do
            for _, obj in ipairs(objects) do
                obj:Destroy()
            end
        end
        espObjects = {}
        selectedPlayer = nil
        voidTouchTarget = nil
    end
end

-- ==================== GUI ====================
local screen = Instance.new("ScreenGui")
screen.Parent = playerGui
screen.ResetOnSpawn = false
screen.Name = "BrainrotHack"
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 470)
mainFrame.Position = UDim2.new(0, 20, 0.5, -235)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.Parent = screen

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 7)
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(30, 30, 30)

-- Title
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 7)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.7, 0, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Brainrot Hack v5"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

-- Content
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -38)
content.Position = UDim2.new(0, 8, 0, 34)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Toggle Creator
local function createToggle(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BorderSizePixel = 0
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = name .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 140, 70) or Color3.fromRGB(40, 40, 40)
        callback(enabled)
    end)
    return btn
end

-- Toggles
createToggle("Invisible", 0, setInvisible)
createToggle("NoClip (Walls)", 34, setNoClip)
createToggle("AntiHit", 68, setAntiHit)
createToggle("Void Touch", 102, function(state)
    setVoidTouch(state)
end)
createToggle("AutoSteal", 136, setAutoSteal)
createToggle("Speed Hack", 170, setSpeedHack)
createToggle("Lock Base", 204, setBaseLock)
createToggle("ESP", 238, setESP)

-- Speed multiplier
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 16)
speedLabel.Position = UDim2.new(0, 0, 0, 276)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed Multiplier: x2"
speedLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = content

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 28, 0, 20)
minusBtn.Position = UDim2.new(0, 0, 0, 294)
minusBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minusBtn.BorderSizePixel = 0
minusBtn.Text = "-"
minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 14
minusBtn.AutoButtonColor = false
minusBtn.Parent = content
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 28, 0, 20)
plusBtn.Position = UDim2.new(1, -28, 0, 294)
plusBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
plusBtn.BorderSizePixel = 0
plusBtn.Text = "+"
plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 14
plusBtn.AutoButtonColor = false
plusBtn.Parent = content
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

minusBtn.MouseButton1Click:Connect(function()
    local newMult = math.max(speedMultiplier - 0.5, 1)
    speedMultiplier = newMult
    speedLabel.Text = "Speed Multiplier: x" .. speedMultiplier
    updateSpeedMultiplier(speedMultiplier)
end)

plusBtn.MouseButton1Click:Connect(function()
    local newMult = math.min(speedMultiplier + 0.5, 10)
    speedMultiplier = newMult
    speedLabel.Text = "Speed Multiplier: x" .. speedMultiplier
    updateSpeedMultiplier(speedMultiplier)
end)

-- Teleport
local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(1, 0, 0, 28)
teleportBtn.Position = UDim2.new(0, 0, 0, 322)
teleportBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
teleportBtn.BorderSizePixel = 0
teleportBtn.Text = "Teleport to Base"
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Font = Enum.Font.GothamSemibold
teleportBtn.TextSize = 12
teleportBtn.AutoButtonColor = false
teleportBtn.Parent = content
Instance.new("UICorner", teleportBtn).CornerRadius = UDim.new(0, 5)

teleportBtn.MouseButton1Click:Connect(teleportToBase)

-- Selected target info
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, 0, 0, 20)
targetLabel.Position = UDim2.new(0, 0, 0, 356)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Void Target: ALL"
targetLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
targetLabel.Font = Enum.Font.GothamSemibold
targetLabel.TextSize = 10
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = content

-- Clear target button
local clearTargetBtn = Instance.new("TextButton")
clearTargetBtn.Size = UDim2.new(1, 0, 0, 22)
clearTargetBtn.Position = UDim2.new(0, 0, 0, 378)
clearTargetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
clearTargetBtn.BorderSizePixel = 0
clearTargetBtn.Text = "Clear Void Target"
clearTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearTargetBtn.Font = Enum.Font.GothamSemibold
clearTargetBtn.TextSize = 10
clearTargetBtn.AutoButtonColor = false
clearTargetBtn.Parent = content
Instance.new("UICorner", clearTargetBtn).CornerRadius = UDim.new(0, 4)

clearTargetBtn.MouseButton1Click:Connect(function()
    selectedPlayer = nil
    voidTouchTarget = nil
    targetLabel.Text = "Void Target: ALL"
    updateAllESPButtons()
end)

-- Обновление информации о цели
spawn(function()
    while true do
        if selectedPlayer then
            targetLabel.Text = "Void Target: " .. selectedPlayer.Name
        else
            targetLabel.Text = "Void Target: ALL"
        end
        wait(0.5)
    end
end)

-- Перетаскивание
local dragging = false
local dragStart, frameStart

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Restore button
local restoreBtn = Instance.new("TextButton")
restoreBtn.Size = UDim2.new(0, 45, 0, 26)
restoreBtn.Position = UDim2.new(1, -55, 0, 8)
restoreBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
restoreBtn.BorderSizePixel = 0
restoreBtn.Text = "Show"
restoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
restoreBtn.Font = Enum.Font.GothamBold
restoreBtn.TextSize = 11
restoreBtn.Visible = false
restoreBtn.Parent = screen
Instance.new("UICorner", restoreBtn).CornerRadius = UDim.new(0, 5)

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    restoreBtn.Visible = true
end)

restoreBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    restoreBtn.Visible = false
end)

-- Инициализация Anti TP Back
antiTPBack()

-- Respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    
    wait(0.5)
    
    if invisible then setInvisible(true) end
    if noclip then setNoClip(false); setNoClip(true) end
    if antihit then setAntiHit(false); setAntiHit(true) end
    if voidtouch then setVoidTouch(false); setVoidTouch(true) end
    if autosteal then spawn(autoStealLoop) end
    if speedhack then setSpeedHack(false); setSpeedHack(true) end
    if baseLocked then setBaseLock(false); setBaseLock(true) end
    
    antiTPBack()
end)