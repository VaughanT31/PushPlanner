-- PushPlanner - UI/MainWindow.lua
-- Assembles the planner page from the widget toolkit. Built lazily on first
-- open; events only registered while shown.

local _, PP = ...
local Theme = PP.Theme
local L = PP.L

PP.MainWindow = {}
local MainWindow = PP.MainWindow

local WINDOW_WIDTH = 560
local WINDOW_HEIGHT = 560
local STAT_GAP = 8

local window
local statCurrent, statTarget, statGap
local charName, charRating
local targetInput, maxLevelInput, avoidDropdown, rememberCheckbox, calculateButton
local viewport, scrollContent
local emptyStateText
local footer
local cards = {}
local dungeonCache = {}
local eventFrame
local scrollOffset = 0

local function ClearCards()
    for _, card in ipairs(cards) do
        card:Hide()
        card:SetParent(nil)
    end
    cards = {}
end

-- Manual scroll clipping instead of a Blizzard ScrollFrame. scrollContent
-- sits inside viewport (which clips its children); scrolling just moves
-- scrollContent's top edge up/down and viewport's clip does the rest. This
-- avoids ScrollFrame's own scroll-range tracking, which was found to serve
-- a stale range after the content height changes.
local function ClampScroll()
    local maxScroll = math.max((scrollContent:GetHeight() or 0) - viewport:GetHeight(), 0)
    if scrollOffset < 0 then scrollOffset = 0 end
    if scrollOffset > maxScroll then scrollOffset = maxScroll end
    scrollContent:ClearAllPoints()
    scrollContent:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, scrollOffset)
    scrollContent:SetPoint("RIGHT", viewport, "RIGHT", 0, 0)
end

local function ResetScroll()
    scrollOffset = 0
    ClampScroll()
end

local function RefreshHeader()
    local name = UnitName("player") or "?"
    local _, classFile = UnitClass("player")
    local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]) or { r = 1, g = 1, b = 1 }
    charName:SetText(name)
    charName:SetTextColor(classColor.r, classColor.g, classColor.b)

    local rating = PP.Data.GetOverallRating()
    local color = PP.Data.GetRarityColor(rating)
    charRating:SetText(string.format("Rating: %d", rating))
    charRating:SetTextColor(unpack(color))

    statCurrent:SetValue(tostring(rating))
    local target = PP.db.targetRating or 0
    statTarget:SetValue(tostring(target))
    local gap = target - rating
    statGap:SetValue(tostring(math.max(gap, 0)), gap > 0 and "warn" or "good")

    return rating, target
end

local function LoadDungeons()
    dungeonCache = PP.Data.GetSeasonDungeons()
    for _, d in ipairs(dungeonCache) do
        local best = PP.Data.GetBestRun(d.mapID)
        d.score = best and best.score or 0
    end

    local items = {}
    for _, d in ipairs(dungeonCache) do
        table.insert(items, { value = d.mapID, text = d.name or ("Map " .. d.mapID) })
    end
    avoidDropdown:SetItems(items)
end

local function ShowEmptyState(text, colorKey)
    ClearCards()
    emptyStateText:SetText(text)
    emptyStateText:SetTextColor(unpack(Theme.colors[colorKey or "textDim"]))
    emptyStateText:Show()
    scrollContent:SetHeight(1)
    ResetScroll()
end

function MainWindow:Calculate()
    local rating = PP.Data.GetOverallRating()
    local target = targetInput:GetValue()
    PP.db.targetRating = target

    local maxLevel = maxLevelInput:GetValue()
    PP.db.maxKeyLevel = maxLevel

    local avoidList = avoidDropdown:GetSelected()
    local avoidSet = {}
    for _, mapID in ipairs(avoidList) do avoidSet[mapID] = true end
    PP.db.avoidedDungeons = avoidList

    RefreshHeader()

    if #dungeonCache == 0 then
        ShowEmptyState(L.NO_DUNGEON_DATA or "No dungeon data yet - open a Mythic+ map or wait a moment and try again.", "warn")
        return
    end

    local result = PP.Planner.Plan(dungeonCache, rating, target, avoidSet, maxLevel)

    if result.status == "already" then
        ShowEmptyState(L.ALREADY_THERE or "You already have that rating.", "good")
        return
    elseif result.status == "all_avoided" then
        ShowEmptyState(L.ALL_AVOIDED or "Every dungeon is avoided - allow at least one to plan runs.", "warn")
        return
    elseif result.status == "unreachable" then
        ShowEmptyState(L.UNREACHABLE or "Can't reach this target with these settings - lower the target, raise Max Level, or avoid fewer dungeons.", "warn")
        return
    end

    emptyStateText:Hide()
    ClearCards()
    ResetScroll()

    local affixes = PP.Data.GetCurrentAffixes()
    local prev
    local totalHeight = 0
    local gap = 6
    for i, option in ipairs(result.options) do
        local card = PP.ResultsCard.New(scrollContent, option, i, i == #result.options, affixes)
        card:SetPoint("RIGHT", scrollContent, "RIGHT", 0, 0)
        if prev then
            card:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -gap)
        else
            card:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, 0)
        end
        card:Show()
        table.insert(cards, card)
        prev = card
        totalHeight = totalHeight + card:GetHeight() + gap
    end
    scrollContent:SetHeight(math.max(totalHeight, 1))
    ClampScroll()
end

function MainWindow:RefreshInputs()
    targetInput:SetValue(PP.db.targetRating or 0)
    maxLevelInput:SetValue(PP.db.maxKeyLevel or 20)
    avoidDropdown:SetSelected(PP.db.avoidedDungeons or {})
    rememberCheckbox:SetChecked(PP.db.rememberInputs)
end

local function Build()
    window = PP.Widgets.Window.New({
        name = "PushPlannerWindow",
        title = PP.name,
        width = WINDOW_WIDTH,
        height = WINDOW_HEIGHT,
        savedPosition = PP.db.window,
    })

    local content = window.content

    -- Character header
    charName = Theme:CreateFontString(content, "sizeLarge", "text")
    charName:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)

    charRating = Theme:CreateFontString(content, "size", "textDim")
    charRating:SetPoint("LEFT", charName, "RIGHT", 10, 0)

    -- Summary stat cells, split evenly across the full content width.
    local statWidth = (WINDOW_WIDTH - Theme.insets.panel * 2 - STAT_GAP * 2) / 3
    statCurrent = PP.Widgets.StatCell.New(content, { label = "CURRENT", width = statWidth })
    statCurrent:SetPoint("TOPLEFT", charName, "BOTTOMLEFT", 0, -10)

    statTarget = PP.Widgets.StatCell.New(content, { label = "TARGET", width = statWidth })
    statTarget:SetPoint("LEFT", statCurrent, "RIGHT", STAT_GAP, 0)

    statGap = PP.Widgets.StatCell.New(content, { label = "GAP", width = statWidth })
    statGap:SetPoint("LEFT", statTarget, "RIGHT", STAT_GAP, 0)

    -- Input row
    targetInput = PP.Widgets.EditBox.New(content, { label = "Target Rating", numeric = true, width = 120 })
    targetInput:SetPoint("TOPLEFT", statCurrent, "BOTTOMLEFT", 0, -14)

    maxLevelInput = PP.Widgets.EditBox.New(content, { label = "Max Level", numeric = true, width = 90 })
    maxLevelInput:SetPoint("LEFT", targetInput, "RIGHT", 8, 0)

    avoidDropdown = PP.Widgets.Dropdown.New(content, { label = "Avoid Dungeons", width = 150, emptyText = "None" })
    avoidDropdown:SetPoint("LEFT", maxLevelInput, "RIGHT", 8, 0)

    rememberCheckbox = PP.Widgets.Checkbox.New(content, {
        label = "Remember",
        checked = PP.db.rememberInputs,
        onChanged = function(checked) PP.db.rememberInputs = checked end,
    })
    rememberCheckbox:SetPoint("LEFT", avoidDropdown, "RIGHT", 10, 4)

    calculateButton = PP.Widgets.Button.New(content, { text = "Calculate", width = 100, accent = true, onClick = function()
        MainWindow:Calculate()
    end })
    calculateButton:SetPoint("TOPLEFT", targetInput, "BOTTOMLEFT", 0, -14)

    -- Results area. A plain frame that clips its children, not a Blizzard
    -- ScrollFrame - scrolling is just moving scrollContent's anchor offset
    -- (see ClampScroll/ResetScroll above), fully under our own control.
    viewport = CreateFrame("Frame", nil, content)
    viewport:SetPoint("TOPLEFT", calculateButton, "BOTTOMLEFT", 0, -12)
    viewport:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    viewport:SetPoint("BOTTOM", content, "BOTTOM", 0, 26)
    viewport:SetClipsChildren(true)
    viewport:EnableMouseWheel(true)
    viewport:SetScript("OnMouseWheel", function(_, delta)
        scrollOffset = scrollOffset - delta * 40
        ClampScroll()
    end)

    scrollContent = CreateFrame("Frame", nil, viewport)
    scrollContent:SetHeight(1)
    scrollContent:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, 0)
    scrollContent:SetPoint("RIGHT", viewport, "RIGHT", 0, 0)

    emptyStateText = Theme:CreateFontString(scrollContent, "size", "textDim")
    emptyStateText:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 4, -4)
    emptyStateText:SetPoint("RIGHT", scrollContent, "RIGHT", -4, 0)
    emptyStateText:SetJustifyH("LEFT")
    emptyStateText:SetWordWrap(true)
    emptyStateText:Hide()

    -- Footer
    footer = Theme:CreateFontString(content, "sizeSmall", "textDim")
    footer:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    footer:SetJustifyH("LEFT")
    footer:SetText(string.format("PushPlanner v%s - math ported from Mythic Planner and SamFarah/RatingCalculator", PP.version))

    -- Events, only registered while shown.
    eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "CHALLENGE_MODE_MAPS_UPDATE" then
            LoadDungeons()
        end
        RefreshHeader()
    end)

    window:SetScript("OnShow", function()
        eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
        eventFrame:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
        PP.Data.RequestUpdate()
        LoadDungeons()
        MainWindow:RefreshInputs()
        RefreshHeader()
    end)
    window:SetScript("OnHide", function()
        eventFrame:UnregisterAllEvents()
    end)
end

function MainWindow:Toggle()
    if not window then
        Build()
    end
    if window:IsShown() then
        window:Hide()
    else
        window:Show()
    end
end
