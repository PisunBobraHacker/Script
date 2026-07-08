-- // Steal a Brainrot — Final Script v12 for Xeno
-- // Invisible скрывает ник + сфера Void Touch + всё остальное

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then playerGui = game:GetService("CoreGui") end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local invisible = false
local noclip = false
local antihit = false
local voidtouch = false
local speedhack = false
local baseLocked = false
local espEnabled = false
local speedMultiplier = 2
local voidTarget = nil
local voidRadius = 15

local noclipConn, antihitConn, voidtouchConn = nil, nil, nil
local espObjects = {}
local dropdownOpen = false
local dropdownButtons = {}
local voidSphere = nil

-- ==================== ФУНКЦИИ ====================

-- INVISIBLE (скрывает ник)
local function setInvisible(state)
    invisible = state
    if not Character then return end
    local t = state and 1 or 0
    
    -- Скрываем части тела
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = t
        elseif part:IsA("Decal") then
            part.Transparency = t
        end
    end
    
    -- Скрываем ник через Humanoid
    if Humanoid then
        Humanoid.DisplayDistanceType = state and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Viewer
    end
    
    -- Скрываем BillboardGui с ником
    if Character:FindFirstChild("Head") then
        local head = Character.Head
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("BillboardGui") then
                child.Enabled = not state
            end
        end
    end
    
    -- Скрываем стандартный тег игрока
    pcall(function()
        if state then
            LocalPlayer.DevEnableMouseLock = true
        else
            LocalPlayer.DevEnableMouseLock = false
        end
    end)
end

-- NOCLIP
local function setNoClip(state)
    noclip = state
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if not Character or not HumanoidRootPart then return end
            local moveDir = Humanoid.MoveDirection
            if moveDir.Magnitude < 0.1 then return end
            
            local rayOrigin = HumanoidRootPart.Position
            local rayDirection = moveDir * 3
            
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {Character}
            
            local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
            
            if rayResult then
                if math.abs(rayResult.Normal.Y) < 0.3 then
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                else
                    for _, part in ipairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = true end
                    end
                end
            else
                for _, part in ipairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if Character then
            for _, part in ipairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- ANTIHIT
local function setAntiHit(state)
    antihit = state
    if state then
        antihitConn = RunService.Heartbeat:Connect(function()
            if not Character or not Humanoid or not HumanoidRootPart then return end
            if Humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
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
            local tool = Character:FindFirstChildOfClass("Tool")
            if tool then tool.Parent = Character end
        end)
    else
        if antihitConn then antihitConn:Disconnect(); antihitConn = nil end
    end
end

-- VOID SPHERE
local function updateVoidSphere()
    if voidSphere then
        voidSphere.Size = Vector3.new(voidRadius * 2, voidRadius * 2, voidRadius * 2)
    end
end

local function createVoidSphere()
    if voidSphere then voidSphere:Destroy() end
    voidSphere = Instance.new("Part")
    voidSphere.Name = "VoidSphere"
    voidSphere.Shape = Enum.PartType.Ball
    voidSphere.Size = Vector3.new(voidRadius * 2, voidRadius * 2, voidRadius * 2)
    voidSphere.Anchored = true
    voidSphere.CanCollide = false
    voidSphere.Transparency = 0.7
    voidSphere.Color = Color3.fromRGB(255, 0, 0)
    voidSphere.Material = Enum.Material.ForceField
    voidSphere.Parent = Workspace
    
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Parent = voidSphere
end

local function removeVoidSphere()
    if voidSphere then
        voidSphere:Destroy()
        voidSphere = nil
    end
end

-- VOID TOUCH
local function setVoidTouch(state)
    voidtouch = state
    if state then
        createVoidSphere()
        local function findEnemies()
            local enemies = {}
            if voidTarget then
                local char = voidTarget.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChild("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        table.insert(enemies, {root = hrp, humanoid = hum})
                    end
                end
            else
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        local hum = player.Character:FindFirstChild("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            table.insert(enemies, {root = hrp, humanoid = hum})
                        end
                    end
                end
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Humanoid") and obj.Health > 0 and obj.Parent ~= Character then
                        local root = obj.Parent:FindFirstChild("HumanoidRootPart") or obj.Parent:FindFirstChild("Torso")
                        if root then
                            local isPlayer = false
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr.Character == obj.Parent then isPlayer = true; break end
                            end
                            if not isPlayer then
                                table.insert(enemies, {root = root, humanoid = obj})
                            end
                        end
                    end
                end
            end
            return enemies
        end
        
        voidtouchConn = RunService.Heartbeat:Connect(function()
            if not Character or not HumanoidRootPart then return end
            
            if voidSphere then
                voidSphere.Position = HumanoidRootPart.Position
            end
            
            local enemies = findEnemies()
            local myPos = HumanoidRootPart.Position
            
            for _, enemy in ipairs(enemies) do
                if enemy.root and enemy.root.Parent then
                    local dist = (enemy.root.Position - myPos).Magnitude
                    if dist <= voidRadius then
                        local direction = (enemy.root.Position - myPos).Unit
                        if direction.Magnitude < 0.1 then
                            direction = Vector3.new(math.random(-1, 1), 1, math.random(-1, 1)).Unit
                        end
                        local launchVelocity = direction * 5000 + Vector3.new(0, 2000, 0)
                        enemy.root.Velocity = launchVelocity
                        enemy.root.RotVelocity = Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
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
        removeVoidSphere()
    end
end

-- LOCK BASE
local function findBasePrompt()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local p = obj.Parent
            if p and (p.Name:lower():find("base") or p.Name:lower():find("capture") or p.Name:lower():find("claim")) then
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
                    HumanoidRootPart.CFrame = CFrame.new(prompt.Parent.Position + Vector3.new(0, 2, 0))
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
            Humanoid.WalkSpeed = 16 * speedMultiplier
        else
            Humanoid.WalkSpeed = 16
        end
    end
end

local function updateSpeed(mult)
    speedMultiplier = mult
    if speedhack and Humanoid then
        Humanoid.WalkSpeed = 16 * mult
    end
end

-- TELEPORT
local function findBase()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") and obj.Enabled then return obj end
    end
    return nil
end

local function teleportToBase()
    local base = findBase()
    if base and HumanoidRootPart then
        local targetPos = base.Position + Vector3.new(0, 3, 0)
        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local goal = {CFrame = CFrame.new(targetPos)}
        local tween = TweenService:Create(HumanoidRootPart, tweenInfo, goal)
        tween:Play()
    end
end

-- ESP
local function createESP(player)
    if not player.Character then return end
    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do obj:Destroy() end
    end
    
    local items = {}
    
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.Parent = player.Character
    table.insert(items, hl)
    
    local head = player.Character:WaitForChild("Head", 5)
    if head then
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 100, 0, 30)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Parent = head
        
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, 0, 1, 0)
        name.BackgroundTransparency = 1
        name.Text = player.Name
        name.TextColor3 = Color3.fromRGB(255, 0, 0)
        name.Font = Enum.Font.GothamBold
        name.TextSize = 14
        name.Parent = bb
        
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

-- ==================== GUI ====================
local screen = Instance.new("ScreenGui")
screen.Parent = playerGui
screen.ResetOnSpawn = false
screen.Name = "BrainrotHack"
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 530)
mainFrame.Position = UDim2.new(0, 20, 0.5, -265)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.Parent = screen

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 7)
Instance.new("UIStroke", mainFrame).Color = Color3.fromRGB(30, 30, 30)

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
titleText.Text = "Brainrot Hack v12"
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

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -38)
content.Position = UDim2.new(0, 8, 0, 34)
content.BackgroundTransparency = 1
content.Parent = mainFrame

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

createToggle("Invisible", 0, setInvisible)
createToggle("NoClip (Walls)", 34, setNoClip)
createToggle("AntiHit", 68, setAntiHit)
createToggle("ESP", 102, setESP)
createToggle("Speed Hack", 136, setSpeedHack)
createToggle("Lock Base", 170, setBaseLock)

-- Void Touch toggle
local voidTouchToggle = Instance.new("TextButton")
voidTouchToggle.Size = UDim2.new(1, 0, 0, 30)
voidTouchToggle.Position = UDim2.new(0, 0, 0, 204)
voidTouchToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
voidTouchToggle.BorderSizePixel = 0
voidTouchToggle.Text = "Void Touch: OFF"
voidTouchToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
voidTouchToggle.Font = Enum.Font.GothamSemibold
voidTouchToggle.TextSize = 12
voidTouchToggle.AutoButtonColor = false
voidTouchToggle.Parent = content
Instance.new("UICorner", voidTouchToggle).CornerRadius = UDim.new(0, 5)

local vtEnabled = false
voidTouchToggle.MouseButton1Click:Connect(function()
    vtEnabled = not vtEnabled
    voidTouchToggle.Text = "Void Touch: " .. (vtEnabled and "ON" or "OFF")
    voidTouchToggle.BackgroundColor3 = vtEnabled and Color3.fromRGB(0, 140, 70) or Color3.fromRGB(40, 40, 40)
    setVoidTouch(vtEnabled)
end)

-- Void Target
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, 0, 0, 16)
targetLabel.Position = UDim2.new(0, 0, 0, 238)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Void Target: ALL"
targetLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
targetLabel.Font = Enum.Font.GothamSemibold
targetLabel.TextSize = 10
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Parent = content

-- Dropdown
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size = UDim2.new(1, 0, 0, 26)
dropdownBtn.Position = UDim2.new(0, 0, 0, 256)
dropdownBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
dropdownBtn.BorderSizePixel = 0
dropdownBtn.Text = "Select Target [v]"
dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownBtn.Font = Enum.Font.GothamSemibold
dropdownBtn.TextSize = 11
dropdownBtn.AutoButtonColor = false
dropdownBtn.Parent = content
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 4)

local dropdownList = Instance.new("Frame")
dropdownList.Size = UDim2.new(1, 0, 0, 0)
dropdownList.Position = UDim2.new(0, 0, 0, 284)
dropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropdownList.BorderSizePixel = 0
dropdownList.Visible = false
dropdownList.ClipsDescendants = true
dropdownList.Parent = content
Instance.new("UICorner", dropdownList).CornerRadius = UDim.new(0, 4)

local dropdownScrolling = Instance.new("ScrollingFrame")
dropdownScrolling.Size = UDim2.new(1, -4, 1, -4)
dropdownScrolling.Position = UDim2.new(0, 2, 0, 2)
dropdownScrolling.BackgroundTransparency = 1
dropdownScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownScrolling.ScrollBarThickness = 3
dropdownScrolling.Parent = dropdownList

local function updateDropdown()
    for _, btn in ipairs(dropdownButtons) do btn:Destroy() end
    dropdownButtons = {}
    
    local y = 0
    
    local allBtn = Instance.new("TextButton")
    allBtn.Size = UDim2.new(1, 0, 0, 24)
    allBtn.Position = UDim2.new(0, 0, 0, y)
    allBtn.BackgroundColor3 = voidTarget == nil and Color3.fromRGB(0, 140, 70) or Color3.fromRGB(50, 50, 50)
    allBtn.BorderSizePixel = 0
    allBtn.Text = "ALL"
    allBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    allBtn.Font = Enum.Font.GothamSemibold
    allBtn.TextSize = 11
    allBtn.AutoButtonColor = false
    allBtn.Parent = dropdownScrolling
    
    allBtn.MouseButton1Click:Connect(function()
        voidTarget = nil
        targetLabel.Text = "Void Target: ALL"
        dropdownList.Visible = false
        dropdownOpen = false
        updateDropdown()
    end)
    table.insert(dropdownButtons, allBtn)
    y += 26
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.Position = UDim2.new(0, 0, 0, y)
            btn.BackgroundColor3 = voidTarget == player and Color3.fromRGB(0, 140, 70) or Color3.fromRGB(50, 50, 50)
            btn.BorderSizePixel = 0
            btn.Text = player.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 11
            btn.AutoButtonColor = false
            btn.Parent = dropdownScrolling
            
            btn.MouseButton1Click:Connect(function()
                voidTarget = player
                targetLabel.Text = "Void Target: " .. player.Name
                dropdownList.Visible = false
                dropdownOpen = false
                updateDropdown()
            end)
            table.insert(dropdownButtons, btn)
            y += 26
        end
    end
    
    dropdownScrolling.CanvasSize = UDim2.new(0, 0, 0, y)
end

dropdownBtn.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    dropdownList.Visible = dropdownOpen
    if dropdownOpen then
        updateDropdown()
        dropdownList.Size = UDim2.new(1, 0, 0, math.min(#dropdownButtons * 26, 150))
    end
end)

-- Void Radius
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(1, 0, 0, 16)
radiusLabel.Position = UDim2.new(0, 0, 0, 288)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Void Radius: " .. voidRadius
radiusLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
radiusLabel.Font = Enum.Font.GothamSemibold
radiusLabel.TextSize = 11
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Parent = content

local radiusMinus = Instance.new("TextButton")
radiusMinus.Size = UDim2.new(0, 28, 0, 20)
radiusMinus.Position = UDim2.new(0, 0, 0, 306)
radiusMinus.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
radiusMinus.BorderSizePixel = 0
radiusMinus.Text = "-"
radiusMinus.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusMinus.Font = Enum.Font.GothamBold
radiusMinus.TextSize = 14
radiusMinus.AutoButtonColor = false
radiusMinus.Parent = content
Instance.new("UICorner", radiusMinus).CornerRadius = UDim.new(0, 4)

local radiusPlus = Instance.new("TextButton")
radiusPlus.Size = UDim2.new(0, 28, 0, 20)
radiusPlus.Position = UDim2.new(1, -28, 0, 306)
radiusPlus.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
radiusPlus.BorderSizePixel = 0
radiusPlus.Text = "+"
radiusPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
radiusPlus.Font = Enum.Font.GothamBold
radiusPlus.TextSize = 14
radiusPlus.AutoButtonColor = false
radiusPlus.Parent = content
Instance.new("UICorner", radiusPlus).CornerRadius = UDim.new(0, 4)

radiusMinus.MouseButton1Click:Connect(function()
    voidRadius = math.max(voidRadius - 5, 5)
    radiusLabel.Text = "Void Radius: " .. voidRadius
    updateVoidSphere()
end)

radiusPlus.MouseButton1Click:Connect(function()
    voidRadius = math.min(voidRadius + 5, 100)
    radiusLabel.Text = "Void Radius: " .. voidRadius
    updateVoidSphere()
end)

-- Speed
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 16)
speedLabel.Position = UDim2.new(0, 0, 0, 332)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: x" .. speedMultiplier
speedLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.TextSize = 11
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = content

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 28, 0, 20)
minusBtn.Position = UDim2.new(0, 0, 0, 350)
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
plusBtn.Position = UDim2.new(1, -28, 0, 350)
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
    speedMultiplier = math.max(speedMultiplier - 0.5, 1)
    speedLabel.Text = "Speed: x" .. speedMultiplier
    updateSpeed(speedMultiplier)
end)

plusBtn.MouseButton1Click:Connect(function()
    speedMultiplier = math.min(speedMultiplier + 0.5, 10)
    speedLabel.Text = "Speed: x" .. speedMultiplier
    updateSpeed(speedMultiplier)
end)

-- Teleport
local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(1, 0, 0, 28)
teleportBtn.Position = UDim2.new(0, 0, 0, 378)
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

-- Restore
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

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
    
    wait(0.5)
    
    if invisible then setInvisible(true) end
    if noclip then setNoClip(false); setNoClip(true) end
    if antihit then setAntiHit(false); setAntiHit(true) end
    if vtEnabled then setVoidTouch(false); setVoidTouch(true) end
    if speedhack then setSpeedHack(false); setSpeedHack(true) end
    if baseLocked then setBaseLock(false); setBaseLock(true) end
end)