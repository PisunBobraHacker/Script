-- // Steal a Brainrot — Full Script v3 for Xeno
-- // AntiHit (защита от дубинок), Void Touch (отбрасывает врагов), NoClip, Invisible, AutoSteal, Fly, Lock Base, Teleport

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then playerGui = game:GetService("CoreGui") end

-- Переменные
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local invisible = false
local noclip = false
local antihit = false
local voidtouch = false
local autosteal = false
local flying = false
local baseLocked = false
local flySpeed = 50

local flyBV, flyBG, flyConn = nil, nil, nil
local noclipConn, antihitConn, voidtouchConn, autostealConn = nil, nil, nil, nil
local flyKeys = {W = false, A = false, S = false, D = false, Space = false, LeftControl = false}

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

-- NOCLIP
local function setNoClip(state)
    noclip = state
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
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

-- ANTIHIT (защита от дубинок: мозг не выпадает, не отлетаешь)
local function setAntiHit(state)
    antihit = state
    if state then
        antihitConn = RunService.Heartbeat:Connect(function()
            if not Character or not Humanoid or not HumanoidRootPart then return end
            
            -- Блокируем стан и падение
            local currentState = Humanoid:GetState()
            if currentState == Enum.HumanoidStateType.FallingDown then
                Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            
            -- Обнуляем скорость от ударов
            if HumanoidRootPart.Velocity.Magnitude > 100 then
                HumanoidRootPart.Velocity = Vector3.zero
                HumanoidRootPart.RotVelocity = Vector3.zero
            end
            
            -- Блокируем ragdoll
            pcall(function()
                if Humanoid:FindFirstChild("Ragdoll") then
                    Humanoid:FindFirstChild("Ragdoll"):Destroy()
                end
            end)
            
            -- Защита предмета (мозга) в руках
            for _, obj in ipairs(Character:GetChildren()) do
                if obj:IsA("Tool") or obj.Name:lower():find("brain") or obj.Name:lower():find("rot") then
                    -- Фиксируем предмет чтобы не выпал
                    if obj:IsA("BasePart") then
                        obj.Anchored = false
                        obj.CanCollide = false
                    end
                end
            end
            
            -- Проверяем предметы которые держим
            pcall(function()
                local tool = Character:FindFirstChildOfClass("Tool")
                if tool then
                    -- Не даем выбить предмет
                    tool.Parent = Character
                end
            end)
        end)
    else
        if antihitConn then antihitConn:Disconnect(); antihitConn = nil end
    end
end

-- VOID TOUCH (враги отлетают за карту при касании)
local function setVoidTouch(state)
    voidtouch = state
    if state then
        -- Создаем невидимую сферу вокруг игрока которая отбрасывает врагов
        local function findEnemies()
            local enemies = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        table.insert(enemies, {player = player, root = hrp, humanoid = hum, character = player.Character})
                    end
                end
            end
            -- Также ищем NPC/monsters
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Humanoid") and obj.Health > 0 and obj.Parent and obj.Parent ~= Character then
                    local root = obj.Parent:FindFirstChild("HumanoidRootPart") or obj.Parent:FindFirstChild("Torso")
                    if root then
                        local isPlayer = false
                        for _, plr in ipairs(Players:GetPlayers()) do
                            if plr.Character == obj.Parent then
                                isPlayer = true
                                break
                            end
                        end
                        if not isPlayer then
                            table.insert(enemies, {player = nil, root = root, humanoid = obj, character = obj.Parent})
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
            local voidDistance = 15 -- радиус действия
            
            for _, enemy in ipairs(enemies) do
                if enemy.root and enemy.root.Parent then
                    local dist = (enemy.root.Position - myPos).Magnitude
                    if dist <= voidDistance then
                        -- Отбрасываем врага далеко за карту
                        local direction = (enemy.root.Position - myPos).Unit
                        if direction.Magnitude < 0.1 then
                            direction = Vector3.new(math.random(-1, 1), 1, math.random(-1, 1)).Unit
                        end
                        local launchVelocity = direction * 5000 + Vector3.new(0, 2000, 0)
                        enemy.root.Velocity = launchVelocity
                        enemy.root.RotVelocity = Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
                        
                        -- Наносим урон врагу (опционально)
                        pcall(function()
                            if enemy.humanoid then
                                enemy.humanoid:TakeDamage(99999)
                            end
                        end)
                    end
                end
            end
        end)
    else
        if voidtouchConn then voidtouchConn:Disconnect(); voidtouchConn = nil end
    end
end

-- AUTOSTEAL
local function findBrain()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            return obj
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("brain") or obj.Name:lower():find("rot")) then
            return obj
        end
    end
    return nil
end

local function autoStealLoop()
    while autosteal and Character and HumanoidRootPart do
        local target = findBrain()
        if target then
            local pos = target:IsA("ProximityPrompt") and target.Parent.Position or target.Position
            HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
            
            if target:IsA("ProximityPrompt") then
                fireproximityprompt(target)
            else
                firetouchinterest(HumanoidRootPart, target, 0)
                wait(0.05)
                firetouchinterest(HumanoidRootPart, target, 1)
            end
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

-- TELEPORT TO BASE
local function findBase()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and obj.Enabled then
            return obj
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("base") or obj.Name:lower():find("safe") or obj.Name:lower():find("spawn")) then
            return obj
        end
    end
    return nil
end

local function teleportToBase()
    local base = findBase()
    if base and HumanoidRootPart then
        local pos = base:IsA("BasePart") and base.Position or base.CFrame.Position
        HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

-- LOCK BASE
local baseLockPart = nil

local function setBaseLock(state)
    baseLocked = state
    if state then
        local base = findBase()
        if base then
            local basePos = base:IsA("BasePart") and base.Position or base.CFrame.Position
            
            baseLockPart = Instance.new("Part")
            baseLockPart.Name = "BaseLock"
            baseLockPart.Size = Vector3.new(20, 10, 20)
            baseLockPart.Position = basePos
            baseLockPart.Anchored = true
            baseLockPart.CanCollide = true
            baseLockPart.Transparency = 1
            baseLockPart.Parent = Workspace
            
            spawn(function()
                while baseLocked and Character and HumanoidRootPart and baseLockPart do
                    HumanoidRootPart.CFrame = CFrame.new(basePos + Vector3.new(0, 3, 0))
                    wait(0.1)
                end
            end)
        end
    else
        if baseLockPart then
            baseLockPart:Destroy()
            baseLockPart = nil
        end
    end
end

-- FLY
local function startFly()
    if not HumanoidRootPart or not Humanoid then return end
    
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1, 1, 1) * 999999
    flyBV.P = 9000
    flyBV.Velocity = Vector3.zero
    flyBV.Name = "FlyVel"
    flyBV.Parent = HumanoidRootPart

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1, 1, 1) * 999999
    flyBG.P = 9000
    flyBG.D = 100
    flyBG.CFrame = HumanoidRootPart.CFrame
    flyBG.Name = "FlyGyro"
    flyBG.Parent = HumanoidRootPart

    Humanoid.PlatformStand = true

    flyConn = RunService.Heartbeat:Connect(function()
        if not flying or not Character or not HumanoidRootPart or not Humanoid then
            stopFly()
            return
        end

        Humanoid.PlatformStand = true

        local cam = Camera
        local look = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)

        local dir = Vector3.zero
        if flyKeys.W then dir += look end
        if flyKeys.S then dir -= look end
        if flyKeys.A then dir -= right end
        if flyKeys.D then dir += right end
        if flyKeys.Space then dir += up end
        if flyKeys.LeftControl then dir -= up end

        if dir.Magnitude > 1 then dir = dir.Unit end

        if flyBV and flyBV.Parent then flyBV.Velocity = dir * flySpeed end
        if flyBG and flyBG.Parent then flyBG.CFrame = cam.CFrame * CFrame.Angles(-math.rad(90), 0, 0) end
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
    if Humanoid then Humanoid.PlatformStand = false end
end

local function setFly(state)
    flying = state
    if state then startFly() else stopFly() end
end

-- ==================== GUI ====================
local screen = Instance.new("ScreenGui")
screen.Parent = playerGui
screen.ResetOnSpawn = false
screen.Name = "BrainrotHack"
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 210, 0, 420)
mainFrame.Position = UDim2.new(0, 20, 0.5, -210)
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
titleText.Text = "Brainrot Hack"
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
createToggle("NoClip", 34, setNoClip)
createToggle("AntiHit", 68, setAntiHit)
createToggle("Void Touch", 102, setVoidTouch)
createToggle("AutoSteal", 136, setAutoSteal)
createToggle("Fly", 170, setFly)
createToggle("Lock Base", 204, setBaseLock)

-- Speed control
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 16)
speedLabel.Position = UDim2.new(0, 0, 0, 242)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Fly Speed: 50"
speedLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = content

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 28, 0, 20)
minusBtn.Position = UDim2.new(0, 0, 0, 260)
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
plusBtn.Position = UDim2.new(1, -28, 0, 260)
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
    flySpeed = math.max(flySpeed - 10, 10)
    speedLabel.Text = "Fly Speed: " .. flySpeed
end)

plusBtn.MouseButton1Click:Connect(function()
    flySpeed = math.min(flySpeed + 10, 200)
    speedLabel.Text = "Fly Speed: " .. flySpeed
end)

-- Teleport
local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(1, 0, 0, 28)
teleportBtn.Position = UDim2.new(0, 0, 0, 288)
teleportBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
teleportBtn.BorderSizePixel = 0
teleportBtn.Text = "Teleport to Base"
teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportBtn.Font = Enum.Font.GothamSemibold
teleportBtn.TextSize = 12
teleportBtn.AutoButtonColor = false
teleportBtn.Parent = content
Instance.new("UICorner", teleportBtn).CornerRadius = UDim.new(0, 5)

teleportBtn.MouseButton1Click:Connect(function()
    teleportToBase()
end)

-- ==================== ПЕРЕТАСКИВАНИЕ ====================
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

-- ==================== КЛАВИШИ ПОЛЕТА ====================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.W then flyKeys.W = true
    elseif k == Enum.KeyCode.A then flyKeys.A = true
    elseif k == Enum.KeyCode.S then flyKeys.S = true
    elseif k == Enum.KeyCode.D then flyKeys.D = true
    elseif k == Enum.KeyCode.Space then flyKeys.Space = true
    elseif k == Enum.KeyCode.LeftControl then flyKeys.LeftControl = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local k = input.KeyCode
    if k == Enum.KeyCode.W then flyKeys.W = false
    elseif k == Enum.KeyCode.A then flyKeys.A = false
    elseif k == Enum.KeyCode.S then flyKeys.S = false
    elseif k == Enum.KeyCode.D then flyKeys.D = false
    elseif k == Enum.KeyCode.Space then flyKeys.Space = false
    elseif k == Enum.KeyCode.LeftControl then flyKeys.LeftControl = false
    end
end)

-- ==================== РЕСПАВН ====================
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
    if flying then stopFly(); flying = false; setFly(true) end
    if baseLocked then setBaseLock(false); setBaseLock(true) end
end)

-- ==================== ОЧИСТКА ПРИ ВЫХОДЕ ====================
LocalPlayer.OnTeleport:Connect(function()
    setFly(false)
    setNoClip(false)
    setAntiHit(false)
    setVoidTouch(false)
    setInvisible(false)
    setAutoSteal(false)
    setBaseLock(false)
end)
