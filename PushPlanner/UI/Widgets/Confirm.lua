-- PushPlanner - UI/Widgets/Confirm.lua
-- PP.Confirm: our own yes/no popup, never StaticPopup_Show.

local _, PP = ...
local Theme = PP.Theme

local popup = CreateFrame("Frame", "PushPlannerConfirm", UIParent, "BackdropTemplate")
popup:SetSize(300, 110)
popup:SetPoint("CENTER")
popup:SetFrameStrata("FULLSCREEN_DIALOG")
Theme:SkinPanel(popup, "panel", "borderAccent")
popup:Hide()

local message = Theme:CreateFontString(popup, "size", "text")
message:SetPoint("TOP", popup, "TOP", 0, -16)
message:SetPoint("LEFT", popup, "LEFT", 12, 0)
message:SetPoint("RIGHT", popup, "RIGHT", -12, 0)
message:SetJustifyH("CENTER")
message:SetWordWrap(true)

local acceptBtn = PP.Widgets.Button.New(popup, { text = "Accept", width = 110, accent = true })
acceptBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 20, 16)

local cancelBtn = PP.Widgets.Button.New(popup, { text = "Cancel", width = 110 })
cancelBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -20, 16)

local currentOnAccept, currentOnCancel

acceptBtn:SetScript("OnClick", function()
    popup:Hide()
    if currentOnAccept then currentOnAccept() end
end)

cancelBtn:SetScript("OnClick", function()
    popup:Hide()
    if currentOnCancel then currentOnCancel() end
end)

function PP.Confirm(text, onAccept, onCancel)
    message:SetText(text or "")
    currentOnAccept = onAccept
    currentOnCancel = onCancel
    popup:Show()
end
