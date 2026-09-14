-- PushPlanner - Data/SeasonScoring.lua
-- Per-level base score table for the current season. Update this file, and
-- only this file, when a new season's scoring model needs a refresh.
--
-- Verified 2026-08-31 against Mr. Mythical's rating calculator (community
-- M+ score reference for Midnight Season 2 / 12.1.0): baseByLevel and the
-- timing-bonus constants below match, except [4] was 200 and should be 185
-- (fixed here) -- the +30 breakpoint jump belongs at level 5, not 4, to
-- line up with the +5/+7/+10/+12 affix-bonus levels. overtimeFlat and
-- GetMin's over-10 floor were not independently confirmed by that source.
local _, PP = ...

PP.SeasonScoring = {
    seasonId = "MN_S2",

    -- Base = score for finishing that key level exactly on par time.
    baseByLevel = {
        [2] = 155,
        [3] = 170,
        [4] = 185,
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

    -- Keystone upgrade ("chest") tiers: fraction of the timer saved needed
    -- to earn each tier. Tier 3's threshold matches timingCapPct by design
    -- (the timing-score bonus and the 3rd upgrade cap out at the same pace).
    chestThresholds = { [2] = 0.2, [3] = 0.4 },
}
