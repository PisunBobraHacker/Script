if game.PlaceId ~= 13253735473 then game.Players.LocalPlayer:Kick("Game not support!") return end

local type_custom = typeof
if not LPH_OBFUSCATED then
    LPH_JIT = function(...) return ...; end;
    LPH_JIT_MAX = function(...) return ...; end;
    LPH_NO_VIRTUALIZE = function(...) return ...; end;
    LPH_NO_UPVALUES = function(f) return (function(...) return f(...); end); end;
    LPH_ENCSTR = function(...) return ...; end;
    LPH_ENCNUM = function(...) return ...; end;
    LPH_ENCFUNC = function(func, key1, key2) if key1 ~= key2 then return print("LPH_ENCFUNC mismatch") end return func end
    LPH_CRASH = function() return print(debug.traceback()); end;
    
    SWG_DiscordUser = "private"
    SWG_DiscordID = 0
    SWG_Private = true
    SWG_Dev = false
    SWG_Version = "1.0"
    SWG_Title = '101 crack | Trident Survival'
    SWG_ShortName = ''
    SWG_FullName = ''
    SWG_FFA = false
end;

local workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Lighting = cloneref(game:GetService("Lighting"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local GuiInset = cloneref(game:GetService("GuiService")):GetGuiInset()
local CoreGui = cloneref(game:GetService("CoreGui"))
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local _CFramenew = CFrame.new
local _Vector2new = Vector2.new
local _Vector3new = Vector3.new
local _IsDescendantOf = game.IsDescendantOf
local _FindFirstChild = game.FindFirstChild
local _FindFirstChildOfClass = game.FindFirstChildOfClass
local _Raycast = workspace.Raycast
local _IsKeyDown = UserInputService.IsKeyDown
local _WorldToViewportPoint = Camera.WorldToViewportPoint
local _Vector3zeromin = Vector3.zero.Min
local _Vector2zeromin = Vector2.zero.Min
local _Vector3zeromax = Vector3.zero.Max
local _Vector2zeromax = Vector2.zero.Max
local _IsA = game.IsA
local tablecreate = table.create
local mathfloor = math.floor
local mathround = math.round
local mathclamp = math.clamp
local tostring = tostring
local unpack = unpack
local getupvalues = debug.getupvalues
local getupvalue = debug.getupvalue
local setupvalue = debug.setupvalue
local getconstants = debug.getconstants
local getconstant = debug.getconstant
local setconstant = debug.setconstant
local getstack = debug.getstack
local setstack = debug.setstack
local getinfo = debug.getinfo
local rawget = rawget

local cheat = {
    Library = nil,
    Toggles = nil,
    Options = nil,
    ThemeManager = nil,
    SaveManager = nil,
    connections = {
        heartbeats = {},
        renderstepped = {}
    },
    hooks = {},
    metahooks = {},
    drawings = {},
    game_hooks = {}
}

local dbg = debug
local gu = dbg.getupvalues
local su = dbg.setupvalue
local gc = dbg.getconstants
local sc = dbg.setconstant
local gs = dbg.getstack
local ss = dbg.setstack
local gi = dbg.getinfo

local mmr = mousemoverel
mousemoverel = function(x, y)
    return LPH_NO_VIRTUALIZE(function()
        if cheat.utility and cheat.utility.anti_trace then
            if cheat.utility.anti_trace() then return end
        end
        return mmr(x, y)
    end)()
end

cheat.utility = {} do
    cheat.utility.new_heartbeat = function(func)
        return LPH_NO_VIRTUALIZE(function()
            local obj = {}
            cheat.connections.heartbeats[func] = func
            function obj:Disconnect()
                if func then
                    cheat.connections.heartbeats[func] = nil
                    func = nil
                end
            end
            return obj
        end)()
    end
    
    cheat.utility.new_renderstepped = function(func)
        return LPH_NO_VIRTUALIZE(function()
            local obj = {}
            cheat.connections.renderstepped[func] = func
            function obj:Disconnect()
                if func then
                    cheat.connections.renderstepped[func] = nil
                    func = nil
                end
            end
            return obj
        end)()
    end
    
    cheat.utility.new_drawing = function(drawobj, args)
        return LPH_NO_VIRTUALIZE(function()
            local obj = Drawing.new(drawobj)
            for i, v in pairs(args) do
                obj[i] = v
            end
            cheat.drawings[obj] = obj
            return obj
        end)()
    end
    
    cheat.utility.new_hook = function(f, newf, usecclosure)
        return LPH_NO_VIRTUALIZE(function()
            if usecclosure then
                local old; old = hookfunction(f, newcclosure(function(...)
                    return newf(old, ...)
                end))
                cheat.hooks[f] = old
                return old
            else
                local old; old = hookfunction(f, function(...)
                    return newf(old, ...)
                end)
                cheat.hooks[f] = old
                return old
            end
        end)()
    end
    
    cheat.utility.hook_metamethod = function(instance, metamethod, newf)
        return LPH_NO_VIRTUALIZE(function()
            local old; old = hookmetamethod(instance, metamethod, newcclosure(newf))
            cheat.metahooks[metamethod] = {instance = instance, func = old}
            return old
        end)()
    end
    
    cheat.utility.protect_constants = function(func)
        return LPH_NO_VIRTUALIZE(function()
            local success, constants = pcall(function()
                return gc(func)
            end)
            
            if success and constants then
                for i, v in ipairs(constants) do
                    if type(v) == "string" then
                        if v:find("hook") or v:find("debug") or v:find("cheat") or v:find("silver") then
                            pcall(function()
                                sc(func, i, string.reverse(v))
                            end)
                        end
                    end
                end
            end
        end)()
    end
    
-- =============================================
-- ДОБАВЛЯЕМ В РАЗДЕЛ COMBAT
-- =============================================

-- Секция BIG HEAD
local bighead_section = combat_tab:section({
    name = "BIG HEAD",
    side = "left",
    size = 250
})

-- Переменные для Big Head
local bigHeadEnabled = false
local bigHeadSize = 3.5
local bigHeadTransparency = 0.3
local bigHeadTargets = {}

-- Функция применения Big Head
local function applyBigHead(character)
    if not character or not character:IsA("Model") then return end
    
    local head = character:FindFirstChild("Head") 
        or character:FindFirstChild("HeadMesh") 
        or character:FindFirstChild("HumanoidRootPart")
    
    if not head then return end
    if bigHeadTargets[character] then return end
    bigHeadTargets[character] = true
    
    -- Сохраняем оригинальный размер
    if not head:GetAttribute("OriginalSize") then
        head:SetAttribute("OriginalSize", head.Size)
    end
    
    -- Применяем изменения
    if bigHeadEnabled then
        local newSize = head:GetAttribute("OriginalSize") * bigHeadSize
        head.Size = newSize
        head.Transparency = bigHeadTransparency
    end
end

-- Функция обновления всех голов
local function updateAllBigHeads()
    for character, _ in pairs(bigHeadTargets) do
        if character and character.Parent then
            local head = character:FindFirstChild("Head") 
                or character:FindFirstChild("HeadMesh") 
                or character:FindFirstChild("HumanoidRootPart")
            if head then
                local original = head:GetAttribute("OriginalSize") or Vector3.new(2, 1, 1)
                if bigHeadEnabled then
                    head.Size = original * bigHeadSize
                    head.Transparency = bigHeadTransparency
                else
                    head.Size = original
                    head.Transparency = 0
                end
            end
        else
            bigHeadTargets[character] = nil
        end
    end
end

-- Toggle Big Head
bighead_section:toggle({
    name = "enable big head",
    def = false,
    callback = function(value)
        bigHeadEnabled = value
        if value then
            -- Сканируем всех игроков
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    applyBigHead(player.Character)
                end
                -- Следим за появлением персонажа
                player.CharacterAdded:Connect(function(character)
                    task.wait(0.5)
                    applyBigHead(character)
                end)
            end
            -- Сканируем NPC/монстров
            for _, obj in pairs(Workspace:GetChildren()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                    applyBigHead(obj)
                end
            end
        else
            updateAllBigHeads()
        end
    end
})

-- Ползунок размера головы
bighead_section:slider({
    name = "head size",
    def = 3.5,
    max = 10,
    min = 1,
    rounding = true,
    ticking = true,
    measuring = "x",
    callback = function(value)
        bigHeadSize = value
        updateAllBigHeads()
    end
})

-- Ползунок прозрачности
bighead_section:slider({
    name = "head transparency",
    def = 0.3,
    max = 1,
    min = 0,
    rounding = true,
    ticking = true,
    measuring = "",
    callback = function(value)
        bigHeadTransparency = value
        updateAllBigHeads()
    end
})

-- =============================================
-- СЕКЦИЯ SILENT AIM
-- =============================================
local silent_section = combat_tab:section({
    name = "SILENT AIM",
    side = "right",
    size = 250
})

-- Переменные для Silent Aim
local silentAimEnabled = false
local silentAimHitPart = "Head"
local silentAimFov = 300
local silentAimPrediction = true
local silentAimWallCheck = false
local silentAimTarget = nil
local silentAimConnection = nil

-- Получаем валидных игроков
local function getValidPlayers()
    local result = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(result, player)
            end
        end
    end
    return result
end

-- Получаем часть тела для цели
local function getTargetPart(character)
    if silentAimHitPart == "Head" then
        return character:FindFirstChild("Head")
    elseif silentAimHitPart == "UpperTorso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    else
        return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("LowerTorso")
    end
end

-- Проверка на стену
local function checkWall(origin, targetPos)
    if not silentAimWallCheck then return true end
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local direction = (targetPos - origin).Unit * (targetPos - origin).Magnitude
    local result = Workspace:Raycast(origin, direction, params)
    
    return result == nil
end

-- Находим ближайшую цель
local function findClosestTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local origin = Camera.CFrame.Position
    local closest = nil
    local closestDist = silentAimFov
    
    for _, player in pairs(getValidPlayers()) do
        local part = getTargetPart(player.Character)
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen and screenPos.Z > 0 then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < closestDist then
                    if checkWall(origin, part.Position) then
                        closestDist = dist
                        closest = {
                            player = player,
                            part = part,
                            screenPos = screenPos,
                            worldPos = part.Position
                        }
                    end
                end
            end
        end
    end
    
    return closest
end

-- Основная функция Silent Aim
local function onSilentAimStep()
    if not silentAimEnabled then 
        silentAimTarget = nil
        return 
    end
    
    -- Работает только при зажатой ЛКМ
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        silentAimTarget = nil
        return
    end
    
    local target = findClosestTarget()
    silentAimTarget = target or nil
end

-- Настройка Silent Aim (хук)
local function setupSilentAim()
    local mt = getrawmetatable(game)
    if mt then
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "CFrame" and silentAimEnabled and silentAimTarget then
                local origin = self.Position
                local targetPos = silentAimTarget.worldPos
                
                -- Упреждение
                if silentAimPrediction then
                    local velocity = Vector3.new(0, 0, 0)
                    local character = silentAimTarget.player.Character
                    if character then
                        local root = character:FindFirstChild("HumanoidRootPart")
                        if root then
                            velocity = root.Velocity or Vector3.new(0, 0, 0)
                        end
                    end
                    local distance = (targetPos - origin).Magnitude
                    local bulletSpeed = 2000
                    local travelTime = distance / bulletSpeed
                    targetPos = targetPos + (velocity * travelTime * 0.5)
                end
                
                return CFrame.new(origin, targetPos)
            end
            return oldIndex(self, key)
        end)
    end
end

-- Функция включения/выключения Silent Aim
local function toggleSilentAim(state)
    silentAimEnabled = state
    if state then
        if not silentAimConnection then
            silentAimConnection = RunService.RenderStepped:Connect(onSilentAimStep)
        end
        setupSilentAim()
    else
        if silentAimConnection then
            silentAimConnection:Disconnect()
            silentAimConnection = nil
        end
        silentAimTarget = nil
    end
end

-- Toggle Silent Aim
silent_section:toggle({
    name = "enable silent aim",
    def = false,
    callback = function(value)
        toggleSilentAim(value)
    end
})

-- Выбор части тела
silent_section:dropdown({
    name = "hit part",
    def = "Head",
    options = {"Head", "UpperTorso", "HumanoidRootPart"},
    callback = function(value)
        silentAimHitPart = value
    end
})

-- FOV радиус
silent_section:slider({
    name = "fov radius",
    def = 300,
    max = 800,
    min = 50,
    rounding = true,
    ticking = true,
    measuring = "px",
    callback = function(value)
        silentAimFov = value
    end
})

-- Упреждение
silent_section:toggle({
    name = "prediction (упреждение)",
    def = true,
    callback = function(value)
        silentAimPrediction = value
    end
})

-- Проверка стен
silent_section:toggle({
    name = "wall check",
    def = false,
    callback = function(value)
        silentAimWallCheck = value
    end
})

print(" Big Head и Silent Aim добавлены в раздел Combat!")
    --[[ ИСПРАВЛЕНО: удалён неверный вызов gs() без аргументов ]]
    cheat.utility.anti_trace = function()
        return LPH_NO_VIRTUALIZE(function()
            return false
        end)()
    end
    
    cheat.utility.protect_upvalues = function(func)
        return LPH_NO_VIRTUALIZE(function()
            local success, upvalues = pcall(function()
                return gu(func)
            end)
            
            if success and upvalues then
                for i = 1, #upvalues do
                    local upv = gu(func, i)
                    if type(upv) == "function" then
                        local protected = function(...)
                            cheat.utility.anti_trace()
                            return upv(...)
                        end
                        su(func, i, protected)
                    end
                end
            end
        end)()
    end
    
    local connection; connection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(delta)
        for _, func in pairs(cheat.connections.heartbeats) do
            if type(func) == "function" then
                pcall(func, delta)
            end
        end
    end))
    
    local connection1; connection1 = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(delta)
        for _, func in pairs(cheat.connections.renderstepped) do
            if type(func) == "function" then
                pcall(func, delta)
            end
        end
    end))
    
    cheat.utility.unload = function()
        return LPH_NO_VIRTUALIZE(function()
            connection:Disconnect()
            connection1:Disconnect()
            for key, _ in pairs(cheat.connections.heartbeats) do
                cheat.connections.heartbeats[key] = nil
            end
            for key, _ in pairs(cheat.connections.renderstepped) do
                cheat.connections.renderstepped[key] = nil
            end
            for _, drawing in pairs(cheat.drawings) do
                drawing:Remove()
                cheat.drawings[_] = nil
            end
            for hooked, original in pairs(cheat.hooks) do
                if type(original) == "function" then
                    hookfunction(hooked, clonefunction(original))
                else
                    hookmetamethod(original["instance"], original["metamethod"], clonefunction(original["func"]))
                end
            end
            for metamethod, data in pairs(cheat.metahooks) do
                if data and data.func then
                    hookmetamethod(data.instance, metamethod, clonefunction(data.func))
                end
            end
            for game_func, original in pairs(cheat.game_hooks) do
                if original then
                    if type(original) == "table" and original.instance then
                        hookmetamethod(original.instance, original.metamethod, clonefunction(original.func))
                    end
                end
            end
        end)()
    end
end

local trident = {
    loaded = false,
    lastpos = nil,
    middlepart = nil,
    tcp = nil,
    original_model = nil
}

local function setup_trident()
    return LPH_NO_VIRTUALIZE(function()
        cheat.utility.anti_trace()
        local success = pcall(function()
            if workspace:FindFirstChild("Const") and 
               workspace.Const:FindFirstChild("Ignore") and
               workspace.Const.Ignore:FindFirstChild("LocalCharacter") then
                trident.middlepart = workspace.Const.Ignore.LocalCharacter:FindFirstChild("Middle")
            end
            
            local replicatedStorage = game:GetService("ReplicatedStorage")
            if replicatedStorage:FindFirstChild("Shared") and
               replicatedStorage.Shared:FindFirstChild("entities") and
               replicatedStorage.Shared.entities:FindFirstChild("Player") and
               replicatedStorage.Shared.entities.Player:FindFirstChild("Model") then
                trident.original_model = replicatedStorage.Shared.entities.Player.Model
            end
            
            if LocalPlayer then
                trident.tcp = LocalPlayer:FindFirstChild("TCP")
            end
        end)
        return success and trident.middlepart and trident.original_model and trident.tcp
    end)()
end

repeat task.wait(0.5) until setup_trident()

spawn(LPH_NO_VIRTUALIZE(function()
    cheat.utility.anti_trace()
    
    local old_random_hook = cheat.utility.hook_metamethod(Random.new(), "__namecall", LPH_NO_VIRTUALIZE(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "NextNumber" then
            if args[1] == -100 and args[2] == 100 then
                return cheat.metahooks.__namecall.func(self, -1, 1)
            end
        end
        
        return cheat.metahooks.__namecall.func(self, ...)
    end))
    
    cheat.game_hooks["Random"] = {instance = Random.new(), metamethod = "__namecall", func = old_random_hook}

    pcall(function()
        cheat.utility.protect_constants(loadstring)
        cheat.utility.protect_constants(hookfunction)
        cheat.utility.protect_constants(hookmetamethod)
        cheat.utility.protect_constants(gc)
        cheat.utility.protect_constants(sc)
        cheat.utility.protect_constants(gu)
        cheat.utility.protect_constants(su)
    end)

    pcall(function()
        cheat.utility.protect_upvalues(LocalPlayer.GetMouse)
        cheat.utility.protect_upvalues(RunService.Heartbeat.Connect)
        cheat.utility.protect_upvalues(RunService.RenderStepped.Connect)
        cheat.utility.protect_upvalues(game.HttpGet)
        cheat.utility.protect_upvalues(game.FindFirstChild)
        cheat.utility.protect_upvalues(Drawing.new)
    end)
end))

spawn(LPH_NO_VIRTUALIZE(function()
    local library, window
    
    local success, err = pcall(function()
        library = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/Splix" .. 
            "?t=" .. tostring(tick()) .. "&v=" .. SWG_Version
        ))()
        
        if library then
            window = library:new({
                textsize = 13.5,
                font = Enum.Font.RobotoMono,
                name = string.format(SWG_Title, SWG_Version, SWG_FullName),
                color = Color3.fromRGB(255, 230, 225)
            })
        end
    end)
    
    if not success or not library then
        return
    end
    
    local combat_tab = window:page({name = "COMBAT"})
    local visuals_tab = window:page({name = "VISUALS"})
    local misc_tab = window:page({name = "MISC"})
    
    local aimbot_section = combat_tab:section({name = "AIMBOT", side = "left", size = 250})
    local hitbox_section = combat_tab:section({name = "HITBOX", side = "right", size = 250})
    local esp_section = visuals_tab:section({name = "PLAYER ESP", side = "left", size = 250})
    local crosshair_section = visuals_tab:section({name = "CROSSHAIR", side = "right", size = 250})
    local world_section = visuals_tab:section({name = "WORLD", side = "left", size = 250})
    local misc_section = misc_tab:section({name = "MISC SELECTION", side = "left", size = 250})
    
    local validcharacters = {}
    local hbc, original_size, hbsize = nil, trident.original_model and trident.original_model.Head and trident.original_model.Head.Size or Vector3.new(2, 1, 1), Vector3.new(4, 4, 4)
    local hitboxheadsizex, hitboxheadsizey, hitboxheadtransparency, cancollide = 4, 4, 1, false
    local hitboxSleeperCheck = false
    local hitboxBotCheck = false
    
    local espEnabled = false
    local infoEsp = false
    local chamsEsp = false
    local checkSleeper = false
    local checkBot = false
    local maxDistance = 1000
    local espColor = Color3.new(1, 1, 1)
    local chamsColor = Color3.new(1, 0, 0)
    
    local time = 12
    local timechanger = false
    
    local OreConfigs = {
        ["Nitrate Ore"] = {
            Name = "NITRATE",
            Color = Color3.fromRGB(255, 255, 255),
            Part1Color = Color3.fromRGB(248, 248, 248),
            Part2Color = Color3.fromRGB(72, 72, 72),
            TextureID = "rbxassetid://12939036056"
        },
        ["Iron Ore"] = {
            Name = "IRON",
            Color = Color3.fromRGB(255, 255, 0),
            Part1Color = Color3.fromRGB(199, 172, 120),
            Part2Color = Color3.fromRGB(72, 72, 72),
            TextureID = "rbxassetid://12939036056"
        },
        ["Cobblestone"] = {
            Name = "STONE",
            Color = Color3.fromRGB(128, 128, 128),
            Part1Color = Color3.fromRGB(72, 72, 72),
            TextureID = "rbxassetid://12939036056"
        }
    }
    
    local oreEspEnabled = {
        stone = false,
        iron = false,
        nitrate = false
    }
    
    local oreMaxDistance = 500
    local oreCache = setmetatable({}, {__mode = "v"})
    local oreLabels = {}
    
    local freecamEnabled = false
    local freecamFlySpeed = 5
    local freecamSprintMultiplier = 2.5
    local freecamSensitivity = 0.4
    local freecamBind = Enum.KeyCode.X
    
    local freecamPos = Vector3.new(0, 10, 0)
    local freecamYaw = 0
    local freecamPitch = 0
    local freecamActive = false
    local freecamConnection = nil
    
    local aimbotEnabled = false
    local aimbotFovSize = 80
    local aimbotSmoothness = 5
    local aimbotWorkingDistance = 1000
    local aimbotSleeperCheck = false
    local aimbotBotCheck = false
    local aimbotWallCheck = false
    local aimbotLockedTarget = nil
    
    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.NumSides = 64
    fovCircle.Radius = aimbotFovSize
    fovCircle.Filled = false
    fovCircle.Visible = false
    fovCircle.Transparency = 0.5
    fovCircle.Color = Color3.new(1, 0, 0)
    fovCircle.ZIndex = 999
    cheat.drawings[fovCircle] = fovCircle
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local function getAimPart(model)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            if not model then return nil end
            local head = _FindFirstChild(model, "Head")
            if head then return head end
            local torso = _FindFirstChild(model, "UpperTorso") or _FindFirstChild(model, "LowerTorso") or _FindFirstChild(model, "HumanoidRootPart")
            return torso
        end)()
    end
    
    local function checkWall(part)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            if not part then return false end
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent, Camera}
            local origin = Camera.CFrame.Position
            local direction = (part.Position - origin)
            local ray = _Raycast(workspace, origin, direction, raycastParams)
            return ray == nil
        end)()
    end
    
    local function toggleFreecam()
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            freecamActive = not freecamActive
            
            if freecamActive then
                local lookVector = Camera.CFrame.LookVector
                freecamPos = Camera.CFrame.Position
                freecamYaw = math.atan2(-lookVector.X, -lookVector.Z)
                freecamPitch = math.asin(lookVector.Y)
                
                Camera.CameraType = Enum.CameraType.Scriptable
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            else
                Camera.CameraType = Enum.CameraType.Custom
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end)()
    end
    
    local function updateFreecam(dt)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            if not freecamActive then return end
            
            local mouseDelta = UserInputService:GetMouseDelta()
            freecamYaw = freecamYaw - (mouseDelta.X * freecamSensitivity * 0.05)
            freecamPitch = freecamPitch - (mouseDelta.Y * freecamSensitivity * 0.05)
            freecamPitch = mathclamp(freecamPitch, math.rad(-89), math.rad(89))
            
            local rotation = CFrame.Angles(0, freecamYaw, 0) * CFrame.Angles(freecamPitch, 0, 0)
            
            local moveDir = Vector3.new(0, 0, 0)
            
            if _IsKeyDown(UserInputService, Enum.KeyCode.W) then
                moveDir = moveDir + Vector3.new(0, 0, -1)
            end
            if _IsKeyDown(UserInputService, Enum.KeyCode.S) then
                moveDir = moveDir + Vector3.new(0, 0, 1)
            end
            if _IsKeyDown(UserInputService, Enum.KeyCode.A) then
                moveDir = moveDir + Vector3.new(-1, 0, 0)
            end
            if _IsKeyDown(UserInputService, Enum.KeyCode.D) then
                moveDir = moveDir + Vector3.new(1, 0, 0)
            end
            if _IsKeyDown(UserInputService, Enum.KeyCode.E) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if _IsKeyDown(UserInputService, Enum.KeyCode.Q) then
                moveDir = moveDir + Vector3.new(0, -1, 0)
            end
            
            local currentSpeed = freecamFlySpeed
            if _IsKeyDown(UserInputService, Enum.KeyCode.LeftShift) then
                currentSpeed = currentSpeed * freecamSprintMultiplier
            end
            
            local worldMoveDir = rotation:VectorToWorldSpace(moveDir)
            freecamPos = freecamPos + (worldMoveDir * currentSpeed * dt * 60)
            
            Camera.CFrame = CFrame.new(freecamPos) * rotation
        end)()
    end
    
    local function IdentifyOre(model)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if model.Name ~= "Model" then return nil end
            
            if oreCache[model] then
                return oreCache[model].name, oreCache[model].config
            end
            
            local children = model:GetChildren()
            local result = nil
            local resultConfig = nil
            local maxChecks = math.min(#children, 5)
            
            for configName, config in pairs(OreConfigs) do
                local p1Match = false
                local p2Match = (configName == "Cobblestone")
                
                for i = 1, maxChecks do
                    local child = children[i]
                    
                    if child and (child:IsA("MeshPart") or child:IsA("Part")) then
                        local idMatch = true
                        if child:IsA("MeshPart") then
                            idMatch = child.MeshId == config.TextureID
                        end
                        
                        if idMatch then
                            if not p1Match and child.Color == config.Part1Color then
                                p1Match = true
                            elseif config.Part2Color and not p2Match and child.Color == config.Part2Color then
                                p2Match = true
                            end
                        end
                    end
                    
                    if p1Match and p2Match then
                        result = configName
                        resultConfig = config
                        break
                    end
                end
                
                if p1Match and p2Match then
                    break
                end
            end
            
            if result then
                oreCache[model] = {name = result, config = resultConfig}
            end
            
            return result, resultConfig
        end)()
    end
    
    local function createOreLabel(oreModel, oreName, config)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if oreLabels[oreModel] then 
                oreLabels[oreModel]:Remove()
            end
            
            local textLabel = Drawing.new("Text")
            textLabel.Text = oreName
            textLabel.Color = config.Color
            textLabel.Size = 12
            textLabel.Center = true
            textLabel.Outline = false
            textLabel.Font = 3
            textLabel.Visible = false
            
            oreLabels[oreModel] = textLabel
            
            return textLabel
        end)()
    end
    
    local function getOreCenter(model)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            local parts = {}
            local totalPos = Vector3.new(0, 0, 0)
            local count = 0
            
            for _, child in pairs(model:GetChildren()) do
                if child:IsA("BasePart") then
                    table.insert(parts, child)
                    totalPos = totalPos + child.Position
                    count = count + 1
                end
            end
            
            if count > 0 then
                return totalPos / count
            end
            
            local root = _FindFirstChild(model, "Part") or model:FindFirstChildWhichIsA("BasePart")
            return root and root.Position or nil
        end)()
    end
    
    local function checkForOres()
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            for _, model in pairs(workspace:GetChildren()) do
                if model:IsA("Model") and not oreLabels[model] and not oreCache[model] then
                    local oreName, config = IdentifyOre(model)
                    if oreName then
                        createOreLabel(model, oreName, config)
                    end
                end
            end
        end)()
    end
    
    checkForOres()
    
    workspace.DescendantAdded:Connect(LPH_NO_VIRTUALIZE(function(descendant)
        cheat.utility.anti_trace()
        
        if descendant:IsA("Model") then
            task.wait(1.0)
            if descendant.Parent and not oreLabels[descendant] then
                local oreName, config = IdentifyOre(descendant)
                if oreName then
                    createOreLabel(descendant, oreName, config)
                end
            end
        end
    end))

    workspace.DescendantRemoving:Connect(LPH_NO_VIRTUALIZE(function(descendant)
        cheat.utility.anti_trace()
        
        if descendant:IsA("Model") and oreLabels[descendant] then
            oreLabels[descendant]:Remove()
            oreLabels[descendant] = nil
            oreCache[descendant] = nil
        end
    end))
    
    local crosshair = {
        enabled = false,
        color = Color3.new(1, 1, 1),
        thickness = 2,
        length = 8,
        gap = 4
    }
    
    local crosshair_frame = nil
    local crosshair_lines = {}
    
    local playerCache = {}
    local espObjects = {}
    local chamsObjects = {}
    
    local function isSleeper(model)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if not model then return false end
            local lt = _FindFirstChild(model, "LowerTorso")
            if lt then
                local rj = _FindFirstChild(lt, "RootRig")
                if rj and type_custom(rj.CurrentAngle) == "number" and rj.CurrentAngle ~= 0 then 
                    return true 
                end
            end
            return false
        end)()
    end
    
    local function isBot(model)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if not model then return true end
            local torso = _FindFirstChild(model, "Torso")
            if torso and _FindFirstChild(torso, "LeftBooster") then
                return false
            end
            return true
        end)()
    end
    
    local function addtovc(obj)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if not obj then return end
            if not _FindFirstChild(obj, "Head") and not _FindFirstChild(obj, "LowerTorso") then return end
            validcharacters[obj] = obj
        end)()
    end
    
    local function removefromvc(obj)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if not validcharacters[obj] then return end
            validcharacters[obj] = nil
        end)()
    end
    
    local function addToPlayerCache(obj)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if _IsA(obj, "Model") then
                local root = _FindFirstChild(obj, "HumanoidRootPart") or _FindFirstChild(obj, "LowerTorso")
                if root and obj.Name ~= LocalPlayer.Name then 
                    table.insert(playerCache, obj) 
                end
            end
        end)()
    end
    
    local function removeFromPlayerCache(obj)
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            for i = #playerCache, 1, -1 do 
                if playerCache[i] == obj then 
                    table.remove(playerCache, i) 
                end 
            end
        end)()
    end
    
    for i, v in pairs(workspace:GetChildren()) do 
        addtovc(v)
        addToPlayerCache(v)
    end
    
    workspace.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(obj)
        cheat.utility.anti_trace()
        addtovc(obj)
        addToPlayerCache(obj)
    end))
    
    workspace.ChildRemoved:Connect(LPH_NO_VIRTUALIZE(function(obj)
        cheat.utility.anti_trace()
        
        removefromvc(obj)
        removeFromPlayerCache(obj)
        
        if espObjects[obj] then
            for _, drawing in pairs(espObjects[obj]) do
                drawing.Visible = false
                drawing:Remove()
            end
            espObjects[obj] = nil
        end
        
        if chamsObjects[obj] then
            chamsObjects[obj].Enabled = false
            chamsObjects[obj]:Destroy()
            chamsObjects[obj] = nil
        end
    end))
    
    local function create_crosshair_gui()
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if crosshair_frame then
                crosshair_frame:Destroy()
                crosshair_frame = nil
            end
            
            if not crosshair.enabled then
                return
            end
            
            local screen_gui = Instance.new("ScreenGui")
            screen_gui.Name = "SilverCrosshair"
            screen_gui.ResetOnSpawn = false
            screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            screen_gui.Parent = CoreGui
            
            local frame = Instance.new("Frame")
            frame.Name = "CrosshairFrame"
            frame.Size = UDim2.new(0, 2, 0, 2)
            frame.BackgroundTransparency = 1
            frame.Parent = screen_gui
            
            local mouse_x, mouse_y = Mouse.X, Mouse.Y + GuiInset.Y
            frame.Position = UDim2.new(0, mouse_x - 1, 0, mouse_y - 1 - GuiInset.Y)
            
            local half_length = mathfloor(crosshair.length / 2)
            local half_gap = mathfloor(crosshair.gap / 2)
            local thick = mathfloor(crosshair.thickness)
            
            if thick < 2 then thick = 2 end
            if half_length < 1 then half_length = 1 end
            if half_gap < 0 then half_gap = 0 end
            
            local function create_line(name, size, position)
                local line = Instance.new("Frame")
                line.Name = name
                line.Size = UDim2.new(0, size.X, 0, size.Y)
                line.Position = UDim2.new(0, position.X, 0, position.Y)
                line.BackgroundColor3 = crosshair.color
                line.BackgroundTransparency = 0
                line.BorderSizePixel = 0
                line.Parent = frame
                return line
            end
            
            local line_top = create_line("Top", Vector2.new(thick, half_length), Vector2.new(-mathfloor(thick/2), -half_length - half_gap))
            local line_bottom = create_line("Bottom", Vector2.new(thick, half_length), Vector2.new(-mathfloor(thick/2), half_gap))
            local line_left = create_line("Left", Vector2.new(half_length, thick), Vector2.new(-half_length - half_gap, -mathfloor(thick/2)))
            local line_right = create_line("Right", Vector2.new(half_length, thick), Vector2.new(half_gap, -mathfloor(thick/2)))
            
            crosshair_frame = frame
            crosshair_lines = {line_top, line_bottom, line_left, line_right}
        end)()
    end
    
    local function update_crosshair_gui()
        return LPH_NO_VIRTUALIZE(function()
            cheat.utility.anti_trace()
            
            if not crosshair.enabled then
                if crosshair_frame then
                    crosshair_frame:Destroy()
                    crosshair_frame = nil
                end
                return
            end
            
            if not crosshair_frame or not crosshair_frame.Parent then
                create_crosshair_gui()
                return
            end
            
            local mouse_x, mouse_y = Mouse.X, Mouse.Y + GuiInset.Y
            crosshair_frame.Position = UDim2.new(0, mouse_x - 1, 0, mouse_y - 1 - GuiInset.Y)
            
            if #crosshair_lines >= 4 then
                local half_length = mathfloor(crosshair.length / 2)
                local half_gap = mathfloor(crosshair.gap / 2)
                local thick = mathfloor(crosshair.thickness)
                
                if thick < 2 then thick = 2 end
                if half_length < 1 then half_length = 1 end
                if half_gap < 0 then half_gap = 0 end
                
                for _, line in ipairs(crosshair_lines) do
                    if line then
                        line.BackgroundColor3 = crosshair.color
                        line.BackgroundTransparency = 0
                    end
                end
                
                crosshair_lines[1].Size = UDim2.new(0, thick, 0, half_length)
                crosshair_lines[1].Position = UDim2.new(0, -mathfloor(thick/2), 0, -half_length - half_gap)
                
                crosshair_lines[2].Size = UDim2.new(0, thick, 0, half_length)
                crosshair_lines[2].Position = UDim2.new(0, -mathfloor(thick/2), 0, half_gap)
                
                crosshair_lines[3].Size = UDim2.new(0, half_length, 0, thick)
                crosshair_lines[3].Position = UDim2.new(0, -half_length - half_gap, 0, -mathfloor(thick/2))
                
                crosshair_lines[4].Size = UDim2.new(0, half_length, 0, thick)
                crosshair_lines[4].Position = UDim2.new(0, half_gap, 0, -mathfloor(thick/2))
            end
        end)()
    end
    
    local last_hitbox_update = 0
    local hitbox_update_interval = 0.033
    
    aimbot_section:toggle({
        name = "enabled",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            aimbotEnabled = value
            fovCircle.Visible = value
            if not value then
                aimbotLockedTarget = nil
            end
        end)
    })
    
    aimbot_section:slider({
        name = "fov size",
        def = 50,
        max = 100,
        min = 10,
        rounding = true,
        ticking = true,
        measuring = "",
        callback = LPH_NO_VIRTUALIZE(function(value)
            aimbotFovSize = value
            fovCircle.Radius = value
        end)
    })
    
    aimbot_section:slider({
        name = "smoothness",
        def = 5,
        max = 10,
        min = 1,
        rounding = true,
        ticking = true,
        measuring = "",
        callback = LPH_NO_VIRTUALIZE(function(value)
            aimbotSmoothness = value
        end)
    })
    
    aimbot_section:slider({
        name = "working distance",
        def = 1000,
        max = 1000,
        min = 100,
        rounding = true,
        ticking = true,
        measuring = "studs",
        callback = LPH_NO_VIRTUALIZE(function(value)
            aimbotWorkingDistance = value
        end)
    })
    
    aimbot_section:toggle({
        name = "sleeper check",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            aimbotSleeperCheck = value
        end)
    })
    
    aimbot_section:toggle({
        name = "bot check",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            aimbotBotCheck = value
        end)
    })
    
    aimbot_section:toggle({
        name = "wall check",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            aimbotWallCheck = value
        end)
    })
    
    hitbox_section:toggle({
        name = "hitbox expander",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            if hbc then 
                hbc:Disconnect() 
                hbc = nil 
            end
            
            if value then
                hbc = cheat.utility.new_heartbeat(LPH_NO_VIRTUALIZE(function(delta)
                    cheat.utility.anti_trace()
                    
                    local current_time = tick()
                    if current_time - last_hitbox_update < hitbox_update_interval then
                        return
                    end
                    last_hitbox_update = current_time
                    
                    local cameraPos = Camera.CFrame.Position
                    local maxHitboxDist = 1000
                    
                    for obj, _ in pairs(validcharacters) do
                        local primpart = obj and _FindFirstChild(obj, 'Head')
                        if primpart then
                            local dist = (cameraPos - primpart.Position).Magnitude
                            if dist <= maxHitboxDist then
                                local sleeper = isSleeper(obj)
                                local bot = isBot(obj)
                                
                                local shouldSkip = (hitboxSleeperCheck and sleeper) or (hitboxBotCheck and bot)
                                
                                if not shouldSkip then
                                    pcall(LPH_NO_VIRTUALIZE(function()
                                        primpart.Size = hbsize
                                        primpart.Transparency = hitboxheadtransparency
                                        primpart.CanCollide = cancollide
                                    end))
                                else
                                    pcall(LPH_NO_VIRTUALIZE(function()
                                        primpart.Size = original_size
                                        primpart.Transparency = 0
                                        primpart.CanCollide = true
                                    end))
                                end
                            end
                        end
                    end
                end))
            else
                for obj, _ in pairs(validcharacters) do
                    local primpart = obj and _FindFirstChild(obj, 'Head')
                    if primpart then
                        pcall(LPH_NO_VIRTUALIZE(function()
                            primpart.Size = original_size
                            primpart.Transparency = 0
                            primpart.CanCollide = true
                        end))
                    end
                end
            end
        end)
    })
    
    hitbox_section:toggle({
        name = "can collide",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(v)
            cancollide = v
        end)
    })
    
    hitbox_section:toggle({
        name = "sleeper check",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            hitboxSleeperCheck = value
        end)
    })
    
    hitbox_section:toggle({
        name = "bot check",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            hitboxBotCheck = value
        end)
    })
    
    hitbox_section:slider({
        name = "transparency",
        def = 1,
        max = 1,
        min = 0,
        rounding = true,
        ticking = false,
        measuring = "",
        callback = LPH_NO_VIRTUALIZE(function(value)
            hitboxheadtransparency = value
        end)
    })
    
    hitbox_section:slider({
        name = "size x",
        def = 3,
        max = 6,
        min = 2,
        rounding = true,
        ticking = false,
        measuring = "",
        callback = LPH_NO_VIRTUALIZE(function(value)
            hitboxheadsizex = value
            hbsize = Vector3.new(hitboxheadsizex, hitboxheadsizey, hitboxheadsizex)
        end)
    })
    
    hitbox_section:slider({
        name = "size y",
        def = 3,
        max = 6,
        min = 2,
        rounding = true,
        ticking = false,
        measuring = "",
        callback = LPH_NO_VIRTUALIZE(function(value)
            hitboxheadsizey = value
            hbsize = Vector3.new(hitboxheadsizex, hitboxheadsizey, hitboxheadsizex)
        end)
    })
    
    crosshair_section:toggle({
        name = "enable crosshair",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            crosshair.enabled = value
            if value then
                create_crosshair_gui()
            else
                if crosshair_frame then
                    crosshair_frame:Destroy()
                    crosshair_frame = nil
                end
            end
        end)
    })
    
    crosshair_section:colorpicker({
        name = "crosshair color",
        cpname = nil,
        def = Color3.fromRGB(255, 255, 255),
        callback = LPH_NO_VIRTUALIZE(function(value)
            crosshair.color = value
            if crosshair_frame and #crosshair_lines >= 4 then
                for _, line in ipairs(crosshair_lines) do
                    if line then
                        line.BackgroundColor3 = value
                    end
                end
            end
        end)
    })
    
    crosshair_section:slider({
        name = "crosshair thickness",
        def = 2,
        max = 6,
        min = 2,
        rounding = true,
        ticking = true,
        measuring = "px",
        callback = LPH_NO_VIRTUALIZE(function(value)
            crosshair.thickness = value
            update_crosshair_gui()
        end)
    })
    
    crosshair_section:slider({
        name = "crosshair length",
        def = 8,
        max = 20,
        min = 4,
        rounding = true,
        ticking = true,
        measuring = "px",
        callback = LPH_NO_VIRTUALIZE(function(value)
            crosshair.length = value
            update_crosshair_gui()
        end)
    })
    
    crosshair_section:slider({
        name = "crosshair gap",
        def = 4,
        max = 12,
        min = 1,
        rounding = true,
        ticking = true,
        measuring = "px",
        callback = LPH_NO_VIRTUALIZE(function(value)
            crosshair.gap = value
            update_crosshair_gui()
        end)
    })
    
    world_section:toggle({
        name = "enable time changer",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            timechanger = value
        end)
    })
    
    world_section:slider({
        name = "time changer",
        def = mathround(Lighting.ClockTime),
        max = 24,
        min = 0,
        rounding = true,
        ticking = true,
        measuring = "",
        callback = LPH_NO_VIRTUALIZE(function(value)
            time = value
        end)
    })
    
    world_section:toggle({
        name = "stone esp",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            oreEspEnabled.stone = value
        end)
    })
    
    world_section:toggle({
        name = "iron esp",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            oreEspEnabled.iron = value
        end)
    })
    
    world_section:toggle({
        name = "nitrate esp",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            oreEspEnabled.nitrate = value
        end)
    })
    
    world_section:slider({
        name = "ore max distance",
        def = 500,
        max = 1000,
        min = 100,
        rounding = true,
        ticking = true,
        measuring = "studs",
        callback = LPH_NO_VIRTUALIZE(function(value)
            oreMaxDistance = value
        end)
    })
    
    misc_section:toggle({
        name = "enable freecam",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            freecamEnabled = value
            if not value and freecamActive then
                toggleFreecam()
            end
            if value then
                if not freecamConnection then
                    freecamConnection = cheat.utility.new_renderstepped(LPH_NO_VIRTUALIZE(function(dt)
                        updateFreecam(dt)
                    end))
                end
            else
                if freecamConnection then
                    freecamConnection:Disconnect()
                    freecamConnection = nil
                end
            end
        end)
    })
    
    misc_section:keybind({
        name = "freecam bind",
        def = Enum.KeyCode.X,
        callback = LPH_NO_VIRTUALIZE(function(value)
            freecamBind = value
        end)
    })
    
    misc_section:slider({
        name = "freecam speed",
        def = 5,
        max = 20,
        min = 1,
        rounding = true,
        ticking = true,
        measuring = "",
        callback = LPH_NO_VIRTUALIZE(function(value)
            freecamFlySpeed = value
        end)
    })
    
    cheat.utility.new_heartbeat(LPH_NO_VIRTUALIZE(function()
        if timechanger then
            Lighting.ClockTime = time
        end
    end))
    
    UserInputService.InputBegan:Connect(LPH_NO_VIRTUALIZE(function(input, processed)
        cheat.utility.anti_trace()
        
        if processed then return end
        
        if freecamEnabled and input.KeyCode == freecamBind then
            toggleFreecam()
        end
        
        if input.KeyCode == Enum.KeyCode.End then
            cheat.utility.unload()
            if window and window.hide then
                window:hide()
            end
        end
    end))
    
    esp_section:toggle({
        name = "player esp",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            espEnabled = value
            if not value then
                for player, esp in pairs(espObjects) do
                    if esp.name then esp.name.Visible = false end
                    if esp.dist then esp.dist.Visible = false end
                end
                for player, chams in pairs(chamsObjects) do
                    chams.Enabled = false
                end
            end
        end)
    })
    
    esp_section:toggle({
        name = "info esp",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            infoEsp = value
        end)
    })
    
    esp_section:toggle({
        name = "chams esp",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            chamsEsp = value
            if not value then
                for player, chams in pairs(chamsObjects) do
                    chams.Enabled = false
                end
            end
        end)
    })
    
    esp_section:toggle({
        name = "check sleeper",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            checkSleeper = value
        end)
    })
    
    esp_section:toggle({
        name = "check bot",
        def = false,
        callback = LPH_NO_VIRTUALIZE(function(value)
            checkBot = value
        end)
    })
    
    esp_section:colorpicker({
        name = "esp color",
        cpname = nil,
        def = Color3.fromRGB(255,255,255),
        callback = LPH_NO_VIRTUALIZE(function(value)
            espColor = value
            for player, esp in pairs(espObjects) do
                if esp.name then esp.name.Color = value end
                if esp.dist then esp.dist.Color = value end
            end
        end)
    })
    
    esp_section:colorpicker({
        name = "chams color",
        cpname = nil,
        def = Color3.fromRGB(255,0,0),
        callback = LPH_NO_VIRTUALIZE(function(value)
            chamsColor = value
            for player, chams in pairs(chamsObjects) do
                chams.FillColor = value
            end
        end)
    })
    
    esp_section:slider({
        name = "max distance",
        def = 1000,
        max = 1000,
        min = 100,
        rounding = true,
        ticking = false,
        measuring = "studs",
        callback = LPH_NO_VIRTUALIZE(function(value)
            maxDistance = value
        end)
    })
    
    local esp_render_connection
    esp_render_connection = cheat.utility.new_renderstepped(LPH_NO_VIRTUALIZE(function()
        cheat.utility.anti_trace()
        
        update_crosshair_gui()
        
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        
        if aimbotEnabled then
            local target = nil
            local minDist = aimbotFovSize
            local hasValidTarget = false
            
            if aimbotLockedTarget then
                local part = getAimPart(aimbotLockedTarget)
                if aimbotLockedTarget.Parent and part then
                    local distance = (Camera.CFrame.Position - part.Position).Magnitude
                    if distance <= aimbotWorkingDistance then
                        local screenPos, onScreen = _WorldToViewportPoint(Camera, part.Position)
                        if onScreen then
                            local mag = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if mag < aimbotFovSize * 1.5 then
                                local wallCheckPass = not aimbotWallCheck or checkWall(part)
                                if wallCheckPass then
                                    target = screenPos
                                    hasValidTarget = true
                                end
                            else
                                aimbotLockedTarget = nil
                            end
                        else
                            aimbotLockedTarget = nil
                        end
                    else
                        aimbotLockedTarget = nil
                    end
                else
                    aimbotLockedTarget = nil
                end
            end
            
            if not aimbotLockedTarget then
                for _, player in ipairs(playerCache) do
                    local part = getAimPart(player)
                    if part then
                        local sleeper = isSleeper(player)
                        local bot = isBot(player)
                        local distance = (Camera.CFrame.Position - part.Position).Magnitude
                        
                        if distance <= aimbotWorkingDistance and 
                           not (aimbotSleeperCheck and sleeper) and 
                           not (aimbotBotCheck and bot) then
                            
                            local screenPos, onScreen = _WorldToViewportPoint(Camera, part.Position)
                            if onScreen then
                                local mag = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                if mag < aimbotFovSize then
                                    local wallCheckPass = not aimbotWallCheck or checkWall(part)
                                    if wallCheckPass then
                                        hasValidTarget = true
                                    end
                                    if mag < minDist then
                                        if not aimbotWallCheck or checkWall(part) then
                                            minDist = mag
                                            target = screenPos
                                            aimbotLockedTarget = player
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            if hasValidTarget then
                fovCircle.Color = Color3.new(0, 1, 0)
            else
                fovCircle.Color = Color3.new(1, 0, 0)
            end
            
            if target and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local dx = (target.X - mousePos.X) / aimbotSmoothness
                local dy = (target.Y - mousePos.Y) / aimbotSmoothness
                if cheat.utility.anti_trace() then return end
                mmr(dx, dy)
            end
        else
            aimbotLockedTarget = nil
        end
        
        local cameraPos = Camera.CFrame.Position
        
        for model, label in pairs(oreLabels) do
            if model and model.Parent then
                local oreName, config = IdentifyOre(model)
                if oreName then
                    local shouldShow = false
                    if oreName == "Cobblestone" and oreEspEnabled.stone then
                        shouldShow = true
                    elseif oreName == "Iron Ore" and oreEspEnabled.iron then
                        shouldShow = true
                    elseif oreName == "Nitrate Ore" and oreEspEnabled.nitrate then
                        shouldShow = true
                    end
                    
                    if shouldShow then
                        local centerPos = getOreCenter(model)
                        if centerPos then
                            local distance = (cameraPos - centerPos).Magnitude
                            if distance <= oreMaxDistance then
                                local screenPos, onScreen = _WorldToViewportPoint(Camera, centerPos)
                                if onScreen then
                                    label.Position = Vector2.new(screenPos.X, screenPos.Y)
                                    label.Visible = true
                                else
                                    label.Visible = false
                                end
                            else
                                label.Visible = false
                            end
                        else
                            label.Visible = false
                        end
                    else
                        label.Visible = false
                    end
                else
                    label.Visible = false
                end
            else
                if label then
                    label:Remove()
                end
                oreLabels[model] = nil
                oreCache[model] = nil
            end
        end
        
        if espEnabled then
            for _, player in ipairs(playerCache) do
                local root = _FindFirstChild(player, "LowerTorso") or _FindFirstChild(player, "HumanoidRootPart")
                if root then
                    local distance = (cameraPos - root.Position).Magnitude
                    
                    if distance <= maxDistance then
                        local sleeper = isSleeper(player)
                        local bot = isBot(player)
                        
                        if not (checkSleeper and sleeper) and not (checkBot and bot) then
                            
                            if chamsEsp then
                                if not chamsObjects[player] or chamsObjects[player].Parent ~= player then
                                    if chamsObjects[player] then 
                                        chamsObjects[player]:Destroy() 
                                    end
                                    local highlight = Instance.new("Highlight")
                                    highlight.FillTransparency = 0.5
                                    highlight.OutlineTransparency = 1
                                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    highlight.Parent = player
                                    chamsObjects[player] = highlight
                                end
                                chamsObjects[player].Enabled = true
                                chamsObjects[player].FillColor = chamsColor
                            elseif chamsObjects[player] then 
                                chamsObjects[player].Enabled = false 
                            end
                            
                            local screenPos, onScreen = _WorldToViewportPoint(Camera, root.Position)
                            
                            if onScreen then
                                if not espObjects[player] then
                                    espObjects[player] = {
                                        name = cheat.utility.new_drawing("Text", {}),
                                        dist = cheat.utility.new_drawing("Text", {})
                                    }
                                    
                                    espObjects[player].name.Size = 13
                                    espObjects[player].name.Center = true
                                    espObjects[player].name.Font = 2
                                    espObjects[player].name.Outline = false
                                    espObjects[player].name.ZIndex = 3
                                    
                                    espObjects[player].dist.Size = 13
                                    espObjects[player].dist.Center = true
                                    espObjects[player].dist.Font = 2
                                    espObjects[player].dist.Outline = false
                                    espObjects[player].dist.ZIndex = 3
                                end
                                
                                local esp = espObjects[player]
                                local boxSize = 5000 / screenPos.Z
                                
                                esp.name.Visible = infoEsp
                                esp.name.Text = sleeper and "SLEEPER" or (bot and "BOT" or "PLAYER")
                                esp.name.Color = espColor
                                esp.name.Position = _Vector2new(screenPos.X, screenPos.Y - boxSize/2 - 15)
                                
                                esp.dist.Visible = infoEsp
                                esp.dist.Text = string.format("[%dm]", mathfloor(distance))
                                esp.dist.Color = espColor
                                esp.dist.Position = _Vector2new(screenPos.X, screenPos.Y + boxSize/2 + 5)
                            else
                                if espObjects[player] then
                                    espObjects[player].name.Visible = false
                                    espObjects[player].dist.Visible = false
                                end
                                if chamsObjects[player] then 
                                    chamsObjects[player].Enabled = false 
                                end
                            end
                        else
                            if espObjects[player] then
                                espObjects[player].name.Visible = false
                                espObjects[player].dist.Visible = false
                            end
                            if chamsObjects[player] then 
                                chamsObjects[player].Enabled = false 
                            end
                        end
                    else
                        if espObjects[player] then
                            espObjects[player].name.Visible = false
                            espObjects[player].dist.Visible = false
                        end
                        if chamsObjects[player] then 
                            chamsObjects[player].Enabled = false 
                        end
                    end
                end
            end
        else
            for player, esp in pairs(espObjects) do
                if esp.name then esp.name.Visible = false end
                if esp.dist then esp.dist.Visible = false end
            end
            for player, chams in pairs(chamsObjects) do
                chams.Enabled = false
            end
        end
    end))

end))