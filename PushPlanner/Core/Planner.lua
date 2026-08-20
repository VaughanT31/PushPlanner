-- PushPlanner - Core/Planner.lua
-- Greedy min-runs planner, ported from RcService.cs (scope.md section 8.7).
-- Pure function over data passed in - no WoW API calls here either.

local _, PP = ...

PP.Planner = {}
local Planner = PP.Planner
local Scoring = PP.Scoring

local function CountKeys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function SortedByScore(dungeons, ascending)
    local copy = {}
    for i, d in ipairs(dungeons) do copy[i] = d end
    table.sort(copy, function(a, b)
        if ascending then
            return a.score < b.score
        end
        return a.score > b.score
    end)
    return copy
end

local function SumScores(list, count)
    local sum = 0
    for i = 1, count do
        sum = sum + list[i].score
    end
    return sum
end

local function OptionSignature(runs)
    local parts = {}
    for _, run in ipairs(runs) do
        table.insert(parts, run.dungeon.mapID .. ":" .. run.level)
    end
    table.sort(parts)
    return table.concat(parts, ",")
end

-- dungeons: array of { mapID, name, texture, timeLimit, score }
-- avoidSet: { [mapID] = true }
function Planner.Plan(dungeons, current, target, avoidSet, maxLevel)
    avoidSet = avoidSet or {}
    maxLevel = maxLevel or 20

    if current >= target then
        return { status = "already", options = {} }
    end

    local seasonDungeons = #dungeons
    local nDung = seasonDungeons - CountKeys(avoidSet)
    if nDung <= 0 then
        return { status = "all_avoided", options = {} }
    end

    local perDung = target / nDung
    local sortedDesc = SortedByScore(dungeons, false)

    local runPool = {}
    for _, d in ipairs(sortedDesc) do
        if d.score > perDung then
            perDung = perDung - (d.score - perDung) / seasonDungeons
        elseif not avoidSet[d.mapID] then
            table.insert(runPool, d)
        end
    end
    table.sort(runPool, function(a, b) return a.score < b.score end)

    local gap = target - current
    local options = {}
    local seen = {}

    for i = 1, #runPool do
        local sumFirstI = SumScores(runPool, i)
        local targetPer = (target - (current - sumFirstI)) / i

        local levelExceeded = false
        local runs = {}
        for j = 1, i do
            local d = runPool[j]
            local level, base = Scoring.MetricsForScore(targetPer)
            if level > maxLevel then
                levelExceeded = true
                break
            end
            local time, newScore = Scoring.FinishTimeForScore(targetPer, level, base, d.timeLimit)
            if newScore > d.score then
                table.insert(runs, {
                    dungeon = d,
                    level = level,
                    time = time,
                    newScore = newScore,
                    oldScore = d.score,
                })
            end
        end

        if not levelExceeded and #runs > 0 then
            local cumulative = 0
            local finalRuns = {}
            for _, run in ipairs(runs) do
                table.insert(finalRuns, run)
                cumulative = cumulative + (run.newScore - run.oldScore)
                if cumulative >= gap then break end
            end

            if cumulative >= gap then
                local sig = OptionSignature(finalRuns)
                if not seen[sig] then
                    seen[sig] = true
                    table.insert(options, { runs = finalRuns, dungeonCount = #finalRuns })
                end
            end
        end
    end

    local status = #options > 0 and "ok" or "unreachable"
    return { status = status, options = options, gap = gap }
end
