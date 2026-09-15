-- Bar.lua: Handles saving and dynamically restoring action bars (spells, macros, items, companions)

local spellCache = {}
local BOOK_SPELL = BOOKTYPE_SPELL or "spell"

-- Helper: Builds the ABS-style cache of the entire spellbook
local function BuildSpellCache()
    table.wipe(spellCache)
    
    local numTabs = GetNumSpellTabs()
    for book = 1, numTabs do
        local _, _, offset, numSpells = GetSpellTabInfo(book)
        if offset and numSpells then
            for i = 1, numSpells do
                local index = offset + i
                local spell, rank = GetSpellName(index, BOOK_SPELL)
                
                if spell then
                    -- Because it scans forward, spellCache[spell] naturally overwrites itself with the highest rank index
                    spellCache[spell] = index
                    
                    if rank and rank ~= "" then
                        spellCache[spell .. rank] = index
                    end
                end
            end
        end
    end
end

-- Helper: Finds a companion (mount/pet) index based on its Spell ID
local function FindCompanionIndex(subType, targetSpellID)
    local count = GetNumCompanions(subType)
    for i = 1, count do
        local _, _, creatureSpellID = GetCompanionInfo(subType, i)
        if creatureSpellID == targetSpellID then
            return i
        end
    end
    return nil
end

-- Helper: Verifies a macro exists by name, or recreates it if missing
local function EnsureMacroExists(name, icon, body)
    local macroID = GetMacroIndexByName(name)
    if macroID > 0 then return macroID end 
    
    macroID = CreateMacro(name, icon, body, 1)
    if macroID == 0 then macroID = CreateMacro(name, icon, body, nil) end
    if macroID == 0 then
        print("|cFFFF0000PTBA Error:|r Macro space is completely full. Could not restore macro: " .. tostring(name))
    end
    
    return macroID
end

-- ==========================================
-- MAIN FUNCTIONS
-- ==========================================

function PTBA.SaveBars()
    local profile = PTBA.GetActiveProfileData()
    if not profile then return end
    
    profile.actionBars = {}

    for slot = 1, 120 do
        local aType, id, subType = GetActionInfo(slot)
        if aType then
            local data = { type = aType }
            local valid = false
            
            if aType == "spell" then
                -- CRITICAL WOTLK API FIX: 'id' is a spellbook index, not a global spell ID.
                local name, rankStr = GetSpellName(id, BOOK_SPELL)
                if name then
                    data.name = name
                    data.rankStr = rankStr or ""
                    valid = true
                end
                
            elseif aType == "macro" then
                local name, iconTexture, body = GetMacroInfo(id)
                if name then
                    data.name = name
                    data.icon = iconTexture
                    data.body = body
                    valid = true
                end
                
            elseif aType == "item" then
                data.id = id
                data.name = GetItemInfo(id) 
                valid = true
                
            elseif aType == "companion" then
                local _, _, creatureSpellID = GetCompanionInfo(subType, id)
                if creatureSpellID then
                    data.subType = subType
                    data.spellID = creatureSpellID
                    valid = true
                end
                
            elseif aType == "equipmentset" then
                if id then
                    data.id = id
                    valid = true
                end
            end
            
            if valid then
                profile.actionBars[slot] = data
            end
        end
    end
    
    print("|cFF00FF00PTBA:|r Action bars saved to profile |cFFFFFF00" .. PTBA_DB.activeProfile .. "|r")
end

function PTBA.CheckAndApplyBars()
    if InCombatLockdown() then return end
    
    local profile = PTBA.GetActiveProfileData()
    if not profile or not profile.actionBars then return end

    BuildSpellCache()
    ClearCursor()
    
    -- Mute game sounds to prevent click spam noise
    local soundToggle = GetCVar("Sound_EnableAllSound")
    SetCVar("Sound_EnableAllSound", 0)

    for slot = 1, 120 do
        local saved = profile.actionBars[slot]
        if saved then
            
            -- Force clear the slot first to bypass Action Bar Locks
            local currentType, currentId = GetActionInfo(slot)
            if currentType or currentId then
                PickupAction(slot)
                ClearCursor()
            end
            
            if saved.type == "spell" and saved.name then
                -- Target the highest known rank in the cache
                local targetIndex = spellCache[saved.name]
                
                if targetIndex then
                    PickupSpell(targetIndex, BOOK_SPELL)
                    if GetCursorInfo() == "spell" then 
                        PlaceAction(slot) 
                    end
                    ClearCursor()
                end
                
            elseif saved.type == "macro" and saved.name then
                local macroID = EnsureMacroExists(saved.name, saved.icon, saved.body)
                if macroID and macroID > 0 then
                    PickupMacro(macroID)
                    if GetCursorInfo() == "macro" then 
                        PlaceAction(slot) 
                    end
                    ClearCursor()
                end
                
            elseif saved.type == "item" and saved.id then
                if GetItemCount(saved.id) > 0 then
                    PickupItem(saved.id)
                    if GetCursorInfo() == "item" then 
                        PlaceAction(slot) 
                    end
                    ClearCursor()
                end
                
            elseif saved.type == "companion" and saved.spellID then
                local cIndex = FindCompanionIndex(saved.subType, saved.spellID)
                if cIndex then
                    PickupCompanion(saved.subType, cIndex)
                    if GetCursorInfo() == "companion" then 
                        PlaceAction(slot) 
                    end
                    ClearCursor()
                end
                
            elseif saved.type == "equipmentset" and saved.id then
                PickupEquipmentSetByName(saved.id)
                if GetCursorInfo() == "equipmentset" then 
                        PlaceAction(slot) 
                end
                ClearCursor()
            end
        end
    end

    SetCVar("Sound_EnableAllSound", soundToggle)
    print("|cFF00FF00PTBA:|r Profile action bars applied successfully.")
end