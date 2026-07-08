-- // HuyilanHub v5 for Xeno
-- // Исправлено: AntiAim не сбивает прицел, GodMode рабочий, Wallshot + SilentAim фикс, аимбот плавный

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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
local aimbot = false
local aimbotPart = "Head"
local silentAim = false
local espEnabled = false
local noRecoil = false
local rapidFire = false
local flying = false
local speedhack = false
local noclip = false
local godmode = false
local antiAim = false
local wallshot = false
local triggerBot = false
local crosshairEnabled = false
local aimbotFOV = 200
local flySpeed = 50
local speedMultiplier = 2
local rapidFireDelay = 0.05
local triggerBotDelay = 0.1
local menuVisible = false

local flyBV, flyBG, flyConn = nil, nil, nil
local noclipConn, godmodeConn, antiAimConn, triggerBotConn, silentAimConn, wallshotConn = nil, nil, nil, nil, nil, nil
local flyKeys = {W = false, A = false, S = false, D = false, Space = false, LeftControl = false}
local espObjects = {}
local fovCircle = nil
local crosshairGui = nil
local aimbotDropdownOpen = false
local rgbConn = nil
local lastAimTarget = nil

-- ==================== GODMODE (фикс) ====================
local function setGodmode(state)
    godmode = state
    if state then
        godmodeConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                if Humanoid and Humanoid.Health > 0 then
                    Humanoid.Health = Humanoid.MaxHealth
                end
                if Character then
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.CanTouch = false
                        end
                    end
                end
            end)
        end)
    else
        if godmodeConn then godmodeConn:Disconnect(); godmodeConn = nil end
        pcall(function()
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanTouch = true
                    end
                end
            end
        end)
    end
end

-- ==================== NOCLIP ====================
local function setNoClip(state)
    noclip = state
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                if not Character or not HumanoidRootPart then return end
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
                if HumanoidRootPart.Position.Y < -100 then
                    HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
                end
                if HumanoidRootPart.Position.Magnitude > 5000 then
                    HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
                end
            end)
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        pcall(function()
            if Character then
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end)
    end
end

-- ==================== ANTI AIM (не сбивает прицел) ====================
local function setAntiAim(state)
    antiAim = state
    if state then
        antiAimConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                if Character and HumanoidRootPart and Humanoid then
                    -- Меняем только тело, камера остается на месте
                    local camCFrame = Camera.CFrame
                    
                    -- Вращаем RootPart независимо от камеры
                    Humanoid.AutoRotate = false
                    HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(tick() * 600 % 360), 0)
                    
                    -- Наклоняем тело
                    local rootCF = HumanoidRootPart.CFrame
                    HumanoidRootPart.CFrame = rootCF * CFrame.Angles(
                        math.rad(math.sin(tick() * 20) * 45),
                        0,
                        math.rad(math.cos(tick() * 18) * 45)
                    )
                    
                    -- Камера остается где была (не привязана к телу)
                    Camera.CFrame = camCFrame
                end
            end)
        end)
    else
        if antiAimConn then antiAimConn:Disconnect(); antiAimConn = nil end
        pcall(function()
            if Humanoid then
                Humanoid.AutoRotate = true
            end
        end)
    end
end

-- ==================== WALLSHOT (фикс) ====================
local function setWallshot(state)
    wallshot = state
    if state then
        wallshotConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                -- Делаем стены проходимыми для рейкастов оружия
                if Character then
                    for _, part in ipairs(Workspace:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide and part.Transparency < 0.5 then
                            -- Не трогаем части персонажей
                            local isCharacter = false
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr.Character and part:IsDescendantOf(plr.Character) then
                                    isCharacter = true
                                    break
                                end
                            end
                            if not isCharacter then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end)
    else
        if wallshotConn then wallshotConn:Disconnect(); wallshotConn = nil end
    end
end

-- ==================== SILENT AIM (фикс, работает с wallshot) ====================
local function setSilentAim(state)
    silentAim = state
    if state then
        silentAimConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                if not Character then return end
                
                -- Ищем ближайшего врага
                local closest, closestDist = nil, aimbotFOV
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local targetPart = player.Character:FindFirstChild(aimbotPart)
                        local hum = player.Character:FindFirstChild("Humanoid")
                        if targetPart and hum and hum.Health > 0 then
                            local sp, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                            local dist = onScreen and (Vector2.new(sp.X, sp.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude or 99999
                            if dist < closestDist then
                                closestDist = dist
                                closest = targetPart
                            end
                        end
                    end
                end
                
                if closest then
                    -- Телепортируем позицию выстрела к цели
                    local tool = Character:FindFirstChildOfClass("Tool")
                    if tool then
                        local handle = tool:FindFirstChild("Handle") or tool.PrimaryPart
                        if handle then
                            -- Направляем выстрел на цель игнорируя стены
                            local firePos = closest.Position
                            local dir = (firePos - handle.Position).Unit
                            
                            -- Создаем рейкаст для регистрации попадания
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            rayParams.FilterDescendantsInstances = {Character}
                            rayParams.IgnoreWater = true
                            
                            -- Проверяем что цель видна (wallshot игнорирует стены)
                            local rayResult = Workspace:Raycast(handle.Position, dir * 1000, rayParams)
                            if rayResult then
                                local hitChar = rayResult.Instance.Parent
                                if hitChar and hitChar:FindFirstChild("Humanoid") then
                                    -- Попадание зарегистрировано
                                    firetouchinterest(handle, rayResult.Instance, 0)
                                    firetouchinterest(handle, rayResult.Instance, 1)
                                end
                            end
                        end
                    end
                end
            end)
        end)
    else
        if silentAimConn then silentAimConn:Disconnect(); silentAimConn = nil end
    end
end

-- ==================== TRIGGER BOT ====================
local function setTriggerBot(state)
    triggerBot = state
    if state then
        triggerBotConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                local target = Mouse.Target
                if target and target.Parent then
                    local hum = target.Parent:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 and target.Parent ~= Character then
                        mouse1press()
                        wait(triggerBotDelay)
                        mouse1release()
                    end
                end
            end)
        end)
    else
        if triggerBotConn then triggerBotConn:Disconnect(); triggerBotConn = nil end
    end
end

-- ==================== AIMBOT (плавный, без рывков) ====================
local function findClosestEnemy()
    local closest, closestDist = nil, aimbotFOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(aimbotPart)
            local hum = player.Character:FindFirstChild("Humanoid")
            if targetPart and hum and hum.Health > 0 then
                local sp, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = targetPart
                    end
                end
            end
        end
    end
    return closest
end

local function setAimbot(state)
    aimbot = state
    if state then
        lastAimTarget = nil
        spawn(function()
            while aimbot do
                pcall(function()
                    local target = findClosestEnemy()
                    if target then
                        local targetPos = target.Position
                        local camPos = Camera.CFrame.Position
                        
                        -- Плавность зависит от того та же цель или новая
                        local smooth = (lastAimTarget == target) and 0.06 or 0.15
                        lastAimTarget = target
                        
                        local lookAt = CFrame.new(camPos, targetPos)
                        Camera.CFrame = Camera.CFrame:Lerp(lookAt, smooth)
                    else
                        lastAimTarget = nil
                    end
                end)
                RunService.RenderStepped:Wait()
            end
        end)
    else
        lastAimTarget = nil
    end
end

-- ==================== FOV CIRCLE ====================
local function updateFOVCircle()
    if fovCircle then fovCircle:Destroy(); fovCircle = nil end
    fovCircle = Instance.new("ScreenGui")
    fovCircle.Name = "FOVCircle"
    fovCircle.ResetOnSpawn = false
    fovCircle.Parent = playerGui
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, aimbotFOV * 2, 0, aimbotFOV * 2)
    circle.Position = UDim2.new(0.5, -aimbotFOV, 0.5, -aimbotFOV)
    circle.BackgroundTransparency = 1
    circle.Parent = fovCircle
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.5
    stroke.Thickness = 1.5
    stroke.Parent = circle
    
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
end

-- ==================== CROSSHAIR ====================
local function setCrosshair(state)
    crosshairEnabled = state
    if state then
        if crosshairGui then crosshairGui:Destroy() end
        crosshairGui = Instance.new("ScreenGui")
        crosshairGui.Name = "Crosshair"
        crosshairGui.ResetOnSpawn = false
        crosshairGui.Parent = playerGui
        
        local v = Instance.new("Frame")
        v.Size = UDim2.new(0, 2, 0, 14)
        v.Position = UDim2.new(0.5, -1, 0.5, -7)
        v.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        v.BorderSizePixel = 0
        v.Parent = crosshairGui
        
        local h = Instance.new("Frame")
        h.Size = UDim2.new(0, 14, 0, 2)
        h.Position = UDim2.new(0.5, -7, 0.5, -1)
        h.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        h.BorderSizePixel = 0
        h.Parent = crosshairGui
        
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, 3, 0, 3)
        d.Position = UDim2.new(0.5, -1.5, 0.5, -1.5)
        d.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        d.BorderSizePixel = 0
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
        d.Parent = crosshairGui
    else
        if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
    end
end

-- ==================== ESP ====================
local function createESP(player)
    if not player.Character then return end
    if espObjects[player] then for _, o in ipairs(espObjects[player]) do o:Destroy() end end
    local items = {}
    
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 100, 100)
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.Parent = player.Character
    table.insert(items, hl)
    
    local head = player.Character:WaitForChild("Head", 5)
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 100, 0, 35)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head
        
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, 0, 0.5, 0)
        name.BackgroundTransparency = 1
        name.Text = player.Name
        name.TextColor3 = Color3.fromRGB(255, 255, 255)
        name.Font = Enum.Font.GothamBold
        name.TextSize = 11
        name.Parent = bb
        
        local hp = Instance.new("TextLabel")
        hp.Size = UDim2.new(1, 0, 0.5, 0)
        hp.Position = UDim2.new(0, 0, 0.5, 0)
        hp.BackgroundTransparency = 1
        hp.Text = "HP: " .. math.floor(player.Character.Humanoid.Health)
        hp.TextColor3 = Color3.fromRGB(255, 150, 150)
        hp.Font = Enum.Font.GothamSemibold
        hp.TextSize = 10
        hp.Parent = bb
        
        table.insert(items, bb)
    end
    
    espObjects[player] = items
end

local function setESP(state)
    espEnabled = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then createESP(p) end
        end
        Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function()
                wait(0.5)
                if espEnabled then createESP(p) end
            end)
        end)
    else
        for _, items in pairs(espObjects) do
            for _, obj in ipairs(items) do obj:Destroy() end
        end
        espObjects = {}
    end
end

-- ==================== NO RECOIL / RAPID FIRE ====================
local function setNoRecoil(state) noRecoil = state end

local function setRapidFire(state)
    rapidFire = state
    if state then
        spawn(function()
            while rapidFire do
                pcall(function()
                    if Character and Character:FindFirstChildOfClass("Tool") then
                        if Mouse.Target and Mouse.Target.Parent and Mouse.Target.Parent:FindFirstChild("Humanoid") then
                            mouse1press()
                            wait(rapidFireDelay)
                            mouse1release()
                        end
                    end
                end)
                wait(0.01)
            end
        end)
    end
end

-- ==================== FLY ====================
local function startFly()
    if not HumanoidRootPart or not Humanoid then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1, 1, 1) * 999999
    flyBV.P = 9000
    flyBV.Parent = HumanoidRootPart
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1, 1, 1) * 999999
    flyBG.P = 9000
    flyBG.D = 100
    flyBG.CFrame = HumanoidRootPart.CFrame
    flyBG.Parent = HumanoidRootPart
    Humanoid.PlatformStand = true

    flyConn = RunService.Heartbeat:Connect(function()
        if not flying or not Character or not HumanoidRootPart or not Humanoid then stopFly(); return end
        Humanoid.PlatformStand = true
        local cam = Camera
        local dir = Vector3.zero
        if flyKeys.W then dir += cam.CFrame.LookVector end
        if flyKeys.S then dir -= cam.CFrame.LookVector end
        if flyKeys.A then dir -= cam.CFrame.RightVector end
        if flyKeys.D then dir += cam.CFrame.RightVector end
        if flyKeys.Space then dir += Vector3.new(0, 1, 0) end
        if flyKeys.LeftControl then dir -= Vector3.new(0, 1, 0) end
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

-- ==================== SPEED HACK ====================
local function setSpeedHack(state)
    speedhack = state
    if Humanoid then Humanoid.WalkSpeed = state and 16 * speedMultiplier or 16 end
end

local function updateSpeed(mult)
    speedMultiplier = mult
    if speedhack and Humanoid then Humanoid.WalkSpeed = 16 * mult end
end

-- ==================== RGB GUI ====================
local screen = Instance.new("ScreenGui")
screen.Parent = playerGui
screen.ResetOnSpawn = false
screen.Name = "HuyilanHub"
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Enabled = false

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
})

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 580)
mainFrame.Position = UDim2.new(0, 30, 0.5, -290)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.Parent = screen

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Transparency = 0.7
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleGradientClone = titleGradient:Clone()
titleGradientClone.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.6, 0, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "HuyilanHub"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.Font = Enum.Font.GothamBlack
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Position = UDim2.new(1, -52, 0.5, -12)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.BackgroundTransparency = 0.85
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.Parent = titleBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 4)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -24, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -43)
content.Position = UDim2.new(0, 8, 0, 41)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- RGB анимация
local function startRGB()
    if rgbConn then rgbConn:Disconnect() end
    rgbConn = RunService.RenderStepped:Connect(function()
        local hue = (tick() * 50) % 360
        titleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(((hue) % 360) / 360, 1, 1)),
            ColorSequenceKeypoint.new(0.25, Color3.fromHSV(((hue + 60) % 360) / 360, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(((hue + 120) % 360) / 360, 1, 1)),
            ColorSequenceKeypoint.new(0.75, Color3.fromHSV(((hue + 180) % 360) / 360, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(((hue + 240) % 360) / 360, 1, 1))
        })
        titleGradientClone.Color = titleGradient.Color
        mainStroke.Color = Color3.fromHSV(((hue + 180) % 360) / 360, 1, 1)
    end)
end

startRGB()

local function createToggle(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderSizePixel = 0
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(50, 50, 50)
    btnStroke.Thickness = 0.5
    btnStroke.Parent = btn

    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        btn.Text = name .. ": " .. (enabled and "ON" or "OFF")
        btn.BackgroundColor3 = enabled and Color3.fromRGB(80, 0, 120) or Color3.fromRGB(30, 30, 30)
        btnStroke.Color = enabled and Color3.fromRGB(150, 50, 255) or Color3.fromRGB(50, 50, 50)
        callback(enabled)
    end)
    return btn
end

createToggle("Aimbot", 0, setAimbot)
updateFOVCircle()

-- Aimbot Part
local aimbotPartLabel = Instance.new("TextLabel")
aimbotPartLabel.Size = UDim2.new(1, 0, 0, 14)
aimbotPartLabel.Position = UDim2.new(0, 0, 0, 32)
aimbotPartLabel.BackgroundTransparency = 1
aimbotPartLabel.Text = "Part: Head"
aimbotPartLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
aimbotPartLabel.Font = Enum.Font.GothamSemibold
aimbotPartLabel.TextSize = 10
aimbotPartLabel.Parent = content

local aimbotPartBtn = Instance.new("TextButton")
aimbotPartBtn.Size = UDim2.new(1, 0, 0, 20)
aimbotPartBtn.Position = UDim2.new(0, 0, 0, 48)
aimbotPartBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
aimbotPartBtn.BorderSizePixel = 0
aimbotPartBtn.Text = "Select [v]"
aimbotPartBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
aimbotPartBtn.Font = Enum.Font.GothamSemibold
aimbotPartBtn.TextSize = 10
aimbotPartBtn.AutoButtonColor = false
aimbotPartBtn.Parent = content
Instance.new("UICorner", aimbotPartBtn).CornerRadius = UDim.new(0, 4)

local aimbotPartList = Instance.new("Frame")
aimbotPartList.Size = UDim2.new(1, 0, 0, 0)
aimbotPartList.Position = UDim2.new(0, 0, 0, 70)
aimbotPartList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
aimbotPartList.BorderSizePixel = 0
aimbotPartList.Visible = false
aimbotPartList.ClipsDescendants = true
aimbotPartList.Parent = content
Instance.new("UICorner", aimbotPartList).CornerRadius = UDim.new(0, 4)

local parts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
local partBtns = {}

for i, partName in ipairs(parts) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.Position = UDim2.new(0, 0, 0, (i-1) * 22)
    btn.BackgroundColor3 = aimbotPart == partName and Color3.fromRGB(80, 0, 120) or Color3.fromRGB(40, 40, 40)
    btn.BorderSizePixel = 0
    btn.Text = partName
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = aimbotPartList
    
    btn.MouseButton1Click:Connect(function()
        aimbotPart = partName
        aimbotPartLabel.Text = "Part: " .. partName
        aimbotPartList.Visible = false
        aimbotDropdownOpen = false
        for _, b in ipairs(partBtns) do
            b.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
        btn.BackgroundColor3 = Color3.fromRGB(80, 0, 120)
    end)
    
    table.insert(partBtns, btn)
end

aimbotPartBtn.MouseButton1Click:Connect(function()
    aimbotDropdownOpen = not aimbotDropdownOpen
    aimbotPartList.Visible = aimbotDropdownOpen
    if aimbotDropdownOpen then
        aimbotPartList.Size = UDim2.new(1, 0, 0, #parts * 22)
    end
end)

createToggle("Silent Aim", 72, setSilentAim)
createToggle("Trigger Bot", 104, setTriggerBot)
createToggle("ESP", 136, setESP)
createToggle("No Recoil", 168, setNoRecoil)
createToggle("Rapid Fire", 200, setRapidFire)
createToggle("Wallshot", 232, setWallshot)
createToggle("Anti Aim", 264, setAntiAim)
createToggle("God Mode", 296, setGodmode)
createToggle("NoClip", 328, setNoClip)
createToggle("Fly", 360, setFly)
createToggle("Speed Hack", 392, setSpeedHack)
createToggle("Crosshair", 424, setCrosshair)

-- FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1, 0, 0, 14)
fovLabel.Position = UDim2.new(0, 0, 0, 458)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV: " .. aimbotFOV
fovLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
fovLabel.Font = Enum.Font.GothamSemibold
fovLabel.TextSize = 10
fovLabel.Parent = content

local fovMinus = Instance.new("TextButton")
fovMinus.Size = UDim2.new(0, 24, 0, 16)
fovMinus.Position = UDim2.new(0, 0, 0, 474)
fovMinus.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
fovMinus.BorderSizePixel = 0
fovMinus.Text = "-"
fovMinus.TextColor3 = Color3.fromRGB(200, 200, 200)
fovMinus.Font = Enum.Font.GothamBold
fovMinus.TextSize = 12
fovMinus.AutoButtonColor = false
fovMinus.Parent = content
Instance.new("UICorner", fovMinus).CornerRadius = UDim.new(0, 3)

local fovPlus = Instance.new("TextButton")
fovPlus.Size = UDim2.new(0, 24, 0, 16)
fovPlus.Position = UDim2.new(1, -24, 0, 474)
fovPlus.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
fovPlus.BorderSizePixel = 0
fovPlus.Text = "+"
fovPlus.TextColor3 = Color3.fromRGB(200, 200, 200)
fovPlus.Font = Enum.Font.GothamBold
fovPlus.TextSize = 12
fovPlus.AutoButtonColor = false
fovPlus.Parent = content
Instance.new("UICorner", fovPlus).CornerRadius = UDim.new(0, 3)

fovMinus.MouseButton1Click:Connect(function()
    aimbotFOV = math.max(aimbotFOV - 25, 50)
    fovLabel.Text = "FOV: " .. aimbotFOV
    updateFOVCircle()
end)

fovPlus.MouseButton1Click:Connect(function()
    aimbotFOV = math.min(aimbotFOV + 25, 500)
    fovLabel.Text = "FOV: " .. aimbotFOV
    updateFOVCircle()
end)

-- Speed
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 14)
speedLabel.Position = UDim2.new(0, 0, 0, 496)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: x" .. speedMultiplier
speedLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.TextSize = 10
speedLabel.Parent = content

local spdMinus = Instance.new("TextButton")
spdMinus.Size = UDim2.new(0, 24, 0, 16)
spdMinus.Position = UDim2.new(0, 0, 0, 512)
spdMinus.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
spdMinus.BorderSizePixel = 0
spdMinus.Text = "-"
spdMinus.TextColor3 = Color3.fromRGB(200, 200, 200)
spdMinus.Font = Enum.Font.GothamBold
spdMinus.TextSize = 12
spdMinus.AutoButtonColor = false
spdMinus.Parent = content
Instance.new("UICorner", spdMinus).CornerRadius = UDim.new(0, 3)

local spdPlus = Instance.new("TextButton")
spdPlus.Size = UDim2.new(0, 24, 0, 16)
spdPlus.Position = UDim2.new(1, -24, 0, 512)
spdPlus.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
spdPlus.BorderSizePixel = 0
spdPlus.Text = "+"
spdPlus.TextColor3 = Color3.fromRGB(200, 200, 200)
spdPlus.Font = Enum.Font.GothamBold
spdPlus.TextSize = 12
spdPlus.AutoButtonColor = false
spdPlus.Parent = content
Instance.new("UICorner", spdPlus).CornerRadius = UDim.new(0, 3)

spdMinus.MouseButton1Click:Connect(function()
    speedMultiplier = math.max(speedMultiplier - 0.5, 1)
    speedLabel.Text = "Speed: x" .. speedMultiplier
    updateSpeed(speedMultiplier)
end)

spdPlus.MouseButton1Click:Connect(function()
    speedMultiplier = math.min(speedMultiplier + 0.5, 10)
    speedLabel.Text = "Speed: x" .. speedMultiplier
    updateSpeed(speedMultiplier)
end)

-- Fly Speed
local flyLabel = Instance.new("TextLabel")
flyLabel.Size = UDim2.new(1, 0, 0, 14)
flyLabel.Position = UDim2.new(0, 0, 0, 534)
flyLabel.BackgroundTransparency = 1
flyLabel.Text = "Fly Speed: " .. flySpeed
flyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
flyLabel.Font = Enum.Font.GothamSemibold
flyLabel.TextSize = 10
flyLabel.Parent = content

local flyMinusBtn = Instance.new("TextButton")
flyMinusBtn.Size = UDim2.new(0, 24, 0, 16)
flyMinusBtn.Position = UDim2.new(0, 0, 0, 550)
flyMinusBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
flyMinusBtn.BorderSizePixel = 0
flyMinusBtn.Text = "-"
flyMinusBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
flyMinusBtn.Font = Enum.Font.GothamBold
flyMinusBtn.TextSize = 12
flyMinusBtn.AutoButtonColor = false
flyMinusBtn.Parent = content
Instance.new("UICorner", flyMinusBtn).CornerRadius = UDim.new(0, 3)

local flyPlusBtn = Instance.new("TextButton")
flyPlusBtn.Size = UDim2.new(0, 24, 0, 16)
flyPlusBtn.Position = UDim2.new(1, -24, 0, 550)
flyPlusBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
flyPlusBtn.BorderSizePixel = 0
flyPlusBtn.Text = "+"
flyPlusBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
flyPlusBtn.Font = Enum.Font.GothamBold
flyPlusBtn.TextSize = 12
flyPlusBtn.AutoButtonColor = false
flyPlusBtn.Parent = content
Instance.new("UICorner", flyPlusBtn).CornerRadius = UDim.new(0, 3)

flyMinusBtn.MouseButton1Click:Connect(function()
    flySpeed = math.max(flySpeed - 10, 10)
    flyLabel.Text = "Fly Speed: " .. flySpeed
end)

flyPlusBtn.MouseButton1Click:Connect(function()
    flySpeed = math.min(flySpeed + 10, 200)
    flyLabel.Text = "Fly Speed: " .. flySpeed
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

-- Сворачивание
local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame:TweenSize(UDim2.new(0, 240, 0, 35), "Out", "Quad", 0.3)
        minimizeBtn.Text = "+"
    else
        mainFrame:TweenSize(UDim2.new(0, 240, 0, 580), "Out", "Quad", 0.3)
        minimizeBtn.Text = "-"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    screen.Enabled = false
    menuVisible = false
end)

-- Right Shift
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        menuVisible = not menuVisible
        screen.Enabled = menuVisible
    end
end)

-- Fly keys
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

-- Respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    
    wait(0.5)
    
    if godmode then setGodmode(false); setGodmode(true) end
    if noclip then setNoClip(false); setNoClip(true) end
    if antiAim then setAntiAim(false); setAntiAim(true) end
    if flying then stopFly(); flying = false; setFly(true) end
    if speedhack then setSpeedHack(false); setSpeedHack(true) end
    if triggerBot then setTriggerBot(false); setTriggerBot(true) end
    if silentAim then setSilentAim(false); setSilentAim(true) end
    if wallshot then setWallshot(false); setWallshot(true) end
end)

screen.Enabled = false