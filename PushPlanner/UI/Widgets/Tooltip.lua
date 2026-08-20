-- PushPlanner - UI/Widgets/Tooltip.lua
-- PP.ShowTip / PP.HideTip: our own plain-text tooltip, never GameTooltip
-- (per house convention). Item/affix links elsewhere may still use
-- GameTooltip:SetHyperlink directly - that is standard and unrelated.

local _, PP = ...
local Theme = PP.Theme

local tip = CreateFrame("Frame", "PushPlannerTooltip", UIParent, "BackdropTemplate")
tip:SetFrameStrata("TOOLTIP")
Theme:SkinPanel(tip, "panel", "borderAccent")
tip:Hide()

local text = Theme:CreateFontString(tip, "sizeSmall", "text")
text:SetPoint("TOPLEFT", tip, "TOPLEFT", 6, -6)
text:SetJustifyH("LEFT")
text:SetWordWrap(true)
text:SetWidth(220)

function PP.ShowTip(owner, message, anchor)
    if not owner or not message or message == "" then return end
    text:SetText(message)
    tip:SetSize(text:GetStringWidth() + 12, text:GetStringHeight() + 12)
    tip:ClearAllPoints()
    tip:SetPoint(anchor == "ANCHOR_TOP" and "BOTTOM" or "TOPLEFT",
        owner, anchor == "ANCHOR_TOP" and "TOP" or "BOTTOMLEFT", 0, anchor == "ANCHOR_TOP" and 4 or -4)
    tip:Show()
end

function PP.HideTip()
    tip:Hide()
end
