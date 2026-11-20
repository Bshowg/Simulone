# The Lord's Will: its own modules

Modules that only The Lord's Will uses. They are written like the shared ones in `modules/` (generic: the game passes
its numbers in), but live here until a second game needs one; then it moves to `modules/` and becomes shared.
The shared modules are documented in [modules/README.md](../../../modules/README.md).

## ambience.js: a soundscape with no recordings

`createAmbience({ layers, strikes, volume, fade })` makes sound in the browser (Web Audio) and needs no audio files. It knows nothing about the engine.

A soundscape is a list of **layers**. Each has a `kind`, the options of that kind, and a `level()` function returning 0 to 1: how much of it should be heard now. The game decides what a level depends on (hour, season, what the camera sees); the module makes the sound and fades it to follow.

| kind | what it is | options |
|---|---|---|
| `noise` | a steady rush shaped by a filter: wind, water, a crowd, a fire | `filter`, `freq`, `q`, `gain`, `sway { rate, depth }` (gusts), `wobble { rate, cents }` (drifting pitch) |
| `chirps` | short sliding tones at random moments: birds, crickets, an owl | `rate`, `freq [low, high]`, `slide`, `length`, `notes [min, max]`, `gap`, `gain`, `tremolo` |
| `ticks` | short knocks at random moments: an axe, a hammer, a crackle | `rate`, `freq [low, high]`, `q`, `length`, `gain` |

`strikes` are one-off sounds by name (a bell: `{ freq, partials, length, gain }`), played with `strike(name, times, every)`.

| call | does |
|---|---|
| `start()` | begin; must be called from a tap or click (browsers allow no sound before one) |
| `stop()` | fall silent |
| `update()` | follow the levels; call every frame |
| `sleep(bool)` | hold while the page is out of sight |
| `setVolume(v)` | overall loudness |
| `levels` | the last level of each layer, by id (for testing and tuning) |

Example: [games/lords-will/sound.js](../../../games/lords-will/sound.js).

## region.js

Several maps under one game. The simulation runs one map at a time; this keeps the others.

For each land it holds a saved game to come back to, its stores, and a **book**: what each season of the year lately added to or took from those stores. Once a season the whole region moves on together: every settled land that is not being played gets that season's entry from its book, standing orders set out, and goods that have been on the road long enough arrive.

```js
const region = createRegion({ lands: LANDS, first: 'home', storage: { key: 'my-region' } });

// leaving a land (and whenever the game is saved)
region.keep(id, { snapshot: saves.snapshot(sim), stores: economy.town, caps, people: sim.count, info: { stage }, tick: sim.tick });
// going to another
const st = region.enter(otherId);        // then build that land's game, restore st.snapshot, and set its stores to st.stores
// when a season ends on the land being played
region.record(id, 'autumn', { grain: +278, firewood: +66 });
region.endSeason('autumn', { take: (r, n) => …, give: (r, n) => … });   // how to reach the live stores
```

| | |
|---|---|
| `region.hold(id)`, `region.settle(id, stores)` | The player now holds a land; a held land gets its first settlement with these stores. |
| `region.held()`, `region.land(id)`, `region.def(id)`, `region.active` | What is held, a land's state and definition, where the player is. |
| `region.send(from, to, goods, take)` | Put goods on the road now; `take` removes them from where they are. |
| `region.order(from, to, goods)`, `region.cancel(orderId)` | A standing order: the same goods every season. A land can send `maxOrders` (3). |
| `region.coming(to)` | What is on the road to a land. |
| `region.endSeason(name, live)` | Returns `{ arrived, short, lean }`: deliveries, orders a source could not fill, and lands whose book ran a store to nothing. |
| `region.state.shared` | A plain object saved with the region: give it to each land's progress module as `game`. |
| `region.save()`, `load(data)`, `write()`, `read()`, `reset()`, `clear()` | The whole region as data, saved games included. |

**Things to know.**

- It knows nothing about what a store holds or what a land is like; a land's definition (size, kind, seed) is the game's.
- A land that is not being played has no people moving in it: nobody is born, ages or dies there, and nothing is built. Only its stores change, by its book.
- A book entry is whatever the game records. Leave out anything that should stand still while nobody is looking (a treasury).
- Coming back to a land after time has passed is the game's job: restore the saved game, set the stores, move the clock on, and bring whatever follows the clock in line.

