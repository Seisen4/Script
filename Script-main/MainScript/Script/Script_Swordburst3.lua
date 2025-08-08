-- SERVICES
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    Workspace = game:GetService("Workspace"),
    VirtualUser = game:GetService("VirtualUser")
}

-- PLAYER & CHARACTER REFERENCES
local PlayerData = {
    player = Services.Players.LocalPlayer,
    character = nil,
    humanoid = nil,
    hrp = nil,
    profile = nil,
    inventory = nil
}

-- Initialize player data
PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
PlayerData.humanoid = PlayerData.character:WaitForChild("Humanoid")
PlayerData.hrp = PlayerData.character:WaitForChild("HumanoidRootPart")
PlayerData.profile = Services.ReplicatedStorage:WaitForChild("Profiles"):WaitForChild(PlayerData.player.Name)
PlayerData.inventory = PlayerData.profile:WaitForChild("Inventory")

-- GAME FOLDERS & REFERENCES
local GameFolders = {
    mobsFolder = Services.Workspace:FindFirstChild("Mobs"),
    waystones = Services.Workspace:FindFirstChild("Waystones", 9e9),
    stations = Services.Workspace:FindFirstChild("CraftingStations", 9e9)
}

-- CRAFTING STATIONS
local CraftingStations = {
    enchanting = GameFolders.stations and GameFolders.stations:FindFirstChild("Enchanting", 9e9) or nil,
    mounts = GameFolders.stations and GameFolders.stations:FindFirstChild("Mounts", 9e9) or nil,
    smithing = GameFolders.stations and GameFolders.stations:FindFirstChild("Smithing", 9e9) or nil
}

-- REMOTE EVENTS & FUNCTIONS
local Remotes = {
    -- Crafting
    dismantle = Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Crafting"):WaitForChild("Dismantle"),
    chest = Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Chests"):WaitForChild("ClaimItem"),
    useSkill = Services.ReplicatedStorage.Systems.Skills:WaitForChild("UseSkill"),
    
    -- Combat
    playerAttack = Services.ReplicatedStorage.Systems.Combat.PlayerAttack,
    skillAttack = Services.ReplicatedStorage.Systems.Combat:WaitForChild("PlayerSkillAttack"),
    
    -- Skills
    useSkill = Services.ReplicatedStorage.Systems.Skills:WaitForChild("UseSkill"),
    
    -- Effects
    doEffect = Services.ReplicatedStorage.Systems.Effects.DoEffect,
    
    -- Teleportation
    teleportWaystone = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Locations", 9e9):WaitForChild("TeleportWaystone", 9e9),
    teleportFloor = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Teleport", 9e9):WaitForChild("Teleport", 9e9),
    voidTower = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("TowerDungeon", 9e9):WaitForChild("StartDungeon", 9e9),
    EnterDungeon = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("DungeonRaids", 9e9):WaitForChild("EnterDungeon", 9e9)
}

-- QUEST SYSTEM REMOTES
local QuestRemotes = {
    folder = Services.ReplicatedStorage:WaitForChild("Systems"):FindFirstChild("WeeklyQuests") or Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("DailyQuests"),
    claimQuest = nil,
    claimReward = nil,
    update = nil
}

-- Initialize quest remotes
QuestRemotes.claimQuest = QuestRemotes.folder:WaitForChild("ClaimIndividualDailyQuest")
QuestRemotes.claimReward = QuestRemotes.folder:WaitForChild("ClaimDailyQuestReward")
QuestRemotes.update = QuestRemotes.folder:WaitForChild("Update")

-- ACHIEVEMENT REMOTE
local achievementRemote = Services.ReplicatedStorage:WaitForChild("Systems", 9e9):WaitForChild("Achievements", 9e9):WaitForChild("ClaimAchievementReward", 9e9)

-- MODULES
local Modules = {
    antiCheat = require(Services.ReplicatedStorage.Systems.AntiCheat),
    questList = require(Services.ReplicatedStorage.Systems.Quests.QuestList),
    drops = require(Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Drops")),
    skillSystem = require(Services.ReplicatedStorage.Systems.Skills),
    items = require(Services.ReplicatedStorage.Systems.Items)
}

-- CONFIGURATION & CONSTANTS
local CONFIG = {
    HEIGHT_OFFSET = 35,
    FOLLOW_DISTANCE = 3,
    BASE_SPEED = 40,
    SPEED_CAP = 90,
    DISTANCE_THRESHOLD = 200,
    KILL_AURA_RANGE = 100,
    KILL_AURA_DELAY = 0.26,
    AUTO_COLLECT_ENABLED = true,
    COLLECT_RADIUS = 80,
    CHECK_INTERVAL = 0.1,
    SKILL_SLOTS = {1, 2, 3}, -- Add as many slots as you want
    FALLBACK_COOLDOWN = 2,
    QUEST_CHECK_INTERVAL = 2,
    TRIGGER_DISTANCE = 500,
    AUTO_CLAIM_ENABLED = true,
    TELEPORT_DELAY = 2,
}

-- Add global unload flag and connection holders
local isUnloaded = false
local connections = {}

-- ANTI-AFK SYSTEM
local AntiAfkSystem = {
    -- Passive Anti-AFK
    setup = function()
        local conn = PlayerData.player.Idled:Connect(function()
            Services.VirtualUser:Button2Down(Vector2.new(0, 0), Services.Workspace.CurrentCamera.CFrame)
            task.wait(1)
            Services.VirtualUser:Button2Up(Vector2.new(0, 0), Services.Workspace.CurrentCamera.CFrame)
        end)
        table.insert(connections, conn)
    end,

    -- Notification UI
    createNotification = function()
        -- This function is now empty as we're using Obsidian UI for notifications
    end
}

-- Initialize Anti-AFK
AntiAfkSystem.setup()
AntiAfkSystem.createNotification()

-- RUNTIME STATE & VARIABLES
local RuntimeState = {
    -- Automation toggles
    stopFollowing = true,
    killAuraEnabled = false,
    autoCollectEnabled = false,
    autoSkillEnabled = false,
    autoClaimEnabled = false,
    autoDismantleEnabled = false,
    autoDailyQuestsEnabled = false,
    autoAchievementEnabled = false,
    
    -- UI toggles
    openEnchantUIManualEnabled = false,
    openMountsUIManualEnabled = false,
    openSmithingUIManualEnabled = false,
    
    -- Selection variables
    selectedMobName = "Razor Boar",
    selectedQuestId = nil,
    selectedRarity = "Uncommon",
    
    -- Movement/physics
    bodyVelocity = nil,
    tween = nil,
    lastVelocity = Vector3.zero,
    
    -- Quest system
    global_isEnabled_autoquest = false,
    
    -- Caches and tracking
    dropCache = {},
    lastUsed = {},
    claimedQuest = {},
    claimedReward = {},
    autoTowerDungeonEnabled = false,
    selectedDungeonFloor = nil,
    infiniteStamina = false,
    autoBossEnabled = false,
    bossFollowDistance = 3,
    error445Enabled = false,
    customFpsBoostEnabled = false,
    maxFpsBoostEnabled = false,
    superMaxFpsBoostEnabled = false,
    bossArenaNoclip = false,
    autoIceDungeonEnabled = false,
    autoDungeonEnabled = false,
    autoCaveDungeonEnabled = false,
    autoPortalEnabled = false,
}

local configFolder = "SeisenHub"
local configFile = configFolder .. "/seisen_hub_sb3.txt"
local HttpService = game:GetService("HttpService")



local function loadConfig()
    if not (isfile and isfile(configFile)) then return end
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(configFile))
    end)
    if success and type(data) == "table" then
        for k, v in pairs(data) do
            if RuntimeState[k] ~= nil then
                RuntimeState[k] = v
            end
        end
    end
end

loadConfig()

if not isfolder(configFolder) then
    makefolder(configFolder)
end

local function saveConfig()
    local config = {
        stopFollowing = RuntimeState.stopFollowing,
        killAuraEnabled = RuntimeState.killAuraEnabled,
        autoCollectEnabled = RuntimeState.autoCollectEnabled,
        autoSkillEnabled = RuntimeState.autoSkillEnabled,
        autoClaimEnabled = RuntimeState.autoClaimEnabled,
        autoDismantleEnabled = RuntimeState.autoDismantleEnabled,
        autoDailyQuestsEnabled = RuntimeState.autoDailyQuestsEnabled,
        autoAchievementEnabled = RuntimeState.autoAchievementEnabled,
        openEnchantUIManualEnabled = RuntimeState.openEnchantUIManualEnabled,
        openMountsUIManualEnabled = RuntimeState.openMountsUIManualEnabled,
        openSmithingUIManualEnabled = RuntimeState.openSmithingUIManualEnabled,
        selectedMobName = RuntimeState.selectedMobName,
        selectedQuestId = RuntimeState.selectedQuestId,
        selectedRarity = RuntimeState.selectedRarity,
        global_isEnabled_autoquest = RuntimeState.global_isEnabled_autoquest,
        autoTowerDungeonEnabled = RuntimeState.autoTowerDungeonEnabled,
        selectedDungeonFloor = RuntimeState.selectedDungeonFloor,
        infiniteStamina = RuntimeState.infiniteStamina,
        autoBossEnabled = RuntimeState.autoBossEnabled,
        bossFollowDistance = RuntimeState.bossFollowDistance,
        error445Enabled = RuntimeState.error445Enabled,
        customFpsBoostEnabled = RuntimeState.customFpsBoostEnabled,
        maxFpsBoostEnabled = RuntimeState.maxFpsBoostEnabled,
        superMaxFpsBoostEnabled = RuntimeState.superMaxFpsBoostEnabled,
        bossArenaNoclip = RuntimeState.bossArenaNoclip,
        autoIceDungeonEnabled = RuntimeState.autoIceDungeonEnabled,
        autoDungeonEnabled = RuntimeState.autoDungeonEnabled,
        autoCaveDungeonEnabled = RuntimeState.autoCaveDungeonEnabled,
        autoPortalEnabled = RuntimeState.autoPortalEnabled,
    }
    pcall(function()
        writefile(configFile, HttpService:JSONEncode(config))
    end)
end


-- RARITY SYSTEM
local RaritySystem = {
    map = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5
    },
    list = { "Common", "Uncommon", "Rare", "Epic", "Legendary" },
    currentIndex = 2
}

-- Fix: Define QuestSystem before using it
local QuestSystem = {
    toMobMap = {}
}

-- Initialize quest mapping
for id, data in pairs(Modules.questList) do
    if data.Type == "Kill" and data.Target then
        QuestSystem.toMobMap[id] = data.Target
    end
end

-- DROP CACHE INITIALIZATION
local function initializeDropCache()
local success, drops = pcall(function()
        return getupvalue(Modules.drops.SpawnDropModel, 7)
end)
    
if success and type(drops) == "table" then
        RuntimeState.dropCache = drops
        return true
    else
        warn("⚠️ Failed to access drop cache. Auto collect disabled.")
        RuntimeState.autoCollectEnabled = false
        return false
    end
end

-- Initialize drop cache
initializeDropCache()

-- Function to simulate triggering ProximityPrompt
local function triggerPrompt(prompt)
    pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.35)
        prompt:Trigger()
        task.wait(0.2)
        prompt:InputHoldEnd()
    end)
end

-- Unlock all waystones using ProximityPrompt (no movement)
local function unlockAllWaystones()
    local unlocked = {}

    for _, stone in ipairs(GameFolders.waystones:GetChildren()) do
        if stone:IsA("Model") and tonumber(stone.Name) and not unlocked[stone.Name] then
            -- Teleport to the waystone
            Remotes.teleportWaystone:FireServer(stone)
            task.wait(CONFIG.TELEPORT_DELAY)

            local main = stone:FindFirstChild("Main")
            if main then
                local prompt = main:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    triggerPrompt(prompt)
                    unlocked[stone.Name] = true
                end
            end

            task.wait(1.2)
        end
    end
end

-- Load Obsidian UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
Library.ShowCustomCursor = false

-- Create the main window with mobile button positioning
local Window = Library:CreateWindow({
    Title = "Seisen Hub",
    Footer = "Swordburst 3",
    Center = true,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.RightControl,
    MobileButtonsSide = "Right" -- "Left" or "Right"
})

-- Check if the user is on mobile
if Library.IsMobile then
    -- Adjust your UI accordingly (e.g., scale, layout, etc.)
    -- You can add mobile-specific tweaks here if needed
end

-- Tabs
local MainTab = Window:AddTab("Main", "box")
local SettingsTab = Window:AddTab("Settings", "settings")
local InfoGroup = SettingsTab:AddLeftGroupbox("Script Information", "info")
-- MainTab: Features
local MainBox = MainTab:AddLeftGroupbox("Automation")

MainBox:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = not RuntimeState.stopFollowing,
    Callback = function(Value)
        RuntimeState.stopFollowing = not Value
        if Value then startFollowing() else stopFollowingNow() end
        saveConfig()
    end
})

MainBox:AddToggle("KillAura", {
    Text = "Kill Aura",
    Default = RuntimeState.killAuraEnabled,
    Callback = function(Value)
        RuntimeState.killAuraEnabled = Value
        saveConfig()
    end
})

MainBox:AddToggle("AutoQuest", {
    Text = "Auto Quest",
    Default = RuntimeState.global_isEnabled_autoquest,
    Callback = function(Value)
        RuntimeState.global_isEnabled_autoquest = Value
        saveConfig()
    end
})

MainBox:AddToggle("AutoCollect", {
    Text = "Auto Collect",
    Default = RuntimeState.autoCollectEnabled,
    Callback = function(Value)
        RuntimeState.autoCollectEnabled = Value
        saveConfig()
    end
})

MainBox:AddToggle("AutoSkill", {
    Text = "Auto Skill",
    Default = RuntimeState.autoSkillEnabled,
    Callback = function(Value)
        RuntimeState.autoSkillEnabled = Value
        saveConfig()
    end
})

MainBox:AddToggle("AutoClaim", {
    Text = "Auto Claim Chest",
    Default = RuntimeState.autoClaimEnabled,
    Callback = function(Value)
        RuntimeState.autoClaimEnabled = Value
        saveConfig()
    end
})

MainBox:AddToggle("AutoDailyQuests", {
    Text = "Auto Claim Daily Quests",
    Default = RuntimeState.autoDailyQuestsEnabled,
    Callback = function(Value)
        RuntimeState.autoDailyQuestsEnabled = Value
        saveConfig()
        if Value then
            for i = 1, 10 do pcall(function() QuestRemotes.claimQuest:FireServer(unpack({i})) end) end
            for _, milestone in ipairs({1, 3, 6}) do pcall(function() QuestRemotes.claimReward:FireServer(milestone) end) end
        end
    end
})

MainBox:AddToggle("AutoAchievement", {
    Text = "Auto Claim Achievement",
    Default = RuntimeState.autoAchievementEnabled,
    Callback = function(Value)
        RuntimeState.autoAchievementEnabled = Value
        saveConfig()
    end
})

-- Infinite Stamina patch logic
local staminaModule = require(Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Stamina"))
local originalCanUse = staminaModule.CanUseStamina
local originalUse = staminaModule.UseStamina
local originalAttachBar = staminaModule.AttachBar
local infiniteStaminaEnabled = false

local function toggleInfiniteStamina(enabled)
    infiniteStaminaEnabled = enabled
    if enabled then
        -- Enable infinite stamina
        staminaModule.CanUseStamina = function(_, _) return true end
        staminaModule.UseStamina = function(_, _) return true end
        staminaModule.SetMaxStamina(_, 999999)
        staminaModule.AttachBar = function(_, _) end
        -- Delete existing stamina bar UI
        local player = Services.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BillboardGui") and part.Name == "StaminaBar" then
                part:Destroy()
            end
        end
    else
        -- Restore original stamina functions
        staminaModule.CanUseStamina = originalCanUse
        staminaModule.UseStamina = originalUse
        staminaModule.AttachBar = originalAttachBar
    end
end

MainBox:AddToggle("InfiniteStamina", {
    Text = "Infinite Stamina",
    Default = RuntimeState.infiniteStamina,
    Callback = function(Value)
        RuntimeState.infiniteStamina = Value
        toggleInfiniteStamina(Value)
        saveConfig()
    end
})

-- Dropdowns for Mob, Quest, Rarity
local mobDropdownRef, questDropdownRef
local questIdByLabel = {}

local function refreshMobAndQuestDropdowns()
    -- Refresh mob list
    local mobList = {}
    if GameFolders.mobsFolder then
        for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
            if not table.find(mobList, mob.Name) then
                table.insert(mobList, mob.Name)
            end
        end
    end
    if mobDropdownRef then mobDropdownRef:SetValues(mobList) end

    -- Refresh quest list
    local mobSet = {}
    if GameFolders.mobsFolder then
        for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
            mobSet[mob.Name] = true
        end
    end

    local questIDs = {}
    for id, data in pairs(Modules.questList) do
        if data.Type == "Kill" and mobSet[data.Target] then
            table.insert(questIDs, {id = id, level = data.Level})
        end
    end
    table.sort(questIDs, function(a, b) return a.level < b.level end)

    local questLabels = {}
    questIdByLabel = {}
    for _, entry in ipairs(questIDs) do
        local id = entry.id
        local data = Modules.questList[id]
        local label = "[Lv. " .. tostring(data.Level) .. "] " .. data.Target
        if data.Repeatable then
            label = label .. " (Repeatable)"
        end
        table.insert(questLabels, label)
        questIdByLabel[label] = id
    end
    if questDropdownRef then questDropdownRef:SetValues(questLabels) end
end

-- Create MobDropdown and keep a reference
mobDropdownRef = MainBox:AddDropdown("MobDropdown", {
    Text = "Mob",
    Values = {},
    Default = RuntimeState.selectedMobName,
    Callback = function(Value)
        RuntimeState.selectedMobName = Value
        saveConfig()
    end
})

questDropdownRef = MainBox:AddDropdown("QuestDropdown", {
    Text = "Quest",
    Values = {},
    Default = nil,
    Callback = function(Value)
        local id = questIdByLabel[Value]
        if id then
            RuntimeState.selectedQuestId = tonumber(id)
            local targetMob = Modules.questList[id].Target
            RuntimeState.selectedMobName = targetMob
            -- Refresh mob dropdown list and set value
            if mobDropdownRef then
                -- Repopulate the mob list in case it changed
                local mobList = {}
                if GameFolders.mobsFolder then
                    for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
                        if not table.find(mobList, mob.Name) then
                            table.insert(mobList, mob.Name)
                        end
                    end
                end
                mobDropdownRef:SetValues(mobList)
                mobDropdownRef:SetValue(targetMob)
            end
            pcall(function()
                Services.ReplicatedStorage.Systems.Quests.AcceptQuest:FireServer(RuntimeState.selectedQuestId)
            end)
            saveConfig()
        end
    end
})

-- Initial population
refreshMobAndQuestDropdowns()

-- Set default for quest dropdown after initial population
do
    local questLabels = (questDropdownRef and questDropdownRef.GetValues and questDropdownRef:GetValues()) or {}
    for _, label in ipairs(questLabels) do
        if tonumber(questIdByLabel[label]) == tonumber(RuntimeState.selectedQuestId) then
            questDropdownRef:SetValue(label)
            break
        end
    end
end

-- Periodically refresh the dropdowns
task.spawn(function()
    while true do
        refreshMobAndQuestDropdowns()
        task.wait(5)
    end
end)

-- MainTab: Utility Groupbox
local UtilityBox = MainTab:AddRightGroupbox("Utility")

-- Add Boss Follow Distance slider to Utility groupbox above Dismantle Rarity
UtilityBox:AddSlider("BossFollowDistanceSlider", {
    Text = "Follow Distance",
    Min = 10,
    Max = 50,
    Default = RuntimeState.bossFollowDistance or 3,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        RuntimeState.bossFollowDistance = value
        saveConfig()
    end
})



-- Add Auto Portal toggle below Follow Distance
UtilityBox:AddToggle("AutoPortal", {
    Text = "Auto Portal (Not Working With Auto Farm)",
    Default = RuntimeState.autoPortalEnabled or false,
    Callback = function(Value)
        RuntimeState.autoPortalEnabled = Value
        print("[AutoPortal] Toggle set to", Value, "Noclip should be:", not Value)
        saveConfig()
    end
})

UtilityBox:AddToggle("AutoDismantle", {
    Text = "Auto Dismantle",
    Default = RuntimeState.autoDismantleEnabled,
    Callback = function(Value)
        RuntimeState.autoDismantleEnabled = Value
        if Value then AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity]) end
        saveConfig()
    end
})

UtilityBox:AddDropdown("RarityDropdown", {
    Text = "Dismantle Rarity",
    Values = RaritySystem.list,
    Default = RuntimeState.selectedRarity,
    Callback = function(Value)
        RuntimeState.selectedRarity = Value
        saveConfig()
        if RuntimeState.autoDismantleEnabled then
            AutoDismantleByMaxRarity(RaritySystem.map[Value])
        end
    end
})

UtilityBox:AddButton({
    Text = "Open Enchant UI",
    Func = function()
        if CraftingStations.enchanting then
            local prompt = CraftingStations.enchanting:FindFirstChild("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
        end
    end
})

UtilityBox:AddButton({
    Text = "Open Mounts UI",
    Func = function()
        if CraftingStations.mounts then
            local prompt = CraftingStations.mounts:FindFirstChild("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
        end
    end
})

UtilityBox:AddButton({
    Text = "Open Smithing UI",
    Func = function()
        if CraftingStations.smithing then
            local prompt = CraftingStations.smithing:FindFirstChild("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
        end
    end
})

UtilityBox:AddButton({
    Text = "Unlock All Waystones",
    Func = function()
        unlockAllWaystones()
    end
})

-- Waystone Dropdown
local waystoneList = {}
if GameFolders.waystones then
    for _, ws in ipairs(GameFolders.waystones:GetChildren()) do
        if ws:IsA("Model") and tonumber(ws.Name) then
            table.insert(waystoneList, ws.Name)
        end
    end
end
UtilityBox:AddDropdown("WaystoneDropdown", {
    Text = "Waystone",
    Values = waystoneList,
    Callback = function(Value)
        teleportToWaystone(Value)
    end
})

-- Floor Teleport Dropdown
local floorList = { "Town", "Floor1", "Floor2", "Floor3", "Floor4", "Floor5", "Floor6", "Floor7", "Floor8", "VoidTower" }
UtilityBox:AddDropdown("FloorTeleportDropdown", {
    Text = "Teleport",
    Values = floorList,
    Callback = function(Value)
        teleportToFloor(Value)
    end
})

-- Tower & Dungeon previous state holder
local previousStates = {}

local TowerBox = MainTab:AddRightGroupbox("Tower & Dungeon")

TowerBox:AddToggle("AutoTower", {
    Text = "Auto Tower",
    Default = RuntimeState.autoTowerDungeonEnabled,
    Callback = function(Value)
        RuntimeState.autoTowerDungeonEnabled = Value
        saveConfig()
    end
})

TowerBox:AddToggle("AutoIceDungeon", {
    Text = "Auto Ice Dungeon",
    Default = RuntimeState.autoIceDungeonEnabled,
    Callback = function(Value)
        if Value then
            RuntimeState.autoCollectEnabled = true
            RuntimeState.autoSkillEnabled = true
            RuntimeState.killAuraEnabled = true
        else
            RuntimeState.autoCollectEnabled = false
            RuntimeState.autoSkillEnabled = false
            RuntimeState.killAuraEnabled = false
        end
        RuntimeState.autoIceDungeonEnabled = Value
        saveConfig()
    end
})

TowerBox:AddToggle("AutoCaveDungeon", {
    Text = "Auto Cave Dungeon",
    Default = RuntimeState.autoCaveDungeonEnabled,
    Callback = function(Value)
        if Value then
            RuntimeState.autoCaveDungeonEnabled = true
        else
            RuntimeState.autoCaveDungeonEnabled = false
        end
        saveConfig()
    end
})


TowerBox:AddDropdown("DungeonFloor", {
    Text = "Dungeon Floor",
    Values = (function() local t = {}; for i=1,50 do table.insert(t, tostring(i)) end; return t end)(),
    Default = tostring(RuntimeState.selectedDungeonFloor),
    Callback = function(Value)
        RuntimeState.selectedDungeonFloor = tonumber(Value)
        saveConfig()
        pcall(function() Services.ReplicatedStorage.Systems.TowerDungeon.StartDungeon:FireServer(RuntimeState.selectedDungeonFloor) end)
    end
})

local dungeonDifficulties = {"Easy", "Medium", "Hard", "Insane", "Extreme", "Nightmare"}
TowerBox:AddDropdown("CaveDifficulty", {
    Text = "Cave Difficulty",
    Values = dungeonDifficulties,
    Default = dungeonDifficulties[1],
    Callback = function(Value)
        local idx
        for i, v in ipairs(dungeonDifficulties) do
            if v == Value then idx = i break end
        end
        if idx then
            Remotes.EnterDungeon:FireServer("CrystalCavern", idx)
        end
    end
})

TowerBox:AddDropdown("IceDifficulty", {
    Text = "Ice Difficulty",
    Values = dungeonDifficulties,
    Default = dungeonDifficulties[1],
    Callback = function(Value)
        local idx
        for i, v in ipairs(dungeonDifficulties) do
            if v == Value then idx = i break end
        end
        if idx then
            Remotes.EnterDungeon:FireServer("IcyInfernum", idx)
        end
    end
})

-- Infinite Stamina Logic (generic, works for most games)
task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.infiniteStamina then
            local hum = PlayerData.humanoid
            if hum then
                -- Try to set Stamina property if it exists
                pcall(function()
                    if hum:FindFirstChild("Stamina") then
                        hum.Stamina.Value = hum.Stamina.MaxValue or hum.Stamina.Value or 100
                    end
                end)
                -- Try to set Energy property if it exists
                pcall(function()
                    if hum:FindFirstChild("Energy") then
                        hum.Energy.Value = hum.Energy.MaxValue or hum.Energy.Value or 100
                    end
                end)
                -- Try to set any other common stamina-like property
                for _, v in ipairs(hum:GetChildren()) do
                    if v:IsA("NumberValue") and (v.Name:lower():find("stamina") or v.Name:lower():find("energy")) then
                        v.Value = v.MaxValue or v.Value or 100
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Function to delete stamina/energy values from character and humanoid
function deleteStaminaValues()
    local char = PlayerData.player.Character
    if not char then return end
    -- Remove from character
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("NumberValue") and (v.Name:lower():find("stamina") or v.Name:lower():find("energy")) then
            v:Destroy()
        end
    end
    -- Remove from humanoid
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        for _, v in ipairs(hum:GetChildren()) do
            if v:IsA("NumberValue") and (v.Name:lower():find("stamina") or v.Name:lower():find("energy")) then
                v:Destroy()
            end
        end
    end
end

-- Run on script load
pcall(deleteStaminaValues)
-- Run on character respawn
PlayerData.player.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(deleteStaminaValues)
end)

-- On load, apply patch if enabled
if RuntimeState.infiniteStamina then
    toggleInfiniteStamina(true)
end

-- === FUNCTION STUBS TO ENSURE OBSIDIAN UI WORKS ===
if not startFollowing then function startFollowing() print("startFollowing called") end end
if not stopFollowingNow then function stopFollowingNow() print("stopFollowingNow called") end end
if not saveConfig then function saveConfig() print("saveConfig called") end end
if not AutoDismantleByMaxRarity then function AutoDismantleByMaxRarity() print("AutoDismantleByMaxRarity called") end end
if not unlockAllWaystones then function unlockAllWaystones() print("unlockAllWaystones called") end end
if not setAllToSmoothPlasticPersistent then function setAllToSmoothPlasticPersistent() print("setAllToSmoothPlasticPersistent called") end end
if not restoreAllMaterialsPersistent then function restoreAllMaterialsPersistent() print("restoreAllMaterialsPersistent called") end end
if not setAllCastShadowOffPersistent then function setAllCastShadowOffPersistent() print("setAllCastShadowOffPersistent called") end end
if not restoreAllCastShadowsPersistent then function restoreAllCastShadowsPersistent() print("restoreAllCastShadowsPersistent called") end end
if not removeVisualClutterPersistent then function removeVisualClutterPersistent() print("removeVisualClutterPersistent called") end end
if not toggleInfiniteStamina then function toggleInfiniteStamina() print("toggleInfiniteStamina called") end end
-- === END FUNCTION STUBS ===

-- Find closest mob
local function findClosestMob()
    if not GameFolders.mobsFolder then return nil end
    local closest, minDist = nil, math.huge
    for _, mob in pairs(GameFolders.mobsFolder:GetChildren()) do
        if mob:IsA("Model") and string.find(mob.Name, RuntimeState.selectedMobName) then
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            local mobHum = mob:FindFirstChild("Humanoid")
            if mobHRP and (not mobHum or mobHum.Health > 0) then
                local dist = (mobHRP.Position - PlayerData.hrp.Position).Magnitude
                if dist < minDist then
                    closest = mob
                    minDist = dist
                end
            end
        end
    end
    return closest
end

local function activateHover(mobHRP)
    if not RuntimeState.bodyVelocity then
        RuntimeState.bodyVelocity = Instance.new("BodyVelocity")
        RuntimeState.bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        RuntimeState.bodyVelocity.P = 3000
        RuntimeState.bodyVelocity.Velocity = Vector3.zero
        RuntimeState.bodyVelocity.Parent = PlayerData.hrp
    end
    RuntimeState.lastVelocity = RuntimeState.bodyVelocity.Velocity
    Services.RunService:BindToRenderStep("FollowMobStep", Enum.RenderPriority.Character.Value, function()
        if isUnloaded then
            Services.RunService:UnbindFromRenderStep("FollowMobStep")
            return
        end
        if RuntimeState.stopFollowing or not mobHRP or not mobHRP.Parent then return end
        local targetPos = mobHRP.Position + Vector3.new(0, CONFIG.HEIGHT_OFFSET, -CONFIG.FOLLOW_DISTANCE)
        local offset = targetPos - PlayerData.hrp.Position
        local dist = offset.Magnitude
        local speed
        if dist > 60 then
            speed = 40
        elseif dist > 20 then
            speed = 50
        elseif dist > 15 then
            speed = 25
        elseif dist > 10 then
            speed = 15
        else
            speed = 5
        end
        speed = math.min(speed, CONFIG.SPEED_CAP)
        if offset.Magnitude > 2 then
            local desired = offset.Unit * speed
            local smooth = RuntimeState.lastVelocity:Lerp(desired, 0.2)
            RuntimeState.bodyVelocity.Velocity = smooth
            RuntimeState.lastVelocity = smooth
        else
            RuntimeState.bodyVelocity.Velocity = Vector3.zero
            RuntimeState.lastVelocity = Vector3.zero
        end
        Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
    end)
end

local function deactivateHover()
    Services.RunService:UnbindFromRenderStep("FollowMobStep")
    if RuntimeState.bodyVelocity then RuntimeState.bodyVelocity:Destroy() RuntimeState.bodyVelocity = nil end
    RuntimeState.lastVelocity = Vector3.zero
end

-- Helper: setCharacterNoCollide
local function setCharacterNoCollide(state)
    if not PlayerData.character then return end
    for _, part in ipairs(PlayerData.character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state and true or false
        end
    end
end

-- Always-on noclip enforcement loop
if noclipConnection then noclipConnection:Disconnect() end
noclipConnection = game:GetService("RunService").Stepped:Connect(function()
    local shouldNoclip = (not RuntimeState.stopFollowing) or RuntimeState.autoTowerDungeonEnabled or RuntimeState.autoBossEnabled or RuntimeState.bossArenaNoclip or RuntimeState.autoCaveDungeonEnabled or RuntimeState.autoIceDungeonEnabled or RuntimeState.autoPortalEnabled
    if PlayerData.character then
        for _, part in ipairs(PlayerData.character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not shouldNoclip
            end
        end
    end
    -- Debug: Print noclip status when Auto Portal is enabled
    if RuntimeState.autoPortalEnabled and tick() % 5 < 0.1 then
        print("[Noclip Debug] Auto Portal enabled, shouldNoclip:", shouldNoclip)
    end
end)

-- Extra: Force noclip in RenderStepped as well
if noclipRenderConnection then noclipRenderConnection:Disconnect() end
noclipRenderConnection = game:GetService("RunService").RenderStepped:Connect(function()
    local shouldNoclip = (not RuntimeState.stopFollowing) or RuntimeState.autoTowerDungeonEnabled or RuntimeState.autoBossEnabled or RuntimeState.bossArenaNoclip or RuntimeState.autoCaveDungeonEnabled or RuntimeState.autoIceDungeonEnabled or RuntimeState.autoPortalEnabled
    if PlayerData.character then
        for _, part in ipairs(PlayerData.character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not shouldNoclip
            end
        end
    end
end)

function startFollowing()
    setCharacterNoCollide(true)
    -- Start noclip enforcement loop
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = game:GetService("RunService").Stepped:Connect(function()
        local shouldNoclip = (not RuntimeState.stopFollowing) or RuntimeState.autoTowerDungeonEnabled or RuntimeState.autoBossEnabled or RuntimeState.bossArenaNoclip or RuntimeState.autoCaveDungeonEnabled or RuntimeState.autoIceDungeonEnabled or RuntimeState.autoPortalEnabled
        if PlayerData.character then
            for _, part in ipairs(PlayerData.character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not shouldNoclip
                end
            end
        end
    end)
    RuntimeState.stopFollowing = false
    PlayerData.humanoid.AutoRotate = false

    task.spawn(function()
        local currentMob = nil
        local mobHRP = nil
        local bodyVelocity = nil
        local lastVelocity = Vector3.zero
        while not RuntimeState.stopFollowing and not isUnloaded do
            -- Find the closest mob that matches selectedMobName and has a Healthbar
                local bestMob = nil
                local bestDist = math.huge
                local playerPos = PlayerData.hrp and PlayerData.hrp.Position or Vector3.new(0,0,0)
                for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
                if mob:IsA("Model") and mob.Name == RuntimeState.selectedMobName and mob:FindFirstChild("Healthbar") and mob:FindFirstChild("HumanoidRootPart") then
                        local hrp = mob:FindFirstChild("HumanoidRootPart")
                            local dist = (hrp.Position - playerPos).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                bestMob = mob
                        end
                    end
                end
                currentMob = bestMob
            mobHRP = currentMob and currentMob:FindFirstChild("HumanoidRootPart") or nil

            if currentMob and mobHRP then
                -- Create BodyVelocity if not exists
                if not bodyVelocity then
                    bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    bodyVelocity.P = 3000
                    bodyVelocity.Velocity = Vector3.zero
                    bodyVelocity.Parent = PlayerData.hrp
                end
                lastVelocity = bodyVelocity.Velocity
                -- Hover loop: stay at mob as long as it has Healthbar
                while not RuntimeState.stopFollowing and not isUnloaded and currentMob and currentMob.Parent and currentMob:FindFirstChild("Healthbar") do
                    -- Fetch followDist live on every frame
                    local followDist = RuntimeState.bossFollowDistance or CONFIG.FOLLOW_DISTANCE
                    local targetPos = mobHRP.Position + Vector3.new(0, followDist, -CONFIG.FOLLOW_DISTANCE)
                    local offset = targetPos - PlayerData.hrp.Position
                    local dist = offset.Magnitude
                    local speed
                    if dist > 60 then
                        speed = 80
                    elseif dist > 20 then
                        speed = 100
                    else
                        speed = CONFIG.SPEED_CAP
                    end
                    speed = math.min(speed, CONFIG.SPEED_CAP)
                    if offset.Magnitude > 2 then
                        local desired = offset.Unit * speed
                        local smooth = lastVelocity:Lerp(desired, 0.25)
                        bodyVelocity.Velocity = smooth
                        lastVelocity = smooth
                    else
                        bodyVelocity.Velocity = Vector3.zero
                        lastVelocity = Vector3.zero
                    end
                    Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
            task.wait(0.1)
        end
                -- Remove BodyVelocity when leaving mob
                if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
            else
                -- No valid mob found, remove BodyVelocity and wait a bit before retrying
                if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
                task.wait(0.2)
            end
        end
        -- On stop, clean up
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    end)
end


function stopFollowingNow()
    setCharacterNoCollide(false)
    -- Stop noclip enforcement loop
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    RuntimeState.stopFollowing = true
    PlayerData.humanoid.AutoRotate = true
    if RuntimeState.tween then RuntimeState.tween:Cancel() RuntimeState.tween = nil end
    deactivateHover()
end


task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.killAuraEnabled and PlayerData.character and PlayerData.character:FindFirstChild("HumanoidRootPart") then
            local targets = {}
            for _, mob in pairs(GameFolders.mobsFolder:GetChildren()) do
                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                if mobHRP and (mobHRP.Position - PlayerData.hrp.Position).Magnitude <= CONFIG.KILL_AURA_RANGE then
                    table.insert(targets, mob)
                    Remotes.doEffect:FireServer("SlashHit", mobHRP.Position, { mobHRP.CFrame })
                end
            end
            if #targets > 0 then
                Remotes.playerAttack:FireServer(targets)
            end
        end
        task.wait(CONFIG.KILL_AURA_DELAY)
    end
end)

-- Auto Quest logic

local Profile = require(Services.ReplicatedStorage.Systems.Profile)
local Quests = Services.ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Quests")
local CompleteQuest = Quests:WaitForChild("CompleteQuest")
local AcceptQuest = Quests:WaitForChild("AcceptQuest")

local function getActiveQuestId()
    local success, profile = pcall(function()
        return Profile:GetProfile(PlayerData.player)
    end)
    if success and profile and profile.Quests then
        return profile.Quests.Active.Value
    else
        warn("Failed to get player profile or quests: " .. tostring(profile))
        return nil
    end
end

task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.global_isEnabled_autoquest and RuntimeState.selectedQuestId then
            local activeQuestId = getActiveQuestId()
            if activeQuestId and activeQuestId ~= 0 then
                local success, err = pcall(function()
                    CompleteQuest:FireServer(activeQuestId)
                end)
                if not success then
                    warn("Failed to complete quest ID " .. tostring(activeQuestId) .. ": " .. tostring(err))
                end
                task.wait(0.5)
                local newActiveQuestId = getActiveQuestId()
                if newActiveQuestId == 0 or newActiveQuestId == nil then
                    local success, err = pcall(function()
                        AcceptQuest:FireServer(RuntimeState.selectedQuestId)
                    end)
                    if not success then
                        warn("Failed to accept quest ID " .. tostring(RuntimeState.selectedQuestId) .. ": " .. tostring(err))
                    end
                end
            else
                local success, err = pcall(function()
                    AcceptQuest:FireServer(RuntimeState.selectedQuestId)
                end)
                if not success then
                    warn("Failed to accept quest ID " .. tostring(RuntimeState.selectedQuestId) .. ": " .. tostring(err))
                end
            end
        end
        task.wait(CONFIG.QUEST_CHECK_INTERVAL)
    end
end)

-- Auto Collect loop

-- Uncommented

task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.autoCollectEnabled and CONFIG.AUTO_COLLECT_ENABLED then
            PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
            PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
            if not PlayerData.hrp then task.wait(CONFIG.CHECK_INTERVAL) continue end

            -- Process multiple drops per tick for faster collection
            for _, drop in pairs(RuntimeState.dropCache) do
                local model = drop.model
                local itemRef = drop.itemRef
                if model and model.PrimaryPart and itemRef then
                    local distance = (PlayerData.hrp.Position - model.PrimaryPart.Position).Magnitude
                    if distance <= CONFIG.COLLECT_RADIUS then
                        pcall(function()
                            Modules.drops:Pickup(PlayerData.player, itemRef)
                            if RuntimeState.autoDismantleEnabled then
                                task.wait(0.05) -- Reduced wait time for faster dismantling
                                AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
                            end
                        end)
                        -- Removed break - now collects all drops in range
                    end
                end
            end
        end
        task.wait(CONFIG.CHECK_INTERVAL)
    end
end)

-- Auto Skill Helper Functions

local function getNearestMob(maxDistance)
    local closest, minDist = nil, maxDistance or 100
    local char = PlayerData.player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    for _, mob in ipairs(Services.Workspace:WaitForChild("Mobs"):GetChildren()) do
        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
            local dist = (mob.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                closest, minDist = mob, dist
            end
        end
    end
    return closest
end

local function faceTarget(target)
    local char = PlayerData.player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not target then return end
    local dir = (target.Position - hrp.Position).Unit
    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(dir.X, 0, dir.Z))
end

local function getSkillName()
    return Modules.skillSystem:GetSkillInActiveSlot(PlayerData.player, tostring(CONFIG.SKILL_SLOT))
end

local function getCooldown(skillName)
    local data = Modules.skillSystem:GetSkillData(skillName)
    return data and data.Cooldown or CONFIG.FALLBACK_COOLDOWN
end

local function multiHitAttack(target, skillName)
    local skillData = Modules.skillSystem:GetSkillData(skillName)
    local hits = (skillData and skillData.Hits) or {}

    if #hits == 0 then
        Remotes.skillAttack:FireServer({ target }, skillName, 1)
        return
    end

    for hitIndex = 1, #hits do
        Remotes.skillAttack:FireServer({ target }, skillName, hitIndex)
        task.wait(0.05)
    end
end

-- Auto Skill loop

task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.autoSkillEnabled and PlayerData.player.Character and PlayerData.player.Character:FindFirstChild("HumanoidRootPart") then
            for _, slot in ipairs(CONFIG.SKILL_SLOTS) do
                local skill = Modules.skillSystem:GetSkillInActiveSlot(PlayerData.player, tostring(slot))
                if skill and skill ~= "" then
                    local cooldown = getCooldown(skill)
                    local last = RuntimeState.lastUsed[skill] or 0
                    if tick() - last >= cooldown then
                        local target = getNearestMob()
                        if target then
                            faceTarget(target.HumanoidRootPart)
                            pcall(function()
                                Remotes.useSkill:FireServer(skill)
                                multiHitAttack(target, skill)
                            end)
                            RuntimeState.lastUsed[skill] = tick()
                        end
                    end
                end
            end
        end
        task.wait(1) -- was Heartbeat, now 1s for less lag
    end
end)

-- Robust recursive chest finder
local function findAllChests()
    local chests = {}
    local function recurse(parent)
        for _, obj in ipairs(parent:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("RootPart") then
                table.insert(chests, obj)
            end
            recurse(obj)
        end
    end
    recurse(Services.Workspace)
    return chests
end

-- Function to open chest and claim reward
local function openAndClaimChest(chestModel)
    local root = chestModel:FindFirstChild("RootPart")
    if not root then return end

    local prompt = root:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then return end

    prompt.MaxActivationDistance = RuntimeState.autoClaimEnabled and 500 or 10

    local dist = (PlayerData.hrp.Position - root.Position).Magnitude
    if dist <= CONFIG.TRIGGER_DISTANCE then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.15)
            prompt:InputHoldEnd()
        end)

        task.delay(2.5, function()
            pcall(function()
                Remotes.chest:FireServer(chestModel)
            end)
        end)
    end
end

-- Auto Claim Chest loop
task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.autoClaimEnabled and CONFIG.AUTO_CLAIM_ENABLED then
            PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
            PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
            if not PlayerData.hrp then task.wait(CONFIG.CHECK_INTERVAL) continue end

            for _, chest in ipairs(findAllChests()) do
                openAndClaimChest(chest)
                if RuntimeState.autoDismantleEnabled then
                    task.wait(0.1)
                    AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
                end
                task.wait(0.3) -- Add this wait to reduce lag (or use 0.8 for slower)
            end
        end
        task.wait(CONFIG.CHECK_INTERVAL)
    end
end)

-- Auto Daily Quests Logic
local function claimDailyQuestsAndRewards()
    if not RuntimeState.autoDailyQuestsEnabled then return end
    for i = 1, 6 do
        local success, err = pcall(function()
            QuestRemotes.claimQuest:FireServer(unpack({i}))
        end)
    end
    for _, milestone in ipairs({1, 3, 6}) do
        local success, err = pcall(function()
            QuestRemotes.claimReward:FireServer(milestone)
        end)
    end
end

-- Trigger Auto Daily Quests on load (if enabled) and on UpdateEvent
task.spawn(function()
    if RuntimeState.autoDailyQuestsEnabled then
        task.wait(3)
        claimDailyQuestsAndRewards()
    end
end)

QuestRemotes.update.OnClientEvent:Connect(function()
    if isUnloaded then return end
    if RuntimeState.autoDailyQuestsEnabled then
        claimDailyQuestsAndRewards()
    end
end)

-- Auto Achievement Logic

task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.autoAchievementEnabled then
            for id = 1, 50 do
                local success, err = pcall(function()
                    achievementRemote:FireServer(id)
                end)
            end
        end
        task.wait(5)
    end
end)

-- Auto Dismantle Function

function AutoDismantleByMaxRarity(maxRarityIndex)
    for _, item in ipairs(PlayerData.inventory:GetChildren()) do
        local success, rarity = pcall(function()
            return Modules.items:GetRarity(item)
        end)
        if success and rarity <= maxRarityIndex then
            Remotes.dismantle:FireServer(item)
            task.wait(0.1)
        end
    end
end

-- Tower/Dungeon logic (fully restored from original code)

-- Helper: findClosestMobTD
local function findClosestMobTD()
    if not GameFolders.mobsFolder then return nil end
    local closest, minDist = nil, math.huge
    for _, mob in pairs(GameFolders.mobsFolder:GetChildren()) do
        if mob:IsA("Model") then
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            local mobHum = mob:FindFirstChild("Humanoid")
            if mobHRP and (not mobHum or mobHum.Health > 0) then
                local dist = (mobHRP.Position - PlayerData.hrp.Position).Magnitude
                if dist < minDist then
                    closest = mob
                    minDist = dist
                end
            end
        end
    end
    return closest
end

-- Helper: setCharacterNoCollide
local function setCharacterNoCollide(state)
    if not PlayerData.character then return end
    for _, part in ipairs(PlayerData.character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state and true or false
        end
    end
end

-- Auto Tower logic
-- Refactored: Kill Aura logic is now inside this loop, only attacks the hovered mob, with delay, like Auto Boss
local _lastTowerKillAura = 0

task.spawn(function()
    local currentMob = nil
    local mobHRP = nil
    while true do
        if isUnloaded then break end
        if RuntimeState.autoTowerDungeonEnabled then
            -- If we don't have a valid mob, find the closest one with HRP and Healthbar
            if not currentMob or not currentMob.Parent or not currentMob:FindFirstChild("HumanoidRootPart") or not currentMob:FindFirstChild("Healthbar") then
                currentMob = nil
                local bestMob = nil
                local bestDist = math.huge
                local playerPos = PlayerData.hrp and PlayerData.hrp.Position or Vector3.new(0,0,0)
                for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Healthbar") then
                        local hrp = mob:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local dist = (hrp.Position - playerPos).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                bestMob = mob
                            end
                        end
                    end
                end
                currentMob = bestMob
            end
            -- If we have a valid mob, always hover to its HRP
            mobHRP = currentMob and currentMob:FindFirstChild("HumanoidRootPart") or nil
            if mobHRP then
                -- Hover logic for tower (unchanged)
                if not RuntimeState.tdBodyVelocity then
                    RuntimeState.tdBodyVelocity = Instance.new("BodyVelocity")
                    RuntimeState.tdBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    RuntimeState.tdBodyVelocity.P = 3000
                    RuntimeState.tdBodyVelocity.Velocity = Vector3.zero
                    RuntimeState.tdBodyVelocity.Parent = PlayerData.hrp
                end
                local lastVelocity = Vector3.zero
                Services.RunService:BindToRenderStep("FollowMobStepTD", Enum.RenderPriority.Character.Value, function()
                    if isUnloaded or not RuntimeState.autoTowerDungeonEnabled then
                        Services.RunService:UnbindFromRenderStep("FollowMobStepTD")
                        if RuntimeState.tdBodyVelocity then RuntimeState.tdBodyVelocity:Destroy() RuntimeState.tdBodyVelocity = nil end
                        return
                    end
                    if not mobHRP or not mobHRP.Parent then return end
                    local followDist = RuntimeState.bossFollowDistance or CONFIG.FOLLOW_DISTANCE
                    local targetPos = mobHRP.Position + Vector3.new(0, followDist, -CONFIG.FOLLOW_DISTANCE)
                    local offset = targetPos - PlayerData.hrp.Position
                    local dist = offset.Magnitude
                    local speed
                    if dist > 60 then
                        speed = 80
                    elseif dist > 20 then
                        speed = 100
                    else
                        speed = CONFIG.SPEED_CAP
                    end
                    speed = math.min(speed, CONFIG.SPEED_CAP)
                    if offset.Magnitude > 0.5 then
                        local desired = offset.Unit * speed
                        local smooth = lastVelocity:Lerp(desired, 0.2)
                        RuntimeState.tdBodyVelocity.Velocity = smooth
                        lastVelocity = smooth
                    else
                        RuntimeState.tdBodyVelocity.Velocity = Vector3.zero
                        lastVelocity = Vector3.zero
                    end
                    Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
                end)
                -- Kill Aura for Auto Tower (same as Auto Boss, only attack hovered mob, with delay)
                if tick() - _lastTowerKillAura >= CONFIG.KILL_AURA_DELAY then
                    if (mobHRP.Position - PlayerData.hrp.Position).Magnitude <= CONFIG.KILL_AURA_RANGE then
                        Remotes.doEffect:FireServer("SlashHit", mobHRP.Position, { mobHRP.CFrame })
                        Remotes.playerAttack:FireServer({currentMob})
                        _lastTowerKillAura = tick()
                    end
                end
            else
                Services.RunService:UnbindFromRenderStep("FollowMobStepTD")
                if RuntimeState.tdBodyVelocity then RuntimeState.tdBodyVelocity:Destroy() RuntimeState.tdBodyVelocity = nil end
                -- Tween to portal if it exists (unchanged)
                local portal
                pcall(function()
                    portal = workspace:FindFirstChild("TowerDungeon")
                        and workspace.TowerDungeon:FindFirstChild("StaircaseRoom")
                        and workspace.TowerDungeon.StaircaseRoom:FindFirstChild("Portal")
                end)
                if portal and portal:IsA("BasePart") then
                    local target = portal.Position + Vector3.new(0, 5, 0)
                    local dist = (PlayerData.hrp.Position - target).Magnitude
                    local speed = CONFIG.BASE_SPEED
                    if dist > CONFIG.DISTANCE_THRESHOLD then speed = CONFIG.BASE_SPEED
                    elseif dist > 60 then speed = 70
                    elseif dist > 40 then speed = 90
                    else speed = 110 end
                    speed = math.clamp(speed, CONFIG.BASE_SPEED, CONFIG.SPEED_CAP)
                    if RuntimeState.tween then RuntimeState.tween:Cancel() end
                    local duration = (target - PlayerData.hrp.Position).Magnitude / speed
                    RuntimeState.tween = Services.TweenService:Create(PlayerData.hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                        CFrame = CFrame.new(target)
                    })
                    RuntimeState.tween:Play()
                    Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
                    task.wait(duration + 0.1)
                    if (PlayerData.hrp.Position - portal.Position).Magnitude <= 5 then
                        task.wait(5 + math.random() * 3)
                    end
                end
            end
        else
            Services.RunService:UnbindFromRenderStep("FollowMobStepTD")
            if RuntimeState.tdBodyVelocity then RuntimeState.tdBodyVelocity:Destroy() RuntimeState.tdBodyVelocity = nil end
            currentMob = nil
        end
        task.wait(0.05)
    end
end)

-- Noclip logic for Auto Tower

task.spawn(function()
    local wasEnabled = false
    while true do
        if isUnloaded then break end
        if RuntimeState.autoTowerDungeonEnabled then
            setCharacterNoCollide(true)
            wasEnabled = true
        elseif wasEnabled then
            setCharacterNoCollide(false)
            wasEnabled = false
        end
        task.wait(0.1)
    end
end)

-- Kill Aura for Auto Tower
local function autoDungeonKillAura()
    -- Robust checks for player and mob folder
    if not PlayerData.character or not PlayerData.character:FindFirstChild("HumanoidRootPart") then
        print("[KillAura] Player character or HRP missing!")
        return
    end
    if not GameFolders.mobsFolder then
        print("[KillAura] mobsFolder missing!")
        return
    end
    local targets = {}
    for _, mob in pairs(GameFolders.mobsFolder:GetChildren()) do
        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
        if mobHRP and (mobHRP.Position - PlayerData.hrp.Position).Magnitude <= CONFIG.KILL_AURA_RANGE then
            table.insert(targets, mob)
            Remotes.doEffect:FireServer("SlashHit", mobHRP.Position, { mobHRP.CFrame })
            print("[KillAura] Attacking mob:", mob.Name)
        end
    end
    if #targets > 0 then
        Remotes.playerAttack:FireServer(targets)
        print("[KillAura] Fired playerAttack for", #targets, "targets.")
    else
        print("[KillAura] No mobs in range.")
    end
end

-- Auto Collect for Auto Tower
local function autoDungeonCollect()
    PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
    PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
    if not PlayerData.hrp then return end
    for _, drop in pairs(RuntimeState.dropCache) do
        local model = drop.model
        local itemRef = drop.itemRef
        if model and model.PrimaryPart and itemRef then
            local distance = (PlayerData.hrp.Position - model.PrimaryPart.Position).Magnitude
            if distance <= CONFIG.COLLECT_RADIUS then
                pcall(function()
                    Modules.drops:Pickup(PlayerData.player, itemRef)
                    if RuntimeState.autoDismantleEnabled then
                        task.wait(0.1)
                        AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
                    end
                end)
                break -- Only one per tick
            end
        end
    end
end

task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.autoTowerDungeonEnabled then
            autoDungeonCollect()
        end
        task.wait(CONFIG.CHECK_INTERVAL)
    end
end)

-- Auto Skill for Auto Tower
local function autoDungeonSkill()
    if PlayerData.player.Character and PlayerData.player.Character:FindFirstChild("HumanoidRootPart") then
        for _, slot in ipairs(CONFIG.SKILL_SLOTS) do
            local skill = Modules.skillSystem:GetSkillInActiveSlot(PlayerData.player, tostring(slot))
            if skill and skill ~= "" then
                local cooldown = getCooldown(skill)
                local last = RuntimeState.lastUsed[skill] or 0
                if tick() - last >= cooldown then
                    local target = getNearestMob()
                    if target then
                        faceTarget(target.HumanoidRootPart)
                        pcall(function()
                            Remotes.useSkill:FireServer(skill)
                            multiHitAttack(target, skill)
                        end)
                        RuntimeState.lastUsed[skill] = tick()
                    end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.autoTowerDungeonEnabled then
            autoDungeonSkill()
        end
        task.wait(1)
    end
end)

-- (Repeat similar logic for autoDungeonEnabled and autoIceDungeonEnabled as in your original code)

-- Additional auto tower logic: go to portal if no mobs are found

-- In the auto tower main loop, after checking for mobs:
task.spawn(function()
    local lastMobHRP = nil
    while true do
        if isUnloaded then break end
        if RuntimeState.autoTowerDungeonEnabled then
            local mob = findClosestMobTD()
            if mob then
                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                if mobHRP then
                    -- (existing hover logic here)
                end
            else
                -- No mobs found, wait before going to Portal
                Services.RunService:UnbindFromRenderStep("FollowMobStepTD")
                if RuntimeState.tdBodyVelocity then RuntimeState.tdBodyVelocity:Destroy() RuntimeState.tdBodyVelocity = nil end
                lastMobHRP = nil
                -- Wait up to 3 seconds, checking for mobs every 0.2s
                local foundMob = false
                for i = 1, 15 do
                    task.wait(0.2)
                    if findClosestMobTD() then
                        foundMob = true
                        break
                    end
                end
                if not foundMob then
                    local portal
                    pcall(function()
                        portal = workspace:FindFirstChild("TowerDungeon")
                            and workspace.TowerDungeon:FindFirstChild("StaircaseRoom")
                            and workspace.TowerDungeon.StaircaseRoom:FindFirstChild("Portal")
                    end)
                    if portal and portal:IsA("BasePart") and PlayerData.hrp then
                        local target = portal.Position + Vector3.new(0, 5, 0)
                        local dist = (PlayerData.hrp.Position - target).Magnitude
                        local speed = CONFIG.BASE_SPEED
                        if dist > CONFIG.DISTANCE_THRESHOLD then speed = CONFIG.BASE_SPEED
                        elseif dist > 60 then speed = 70
                        elseif dist > 40 then speed = 90
                        else speed = 110 end
                        speed = math.clamp(speed, CONFIG.BASE_SPEED, CONFIG.SPEED_CAP)
                        -- Tween to portal
                        if RuntimeState.tween then RuntimeState.tween:Cancel() end
                        local duration = (target - PlayerData.hrp.Position).Magnitude / speed
                        RuntimeState.tween = Services.TweenService:Create(PlayerData.hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                            CFrame = CFrame.new(target)
                        })
                        RuntimeState.tween:Play()
                        Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
                        task.wait(duration + 0.1)
                        -- Wait 5-8 seconds if close to portal
                        if (PlayerData.hrp.Position - portal.Position).Magnitude <= 5 then
                            task.wait(5 + math.random() * 3)
                        end
                    end
                end
            end
        else
            Services.RunService:UnbindFromRenderStep("FollowMobStepTD")
            if RuntimeState.tdBodyVelocity then RuntimeState.tdBodyVelocity:Destroy() RuntimeState.tdBodyVelocity = nil end
            lastMobHRP = nil
        end
        task.wait(0.2)
    end
end)

-- Add Script Control groupbox on the left for Unload UI
local ScriptControlBox = SettingsTab:AddLeftGroupbox("Script Control")

ScriptControlBox:AddButton({
    Text = "Unload UI",
    Func = function()
        isUnloaded = true
        -- Disconnect all connections
        for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
        -- Unbind all RenderSteps
        Services.RunService:UnbindFromRenderStep("FollowMobStep")
        Services.RunService:UnbindFromRenderStep("FollowMobStepTD")
        Services.RunService:UnbindFromRenderStep("FollowMobStepIceDungeon")
        Services.RunService:UnbindFromRenderStep("FollowMobStepCaveDungeon")
        -- Destroy all custom BodyVelocity/Tween objects
        if RuntimeState.tdBodyVelocity then pcall(function() RuntimeState.tdBodyVelocity:Destroy() end) RuntimeState.tdBodyVelocity = nil end
        if RuntimeState.iceDungeonBodyVelocity then pcall(function() RuntimeState.iceDungeonBodyVelocity:Destroy() end) RuntimeState.iceDungeonBodyVelocity = nil end
        if RuntimeState.caveDungeonBodyVelocity then pcall(function() RuntimeState.caveDungeonBodyVelocity:Destroy() end) RuntimeState.caveDungeonBodyVelocity = nil end
        if RuntimeState.bossBodyVelocity then pcall(function() RuntimeState.bossBodyVelocity:Destroy() end) RuntimeState.bossBodyVelocity = nil end
        if RuntimeState.bossArenaBodyVelocity then pcall(function() RuntimeState.bossArenaBodyVelocity:Destroy() end) RuntimeState.bossArenaBodyVelocity = nil end
        if RuntimeState.tween then pcall(function() RuntimeState.tween:Cancel() end) RuntimeState.tween = nil end
        -- Restore player state
        if PlayerData.humanoid then pcall(function() PlayerData.humanoid.AutoRotate = true end) end
        setCharacterNoCollide(false)
        -- Restore workspace state (FPS boosts)
        disconnectAllFpsListeners()
        -- Destroy all UI elements
        if Library and Library.Unload then pcall(function() Library:Unload() end) end
        -- Remove global tasks/connections
        if _G.autoBossTask and typeof(_G.autoBossTask) == "RBXScriptConnection" then pcall(function() _G.autoBossTask:Disconnect() end) _G.autoBossTask = nil end
        if _G.autoBossTaskThread then pcall(function() coroutine.close(_G.autoBossTaskThread) end) _G.autoBossTaskThread = nil end
        -- Force cursor visible for 1 second, then stop
        for i = 1, 20 do
            game:GetService("UserInputService").MouseIconEnabled = true
            task.wait(0.05)
        end
        -- Optionally: print confirmation
        print("[Unload] Script and all resources cleaned up.")
    end
})


-- Track selected scale without applying immediately
local pendingDPIScale = 100

ScriptControlBox:AddSlider("DPIScaleSlider", {
    Text = "UI Scale",
    Min = 50,
    Max = 200,
    Default = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        pendingDPIScale = value
    end
})

InfoGroup:AddLabel("Script by: Seisen")
InfoGroup:AddLabel("Version: 1.0.0")
InfoGroup:AddLabel("Game: Swordburst 3")

InfoGroup:AddButton("Join Discord", function()
    setclipboard("https://discord.gg/F4sAf6z8Ph")
    print("Copied Discord Invite!")
end)

-- Apply the scale when mouse is released
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Library:SetDPIScale(pendingDPIScale)
    end
end)

-- Add Boss Dropdown and Auto Boss Toggle to Automation groupbox
local bossDropdownRef
local bossList = {}
if GameFolders.mobsFolder then
    for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
        if mob:IsA("Model") and (mob.Name:lower():find("boss") or mob.Name:lower():find("guardian") or mob.Name:lower():find("king") or mob.Name:lower():find("queen")) then
            if not table.find(bossList, mob.Name) then
                table.insert(bossList, mob.Name)
            end
        end
    end
end
MainBox:AddToggle("AutoBoss", {
    Text = "Auto Boss",
    Default = RuntimeState.autoBossEnabled or false,
    Callback = function(Value)
        RuntimeState.autoBossEnabled = Value
        if Value then
            RuntimeState.bossArenaNoclip = true
            print("[AutoBoss] Noclip enabled via AutoBoss toggle")
        else
            RuntimeState.bossArenaNoclip = false
            print("[AutoBoss] Noclip disabled via AutoBoss toggle")
        end
        saveConfig()
    end
})

-- Add Boss Arena Dropdown to Automation groupbox
local bossArenaDropdownRef
local bossArenaList = {}
local bossArenasFolder = Services.Workspace:FindFirstChild("BossArenas")
if bossArenasFolder then
    for _, arena in ipairs(bossArenasFolder:GetChildren()) do
        if arena:IsA("Model") or arena:IsA("Folder") or arena:IsA("BasePart") then
            table.insert(bossArenaList, arena.Name)
        end
    end
end
bossArenaDropdownRef = MainBox:AddDropdown("BossArenaDropdown", {
    Text = "Boss Arena",
    Values = bossArenaList,
    Default = bossArenaList[1],
    Callback = function(Value)
        RuntimeState.selectedBossArena = Value
        saveConfig()
        -- Move to the Spawn part inside the selected arena using BodyVelocity
        local bossArenasFolder = Services.Workspace:FindFirstChild("BossArenas")
        if bossArenasFolder then
            local arena = bossArenasFolder:FindFirstChild(Value)
            if arena and arena:IsA("Folder") then
                local spawnPart = arena:FindFirstChild("Spawn")
                if spawnPart and spawnPart:IsA("BasePart") then
                    -- Update character references before movement
                    PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
                    PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
                    if not PlayerData.hrp then print("[BossArena] No HRP!") return end
                    -- Clean up any previous BodyVelocity
                    if RuntimeState.bossArenaBodyVelocity then RuntimeState.bossArenaBodyVelocity:Destroy() RuntimeState.bossArenaBodyVelocity = nil end
                    RuntimeState.bossArenaNoclip = true
                    print("[BossArena] Noclip enabled")
                    local targetPos = spawnPart.Position + Vector3.new(0, 5, 0)
                    local function cleanup()
                        if RuntimeState.bossArenaBodyVelocity then RuntimeState.bossArenaBodyVelocity:Destroy() RuntimeState.bossArenaBodyVelocity = nil end
                        RuntimeState.bossArenaNoclip = false
                        print("[BossArena] Noclip disabled (cleanup)")
                    end
                    RuntimeState.bossArenaBodyVelocity = Instance.new("BodyVelocity")
                    RuntimeState.bossArenaBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    RuntimeState.bossArenaBodyVelocity.P = 3000
                    RuntimeState.bossArenaBodyVelocity.Velocity = Vector3.zero
                    RuntimeState.bossArenaBodyVelocity.Parent = PlayerData.hrp
                    local lastVelocity = Vector3.zero
                    local reached = false
                    local stepConn
                    stepConn = Services.RunService.Heartbeat:Connect(function()
                        -- Update character/HRP every frame
                        local oldChar, oldHrp = PlayerData.character, PlayerData.hrp
                        PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
                        PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
                        if PlayerData.character ~= oldChar or PlayerData.hrp ~= oldHrp then
                            print("[BossArena] Character/HRP updated", PlayerData.character, PlayerData.hrp)
                        end
                        if not PlayerData.hrp or not RuntimeState.bossArenaBodyVelocity then if stepConn then stepConn:Disconnect() end cleanup() return end
                        local offset = targetPos - PlayerData.hrp.Position
                        local dist = offset.Magnitude
                        local speed
                        if dist > 60 then
                            speed = 80
                        elseif dist > 20 then
                            speed = 100
                        else
                            speed = 110
                        end
                        speed = math.min(speed, CONFIG.SPEED_CAP)
                        if offset.Magnitude > 1 then
                            local desired = offset.Unit * speed
                            local smooth = lastVelocity:Lerp(desired, 0.25)
                            RuntimeState.bossArenaBodyVelocity.Velocity = smooth
                            lastVelocity = smooth
                        else
                            RuntimeState.bossArenaBodyVelocity.Velocity = Vector3.zero
                            lastVelocity = Vector3.zero
                            reached = true
                        end
                        if reached and cleanup then cleanup() end
                        task.wait(0.05)
                    end)
                end
            end
        end
    end
})

-- Auto Boss logic: hover to boss mob when Auto Boss is enabled and a Boss Arena is selected
_G.autoBossTask = Services.RunService.Heartbeat:Connect(function()
    if isUnloaded or not RuntimeState.autoBossEnabled or not RuntimeState.selectedBossArena then
        if RuntimeState.bossBodyVelocity then RuntimeState.bossBodyVelocity:Destroy() RuntimeState.bossBodyVelocity = nil end
        return
    end
    local bossName = RuntimeState.selectedBossArena
    local mobsFolder = GameFolders.mobsFolder
    if not mobsFolder then return end
    -- Find the closest mob whose name matches the selected boss arena
    local bestMob, bestDist = nil, math.huge
    local playerPos = PlayerData.hrp and PlayerData.hrp.Position or Vector3.new(0,0,0)
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") and mob.Name == bossName and mob:FindFirstChild("HumanoidRootPart") then
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            local dist = (hrp.Position - playerPos).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestMob = mob
            end
        end
    end
    if bestMob and bestMob:FindFirstChild("HumanoidRootPart") then
        local mobHRP = bestMob:FindFirstChild("HumanoidRootPart")
        if not RuntimeState.bossBodyVelocity then
            RuntimeState.bossBodyVelocity = Instance.new("BodyVelocity")
            RuntimeState.bossBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            RuntimeState.bossBodyVelocity.P = 3000
            RuntimeState.bossBodyVelocity.Velocity = Vector3.zero
            RuntimeState.bossBodyVelocity.Parent = PlayerData.hrp
        end
        local followDist = RuntimeState.bossFollowDistance or CONFIG.FOLLOW_DISTANCE
        local targetPos = mobHRP.Position + Vector3.new(0, followDist, -CONFIG.FOLLOW_DISTANCE)
        local offset = targetPos - PlayerData.hrp.Position
        local dist = offset.Magnitude
        local speed
        if dist > 60 then
            speed = 80
        elseif dist > 20 then
            speed = 100
        else
            speed = CONFIG.SPEED_CAP
        end
        speed = math.min(speed, CONFIG.SPEED_CAP)
        if offset.Magnitude > 2 then
            local desired = offset.Unit * speed
            local smooth = RuntimeState.bossBodyVelocity.Velocity:Lerp(desired, 0.25)
            RuntimeState.bossBodyVelocity.Velocity = smooth
        else
            RuntimeState.bossBodyVelocity.Velocity = Vector3.zero
        end
        Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
        
        -- Kill Aura for Auto Boss with delay
        if not RuntimeState._lastBossKillAura or tick() - RuntimeState._lastBossKillAura >= CONFIG.KILL_AURA_DELAY then
            if mobHRP and (mobHRP.Position - PlayerData.hrp.Position).Magnitude <= CONFIG.KILL_AURA_RANGE then
                Remotes.doEffect:FireServer("SlashHit", mobHRP.Position, { mobHRP.CFrame })
                Remotes.playerAttack:FireServer({bestMob})
                RuntimeState._lastBossKillAura = tick()
            end
        end

        -- Auto Collect for Auto Boss (copied from automation)
        if not RuntimeState._lastBossAutoCollect or tick() - RuntimeState._lastBossAutoCollect >= CONFIG.CHECK_INTERVAL then
            PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
            PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
            if PlayerData.hrp then
                for _, drop in pairs(RuntimeState.dropCache) do
                    local model = drop.model
                    local itemRef = drop.itemRef
                    if model and model.PrimaryPart and itemRef then
                        local distance = (PlayerData.hrp.Position - model.PrimaryPart.Position).Magnitude
                        if distance <= CONFIG.COLLECT_RADIUS then
                            pcall(function()
                                Modules.drops:Pickup(PlayerData.player, itemRef)
                                if RuntimeState.autoDismantleEnabled then
                                    task.wait(0.1)
                                    AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
                                end
                            end)
                            break -- Only one per tick
                        end
                    end
                end
            end
            RuntimeState._lastBossAutoCollect = tick()
        end

        -- Auto Skill for Auto Boss (copied from automation)
        if not RuntimeState._lastBossAutoSkill or tick() - RuntimeState._lastBossAutoSkill >= 1 then
            for _, slot in ipairs(CONFIG.SKILL_SLOTS) do
                local skill = Modules.skillSystem:GetSkillInActiveSlot(PlayerData.player, tostring(slot))
                if skill and skill ~= "" then
                    local cooldown = getCooldown(skill)
                    local last = RuntimeState.lastUsed[skill] or 0
                    if tick() - last >= cooldown then
                        if mobHRP then
                            faceTarget(mobHRP)
                            pcall(function()
                                Remotes.useSkill:FireServer(skill)
                                multiHitAttack(bestMob, skill)
                            end)
                            RuntimeState.lastUsed[skill] = tick()
                        end
                    end
                end
            end
            RuntimeState._lastBossAutoSkill = tick()
        end
    else
        if RuntimeState.bossBodyVelocity then RuntimeState.bossBodyVelocity:Destroy() RuntimeState.bossBodyVelocity = nil end
    end
end)

-- Remove the separate autoBossCollect and autoBossSkill loops and their function definitions

-- (move Dismantle Rarity dropdown below this slider)

-- In Auto Boss logic, use RuntimeState.bossFollowDistance or fallback to CONFIG.FOLLOW_DISTANCE
_G.autoBossTask = Services.RunService.Heartbeat:Connect(function()
    if isUnloaded or not RuntimeState.autoBossEnabled or not RuntimeState.selectedBossArena then
        if RuntimeState.bossBodyVelocity then RuntimeState.bossBodyVelocity:Destroy() RuntimeState.bossBodyVelocity = nil end
        return
    end
    local bossName = RuntimeState.selectedBossArena
    local mobsFolder = GameFolders.mobsFolder
    if not mobsFolder then return end
    -- Find the closest mob whose name matches the selected boss arena
    local bestMob, bestDist = nil, math.huge
    local playerPos = PlayerData.hrp and PlayerData.hrp.Position or Vector3.new(0,0,0)
    for _, mob in ipairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") and mob.Name == bossName and mob:FindFirstChild("HumanoidRootPart") then
            local hrp = mob:FindFirstChild("HumanoidRootPart")
            local dist = (hrp.Position - playerPos).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestMob = mob
            end
        end
    end
    if bestMob and bestMob:FindFirstChild("HumanoidRootPart") then
        local mobHRP = bestMob:FindFirstChild("HumanoidRootPart")
        if not RuntimeState.bossBodyVelocity then
            RuntimeState.bossBodyVelocity = Instance.new("BodyVelocity")
            RuntimeState.bossBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            RuntimeState.bossBodyVelocity.P = 3000
            RuntimeState.bossBodyVelocity.Velocity = Vector3.zero
            RuntimeState.bossBodyVelocity.Parent = PlayerData.hrp
        end
        local followDist = RuntimeState.bossFollowDistance or CONFIG.FOLLOW_DISTANCE
        local targetPos = mobHRP.Position + Vector3.new(0, followDist, -CONFIG.FOLLOW_DISTANCE)
        local offset = targetPos - PlayerData.hrp.Position
        local dist = offset.Magnitude
        local speed
        if dist > 60 then
            speed = 80
        elseif dist > 20 then
            speed = 100
        else
            speed = CONFIG.SPEED_CAP
        end
        speed = math.min(speed, CONFIG.SPEED_CAP)
        if offset.Magnitude > 2 then
            local desired = offset.Unit * speed
            local smooth = RuntimeState.bossBodyVelocity.Velocity:Lerp(desired, 0.25)
            RuntimeState.bossBodyVelocity.Velocity = smooth
        else
            RuntimeState.bossBodyVelocity.Velocity = Vector3.zero
        end
        Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
    else
        if RuntimeState.bossBodyVelocity then RuntimeState.bossBodyVelocity:Destroy() RuntimeState.bossBodyVelocity = nil end
    end
end)

-- Custom FPS Boost logic
local customFpsBoostConn
local originalFpsMaterials = {}

function enableCustomFpsBoost()
    -- Set all BaseParts to SmoothPlastic and destroy all Decals/Textures/SurfaceGuis
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent then
                if not originalFpsMaterials[obj] then
                    originalFpsMaterials[obj] = obj.Material
                    obj.Destroying:Connect(function() originalFpsMaterials[obj] = nil end)
                end
                pcall(function() obj.Material = Enum.Material.SmoothPlastic end)
            elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceGui") then
                pcall(function() obj:Destroy() end)
            end
        end
    end
    -- Listen for new parts/textures/decals
    if customFpsBoostConn then customFpsBoostConn:Disconnect() end
    customFpsBoostConn = Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent then
                if not originalFpsMaterials[obj] then
                    originalFpsMaterials[obj] = obj.Material
                    obj.Destroying:Connect(function() originalFpsMaterials[obj] = nil end)
                end
                pcall(function() obj.Material = Enum.Material.SmoothPlastic end)
            elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceGui") then
                pcall(function() obj:Destroy() end)
            end
        end
    end)
end

function disableCustomFpsBoost()
    -- Restore all saved materials
    for obj, mat in pairs(originalFpsMaterials) do
        if obj and typeof(obj) == "Instance" and obj:IsA("BasePart") and obj.Parent then
            pcall(function() obj.Material = mat end)
        end
    end
    originalFpsMaterials = {}
    if customFpsBoostConn then customFpsBoostConn:Disconnect() customFpsBoostConn = nil end
end

ScriptControlBox:AddToggle("CustomFPSBoostToggle", {
    Text = "Custom FPS Boost",
    Default = RuntimeState.customFpsBoostEnabled or false,
    Callback = function(Value)
        RuntimeState.customFpsBoostEnabled = Value
        if Value then
            enableCustomFpsBoost()
        else
            disableCustomFpsBoost()
        end
        saveConfig()
    end
})

-- On load, apply if enabled
if RuntimeState.customFpsBoostEnabled then
    enableCustomFpsBoost()
end

-- Max and Super Max FPS Boost logic
local maxFpsBoostConn, superMaxFpsBoostConn
local originalFpsCastShadows = {}
local originalFpsTransparency = {}
local originalFpsParticleStates = {}

function enableMaxFpsBoost()
    enableCustomFpsBoost()
    -- Disable all shadows and all particles/trails/smokes
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent then
                if originalFpsCastShadows[obj] == nil then
                    originalFpsCastShadows[obj] = obj.CastShadow
                    obj.Destroying:Connect(function() originalFpsCastShadows[obj] = nil end)
                end
                pcall(function() obj.CastShadow = false end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") then
                if originalFpsParticleStates[obj] == nil then
                    originalFpsParticleStates[obj] = obj.Enabled
                    obj.Destroying:Connect(function() originalFpsParticleStates[obj] = nil end)
                end
                pcall(function() obj.Enabled = false end)
            end
        end
    end
    if maxFpsBoostConn then maxFpsBoostConn:Disconnect() end
    maxFpsBoostConn = Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent then
                if originalFpsCastShadows[obj] == nil then
                    originalFpsCastShadows[obj] = obj.CastShadow
                    obj.Destroying:Connect(function() originalFpsCastShadows[obj] = nil end)
                end
                pcall(function() obj.CastShadow = false end)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") then
                if originalFpsParticleStates[obj] == nil then
                    originalFpsParticleStates[obj] = obj.Enabled
                    obj.Destroying:Connect(function() originalFpsParticleStates[obj] = nil end)
                end
                pcall(function() obj.Enabled = false end)
            end
        end
    end)
end

function disableMaxFpsBoost()
    disableCustomFpsBoost()
    for obj, val in pairs(originalFpsCastShadows) do
        if obj and typeof(obj) == "Instance" and obj:IsA("BasePart") and obj.Parent then
            pcall(function() obj.CastShadow = val end)
        end
    end
    originalFpsCastShadows = {}
    for obj, val in pairs(originalFpsParticleStates) do
        if obj and typeof(obj) == "Instance" and (obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")) then
            pcall(function() obj.Enabled = val end)
        end
    end
    originalFpsParticleStates = {}
    if maxFpsBoostConn then maxFpsBoostConn:Disconnect() maxFpsBoostConn = nil end
end

function enableSuperMaxFpsBoost()
    enableMaxFpsBoost()
    -- Set all BaseParts (except player's character and except whitelisted folders) to Transparency = 1, disable SurfaceGuis, BillboardGuis, Adornments
    local playerChar = PlayerData.player and PlayerData.player.Character
    local whitelist = {
        "Mobs", "QuestNPCs", "Ores", "MobPortals", "FishingSpots", "Dungeon", "Drops", "CraftingStations", "Characters", "BossRoom", "BossArenas"
    }
    local whitelistFolders = {}
    for _, name in ipairs(whitelist) do
        local folder = Services.Workspace:FindFirstChild(name)
        if folder then
            table.insert(whitelistFolders, folder)
        end
    end
    local function isWhitelisted(obj)
        for _, folder in ipairs(whitelistFolders) do
            if obj:IsDescendantOf(folder) then return true end
        end
        return false
    end
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent and (not playerChar or not obj:IsDescendantOf(playerChar)) then
                if not isWhitelisted(obj) then
                    if originalFpsTransparency[obj] == nil then
                        originalFpsTransparency[obj] = obj.Transparency
                        obj.Destroying:Connect(function() originalFpsTransparency[obj] = nil end)
                    end
                    pcall(function() obj.Transparency = 1 end)
                else
                    -- For whitelisted, enable noclip
                    pcall(function() obj.CanCollide = false end)
                end
            elseif (obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") or obj:IsA("Adornment")) and not isWhitelisted(obj) then
                pcall(function() obj.Enabled = false end)
            end
        end
    end
    if superMaxFpsBoostConn then superMaxFpsBoostConn:Disconnect() end
    superMaxFpsBoostConn = Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj and typeof(obj) == "Instance" then
            if obj:IsA("BasePart") and obj.Parent and (not playerChar or not obj:IsDescendantOf(playerChar)) then
                if not isWhitelisted(obj) then
                    if originalFpsTransparency[obj] == nil then
                        originalFpsTransparency[obj] = obj.Transparency
                        obj.Destroying:Connect(function() originalFpsTransparency[obj] = nil end)
                    end
                    pcall(function() obj.Transparency = 1 end)
                else
                    pcall(function() obj.CanCollide = false end)
                end
            elseif (obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") or obj:IsA("Adornment")) and not isWhitelisted(obj) then
                pcall(function() obj.Enabled = false end)
            end
        end
    end)
end

function disableSuperMaxFpsBoost()
    disableMaxFpsBoost()
    for obj, val in pairs(originalFpsTransparency) do
        if obj and typeof(obj) == "Instance" and obj:IsA("BasePart") and obj.Parent then
            pcall(function() obj.Transparency = val end)
        end
    end
    originalFpsTransparency = {}
    if superMaxFpsBoostConn then superMaxFpsBoostConn:Disconnect() superMaxFpsBoostConn = nil end
end

-- Only one FPS boost can be enabled at a time
local function disableAllFpsBoosts()
    disableSuperMaxFpsBoost()
    disableMaxFpsBoost()
    disableCustomFpsBoost()
end


ScriptControlBox:AddToggle("MaxFPSBoostToggle", {
    Text = "Max FPS Boost",
    Default = RuntimeState.maxFpsBoostEnabled or false,
    Callback = function(Value)
        if Value then
            RuntimeState.maxFpsBoostEnabled = true
            RuntimeState.customFpsBoostEnabled = false
            RuntimeState.superMaxFpsBoostEnabled = false
            disableCustomFpsBoost()
            disableSuperMaxFpsBoost()
            enableMaxFpsBoost()
        else
            RuntimeState.maxFpsBoostEnabled = false
            disableMaxFpsBoost()
        end
        saveConfig()
    end
})

ScriptControlBox:AddToggle("SuperMaxFPSBoostToggle", {
    Text = "Super Max FPS Boost",
    Default = RuntimeState.superMaxFpsBoostEnabled or false,
    Callback = function(Value)
        if Value then
            RuntimeState.superMaxFpsBoostEnabled = true
            RuntimeState.customFpsBoostEnabled = false
            RuntimeState.maxFpsBoostEnabled = false
            disableCustomFpsBoost()
            disableMaxFpsBoost()
            enableSuperMaxFpsBoost()
        else
            RuntimeState.superMaxFpsBoostEnabled = false
            disableSuperMaxFpsBoost()
        end
        saveConfig()
    end
})

-- On load, apply correct boost
if RuntimeState.superMaxFpsBoostEnabled then
    enableSuperMaxFpsBoost()
elseif RuntimeState.maxFpsBoostEnabled then
    enableMaxFpsBoost()
elseif RuntimeState.customFpsBoostEnabled then
    enableCustomFpsBoost()
end

function teleportToWaystone(waystoneName)
    local waystone = GameFolders.waystones:FindFirstChild(waystoneName)
    if waystone then
        Remotes.teleportWaystone:FireServer(waystone)
    end
end

function teleportToFloor(floorName)
    Remotes.teleportFloor:FireServer(floorName)
end

-- Auto Ice Dungeon
task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.autoIceDungeonEnabled then
            local DungeonRooms = workspace:FindFirstChild("DungeonRooms")
            local rooms = {}
            if DungeonRooms then
                for _, child in ipairs(DungeonRooms:GetChildren()) do
                    local num = tonumber(child.Name)
                    if num then rooms[num] = child end
                end
            end
            local function hoverToTargetIce(targetPos)
                Services.RunService:UnbindFromRenderStep("FollowMobStepIceDungeon")
                if RuntimeState.iceDungeonBodyVelocity then RuntimeState.iceDungeonBodyVelocity:Destroy() RuntimeState.iceDungeonBodyVelocity = nil end
                RuntimeState.iceDungeonBodyVelocity = Instance.new("BodyVelocity")
                RuntimeState.iceDungeonBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                RuntimeState.iceDungeonBodyVelocity.P = 3000
                RuntimeState.iceDungeonBodyVelocity.Velocity = Vector3.zero
                RuntimeState.iceDungeonBodyVelocity.Parent = PlayerData.hrp
                local lastVelocity = Vector3.zero
                Services.RunService:BindToRenderStep("FollowMobStepIceDungeon", Enum.RenderPriority.Character.Value, function()
                    if isUnloaded or not RuntimeState.autoIceDungeonEnabled then
                        Services.RunService:UnbindFromRenderStep("FollowMobStepIceDungeon")
                        if RuntimeState.iceDungeonBodyVelocity then RuntimeState.iceDungeonBodyVelocity:Destroy() RuntimeState.iceDungeonBodyVelocity = nil end
                        return
                    end
                    local offset = targetPos - PlayerData.hrp.Position
                    local dist = offset.Magnitude
                    local speed
                    if dist > 60 then
                        speed = 80
                    elseif dist > 20 then
                        speed = 100
                    else
                        speed = CONFIG.SPEED_CAP
                    end
                    speed = math.min(speed, CONFIG.SPEED_CAP)
                    if offset.Magnitude > 0.5 then
                        local desired = offset.Unit * speed
                        local smooth = lastVelocity:Lerp(desired, 0.2)
                        RuntimeState.iceDungeonBodyVelocity.Velocity = smooth
                        lastVelocity = smooth
                    else
                        RuntimeState.iceDungeonBodyVelocity.Velocity = Vector3.zero
                        lastVelocity = Vector3.zero
                    end
                    if Modules.antiCheat then
                        Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
                    end
                end)
                while (PlayerData.hrp.Position - targetPos).Magnitude > 7 and RuntimeState.autoIceDungeonEnabled and not isUnloaded do
                    task.wait(0.1)
                end
                Services.RunService:UnbindFromRenderStep("FollowMobStepIceDungeon")
                if RuntimeState.iceDungeonBodyVelocity then RuntimeState.iceDungeonBodyVelocity:Destroy() RuntimeState.iceDungeonBodyVelocity = nil end
                task.wait(0.2)
                if not RuntimeState.autoIceDungeonEnabled or isUnloaded then return false end
                return true
            end
            local function findClosestMobIce()
                local closest, minDist = nil, 9999
                local char = PlayerData.player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
                if not GameFolders.mobsFolder then return nil end
                for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Healthbar") then
                        local dist = (mob.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < minDist then
                            closest, minDist = mob, dist
                        end
                    end
                end
                return closest
            end
            local function farmMobsIce()
                local lastMobHRP = nil
                local foundAnyMob = false
                while RuntimeState.autoIceDungeonEnabled and not isUnloaded do
                    local mob = findClosestMobIce()
                    if not RuntimeState.autoIceDungeonEnabled or isUnloaded then break end
                    if mob then
                        foundAnyMob = true
                        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                        if mobHRP then
                            if lastMobHRP ~= mobHRP then
                                Services.RunService:UnbindFromRenderStep("FollowMobStepIceDungeon")
                                if RuntimeState.iceDungeonBodyVelocity then RuntimeState.iceDungeonBodyVelocity:Destroy() RuntimeState.iceDungeonBodyVelocity = nil end
                                lastMobHRP = mobHRP
                            end
                            if not RuntimeState.iceDungeonBodyVelocity then
                                RuntimeState.iceDungeonBodyVelocity = Instance.new("BodyVelocity")
                                RuntimeState.iceDungeonBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                                RuntimeState.iceDungeonBodyVelocity.P = 3000
                                RuntimeState.iceDungeonBodyVelocity.Velocity = Vector3.zero
                                RuntimeState.iceDungeonBodyVelocity.Parent = PlayerData.hrp
                            end
                            local lastVelocity = Vector3.zero
                            Services.RunService:BindToRenderStep("FollowMobStepIceDungeon", Enum.RenderPriority.Character.Value, function()
                                if isUnloaded or not RuntimeState.autoIceDungeonEnabled then
                                    Services.RunService:UnbindFromRenderStep("FollowMobStepIceDungeon")
                                    if RuntimeState.iceDungeonBodyVelocity then RuntimeState.iceDungeonBodyVelocity:Destroy() RuntimeState.iceDungeonBodyVelocity = nil end
                                    return
                                end
                                if not mobHRP or not mobHRP.Parent then return end
                                local followDist = RuntimeState.bossFollowDistance or CONFIG.FOLLOW_DISTANCE
                                local targetPos = mobHRP.Position + Vector3.new(0, followDist, -CONFIG.FOLLOW_DISTANCE)
                                local offset = targetPos - PlayerData.hrp.Position
                                local dist = offset.Magnitude
                                local speed
                                if dist > 60 then
                                    speed = 80
                                elseif dist > 20 then
                                    speed = 100
                                else
                                    speed = CONFIG.SPEED_CAP
                                end
                                speed = math.min(speed, CONFIG.SPEED_CAP)
                                if offset.Magnitude > 0.5 then
                                    local desired = offset.Unit * speed
                                    local smooth = lastVelocity:Lerp(desired, 0.2)
                                    RuntimeState.iceDungeonBodyVelocity.Velocity = smooth
                                    lastVelocity = smooth
                                else
                                    RuntimeState.iceDungeonBodyVelocity.Velocity = Vector3.zero
                                    lastVelocity = Vector3.zero
                                end
                                if Modules.antiCheat then
                                    Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
                                end
                            end)
                            local t0 = tick()
                            while tick() - t0 < 1.0 and RuntimeState.autoIceDungeonEnabled and not isUnloaded do
                                autoDungeonCollect()
                                task.wait(CONFIG.KILL_AURA_DELAY)
                                if not RuntimeState.autoIceDungeonEnabled or isUnloaded then break end
                            end
                        end
                    else
                        if foundAnyMob then
                            break
                        else
                            Services.RunService:UnbindFromRenderStep("FollowMobStepIceDungeon")
                            if RuntimeState.iceDungeonBodyVelocity then RuntimeState.iceDungeonBodyVelocity:Destroy() RuntimeState.iceDungeonBodyVelocity = nil end
                            lastMobHRP = nil
                            return false
                        end
                    end
                end
                return true
            end
            local visitedArch = {}
            local function tweenToArchIce(roomNum)
                if not RuntimeState.autoIceDungeonEnabled or isUnloaded then return end
                if visitedArch[roomNum] then return end
                local room = rooms[roomNum]
                local arch = room and room:FindFirstChild("Door") and room.Door:FindFirstChild("Arch")
                if arch and PlayerData.hrp then
                    local distToArch = (PlayerData.hrp.Position - arch.Position).Magnitude
                    if distToArch > 7 then
                        local ok = hoverToTargetIce(arch.Position)
                        if ok == false then return end
                    end
                    visitedArch[roomNum] = true
                end
            end
            local archSequence = {1, 7, 18, 25}
            for _, archNum in ipairs(archSequence) do
                if not RuntimeState.autoIceDungeonEnabled or isUnloaded then break end
                tweenToArchIce(archNum)
                while RuntimeState.autoIceDungeonEnabled and not isUnloaded do
                    local mobsFound = false
                    for i = 1, 2 do
                        if not RuntimeState.autoIceDungeonEnabled or isUnloaded then break end
                        if findClosestMobIce() then
                            mobsFound = true
                            break
                        end
                        task.wait(1)
                    end
                    if not RuntimeState.autoIceDungeonEnabled or isUnloaded then break end
                    if mobsFound then
                        farmMobsIce()
                    else
                        local searchTime = 5 + math.random() * 3
                        local foundDuringSearch = false
                        for t = 1, math.floor(searchTime) do
                            if not RuntimeState.autoIceDungeonEnabled or isUnloaded then break end
                            if findClosestMobIce() then
                                foundDuringSearch = true
                                farmMobsIce()
                                break
                            end
                            task.wait(1)
                        end
                        if not foundDuringSearch then
                            break
                        end
                    end
                end
            end
            -- After last arch, go to ExitDoor > Part
            local exitPart = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("ExitDoor") and workspace.Map.ExitDoor:FindFirstChild("Part")
            if exitPart and PlayerData.hrp then
                local distToExit = (PlayerData.hrp.Position - exitPart.Position).Magnitude
                if distToExit > 7 then
                    local function moveToExitIce()
                        local reached = false
                        while not reached and RuntimeState.autoIceDungeonEnabled and not isUnloaded do
                            local hrp = PlayerData.hrp
                            if not hrp then break end
                            local offset = exitPart.Position - hrp.Position
                            local dist = offset.Magnitude
                            local speed = (dist > 60) and 80 or (dist > 20) and 100 or 110
                            speed = math.min(speed, CONFIG.SPEED_CAP)
                            if dist > 1 then
                                local desired = offset.Unit * speed
                                hrp.Velocity = desired
                            else
                                hrp.Velocity = Vector3.zero
                                reached = true
                            end
                            task.wait(0.05)
                        end
                        if PlayerData.hrp then PlayerData.hrp.Velocity = Vector3.zero end
                    end
                    moveToExitIce()
                end
            end
            Services.RunService:UnbindFromRenderStep("FollowMobStepIceDungeon")
            if RuntimeState.iceDungeonBodyVelocity then RuntimeState.iceDungeonBodyVelocity:Destroy() RuntimeState.iceDungeonBodyVelocity = nil end
            while RuntimeState.autoIceDungeonEnabled and not isUnloaded do
                task.wait(0.5)
            end
        end
        task.wait(1)
    end
end)


-- Boss Arena movement (was Heartbeat)
local function moveToBossArena(targetPos, cleanup)
    task.spawn(function()
        local lastVelocity = Vector3.zero
        local reached = false
        while not reached do
            if isUnloaded or not RuntimeState.bossArenaBodyVelocity then if cleanup then cleanup() end break end
            local oldChar, oldHrp = PlayerData.character, PlayerData.hrp
            PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
            PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
            if PlayerData.character ~= oldChar or PlayerData.hrp ~= oldHrp then
                print("[BossArena] Character/HRP updated", PlayerData.character, PlayerData.hrp)
            end
            if not PlayerData.hrp or not RuntimeState.bossArenaBodyVelocity then if cleanup then cleanup() end break end
            local offset = targetPos - PlayerData.hrp.Position
            local dist = offset.Magnitude
            local speed
            if dist > 60 then
                speed = 80
            elseif dist > 20 then
                speed = 100
            else
                speed = 110
            end
            speed = math.min(speed, CONFIG.SPEED_CAP)
            if offset.Magnitude > 1 then
                local desired = offset.Unit * speed
                local smooth = lastVelocity:Lerp(desired, 0.25)
                RuntimeState.bossArenaBodyVelocity.Velocity = smooth
                lastVelocity = smooth
            else
                RuntimeState.bossArenaBodyVelocity.Velocity = Vector3.zero
                lastVelocity = Vector3.zero
                reached = true
            end
            if reached and cleanup then cleanup() end
            task.wait(0.05)
        end
    end)
end

-- Replace all _G.autoBossTask Heartbeat loops with a single task.spawn loop
if _G.autoBossTask and typeof(_G.autoBossTask) == "RBXScriptConnection" then _G.autoBossTask:Disconnect() end
_G.autoBossTask = nil

_G.autoBossTaskThread = nil
if _G.autoBossTaskThread then coroutine.close(_G.autoBossTaskThread) end
_G.autoBossTaskThread = task.spawn(function()
    while true do
        if isUnloaded then break end
        if not RuntimeState.autoBossEnabled or not RuntimeState.selectedBossArena then
            if RuntimeState.bossBodyVelocity then RuntimeState.bossBodyVelocity:Destroy() RuntimeState.bossBodyVelocity = nil end
            task.wait(0.1)
            continue
        end
        -- Auto Collect for Auto Boss (uses the same logic as the global automation)
        if RuntimeState.autoCollectEnabled and CONFIG.AUTO_COLLECT_ENABLED then
            PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
            PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
            if not PlayerData.hrp then
                task.wait(CONFIG.CHECK_INTERVAL)
            else
                for _, drop in pairs(RuntimeState.dropCache) do
                    local model = drop.model
                    local itemRef = drop.itemRef
                    if model and model.PrimaryPart and itemRef then
                        local distance = (PlayerData.hrp.Position - model.PrimaryPart.Position).Magnitude
                        if distance <= CONFIG.COLLECT_RADIUS then
                            pcall(function()
                                Modules.drops:Pickup(PlayerData.player, itemRef)
                                if RuntimeState.autoDismantleEnabled then
                                    task.wait(0.1)
                                    AutoDismantleByMaxRarity(RaritySystem.map[RuntimeState.selectedRarity])
                                end
                            end)
                            break -- Only one per tick
                        end
                    end
                end
            end
        end
        local bossName = RuntimeState.selectedBossArena
        local mobsFolder = GameFolders.mobsFolder
        if not mobsFolder then task.wait(0.1) continue end
        -- Find the closest mob whose name matches the selected boss arena
        local bestMob, bestDist = nil, math.huge
        local playerPos = PlayerData.hrp and PlayerData.hrp.Position or Vector3.new(0,0,0)
        for _, mob in ipairs(mobsFolder:GetChildren()) do
            if mob:IsA("Model") and mob.Name == bossName and mob:FindFirstChild("HumanoidRootPart") then
                local hrp = mob:FindFirstChild("HumanoidRootPart")
                local dist = (hrp.Position - playerPos).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestMob = mob
                end
            end
        end
        if bestMob and bestMob:FindFirstChild("HumanoidRootPart") then
            local mobHRP = bestMob:FindFirstChild("HumanoidRootPart")
            if not RuntimeState.bossBodyVelocity then
                RuntimeState.bossBodyVelocity = Instance.new("BodyVelocity")
                RuntimeState.bossBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                RuntimeState.bossBodyVelocity.P = 3000
                RuntimeState.bossBodyVelocity.Velocity = Vector3.zero
                RuntimeState.bossBodyVelocity.Parent = PlayerData.hrp
            end
            local followDist = RuntimeState.bossFollowDistance or CONFIG.FOLLOW_DISTANCE
            local targetPos = mobHRP.Position + Vector3.new(0, followDist, -CONFIG.FOLLOW_DISTANCE)
            local offset = targetPos - PlayerData.hrp.Position
            local dist = offset.Magnitude
            local speed
            if dist > 60 then
                speed = 80
            elseif dist > 20 then
                speed = 100
            else
                speed = CONFIG.SPEED_CAP
            end
            speed = math.min(speed, CONFIG.SPEED_CAP)
            if offset.Magnitude > 2 then
                local desired = offset.Unit * speed
                local smooth = RuntimeState.bossBodyVelocity.Velocity:Lerp(desired, 0.25)
                RuntimeState.bossBodyVelocity.Velocity = smooth
            else
                RuntimeState.bossBodyVelocity.Velocity = Vector3.zero
            end
            Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
            -- Kill Aura for Auto Boss with delay
            if not RuntimeState._lastBossKillAura or tick() - RuntimeState._lastBossKillAura >= CONFIG.KILL_AURA_DELAY then
                if mobHRP and (mobHRP.Position - PlayerData.hrp.Position).Magnitude <= CONFIG.KILL_AURA_RANGE then
                    Remotes.doEffect:FireServer("SlashHit", mobHRP.Position, { mobHRP.CFrame })
                    Remotes.playerAttack:FireServer({bestMob})
                    RuntimeState._lastBossKillAura = tick()
                end
            end
            -- Auto Skill for Auto Boss (copied from automation)
            if not RuntimeState._lastBossAutoSkill or tick() - RuntimeState._lastBossAutoSkill >= 1 then
                for _, slot in ipairs(CONFIG.SKILL_SLOTS) do
                    local skill = Modules.skillSystem:GetSkillInActiveSlot(PlayerData.player, tostring(slot))
                    if skill and skill ~= "" then
                        local cooldown = getCooldown(skill)
                        local last = RuntimeState.lastUsed[skill] or 0
                        if tick() - last >= cooldown then
                            if mobHRP then
                                faceTarget(mobHRP)
                                pcall(function()
                                    Remotes.useSkill:FireServer(skill)
                                    multiHitAttack(bestMob, skill)
                                end)
                                RuntimeState.lastUsed[skill] = tick()
                            end
                        end
                    end
                end
                RuntimeState._lastBossAutoSkill = tick()
            end
        else
            if RuntimeState.bossBodyVelocity then RuntimeState.bossBodyVelocity:Destroy() RuntimeState.bossBodyVelocity = nil end
        end
        task.wait(0.05)
    end
end)

-- Auto Cave Dungeon (duplicated from Auto Ice Dungeon)
local _lastCaveKillAura = 0

-- Duplicated and adapted from Auto Ice Dungeon
-- Uses archSequence = {1, 7, 20} for cave

-- Main Auto Cave Dungeon loop
task.spawn(function()
    while true do
        if isUnloaded then break end
        if RuntimeState.autoCaveDungeonEnabled then
            local DungeonRooms = workspace:FindFirstChild("DungeonRooms")
            local rooms = {}
            if DungeonRooms then
                for _, child in ipairs(DungeonRooms:GetChildren()) do
                    local num = tonumber(child.Name)
                    if num then rooms[num] = child end
                end
            end
            local function hoverToTargetCave(targetPos)
                Services.RunService:UnbindFromRenderStep("FollowMobStepCaveDungeon")
                if RuntimeState.caveDungeonBodyVelocity then RuntimeState.caveDungeonBodyVelocity:Destroy() RuntimeState.caveDungeonBodyVelocity = nil end
                RuntimeState.caveDungeonBodyVelocity = Instance.new("BodyVelocity")
                RuntimeState.caveDungeonBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                RuntimeState.caveDungeonBodyVelocity.P = 3000
                RuntimeState.caveDungeonBodyVelocity.Velocity = Vector3.zero
                RuntimeState.caveDungeonBodyVelocity.Parent = PlayerData.hrp
                local lastVelocity = Vector3.zero
                Services.RunService:BindToRenderStep("FollowMobStepCaveDungeon", Enum.RenderPriority.Character.Value, function()
                    if isUnloaded or not RuntimeState.autoCaveDungeonEnabled then
                        Services.RunService:UnbindFromRenderStep("FollowMobStepCaveDungeon")
                        if RuntimeState.caveDungeonBodyVelocity then RuntimeState.caveDungeonBodyVelocity:Destroy() RuntimeState.caveDungeonBodyVelocity = nil end
                        return
                    end
                    local offset = targetPos - PlayerData.hrp.Position
                    local dist = offset.Magnitude
                    local speed
                    if dist > 60 then
                        speed = 80
                    elseif dist > 20 then
                        speed = 100
                    else
                        speed = CONFIG.SPEED_CAP
                    end
                    speed = math.min(speed, CONFIG.SPEED_CAP)
                    if offset.Magnitude > 0.5 then
                        local desired = offset.Unit * speed
                        local smooth = lastVelocity:Lerp(desired, 0.2)
                        RuntimeState.caveDungeonBodyVelocity.Velocity = smooth
                        lastVelocity = smooth
                    else
                        RuntimeState.caveDungeonBodyVelocity.Velocity = Vector3.zero
                        lastVelocity = Vector3.zero
                    end
                    if Modules.antiCheat then
                        Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
                    end
                end)
                while (PlayerData.hrp.Position - targetPos).Magnitude > 7 and RuntimeState.autoCaveDungeonEnabled and not isUnloaded do
                    task.wait(0.1)
                end
                Services.RunService:UnbindFromRenderStep("FollowMobStepCaveDungeon")
                if RuntimeState.caveDungeonBodyVelocity then RuntimeState.caveDungeonBodyVelocity:Destroy() RuntimeState.caveDungeonBodyVelocity = nil end
                task.wait(0.2)
                if not RuntimeState.autoCaveDungeonEnabled or isUnloaded then return false end
                return true
            end
            local function findClosestMobCave()
                local closest, minDist = nil, 9999
                local char = PlayerData.player.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
                if not GameFolders.mobsFolder then return nil end
                for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
                    if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Healthbar") then
                        local dist = (mob.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < minDist then
                            closest, minDist = mob, dist
                        end
                    end
                end
                return closest
            end
            local function farmMobsCave()
                local lastMobHRP = nil
                local foundAnyMob = false
                local lastAutoCollect = 0
                local lastAutoSkill = 0
                local lastVelocity = Vector3.zero -- Persist across frames for smoothing
                while RuntimeState.autoCaveDungeonEnabled and not isUnloaded do
                    -- Always pick the closest valid mob every frame (like Auto Tower/Ice)
                    local mob = nil
                    local minDist = math.huge
                    local char = PlayerData.player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") and GameFolders.mobsFolder then
                        local playerPos = char.HumanoidRootPart.Position
                        for _, m in ipairs(GameFolders.mobsFolder:GetChildren()) do
                            if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Healthbar") then
                                local mobHum = m:FindFirstChild("Humanoid")
                                if not mobHum or mobHum.Health > 0 then
                                    local dist = (m.HumanoidRootPart.Position - playerPos).Magnitude
                                    if dist < minDist then
                                        mob = m
                                        minDist = dist
                                    end
                                end
                            end
                        end
                    end
                    if not RuntimeState.autoCaveDungeonEnabled or isUnloaded then break end
                    if mob then
                        foundAnyMob = true
                        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                        if mobHRP then
                            if lastMobHRP ~= mobHRP then
                                Services.RunService:UnbindFromRenderStep("FollowMobStepCaveDungeon")
                                if RuntimeState.caveDungeonBodyVelocity then RuntimeState.caveDungeonBodyVelocity:Destroy() RuntimeState.caveDungeonBodyVelocity = nil end
                                lastMobHRP = mobHRP
                                lastVelocity = Vector3.zero -- Reset smoothing only when mob changes
                                if not RuntimeState.caveDungeonBodyVelocity then
                                    RuntimeState.caveDungeonBodyVelocity = Instance.new("BodyVelocity")
                                    RuntimeState.caveDungeonBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                                    RuntimeState.caveDungeonBodyVelocity.P = 3000
                                    RuntimeState.caveDungeonBodyVelocity.Velocity = Vector3.zero
                                    RuntimeState.caveDungeonBodyVelocity.Parent = PlayerData.hrp
                                end
                                Services.RunService:BindToRenderStep("FollowMobStepCaveDungeon", Enum.RenderPriority.Character.Value, function()
                                    if isUnloaded or not RuntimeState.autoCaveDungeonEnabled then
                                        Services.RunService:UnbindFromRenderStep("FollowMobStepCaveDungeon")
                                        if RuntimeState.caveDungeonBodyVelocity then RuntimeState.caveDungeonBodyVelocity:Destroy() RuntimeState.caveDungeonBodyVelocity = nil end
                                        return
                                    end
                                    if not mobHRP or not mobHRP.Parent then return end
                                    local followDist = RuntimeState.bossFollowDistance or CONFIG.FOLLOW_DISTANCE
                                    local targetPos = mobHRP.Position + Vector3.new(0, followDist, -CONFIG.FOLLOW_DISTANCE)
                                    local offset = targetPos - PlayerData.hrp.Position
                                    local dist = offset.Magnitude
                                    local speed
                                    if dist > 60 then
                                        speed = 80
                                    elseif dist > 20 then
                                        speed = 100
                                    else
                                        speed = CONFIG.SPEED_CAP
                                    end
                                    speed = math.min(speed, CONFIG.SPEED_CAP)
                                    if offset.Magnitude > 0.5 then
                                        local desired = offset.Unit * speed
                                        local smooth = lastVelocity:Lerp(desired, 0.2)
                                        RuntimeState.caveDungeonBodyVelocity.Velocity = smooth
                                        lastVelocity = smooth
                                    else
                                        RuntimeState.caveDungeonBodyVelocity.Velocity = Vector3.zero
                                        lastVelocity = Vector3.zero
                                    end
                                    if Modules.antiCheat then
                                        Modules.antiCheat:UpdatePosition(PlayerData.player, PlayerData.hrp.CFrame)
                                    end
                                end)
                            end
                            -- 1:1 with Ice Dungeon: stick to this mob for up to 1 second, calling kill aura and collect every KILL_AURA_DELAY
                            local t0 = tick()
                            while tick() - t0 < 1.0 and RuntimeState.autoCaveDungeonEnabled and not isUnloaded do
                                -- Kill Aura
                                if tick() - _lastCaveKillAura >= CONFIG.KILL_AURA_DELAY then
                                    if (mobHRP.Position - PlayerData.hrp.Position).Magnitude <= CONFIG.KILL_AURA_RANGE then
                                        Remotes.doEffect:FireServer("SlashHit", mobHRP.Position, { mobHRP.CFrame })
                                        Remotes.playerAttack:FireServer({mob})
                                        _lastCaveKillAura = tick()
                                    end
                                end
                                -- Auto Collect (no dismantle)
                                if tick() - lastAutoCollect >= CONFIG.CHECK_INTERVAL then
                                    PlayerData.character = PlayerData.player.Character or PlayerData.player.CharacterAdded:Wait()
                                    PlayerData.hrp = PlayerData.character:FindFirstChild("HumanoidRootPart")
                                    if PlayerData.hrp then
                                        for _, drop in pairs(RuntimeState.dropCache) do
                                            local model = drop.model
                                            local itemRef = drop.itemRef
                                            if model and model.PrimaryPart and itemRef then
                                                local distance = (PlayerData.hrp.Position - model.PrimaryPart.Position).Magnitude
                                                if distance <= CONFIG.COLLECT_RADIUS then
                                                    pcall(function()
                                                        Modules.drops:Pickup(PlayerData.player, itemRef)
                                                    end)
                                                    break -- Only one per tick
                                                end
                                            end
                                        end
                                    end
                                    lastAutoCollect = tick()
                                end
                                -- Auto Skill
                                if tick() - lastAutoSkill >= 1 then
                                    for _, slot in ipairs(CONFIG.SKILL_SLOTS) do
                                        local skill = Modules.skillSystem:GetSkillInActiveSlot(PlayerData.player, tostring(slot))
                                        if skill and skill ~= "" then
                                            local cooldown = getCooldown(skill)
                                            local last = RuntimeState.lastUsed[skill] or 0
                                            if tick() - last >= cooldown then
                                                if mobHRP then
                                                    faceTarget(mobHRP)
                                                    pcall(function()
                                                        Remotes.useSkill:FireServer(skill)
                                                        multiHitAttack(mob, skill)
                                                    end)
                                                    RuntimeState.lastUsed[skill] = tick()
                                                end
                                            end
                                        end
                                    end
                                    lastAutoSkill = tick()
                                end
                                task.wait(CONFIG.KILL_AURA_DELAY)
                                if not RuntimeState.autoCaveDungeonEnabled or isUnloaded then break end
                            end
                        end
                    else
                        if foundAnyMob then
                            break
                        else
                            Services.RunService:UnbindFromRenderStep("FollowMobStepCaveDungeon")
                            if RuntimeState.caveDungeonBodyVelocity then RuntimeState.caveDungeonBodyVelocity:Destroy() RuntimeState.caveDungeonBodyVelocity = nil end
                            lastMobHRP = nil
                            return false
                        end
                    end
                end
                return true
            end
            local visitedArch = {}
            local function tweenToArchCave(roomNum)
                if not RuntimeState.autoCaveDungeonEnabled or isUnloaded then return end
                if visitedArch[roomNum] then return end
                local room = rooms[roomNum]
                local arch = room and room:FindFirstChild("Door") and room.Door:FindFirstChild("Arch")
                if arch and PlayerData.hrp then
                    local distToArch = (PlayerData.hrp.Position - arch.Position).Magnitude
                    if distToArch > 7 then
                        local ok = hoverToTargetCave(arch.Position)
                        if ok == false then return end
                    end
                    visitedArch[roomNum] = true
                end
            end
            local archSequence = {1, 7, 20}
            for _, archNum in ipairs(archSequence) do
                if not RuntimeState.autoCaveDungeonEnabled or isUnloaded then break end
                tweenToArchCave(archNum)
                while RuntimeState.autoCaveDungeonEnabled and not isUnloaded do
                    local mobsFound = false
                    for i = 1, 2 do
                        if not RuntimeState.autoCaveDungeonEnabled or isUnloaded then break end
                        if findClosestMobCave() then
                            mobsFound = true
                            break
                        end
                        task.wait(1)
                    end
                    if not RuntimeState.autoCaveDungeonEnabled or isUnloaded then break end
                    if mobsFound then
                        farmMobsCave()
                    else
                        local searchTime = 5 + math.random() * 3
                        local foundDuringSearch = false
                        for t = 1, math.floor(searchTime) do
                            if not RuntimeState.autoCaveDungeonEnabled or isUnloaded then break end
                            if findClosestMobCave() then
                                foundDuringSearch = true
                                farmMobsCave()
                                break
                            end
                            task.wait(1)
                        end
                        if not foundDuringSearch then
                            break
                        end
                    end
                end
            end
            -- After last arch, go to ExitDoor > Part
            local exitPart = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("ExitDoor") and workspace.Map.ExitDoor:FindFirstChild("Part")
            if exitPart and PlayerData.hrp then
                local distToExit = (PlayerData.hrp.Position - exitPart.Position).Magnitude
                if distToExit > 7 then
                    local function moveToExitCave()
                        local reached = false
                        while not reached and RuntimeState.autoCaveDungeonEnabled and not isUnloaded do
                            local hrp = PlayerData.hrp
                            if not hrp then break end
                            local offset = exitPart.Position - hrp.Position
                            local dist = offset.Magnitude
                            local speed = (dist > 60) and 80 or (dist > 20) and 100 or 110
                            speed = math.min(speed, CONFIG.SPEED_CAP)
                            if dist > 1 then
                                local desired = offset.Unit * speed
                                hrp.Velocity = desired
                            else
                                hrp.Velocity = Vector3.zero
                                reached = true
                            end
                            task.wait(0.05)
                        end
                        if PlayerData.hrp then PlayerData.hrp.Velocity = Vector3.zero end
                    end
                    moveToExitCave()
                end
            end
            Services.RunService:UnbindFromRenderStep("FollowMobStepCaveDungeon")
            if RuntimeState.caveDungeonBodyVelocity then RuntimeState.caveDungeonBodyVelocity:Destroy() RuntimeState.caveDungeonBodyVelocity = nil end
            while RuntimeState.autoCaveDungeonEnabled and not isUnloaded do
                task.wait(0.5)
            end
        end
        task.wait(1)
    end
end)

-- Add a safe stub for disconnectAllFpsListeners to prevent nil error on unload
if not disconnectAllFpsListeners then
    function disconnectAllFpsListeners()
        if customFpsBoostConn then pcall(function() customFpsBoostConn:Disconnect() end) customFpsBoostConn = nil end
        if maxFpsBoostConn then pcall(function() maxFpsBoostConn:Disconnect() end) maxFpsBoostConn = nil end
        if superMaxFpsBoostConn then pcall(function() superMaxFpsBoostConn:Disconnect() end) superMaxFpsBoostConn = nil end
    end
end

-- Helper: Find closest mob near a given part within a radius
local function findClosestPortalMob(portalPart, radius)
    local closest, minDist = nil, radius or 40
    local totalMobs = 0
    for _, mob in ipairs(GameFolders.mobsFolder:GetChildren()) do
        totalMobs = totalMobs + 1
        if mob:IsA("Model") and mob:FindFirstChild("HumanoidRootPart") then
            local dist = (mob.HumanoidRootPart.Position - portalPart.Position).Magnitude
            if dist < minDist then
                closest, minDist = mob, dist
            end
        end
    end
    print("[AutoPortal] Searched", totalMobs, "mobs, closest is", closest and closest.Name or "none", "at distance", minDist)
    return closest
end

-- Auto Portal logic

task.spawn(function()
    print("[AutoPortal] Loop started")
    while true do
        if isUnloaded then break end
        if RuntimeState.autoPortalEnabled then
            local mobPortals = workspace:FindFirstChild("MobPortals")
            local hrp = PlayerData.hrp or (PlayerData.player.Character and PlayerData.player.Character:FindFirstChild("HumanoidRootPart"))
            if mobPortals and hrp then
                local function getClosestInactivePortal()
                    local closestPortal, closestDist = nil, 500
                    for _, portal in ipairs(mobPortals:GetChildren()) do
                        if portal.Name == "SlayerPortal" and portal:IsA("Model") then
                            local portalPart = portal:FindFirstChild("Portal")
                            if portalPart and portal:GetAttribute("Active") == false then
                                local dist = (portalPart.Position - hrp.Position).Magnitude
                                if dist < closestDist then
                                    closestPortal = portal
                                    closestDist = dist
                                end
                            end
                        end
                    end
                    return closestPortal, closestDist
                end
                while RuntimeState.autoPortalEnabled and not isUnloaded do
                    local closestPortal, closestDist = getClosestInactivePortal()
                    if not closestPortal then
                        task.wait(0.5)
                        break
                    end
                    local portalPart = closestPortal:FindFirstChild("Portal")
                    if not portalPart then task.wait(0.5) break end
                    -- Move to the closest portal
                    local target = portalPart.Position + Vector3.new(0, 5, 0)
                    local lastVelocity = Vector3.zero
                    pcall(function() hrp:SetNetworkOwner(PlayerData.player) end)
                    if RuntimeState.tween then RuntimeState.tween:Cancel() RuntimeState.tween = nil end
                    if not RuntimeState.portalBodyVelocity then
                        RuntimeState.portalBodyVelocity = Instance.new("BodyVelocity")
                        RuntimeState.portalBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                        RuntimeState.portalBodyVelocity.P = 3000
                        RuntimeState.portalBodyVelocity.Velocity = Vector3.zero
                        RuntimeState.portalBodyVelocity.Parent = hrp
                    end
                    local reached = false
                    print("[AutoPortal] Moving to SlayerPortal at", target)
                    while not reached and RuntimeState.autoPortalEnabled and not isUnloaded do
                        local newClosest, newDist = getClosestInactivePortal()
                        if newClosest and newClosest ~= closestPortal then
                            print("[AutoPortal] Found a new closer portal, switching...")
                            break
                        end
                        local offset = target - hrp.Position
                        local dist = offset.Magnitude
                        local speed
                        if dist > 60 then
                            speed = 40
                        elseif dist > 20 then
                            speed = 50
                        elseif dist > 15 then
                            speed = 25
                        elseif dist > 10 then
                            speed = 15
                        else
                            speed = 5
                        end
                        speed = math.min(speed, 110)
                        if offset.Magnitude > 10 then
                            local desired = offset.Unit * speed
                            local smooth = lastVelocity:Lerp(desired, 0.2)
                            RuntimeState.portalBodyVelocity.Velocity = smooth
                            lastVelocity = smooth
                        else
                            RuntimeState.portalBodyVelocity.Velocity = Vector3.zero
                            lastVelocity = Vector3.zero
                            reached = true
                            print("[AutoPortal] Reached SlayerPortal at distance:", dist)
                        end
                        if reached then break end
                        task.wait(0.05)
                    end
                    if RuntimeState.portalBodyVelocity then RuntimeState.portalBodyVelocity:Destroy() RuntimeState.portalBodyVelocity = nil end
                    -- Try to trigger ProximityPrompt (robust)
                    if reached and closestPortal:GetAttribute("Active") == false then
                        local prompt = portalPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            print("[AutoPortal] Robustly triggering ProximityPrompt...")
                            for attempt = 1, 3 do
                                -- Move to within 2 studs of the portal part
                                local moveTries = 0
                                while (portalPart.Position - hrp.Position).Magnitude > 2 and moveTries < 40 do
                                    local offset = (portalPart.Position + Vector3.new(0, 3, 0)) - hrp.Position
                                    local dist = offset.Magnitude
                                    local speed = math.clamp(dist * 5, 10, 40)
                                    local desired = offset.Unit * speed
                                    hrp.Velocity = desired
                                    task.wait(0.05)
                                    moveTries = moveTries + 1
                                end
                                hrp.Velocity = Vector3.zero
                                if RuntimeState.portalBodyVelocity then RuntimeState.portalBodyVelocity.Velocity = Vector3.zero end
                                -- Hold the prompt for 1 second
                                print("[AutoPortal] Attempt", attempt, "to trigger ProximityPrompt...")
                                pcall(function()
                                    prompt:InputHoldBegin()
                                    task.wait(1)
                                    prompt:InputHoldEnd()
                                end)
                                task.wait(0.5)
                                if closestPortal:GetAttribute("Active") == true then
                                    print("[AutoPortal] Portal activated after attempt", attempt)
                                    break
                                end
                            end
                        end
                        -- Wait for portal to become active (or for a new closer portal to appear)
                        local waitStart = tick()
                        while closestPortal:GetAttribute("Active") == false and RuntimeState.autoPortalEnabled and not isUnloaded do
                            local newClosest, newDist = getClosestInactivePortal()
                            if newClosest and newClosest ~= closestPortal then
                                print("[AutoPortal] Found a new closer portal while waiting for activation, switching...")
                                break
                            end
                            if tick() - waitStart > 5 then break end
                            task.wait(0.2)
                        end
                        -- After activation, wait 10-12 seconds for mobs to spawn before hunting
                        if closestPortal:GetAttribute("Active") == true then
                            print("[AutoPortal] Portal is active, waiting 12 seconds for mobs to spawn...")
                            task.wait(12)
                            -- After activation, hunt and move to mobs near the portal (interruptible)
                            local portalHuntRadius = 40
                            local portalHuntTimeout = 40 -- seconds max to hunt at this portal
                            local huntStart = tick()
                            print("[AutoPortal] Starting mob hunt for", portalHuntTimeout, "seconds")
                            while tick() - huntStart < portalHuntTimeout and RuntimeState.autoPortalEnabled and not isUnloaded do
                                -- Interrupt mob hunt if a new closer portal appears
                                local newClosest, newDist = getClosestInactivePortal()
                                if newClosest and newClosest ~= closestPortal then
                                    print("[AutoPortal] Found a new closer portal during mob hunt, switching...")
                                    break
                                end
                                local mob = findClosestPortalMob(portalPart, portalHuntRadius)
                                if not mob then
                                    print("[AutoPortal] No mobs found near portal, waiting...")
                                    task.wait(1)
                                    break
                                end
                                local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                                if mobHRP then
                                    print("[AutoPortal] Found mob:", mob.Name, "at distance:", (mobHRP.Position - portalPart.Position).Magnitude)
                                    print("[AutoPortal] Moving to mob:", mob.Name)
                                    -- Move to mob using BodyVelocity
                                    local lastVelocity = Vector3.zero
                                                                    if not RuntimeState.portalBodyVelocity then
                                    RuntimeState.portalBodyVelocity = Instance.new("BodyVelocity")
                                    RuntimeState.portalBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                                    RuntimeState.portalBodyVelocity.P = 3000
                                    RuntimeState.portalBodyVelocity.Velocity = Vector3.zero
                                    RuntimeState.portalBodyVelocity.Parent = hrp
                                end
                                local reachedMob = false
                                                                            while not reachedMob and RuntimeState.autoPortalEnabled and not isUnloaded do
                                            -- Interrupt mob movement if a new closer portal appears
                                            local newClosest2, newDist2 = getClosestInactivePortal()
                                            if newClosest2 and newClosest2 ~= closestPortal then
                                                print("[AutoPortal] Found a new closer portal during mob movement, switching...")
                                                break
                                            end
                                            local offset = mobHRP.Position + Vector3.new(0, RuntimeState.bossFollowDistance or 3, 0) - hrp.Position
                                        local dist = offset.Magnitude
                                        local speed
                                        if dist > 60 then
                                            speed = 60
                                        elseif dist > 20 then
                                            speed = 50
                                        elseif dist > 15 then
                                            speed = 40
                                        elseif dist > 10 then
                                            speed = 20
                                        else
                                            speed = 5
                                        end
                                        speed = math.min(speed, 110)
                                        if offset.Magnitude > 2 then
                                            local desired = offset.Unit * speed
                                            local smooth = lastVelocity:Lerp(desired, 0.2)
                                            RuntimeState.portalBodyVelocity.Velocity = smooth
                                            lastVelocity = smooth
                                            print("[AutoPortal] Moving to mob, distance:", dist, "speed:", speed)
                                        else
                                            RuntimeState.portalBodyVelocity.Velocity = Vector3.zero
                                            lastVelocity = Vector3.zero
                                            reachedMob = true
                                            print("[AutoPortal] Reached mob:", mob.Name)
                                        end
                                        if reachedMob then break end
                                        task.wait(0.05)
                                    end
                                    if RuntimeState.portalBodyVelocity then RuntimeState.portalBodyVelocity:Destroy() RuntimeState.portalBodyVelocity = nil end
                                    -- If we broke out of the mob movement loop due to a new portal, break the mob hunt loop too
                                    local newClosest3, newDist3 = getClosestInactivePortal()
                                    if newClosest3 and newClosest3 ~= closestPortal then
                                        print("[AutoPortal] Found a new closer portal after mob movement, switching...")
                                        break
                                    end
                                end
                                task.wait(0.1)
                            end
                        end
                    end
                    -- After finishing with this portal, immediately restart and look for the next closest
                end
            else
                task.wait(0.5)
            end
        else
            if RuntimeState.portalBodyVelocity then pcall(function() RuntimeState.portalBodyVelocity:Destroy() end) RuntimeState.portalBodyVelocity = nil end
            task.wait(0.5)
        end
    end
end)


