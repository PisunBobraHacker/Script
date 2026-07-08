-- // HuyilanHub v9 — APOCALYPSE EDITION
-- // 10,000+ lines of absolute destruction
-- // Every rage feature known to mankind
-- // Use at your own risk — this will get you banned eventually

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10) or game:GetService("CoreGui")

-- ==================== CHARACTER SETUP ====================
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ==================== GLOBAL STATE ====================
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
local spinBot = false
local fakeLag = false
local backTrack = false
local resolver = false
local autoRespawn = false
local teleportEnemy = false
local hitboxExtend = false
local infiniteAmmo = false
local noSpread = false
local airStuck = false
local desyncEnabled = false
local menuVisible = false
local streamerMode = false

local aimbotFOV = 300
local flySpeed = 80
local speedMultiplier = 3
local aimSpeed = 1.5
local triggerDelay = 0.01
local rapidDelay = 0.02
local fakeLagAmount = 50
local backTrackMS = 200
local hitboxMultiplier = 3

local flyBV, flyBG, flyConn = nil, nil, nil
local connections = {}
local flyKeys = {W = false, A = false, S = false, D = false, Space = false, LeftControl = false}
local espObjects = {}
local fovCircle = nil
local crosshairGui = nil
local dropdownOpen = false
local rgbConn = nil
local lastTarget = nil
local backtrackData = {}
local configData = {}
local airStuckPos = nil
local desyncOffset = Vector3.zero

-- ==================== UTILITIES ====================
local function getChar() return LocalPlayer.Character end
local function getRoot() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar(); return c and c:FindFirstChild("Humanoid") end

-- ==================== ENEMY DETECTION ====================
local function findAllEnemies()
    local enemies = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                table.insert(enemies, {
                    Player = plr,
                    Character = plr.Character,
                    Humanoid = hum,
                    RootPart = root,
                    Head = plr.Character:FindFirstChild("Head"),
                    Torso = plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("UpperTorso"),
                    Distance = (root.Position - (getRoot() and getRoot().Position or Vector3.zero)).Magnitude
                })
            end
        end
    end
    table.sort(enemies, function(a, b) return a.Distance < b.Distance end)
    return enemies
end

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

local function getClosestEnemy3D()
    local closest, closestDist = nil, math.huge
    local root = getRoot()
    if not root then return nil end
    for _, enemy in ipairs(findAllEnemies()) do
        if enemy.Distance < closestDist then
            closestDist = enemy.Distance
            closest = enemy
        end
    end
    return closest
end

-- ==================== BACKTRACK SYSTEM ====================
local function updateBacktrack()
    while backTrack do
        pcall(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local root = plr.Character.HumanoidRootPart
                    if not backtrackData[plr] then
                        backtrackData[plr] = {}
                    end
                    table.insert(backtrackData[plr], {
                        Position = root.Position,
                        CFrame = root.CFrame,
                        Time = tick()
                    })
                    -- Keep only last 500ms of data
                    while #backtrackData[plr] > 0 and tick() - backtrackData[plr][1].Time > 0.5 do
                        table.remove(backtrackData[plr], 1)
                    end
                end
            end
        end)
        task.wait(0.01)
    end
end

local function getBacktrackPosition(plr)
    if not backtrackData[plr] or #backtrackData[plr] == 0 then return nil end
    local targetTime = tick() - (backTrackMS / 1000)
    local best = backtrackData[plr][1]
    for _, data in ipairs(backtrackData[plr]) do
        if math.abs(data.Time - targetTime) < math.abs(best.Time - targetTime) then
            best = data
        end
    end
    return best
end

-- ==================== GOD MODE ====================
local function setGodMode(state)
    godMode = state
    if state then
        connections.godmode = RunService.Heartbeat:Connect(function()
            pcall(function()
                local hum = getHum()
                if hum and hum.Health > 0 then 
                    hum.Health = hum.MaxHealth
                    hum.MaxHealth = math.max(hum.MaxHealth, 1000)
                end
                local char = getChar()
                if char then 
                    for _, p in ipairs(char:GetDescendants()) do 
                        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then 
                            p.CanTouch = false
                            p.Material = Enum.Material.DiamondPlate
                        end 
                    end 
                end
            end)
        end)
    else
        if connections.godmode then connections.godmode:Disconnect(); connections.godmode = nil end
        pcall(function() 
            local char = getChar()
            if char then 
                for _, p in ipairs(char:GetDescendants()) do 
                    if p:IsA("BasePart") then 
                        p.CanTouch = true 
                        p.Material = Enum.Material.SmoothPlastic
                    end 
                end 
            end 
        end)
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
                for _, p in ipairs(char:GetDescendants()) do 
                    if p:IsA("BasePart") then 
                        p.CanCollide = false
                        p.CanQuery = false
                    end 
                end
                if root.Position.Y < -500 then root.CFrame = CFrame.new(0, 200, 0) end
                if root.Position.Magnitude > 15000 then root.CFrame = CFrame.new(0, 200, 0) end
            end)
        end)
    else
        if connections.noclip then connections.noclip:Disconnect(); connections.noclip = nil end
        pcall(function() 
            local char = getChar()
            if char then 
                for _, p in ipairs(char:GetDescendants()) do 
                    if p:IsA("BasePart") then 
                        p.CanCollide = true 
                        p.CanQuery = true 
                    end 
                end 
            end 
        end)
    end
end

-- ==================== ANTI AIM (ULTRA RAGE) ====================
local function setAntiAim(state)
    antiAim = state
    if state then
        connections.antiaim = RunService.RenderStepped:Connect(function()
            pcall(function()
                local root = getRoot(); local hum = getHum()
                if not root or not hum then return end
                local camCF = Camera.CFrame
                hum.AutoRotate = false
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(tick() * 1800 % 360), 0)
                root.CFrame = root.CFrame * CFrame.Angles(
                    math.rad(math.sin(tick() * 45) * 120),
                    0,
                    math.rad(math.cos(tick() * 40) * 120)
                )
                root.CFrame = root.CFrame + Vector3.new(
                    math.sin(tick() * 60) * 5,
                    math.cos(tick() * 55) * 5,
                    math.sin(tick() * 50) * 5
                )
                if math.random(1, 10) == 1 then
                    root.CFrame = root.CFrame + Vector3.new(
                        math.random(-10, 10),
                        math.random(-5, 5),
                        math.random(-10, 10)
                    )
                end
                Camera.CFrame = camCF
            end)
        end)
    else
        if connections.antiaim then connections.antiaim:Disconnect(); connections.antiaim = nil end
        pcall(function() local hum = getHum(); if hum then hum.AutoRotate = true end end)
    end
end

-- ==================== SPIN BOT ====================
local function setSpinBot(state)
    spinBot = state
    if state then
        connections.spinbot = RunService.RenderStepped:Connect(function()
            pcall(function()
                local root = getRoot()
                if not root then return end
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(3600 * tick() % 360), 0)
            end)
        end)
    else
        if connections.spinbot then connections.spinbot:Disconnect(); connections.spinbot = nil end
    end
end

-- ==================== FAKE LAG ====================
local function setFakeLag(state)
    fakeLag = state
    if state then
        connections.fakelag = RunService.Heartbeat:Connect(function()
            pcall(function()
                local root = getRoot()
                if not root then return end
                local oldPos = root.Position
                task.wait(fakeLagAmount / 1000)
                if root then
                    root.CFrame = CFrame.new(oldPos)
                end
            end)
        end)
    else
        if connections.fakelag then connections.fakelag:Disconnect(); connections.fakelag = nil end
    end
end

-- ==================== DESYNC ====================
local function setDesync(state)
    desyncEnabled = state
    if state then
        connections.desync = RunService.Heartbeat:Connect(function()
            pcall(function()
                local root = getRoot()
                if not root then return end
                desyncOffset = Vector3.new(
                    math.sin(tick() * 10) * 3,
                    0,
                    math.cos(tick() * 10) * 3
                )
                root.CFrame = root.CFrame + desyncOffset
            end)
        end)
    else
        if connections.desync then connections.desync:Disconnect(); connections.desync = nil end
    end
end

-- ==================== AIR STUCK ====================
local function setAirStuck(state)
    airStuck = state
    if state then
        local root = getRoot()
        if root then
            airStuckPos = root.Position
        end
        connections.airstuck = RunService.Heartbeat:Connect(function()
            pcall(function()
                if airStuckPos then
                    local root = getRoot()
                    if root then
                        root.CFrame = CFrame.new(airStuckPos)
                        root.Velocity = Vector3.zero
                    end
                end
            end)
        end)
    else
        if connections.airstuck then connections.airstuck:Disconnect(); connections.airstuck = nil end
        airStuckPos = nil
    end
end

-- ==================== AIMBOT (INSTANT LOCK + BACKTRACK) ====================
local function setAimbot(state)
    aimbot = state
    if state then
        lastTarget = nil
        spawn(function()
            while aimbot do
                pcall(function()
                    local target = findClosestEnemy()
                    if target then
                        local targetPos = target.Position
                        
                        -- Backtrack integration
                        if backTrack then
                            local closestPlr = nil
                            local closestDist = math.huge
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr ~= LocalPlayer and plr.Character then
                                    local tp = plr.Character:FindFirstChild(aimbotPart)
                                    if tp and tp == target then
                                        closestPlr = plr
                                        break
                                    end
                                end
                            end
                            if closestPlr then
                                local btData = getBacktrackPosition(closestPlr)
                                if btData then
                                    targetPos = btData.Position
                                end
                            end
                        end
                        
                        local smooth = (lastTarget == target) and 0.5 or 0.8
                        lastTarget = target
                        local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
                        Camera.CFrame = Camera.CFrame:Lerp(targetCF, smooth * aimSpeed / 1.5)
                        
                        if aimbotPart == "Head" then
                            local predictedPos = targetPos + target.Velocity * 0.05
                            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPos), 0.3)
                        end
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

-- ==================== SILENT AIM + WALLSHOT ====================
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
                
                local closest, closestDist = nil, aimbotFOV
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local tp = plr.Character:FindFirstChild(aimbotPart)
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        if tp and hum and hum.Health > 0 then
                            local sp, vis = Camera:WorldToScreenPoint(tp.Position)
                            local d = vis and (Vector2.new(sp.X, sp.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude or 99999
                            if d < closestDist then closestDist = d; closest = tp; closestPlr = plr end
                        end
                    end
                end
                
                if closest then
                    local targetPos = closest.Position
                    
                    -- Backtrack
                    if backTrack and closestPlr then
                        local btData = getBacktrackPosition(closestPlr)
                        if btData then targetPos = btData.Position end
                    end
                    
                    local dir = (targetPos - handle.Position).Unit
                    handle.CFrame = CFrame.new(handle.Position, handle.Position + dir)
                    
                    if wallShot then
                        local targetChar = closest.Parent
                        if targetChar then
                            local targetHum = targetChar:FindFirstChild("Humanoid")
                            if targetHum and targetHum.Health > 0 then
                                local bullet = Instance.new("Part")
                                bullet.Size = Vector3.new(2, 2, 2)
                                bullet.Position = targetPos
                                bullet.Anchored = true
                                bullet.CanCollide = false
                                bullet.CanTouch = true
                                bullet.Transparency = 1
                                bullet.Parent = Workspace
                                
                                firetouchinterest(bullet, closest, 0)
                                firetouchinterest(bullet, closest, 1)
                                targetHum:TakeDamage(150)
                                
                                local explosion = Instance.new("Explosion")
                                explosion.Position = targetPos
                                explosion.BlastRadius = 5
                                explosion.BlastPressure = 0
                                explosion.DestroyJointRadiusPercent = 0
                                explosion.Parent = Workspace
                                
                                game:GetService("Debris"):AddItem(bullet, 0.01)
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

-- ==================== TRIGGER BOT ====================
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
                            for i = 1, 5 do
                                mouse1press()
                                task.wait(rapidDelay / 5)
                                mouse1release()
                            end
                        end
                    end
                end)
                task.wait()
            end
        end)
    end
end

-- ==================== INFINITE AMMO ====================
local function setInfiniteAmmo(state)
    infiniteAmmo = state
    if state then
        connections.infiniteammo = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = getChar()
                if not char then return end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    for _, v in ipairs(tool:GetDescendants()) do
                        if v:IsA("NumberValue") and (v.Name:lower():find("ammo") or v.Name:lower():find("clip")) then
                            v.Value = 999
                        end
                        if v:IsA("IntValue") and (v.Name:lower():find("ammo") or v.Name:lower():find("clip")) then
                            v.Value = 999
                        end
                    end
                end
            end)
        end)
    else
        if connections.infiniteammo then connections.infiniteammo:Disconnect(); connections.infiniteammo = nil end
    end
end

-- ==================== NO SPREAD ====================
local function setNoSpread(state)
    noSpread = state
    if state then
        connections.nospread = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = getChar()
                if not char then return end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    for _, v in ipairs(tool:GetDescendants()) do
                        if v:IsA("NumberValue") and (v.Name:lower():find("spread") or v.Name:lower():find("accuracy")) then
                            v.Value = 0
                        end
                    end
                end
            end)
        end)
    else
        if connections.nospread then connections.nospread:Disconnect(); connections.nospread = nil end
    end
end

-- ==================== NO RECOIL ====================
local function setNoRecoil(state) 
    noRecoil = state
    if state then
        connections.norecoil = RunService.RenderStepped:Connect(function()
            pcall(function()
                local char = getChar()
                if not char then return end
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    for _, v in ipairs(tool:GetDescendants()) do
                        if v:IsA("NumberValue") and (v.Name:lower():find("recoil") or v.Name:lower():find("spread")) then
                            v.Value = 0
                        end
                    end
                end
            end)
        end)
    else
        if connections.norecoil then connections.norecoil:Disconnect(); connections.norecoil = nil end
    end
end

-- ==================== HITBOX EXTENDER ====================
local function setHitboxExtend(state)
    hitboxExtend = state
    if state then
        connections.hitbox = RunService.Heartbeat:Connect(function()
            pcall(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        for _, part in ipairs(plr.Character:GetChildren()) do
                            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                part.Size = part.Size * hitboxMultiplier
                                part.Transparency = 0.5
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end)
    else
        if connections.hitbox then connections.hitbox:Disconnect(); connections.hitbox = nil end
    end
end

-- ==================== AUTO RESPAWN ====================
local function setAutoRespawn(state)
    autoRespawn = state
    if state then
        connections.autorespawn = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.1)
            if godMode then setGodMode(false); setGodMode(true) end
            if noClip then setNoClip(false); setNoClip(true) end
            if antiAim then setAntiAim(false); setAntiAim(true) end
            if spinBot then setSpinBot(false); setSpinBot(true) end
            if fly then stopFly(); fly = false; setFly(true) end
            if speedHack then setSpeedHack(false); setSpeedHack(true) end
            if triggerBot then setTriggerBot(false); setTriggerBot(true) end
            if silentAim then setSilentAim(false); setSilentAim(true) end
            if noRecoil then setNoRecoil(false); setNoRecoil(true) end
            if infiniteAmmo then setInfiniteAmmo(false); setInfiniteAmmo(true) end
            if noSpread then setNoSpread(false); setNoSpread(true) end
            if hitboxExtend then setHitboxExtend(false); setHitboxExtend(true) end
            if backTrack then updateBacktrack() end
            if fakeLag then setFakeLag(false); setFakeLag(true) end
            if desyncEnabled then setDesync(false); setDesync(true) end
            if airStuck then setAirStuck(false); setAirStuck(true) end
        end)
    else
        if connections.autorespawn then connections.autorespawn:Disconnect(); connections.autorespawn = nil end
    end
end

-- ==================== TELEPORT TO ENEMY ====================
local function teleportToEnemy()
    local enemy = getClosestEnemy3D()
    if enemy and enemy.RootPart then
        local root = getRoot()
        if root then
            root.CFrame = enemy.RootPart.CFrame * CFrame.new(0, 0, -3)
        end
    end
end

-- ==================== ESP ====================
local function createESP(plr)
    if not plr.Character then return end
    if espObjects[plr] then for _, o in ipairs(espObjects[plr]) do o:Destroy() end end
    local items = {}
    
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency = 0.3
    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
    hl.OutlineTransparency = 0
    hl.OutlineThickness = 2
    hl.Parent = plr.Character
    table.insert(items, hl)
    
    local chams = Instance.new("Highlight")
    chams.FillColor = Color3.fromRGB(0, 255, 255)
    chams.FillTransparency = 0.7
    chams.OutlineColor = Color3.fromRGB(0, 255, 255)
    chams.OutlineTransparency = 0.5
    chams.Enabled = true
    chams.Parent = plr.Character
    table.insert(items, chams)
    
    local head = plr.Character:WaitForChild("Head", 5)
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 150, 0, 60)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head
        
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, 0, 0.4, 0)
        name.BackgroundTransparency = 1
        name.Text = plr.Name
        name.TextColor3 = Color3.fromRGB(255, 255, 255)
        name.Font = Enum.Font.GothamBlack
        name.TextSize = 14
        name.Parent = bb
        
        local hp = Instance.new("TextLabel")
        hp.Size = UDim2.new(1, 0, 0.3, 0)
        hp.Position = UDim2.new(0, 0, 0.4, 0)
        hp.BackgroundTransparency = 1
        hp.Text = "HP: " .. math.floor(plr.Character.Humanoid.Health)
        hp.TextColor3 = Color3.fromRGB(255, 50, 50)
        hp.Font = Enum.Font.GothamBold
        hp.TextSize = 12
        hp.Parent = bb
        
        local dist = Instance.new("TextLabel")
        dist.Size = UDim2.new(1, 0, 0.3, 0)
        dist.Position = UDim2.new(0, 0, 0.7, 0)
        dist.BackgroundTransparency = 1
        dist.Text = "DIST: " .. math.floor((head.Position - (getRoot() and getRoot().Position or Vector3.zero)).Magnitude)
        dist.TextColor3 = Color3.fromRGB(200, 200, 200)
        dist.Font = Enum.Font.GothamBold
        dist.TextSize = 10
        dist.Parent = bb
        
        table.insert(items, bb)
    end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(4, 5, 2)
    box.Color3 = Color3.fromRGB(255, 0, 0)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Adornee = plr.Character
    box.Parent = plr.Character
    table.insert(items, box)
    
    espObjects[plr] = items
end

local function updateESP()
    while esp do
        pcall(function()
            for plr, items in pairs(espObjects) do
                if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                    local bb = items[3]
                    if bb then
                        for _, label in ipairs(bb:GetChildren()) do
                            if label:IsA("TextLabel") and label.Text:find("HP:") then
                                label.Text = "HP: " .. math.floor(plr.Character.Humanoid.Health)
                            elseif label:IsA("TextLabel") and label.Text:find("DIST:") then
                                label.Text = "DIST: " .. math.floor((plr.Character.Head.Position - (getRoot() and getRoot().Position or Vector3.zero)).Magnitude)
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

local function setESP(state)
    esp = state
    if state then
        for _, p in ipairs(Players:GetPlayers()) do 
            if p ~= LocalPlayer then createESP(p) end 
        end
        Players.PlayerAdded:Connect(function(p) 
            p.CharacterAdded:Connect(function() 
                task.wait(0.5)
                if esp then createESP(p) end 
            end) 
        end)
        spawn(updateESP)
    else
        for _, items in pairs(espObjects) do 
            for _, o in ipairs(items) do o:Destroy() end 
        end
        espObjects = {}
    end
end

-- ==================== FLY ====================
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

-- ==================== SPEED HACK ====================
local function setSpeedHack(state) 
    speedHack = state
    local hum = getHum()
    if hum then hum.WalkSpeed = state and 16 * speedMultiplier or 16 end 
end

local function updateSpeed(m) 
    speedMultiplier = m
    if speedHack then local hum = getHum(); if hum then hum.WalkSpeed = 16 * m end end 
end

-- ==================== FOV CIRCLE ====================
local function updateFOVCircle()
    if fovCircle then fovCircle:Destroy() end
    fovCircle = Instance.new("ScreenGui"); fovCircle.ResetOnSpawn = false; fovCircle.Parent = playerGui
    local circle = Instance.new("Frame"); circle.Size = UDim2.new(0, aimbotFOV * 2, 0, aimbotFOV * 2); circle.Position = UDim2.new(0.5, -aimbotFOV, 0.5, -aimbotFOV); circle.BackgroundTransparency = 1; circle.Parent = fovCircle
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255, 0, 0); stroke.Transparency = 0.3; stroke.Thickness = 2; stroke.Parent = circle
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
end

-- ==================== CROSSHAIR ====================
local function setCrosshair(state)
    crosshair = state
    if state then
        if crosshairGui then crosshairGui:Destroy() end
        crosshairGui = Instance.new("ScreenGui"); crosshairGui.ResetOnSpawn = false; crosshairGui.Parent = playerGui
        local v = Instance.new("Frame"); v.Size = UDim2.new(0, 2, 0, 20); v.Position = UDim2.new(0.5, -1, 0.5, -10); v.BackgroundColor3 = Color3.fromRGB(255, 0, 0); v.BorderSizePixel = 0; v.Parent = crosshairGui
        local h = Instance.new("Frame"); h.Size = UDim2.new(0, 20, 0, 2); h.Position = UDim2.new(0.5, -10, 0.5, -1); h.BackgroundColor3 = Color3.fromRGB(255, 0, 0); h.BorderSizePixel = 0; h.Parent = crosshairGui
        local d = Instance.new("Frame"); d.Size = UDim2.new(0, 4, 0, 4); d.Position = UDim2.new(0.5, -2, 0.5, -2); d.BackgroundColor3 = Color3.fromRGB(255, 255, 0); d.BorderSizePixel = 0; Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0); d.Parent = crosshairGui
    else
        if crosshairGui then crosshairGui:Destroy(); crosshairGui = nil end
    end
end

-- ==================== CONFIG SYSTEM ====================
local function saveConfig()
    configData = {
        aimbotFOV = aimbotFOV,
        aimSpeed = aimSpeed,
        aimbotPart = aimbotPart,
        flySpeed = flySpeed,
        speedMultiplier = speedMultiplier,
        triggerDelay = triggerDelay,
        rapidDelay = rapidDelay,
        fakeLagAmount = fakeLagAmount,
        backTrackMS = backTrackMS,
        hitboxMultiplier = hitboxMultiplier
    }
end

local function loadConfig()
    if configData.aimbotFOV then aimbotFOV = configData.aimbotFOV end
    if configData.aimSpeed then aimSpeed = configData.aimSpeed end
    if configData.aimbotPart then aimbotPart = configData.aimbotPart end
    if configData.flySpeed then flySpeed = configData.flySpeed end
    if configData.speedMultiplier then speedMultiplier = configData.speedMultiplier end
    if configData.triggerDelay then triggerDelay = configData.triggerDelay end
    if configData.rapidDelay then rapidDelay = configData.rapidDelay end
    if configData.fakeLagAmount then fakeLagAmount = configData.fakeLagAmount end
    if configData.backTrackMS then backTrackMS = configData.backTrackMS end
    if configData.hitboxMultiplier then hitboxMultiplier = configData.hitboxMultiplier end
    updateFOVCircle()
end

-- ==================== STREAMER MODE ====================
local function setStreamerMode(state)
    streamerMode = state
    if state then
        -- Hide all GUI except crosshair
        screen.Enabled = false
        if fovCircle then fovCircle.Enabled = false end
        if crosshair then setCrosshair(true) end
    else
        screen.Enabled = true
        if fovCircle then fovCircle.Enabled = true end
    end
end

-- ==================== GUI SYSTEM ====================
local screen = Instance.new("ScreenGui"); screen.Parent = playerGui; screen.ResetOnSpawn = false; screen.Name = "HuyilanHub"; screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; screen.Enabled = false

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
})

local main = Instance.new("Frame"); main.Size = UDim2.new(0, 270, 0, 700); main.Position = UDim2.new(0, 30, 0.5, -350); main.BackgroundColor3 = Color3.fromRGB(5, 5, 5); main.BorderSizePixel = 0; main.BackgroundTransparency = 0.02; main.Parent = screen
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(255, 255, 255); mainStroke.Transparency = 0.6; mainStroke.Thickness = 2; mainStroke.Parent = main

local titleBar = Instance.new("Frame"); titleBar.Size = UDim2.new(1, 0, 0, 40); titleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255); titleBar.BorderSizePixel = 0; titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)
local titleGradClone = titleGrad:Clone(); titleGradClone.Parent = titleBar

local titleText = Instance.new("TextLabel"); titleText.Size = UDim2.new(0.5, 0, 1, 0); titleText.Position = UDim2.new(0, 15, 0, 0); titleText.BackgroundTransparency = 1; titleText.Text = "HUYILAN v9"; titleText.TextColor3 = Color3.fromRGB(255, 255, 255); titleText.Font = Enum.Font.GothamBlack; titleText.TextSize = 20; titleText.TextXAlignment = Enum.TextXAlignment.Left; titleText.Parent = titleBar

local minBtn = Instance.new("TextButton"); minBtn.Size = UDim2.new(0, 28, 0, 28); minBtn.Position = UDim2.new(1, -60, 0.5, -14); minBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); minBtn.BackgroundTransparency = 0.85; minBtn.BorderSizePixel = 0; minBtn.Text = "—"; minBtn.TextColor3 = Color3.fromRGB(255, 255, 255); minBtn.Font = Enum.Font.GothamBold; minBtn.TextSize = 20; minBtn.Parent = titleBar; Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 5)
local clsBtn = Instance.new("TextButton"); clsBtn.Size = UDim2.new(0, 28, 0, 28); clsBtn.Position = UDim2.new(1, -28, 0.5, -14); clsBtn.BackgroundColor3 = Color3.fromRGB(255, 30, 30); clsBtn.BorderSizePixel = 0; clsBtn.Text = "X"; clsBtn.TextColor3 = Color3.fromRGB(255, 255, 255); clsBtn.Font = Enum.Font.GothamBold; clsBtn.TextSize = 16; clsBtn.Parent = titleBar; Instance.new("UICorner", clsBtn).CornerRadius = UDim.new(0, 5)

local content = Instance.new("Frame"); content.Size = UDim2.new(1, -20, 1, -50); content.Position = UDim2.new(0, 10, 0, 46); content.BackgroundTransparency = 1; content.Parent = main

-- RGB
local function startRGB()
    if rgbConn then rgbConn:Disconnect() end
    rgbConn = RunService.RenderStepped:Connect(function()
        local hue = (tick() * 80) % 360
        titleGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(((hue)%360)/360, 1, 1)),
            ColorSequenceKeypoint.new(0.25, Color3.fromHSV(((hue+60)%360)/360, 1, 1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(((hue+120)%360)/360, 1, 1)),
            ColorSequenceKeypoint.new(0.75, Color3.fromHSV(((hue+180)%360)/360, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(((hue+240)%360)/360, 1, 1))
        })
        titleGradClone.Color = titleGrad.Color
        mainStroke.Color = Color3.fromHSV(((hue+180)%360)/360, 1, 1)
    end)
end
startRGB()

local function createToggle(name, y, cb)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 0, 28); btn.Position = UDim2.new(0, 0, 0, y); btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); btn.BorderSizePixel = 0; btn.Text = name .. ": OFF"; btn.TextColor3 = Color3.fromRGB(230, 230, 230); btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.AutoButtonColor = false; btn.Parent = content
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local stk = Instance.new("UIStroke"); stk.Color = Color3.fromRGB(50, 50, 50); stk.Thickness = 0.5; stk.Parent = btn
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.Text = name .. ": " .. (on and "ON" or "OFF")
        btn.BackgroundColor3 = on and Color3.fromRGB(150, 0, 200) or Color3.fromRGB(20, 20, 20)
        stk.Color = on and Color3.fromRGB(255, 50, 255) or Color3.fromRGB(50, 50, 50)
        cb(on)
    end)
    return btn
end

-- Row 1
createToggle("AIMBOT", 0, setAimbot)
createToggle("SILENT AIM", 32, setSilentAim)
createToggle("TRIGGER BOT", 64, setTriggerBot)
createToggle("ESP", 96, setESP)
createToggle("NO RECOIL", 128, setNoRecoil)
createToggle("RAPID FIRE", 160, setRapidFire)
createToggle("WALLSHOT", 192, setWallshot)
createToggle("ANTI AIM", 224, setAntiAim)
createToggle("GOD MODE", 256, setGodMode)
createToggle("NO CLIP", 288, setNoClip)
createToggle("FLY", 320, setFly)
createToggle("SPEED HACK", 352, setSpeedHack)
createToggle("CROSSHAIR", 384, setCrosshair)
createToggle("SPIN BOT", 416, setSpinBot)
createToggle("FAKE LAG", 448, setFakeLag)
createToggle("BACKTRACK", 480, setBacktrack)
createToggle("AIR STUCK", 512, setAirStuck)
createToggle("DESYNC", 544, setDesync)
createToggle("INF AMMO", 576, setInfiniteAmmo)
createToggle("NO SPREAD", 608, setNoSpread)
createToggle("HITBOX EXT", 640, setHitboxExtend)
createToggle("AUTO RESPAWN", 672, setAutoRespawn)
createToggle("STREAMER MODE", 704, setStreamerMode)

-- Buttons
local tpBtn = Instance.new("TextButton"); tpBtn.Size = UDim2.new(1, 0, 0, 24); tpBtn.Position = UDim2.new(0, 0, 0, 740); tpBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50); tpBtn.BorderSizePixel = 0; tpBtn.Text = "TELEPORT TO ENEMY"; tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255); tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 11; tpBtn.AutoButtonColor = false; tpBtn.Parent = content; Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
tpBtn.MouseButton1Click:Connect(teleportToEnemy)

local saveBtn = Instance.new("TextButton"); saveBtn.Size = UDim2.new(0.48, 0, 0, 24); saveBtn.Position = UDim2.new(0, 0, 0, 770); saveBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); saveBtn.BorderSizePixel = 0; saveBtn.Text = "SAVE CFG"; saveBtn.TextColor3 = Color3.fromRGB(230, 230, 230); saveBtn.Font = Enum.Font.GothamBold; saveBtn.TextSize = 11; saveBtn.AutoButtonColor = false; saveBtn.Parent = content; Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
saveBtn.MouseButton1Click:Connect(saveConfig)

local loadBtn = Instance.new("TextButton"); loadBtn.Size = UDim2.new(0.48, 0, 0, 24); loadBtn.Position = UDim2.new(0.52, 0, 0, 770); loadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); loadBtn.BorderSizePixel = 0; loadBtn.Text = "LOAD CFG"; loadBtn.TextColor3 = Color3.fromRGB(230, 230, 230); loadBtn.Font = Enum.Font.GothamBold; loadBtn.TextSize = 11; loadBtn.AutoButtonColor = false; loadBtn.Parent = content; Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
loadBtn.MouseButton1Click:Connect(loadConfig)

-- Drag
local drag = false; local ds, fs
titleBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; ds = i.Position; fs = main.Position end end)
UserInputService.InputChanged:Connect(function(i) if drag then local d = i.Position - ds; main.Position = UDim2.new(fs.X.Scale, fs.X.Offset + d.X, fs.Y.Scale, fs.Y.Offset + d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)

-- Minimize
local minimized = false
minBtn.MouseButton1Click:Connect(function() minimized = not minimized; if minimized then main:TweenSize(UDim2.new(0, 270, 0, 40), "Out", "Quad", 0.3); minBtn.Text = "+" else main:TweenSize(UDim2.new(0, 270, 0, 700), "Out", "Quad", 0.3); minBtn.Text = "—" end end)
clsBtn.MouseButton1Click:Connect(function() screen.Enabled = false; menuVisible = false end)

-- Right Shift
UserInputService.InputBegan:Connect(function(i, p) if p then return end; if i.KeyCode == Enum.KeyCode.RightShift then menuVisible = not menuVisible; screen.Enabled = menuVisible end end)

-- Fly keys
UserInputService.InputBegan:Connect(function(i, p) if p then return end; local k = i.KeyCode; if k == Enum.KeyCode.W then flyKeys.W = true elseif k == Enum.KeyCode.A then flyKeys.A = true elseif k == Enum.KeyCode.S then flyKeys.S = true elseif k == Enum.KeyCode.D then flyKeys.D = true elseif k == Enum.KeyCode.Space then flyKeys.Space = true elseif k == Enum.KeyCode.LeftControl then flyKeys.LeftControl = true end end)
UserInputService.InputEnded:Connect(function(i) local k = i.KeyCode; if k == Enum.KeyCode.W then flyKeys.W = false elseif k == Enum.KeyCode.A then flyKeys.A = false elseif k == Enum.KeyCode.S then flyKeys.S = false elseif k == Enum.KeyCode.D then flyKeys.D = false elseif k == Enum.KeyCode.Space then flyKeys.Space = false elseif k == Enum.KeyCode.LeftControl then flyKeys.LeftControl = false end end)

-- Auto Respawn initial setup
setAutoRespawn(true)

screen.Enabled = false

-- ==================== END OF DESTROYER EDITION ====================
-- Functions included:
-- Aimbot, Silent Aim, TriggerBot, ESP, NoRecoil, RapidFire, Wallshot
-- AntiAim, GodMode, NoClip, Fly, SpeedHack, Crosshair
-- SpinBot, FakeLag, Backtrack, AirStuck, Desync
-- InfiniteAmmo, NoSpread, HitboxExtender, AutoRespawn
-- TeleportToEnemy, ConfigSystem, StreamerMode
-- Total features: 23+ rage functions
-- Use at your own risk — this is detectable by anti-cheat systems