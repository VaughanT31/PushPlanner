-- PushPlanner - Core/Data.lua
-- Reads season dungeons, par times, best runs, overall rating and weekly
-- affixes live from the WoW API. No external HTTP, no libraries.

local _, PP = ...

PP.Data = {}
local Data = PP.Data

-- Fallback affix icon table, only used if C_MythicPlus.GetCurrentAffixes()
-- returns nothing (e.g. before the weekly reset is known).
local FALLBACK_AFFIX_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function Data.RequestUpdate()
    if C_MythicPlus and C_MythicPlus.RequestMapInfo then
        C_MythicPlus.RequestMapInfo()
    end
    if C_MythicPlus and C_MythicPlus.RequestCurrentAffixes then
        C_MythicPlus.RequestCurrentAffixes()
    end
end

-- Returns an array of { mapID, name, texture, timeLimit }.
function Data.GetSeasonDungeons()
    local dungeons = {}
    if not (C_ChallengeMode and C_ChallengeMode.GetMapTable) then
        return dungeons
    end
    local mapIDs = C_ChallengeMode.GetMapTable()
    for _, mapID in ipairs(mapIDs or {}) do
        local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
        table.insert(dungeons, {
            mapID = mapID,
            name = name,
            texture = texture,
            timeLimit = timeLimit,
        })
    end
    return dungeons
end

-- Returns { score, level, durationSec, timed } or nil if no run exists.
function Data.GetBestRun(mapID)
    if not (C_MythicPlus and C_MythicPlus.GetSeasonBestForMap) then
        return nil
    end
    local info = C_MythicPlus.GetSeasonBestForMap(mapID)
    if not info or not info.dungeonScore or info.dungeonScore == 0 then
        return nil
    end
    return {
        score = info.dungeonScore,
        level = info.level,
        durationSec = info.durationSec,
        timed = info.level ~= nil and info.level > 0,
    }
end

function Data.GetOverallRating()
    if C_ChallengeMode and C_ChallengeMode.GetOverallDungeonScore then
        return C_ChallengeMode.GetOverallDungeonScore() or 0
    end
    return 0
end

function Data.GetRarityColor(score)
    if C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor then
        local color = C_ChallengeMode.GetDungeonScoreRarityColor(score or 0)
        if color then
            return { color.r, color.g, color.b, 1 }
        end
    end
    return PP.Theme.colors.text
end

-- Returns an array of { texture, name } for the current week's affixes.
function Data.GetCurrentAffixes()
    local affixes = {}
    if C_MythicPlus and C_MythicPlus.GetCurrentAffixes then
        local active = C_MythicPlus.GetCurrentAffixes()
        for _, entry in ipairs(active or {}) do
            local affixID = entry.id
            local name, _, texture
            if C_ChallengeMode and C_ChallengeMode.GetAffixInfo then
                name, _, texture = C_ChallengeMode.GetAffixInfo(affixID)
            end
            table.insert(affixes, {
                id = affixID,
                name = name or ("Affix " .. tostring(affixID)),
                texture = texture or FALLBACK_AFFIX_ICON,
            })
        end
    end
    return affixes
end
