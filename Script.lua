-- // Steal a Brainrot — Lite + Void Touch
-- // Fly, AntiHit, AutoSteal, Teleport, Lock Base, Void Touch (imba)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local playerGui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
if not playerGui then playerGui = game:GetService("CoreGui") end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local antihit = false
local autosteal = false
local flying = false
local baseLocked = false
local voidtouch = false
local flySpeed = 50

local flyBV, flyBG, flyConn = nil, nil, nil
local antihitConn, voidtouchConn = nil, nil
local flyKeys = {W = false, A = false, S = false, D = false, Space = false, LeftControl = false}

-- ==================== ФУНКЦИИ ====================

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
        end)
    else
        if antihitConn then antihitConn:Disconnect(); antihitConn = nil end
    end
end

-- VOID TOUCH (imba version)
local function setVoidTouch(state)
    voidtouch = state
    if state then
        voidtouchConn = RunService.Heartbeat:Connect(function()
            if not Character or not HumanoidRootPart then return end
            local myPos = HumanoidRootPart.Position
            
            for _, player in ipairs(Players:GetPlayers()) do