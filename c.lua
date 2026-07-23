local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local CritRemote = nil
local Enabled = true

-- Ищем ремоут крита
local function FindRemote()
    local keywords = {"Crit", "Critical", "CriticalHit", "crit", "critHit"}
    local function search(parent)
        for _, child in parent:GetChildren() do
            for _, kw in keywords do
                if string.find(string.lower(child.Name), string.lower(kw)) and (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) then
                    return child
                end
            end
            if child:IsA("Folder") or child:IsA("Model") then
                local found = search(child)
                if found then return found end
            end
        end
        return nil
    end
    return search(ReplicatedStorage)
end

CritRemote = FindRemote()

-- Toggle на F2
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.F2 then
        Enabled = not Enabled
    end
end)

-- Авто-крит
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not Enabled then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if CritRemote then
            pcall(function()
                if CritRemote:IsA("RemoteEvent") then
                    CritRemote:FireServer()
                else
                    CritRemote:InvokeServer()
                end
            end)
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end
end)