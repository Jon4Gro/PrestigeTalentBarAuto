local minimapButton = CreateFrame("Button", "PTBAMinimapButton", Minimap)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetWidth(32)
minimapButton:SetHeight(32)
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:RegisterForDrag("LeftButton")
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local iconTexture = minimapButton:CreateTexture(nil, "BACKGROUND")
iconTexture:SetWidth(21)
iconTexture:SetHeight(21)
iconTexture:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapButton.icon = iconTexture

local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetWidth(56)
border:SetHeight(56)
border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)

-- Function to update the icon based on enabled state
function PTBA.UpdateMinimapIcon()
    if PTBA_DB.enabled then
        minimapButton.icon:SetTexture("Interface\\Icons\\achievement_boss_kingymiron_03")
    else
        minimapButton.icon:SetTexture("Interface\\Icons\\achievement_boss_kingymiron_01")
    end
    
    if PTBA_DB.minimap.hide then
        minimapButton:Hide()
    else
        minimapButton:Show()
    end
end

-- Math to keep the button on the edge of the minimap
local function UpdatePosition()
    local radius = 80 -- Standard minimap radius
    local angle = math.rad(PTBA_DB.minimap.minimapPos or 45)
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    
    -- Round minimap calculation (standard 3.3.5a UI)
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

minimapButton:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", function(self)
        local xpos, ypos = GetCursorPosition()
        local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()

        xpos = xmin - xpos / Minimap:GetEffectiveScale() + 70
        ypos = ypos / Minimap:GetEffectiveScale() - ymin - 70

        local angle = math.deg(math.atan2(ypos, xpos))
        if angle < 0 then angle = angle + 360 end
        
        PTBA_DB.minimap.minimapPos = angle
        UpdatePosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
end)

minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        PTBA_DB.enabled = not PTBA_DB.enabled
        PTBA.UpdateMinimapIcon()
        local state = PTBA_DB.enabled and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
        print("PrestigeTalentBarAuto is now " .. state)
    elseif button == "RightButton" then
        -- We will link this to the UI panel later
        if PTBA.ToggleOptionsPanel then
            PTBA.ToggleOptionsPanel()
        end
    end
end)

minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("PrestigeTalentBarAuto")
    GameTooltip:AddLine("Left-Click to toggle ON/OFF", 1, 1, 1)
    GameTooltip:AddLine("Right-Click for Options", 1, 1, 1)
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Initialize position on load
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    UpdatePosition()
end)
