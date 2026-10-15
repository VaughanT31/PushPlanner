-- PushPlanner - Core/Subjects.lua
-- Who the plan is for. The planner only needs each dungeon's best score and
-- the overall rating, so planning for someone else is just a different
-- source for those numbers:
--   me      your own character (C_MythicPlus, as before)
--   unit    a party/raid member or your target: the game shares their
--           Mythic+ summary (C_PlayerInfo.GetPlayerMythicPlusRatingSummary)
--   name    anyone by name and realm, from the Raider.IO addon's own data
--           when it's installed (optional; nothing breaks without it)
--   manual  best key level and timed/over time per dungeon, typed in
-- Subjects.Load(subject, dungeons) -> { rating, scores = { [mapID] = score },
-- source } or nil, reason.

local _, PP = ...

PP.Subjects = {}
local Subjects = PP.Subjects
local Scoring = PP.Scoring

-- The score a best run of `level` gave, timed or not. Exact time isn't known
-- from a level alone, so a timed run counts as on par and an over-time run
-- as 10% over par: close to what the game shows, and the same both ways.
function Subjects.ScoreFor(level, timed, timeLimit, fraction)
    if not level or level <= 0 then
        return 0
    end
    timeLimit = timeLimit or 1800
    if fraction and fraction > 0 then
        return Scoring.GetRunScore(fraction * timeLimit, timeLimit, level)
    end
    if timed then
        return Scoring.GetBase(level)
    end
    return Scoring.GetRunScore(timeLimit * 1.1, timeLimit, level)
end

local function Secret(value)
    return issecretvalue and value ~= nil and issecretvalue(value)
end

-- A display name for a unit ("Name" or "Name-Realm").
function Subjects.UnitLabel(unit)
    local name, realm = UnitName(unit)
    if not name or Secret(name) then
        return nil
    end
    if realm and realm ~= "" and not Secret(realm) then
        return name .. "-" .. realm
    end
    return name
end

-- The choices for the "Plan for" dropdown: you, your target if it's another
-- player, everyone in your party, then by name and typed in.
function Subjects.Choices()
    local list = { { value = "me", text = "Me", subject = { kind = "me" } } }
    local function addUnit(unit, prefix)
        if UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
            local label = Subjects.UnitLabel(unit)
            if label then
                list[#list + 1] = { value = unit, text = prefix .. label, subject = { kind = "unit", unit = unit, label = label } }
            end
        end
    end
    addUnit("target", "Target: ")
    for i = 1, 4 do
        addUnit("party" .. i, "")
    end
    list[#list + 1] = { value = "name", text = "By name...", subject = { kind = "name" } }
    list[#list + 1] = { value = "manual", text = "Type it in...", subject = { kind = "manual" } }
    return list
end

local function FromMe(dungeons)
    local scores = {}
    for _, d in ipairs(dungeons) do
        local best = PP.Data.GetBestRun(d.mapID)
        scores[d.mapID] = best and best.score or 0
    end
    return { rating = PP.Data.GetOverallRating(), scores = scores, source = "From the game" }
end

local function FromUnit(subject, dungeons)
    local unit = subject.unit
    if not unit or not UnitExists(unit) or (subject.label and Subjects.UnitLabel(unit) ~= subject.label) then
        return nil, ("%s is no longer in your group or targeted. Pick them again from \"Plan for\"."):format(subject.label or "They")
    end
    if not (C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary) then
        return nil, "The game doesn't share this right now."
    end
    local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
    if not summary then
        return nil, "Their Mythic+ data hasn't loaded. Get closer or invite them, then try again."
    end
    local scores = {}
    for _, d in ipairs(dungeons) do scores[d.mapID] = 0 end
    for _, run in ipairs(summary.runs or {}) do
        if run.challengeModeID and scores[run.challengeModeID] ~= nil then
            scores[run.challengeModeID] = run.mapScore or 0
        end
    end
    return { rating = summary.currentSeasonScore or 0, scores = scores, source = "From the game (" .. (unit == "target" and "target" or "group") .. ")" }
end

-- Raider.IO's addon keeps its own copy of most players' runs. Its fields
-- have changed over the years, so this reads them defensively and matches
-- each dungeon by challenge map ID, then by name.
local function MatchDungeon(dungeons, info)
    if type(info) ~= "table" then
        return nil
    end
    for _, key in ipairs({ "keystone_instance", "keystoneInstance", "challengeModeID", "id" }) do
        local id = tonumber(info[key])
        if id then
            for _, d in ipairs(dungeons) do
                if d.mapID == id then return d end
            end
        end
    end
    local wanted = type(info.name) == "string" and info.name:lower()
    if wanted then
        for _, d in ipairs(dungeons) do
            if d.name and d.name:lower() == wanted then return d end
        end
    end
    return nil
end

local function FromRaiderIO(subject, dungeons)
    local rio = _G.RaiderIO
    if not (rio and rio.GetProfile) then
        return nil, "Install the Raider.IO addon to look up anyone by name, or pick \"Type it in\"."
    end
    if not subject.name or subject.name == "" then
        return nil, "Type a name, like Zed-Draenor."
    end
    local ok, profile = pcall(rio.GetProfile, subject.name, subject.realm)
    local keystone = ok and type(profile) == "table" and profile.mythicKeystoneProfile
    if type(keystone) ~= "table" or keystone.hasRenderableData == false then
        return nil, ("Raider.IO's addon data has no Mythic+ runs for %s. Check the name and realm, or pick \"Type it in\"."):format(subject.label or subject.name)
    end

    local scores, sum = {}, 0
    for _, d in ipairs(dungeons) do scores[d.mapID] = 0 end
    local runs = keystone.sortedDungeons or keystone.dungeons or {}
    for key, run in pairs(runs) do
        if type(run) == "table" then
            local d = MatchDungeon(dungeons, run.dungeon or run)
            local level = tonumber(run.level)
            if d and level and level > 0 then
                local timed = (tonumber(run.chests) or 0) > 0
                local score = Subjects.ScoreFor(level, timed, d.timeLimit, tonumber(run.fractionalTime))
                if score > scores[d.mapID] then
                    sum = sum - scores[d.mapID] + score
                    scores[d.mapID] = score
                end
            end
        end
    end
    local rating = tonumber(keystone.currentScore) or sum
    return { rating = rating, scores = scores, source = "From Raider.IO addon data (may be a few days old)" }
end

local function FromManual(dungeons)
    local typed = PP.db.manualRuns or {}
    local scores, sum = {}, 0
    for _, d in ipairs(dungeons) do
        local run = typed[d.mapID]
        local score = run and Subjects.ScoreFor(run.level, run.timed, d.timeLimit) or 0
        scores[d.mapID] = score
        sum = sum + score
    end
    return { rating = math.floor(sum + 0.5), scores = scores, source = "Typed in" }
end

function Subjects.Load(subject, dungeons)
    subject = subject or { kind = "me" }
    if subject.kind == "unit" then
        return FromUnit(subject, dungeons)
    elseif subject.kind == "name" then
        return FromRaiderIO(subject, dungeons)
    elseif subject.kind == "manual" then
        return FromManual(dungeons)
    end
    return FromMe(dungeons)
end

-- "Zed-Draenor" / "Zed" -> name, realm (realm nil for your own realm).
function Subjects.ParseName(text)
    text = (text or ""):match("^%s*(.-)%s*$")
    if text == "" then
        return nil
    end
    local name, realm = text:match("^([^%-]+)%-(.+)$")
    if not name then
        name = text
    end
    return name, realm
end
