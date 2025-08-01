--[[
    @author  (nathan) - Modernized with WindUI
    @description Grow a Garden auto-farm script with modern WindUI interface
    https://www.roblox.com/games/126884695634066
]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Leaderstats = LocalPlayer.leaderstats
local Backpack = LocalPlayer.Backpack
local PlayerGui = LocalPlayer.PlayerGui

local ShecklesCount = Leaderstats.Sheckles
local GameInfo = MarketplaceService:GetProductInfo(game.PlaceId)

--// Load WindUI with proper error checking
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Check if WindUI loaded correctly
if type(WindUI) ~= "table" then
    warn("WindUI did not load correctly. It is a " .. type(WindUI) .. ". Please ensure the game allows httpget and loadstring.")
    return
end

--// Folders
local GameEvents = ReplicatedStorage.GameEvents
local Farms = workspace.Farm

--// Gradient function for styled text
function gradient(text, startColor, endColor)
    local result = ""
    local length = #text

    for i = 1, length do
        local t = (i - 1) / math.max(length - 1, 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * t) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * t) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * t) * 255)

        local char = text:sub(i, i)
        result = result .. "<font color=\"rgb(" .. r ..", " .. g .. ", " .. b .. ")\">" .. char .. "</font>"
    end

    return result
end

--// Dicts
local SeedStock = {}
local OwnedSeeds = {}
local HarvestIgnores = {
	Normal = false,
	Gold = false,
	Rainbow = false
}

--// Globals
local SelectedSeed, SelectedSeedStock, AutoPlantRandom, AutoPlant, AutoHarvest, AutoBuy, AutoSell, SellThreshold, NoClip, AutoWalk, AutoWalkAllowRandom, AutoWalkMaxWait, AutoWalkStatus, OnlyShowStock

--// Add custom red/black theme
WindUI:AddTheme({
    Name = "ZeryxTheme",
    Accent = "#FF0000",
    Dialog = "#141414",
    Outline = "#FF0000",
    Text = "#FFFFFF",
    Placeholder = "#999999",
    Background = "#0e0e10",
    Button = "#FF0000",
    Icon = "#FF0000",
})

--// Welcome Popup
local Confirmed = false
WindUI:Popup({
    Title = "Welcome to Zeryx!",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Content = "Welcome to the modernized " .. gradient("Zeryx", Color3.fromHex("#FF0000"), Color3.fromHex("#000000")) .. " auto-farm script with WindUI!",
    Buttons = {
        {
            Title = "Cancel",
            Callback = function() 
                Confirmed = false 
            end,
            Variant = "Secondary",
        },
        {
            Title = "Start Farming",
            Icon = "play",
            Callback = function() 
                Confirmed = true 
            end,
            Variant = "Primary",
        }
    }
})

repeat wait() until Confirmed

if not Confirmed then
    return -- Exit if user cancelled
end

--// Interface functions
local function Plant(Position: Vector3, Seed: string)
	GameEvents.Plant_RE:FireServer(Position, Seed)
	wait(.3)
end

local function GetFarms()
	return Farms:GetChildren()
end

local function GetFarmOwner(Farm: Folder): string
	local Important = Farm.Important
	local Data = Important.Data
	local Owner = Data.Owner
	return Owner.Value
end

local function GetFarm(PlayerName: string): Folder?
	local Farms = GetFarms()
	for _, Farm in next, Farms do
		local Owner = GetFarmOwner(Farm)
		if Owner == PlayerName then
			return Farm
		end
	end
    return
end

local IsSelling = false
local function SellInventory()
	local Character = LocalPlayer.Character
	local Previous = Character:GetPivot()
	local PreviousSheckles = ShecklesCount.Value

	--// Prevent conflict
	if IsSelling then return end
	IsSelling = true

	Character:PivotTo(CFrame.new(62, 4, -26))
	while wait() do
		if ShecklesCount.Value ~= PreviousSheckles then break end
		GameEvents.Sell_Inventory:FireServer()
	end
	Character:PivotTo(Previous)

	wait(0.2)
	IsSelling = false
	
	-- Notify success
	WindUI:Notify({
		Title = "Inventory Sold!",
		Content = "Successfully sold inventory for " .. (ShecklesCount.Value - PreviousSheckles) .. " sheckles",
		Icon = "coins",
		Duration = 3,
	})
end

local function BuySeed(Seed: string)
	GameEvents.BuySeedStock:FireServer(Seed)
end

local function BuyAllSelectedSeeds()
    local Seed = SelectedSeedStock.Selected
    local Stock = SeedStock[Seed]

	if not Stock or Stock <= 0 then return end

    for i = 1, Stock do
        BuySeed(Seed)
    end
    
    -- Notify purchase
    WindUI:Notify({
		Title = "Seeds Purchased",
		Content = "Bought " .. Stock .. " " .. Seed .. " seeds",
		Icon = "shopping-cart",
		Duration = 3,
	})
end

local function GetSeedInfo(Seed: Tool): number?
	local PlantName = Seed:FindFirstChild("Plant_Name")
	local Count = Seed:FindFirstChild("Numbers")
	if not PlantName then return end
	return PlantName.Value, Count.Value
end

local function CollectSeedsFromParent(Parent, Seeds: table)
	for _, Tool in next, Parent:GetChildren() do
		local Name, Count = GetSeedInfo(Tool)
		if not Name then continue end
		Seeds[Name] = {
            Count = Count,
            Tool = Tool
        }
	end
end

local function CollectCropsFromParent(Parent, Crops: table)
	for _, Tool in next, Parent:GetChildren() do
		local Name = Tool:FindFirstChild("Item_String")
		if not Name then continue end
		table.insert(Crops, Tool)
	end
end

local function GetOwnedSeeds(): table
	local Character = LocalPlayer.Character
	CollectSeedsFromParent(Backpack, OwnedSeeds)
	CollectSeedsFromParent(Character, OwnedSeeds)
	return OwnedSeeds
end

local function GetInvCrops(): table
	local Character = LocalPlayer.Character
	local Crops = {}
	CollectCropsFromParent(Backpack, Crops)
	CollectCropsFromParent(Character, Crops)
	return Crops
end

local function GetArea(Base: BasePart)
	local Center = Base:GetPivot()
	local Size = Base.Size
	local X1 = math.ceil(Center.X - (Size.X/2))
	local Z1 = math.ceil(Center.Z - (Size.Z/2))
	local X2 = math.floor(Center.X + (Size.X/2))
	local Z2 = math.floor(Center.Z + (Size.Z/2))
	return X1, Z1, X2, Z2
end

local function EquipCheck(Tool)
    local Character = LocalPlayer.Character
    local Humanoid = Character.Humanoid
    if Tool.Parent ~= Backpack then return end
    Humanoid:EquipTool(Tool)
end

--// Auto farm functions
local MyFarm = GetFarm(LocalPlayer.Name)
local MyImportant = MyFarm.Important
local PlantLocations = MyImportant.Plant_Locations
local PlantsPhysical = MyImportant.Plants_Physical

local Dirt = PlantLocations:FindFirstChildOfClass("Part")
local X1, Z1, X2, Z2 = GetArea(Dirt)

local function GetRandomFarmPoint(): Vector3
    local FarmLands = PlantLocations:GetChildren()
    local FarmLand = FarmLands[math.random(1, #FarmLands)]
    local X1, Z1, X2, Z2 = GetArea(FarmLand)
    local X = math.random(X1, X2)
    local Z = math.random(Z1, Z2)
    return Vector3.new(X, 4, Z)
end

local function AutoPlantLoop()
	local Seed = SelectedSeed.Selected
	local SeedData = OwnedSeeds[Seed]
	if not SeedData then return end

    local Count = SeedData.Count
    local Tool = SeedData.Tool

	if Count <= 0 then return end

    local Planted = 0
	local Step = 1

    EquipCheck(Tool)

	if AutoPlantRandom.Value then
		for i = 1, Count do
			local Point = GetRandomFarmPoint()
			Plant(Point, Seed)
		end
	end
	
	for X = X1, X2, Step do
		for Z = Z1, Z2, Step do
			if Planted > Count then break end
			local Point = Vector3.new(X, 0.13, Z)
			Planted += 1
			Plant(Point, Seed)
		end
	end
end

local function HarvestPlant(Plant: Model)
	local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
	if not Prompt then return end
	fireproximityprompt(Prompt)
end

local function GetSeedStock(IgnoreNoStock: boolean?): table
	local SeedShop = PlayerGui.Seed_Shop
	local Items = SeedShop:FindFirstChild("Blueberry", true).Parent
	local NewList = {}

	for _, Item in next, Items:GetChildren() do
		local MainFrame = Item:FindFirstChild("Main_Frame")
		if not MainFrame then continue end

		local StockText = MainFrame.Stock_Text.Text
		local StockCount = tonumber(StockText:match("%d+"))

		if IgnoreNoStock then
			if StockCount <= 0 then continue end
			NewList[Item.Name] = StockCount
			continue
		end

		SeedStock[Item.Name] = StockCount
	end

	return IgnoreNoStock and NewList or SeedStock
end

local function CanHarvest(Plant): boolean?
    local Prompt = Plant:FindFirstChild("ProximityPrompt", true)
	if not Prompt then return end
    if not Prompt.Enabled then return end
    return true
end

local function CollectHarvestable(Parent, Plants, IgnoreDistance: boolean?)
	local Character = LocalPlayer.Character
	local PlayerPosition = Character:GetPivot().Position

    for _, Plant in next, Parent:GetChildren() do
		local Fruits = Plant:FindFirstChild("Fruits")
		if Fruits then
			CollectHarvestable(Fruits, Plants, IgnoreDistance)
		end

		local PlantPosition = Plant:GetPivot().Position
		local Distance = (PlayerPosition-PlantPosition).Magnitude
		if not IgnoreDistance and Distance > 15 then continue end

		local Variant = Plant:FindFirstChild("Variant")
		if HarvestIgnores[Variant.Value] then continue end

        if CanHarvest(Plant) then
            table.insert(Plants, Plant)
        end
	end
    return Plants
end

local function GetHarvestablePlants(IgnoreDistance: boolean?)
    local Plants = {}
    CollectHarvestable(PlantsPhysical, Plants, IgnoreDistance)
    return Plants
end

local function HarvestPlants(Parent: Model)
	local Plants = GetHarvestablePlants()
    for _, Plant in next, Plants do
        HarvestPlant(Plant)
    end
end

local function AutoSellCheck()
    local CropCount = #GetInvCrops()
    if not AutoSell.Value then return end
    if CropCount < SellThreshold.Value then return end
    SellInventory()
end

local function AutoWalkLoop()
	if IsSelling then return end

    local Character = LocalPlayer.Character
    local Humanoid = Character.Humanoid

    local Plants = GetHarvestablePlants(true)
	local RandomAllowed = AutoWalkAllowRandom.Value
	local DoRandom = #Plants == 0 or math.random(1, 3) == 2

    if RandomAllowed and DoRandom then
        local Position = GetRandomFarmPoint()
        Humanoid:MoveTo(Position)
		AutoWalkStatus.Text = "Moving to random point"
        return
    end
   
    for _, Plant in next, Plants do
        local Position = Plant:GetPivot().Position
        Humanoid:MoveTo(Position)
		AutoWalkStatus.Text = "Moving to " .. Plant.Name
    end
end

local function NoclipLoop()
    local Character = LocalPlayer.Character
    if not NoClip.Value then return end
    if not Character then return end

    for _, Part in Character:GetDescendants() do
        if Part:IsA("BasePart") then
            Part.CanCollide = false
        end
    end
end

local function MakeLoop(Toggle, Func)
	coroutine.wrap(function()
		while wait(.01) do
			if not Toggle.Value then continue end
			Func()
		end
	end)()
end

local function StartServices()
	MakeLoop(AutoWalk, function()
		local MaxWait = AutoWalkMaxWait.Value
		AutoWalkLoop()
		wait(math.random(1, MaxWait))
	end)

	MakeLoop(AutoHarvest, function()
		HarvestPlants(PlantsPhysical)
	end)

	MakeLoop(AutoBuy, BuyAllSelectedSeeds)
	MakeLoop(AutoPlant, AutoPlantLoop)

	while wait(.1) do
		GetSeedStock()
		GetOwnedSeeds()
	end
end

--// Create WindUI Window with CORRECTED UDim2 constructor
local Window = WindUI:CreateWindow({
    Title = "Zeryx",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Author = "grow a garden - WindUI Edition",
    Folder = "Zeryx",
    Size = UDim2.new(0, 360, 0, 80), -- FIXED: Using UDim2.new instead of UDim2.fromOffset
    Transparent = true,
    Theme = "ZeryxTheme", -- Use our custom theme
    User = {
        Enabled = true,
        Callback = function() 
            WindUI:Notify({
                Title = "Profile Clicked",
                Content = "User profile accessed",
                Icon = "user",
                Duration = 2,
            })
        end,
        Anonymous = false
    },
    SideBarWidth = 220,
    ScrollBarEnabled = true,
})

--// Create Sections
local AutoFarmSection = Window:Section({
    Title = "Auto Farm Features",
    Icon = "tractor",
    Opened = true,
})

local InventorySection = Window:Section({
    Title = "Inventory Management", 
    Icon = "package",
    Opened = true,
})

local MovementSection = Window:Section({
    Title = "Movement & Navigation",
    Icon = "navigation",
    Opened = false,
})

local EmptyTabSection = Window:Section({
    Title = "Extra Features",
    Icon = "plus",
    Opened = true,
})

--// Create Tabs
local PlantTab = AutoFarmSection:Tab({ 
    Title = "Auto Plant", 
    Icon = "seedling", 
    Desc = "Automated planting system with seed selection" 
})

local HarvestTab = AutoFarmSection:Tab({ 
    Title = "Auto Harvest", 
    Icon = "scissors", 
    Desc = "Automated harvesting with filtering options" 
})

local BuyTab = AutoFarmSection:Tab({ 
    Title = "Auto Buy", 
    Icon = "shopping-cart", 
    Desc = "Automated seed purchasing system" 
})

local SellTab = InventorySection:Tab({ 
    Title = "Auto Sell", 
    Icon = "coins", 
    Desc = "Automated inventory selling with thresholds" 
})

local WalkTab = MovementSection:Tab({ 
    Title = "Auto Walk", 
    Icon = "footprints", 
    Desc = "Automated movement and navigation" 
})

-- Empty tabs to populate
local ExtraTab1 = EmptyTabSection:Tab({
    Title = "Utility 1",
    Icon = "tool",
    Desc = "General utility functions"
})

local ExtraTab2 = EmptyTabSection:Tab({
    Title = "Utility 2",
    Icon = "settings",
    Desc = "Additional settings and options"
})

--// Plant Tab Content
PlantTab:Paragraph({
    Title = "Auto Plant System",
    Desc = "Automatically plant seeds in your farm area with customizable options",
    Image = "seedling",
    Color = "Red",
})

SelectedSeed = PlantTab:Dropdown({
    Title = "Select Seed",
    Values = function() 
        local seeds = {}
        for name, data in pairs(OwnedSeeds) do
            table.insert(seeds, name)
        end
        return seeds
    end,
    Multi = false,
    Default = "",
    Callback = function(value) 
        print("Selected seed: " .. tostring(value))
    end
})

AutoPlant = PlantTab:Toggle({
    Title = "Enable Auto Plant",
    Icon = "play",
    Value = false,
    Callback = function(state) 
        if state then
            WindUI:Notify({
                Title = "Auto Plant Enabled",
                Content = "Automatic planting is now active",
                Icon = "seedling",
                Duration = 2,
            })
        end
    end
})

AutoPlantRandom = PlantTab:Toggle({
    Title = "Random Planting Points",
    Icon = "shuffle",
    Value = false,
    Callback = function(state) 
        print("Random planting: " .. tostring(state))
    end
})

PlantTab:Button({
    Title = "Plant All Seeds",
    Icon = "zap",
    Desc = "Plant all available seeds immediately",
    Callback = function() 
        AutoPlantLoop()
        WindUI:Notify({
            Title = "Planting Complete",
            Content = "All available seeds have been planted",
            Icon = "check-circle",
            Duration = 3,
        })
    end,
})

--// Harvest Tab Content
HarvestTab:Paragraph({
    Title = "Auto Harvest System", 
    Desc = "Automatically harvest mature plants with filtering options",
    Image = "scissors",
    Color = "Red",
})

AutoHarvest = HarvestTab:Toggle({
    Title = "Enable Auto Harvest",
    Icon = "play",
    Value = false,
    Callback = function(state) 
        if state then
            WindUI:Notify({
                Title = "Auto Harvest Enabled",
                Content = "Automatic harvesting is now active",
                Icon = "scissors",
                Duration = 2,
            })
        end
    end
})

HarvestTab:Divider()

-- Harvest ignore toggles
for _, variant in ipairs({"Normal", "Gold", "Rainbow"}) do
    HarvestTab:Toggle({
        Title = "Ignore " .. variant .. " Plants",
        Icon = variant == "Gold" and "star" or variant == "Rainbow" and "palette" or "circle",
        Value = HarvestIgnores[variant],
        Callback = function(state) 
            HarvestIgnores[variant] = state
            print("Ignore " .. variant .. ": " .. tostring(state))
        end
    })
end

--// Buy Tab Content
BuyTab:Paragraph({
    Title = "Auto Buy System",
    Desc = "Automatically purchase seeds from the shop",
    Image = "shopping-cart", 
    Color = "Red",
})

SelectedSeedStock = BuyTab:Dropdown({
    Title = "Select Seed to Buy",
    Values = function()
        local OnlyStock = OnlyShowStock and OnlyShowStock.Value
        local stocks = GetSeedStock(OnlyStock)
        local seeds = {}
        for name, _ in pairs(stocks) do
            table.insert(seeds, name)
        end
        return seeds
    end,
    Multi = false,
    Default = "",
    Callback = function(value) 
        print("Selected seed to buy: " .. tostring(value))
    end
})

AutoBuy = BuyTab:Toggle({
    Title = "Enable Auto Buy",
    Icon = "play",
    Value = false,
    Callback = function(state) 
        if state then
            WindUI:Notify({
                Title = "Auto Buy Enabled", 
                Content = "Automatic seed purchasing is now active",
                Icon = "shopping-cart",
                Duration = 2,
            })
        end
    end
})

OnlyShowStock = BuyTab:Toggle({
    Title = "Only Show Available Stock",
    Icon = "filter",
    Value = false,
    Callback = function(state) 
        print("Only show stock: " .. tostring(state))
    end
})

BuyTab:Button({
    Title = "Buy All Selected",
    Icon = "shopping-bag",
    Desc = "Purchase all available stock of selected seed",
    Callback = function() 
        BuyAllSelectedSeeds()
    end,
})

--// Sell Tab Content
SellTab:Paragraph({
    Title = "Auto Sell System",
    Desc = "Automatically sell crops when inventory reaches threshold",
    Image = "coins",
    Color = "Red",
})

SellTab:Button({
    Title = "Sell Inventory Now",
    Icon = "dollar-sign",
    Desc = "Immediately sell all crops in inventory",
    Callback = function() 
        SellInventory()
    end,
})

AutoSell = SellTab:Toggle({
    Title = "Enable Auto Sell",
    Icon = "play", 
    Value = false,
    Callback = function(state) 
        if state then
            WindUI:Notify({
                Title = "Auto Sell Enabled",
                Content = "Automatic selling is now active",
                Icon = "coins",
                Duration = 2,
            })
        end
    end
})

SellThreshold = SellTab:Slider({
    Title = "Crop Threshold",
    Value = {
        Min = 1,
        Max = 199,
        Default = 15,
    },
    Callback = function(value) 
        print("Sell threshold set to: " .. value)
    end
})

--// Walk Tab Content
WalkTab:Paragraph({
    Title = "Auto Walk System",
    Desc = "Automated movement and navigation with noclip support",
    Image = "footprints",
    Color = "Red",
})

AutoWalkStatus = WalkTab:Paragraph({
    Title = "Status: Idle",
    Desc = "Current movement status",
    Image = "activity",
})

AutoWalk = WalkTab:Toggle({
    Title = "Enable Auto Walk",
    Icon = "play",
    Value = false,
    Callback = function(state) 
        if state then
            WindUI:Notify({
                Title = "Auto Walk Enabled",
                Content = "Automatic movement is now active", 
                Icon = "footprints",
                Duration = 2,
            })
        end
    end
})

AutoWalkAllowRandom = WalkTab:Toggle({
    Title = "Allow Random Points",
    Icon = "shuffle",
    Value = true,
    Callback = function(state) 
        print("Allow random points: " .. tostring(state))
    end
})

NoClip = WalkTab:Toggle({
    Title = "NoClip",
    Icon = "ghost",
    Value = false,
    Callback = function(state) 
        if state then
            WindUI:Notify({
                Title = "NoClip Enabled",
                Content = "You can now walk through walls",
                Icon = "ghost",
                Duration = 2,
            })
        end
    end
})

AutoWalkMaxWait = WalkTab:Slider({
    Title = "Max Movement Delay",
    Value = {
        Min = 1,
        Max = 120,
        Default = 10,
    },
    Callback = function(value) 
        print("Max walk delay set to: " .. value .. " seconds")
    end
})

--// Populate Empty Tabs
ExtraTab1:Paragraph({
    Title = "Utility Feature 1",
    Desc = "This is a placeholder for a new utility feature.",
    Image = "tool",
    Color = "Red",
})

local utilityToggle1 = ExtraTab1:Toggle({
    Title = "Enable Utility 1",
    Icon = "power",
    Value = false,
    Callback = function(state)
        print("Utility 1 enabled: " .. tostring(state))
        WindUI:Notify({
            Title = "Utility 1 Status",
            Content = "Utility 1 is now " .. (state and "enabled" or "disabled"),
            Icon = "info",
            Duration = 2,
        })
    end
})

ExtraTab1:Button({
    Title = "Perform Action 1",
    Icon = "play",
    Desc = "Click to perform a sample action for Utility 1",
    Callback = function()
        print("Action 1 performed!")
        WindUI:Notify({
            Title = "Action Performed",
            Content = "Sample action from Utility 1 executed!",
            Icon = "check",
            Duration = 2,
        })
    end
})

ExtraTab2:Paragraph({
    Title = "Utility Feature 2",
    Desc = "This is a placeholder for another utility feature.",
    Image = "settings",
    Color = "Red",
})

local utilityToggle2 = ExtraTab2:Toggle({
    Title = "Enable Utility 2",
    Icon = "power",
    Value = false,
    Callback = function(state)
        print("Utility 2 enabled: " .. tostring(state))
        WindUI:Notify({
            Title = "Utility 2 Status",
            Content = "Utility 2 is now " .. (state and "enabled" or "disabled"),
            Icon = "info",
            Duration = 2,
        })
    end
})

ExtraTab2:Button({
    Title = "Perform Action 2",
    Icon = "play",
    Desc = "Click to perform a sample action for Utility 2",
    Callback = function()
        print("Action 2 performed!")
        WindUI:Notify({
            Title = "Action Performed",
            Content = "Sample action from Utility 2 executed!",
            Icon = "check",
            Duration = 2,
        })
    end
})

--// Start the automation services
RunService.Stepped:Connect(NoclipLoop)
Backpack.ChildAdded:Connect(AutoSellCheck)

StartServices()

--// Success notification
WindUI:Notify({
    Title = "Script Loaded Successfully!",
    Content = "Zeryx is ready to use",
    Icon = "check-circle",
    Duration = 5,
})

