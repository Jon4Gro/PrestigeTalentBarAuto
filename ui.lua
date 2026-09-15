-- UI.lua: Constructs the standard Interface Options panel and handles user interaction

local panel = CreateFrame("Frame", "PTBA_OptionsPanel", UIParent)
panel.name = "PrestigeTalentBarAuto"
InterfaceOptions_AddCategory(panel)

function PTBA.ToggleOptionsPanel()
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel) 
end

-- ==========================================
-- STATIC POPUPS (Input / Confirmations)
-- ==========================================

StaticPopupDialogs["PTBA_NEW_PROFILE"] = {
    text = "Enter name for new profile:",
    button1 = "Accept", button2 = "Cancel",
    hasEditBox = 1, maxLetters = 32,
    OnAccept = function(self)
        local text = self.editBox:GetText()
        if PTBA.CreateProfile(text) then
            PTBA_DB.activeProfile = text
            PTBA.RefreshUI()
        else
            print("|cFFFF0000PTBA Error:|r Invalid or duplicate profile name.")
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local text = self:GetParent().editBox:GetText()
        if PTBA.CreateProfile(text) then
            PTBA_DB.activeProfile = text
            PTBA.RefreshUI()
            self:GetParent():Hide()
        end
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

StaticPopupDialogs["PTBA_RENAME_PROFILE"] = {
    text = "Rename profile:",
    button1 = "Accept", button2 = "Cancel",
    hasEditBox = 1, maxLetters = 32,
    OnAccept = function(self)
        local text = self.editBox:GetText()
        if PTBA.RenameProfile(PTBA_DB.activeProfile, text) then
            PTBA.RefreshUI()
        else
            print("|cFFFF0000PTBA Error:|r Invalid or duplicate profile name.")
        end
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

StaticPopupDialogs["PTBA_DUPLICATE_PROFILE"] = {
    text = "Enter name for duplicated profile:",
    button1 = "Accept", button2 = "Cancel",
    hasEditBox = 1, maxLetters = 32,
    OnAccept = function(self)
        local text = self.editBox:GetText()
        if PTBA.DuplicateProfile(PTBA_DB.activeProfile, text) then
            PTBA_DB.activeProfile = text
            PTBA.RefreshUI()
        else
            print("|cFFFF0000PTBA Error:|r Invalid or duplicate profile name.")
        end
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

StaticPopupDialogs["PTBA_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete the active profile?",
    button1 = "Yes", button2 = "No",
    OnAccept = function()
        if PTBA.DeleteProfile(PTBA_DB.activeProfile) then
            PTBA.RefreshUI()
        end
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

StaticPopupDialogs["PTBA_APPLY_BARS_CONFIRM"] = {
    text = "|cFFFF0000WARNING:|r\nAre you sure you want to apply action bars from the profile?\nThis will overwrite your current action bars.",
    button1 = "Apply", button2 = "Cancel",
    OnAccept = function()
        PTBA.CheckAndApplyBars()
    end,
    timeout = 0, whileDead = 1, hideOnEscape = 1
}

-- ==========================================
-- UI WIDGETS
-- ==========================================

-- 1. Profile Selection Dropdown (with Label inline)
local profileLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
profileLabel:SetPoint("TOPLEFT", 16, -20)
profileLabel:SetText("Selected Profile:")

local profileDropdown = CreateFrame("Frame", "PTBA_ProfileDropdown", panel, "UIDropDownMenuTemplate")
-- The -15 X offset pulls the dropdown left to hide the invisible padding Blizzard adds to dropdown frames
profileDropdown:SetPoint("LEFT", profileLabel, "RIGHT", -15, -3)

local function ProfileDropdown_OnClick(self)
    UIDropDownMenu_SetSelectedValue(profileDropdown, self.value)
    PTBA_DB.activeProfile = self.value
    PTBA.RefreshUI()
end

local function ProfileDropdown_Initialize()
    if not PTBA_DB or not PTBA_DB.profiles then return end 
    local info = UIDropDownMenu_CreateInfo()
    for name, _ in pairs(PTBA_DB.profiles) do
        info.text = name
        info.value = name
        info.func = ProfileDropdown_OnClick
        info.checked = (name == PTBA_DB.activeProfile)
        UIDropDownMenu_AddButton(info)
    end
end

UIDropDownMenu_Initialize(profileDropdown, ProfileDropdown_Initialize)
UIDropDownMenu_SetWidth(profileDropdown, 180) 
UIDropDownMenu_JustifyText(profileDropdown, "LEFT")

-- 2. Profile Management Buttons (Moved below Dropdown)
local btnNew = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnNew:SetSize(60, 22)
btnNew:SetPoint("TOPLEFT", profileLabel, "BOTTOMLEFT", 0, -10)
btnNew:SetText("New")
btnNew:SetScript("OnClick", function() StaticPopup_Show("PTBA_NEW_PROFILE") end)

local btnRename = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnRename:SetSize(60, 22)
btnRename:SetPoint("LEFT", btnNew, "RIGHT", 5, 0)
btnRename:SetText("Rename")
btnRename:SetScript("OnClick", function() 
    local dialog = StaticPopup_Show("PTBA_RENAME_PROFILE")
    if dialog then dialog.editBox:SetText(PTBA_DB.activeProfile) end
end)

local btnDuplicate = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnDuplicate:SetSize(70, 22)
btnDuplicate:SetPoint("LEFT", btnRename, "RIGHT", 5, 0)
btnDuplicate:SetText("Duplicate")
btnDuplicate:SetScript("OnClick", function() 
    local dialog = StaticPopup_Show("PTBA_DUPLICATE_PROFILE")
    if dialog then dialog.editBox:SetText(PTBA_DB.activeProfile.."_Copy") end
end)

local btnDelete = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnDelete:SetSize(60, 22)
btnDelete:SetPoint("LEFT", btnDuplicate, "RIGHT", 5, 0)
btnDelete:SetText("Delete")
btnDelete:SetScript("OnClick", function() StaticPopup_Show("PTBA_DELETE_PROFILE") end)

-- Action Bar Section (Label and Buttons Inline)
local barTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
barTitle:SetPoint("TOPLEFT", btnNew, "BOTTOMLEFT", 0, -20)
barTitle:SetText("Action Bars 1-10:")

local btnSaveBars = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnSaveBars:SetSize(110, 22)
btnSaveBars:SetPoint("LEFT", barTitle, "RIGHT", 10, 0)
btnSaveBars:SetText("Save Current")
btnSaveBars:SetScript("OnClick", function() PTBA.SaveBars() end)

local btnApplyBars = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnApplyBars:SetSize(110, 22)
btnApplyBars:SetPoint("LEFT", btnSaveBars, "RIGHT", 5, 0)
btnApplyBars:SetText("Apply Profile")
btnApplyBars:SetScript("OnClick", function() StaticPopup_Show("PTBA_APPLY_BARS_CONFIRM") end)

-- Settings Section
local chkMinimap = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
chkMinimap:SetPoint("TOPLEFT", barTitle, "BOTTOMLEFT", -5, -15)
chkMinimap.text = chkMinimap:CreateFontString(nil, "ARTWORK", "GameFontNormal")
chkMinimap.text:SetPoint("LEFT", chkMinimap, "RIGHT", 0, 1)
chkMinimap.text:SetText("Show Minimap Button")
chkMinimap:SetScript("OnClick", function(self)
    PTBA_DB.minimap.hide = not self:GetChecked()
    PTBA.UpdateMinimapIcon()
end)

local chkAutoTalents = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
chkAutoTalents:SetPoint("TOPLEFT", chkMinimap, "BOTTOMLEFT", 0, -5)
chkAutoTalents.text = chkAutoTalents:CreateFontString(nil, "ARTWORK", "GameFontNormal")
chkAutoTalents.text:SetPoint("LEFT", chkAutoTalents, "RIGHT", 0, 1)
chkAutoTalents.text:SetText("Auto-Talent")
chkAutoTalents:SetScript("OnClick", function(self)
    PTBA_DB.autoTalents = self:GetChecked()
end)

local cmdTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
cmdTitle:SetPoint("TOPLEFT", chkAutoTalents, "BOTTOMLEFT", 5, -15)
cmdTitle:SetText("Reset Talent Command:")

local cmdInput = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
cmdInput:SetSize(120, 20)
cmdInput:SetPoint("LEFT", cmdTitle, "RIGHT", 10, 0)
cmdInput:SetAutoFocus(false)
cmdInput:SetScript("OnTextChanged", function(self)
    PTBA_DB.customResetCommand = self:GetText()
end)

-- Talent Section (Label and Buttons Inline)
local talentTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
talentTitle:SetPoint("TOPLEFT", cmdTitle, "BOTTOMLEFT", -5, -25)
talentTitle:SetText("Talent Management:")

local btnRecord = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnRecord:SetSize(90, 22)
btnRecord:SetPoint("LEFT", talentTitle, "RIGHT", 15, 0)
btnRecord:SetText("Start Rec")
btnRecord:SetScript("OnClick", function(self)
    PTBA_DB.isRecordingTalents = not PTBA_DB.isRecordingTalents
    if PTBA_DB.isRecordingTalents then
        self:SetText("Stop Rec")
        print("|cFF00FF00PTBA:|r Talent Recording Started. Open Talent Tree and assign points.")
    else
        self:SetText("Start Rec")
        print("|cFF00FF00PTBA:|r Talent Recording Stopped.")
    end
end)

local btnClearTalents = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnClearTalents:SetSize(90, 22)
btnClearTalents:SetPoint("LEFT", btnRecord, "RIGHT", 5, 0)
btnClearTalents:SetText("Clear Queue")
btnClearTalents:SetScript("OnClick", function()
    PTBA.ClearTalentQueue()
    PTBA.RefreshUI()
end)

-- Multiline Scrollable Talent Queue Field
local csvTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
csvTitle:SetPoint("TOPLEFT", talentTitle, "BOTTOMLEFT", 0, -15)
csvTitle:SetText("Talent Queue (Format: Tab:Index, Tab:Index):")

local scrollFrame = CreateFrame("ScrollFrame", "PTBA_CSVScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", csvTitle, "BOTTOMLEFT", 5, -10)
scrollFrame:SetSize(310, 75) -- Height fits approx 5 lines

local scrollBg = CreateFrame("Frame", nil, scrollFrame)
scrollBg:SetPoint("TOPLEFT", -4, 4)
scrollBg:SetPoint("BOTTOMRIGHT", 26, -4)
scrollBg:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
scrollBg:SetBackdropColor(0, 0, 0, 0.8)
scrollBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
scrollFrame:SetFrameLevel(scrollBg:GetFrameLevel() + 1)

local csvInput = CreateFrame("EditBox", "PTBA_CSVEditBox", scrollFrame)
csvInput:SetSize(310, 75)
csvInput:SetMultiLine(true)
csvInput:SetAutoFocus(false)
csvInput:SetFontObject("ChatFontNormal")
csvInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
scrollFrame:SetScrollChild(csvInput)

-- Explicit Save Button for the Multiline box
local btnSaveCSV = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
btnSaveCSV:SetSize(120, 22)
btnSaveCSV:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", -5, -10)
btnSaveCSV:SetText("Save Queue Text")
btnSaveCSV:SetScript("OnClick", function()
    csvInput:ClearFocus()
    PTBA.LoadTalentsFromCSV(csvInput:GetText())
    print("|cFF00FF00PTBA:|r Talent Queue loaded from text.")
end)

-- ==========================================
-- UI REFRESH LOGIC
-- ==========================================

function PTBA.RefreshUI()
    UIDropDownMenu_SetText(profileDropdown, PTBA_DB.activeProfile)
    
    local isDefault = (PTBA_DB.activeProfile == "Default")
    if isDefault then
        btnRename:Disable()
        btnDelete:Disable()
    else
        btnRename:Enable()
        btnDelete:Enable()
    end
    
    chkMinimap:SetChecked(not PTBA_DB.minimap.hide)
    chkAutoTalents:SetChecked(PTBA_DB.autoTalents)
    cmdInput:SetText(PTBA_DB.customResetCommand or ".respec")
    
    if PTBA_DB.isRecordingTalents then
        btnRecord:SetText("Stop Rec")
    else
        btnRecord:SetText("Start Rec")
    end
    
    PTBA.UpdateTalentCSV()
    local profileData = PTBA.GetActiveProfileData()
    if profileData then
        local hadFocus = csvInput:HasFocus()
        if hadFocus then csvInput:ClearFocus() end
        csvInput:SetText(profileData.talentCSV or "")
        if hadFocus then csvInput:SetFocus() end
    end
end

panel:SetScript("OnShow", function()
    PTBA.RefreshUI()
end)
