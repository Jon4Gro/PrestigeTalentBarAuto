-- Talent.lua: Handles recording talent sequences, CSV parsing, and auto-learning

StaticPopupDialogs["PTBA_RESPEC_PROMPT"] = {
    text = "|cFF00FF00PrestigeTalentBarAuto:|r\nYour current talents do not match the saved Profile Queue.\nYou need a Respec to continue the auto-queue.\n\nExecute reset command?",
    button1 = "Yes (Reset)",
    button2 = "Ignore",
    OnAccept = function()
        local editBox = ChatEdit_ChooseBoxForSend()
        editBox:SetText(PTBA_DB.customResetCommand)
        ChatEdit_SendText(editBox)
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

-- ==========================================
-- CSV & DATA MANAGEMENT
-- ==========================================

function PTBA.UpdateTalentCSV()
    local profile = PTBA.GetActiveProfileData()
    if not profile or not profile.talents then return end
    
    local parts = {}
    for _, step in ipairs(profile.talents) do
        table.insert(parts, step.tab .. ":" .. step.index)
    end
    profile.talentCSV = table.concat(parts, ", ")
end

function PTBA.LoadTalentsFromCSV(csvString)
    local profile = PTBA.GetActiveProfileData()
    if not profile then return end
    
    local newTalents = {}
    for pair in string.gmatch(csvString, "([^,]+)") do
        pair = pair:match("^%s*(.-)%s*$")
        local tab, index = string.match(pair, "^(%d+):(%d+)$")
        
        if tab and index then
            local t, i = tonumber(tab), tonumber(index)
            local name = GetTalentInfo(t, i) or "Unknown"
            
            -- WotLK API Fix: Catches both |Htalent:ID|h and |Hspell:ID|h
            local link = GetTalentLink(t, i)
            local spellID = 0
            if link then spellID = tonumber(link:match("|H%a+:(%d+)")) or 0 end
            
            table.insert(newTalents, { tab = t, index = i, spellID = spellID, name = name })
        end
    end
    
    profile.talents = newTalents
    profile.talentCSV = csvString
end

-- ==========================================
-- RECORDING MODE (With Shadow Tracking to prevent Over-Clicking)
-- ==========================================

local shadowRanks = {}

local function InitShadowRanks()
    shadowRanks = {}
    for t = 1, 3 do
        shadowRanks[t] = {}
        for idx = 1, GetNumTalents(t) do
            local _, _, _, _, currRank = GetTalentInfo(t, idx)
            shadowRanks[t][idx] = currRank
        end
    end
    ResetGroupPreviewTalentPoints()
end

function PTBA.SetRecording(state)
    PTBA_DB.isRecordingTalents = state
    if state then
        InitShadowRanks()
        print("|cFF00FF00PTBA:|r Talent Recording Started. Open Talent Tree and assign points.")
    else
        print("|cFF00FF00PTBA:|r Talent Recording Stopped.")
    end
end

function PTBA.RecordTalent(tab, index, points)
    local profile = PTBA.GetActiveProfileData()
    if not profile then return end
    
    -- Ensure shadowRanks exists if UI was reloaded mid-recording
    if not shadowRanks[1] then InitShadowRanks() end

    local name, _, _, _, currRank, maxRank = GetTalentInfo(tab, index)
    if not name then name = "Unknown Talent" end
    
    -- WotLK API Fix: Catch the ID dynamically regardless of hyperlink type
    local link = GetTalentLink(tab, index)
    local spellID = 0
    if link then spellID = tonumber(link:match("|H%a+:(%d+)")) or 0 end
    
    local currentShadow = shadowRanks[tab][index] or 0

    if points > 0 then
        -- Math prevents you from clicking more times than the maxRank allows
        local spaceLeft = maxRank - currentShadow
        local toAdd = math.min(points, spaceLeft)
        
        if toAdd <= 0 then return end -- Overclick blocked
        
        for i = 1, toAdd do
            shadowRanks[tab][index] = shadowRanks[tab][index] + 1
            table.insert(profile.talents, { tab = tab, index = index, spellID = spellID, name = name })
        end
        print(string.format("|cFF00FF00PTBA:|r Recorded: |cFFFFFF00%s|r (ID: %d)", name, spellID))
        
    elseif points < 0 then
        -- Math prevents you from removing more points than you've added in this session
        local toRemove = math.abs(points)
        local addedInPreview = currentShadow - currRank
        toRemove = math.min(toRemove, addedInPreview)
        
        if toRemove <= 0 then return end
        
        for i = 1, toRemove do
            shadowRanks[tab][index] = shadowRanks[tab][index] - 1
            for j = #profile.talents, 1, -1 do
                if profile.talents[j].tab == tab and profile.talents[j].index == index then
                    table.remove(profile.talents, j)
                    break
                end
            end
        end
        print(string.format("|cFFFF0000PTBA:|r Removed: |cFFFFFF00%s|r", name))
    end
    
    PTBA.UpdateTalentCSV()
    if PTBA_OptionsPanel and PTBA_OptionsPanel:IsVisible() and PTBA.RefreshUI then
        PTBA.RefreshUI()
    end
end

hooksecurefunc("AddPreviewTalentPoints", function(tab, index, points)
    if not PTBA_DB.isRecordingTalents then return end
    PTBA.RecordTalent(tab, index, points)
end)

hooksecurefunc("LearnTalent", function(tab, index)
    if not PTBA_DB.isRecordingTalents then return end
    PTBA.RecordTalent(tab, index, 1)
end)

function PTBA.ClearTalentQueue()
    local profile = PTBA.GetActiveProfileData()
    if profile then
        profile.talents = {}
        profile.talentCSV = ""
        if PTBA_DB.isRecordingTalents then InitShadowRanks() end
        print("|cFF00FF00PTBA:|r Talent queue cleared for profile: " .. PTBA_DB.activeProfile)
    end
end

-- ==========================================
-- AUTO APPLY LOGIC
-- ==========================================

function PTBA.CheckAndApplyTalents(currentLevel)
    if not PTBA_DB.autoTalents then return end
    if currentLevel < 10 then return end
    if PTBA_DB.isRecordingTalents then return end 
    
    local profile = PTBA.GetActiveProfileData()
    if not profile or not profile.talents or #profile.talents == 0 then return end
    
    local unspent = UnitCharacterPoints("player")
    local remainingSpent = 0
    local current = {}
    
    for t = 1, 3 do
        current[t] = {}
        for idx = 1, GetNumTalents(t) do
            local _, _, _, _, rank = GetTalentInfo(t, idx)
            current[t][idx] = rank
            remainingSpent = remainingSpent + rank
        end
    end
    
    local totalAvailablePointsToProcess = remainingSpent + unspent
    local pointsProcessed = 0
    local indexInQueue = 1
    local mismatch = false
    local addedPreview = false
    
    ResetGroupPreviewTalentPoints()
    
    while pointsProcessed < totalAvailablePointsToProcess and indexInQueue <= #profile.talents do
        local step = profile.talents[indexInQueue]
        local t = step.tab
        local idx = step.index
        
        -- Validation Check: Ensures server hasn't changed the talent layout
        local currentName = GetTalentInfo(t, idx)
        if step.name and step.name ~= "Unknown" and currentName ~= step.name then
            print(string.format("|cFFFF0000PTBA Error:|r Talent mismatch! Expected '%s', found '%s'. Resetting to protect build.", step.name, currentName or "Nil"))
            mismatch = true
            break
        end
        
        if current[t][idx] > 0 then
            current[t][idx] = current[t][idx] - 1
            remainingSpent = remainingSpent - 1
        else
            if unspent > 0 then
                AddPreviewTalentPoints(t, idx, 1)
                unspent = unspent - 1
                addedPreview = true
            else
                mismatch = true
                break
            end
        end
        pointsProcessed = pointsProcessed + 1
        indexInQueue = indexInQueue + 1
    end
    
    if remainingSpent > 0 then mismatch = true end
    if addedPreview then LearnPreviewTalents() end
    if mismatch and not StaticPopup_Visible("PTBA_RESPEC_PROMPT") then
        StaticPopup_Show("PTBA_RESPEC_PROMPT")
    end
end