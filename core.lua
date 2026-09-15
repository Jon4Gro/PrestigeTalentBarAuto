-- Create a global namespace for our addon files to share functions and data
PTBA = {}

-- Default Settings
local defaultDB = {
    enabled = false, -- Default to off until user toggles it
    minimap = { hide = false, minimapPos = 45 },
    customResetCommand = ".respec", -- Default command, editable in UI
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
frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Triggered when leaving combat

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "PrestigeTalentBarAuto" then
        -- Initialize Database
        if not PTBA_DB then
            PTBA_DB = defaultDB
        else
            -- Ensure any missing keys from updates are added
            for k, v in pairs(defaultDB) do
                if PTBA_DB[k] == nil then
                    PTBA_DB[k] = v
                end
            end
        end
        
        -- Initialize Minimap Button State
        if PTBA.UpdateMinimapIcon then
            PTBA.UpdateMinimapIcon()
        end
        
        print("|cFF00FF00PrestigeTalentBarAuto|r loaded. Active Profile: |cFFFFFF00" .. PTBA_DB.activeProfile .. "|r")
        self:UnregisterEvent("ADDON_LOADED")
        
    elseif event == "PLAYER_LEVEL_UP" then
        if not PTBA_DB.enabled then return end
        local newLevel = arg1
        
        -- Trigger our checks
        if PTBA.CheckAndApplyBars then PTBA.CheckAndApplyBars() end
        if PTBA.CheckAndApplyTalents then PTBA.CheckAndApplyTalents(newLevel) end
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not PTBA_DB.enabled then return end
        
        -- Player left combat, check if we had pending actions
        if PTBA.CheckAndApplyBars then PTBA.CheckAndApplyBars() end
        if PTBA.CheckAndApplyTalents then PTBA.CheckAndApplyTalents(UnitLevel("player")) end
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
    if PTBA_DB.activeProfile == name then
        PTBA_DB.activeProfile = "Default"
    end
    return true
end

function PTBA.DuplicateProfile(sourceName, newName)
    if not PTBA_DB.profiles[sourceName] or PTBA_DB.profiles[newName] or newName == "" then return false end
    
    -- Deep copy the table so they don't share memory references
    local copy = {}
    for k, v in pairs(PTBA_DB.profiles[sourceName]) do
        if type(v) == "table" then
            copy[k] = {}
            for subK, subV in pairs(v) do
                copy[k][subK] = subV
            end
        else
            copy[k] = v
        end
    end
    
    PTBA_DB.profiles[newName] = copy
    return true
end

function PTBA.RenameProfile(oldName, newName)
    if oldName == "Default" or not PTBA_DB.profiles[oldName] or PTBA_DB.profiles[newName] or newName == "" then return false end
    
    -- Transfer data to new key
    PTBA_DB.profiles[newName] = PTBA_DB.profiles[oldName]
    PTBA_DB.profiles[oldName] = nil
    
    -- If this was the active profile, update the active pointer
    if PTBA_DB.activeProfile == oldName then
        PTBA_DB.activeProfile = newName
    end
    return true
end

function PTBA.GetActiveProfileData()
    return PTBA_DB.profiles[PTBA_DB.activeProfile]
end