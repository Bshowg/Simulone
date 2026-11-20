# Regression tests

Headless runs of the games (no browser), with Node, from the project folder. Before any change to `engine/`, `kit/` or
`modules/` goes out, run them all at once with `python tools/test-all.py` (it also builds each game). None of them
asserts everything: read what they print.

| Command | What it shows | What must hold |
|---|---|---|
| `node tools/tests/town.mjs . 20 both` | 20 days of the town example with its economy | it finishes; the money total printed stays the same from day to day (2600) |
| `node tools/tests/save_test.mjs` | The Lord's Will saved mid-game and loaded into a fresh game | prints `PASS: the loaded game is the saved one` |
| `node tools/tests/village.mjs 3` | three years of The Lord's Will with a scripted steward | it finishes, people survive, the hamlet grows |
| `node tools/tests/progress_test.mjs` | the progress module on its own | it finishes without an error |
| `node tools/tests/region_test.mjs` | several lands, carts between them, saving | it finishes without an error |
| `node tools/tests/charter_test.mjs` | the late stages of The Lord's Will | it finishes without an error |
| `node tools/tests/fire_test.mjs` | fire in The Lord's Will | it finishes without an error |
| `node tools/tests/mall.mjs 4` | four days of the mall game (Atrium) with a scripted manager | prints `PASS` |
| `node tools/tests/mall_save_test.mjs` | the mall saved in the middle of a trading day and loaded into a fresh game | prints `PASS: the loaded game is the saved one` |
| `node tools/tests/mall_balance.mjs 150 7 quiet` | a scripted manager plays the mall from an empty lot (about 25 seconds; leave out `quiet` for a line a day; the second number is the seed) | prints `PASS: from an empty lot to a five-floor landmark` |
| `node tools/tests/mall_events_test.mjs` | the mall's litter, cleaner, guard, breakdowns and events, each brought up by hand and answered | prints `PASS: events and upkeep do what they say` |
| `node tools/tests/mall_floors_test.mjs` | a mall with a second floor: links, an escalator, stairs, staff upstairs, a floor cut off, save and load | prints `PASS: floors are joined, reached and left` |
| `node tools/tests/colony.mjs 3` | three minutes of The Colony left to itself, then saved and loaded | prints `PASS` |
| `node tools/tests/war_battle.mjs 4000 5 plain` | one battle of WAR, 4,000 men a side, both commanded by the computer (add `quiet` for the result only) | prints `PASS`; read the ms a tick |
| `node tools/tests/war.mjs` | WAR's campaign: a march, the battle it brings, saved and loaded mid-fight, losses back to the map | prints `PASS` |

A new game should add a scripted run of its own here, and list it in `tools/test-all.py`.
