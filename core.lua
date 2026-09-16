-- Create a global namespace for our addon files to share functions and data
PTBA = {}

-- Default Settings
local defaultDB = {
    enabled = false, 
    minimap = { hide = false, minimapPos = 45 },
    customResetCommand = ".respec", 
    autoTalents = true,
    profiles = {
        ["Default"] = {
            actionBars = {},
            talents = {}, 
            talentCSV = ""
        }
    },
    activeProfile = "Default",
    isRecordingTalents = false
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

-- Delay Frame: Waits 2 seconds after Talents apply before applying Action Bars
local delayFrame = CreateFrame("Frame")
delayFrame:Hide()
local delayTimer = 0
delayFrame:SetScript("OnUpdate", function(self, elapsed)
    delayTimer = delayTimer + elapsed
    if delayTimer >= 2.0 then
        self:Hide()
        if not InCombatLockdown() and PTBA.CheckAndApplyBars then
            PTBA.CheckAndApplyBars()
        end
    end
end)

function PTBA.ProcessLevelUp()
    if InCombatLockdown() then return end
    if not PTBA.pendingLevelUp then return end
    
    PTBA.pendingLevelUp = false
    
    -- 1. Apply Talents immediately
    if PTBA.CheckAndApplyTalents then
        PTBA.CheckAndApplyTalents(UnitLevel("player"))
    end
    
    -- 2. Start the 2-second timer to apply Action Bars
    delayTimer = 0
    delayFrame:Show()
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "PrestigeTalentBarAuto" then
        if not PTBA_DB then
            PTBA_DB = defaultDB
        else
            for k, v in pairs(defaultDB) do
                if PTBA_DB[k] == nil then PTBA_DB[k] = v end
            end
        end
        
        if PTBA.UpdateMinimapIcon then PTBA.UpdateMinimapIcon() end
        
        print("|cFF00FF00PrestigeTalentBarAuto|r loaded. Active Profile: |cFFFFFF00" .. PTBA_DB.activeProfile .. "|r")
        self:UnregisterEvent("ADDON_LOADED")
        
    elseif event == "PLAYER_LEVEL_UP" then
        if not PTBA_DB.enabled then return end
        
        -- Flag that we leveled up, and attempt to process it
        PTBA.pendingLevelUp = true
        PTBA.ProcessLevelUp()
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not PTBA_DB.enabled then return end
        
        -- Only triggers if we leveled up DURING combat and had to wait
        if PTBA.pendingLevelUp then
            PTBA.ProcessLevelUp()
        end
    end
end)

-- ==========================================
-- PROFILE MANAGEMENT FUNCTIONS
-- ==========================================

function PTBA.CreateProfile(name)
    if not name or name == "" or PTBA_DB.profiles[name] then return false end
    PTBA_DB.profiles[name] = { actionBars = {}, talents = {}, talentCSV = "" }
    return true
end

function PTBA.DeleteProfile(name)
    if name == "Default" or not PTBA_DB.profiles[name] then return false end
    PTBA_DB.profiles[name] = nil
    if PTBA_DB.activeProfile == name then PTBA_DB.activeProfile = "Default" end
    return true
end

function PTBA.DuplicateProfile(sourceName, newName)
    if not PTBA_DB.profiles[sourceName] or PTBA_DB.profiles[newName] or newName == "" then return false end
    local copy = {}
    for k, v in pairs(PTBA_DB.profiles[sourceName]) do
        if type(v) == "table" then
            copy[k] = {}
            for subK, subV in pairs(v) do copy[k][subK] = subV end
        else
            copy[k] = v
        end
    end
    PTBA_DB.profiles[newName] = copy
    return true
end

function PTBA.RenameProfile(oldName, newName)
    if oldName == "Default" or not PTBA_DB.profiles[oldName] or PTBA_DB.profiles[newName] or newName == "" then return false end
    PTBA_DB.profiles[newName] = PTBA_DB.profiles[oldName]
    PTBA_DB.profiles[oldName] = nil
    if PTBA_DB.activeProfile == oldName then PTBA_DB.activeProfile = newName end
    return true
end

function PTBA.GetActiveProfileData()
    return PTBA_DB.profiles[PTBA_DB.activeProfile]
end

-- ==========================================
-- SLASH COMMANDS
-- ==========================================

SLASH_PTBA1 = "/ptba"
SlashCmdList["PTBA"] = function(msg)
    msg = string.lower(msg or "")
    local cmd = string.match(msg, "^(%S+)") or ""
    
    if cmd == "save" then
        if PTBA.SaveBars then PTBA.SaveBars() end
    elseif cmd == "apply" or cmd == "restore" then
        if PTBA.CheckAndApplyBars then PTBA.CheckAndApplyBars() end
    elseif cmd == "talents" then
        if PTBA.CheckAndApplyTalents then PTBA.CheckAndApplyTalents(UnitLevel("player")) end
    else
        if PTBA.ToggleOptionsPanel then PTBA.ToggleOptionsPanel() end
        print("|cFF00FF00PrestigeTalentBarAuto Commands:|r")
        print("  |cFFFFFF00/ptba save|r - Saves current bars to the active profile.")
        print("  |cFFFFFF00/ptba apply|r - Applies bars from the active profile.")
        print("  |cFFFFFF00/ptba talents|r - Manually triggers the talent auto-queue.")
        print("  |cFFFFFF00/ptba|r - Opens the Options Panel.")
    end
end