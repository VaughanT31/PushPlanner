# PushPlanner

An in-game port of [mythicplanner.com](https://mythicplanner.com/) /
[SamFarah/RatingCalculator](https://github.com/SamFarah/RatingCalculator).
Set a target Mythic+ rating and see the minimum keystone runs needed to
reach it, read live from your own character. No website, no login, no
typing name/realm.

Targets World of Warcraft: Midnight 12.1.0 (Curse of Ula'tek), Interface
120100. Standalone addon, no dependencies, no embedded libraries.

## Status

Scaffolded per `scope.md` (milestones M0-M5): widget toolkit and theme,
data layer, scoring/planner engine ported from the source projects, main
window, minimap button, settings panel, saved variables, localization
scaffold and attribution files are all in place.

Not yet done:
- The Season 2 score constants in `Data/SeasonScoring.lua` are the
  TWW-lineage model and are flagged there for verification against real
  12.1.0 runs (see scope.md section 11, risk 1).
- Exact API return signatures in `Core/Data.lua` should be checked against
  the 12.1.0 API dump.
- Only the addon/minimap icon (`Media/icon.tga`) is custom art so far;
  panels are still flat colour fills rather than image-based skins.
- No automated test harness wired up (section 10 of scope.md).

## Usage

- `/pp` or `/pushplanner` - toggle the planner window
- `/pp config` - open settings
- `/pp reset` - clear target rating, max level and avoided dungeons

## Credit

Calculation logic and concept ported with thanks from Mythic Planner
(https://mythicplanner.com/) and SamFarah/RatingCalculator
(https://github.com/SamFarah/RatingCalculator), MIT-licensed. Independent
in-game reimplementation, not affiliated with those projects. See
`THIRD-PARTY-LICENSES`.
