-- PushPlanner - Core/MinimapButton.lua
-- Custom minimap button, no LibDBIcon. Stores its angle in SavedVariables
-- and re-places itself with cos/sin on load.

local _, PP = ...

PP.MinimapButton = {}
local MinimapButton = PP.MinimapButton

local BUTTON_SIZE = 31
local ICON = "Interface\\AddOns\\PushPlanner\\Media\\icon"

local button

local function UpdatePosition(angleDeg)
    local angle = math.rad(angleDeg)
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function AngleFromCursor()
    local mx, my = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    mx, my = mx / scale, my / scale
    local cx, cy = Minimap:GetCenter()
    local angle = math.deg(math.atan2(my - cy, mx - cx))
    if angle < 0 then angle = angle + 360 end
    return angle
end

function MinimapButton:Init()
    if button then return end
    if PP.db.minimap.hide then return end

    button = CreateFrame("Button", "PushPlannerMinimapButton", Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button:SetScript("OnDragStart", function()
        button:SetScript("OnUpdate", function()
            local angle = AngleFromCursor()
            PP.db.minimap.angle = angle
            UpdatePosition(angle)
        end)
    end)
    button:SetScript("OnDragStop", function()
        button:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            if PP.MainWindow then PP.MainWindow:Toggle() end
        else
            if PP.Settings then PP.Settings:Open() end
        end
    end)

    button:SetScript("OnEnter", function()
        local rating = PP.Data.GetOverallRating()
        local target = PP.db.targetRating or 0

        local message = "PushPlanner\nRating: " .. rating
        if target > 0 then
            local gap = target - rating
            if gap > 0 then
                message = message .. " (" .. gap .. " to " .. target .. ")"
            else
                message = message .. " (target " .. target .. " reached)"
            end
        end
        message = message .. "\nLeft-click to plan\nRight-click for settings"

        PP.ShowTip(button, message, "ANCHOR_TOP")
    end)
    button:SetScript("OnLeave", function()
        PP.HideTip()
    end)

    UpdatePosition(PP.db.minimap.angle or 200)
end

function MinimapButton:SetShown(shown)
    PP.db.minimap.hide = not shown
    if not button and shown then
        MinimapButton:Init()
    elseif button then
        button:SetShown(shown)
    end
end
