-- PushPlanner - UI/ResultsCard.lua
-- Builds one "Option N" card: a title and a stack of ListRows, one per run.

local _, PP = ...
local Theme = PP.Theme

PP.ResultsCard = {}
local ResultsCard = PP.ResultsCard

local ROW_HEIGHT = 30
local ROW_GAP = 4
local TITLE_HEIGHT = 20

local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

local function ChestLabel(chestLevel)
    if chestLevel == 0 then
        return "not timed"
    end
    return chestLevel .. (chestLevel == 1 and " chest" or " chests")
end

local function AffixIcons(dungeonAffixes)
    local icons = {}
    for _, affix in ipairs(dungeonAffixes or {}) do
        table.insert(icons, { texture = affix.texture, tooltip = affix.name })
    end
    return icons
end

-- option: { runs = { { dungeon, level, time, newScore, oldScore, chestLevel }, ... }, dungeonCount }
function ResultsCard.New(parent, option, index, isLast, affixes)
    local titleLabel = index == 1 and "Option 1 (Fastest)" or ("Option " .. index)
    if isLast then
        titleLabel = titleLabel .. " (Easiest)"
    end

    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Theme:SkinPanel(card, "panelAlt", "border")

    local title = Theme:CreateFontString(card, "sizeTitle", "textTitle")
    title:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -6)
    title:SetText(titleLabel)

    local rows = {}
    local prev
    for _, run in ipairs(option.runs) do
        local row = PP.Widgets.ListRow.New(card, { height = ROW_HEIGHT })
        row:SetPoint("RIGHT", card, "RIGHT", -6, 0)
        if prev then
            row:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -ROW_GAP)
        else
            row:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        end

        row.nameText:SetText(run.dungeon.name or "?")
        row.subText:SetText(string.format("Key %d - complete in %s (or faster) - %s", run.level, FormatTime(run.time), ChestLabel(run.chestLevel)))
        row.iconStrip:SetIcons(AffixIcons(affixes))
        row.valueDelta:SetValueDelta(math.floor(run.newScore + 0.5), math.floor(run.newScore - run.oldScore + 0.5))
        row:SetAccentColor("borderAccent")

        table.insert(rows, row)
        prev = row
    end

    local totalHeight = TITLE_HEIGHT + 8 + (#rows * ROW_HEIGHT) + (math.max(#rows - 1, 0) * ROW_GAP) + 10
    card:SetHeight(totalHeight)

    card.rows = rows
    return card
end
