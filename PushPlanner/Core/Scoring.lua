-- PushPlanner - Core/Scoring.lua
-- Pure score model, ported 1:1 from RcService.cs (scope.md section 8.1-8.2).
-- No WoW API calls in this file - keep it a pure function library so it can
-- be unit tested outside the client.

local _, PP = ...

PP.Scoring = {}
local Scoring = PP.Scoring

local S = PP.SeasonScoring

-- Base = score for finishing that level exactly on par time.
function Scoring.GetBase(level)
    local base = S.baseByLevel[level]
    if base then
        return base
    end
    if level > 12 then
        return S.highLevelOffset + S.highLevelSlope * level
    end
    -- Below the table's lowest key (2): extrapolate using the same slope
    -- so the function stays sane for a level 0/1 corner case.
    return S.highLevelOffset + S.highLevelSlope * level
end

function Scoring.GetMax(level)
    return Scoring.GetBase(level) + 15
end

function Scoring.GetMin(level)
    if level > 10 then
        return 290
    end
    return Scoring.GetBase(level) - 30
end

-- getRunScore(time, timeLimit, level) - section 8.2
function Scoring.GetRunScore(time, timeLimit, level)
    if level > 10 and time > timeLimit then
        level = 10
    end
    local base = Scoring.GetBase(level)
    local pt = math.abs(timeLimit - time) / timeLimit
    local overtime = time > timeLimit
    local corrected = math.min(pt, S.timingCapPct) * (overtime and -1 or 1)
    local score = base + corrected * S.timingWeight - (overtime and S.overtimeFlat or 0)
    return score
end

-- GetChestLevel(time, timeLimit) - returns the keystone-upgrade ("chest")
-- tier (1, 2, or 3) a run earns for finishing at `time` against `timeLimit`,
-- or 0 if it wasn't timed at all.
function Scoring.GetChestLevel(time, timeLimit)
    if time > timeLimit then
        return 0
    end
    local pctUnder = (timeLimit - time) / timeLimit
    if pctUnder >= S.chestThresholds[3] then
        return 3
    elseif pctUnder >= S.chestThresholds[2] then
        return 2
    end
    return 1
end

-- metricsForScore(wanted) - section 8.4. Returns level, base.
function Scoring.MetricsForScore(wanted)
    if wanted > 380 then
        local level = math.floor((wanted - S.highLevelOffset) / S.highLevelSlope)
        local base = S.highLevelOffset + S.highLevelSlope * level
        return level, base
    end

    local bestLevel, bestBase
    for level = 2, 12 do
        local max = Scoring.GetMax(level)
        if max >= wanted then
            bestLevel = level
            bestBase = Scoring.GetBase(level)
            break
        end
    end
    if not bestLevel then
        bestLevel = 12
        bestBase = Scoring.GetBase(12)
    end
    return bestLevel, bestBase
end

-- FinishTimeForScore(wanted, level, base, timeLimit) - section 8.5.
-- Returns time, newScore.
function Scoring.FinishTimeForScore(wanted, level, base, timeLimit)
    local time
    if wanted < base - 15 then
        local p = math.min(S.timingCapPct, (base - wanted - 15) / S.timingWeight)
        time = timeLimit + timeLimit * p
    else
        local p = math.max(0, math.min(S.timingCapPct, (wanted - base) / S.timingWeight))
        time = timeLimit - timeLimit * p
    end
    local newScore = Scoring.GetRunScore(time, timeLimit, level)
    return time, newScore
end
