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
        message = message .. MinimapButton.NextRunText(rating, target)
        message = message .. "\nLeft-click to plan\nRight-click for settings"

        PP.ShowTip(button, message, "ANCHOR_TOP")
    end)
    button:SetScript("OnLeave", function()
        PP.HideTip()
    end)

    UpdatePosition(PP.db.minimap.angle or 200)
end

-- "Next best run: +11 Ara-Kara (+18)" and, with a target, the fewest runs
-- to reach it, from your own season bests. Empty until the game has sent
-- the season's dungeons.
function MinimapButton.NextRunText(rating, target)
    local dungeons = PP.Data.GetSeasonDungeons()
    if #dungeons == 0 then return "" end
    local data = PP.Subjects.Load({ kind = "me" }, dungeons)
    if not data then return "" end
    for _, d in ipairs(dungeons) do d.score = data.scores[d.mapID] or 0 end
    local avoidSet = {}
    for _, mapID in ipairs(PP.db.avoidedDungeons or {}) do avoidSet[mapID] = true end
    local maxLevel = PP.db.maxKeyLevel or 20

    local text = ""
    local next = PP.Planner.BestNextRun(dungeons, avoidSet, maxLevel)
    if next then
        text = text .. ("\nNext best run: +%d %s (+%d)"):format(next.level, next.dungeon.name or "?", math.floor(next.gain + 0.5))
    end
    if target > rating then
        local plan = PP.Planner.Plan(dungeons, data.rating or rating, target, avoidSet, maxLevel)
        local fewest
        for _, option in ipairs(plan.options or {}) do
            if not fewest or option.dungeonCount < fewest then fewest = option.dungeonCount end
        end
        if fewest then
            text = text .. ("\nFewest runs to %d: %d"):format(target, fewest)
        end
    end
    return text
end

function MinimapButton:SetShown(shown)
    PP.db.minimap.hide = not shown
    if not button and shown then
        MinimapButton:Init()
    elseif button then
        button:SetShown(shown)
    end
end
