-- PushPlanner - UI/MainWindow.lua
-- Assembles the planner page from the widget toolkit. Built lazily on first
-- open; events only registered while shown. "Plan for" picks whose numbers
-- the plan uses (Core/Subjects.lua): you, a group member or target, anyone
-- by name (Raider.IO addon data), or runs typed in.

local _, PP = ...
local Theme = PP.Theme
local L = PP.L

PP.MainWindow = {}
local MainWindow = PP.MainWindow

local WINDOW_WIDTH = 560
local WINDOW_HEIGHT = 560
local STAT_GAP = 8
local SETTINGS_HEIGHT = 58
local SETTINGS_HEIGHT_TWO_LINES = 88
local PROGRESS_TEXT_WIDTH = 120

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
local planFor, nameInput, lookupButton, editRunsButton, sourceText
local manualPanel
local progress, progressText, settings, resultsTitle
local subject = { kind = "me" }
local subjectData, subjectError

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

-- Reads the current subject's numbers (cached until the subject changes or
-- the window is refreshed).
local function LoadSubject()
    subjectData, subjectError = PP.Subjects.Load(subject, dungeonCache)
end

local function SubjectName()
    if subject.kind == "me" then
        return UnitName("player") or "?", select(2, UnitClass("player"))
    elseif subject.kind == "unit" then
        local _, classFile = UnitClass(subject.unit)
        return subject.label or "?", classFile
    elseif subject.kind == "name" then
        return subject.label or "By name", nil
    end
    return "Typed-in runs", nil
end

local function RefreshHeader()
    local name, classFile = SubjectName()
    local classColor = (classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]) or { r = 1, g = 1, b = 1 }
    charName:SetText(name)
    charName:SetTextColor(classColor.r, classColor.g, classColor.b)

    local rating = subjectData and math.floor(subjectData.rating + 0.5) or 0
    local color = PP.Data.GetRarityColor(rating)
    charRating:SetText(subjectData and string.format("Rating: %d", rating) or "")
    charRating:SetTextColor(unpack(color))
    sourceText:SetText(subjectData and subjectData.source or "")

    nameInput:SetShown(subject.kind == "name")
    lookupButton:SetShown(subject.kind == "name")
    editRunsButton:SetShown(subject.kind == "manual")
    local twoLines = subject.kind == "name" or subject.kind == "manual"
    settings:SetHeight(twoLines and SETTINGS_HEIGHT_TWO_LINES or SETTINGS_HEIGHT)

    statCurrent:SetValue(tostring(rating))
    statCurrent:SetAccent(color)
    local target = PP.db.targetRating or 0
    statTarget:SetValue(tostring(target))
    local gap = target - rating
    statGap:SetValue(tostring(math.max(gap, 0)), gap > 0 and "warn" or "good")
    statGap:SetAccent(gap > 0 and "warn" or "good")

    -- Progress towards the target.
    progress:SetMinMax(0, math.max(target, 1))
    progress:SetValue(rating)
    local pct = target > 0 and math.min(100, math.floor(rating / target * 100)) or 0
    progressText:SetText(target > 0 and (pct >= 100 and "Target reached" or (pct .. "% of the way")) or "")
    resultsTitle:SetText(target > 0 and ("WAYS TO REACH " .. target) or "WAYS TO GET THERE")

    return rating, target
end

local function LoadDungeons()
    dungeonCache = PP.Data.GetSeasonDungeons()
    for _, d in ipairs(dungeonCache) do
        d.score = 0
    end
    LoadSubject()

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
    LoadSubject()
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
    if not subjectData then
        ShowEmptyState(subjectError or "No Mythic+ data for them.", "warn")
        return
    end
    local rating = subjectData.rating
    for _, d in ipairs(dungeonCache) do
        d.score = subjectData.scores[d.mapID] or 0
    end

    local result = PP.Planner.Plan(dungeonCache, rating, target, avoidSet, maxLevel)

    if result.status == "already" then
        ShowEmptyState(subject.kind == "me" and (L.ALREADY_THERE or "You already have that rating.") or "They already have that rating.", "good")
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
    -- Parse bands for your own spec (only when planning for yourself: other
    -- players' specs aren't known without an inspect).
    local bands
    if subject.kind == "me" and PP.ParseBands and GetSpecialization then
        local specIndex = GetSpecialization()
        local specID = specIndex and GetSpecializationInfo(specIndex)
        bands = specID and PP.ParseBands.specs[specID]
    end
    local prev
    local totalHeight = 0
    local gap = 6
    for i, option in ipairs(result.options) do
        local card = PP.ResultsCard.New(scrollContent, option, i, i == #result.options, affixes, bands)
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

-- Subjects ---------------------------------------------------------------

local function RefreshChoices(extra)
    local items = {}
    for _, choice in ipairs(PP.Subjects.Choices()) do items[#items + 1] = choice end
    if extra then items[#items + 1] = extra end
    planFor:SetItems(items)
    planFor.items = items
end

local function PickerValue()
    if subject.kind == "unit" then return subject.unit end
    return subject.kind
end

function MainWindow:SetSubject(newSubject, extraChoice)
    subject = newSubject or { kind = "me" }
    if extraChoice then RefreshChoices(extraChoice) end
    planFor:SetSelected({ PickerValue() })
    LoadSubject()
    RefreshHeader()
    if subject.kind == "name" and not subject.name then
        ShowEmptyState("Type their name and realm (Zed-Draenor), then Look up. This uses the Raider.IO addon's data, so it needs that addon installed.", "textDim")
        nameInput.box:SetFocus()
    elseif subject.kind == "manual" and not next(PP.db.manualRuns or {}) then
        ShowEmptyState("Click Edit runs and type each dungeon's best key level, then Calculate.", "textDim")
        MainWindow:ShowManualPanel()
    else
        MainWindow:Calculate()
    end
end

-- Opens the window planning for someone (from the right-click menu).
function MainWindow:OpenFor(newSubject)
    if not window then
        self:Toggle()
    elseif not window:IsShown() then
        window:Show()
    end
    local extra
    if newSubject.kind == "unit" then
        extra = { value = newSubject.unit, text = newSubject.label, subject = newSubject }
    end
    self:SetSubject(newSubject, extra)
end

local function LookUp()
    local name, realm = PP.Subjects.ParseName(nameInput:GetValue())
    if not name then
        ShowEmptyState("Type their name and realm, like Zed-Draenor.", "warn")
        return
    end
    nameInput.box:ClearFocus()
    MainWindow:SetSubject({ kind = "name", name = name, realm = realm, label = realm and (name .. "-" .. realm) or name })
end

-- Manual entry: best key level and timed or not, per dungeon.
local function BuildManualPanel()
    manualPanel = CreateFrame("Frame", nil, viewport, "BackdropTemplate")
    manualPanel:SetAllPoints(viewport)
    manualPanel:SetFrameLevel(viewport:GetFrameLevel() + 20)
    Theme:SkinPanel(manualPanel, "panel", "borderAccent")
    manualPanel:EnableMouse(true)
    manualPanel:Hide()

    local title = Theme:CreateFontString(manualPanel, "size", "textTitle")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("Best key per dungeon (0 = none)")
    manualPanel.rows = {}

    local done = PP.Widgets.Button.New(manualPanel, { text = "Done", width = 80, accent = true, onClick = function()
        local runs = {}
        for _, row in ipairs(manualPanel.rows) do
            if row:IsShown() then
                local level = tonumber(row.level.box:GetText()) or 0
                if level > 0 then
                    runs[row.mapID] = { level = level, timed = row.timed:IsChecked() }
                end
            end
        end
        PP.db.manualRuns = runs
        manualPanel:Hide()
        MainWindow:SetSubject({ kind = "manual" })
    end })
    done:SetPoint("BOTTOMRIGHT", -10, 8)
end

function MainWindow:ShowManualPanel()
    if not manualPanel then BuildManualPanel() end
    local typed = PP.db.manualRuns or {}
    for i, d in ipairs(dungeonCache) do
        local row = manualPanel.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, manualPanel)
            row:SetSize(400, 22)
            row:SetPoint("TOPLEFT", 10, -30 - (i - 1) * 26)
            row.name = Theme:CreateFontString(row, "size", "text")
            row.name:SetPoint("LEFT")
            row.name:SetWidth(200)
            row.name:SetJustifyH("LEFT")
            row.name:SetWordWrap(false)
            row.level = PP.Widgets.EditBox.New(row, { numeric = true, width = 44, height = 22, maxLetters = 2 })
            row.level:SetPoint("LEFT", 206, 0)
            row.level.label:Hide()
            row.level.box:ClearAllPoints()
            row.level.box:SetAllPoints(row.level)
            row.timed = PP.Widgets.Checkbox.New(row, { label = "Timed", width = 80 })
            row.timed:SetPoint("LEFT", row.level, "RIGHT", 12, 0)
            row.timed:SetScript("OnClick", function(self) self:SetChecked(not self:IsChecked()) end)
            manualPanel.rows[i] = row
        end
        local run = typed[d.mapID]
        row.mapID = d.mapID
        row.name:SetText(d.name or ("Map " .. d.mapID))
        row.level:SetValue(run and run.level or 0)
        row.timed:SetChecked(run == nil or run.timed == true)
        row:Show()
    end
    for i = #dungeonCache + 1, #manualPanel.rows do manualPanel.rows[i]:Hide() end
    manualPanel:Show()
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

    sourceText = Theme:CreateFontString(content, "sizeSmall", "textDim")
    sourceText:SetPoint("LEFT", charRating, "RIGHT", 10, 0)
    sourceText:SetWordWrap(false)

    planFor = PP.Widgets.Dropdown.New(content, {
        label = "", width = 160, single = true, emptyText = "Me",
        onOpen = function()
            local extra
            if subject.kind == "unit" then
                extra = { value = subject.unit, text = subject.label, subject = subject }
                for _, choice in ipairs(PP.Subjects.Choices()) do
                    if choice.value == subject.unit then extra = nil end
                end
            end
            RefreshChoices(extra)
        end,
        onChanged = function(_, item)
            MainWindow:SetSubject(item and item.subject)
        end,
    })
    -- On the name line, right-aligned, with its own label to the left.
    planFor:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 3)
    local planLabel = Theme:CreateFontString(content, "sizeSmall", "textDim")
    planLabel:SetPoint("RIGHT", planFor.button, "LEFT", -6, 0)
    planLabel:SetText("Plan for")
    sourceText:SetPoint("RIGHT", planLabel, "LEFT", -10, 0)
    sourceText:SetJustifyH("LEFT")

    -- Summary stat cells, split evenly across the full content width, each
    -- with a coloured strip on top.
    local statWidth = (WINDOW_WIDTH - Theme.insets.panel * 2 - STAT_GAP * 2) / 3
    statCurrent = PP.Widgets.StatCell.New(content, { label = "CURRENT", width = statWidth })
    statCurrent:SetPoint("TOPLEFT", charName, "BOTTOMLEFT", 0, -10)

    statTarget = PP.Widgets.StatCell.New(content, { label = "TARGET", width = statWidth, accent = "textTitle" })
    statTarget:SetPoint("LEFT", statCurrent, "RIGHT", STAT_GAP, 0)

    statGap = PP.Widgets.StatCell.New(content, { label = "GAP", width = statWidth, accent = "warn" })
    statGap:SetPoint("LEFT", statTarget, "RIGHT", STAT_GAP, 0)

    -- Progress from the current rating to the target.
    progress = PP.Widgets.ProgressBar.New(content, { height = 8 })
    progress:SetPoint("TOPLEFT", statCurrent, "BOTTOMLEFT", 0, -10)
    progress:SetPoint("RIGHT", content, "RIGHT", -PROGRESS_TEXT_WIDTH, 0)
    progressText = Theme:CreateFontString(content, "sizeSmall", "textDim")
    progressText:SetPoint("LEFT", progress, "RIGHT", 8, 0)
    progressText:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    progressText:SetJustifyH("RIGHT")

    -- Settings: one framed row with Calculate at its end. A second line
    -- holds the name box (Plan for: By name) or Edit runs (Type it in).
    settings = CreateFrame("Frame", nil, content, "BackdropTemplate")
    settings:SetPoint("TOPLEFT", progress, "BOTTOMLEFT", 0, -12)
    settings:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    settings:SetHeight(SETTINGS_HEIGHT)
    Theme:SkinPanel(settings, "panel", "border")

    targetInput = PP.Widgets.EditBox.New(settings, { label = "Target Rating", numeric = true, width = 100 })
    targetInput:SetPoint("TOPLEFT", settings, "TOPLEFT", 10, -8)

    maxLevelInput = PP.Widgets.EditBox.New(settings, { label = "Max Level", numeric = true, width = 70 })
    maxLevelInput:SetPoint("LEFT", targetInput, "RIGHT", 8, 0)

    avoidDropdown = PP.Widgets.Dropdown.New(settings, { label = "Avoid Dungeons", width = 150, emptyText = "None" })
    avoidDropdown:SetPoint("LEFT", maxLevelInput, "RIGHT", 8, 0)

    rememberCheckbox = PP.Widgets.Checkbox.New(settings, {
        label = "Remember",
        width = 84,
        checked = PP.db.rememberInputs,
        onChanged = function(checked) PP.db.rememberInputs = checked end,
    })
    rememberCheckbox:SetPoint("LEFT", avoidDropdown.button, "RIGHT", 12, 0)

    calculateButton = PP.Widgets.Button.New(settings, { text = "Calculate", width = 96, accent = true, onClick = function()
        MainWindow:Calculate()
    end })
    calculateButton:SetPoint("TOP", avoidDropdown.button, "TOP", 0, 0)
    calculateButton:SetPoint("RIGHT", settings, "RIGHT", -10, 0)

    -- By name: name box and Look up, on the second line.
    nameInput = PP.Widgets.EditBox.New(settings, { width = 220, height = 22, maxLetters = 60 })
    nameInput.label:Hide()
    nameInput.box:ClearAllPoints()
    nameInput.box:SetAllPoints(nameInput)
    nameInput:SetPoint("TOPLEFT", targetInput, "BOTTOMLEFT", 0, -8)
    nameInput.box:SetScript("OnEnterPressed", function() LookUp() end)
    nameInput:Hide()
    lookupButton = PP.Widgets.Button.New(settings, { text = "Look up", width = 80, onClick = LookUp })
    lookupButton:SetPoint("LEFT", nameInput, "RIGHT", 6, 0)
    lookupButton:Hide()

    editRunsButton = PP.Widgets.Button.New(settings, { text = "Edit runs", width = 90, onClick = function()
        MainWindow:ShowManualPanel()
    end })
    editRunsButton:SetPoint("TOPLEFT", targetInput, "BOTTOMLEFT", 0, -8)
    editRunsButton:Hide()

    -- Results: a framed panel with a heading. A plain frame inside clips
    -- the cards, not a Blizzard ScrollFrame - scrolling is just moving
    -- scrollContent's anchor offset (see ClampScroll/ResetScroll above),
    -- fully under our own control.
    local results = CreateFrame("Frame", nil, content, "BackdropTemplate")
    results:SetPoint("TOPLEFT", settings, "BOTTOMLEFT", 0, -10)
    results:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    results:SetPoint("BOTTOM", content, "BOTTOM", 0, 20)
    Theme:SkinPanel(results, "panel", "border")
    Theme:AccentStrip(results, "borderAccent")
    resultsTitle = Theme:CreateFontString(results, "sizeSmall", "textTitle")
    resultsTitle:SetPoint("TOPLEFT", results, "TOPLEFT", 10, -9)
    resultsTitle:SetText("WAYS TO GET THERE")

    viewport = CreateFrame("Frame", nil, results)
    viewport:SetPoint("TOPLEFT", results, "TOPLEFT", 8, -28)
    viewport:SetPoint("BOTTOMRIGHT", results, "BOTTOMRIGHT", -8, 8)
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
            -- The season's dungeons arrived after opening: plan now.
            if #cards == 0 and (subject.kind == "me" or subject.kind == "unit") then
                MainWindow:Calculate()
                return
            end
        elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_TARGET_CHANGED" then
            -- Someone else's numbers may only arrive once they're in range.
            if subject.kind == "unit" then LoadSubject() end
        end
        RefreshHeader()
    end)

    window:SetScript("OnShow", function()
        eventFrame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
        eventFrame:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
        eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
        RefreshChoices()
        planFor:SetSelected({ PickerValue() })
        PP.Data.RequestUpdate()
        LoadDungeons()
        MainWindow:RefreshInputs()
        RefreshHeader()
        -- Show a plan straight away instead of an empty panel.
        if subject.kind == "me" or subject.kind == "unit"
            or (subject.kind == "manual" and next(PP.db.manualRuns or {})) then
            MainWindow:Calculate()
        end
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
