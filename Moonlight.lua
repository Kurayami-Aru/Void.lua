local ContextActionService = game:GetService('ContextActionService')
local Phantom = false

local function BlockMovement(actionName, inputState, inputObject)
    return Enum.ContextActionResult.Sink
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local Players = game:GetService('Players')
local Player = Players.LocalPlayer


local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Tornado_Time = tick()

local UserInputService = game:GetService('UserInputService')
local Last_Input = UserInputService:GetLastInputType()

local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')

local Vector2_Mouse_Location = nil
local Grab_Parry = nil

local Remotes = {}
local Parry_Key = nil
local Speed_Divisor_Multiplier = 1.1
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local firstParryFired = false
local ParryThreshold = 1.0
local firstParryType = 'F_Key'
local Previous_Positions = {}
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualInputService = game:GetService("VirtualInputManager")


local GuiService = game:GetService('GuiService')

local function performFirstPress(parryType)
    if parryType == 'F_Key' then
        VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
    elseif parryType == 'Left_Click' then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    elseif parryType == 'Navigation' then
        local button = Players.LocalPlayer.PlayerGui.Hotbar.Block
        updateNavigation(button)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.01)
        updateNavigation(nil)
    end
end

if not LPH_OBFUSCATED then
    function LPH_JIT(Function) return Function end
    function LPH_JIT_MAX(Function) return Function end
    function LPH_NO_VIRTUALIZE(Function) return Function end
end

local PropertyChangeOrder = {}

local HashOne
local HashTwo
local HashThree

LPH_NO_VIRTUALIZE(function()
    for Index, Value in next, getgc() do
        if rawequal(typeof(Value), "function") and islclosure(Value) and getrenv().debug.info(Value, "s"):find("SwordsController") then
            if rawequal(getrenv().debug.info(Value, "l"), 276) then
                HashOne = getconstant(Value, 62)
                HashTwo = getconstant(Value, 64)
                HashThree = getconstant(Value, 65)
            end
        end 
    end
end)()


LPH_NO_VIRTUALIZE(function()
    for Index, Object in next, game:GetDescendants() do
        if Object:IsA("RemoteEvent") and string.find(Object.Name, "\n") then
            Object.Changed:Once(function()
                table.insert(PropertyChangeOrder, Object)
            end)
        end
    end
end)()


repeat
    task.wait()
until #PropertyChangeOrder == 3


local ShouldPlayerJump = PropertyChangeOrder[1]
local MainRemote = PropertyChangeOrder[2]
local GetOpponentPosition = PropertyChangeOrder[3]

local Parry_Key

for Index, Value in pairs(getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do
    if Value and Value.Function and not iscclosure(Value.Function)  then
        for Index2,Value2 in pairs(getupvalues(Value.Function)) do
            if type(Value2) == "function" then
                Parry_Key = getupvalue(getupvalue(Value2, 2), 17);
            end;
        end;
    end;
end;

local function Parry(...)
    ShouldPlayerJump:FireServer(HashOne, Parry_Key, ...)
    MainRemote:FireServer(HashTwo, Parry_Key, ...)
    GetOpponentPosition:FireServer(HashThree, Parry_Key, ...)
end

local Parries = 0

function create_animation(object, info, value)
    local animation = game:GetService('TweenService'):Create(object, info, value)

    animation:Play()
    task.wait(info.Time)

    Debris:AddItem(animation, 0)

    animation:Destroy()
    animation = nil
end

local Animation = {}
Animation.storage = {}

Animation.current = nil
Animation.track = nil

for _, v in pairs(game:GetService("ReplicatedStorage").Misc.Emotes:GetChildren()) do
    if v:IsA("Animation") and v:GetAttribute("EmoteName") then
        local Emote_Name = v:GetAttribute("EmoteName")
        Animation.storage[Emote_Name] = v
    end
end

local Emotes_Data = {}

for Object in pairs(Animation.storage) do
    table.insert(Emotes_Data, Object)
end

table.sort(Emotes_Data)

local Auto_Parry = {}

function Auto_Parry.Parry_Animation()
    local Parry_Animation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default:FindFirstChild('GrabParry')
    local Current_Sword = Player.Character:GetAttribute('CurrentlyEquippedSword')

    if not Current_Sword then
        return
    end

    if not Parry_Animation then
        return
    end

    local Sword_Data = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)

    if not Sword_Data or not Sword_Data['AnimationType'] then
        return
    end

    for _, object in pairs(game:GetService('ReplicatedStorage').Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == Sword_Data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local sword_animation_type = 'GrabParry'

                if object:FindFirstChild('Grab') then
                    sword_animation_type = 'Grab'
                end

                Parry_Animation = object[sword_animation_type]
            end
        end
    end

    Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
    Grab_Parry:Play()
end

function Auto_Parry.Play_Animation(v)
    local Animations = Animation.storage[v]

    if not Animations then
        return false
    end

    local Animator = Player.Character.Humanoid.Animator

    if Animation.track then
        Animation.track:Stop()
    end

    Animation.track = Animator:LoadAnimation(Animations)
    Animation.track:Play()

    Animation.current = v
end

function Auto_Parry.Get_Balls()
    local Balls = {}

    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            table.insert(Balls, Instance)
        end
    end
    return Balls
end

function Auto_Parry.Get_Ball()
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            return Instance
        end
    end
end

function Auto_Parry.Lobby_Balls()
    for _, Instance in pairs(workspace.TrainingBalls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            return Instance
        end
    end
end


local Closest_Entity = nil

function Auto_Parry.Closest_Player()
    local Max_Distance = math.huge
    local Found_Entity = nil
    
    for _, Entity in pairs(workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player) then
            if Entity.PrimaryPart then  -- Check if PrimaryPart exists
                local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
                if Distance < Max_Distance then
                    Max_Distance = Distance
                    Found_Entity = Entity
                end
            end
        end
    end
    
    Closest_Entity = Found_Entity
    return Found_Entity
end

function Auto_Parry:Get_Entity_Properties()
    Auto_Parry.Closest_Player()

    if not Closest_Entity then
        return false
    end

    local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity
    local Entity_Direction = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
    local Entity_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude

    return {
        Velocity = Entity_Velocity,
        Direction = Entity_Direction,
        Distance = Entity_Distance
    }
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled


function Auto_Parry.Parry_Data(Parry_Type)
    Auto_Parry.Closest_Player()
    
    local Events = {}
    local Camera = workspace.CurrentCamera
    local Vector2_Mouse_Location
    
    if Last_Input == Enum.UserInputType.MouseButton1 or (Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard) then
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    
    if isMobile then
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    
    local Players_Screen_Positions = {}
    for _, v in pairs(workspace.Alive:GetChildren()) do
        if v ~= Player.Character then
            local worldPos = v.PrimaryPart.Position
            local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
            
            if isOnScreen then
                Players_Screen_Positions[v] = Vector2.new(screenPos.X, screenPos.Y)
            end
            
            Events[tostring(v)] = screenPos
        end
    end
    
    if Parry_Type == 'Camera' then
        return {0, Camera.CFrame, Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Backwards' then
        local Backwards_Direction = Camera.CFrame.LookVector * -10000
        Backwards_Direction = Vector3.new(Backwards_Direction.X, 0, Backwards_Direction.Z)
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Backwards_Direction), Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'Straight' then
        local Aimed_Player = nil
        local Closest_Distance = math.huge
        local Mouse_Vector = Vector2.new(Vector2_Mouse_Location[1], Vector2_Mouse_Location[2])
        
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character then
                local worldPos = v.PrimaryPart.Position
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
                
                if isOnScreen then
                    local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (Mouse_Vector - playerScreenPos).Magnitude
                    
                    if distance < Closest_Distance then
                        Closest_Distance = distance
                        Aimed_Player = v
                    end
                end
            end
        end
        
        if Aimed_Player then
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Aimed_Player.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        else
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Closest_Entity.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        end
    end
    
    if Parry_Type == 'Random' then
        return {0, CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'High' then
        local High_Direction = Camera.CFrame.UpVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + High_Direction), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Left' then
        local Left_Direction = Camera.CFrame.RightVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Left_Direction), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Right' then
        local Right_Direction = Camera.CFrame.RightVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Right_Direction), Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'RandomTarget' then
        local candidates = {}
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character and v.PrimaryPart then
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
                if isOnScreen then
                    table.insert(candidates, {
                        character = v,
                        screenXY  = { screenPos.X, screenPos.Y }
                    })
                end
            end
        end
        if #candidates > 0 then
            local pick = candidates[ math.random(1, #candidates) ]
            local lookCFrame = CFrame.new(Player.Character.PrimaryPart.Position, pick.character.PrimaryPart.Position)
            return {0, lookCFrame, Events, pick.screenXY}
        else
            return {0, Camera.CFrame, Events, { Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2 }}
        end
    end
    
    return Parry_Type
end

function Auto_Parry.Parry(Parry_Type)
    local Parry_Data = Auto_Parry.Parry_Data(Parry_Type)

    if not firstParryFired then
        performFirstPress(firstParryType)
        firstParryFired = true
    else
        Parry(Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4])
    end

    if Parries > 7 then
        return false
    end

    Parries += 1

    task.delay(0.5, function()
        if Parries > 0 then
            Parries -= 1
        end
    end)
end

local Lerp_Radians = 0
local Last_Warping = tick()

function Auto_Parry.Linear_Interpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end

local Previous_Velocity = {}
local Curving = tick()

local Runtime = workspace.Runtime


function Auto_Parry.Is_Curved(ball, speed)
    local Ball = Auto_Parry.Get_Ball()

    if not Ball then
        return false
    end

    local Zoomies = Ball:FindFirstChild('zoomies')

    if not Zoomies then
        return false
    end

    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)

    local Speed = Velocity.Magnitude
    local Speed_Threshold = math.min(Speed / 100, 40)

    local Direction_Difference = (Ball_Direction - Velocity).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)

    local Dot_Difference = Dot - Direction_Similarity
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude

    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit

    local playerPos = Player.Character.PrimaryPart.Position
    local ballPos = Ball.Position
    local Direction = (playerPos - ballPos).Unit
    local Dot = Direction:Dot(Ball_Direction)
    local Speed = Velocity.Magnitude

    local Speed_Threshold = math.min(Speed/100, 40)
    local Angle_Threshold = 40 * math.max(Dot, 0)
    local Distance = (playerPos - ballPos).Magnitude
    local Reach_Time = Distance / Speed - (Ping / 1000)
    
    local Ball_Distance_Threshold = 15 - math.min(Distance/1000, 15) + Speed_Threshold

    table.insert(Previous_Velocity, Velocity)
    if #Previous_Velocity > 4 then
        table.remove(Previous_Velocity, 1)
    end

    if Ball:FindFirstChild('AeroDynamicSlashVFX') then
        Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
        Tornado_Time = tick()
    end

    if Runtime:FindFirstChild('Tornado') then
        if (tick() - Tornado_Time) < ((Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159) then
            return true
        end
    end

local Enough_Speed = Speed > 160
if Enough_Speed and Reach_Time > (Ping / 10 + 0.03) then
    if Speed < 300 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    elseif Speed <= 600 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 17, 17)
    elseif Speed <= 1000 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 19, 19)
    else
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 20, 20)
    end
end

if Distance < Ball_Distance_Threshold then
    return false
end

local adjustedReachTime = Reach_Time + 0.03

if Speed < 300 then
    if (tick() - Curving) < (adjustedReachTime / 1.2) then return true end
elseif Speed < 450 then
    if (tick() - Curving) < (adjustedReachTime / 1.21) then return true end
elseif Speed < 600 then
    if (tick() - Curving) < (adjustedReachTime / 1.335) then return true end
else
    if (tick() - Curving) < (adjustedReachTime / 1.5) then return true end
end

local Dot_Threshold = (0 - Ping / 1000)
local Direction_Difference = (Ball_Direction - Velocity.Unit)
local Direction_Similarity = Direction:Dot(Direction_Difference.Unit)
local Dot_Difference = Dot - Direction_Similarity

if Dot_Difference < Dot_Threshold then
    return true
end

local Clamped_Dot = math.clamp(Dot, -1, 1)
local Radians = math.deg(math.asin(Clamped_Dot))
Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)

if Speed < 300 then
    if Lerp_Radians < 0.02 then
        Last_Warping = tick()
    end
    if (tick() - Last_Warping) < (adjustedReachTime / 1.19) then
        return true
    end
else
    if Lerp_Radians < 0.018 then
        Last_Warping = tick()
    end
    if (tick() - Last_Warping) < (adjustedReachTime / 1.5) then
        return true
    end
end

if #Previous_Velocity == 4 then
    for i = 1, 2 do
        local prevDir = (Ball_Direction - Previous_Velocity[i].Unit).Unit
        local prevDot = Direction:Dot(prevDir)
        if (Dot - prevDot) < Dot_Threshold then
            return true
        end
    end
end

local backwardsCurveDetected = false
local backwardsAngleThreshold = 100
local horizDirection = Vector3.new(playerPos.X - ballPos.X, 0, playerPos.Z - ballPos.Z)

if horizDirection.Magnitude > 0 then
    horizDirection = horizDirection.Unit
end

local awayFromPlayer = -horizDirection
local horizBallDir = Vector3.new(Ball_Direction.X, 0, Ball_Direction.Z)

if horizBallDir.Magnitude > 0 then
    horizBallDir = horizBallDir.Unit
    local backwardsAngle = math.deg(math.acos(math.clamp(awayFromPlayer:Dot(horizBallDir), -1, 1)))
    if backwardsAngle < backwardsAngleThreshold then
        backwardsCurveDetected = true
    end
end

return (Dot < Dot_Threshold) or backwardsCurveDetected
end

function Auto_Parry:Get_Ball_Properties()
    local Ball = Auto_Parry.Get_Ball()

    local Ball_Velocity = Vector3.zero
    local Ball_Origin = Ball

    local Ball_Direction = (Player.Character.PrimaryPart.Position - Ball_Origin.Position).Unit
    local Ball_Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit)

    return {
        Velocity = Ball_Velocity,
        Direction = Ball_Direction,
        Distance = Ball_Distance,
        Dot = Ball_Dot
    }
end

function Auto_Parry.Spam_Service(self)
    local Ball = Auto_Parry.Get_Ball()

    local Entity = Auto_Parry.Closest_Player()

    if not Ball then
        return false
    end

    if not Entity or not Entity.PrimaryPart then
        return false
    end

    local Spam_Accuracy = 0

    local Velocity = Ball.AssemblyLinearVelocity
    local Speed = Velocity.Magnitude

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Velocity.Unit)

    local Target_Position = Entity.PrimaryPart.Position
    local Target_Distance = Player:DistanceFromCharacter(Target_Position)

    local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6, 95)

    if self.Entity_Properties.Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    if self.Ball_Properties.Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    if Target_Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    local Maximum_Speed = 5 - math.min(Speed / 5, 5)
    local Maximum_Dot = math.clamp(Dot, -1, 0) * Maximum_Speed

    Spam_Accuracy = Maximum_Spam_Distance - Maximum_Dot

    return Spam_Accuracy
end

local Connections_Manager = {}
local Selected_Parry_Type = "Camera"

local Infinity = false

ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
    if b then
        Infinity = true
    else
        Infinity = false
    end
end)

local Parried = false
local Last_Parry = 0


local AutoParry = true

local Balls = workspace:WaitForChild('Balls')
local CurrentBall = nil
local InputTask = nil
local Cooldown = 0.02
local RunTime = workspace:FindFirstChild("Runtime")



local function GetBall()
    for _, Ball in ipairs(Balls:GetChildren()) do
        if Ball:FindFirstChild("ff") then
            return Ball
        end
    end
    return nil
end

local function SpamInput(Label)
    if InputTask then return end
    InputTask = task.spawn(function()
        while AutoParry do
            Auto_Parry.Parry(Selected_Parry_Type)
            task.wait(Cooldown)
        end
        InputTask = nil
    end)
end

Balls.ChildAdded:Connect(function(Value)
    Value.ChildAdded:Connect(function(Child)
        if getgenv().SlashOfFuryDetection and Child.Name == 'ComboCounter' then
            local Sof_Label = Child:FindFirstChildOfClass('TextLabel')

            if Sof_Label then
                repeat
                    local Slashes_Counter = tonumber(Sof_Label.Text)

                    if Slashes_Counter and Slashes_Counter < 30 then
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end

                    task.wait()

                until not Sof_Label.Parent or not Sof_Label
            end
        end
    end)
end)

local player10239123 = Players.LocalPlayer

RunTime.ChildAdded:Connect(function(Object)
    local Name = Object.Name
    if getgenv().PhantomV2Detection then
        if Name == "maxTransmission" or Name == "transmissionpart" then
            local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
            if Weld then
                local Character = player10239123.Character or player10239123.CharacterAdded:Wait()
                if Character and Weld.Part1 == Character.HumanoidRootPart then
                    CurrentBall = GetBall()
                    Weld:Destroy()
    
                    if CurrentBall then
                        local FocusConnection
                        FocusConnection = RunService.RenderStepped:Connect(function()
                            local Highlighted = CurrentBall:GetAttribute("highlighted")
    
                            if Highlighted == true then
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
    
                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                if HumanoidRootPart then
                                    local PlayerPosition = HumanoidRootPart.Position
                                    local BallPosition = CurrentBall.Position
                                    local PlayerToBall = (BallPosition - PlayerPosition).Unit
    
                                    game.Players.LocalPlayer.Character.Humanoid:Move(PlayerToBall, false)
                                end
    
                            elseif Highlighted == false then
                                FocusConnection:Disconnect()
    
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 10
                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
    
                                task.delay(3, function()
                                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                end)
    
                                CurrentBall = nil
                            end
                        end)
    
                        task.delay(3, function()
                            if FocusConnection and FocusConnection.Connected then
                                FocusConnection:Disconnect()
    
                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                CurrentBall = nil
                            end
                        end)
                    end
                end
            end
        end
    end
end)

local player11 = game.Players.LocalPlayer
local PlayerGui = player11:WaitForChild("PlayerGui")
local playerGui = player11:WaitForChild("PlayerGui")
local Hotbar = PlayerGui:WaitForChild("Hotbar")


local ParryCD = playerGui.Hotbar.Block.UIGradient
local AbilityCD = playerGui.Hotbar.Ability.UIGradient

local function isCooldownInEffect1(uigradient)
    return uigradient.Offset.Y < 0.4
end

local function isCooldownInEffect2(uigradient)
    return uigradient.Offset.Y == 0.5
end

local function cooldownProtection()
    if isCooldownInEffect1(ParryCD) then
        game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
        return true
    end
    return false
end

local function AutoAbility()
    if isCooldownInEffect2(AbilityCD) then
        if Player.Character.Abilities["Raging Deflection"].Enabled or Player.Character.Abilities["Rapture"].Enabled or Player.Character.Abilities["Calming Deflection"].Enabled or Player.Character.Abilities["Aerodynamic Slash"].Enabled or Player.Character.Abilities["Fracture"].Enabled or Player.Character.Abilities["Death Slash"].Enabled then
            Parried = true
            game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
            task.wait(2.432)
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
            return true
        end
    end
    return false
end

local function loadExternalLib(url)
    local success, lib = pcall(function() return loadstring(game:HttpGet(url))() end)
    if not success then
        warn("Failed to load library from " .. url)
        return nil
    end
    return lib
end

local externalLib = loadExternalLib("https://pastefy.app/PuiGUa3I/raw")
local mainLib = externalLib.__init("Moonlight") 

local enabled = false
local swordName = ""
local p = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local swords = require(rs:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9))
local ctrl, playFx, lastParry = nil, nil, 0
local function getSlash(name)
    local s = swords:GetSword(name)
    return (s and s.SlashName) or "SlashEffect"
end
local function setSword()
    if not enabled then return end
    setupvalue(rawget(swords, "EquipSwordTo"), 2, false)
    swords:EquipSwordTo(p.Character, swordName)
    ctrl:SetSword(swordName)
end
updateSword = function()
    setSword()
end
while task.wait() and not ctrl do
    for _, v in getconnections(rs.Remotes.FireSwordInfo.OnClientEvent) do
        if v.Function and islclosure(v.Function) then
            local u = getupvalues(v.Function)
            if #u == 1 and type(u[1]) == "table" then
                ctrl = u[1]
                break
            end
        end
    end
end
local parryConnA, parryConnB
while task.wait() and not parryConnA do
    for _, v in getconnections(rs.Remotes.ParrySuccessAll.OnClientEvent) do
        if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
            parryConnA, playFx = v, v.Function
            v:Disable()
            break
        end
    end
end
while task.wait() and not parryConnB do
    for _, v in getconnections(rs.Remotes.ParrySuccessClient.Event) do
        if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
            parryConnB = v
            v:Disable()
            break
        end
    end
end
rs.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
    setthreadidentity(2)
    local args = {...}
    if tostring(args[4]) ~= p.Name then
        lastParry = tick()
    elseif enabled then
        args[1] = getSlash(swordName)
        args[3] = swordName
    end
    return playFx(unpack(args))
end)
task.spawn(function()
    while task.wait(1) do
        if enabled and swordName ~= "" then
            local c = p.Character or p.CharacterAdded:Wait()
            if p:GetAttribute("CurrentlyEquippedSword") ~= swordName or not c:FindFirstChild(swordName) then
                setSword()
            end
            for _, m in pairs(c:GetChildren()) do
                if m:IsA("Model") and m.Name ~= swordName then
                    m:Destroy()
                end
                task.wait()
            end
        end
    end
end)
						
local mainTab   = mainLib.create_tab("Main")
local customTab   = mainLib.create_tab("Customize")

mainTab.create_title({ name = "Parry", section = "left" })

mainTab.create_description_toggle({
  name = "Auto Parry",
  description = "Automatically parries incoming balls",
  flag = "parry",
  enabled = true,
  section = "left",
  callback = function(state)
    if state then
        Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()
                    local One_Ball = Auto_Parry.Get_Ball()
                    local Balls = Auto_Parry.Get_Balls()

                    for _, Ball in pairs(Balls) do

                        if not Ball then
                            return
                        end

                        local Zoomies = Ball:FindFirstChild('zoomies')
                        if not Zoomies then
                            return
                        end

                        Ball:GetAttributeChangedSignal('target'):Once(function()
                            Parried = false
                        end)

                        if Parried then
                            return
                        end

                        local Ball_Target = Ball:GetAttribute('target')
                        local One_Target = One_Ball:GetAttribute('target')

                        local Velocity = Zoomies.VectorVelocity

                        local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude

                        local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10

                        local Ping_Threshold = math.clamp(Ping / 10, 5, 17)

                        local Speed = Velocity.Magnitude

                        local cappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                        local speed_divisor_base = 2.4 + cappedSpeedDiff * 0.002

                        local effectiveMultiplier = Speed_Divisor_Multiplier
                        if getgenv().RandomParryAccuracyEnabled then
                            if Speed < 200 then
                                effectiveMultiplier = 0.7 + (math.random(40, 100) - 1) * (0.35 / 99)
                            else
                                effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                            end
                        end

                        local speed_divisor = speed_divisor_base * effectiveMultiplier
                        local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5)

                        local Curved = Auto_Parry.Is_Curved()

                        if Ball:FindFirstChild('AeroDynamicSlashVFX') then
                            Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                            Tornado_Time = tick()
                        end

                        if Runtime:FindFirstChild('Tornado') then
                            if (tick() - Tornado_Time) < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then
                            return
                            end
                        end

                        if One_Target == tostring(Player) and Curved then
                            return
                        end

                        if Ball:FindFirstChild("ComboCounter") then
                            return
                        end

                        local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild('SingularityCape')
                        if Singularity_Cape then
                            return
                        end 

                        if getgenv().InfinityDetection and Infinity then
                            return
                        end

                        if getgenv().DeathSlashDetection and deathshit then
                            return
                        end

                        if getgenv().TimeHoleDetection and timehole then
                            return
                        end

                        if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                            if getgenv().AutoAbility and AutoAbility() then
                                return
                            end
                        end

                        if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                            if getgenv().CooldownProtection and cooldownProtection() then
                                return
                            end

                            local Parry_Time = os.clock()
                            local Time_View = Parry_Time - (Last_Parry)
                            if Time_View > 0.5 then
                                Auto_Parry.Parry_Animation()
                            end

                            if getgenv().AutoParryKeypress then
                                VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
                            else
                                Auto_Parry.Parry(Selected_Parry_Type)
                            end

                            Last_Parry = Parry_Time
                            Parried = true
                        end
                        local Last_Parrys = tick()
                        repeat
                            RunService.PreSimulation:Wait()
                        until (tick() - Last_Parrys) >= 1 or not Parried
                        Parried = false
                    end
                end)
            else
                if Connections_Manager['Auto Parry'] then
                    Connections_Manager['Auto Parry']:Disconnect()
                    Connections_Manager['Auto Parry'] = nil
                end
            end
        end
    })

mainTab.create_description_toggle({
  name = "Lobby Parry",
  description = "Automatically parries incoming balls",
  flag = "parry",
  enabled = true,
  section = "left",
  callback = function(state)
    if state then
        Connections_Manager['Lobby AP'] = RunService.Heartbeat:Connect(function()
                    local Ball = Auto_Parry.Lobby_Balls()
                    if not Ball then
                        return
                    end
    
                    local Zoomies = Ball:FindFirstChild('zoomies')
                    if not Zoomies then
                        return
                    end
    
                    Ball:GetAttributeChangedSignal('target'):Once(function()
                        Training_Parried = false
                    end)
    
                    if Training_Parried then
                        return
                    end
    
                    local Ball_Target = Ball:GetAttribute('target')
                    local Velocity = Zoomies.VectorVelocity
                    local Distance = Player:DistanceFromCharacter(Ball.Position)
                    local Speed = Velocity.Magnitude
    
                    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
                    local LobbyAPcappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                    local LobbyAPspeed_divisor_base = 2.4 + LobbyAPcappedSpeedDiff * 0.002
    
                    local LobbyAPeffectiveMultiplier = LobbyAP_Speed_Divisor_Multiplier
                    if getgenv().LobbyAPRandomParryAccuracyEnabled then
                        LobbyAPeffectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                    end
    
                    local LobbyAPspeed_divisor = LobbyAPspeed_divisor_base * LobbyAPeffectiveMultiplier
                    local LobbyAPParry_Accuracys = Ping + math.max(Speed / LobbyAPspeed_divisor, 9.5)
    
                    if Ball_Target == tostring(Player) and Distance <= LobbyAPParry_Accuracys then
                            if getgenv().LobbyAPKeypress then
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                            else
                                Auto_Parry.Parry(Selected_Parry_Type)
                            end
                        Training_Parried = true
                    end
                    local Last_Parrys = tick()
                    repeat 
                        RunService.PreSimulation:Wait() 
                    until (tick() - Last_Parrys) >= 1 or not Training_Parried
                    Training_Parried = false
                end)
            else
                if Connections_Manager['Lobby AP'] then
                    Connections_Manager['Lobby AP']:Disconnect()
                    Connections_Manager['Lobby AP'] = nil
                end
            end
        end
    })

local parryTypeMap = {
    ["Camera"] = "Camera",
    ["Random"] = "Random",
    ["Backwards"] = "Backwards",
    ["Straight"] = "Straight",
    ["High"] = "High",
    ["Left"] = "Left",
    ["Right"] = "Right",
    ["Random Target"] = "RandomTarget"
}

mainTab.create_dropdown({
  name = "Curve type",
  flag = "auto_curve",
  section = "left",
  option = "Camera",
  options = {"Camera", "Random", "Backwards", "Straight", "High", "Left", "Right", "Random Target"},
  callback = function(value)
       Selected_Parry_Type = parryTypeMap[value] or value
    end
})

mainTab.create_slider({
  name = "Parry Accuracy",
  flag = "parry_accuracy",
  section = "left",
  value = 100,
  minimum_value = 1,
  maximum_value = 100,
  increment = 1,
  callback = function(value)
       Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.35 / 99)
	end
})

mainTab.create_slider({
  name = "Lobby Parry Accuracy",
  flag = "lobby_parry_accuracy",
  section = "left",
  value = 100,
  minimum_value = 1,
  maximum_value = 100,
  increment = 1,
  callback = function(value)
       Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.37 / 99)
	end
})

mainTab.create_title({ name = "Spam", section = "right" })


mainTab.create_description_toggle({
  name = "Auto Spam",
  description = "Automatically spam incoming balls",
  flag = "spam",
  enabled = true,
  section = "right",
  callback = function(state)
    if state then
        Connections_Manager['Auto Spam'] = RunService.PreSimulation:Connect(function()
                local Ball = Auto_Parry.Get_Ball()

                if not Ball then
                    return
                end

                local Zoomies = Ball:FindFirstChild('zoomies')

                if not Zoomies then
                    return
                end

                Auto_Parry.Closest_Player()

                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()

                local Ping_Threshold = math.clamp(Ping / 10, 18.5, 70)

                local Ball_Target = Ball:GetAttribute('target')

                local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                local Entity_Properties = Auto_Parry:Get_Entity_Properties()

                local Spam_Accuracy = Auto_Parry.Spam_Service({
                    Ball_Properties = Ball_Properties,
                    Entity_Properties = Entity_Properties,
                    Ping = Ping_Threshold
                })

                local Target_Position = Closest_Entity.PrimaryPart.Position
                local Target_Distance = Player:DistanceFromCharacter(Target_Position)

                local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                local Ball_Direction = Zoomies.VectorVelocity.Unit

                local Dot = Direction:Dot(Ball_Direction)

                local Distance = Player:DistanceFromCharacter(Ball.Position)

                if not Ball_Target then
                    return
                end

                if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                    return
                end
                
                local Pulsed = Player.Character:GetAttribute('Pulsed')

                if Pulsed then
                    return
                end

                if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
                    return
                end

                local threshold = ParryThreshold

                if Distance <= Spam_Accuracy and Parries > threshold then
                    if getgenv().SpamParryKeypress then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                    else
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end
                end
            end)
        else
            if Connections_Manager['Auto Spam'] then
                Connections_Manager['Auto Spam']:Disconnect()
                Connections_Manager['Auto Spam'] = nil
            end
        end
    end
})

mainTab.create_description_toggle({
  name = "Manual Spam",
  description = "Manual spam incoming balls",
  flag = "spam",
  enabled = false,
  section = "right",
  callback = function(value)
      getgenv().spamui = value

        if value then
            local gui = Instance.new("ScreenGui")
            gui.Name = "ManualSpamUI"
            gui.ResetOnSpawn = false
            gui.Parent = game.CoreGui

            local frame = Instance.new("Frame")
            frame.Name = "MainFrame"
            frame.Position = UDim2.new(0, 20, 0, 20)
            frame.Size = UDim2.new(0, 150, 0, 70)
            frame.BackgroundColor3 = Color3.fromRGB(10, 10, 50)
            frame.BackgroundTransparency = 0.3
            frame.BorderSizePixel = 0
            frame.Active = true
            frame.Draggable = true
            frame.Parent = gui

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(0, 12)
            uiCorner.Parent = frame

            local uiStroke = Instance.new("UIStroke")
            uiStroke.Thickness = 2
            uiStroke.Color = Color3.fromRGB(0, 0, 0)
            uiStroke.Parent = frame

            local button = Instance.new("TextButton")
            button.Name = "ManualSpamButton"
            button.Text = "Manual Spam"
            button.Size = UDim2.new(0, 160, 0, 40)
            button.Position = UDim2.new(0.5, -80, 0.5, -20)
            button.BackgroundTransparency = 1
            button.BorderSizePixel = 0
            button.Font = Enum.Font.GothamSemibold
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.TextSize = 22
            button.Parent = frame

            local activated = false

            local function toggle()
                activated = not activated
                button.Text = activated and "Stop" or "Manual Spam"
                if activated then
                    Connections_Manager['Manual Spam UI'] = game:GetService("RunService").RenderStepped:Connect(function()
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end)
                else
                    if Connections_Manager['Manual Spam UI'] then
                        Connections_Manager['Manual Spam UI']:Disconnect()
                        Connections_Manager['Manual Spam UI'] = nil
                    end
                end
            end

            button.MouseButton1Click:Connect(toggle)
        else
            if game.CoreGui:FindFirstChild("ManualSpamUI") then
                game.CoreGui:FindFirstChild("ManualSpamUI"):Destroy()
            end

            if Connections_Manager['Manual Spam UI'] then
                Connections_Manager['Manual Spam UI']:Disconnect()
                Connections_Manager['Manual Spam UI'] = nil
            end
        end
    end
})

mainTab.create_title({ name = "Detection", section = "right" })

mainTab.create_description_toggle({
  name = "Infinity Detection",
  description = "Stop parry when turn on Infinity",
  flag = "detect",
  enabled = false,
  section = "right",
  callback = function(value)
      if value then
             getgenv().InfinityDetection = value
            end
        end
    })

mainTab.create_description_toggle({
  name = "Anti Phantom",
  description = "Anti Phantom",
  flag = "detect",
  enabled = false,
  section = "right",
  callback = function(value)
      if value then
	  getgenv().PhantomV2Detection = value
            end
        end
    })
    
mainTab.create_description_toggle({
  name = "Slashes Of Fury Detection",
  description = "Auto parry when turn on SOF",
  flag = "detect",
  enabled = false,
  section = "right",
  callback = function(value)
      if value then 
	  getgenv().SlashOfFuryDetection = value
            end
        end
    })

mainTab.create_description_toggle({
  name = "Cooldown Protection",
  description = "Auto use ability when you miss parry",
  flag = "detect",
  enabled = false,
  section = "right",
  callback = function(value)
      if value then
	  getgenv().CooldownProtection = value
            end
        end
    })	

mainTab.create_description_toggle({
  name = "Auto ability",
  description = "Auto use ability",
  flag = "detect",
  enabled = false,
  section = "right",
  callback = function(value)
      if value then
	  getgenv().AutoAbility = value
            end
        end
    })

customTab.create_title({ name = "Customize", section = "left" })

customTab.create_description_toggle({
  name = "Skin Changer",
  description = "Change skin sword",
  flag = "custom",
  enabled = false,
  section = "left",
  callback = function(state)
      enabled = state
    end
})

customTab:create_input({
    name = "Skin Changer",
    placeholder = "Skin name",
    section = "left",
    default = "",
    Callback = function(v) 
	swordName = v 
    end
})
