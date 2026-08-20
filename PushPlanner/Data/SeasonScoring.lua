-- PushPlanner - Data/SeasonScoring.lua
-- Per-level base score table for the current season. Update this file, and
-- only this file, when a new season's scoring model needs a refresh.
--
-- WARNING: these numbers are the TWW-lineage model (section 8.1 / 11.1 of
-- scope.md). Verify them for Midnight Season 2 (12.1.0) before shipping by
-- back-solving from a couple of known live runs (see Core/Scoring.lua).

local _, PP = ...

PP.SeasonScoring = {
    seasonId = "MN_S2",

    -- Base = score for finishing that key level exactly on par time.
    baseByLevel = {
        [2] = 155,
        [3] = 170,
        [4] = 200,
        [5] = 215,
        [6] = 230,
        [7] = 260,
        [8] = 275,
        [9] = 290,
        [10] = 320,
        [11] = 335,
        [12] = 365,
    },

    -- For level > 12: Base = 185 + 15 * level
    highLevelSlope = 15,
    highLevelOffset = 185,

    -- Timing correction model (section 8.2).
    timingWeight = 37.5,
    timingCapPct = 0.4,
    overtimeFlat = 15,
}
