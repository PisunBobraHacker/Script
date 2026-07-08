-- // HuyilanHub v7.1 — Universal Rage Script for Xeno
-- // Wallshot: пуля игнорирует все препятствия

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
local esp = false
local noRecoil = false
local rapidFire = false
local fly = false
local speedHack = false
local noClip = false
local godMode = false
local antiAim = false
local wallShot = false
local triggerBot = false
local crosshair = false
local menuVisible = false

local aimbotFOV = 300
local flySpeed = 80
local speedMultiplier = 3
local aimSpeed = 1.5
local triggerDelay = 0.01
local rapidDelay = 0.02

local flyBV, flyBG, flyConn = nil, nil, nil
local connections = {}
local flyKeys = {W = false, A = false, S = false, D = false, Space = false, LeftControl = false}
local espObjects = {}
local fovCircle = nil
local crosshairGui = nil
local dropdownOpen = false
local rgbConn = nil
local lastTarget = nil

-- ==================== УТИЛИТЫ ====================
local function getChar() return LocalPlayer.Character end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar(); return c and c:FindFirstChild("Humanoid") end

local function findClosestEnemy()
    local closest, closestDist = nil, aimbotFOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local tp = plr.Character:FindFirstChild(aimbotPart)
            local hum = plr.Character:FindFirstChild("Humanoid")
            if tp and hum and hum.Health > 0 then
                local sp, vis = Camera:WorldToScreenPoint(tp.Position)
                if vis then
                    local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if d < closestDist then closestDist = d; closest = tp end
                end
            end
        end
    end
    return closest
end

-- ==================== GOD MODE ====================
local function setGodMode(state)
    godMode = state
    if state then
        connections.godmode = RunService.Heartbeat:Connect(function()
            pcall(function()
                local hum = getHum()
                if hum and hum.Health > 0 then hum.Health = hum.MaxHealth end
                local char = getChar()
                if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanTouch = false end end end
            end)
        end)
    else
        if connections.godmode then connections.godmode:Disconnect(); connections.godmode = nil end
        pcall(function() local char = getChar(); if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanTouch = true end end end end)
    end
end

-- ==================== NO CLIP ====================
local function setNoClip(state)
    noClip = state
    if state then
        connections.noclip = RunService.Stepped:Connect(function()
            pcall(function()
                local char = getChar(); local root = getRoot()
                if not char or not root then return end
                for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
                if root.Position.Y < -200 then root.CFrame = CFrame.new(0, 100, 0) end
                if root.Position.Magnitude > 10000 then root.CFrame = CFrame.new(0, 100, 0) end
            end)
        end)
    else
        if connections.noclip then connections.noclip:Disconnect(); connections.noclip = nil end
        pcall(function() local char = getChar(); if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end)
    end
end

-- ==================== ANTI AIM (RAGE) ====================
local function setAntiAim(state)
    antiAim = state
    if state then
        connections.antiaim = RunService.RenderStepped:Connect(function()
            pcall(function()
                local root = getRoot(); local hum = getHum()
                if not root or not hum then return end
                local camCF = Camera.CFrame
                hum.AutoRotate = false
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(tick() * 1200 % 360), 0)
                root.CFrame = root.CFrame * CFrame.Angles(math.rad(math.sin(tick() * 30) * 90), 0, math.rad(math.cos(tick() * 25) * 90))
                root.CFrame = root.CFrame + Vector3.new(math.sin(tick() * 40) * 3, math.cos(tick() * 35) * 3, math.sin(tick() * 38) * 3)
                Camera.CFrame = camCF
            end)
        end)
    else
        if connections.antiaim then connections.antiaim:Disconnect(); connections.antiaim = nil end
        pcall(function() local hum = getHum(); if hum then hum.AutoRotate = true end end)
    end
end

-- ==================== AIMBOT (RAGE) ====================
local function setAimbot(state)
    aimbot = state
    if state then
        lastTarget = nil
        spawn(function()
            while aimbot do
                pcall(function()
                    local target = findClosestEnemy()
                    if target then
                        local smooth = (lastTarget == target) and 0.4 or 0.7
                        lastTarget = target
                        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), smooth * aimSpeed / 2)
                    else
                        lastTarget = nil
                    end
                end)
                RunService.RenderStepped:Wait()
            end
        end)
    else
        lastTarget = nil
    end
end

-- ==================== SILENT AIM + WALLSHOT (пуля игнорирует всё) ====================
local function setSilentAim(state)
    silentAim = state
    if state then
        connections.silent = RunService.RenderStepped:Connect(function()
            pcall(function()
                local char = getChar()
                if not char then return end
                local tool = char:FindFirstChildOfClass("Tool")
                if not tool then return end
                local handle = tool:FindFirstChild("Handle") or tool.PrimaryPart
                if not handle then return end
                
                -- Ищем цель
                local closest, closestDist = nil, aimbotFOV
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local tp = plr.Character:FindFirstChild(aimbotPart)
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        if tp and hum and hum.Health > 0 then
                            local sp, vis = Camera:WorldToScreenPoint(tp.Position)
                            local d = vis and (Vector2.new(sp.X, sp.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude or 99999
                            if d < closestDist then closestDist = d; closest = tp end
                        end
                    end
                end
                
                if closest then
                    local dir = (closest.Position - handle.Position).Unit
                    
                    -- Поворачиваем ствол на цель
                    handle.CFrame = CFrame.new(handle.Position, handle.Position + dir)
                    
                    -- Wallshot: пуля телепортируется прямо в цель игнорируя ВСЁ
                    if wallShot then
                        -- Находим любую часть тела цели для попадания
                        local targetChar = closest.Parent
                        if targetChar then
                            local targetHum = targetChar:FindFirstChild("Humanoid")
                            if targetHum and targetHum.Health > 0 then
                                -- Создаем невидимую пулю прямо на цели
                                local bullet = Instance.new("Part")
                                bullet.Size = Vector3.new(1, 1, 1)
                                bullet.Position = closest.Position
                                bullet.Anchored = true
                                bullet.CanCollide = false
                                bullet.Transparency = 1
                                bullet.Parent = Workspace
                                
                                -- Мгновенная регистрация попадания
                                local targetPart = closest
                                firetouchinterest(bullet, targetPart, 0)
                                firetouchinterest(bullet, targetPart, 1)
                                
                                -- Дополнительно: наносим урон напрямую
                                targetHum:TakeDamage(100)
                                
                                -- Удаляем пулю
                                game:GetService("Debris"):AddItem(bullet, 0.02)
                            end
                        end
                    end
                end
            end)
        end)
    else
        if connections.silent then connections.silent:Disconnect(); connections.silent = nil end
    end
end

-- ==================== WALLSHOT ====================
local function setWallshot(state) 
    wallShot = state 
end

-- ==================== TRIGGER BOT (RAGE) ====================
local function setTriggerBot(state)
    triggerBot = state
    if state then
        connections.trigger = RunService.RenderStepped:Connect(function()
            pcall(function()
                local t = Mouse.Target
                if t and t.Parent then
                    local h = t.Parent:FindFirstChild("Humanoid")
                    if h and h.Health > 0 and t.Parent ~= getChar() then
                        mouse1press()
                        task.wait(triggerDelay)
                        mouse1release()
                    end
                end
            end)
        end)
    else
        if connections.trigger then connections.trigger:Disconnect(); connections.trigger = nil end
    end
end

-- ==================== RAPID FIRE ====================
local function setRapidFire(state)
    rapidFire = state
    if state then
        spawn(function()
            while rapidFire do
                pcall(function()
                    local char = getChar()
                    if char and char:FindFirstChildOfClass("Tool") and Mouse.Target and Mouse.Target.Parent then
                        local h = Mouse.Target.Parent:FindFirstChild("Humanoid")
                        if h and h.Health > 0 then
                            mouse1press()
                            task.wait(rapidDelay)
                            mouse1release()
                        end
                    end
                end)
                task.wait()
            end
        end)
    end
end

-- ==================== NO RECOIL ====================
local function setNoRecoil(state) noRecoil = state end

-- ==================== ESP ====================
local function createESP(plr)
    if not plr.Character then return end
    if espObjects[plr] then for _, o in ipairs(espObjects[plr]) do o:Destroy() end end
    local items = {}
    local hl = Instance.new("Highlight"); hl.FillColor = Color3.fromRGB(255, 50, 50); hl.FillTransparency = 0.4; hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 0; hl.Parent = plr.Character; table.insert(items, hl)
    local head = plr.Character:WaitForChild("Head", 5)
    if head then
        local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 120, 0, 40); bb.StudsOffset = Vector3.new(0, 3.5, 0); bb.AlwaysOnTop = true; bb.Parent = head
        local nm = Instance.new("TextLabel"); nm.Size = UDim2.new(1, 0, 0.5, 0); nm.BackgroundTransparency = 1; nm.Text = plr.Name; nm.TextColor3 = Color3.fromRGB(255, 255, 255); nm.Font = Enum.Font.GothamBold; nm.TextSize = 12; nm.Parent = bb
        local hp = Instance.new("TextLabel"); hp.Size = UDim2.new(1, 0, 0.5, 0); hp.Position = UDim2.new(0, 0, 0.5, 0); hp.BackgroundTransparency = 1; hp.Text = "HP: " .. math.floor(plr.Character.Humanoid.Health); hp.TextColor3 = Color3.fromRGB(255, 100, 100); hp.Font = Enum.Font.GothamBold; hp.TextSize = 11; hp.Parent = bb
        table.insert(items, bb)
    end
    espObjects[plr] = items
end

local function setESP(state)
    esp = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createESP(p) end end
        Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.5); if esp then createESP(p) end end) end)
    else
        for _, items in pairs(espObjects) do for _, o in ipairs(items) do o:Destroy() end end
        espObjects = {}
    end
end

-- ==================== FLY / SPEED ====================
local function startFly()
    local root = getRoot(); local hum = getHum()
    if not root or not hum then return end
    flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.one * 9e9; flyBV.P = 9000; flyBV.Velocity = Vector3.zero; flyBV.Parent = root
    flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.one * 9e9; flyBG.P = 9000; flyBG.D = 100; flyBG.CFrame = root.CFrame; flyBG.Parent = root
    hum.PlatformStand = true
    flyConn = RunService.Heartbeat:Connect(function()
        if not fly or not getRoot() or not getHum() then stopFly(); return end
        getHum().PlatformStand = true
        local cam = Camera; local dir = Vector3.zero
        if flyKeys.W then dir += cam.CFrame.LookVector end
        if flyKeys.S then dir -= cam.CFrame.LookVector end
        if flyKeys.A then dir -= cam.CFrame.RightVector end
        if flyKeys.D then dir += cam.CFrame.RightVector end
        if flyKeys.Space then dir += Vector3.yAxis end
        if flyKeys.LeftControl then dir -= Vector3.yAxis end
        if dir.Magnitude > 1 then dir = dir.Unit end
        if flyBV and flyBV.Parent then flyBV.Velocity = dir * flySpeed end
        if flyBG and flyBG.Parent then flyBG.CFrame = cam.CFrame * CFrame.Angles(-math.rad(90), 0, 0) end
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
    local hum = getHum(); if hum then hum.PlatformStand = false end
end

local function setFly(state) fly = state; if state then startFly() else stopFly() end end
local function setSpeedHack(state) speedHack = state; local hum = getHum(); if hum then hum.WalkSpeed = state and 16 * speedMultiplier or 16 end end
local function updateSpeed(m) speedMultiplier = m; if speedHack then local hum = getHum(); if hum then hum.WalkSpeed = 16 * m end end end

-- ==================== FOV / CROSSHAIR ====================
local function updateFOVCircle()
    if fovCircle then fovCircle:Destroy() end
    fovCircle = Instance.new("ScreenGui"); fovCircle.ResetOnSpawn = false; fovCircle.Parent = playerGui
    local c = Instance.new("Frame"); c.Size = UDim2.new(0, aimbotFOV * 2, 0, aimbotFOV * 2); c.Position = UDim2.new(0.5, -aimbotFOV, 0.5, -aimbotFOV); c.BackgroundTransparency = 1; c.Parent = fovCircle
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 50, 50); s.Transparency = 0.3; s.Thickness = 2; s.Parent = c
    Instance.new("UICorner", c).CornerRadius = UDim.new(1, 0)
end

local function setCrosshair(state)
    crosshair = state
    if state then
        if crosshairGui then crosshairGui:Destroy() end
        crosshairGui = Instance.new("ScreenGui"); crosshairGui.ResetOnSpawn = false; crosshairGui.Parent = playerGui
        local v = Instance.new("Frame"); v.Size = UDim2.new(0, 2, 0, 18); v.Position = UDim2.new(0.5, -1, 0.5, -9); v.BackgroundColor3 = Color3.fromRGB(255, 100, 100); v.BorderSizePixel = 0; v.Parent = crosshairGui
        local h = Instance.new("Frame"); h.Size = UDim2.new(0, 18, 0, 2); h.Position = UDim2.new(0.5, -9, 0.5, -1); h.BackgroundColor3 = Color3.fromRGB(255, 100, 100); h.BorderSizePixel = 0; h.Parent = crosshairGui
        local d = Instance.new("Frame"); d.Size = UDim2.new(0, 4, 0, 4); d.Position = UDim2.new(0.5, -2, 0.5, -2); d.BackgroundColor3 = Color3.fromRGB(255, 30, 30); d.BorderSizePixel = 0; Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0); d.Parent = crosshairGui
    else
        if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
    end
end

-- ==================== GUI ====================
local screen = Instance.new("ScreenGui"); screen.Parent = playerGui; screen.ResetOnSpawn = false; screen.Name = "HuyilanHub"; screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; screen.Enabled = false

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))})

local main = Instance.new("Frame"); main.Size = UDim2.new(0, 250, 0, 610); main.Position = UDim2.new(0, 30, 0.5, -305); main.BackgroundColor3 = Color3.fromRGB(8, 8, 8); main.BorderSizePixel = 0; main.BackgroundTransparency = 0.02; main.Parent = screen
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(255, 255, 255); mainStroke.Transparency = 0.6; mainStroke.Thickness = 1.5; mainStroke.Parent = main

local titleBar = Instance.new("Frame"); titleBar.Size = UDim2.new(1, 0, 0, 38); titleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255); titleBar.BorderSizePixel = 0; titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
local titleGradClone = titleGrad:Clone(); titleGradClone.Parent = titleBar

local titleText = Instance.new("TextLabel"); titleText.Size = UDim2.new(0.6, 0, 1, 0); titleText.Position = UDim2.new(0, 14, 0, 0); titleText.BackgroundTransparency = 1; titleText.Text = "HUYILAN HUB"; titleText.TextColor3 = Color3.fromRGB(255, 255, 255); titleText.Font = Enum.Font.GothamBlack; titleText.TextSize = 18; titleText.TextXAlignment = Enum.TextXAlignment.Left; titleText.Parent = titleBar

local minBtn = Instance.new("TextButton"); minBtn.Size = UDim2.new(0, 26, 0, 26); minBtn.Position = UDim2.new(1, -56, 0.5, -13); minBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); minBtn.BackgroundTransparency = 0.85; minBtn.BorderSizePixel = 0; minBtn.Text = "—"; minBtn.TextColor3 = Color3.fromRGB(255, 255, 255); minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 18; minBtn.Parent = titleBar; Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)
local clsBtn = Instance.new("TextButton"); clsBtn.Size = UDim2.new(0, 26, 0, 26); clsBtn.Position = UDim2.new(1, -26, 0.5, -13); clsBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50); clsBtn.BorderSizePixel = 0; clsBtn.Text = "X"; clsBtn.TextColor3 = Color3.fromRGB(255, 255, 255); clsBtn.Font = Enum.Font.GothamBold; clsBtn.TextSize = 15; clsBtn.Parent = titleBar; Instance.new("UICorner", clsBtn).CornerRadius = UDim.new(0, 5)

local content = Instance.new("Frame"); content.Size = UDim2.new(1, -20, 1, -48); content.Position = UDim2.new(0, 10, 0, 44); content.BackgroundTransparency = 1; content.Parent = main

-- RGB
local function startRGB()
    if rgbConn then rgbConn:Disconnect() end
    rgbConn = RunService.RenderStepped:Connect(function()
        local hue = (tick() * 60) % 360
        titleGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromHSV(((hue)%360)/360,1,1)),ColorSequenceKeypoint.new(0.25, Color3.fromHSV(((hue+60)%360)/360,1,1)),ColorSequenceKeypoint.new(0.5, Color3.fromHSV(((hue+120)%360)/360,1,1)),ColorSequenceKeypoint.new(0.75, Color3.fromHSV(((hue+180)%360)/360,1,1)),ColorSequenceKeypoint.new(1, Color3.fromHSV(((hue+240)%360)/360,1,1))})
        titleGradClone.Color = titleGrad.Color
        mainStroke.Color = Color3.fromHSV(((hue+180)%360)/360,1,1)
    end)
end
startRGB()

local function createToggle(name, y, cb)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 30); btn.Position = UDim2.new(0, 0, 0, y); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); btn.BorderSizePixel = 0; btn.Text = name .. ": OFF"; btn.TextColor3 = Color3.fromRGB(220, 220, 220); btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.AutoButtonColor = false; btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local stk = Instance.new("UIStroke"); stk.Color = Color3.fromRGB(40, 40, 40); stk.Thickness = 0.5; stk.Parent = btn
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.Text = name .. ": " .. (on and "ON" or "OFF")
        btn.BackgroundColor3 = on and Color3.fromRGB(120, 0, 180) or Color3.fromRGB(25, 25, 25)
        stk.Color = on and Color3.fromRGB(200, 50, 255) or Color3.fromRGB(40, 40, 40)
        cb(on)
    end)
    return btn
end

createToggle("AIMBOT", 0, setAimbot); updateFOVCircle()

-- Aim Part
local partLabel = Instance.new("TextLabel"); partLabel.Size = UDim2.new(1, 0, 0, 16); partLabel.Position = UDim2.new(0, 0, 0, 34); partLabel.BackgroundTransparency = 1; partLabel.Text = "PART: HEAD"; partLabel.TextColor3 = Color3.fromRGB(200, 150, 255); partLabel.Font = Enum.Font.GothamBold; partLabel.TextSize = 10; partLabel.TextXAlignment = Enum.TextXAlignment.Left; partLabel.Parent = content
local partBtn = Instance.new("TextButton"); partBtn.Size = UDim2.new(1, 0, 0, 22); partBtn.Position = UDim2.new(0, 0, 0, 52); partBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); partBtn.BorderSizePixel = 0; partBtn.Text = "SELECT PART [V]"; partBtn.TextColor3 = Color3.fromRGB(220, 220, 220); partBtn.Font = Enum.Font.GothamBold; partBtn.TextSize = 10; partBtn.AutoButtonColor = false; partBtn.Parent = content; Instance.new("UICorner", partBtn).CornerRadius = UDim.new(0, 4)
local partList = Instance.new("Frame"); partList.Size = UDim2.new(1, 0, 0, 0); partList.Position = UDim2.new(0, 0, 0, 76); partList.BackgroundColor3 = Color3.fromRGB(20, 20, 20); partList.BorderSizePixel = 0; partList.Visible = false; partList.ClipsDescendants = true; partList.Parent = content; Instance.new("UICorner", partList).CornerRadius = UDim.new(0, 4)
local parts = {"HEAD", "TORSO", "LEFT ARM", "RIGHT ARM", "LEFT LEG", "RIGHT LEG"}
for i, pn in ipairs(parts) do
    local pb = Instance.new("TextButton"); pb.Size = UDim2.new(1, 0, 0, 22); pb.Position = UDim2.new(0, 0, 0, (i-1)*24); pb.BackgroundColor3 = aimbotPart == pn and Color3.fromRGB(120, 0, 180) or Color3.fromRGB(35, 35, 35); pb.BorderSizePixel = 0; pb.Text = pn; pb.TextColor3 = Color3.fromRGB(220, 220, 220); pb.Font = Enum.Font.GothamBold; pb.TextSize = 10; pb.AutoButtonColor = false; pb.Parent = partList
    pb.MouseButton1Click:Connect(function() aimbotPart = pn; partLabel.Text = "PART: " .. pn; partList.Visible = false; dropdownOpen = false; for _, b in ipairs(partList:GetChildren()) do if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end end; pb.BackgroundColor3 = Color3.fromRGB(120, 0, 180) end)
end
partBtn.MouseButton1Click:Connect(function() dropdownOpen = not dropdownOpen; partList.Visible = dropdownOpen; if dropdownOpen then partList.Size = UDim2.new(1, 0, 0, #parts * 24) end end)

createToggle("SILENT AIM", 78, setSilentAim)
createToggle("TRIGGER BOT", 112, setTriggerBot)
createToggle("ESP", 146, setESP)
createToggle("NO RECOIL", 180, setNoRecoil)
createToggle("RAPID FIRE", 214, setRapidFire)
createToggle("WALLSHOT", 248, setWallshot)
createToggle("ANTI AIM", 282, setAntiAim)
createToggle("GOD MODE", 316, setGodMode)
createToggle("NO CLIP", 350, setNoClip)
createToggle("FLY", 384, setFly)
createToggle("SPEED HACK", 418, setSpeedHack)
createToggle("CROSSHAIR", 452, setCrosshair)

-- Слайдеры
local function makeSlider(label, y, min, max, step, get, set, fmt)
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, 0, 0, 14); lbl.Position = UDim2.new(0, 0, 0, y); lbl.BackgroundTransparency = 1; lbl.Text = label .. ": " .. fmt(get()); lbl.TextColor3 = Color3.fromRGB(200, 200, 200); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = content
    local minus = Instance.new("TextButton"); minus.Size = UDim2.new(0, 26, 0, 16); minus.Position = UDim2.new(0, 0, 0, y + 16); minus.BackgroundColor3 = Color3.fromRGB(30, 30, 30); minus.BorderSizePixel = 0; minus.Text = "-"; minus.TextColor3 = Color3.fromRGB(220, 220, 220); minus.Font = Enum.Font.GothamBold; minus.TextSize = 14; minus.AutoButtonColor = false; minus.Parent = content; Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 3)
    local plus = Instance.new("TextButton"); plus.Size = UDim2.new(0, 26, 0, 16); plus.Position = UDim2.new(1, -26, 0, y + 16); plus.BackgroundColor3 = Color3.fromRGB(30, 30, 30); plus.BorderSizePixel = 0; plus.Text = "+"; plus.TextColor3 = Color3.fromRGB(220, 220, 220); plus.Font = Enum.Font.GothamBold; plus.TextSize = 14; plus.AutoButtonColor = false; plus.Parent = content; Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 3)
    minus.MouseButton1Click:Connect(function() local v = math.max(get() - step, min); set(v); lbl.Text = label .. ": " .. fmt(v) end)
    plus.MouseButton1Click:Connect(function() local v = math.min(get() + step, max); set(v); lbl.Text = label .. ": " .. fmt(v) end)
    return lbl
end

makeSlider("AIM SPEED", 488, 0.3, 5, 0.2, function() return aimSpeed end, function(v) aimSpeed = v end, function(v) return "x" .. v end)
makeSlider("FOV", 514, 50, 800, 25, function() return aimbotFOV end, function(v) aimbotFOV = v; updateFOVCircle() end, tostring)
makeSlider("SPEED", 540, 1, 10, 0.5, function() return speedMultiplier end, function(v) speedMultiplier = v; updateSpeed(v) end, function(v) return "x" .. v end)
makeSlider("FLY SPD", 566, 10, 300, 10, function() return flySpeed end, function(v) flySpeed = v end, tostring)

-- Drag
local drag = false; local ds, fs
titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; ds = i.Position; fs = main.Position end end)
UserInputService.InputChanged:Connect(function(i) if drag then local d = i.Position - ds; main.Position = UDim2.new(fs.X.Scale, fs.X.Offset + d.X, fs.Y.Scale, fs.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)

-- Minimize
local minimized = false
minBtn.MouseButton1Click:Connect(function() minimized = not minimized; if minimized then main:TweenSize(UDim2.new(0, 250, 0, 38), "Out", "Quad", 0.3); minBtn.Text = "+" else main:TweenSize(UDim2.new(0, 250, 0, 610), "Out", "Quad", 0.3); minBtn.Text = "—" end end)
clsBtn.MouseButton1Click:Connect(function() screen.Enabled = false; menuVisible = false end)

-- Right Shift
UserInputService.InputBegan:Connect(function(i, p) if p then return end; if i.KeyCode == Enum.KeyCode.RightShift then menuVisible = not menuVisible; screen.Enabled = menuVisible end end)

-- Fly keys
UserInputService.InputBegan:Connect(function(i, p) if p then return end; local k = i.KeyCode; if k == Enum.KeyCode.W then flyKeys.W = true elseif k == Enum.KeyCode.A then flyKeys.A = true elseif k == Enum.KeyCode.S then flyKeys.S = true elseif k == Enum.KeyCode.D then flyKeys.D = true elseif k == Enum.KeyCode.Space then flyKeys.Space = true elseif k == Enum.KeyCode.LeftControl then flyKeys.LeftControl = true end end)
UserInputService.InputEnded:Connect(function(i) local k = i.KeyCode; if k == Enum.KeyCode.W then flyKeys.W = false elseif k == Enum.KeyCode.A then flyKeys.A = false elseif k == Enum.KeyCode.S then flyKeys.S = false elseif k == Enum.KeyCode.D then flyKeys.D = false elseif k == Enum.KeyCode.Space then flyKeys.Space = false elseif k == Enum.KeyCode.LeftControl then flyKeys.LeftControl = false end end)

-- Respawn
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c; Humanoid = c:WaitForChild("Humanoid"); HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    if godMode then setGodMode(false); setGodMode(true) end
    if noClip then setNoClip(false); setNoClip(true) end
    if antiAim then setAntiAim(false); setAntiAim(true) end
    if fly then stopFly(); fly = false; setFly(true) end
    if speedHack then setSpeedHack(false); setSpeedHack(true) end
    if triggerBot then setTriggerBot(false); setTriggerBot(true) end
    if silentAim then setSilentAim(false); setSilentAim(true) end
end)

screen.Enabled = false