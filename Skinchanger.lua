local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

getgenv().config = {
    enabled = false,
    model = "",
    anim = "",
    fx = ""
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local swords = require(ReplicatedStorage:WaitForChild("Shared", 9e9)
    :WaitForChild("ReplicatedInstances", 9e9)
    :WaitForChild("Swords", 9e9))

local Library = loadstring(Game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()

local CustomWindow = Library:NewWindow("Moonlight")

local ChangeSkin = CustomWindow:NewSection("Skin Changer")

ChangeSkin:CreateToggle("Skin Changer", function(v)
getgenv().config.enabled = v
getgenv().updateSword()
end)

ChangeSkin:CreateTextbox("Enter Skin Here!!", function(v)
getgenv().config.model = v
getgenv().config.anim = v
getgenv().config.fx = v
getgenv().config.slash = getSlash(v)
getgenv().updateSword()      
end)

local function getSlash(name)
    local s = swords:GetSword(name)
    return (s and s.SlashName) or "SlashEffect"
end

getgenv().config.slash = getSlash(getgenv().config.fx)

local ctrl
for _, conn in ipairs(getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent)) do
    if conn.Function and islclosure(conn.Function) then
        local u = getupvalues(conn.Function)
        if #u == 1 and typeof(u[1]) == "table" then
            ctrl = u[1]
            break
        end
    end
end

local function setSword()
    if not getgenv().config.enabled then return end
    local char = LocalPlayer.Character
    if not char then return end

    setupvalue(rawget(swords, "EquipSwordTo"), 2, false)
    swords:EquipSwordTo(char, getgenv().config.model)
    if ctrl then ctrl:SetSword(getgenv().config.anim) end
end

getgenv().updateSword = function()
    getgenv().config.slash = getSlash(getgenv().config.fx)
    setSword()
end

local playFx
for _, conn in ipairs(getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent)) do
    if conn.Function and debug.getinfo(conn.Function).name == "parrySuccessAll" then
        playFx = conn.Function
        conn:Disable()
        break
    end
end

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
    local a = {...}
    if tostring(a[4]) == LocalPlayer.Name and getgenv().config.enabled then
        a[1], a[3] = getgenv().config.slash, getgenv().config.fx
    end
    return playFx(unpack(a))
end)

Players.LocalPlayer.CharacterAdded:Connect(function()
    task.delay(1, function()
        if getgenv().config.enabled then
            getgenv().updateSword()
        end
    end)
end)

task.spawn(function()
    while task.wait(1.5) do
        if getgenv().config.enabled then
            local char = LocalPlayer.Character
            if not char then continue end

            if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().config.model
            or not char:FindFirstChild(getgenv().config.model) then
                setSword()
            end

            for _, obj in char:GetChildren() do
                if obj:IsA("Model") and obj.Name ~= getgenv().config.model then
                    obj:Destroy()
                end
            end
        end
    end
end)

