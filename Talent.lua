-- Talent.lua: Handles recording talent sequences, CSV parsing, and auto-learning

-- Setup the Respec Prompt Window
StaticPopupDialogs["PTBA_RESPEC_PROMPT"] = {
    text = "|cFF00FF00PrestigeTalentBarAuto:|r\nYour current talents do not match the saved Profile Queue.\nYou need a Respec to continue the auto-queue.\n\nExecute reset command?",
    button1 = "Yes (Reset)",
    button2 = "Ignore",
    OnAccept = function()
        -- Safely simulate typing the command into the chat box to support server emulator commands (.respec, etc)
        local editBox = ChatEdit_ChooseBoxForSend()
        editBox:SetText(PTBA_DB.customResetCommand)
        ChatEdit_SendText(editBox)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3, -- Prevents UI taint with other addons
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
            table.insert(newTalents, { tab = tonumber(tab), index = tonumber(index) })
        end
    end
    
    profile.talents = newTalents
    profile.talentCSV = csvString
end

-- ==========================================
-- RECORDING MODE
-- ==========================================

function PTBA.RecordTalent(tab, index, points)
    local profile = PTBA.GetActiveProfileData()
    if not profile then return end
    
    local name = GetTalentInfo(tab, index)
    if not name then name = "Unknown Talent" end
    
    if points > 0 then
        for i = 1, points do
            table.insert(profile.talents, { tab = tab, index = index })
        end
        print(string.format("|cFF00FF00PTBA:|r Recorded: |cFFFFFF00%s|r (Tab: %d, Index: %d)", name, tab, index))
    elseif points < 0 then
        local toRemove = math.abs(points)
        for i = #profile.talents, 1, -1 do
            if profile.talents[i].tab == tab and profile.talents[i].index == index then
                table.remove(profile.talents, i)
                toRemove = toRemove - 1
                if toRemove == 0 then break end
            end
        end
        print(string.format("|cFFFF0000PTBA:|r Removed: |cFFFFFF00%s|r (Tab: %d, Index: %d)", name, tab, index))
    end
    
    PTBA.UpdateTalentCSV()
    
    -- If the user happens to have the UI open while clicking, refresh it live
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