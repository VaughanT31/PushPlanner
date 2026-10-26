# PushPlanner

An in-game port of [mythicplanner.com](https://mythicplanner.com/) /
[SamFarah/RatingCalculator](https://github.com/SamFarah/RatingCalculator).
Set a target Mythic+ rating and see the minimum keystone runs needed to
reach it, read live from your character. No website, no login.

**New here?** The [wiki](wiki/Home.md) explains every feature step by step (also on the [website](https://ctrlshiftzed.com/wiki/push-planner/)). Questions it doesn't answer: ask on [Discord](https://discord.gg/wz7fw6jM9Z).

Targets World of Warcraft: Midnight 12.1 (Season 2). Standalone addon, no
dependencies, no embedded libraries.

## Plan for someone else

The "Plan for" picker at the top of the window plans for:

- **Me**, read live from your character.
- **Your target or a party member**, from the Mythic+ summary the game shares
  for players in your group or targeted.
- **Anyone by name** (`Name-Realm`), from the Raider.IO addon's own data when
  it's installed. Optional: nothing else needs it. Its data can be a few days old.
- **Typed in**: each dungeon's best key level and whether it was timed.

Right-click a player (unit frames, chat names, friends, guild) and pick
*Plan their Mythic+ push* to open the planner for them.

## Top parse bands

Each planned run shows the key levels the top Warcraft Logs parses of your spec
come from in that dungeon (`Data/ParseBands.lua`, small per-spec aggregates,
no player names). Built with the RecommendedStats data tools and refreshed with
each release.

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
