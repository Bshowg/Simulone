# Optional modules

Generic modules that plug into the engine. The engine does not import or know about any of them; a game opts in by listing one in `modules: [...]`.

| Module | What it is |
|---|---|
| `economy.js` | Resources, what actions move, build costs, store limits |
| `progress.js` | The player's stats, level, unlocks, goals, achievements |
| `calendar.js` | Hours, days, seasons, years |
| `lives.js` | Health, mood, death, births, moving house, leaving |
| `mapgen.js` | Land from a seed (a function, not a hook module) |
| `save.js` | Saving a game and loading it back (a helper, not a hook module) |
| `events.js` | What happens to the game from outside: a table of events with odds, warnings, effects and choices |
| `policies.js` | The dials a player sets: named numbers with a range, read wherever they matter |
| `loader.js` | A loading screen over the page until the art is in and the world is laid out, on opening and on a new game (a helper for the page, not a hook module) |

## loader.js

Covers the page from the moment it is made until the game says it is ready, so the player never sees the engine's
stand-in shapes or half a world. It takes the kit's colours (`--k-bg`, `--k-ink`, `--k-dim`, `--k-line`).

```js
import { createLoader } from '../../modules/loader.js';
const loader = createLoader({ title: 'The Colony', text: 'breaking ground' });     // covering the page already
const image = await loader.track(loader.fetch('./art.png', 'fetching the drawings').then(loadArt), 'unpacking the drawings');
// …make the game and give it its sprites…
loader.ready();                                                    // waits for everything tracked, lets a frame draw, uncovers

// a new game, another map: cover, let the cover show, do the work, uncover
loader.run('a new colony', () => startOver());
```

| | |
|---|---|
| `loader.fetch(url, label)` | Downloads a file with the bar following the bytes; resolves to a `blob:` URL for it (or the URL itself if it could not be read that way). |
| `loader.track(promise, label)` | Waits for this too; the line under the title says what is being waited for. |
| `loader.ready(text)` | Waits for all of it, two drawn frames, then fades the cover out. |
| `loader.run(text, work)` | `show`, two frames so the cover is on screen, `await work()`, then `ready()`. |
| `loader.show(text)`, `loader.hide()`, `loader.say(text)`, `loader.shown` | By hand. |

A game whose art fails to load still opens, on the engine's stand-ins: the loader only waits, it does not decide.

## economy.js

An economy built on a game's existing needs, actions and buildings. You say which resources exist and what each action moves; the module keeps the books, refuses what cannot be paid for, closes what has run out, and lets wealth and scarcity steer decisions through the action matrix.

There is no built-in "money" or "goods":

- a resource that **people can hold** behaves as money (wages, prices, rent);
- a resource that **only the town holds** behaves as goods (stock that is made and used up).

List only the first kind for a money economy, only the second for a goods economy, both for both. Flows that mention a resource you did not list are ignored, so one set of definitions drives all three.

```js
import { createEconomy, flowsFromDefinitions } from '../../modules/economy.js';

const economy = createEconomy({
  resources: {
    money:     { people: true, pooled: true, start: { town: 800, person: 12 } },
    food:      { start: { town: 400 }, low: 150 },
    materials: { start: { town: 120 } },
  },
  ...flowsFromDefinitions({ buildings: BUILDINGS, work: 'work', wage: { money: 3 } }),
  wealth: { resource: 'money', comfortable: 30 },
});

createGame({
  …,
  features: economy.config.features,
  weights:  economy.config.weights,
  modules:  [economy.module, …],
});
```

### Resources

| Field | Meaning |
|---|---|
| `people` | People have a pocket of it. |
| `pooled` | Housed people share one purse per household (income goes in, anyone living there spends from it). |
| `start` | `{ town, person }`: what the town store and each starting person begin with. Newborns start with nothing. |
| `low` | Town stock under which actions that use it start to lose their pull (see Scarcity). |

### Flows

A flow moves an amount of one resource when an action starts or finishes:

```js
{ action: 'eat', at: 'canteen', when: 'start', resource: 'food', amount: 1, from: 'town', to: null, required: true }
```

- `from` / `to`: `'person'`, `'town'`, or `null`. `null` as `from` creates the amount (production); as `to` it uses it up (consumption). Between two accounts it only moves, so such a resource is conserved.
- `at`: only when the action happens at that kind of building. Omit for anywhere.
- `required` (start flows): if `from` cannot cover the amount, the person is refused entry. Without it, whatever is available moves and the action goes ahead.

You can write flows by hand, or let `flowsFromDefinitions` read them off your building definitions:

| On a building | Becomes |
|---|---|
| `serves: { action, uses: { food: 1 } }` | A visit takes 1 food from the town store. Required: no stock, no service. |
| `serves: { price: { money: 1 }, mustPay: true }` | The visitor pays the town. With `mustPay` those who cannot pay are turned away; without it the penniless get in free. |
| `makes: { food: 8 }` | Each finished work shift there adds 8 food to the town store. |
| `wage: { money: 4 }` | The town pays the worker per finished shift (overrides the default `wage`). |
| `cost: { materials: 20 }` | What the town pays to build one. |

### What it does with them

- **Refusal.** A person who cannot cover a required payment is refused at the door and gives up on that action for a while. The module also marks the action as unavailable to them in advance (`sim.deny`), so they do not walk there for nothing.
- **Closing.** A building whose required supply has run out in the town store is closed until it is back.
- **Wealth in the matrix.** With `wealth`, the module adds a per-person matrix input (default name `poor`: 1 with nothing, 0 at `comfortable`). Paid work gets a positive weight on it (`workPull`, default 0.25) and paid-for actions a negative one (`priceShy`, default 0.08). Both are ordinary matrix weights and can be overridden.
- **Scarcity in the matrix.** As a town store falls below its `low`, every action that draws on it pulls less, for everyone at once (`scarcity`, default 0.65; 0 turns it off).
- **Build costs.** `game.place` is refused when the town cannot pay and charges it when the building is placed. `game.canBuild(prefab)` gives the reason to show (`'it takes 30 twigs'`). `economy.costOf(prefab)` and `economy.canAfford(prefab)` are there for labels.
- **Store limits.** `cap` on a resource is the most the town store holds: a number, or `{ base: 400, per: { granary: 400 } }` to add room for each such building. What is made beyond it is lost and counted in `totals[r].wasted`. `economy.capOf(r)` reads it.
- **Amounts that depend on the place or the moment.** A flow's `amount` may be a function `(person, building, sim) => number`: a lodge whose yield follows the trees around it, a wage that follows a policy. It may be `required`; where there is no person or place to ask about it is called with `-1` and `null`.
- **Money that is not in use yet.** `wealth.active: () => boolean`: while it answers false nobody counts as poor. `economy.pay(person, resource, amount)` puts a resource people can hold into one person's hands.
- **Reserves.** `reserve` on a required flow from the town leaves that much in the store: a mill that never grinds the seed corn. It may be a function, for a reserve that changes with the season.
- **No room, no work.** `needsRoom` on a flow into a capped store refuses the action, and closes the place, while the store cannot take what it would make. Without it the surplus is made and lost.
- **Gifts and fines.** `economy.give(resource, amount)` adds to a town store from outside any action (negative takes).

### Reading it

| Member | Meaning |
|---|---|
| `economy.town[resource]` | The town store. |
| `economy.balance(i, resource)` | What person `i` can spend (pocket plus household purse). |
| `economy.held(resource)` | Total held by all people and households. |
| `economy.totals[resource]` | `{ made, used, moved, refused }` since the start. |
| `sim.features.poor[i]` | The wealth input, if `wealth` is set. |

### Limits

- Goods live in one town store. There is no stock per building and nothing is carried, so distance does not matter for supply.
- Buildings have no accounts of their own: prices go to the town and wages come from it.
- The total of a moved-only resource is fixed, so it ends up either with households or with the town depending on wages, prices and rent. Nothing rebalances it automatically.
- One action name covers all work, so the matrix cannot make farm work more attractive than workshop work when food is short. Who works where is still decided by the engine's nearest-first assignment.

## progress.js

The player's side of a game: stats, level, what is unlocked, goals and achievements. It is one idea used four times: **a condition on a stat**.

```js
import { createProgress } from '../../modules/progress.js';

const progress = createProgress({
  gauges: { population: sim => sim.count, food: () => economy.town.food },
  levels: [
    { title: 'first brood', when: { stat: 'born', atLeast: 20 }, reward: { grant: { twigs: 20 } } },
    { title: 'busy nest',   when: { all: [{ stat: 'population', atLeast: 80 }, { stat: 'built.nursery', atLeast: 1 }] } },
  ],
  unlocks: [{ id: 'guard post', when: { level: 2 }, text: 'reach level 2' }],
  goals: [{ id: 'dig', title: 'Dig a tunnel', when: { stat: 'laid.tunnel', atLeast: 4 }, reward: { grant: { twigs: 10 } } }],
  achievements: [{ id: 'hundred', title: 'A hundred', when: { stat: 'population', atLeast: 100 } }],
  grant: (resource, amount) => economy.give(resource, amount),
  storage: { key: 'my-game-progress' },
});
// modules: [progress.module, economy.module, …]   progress first, so "locked" is the answer before "cannot pay"
```

### Stats

A stat is a named number about the whole game. Nothing has to be declared: a stat that was never touched is 0.

| Kind | How it gets its value |
|---|---|
| Counters kept for you | `done.<action>` (each finished action), `born` and `born.<type>` (people spawned with `newborn: true`), `died` and `died.<cause>`, `built` and `built.<prefab>`, `removed` and `removed.<prefab>`, `laid.<tile>` (cells). Turn one off with `count: { actions: false }`. |
| Counters of your own | `progress.add('rescued')`, `progress.add('xp', 5)`, `progress.set(name, value)`. |
| Gauges | Functions in `gauges`, sampled every `every` ticks (30). Each gauge `g` also keeps `g.max`, its highest value. |
| `level` | The player's level. |

A stat belongs to the run unless `stats: { name: { scope } }` says otherwise. `'profile'` is kept from one game to the next (a best score, games played). `'game'` is shared by every map of one game: pass `game: someObject` (a region's `state.shared`) to the progress of each map and they all read and write the same values there; the object is the game's to keep and save. Achievements and unlocks take the same `scope`.

### Conditions

| Form | True when |
|---|---|
| `{ stat, atLeast }`, `{ stat, atMost }` | The stat is on that side of the number. Add `label` for how it reads on a page. |
| `{ level: 3 }` | The player is at least that level. |
| `{ achieved: id }`, `{ unlocked: id }` | That achievement is earned, that thing is unlocked. |
| `{ all: [...] }`, `{ any: [...] }` | All, or any, of the conditions inside. |

Anything stranger is a gauge: write the function, then put a number on it.

`progress.met(cond)` answers yes or no; `progress.progress(cond)` gives `{ done, ratio, parts }` for a bar and "63/100"; `progress.describe(cond)` gives the words.

### What hangs off a condition

- **Levels.** Either a list of steps taken in order (the player starts at level 1, each step may have a `title` and a `reward`), or a curve on a stat: `levels: { stat: 'xp', at: [100, 250, 600] }`. With a curve, `xp: { born: 5, built: 20 }` pays experience each time those counters grow, and rewards can pay it too. A level never goes down.
- **Unlocks.** List the things that start locked; everything else is unlocked. Once unlocked, a thing stays unlocked for the run even if the stat falls back. An entry without `when` is unlocked only by a reward. If the id is a prefab name, the player cannot build it until then (`lockBuilds: false` turns that off); for anything else, ask `progress.isUnlocked(id)` yourself.
- **Goals.** One at a time, in order. Useful as a tutorial. The goal shown is the first one in the list not yet met, and a save keeps the met ones by `id`, so a goal can be put anywhere in the list later. Give a goal put in after games were already saved `addedLater: true`: a save from before 0.3.1 kept only how many goals had been met, and is counted against the list without those.
- **Achievements.** Earned once, kept in the profile by default (`scope: 'run'` for per-game ones).

**Rewards** are data too: `{ xp: 50, grant: { twigs: 30 }, unlock: 'guard post', add: { stars: 1 } }`. `grant` goes through the `grant` function you give, so the module does not need an economy.

### Reading it and showing it

The module draws nothing.

| | |
|---|---|
| `progress.onEvent = (kind, item) => …` | `'level'` `{ level, title, reward }`, `'unlocked'` (the unlock entry), `'achieved'` (the achievement), `'goal'` (the goal just met). |
| `progress.setLevel(n)` | Raise the level now, whatever the conditions say, with each step's reward (a game's own trigger, or a test). |
| `progress.level`, `progress.levelInfo()` | `{ level, max, title, next: { title, when, text, progress } }`. |
| `progress.goal()` | The current goal with `n`, `of`, `text` and `progress`, or `null`. |
| `progress.unlocks()`, `progress.achievements()` | Lists with `unlocked` / `done`, `text` and `progress`. |
| `progress.get(stat)`, `progress.all()` | Stat values. |

### Keeping it

With `storage: { key }` the profile (profile stats, achievements, profile unlocks) is kept in the browser's storage and read back when a game is created; if storage is not available the game plays on without it. `progress.save()` returns `{ v, profile, run }` as plain data and `progress.load(data)` takes the profile back; pass `{ run: true }` to restore the run part as well, which only makes sense once the game itself can be saved. `progress.resetProfile()` forgets it.

### Limits

- The module saves progress only. With `modules/save.js` the run part travels with the saved game; without it a reload starts a new run with the profile intact.
- Checks happen once per sample, so something earned shows up to a second late (at once after building).
- There is no real-world time: no daily goals, nothing that happens while the game is closed.

## calendar.js

Turns ticks into hours, days, seasons and years. It decides nothing: what a season does is the game's business.

```js
const calendar = createCalendar({ day: 1800, startHour: 6,
  seasons: [{ name: 'spring', days: 3 }, { name: 'summer', days: 3 }, { name: 'autumn', days: 3 }, { name: 'winter', days: 3 }] });
// modules: [calendar.module, …]   first, so the others see a new day on the tick it begins
calendar.on('season', c => { if (c.seasonName === 'winter') … });
```

| | |
|---|---|
| `calendar.hour`, `day`, `year`, `season`, `seasonName`, `dayOfSeason`, `seasonProgress`, `yearProgress` | The current moment, kept up to date every tick. |
| `calendar.night` | 0 by day, 1 at night, sliding at dawn and dusk (`light: { dawn: [5, 7], dusk: [21, 23] }`). Multiply it into the matrix to make people sleep at night. |
| `calendar.on(kind, fn)` | Hear the start of an `'hour'`, `'day'`, `'season'` or `'year'`. Returns a function that stops listening. |
| `calendar.until(season)` | Ticks until that season next begins. |
| `calendar.at(tick)` | The same breakdown for any tick. |
| `calendar.hours(h)`, `days(d)`, `years(y)`, `HOUR`, `DAY`, `YEAR` | Game time in ticks. |
| `calendar.clock()` | `"09:30"`. |
| `calendar.gauges()` | `{ year, day, season }` functions for the progress module. |

Leave out `seasons` for a calendar of days only.

## lives.js

Whole lives: health, mood, old age, births, moving house, leaving. It was the town example's own rules file and is unchanged in what it does.

```js
const lives = createLives({
  needs: [{ name: 'hunger', kills: days(2), gloom: 1 }, …], desperate: 0.9, recovery: days(2),
  harmfulActions: { 'sleep rough': days(4) }, slowestWhenIll: 0.5, moodFollows: hours(10), homelessGloom: 0.25, joblessGloom: 0.1,
  lifespan: years(12), lifespanSpread: 0.15, startAges: [years(0.3), years(9.5)],
  family: { from, to, chancePerNight, moodNeeded }, emigration: { moodBelow, after, chancePerDay }, day: DAY,
});
```

- A need left above `desperate` wears health down at the rate its `kills` gives; at nothing the person is removed with the need's name as the cause.
- Mood follows how well needs are met. Someone unhappy for longer than `emigration.after` may leave (cause `'left'`).
- Once a day: a house with two residents of child-bearing age, a free bed and good spirits may have a child (`sim.add` with `newborn: true`), and people move house so that households keep forming.
- `gloomOf: person => number` takes mood off for the game's own reasons (poverty, short rations); a negative number lifts it.
- Read `lives.health[i]`, `lives.mood[i]`, `lives.stats`; hear `lives.onEvent('born' | 'gone', person, detail)`.

It works with the engine's `life` stages (types that follow age).

**Names and kin.** Everyone has a record that outlives them: `{ id, given, family, sex, born, died, cause, parents, partner, children }` (ticks and ids). Pass `names: { given: { f: [...], m: [...] }, family: [...] }` for names; without it people are numbered.

| | |
|---|---|
| `lives.person(i)` | The record of the person in slot `i`. |
| `lives.records[id]`, `lives.pid[i]` | Every record by id, and a living person's id. A slot changes as people come and go; the id does not. |
| `lives.slotOf(id)` | The slot of a living person, or -1. |
| `lives.kin(record)` | `{ partner, parents, children, siblings }` as records, the dead included. |
| `lives.nameOf(record)`, `lives.newFamily()` | "Given Family", and a family name nobody has yet. |

A child takes the family name of the first parent, and its two parents become partners if neither had one. People added with `sim.add(x, y, { family: 'Name' })` keep that name; anyone without one takes the name of the house they first live in. Sex only picks the list a given name comes from.

## mapgen.js

One function that lays plain tiles on a world from a seed, to call from `map.build`. The same seed always gives the same land.

```js
import { generateMap } from '../../modules/mapgen.js';
map: { width: 300, height: 300, build: world => generateMap(world, { seed: 7, steps: [
  { layer: 'forest', amount: 0.3, scale: 20, edge: 0.5 },                 // patches from smooth noise, more of them towards the edges
  { river: 'water', from: [1, 92], to: [298, 108], width: 4, wander: 0.14, ford: 'ford', fordEvery: 45 },
  { clearing: [150, 150], radius: 18, keep: ['water', 'ford'] },          // open ground to start on
  { patch: 'forest', at: [123, 141], radius: 9 },                         // one wood where you want it
  { road: 'road', from: [150, 298], to: [150, 150] },
] }) }
```

Steps run in order and only replace untouched ground (the fill tile), unless a step lists other tiles in `over`. It returns `{ seed, counts, fords, roads }`. It knows nothing about what the tiles mean, and makes rectangles of any size.

## save.js

Takes a running game apart into plain data and puts it back. It keeps the map (every plain tile, every building and whatever a game has written on it), the people (all per-person values, a game's own columns included) and each module's own part.

```js
import { createSave } from '../../modules/save.js';
const saves = createSave({ key: 'my-game-save', version: 1 });

const data = saves.read();                       // on the device, or null
if (!data || !saves.restore(sim, data)) populate(sim);
calendar.on('day', () => saves.write(sim, { camera: { ...game.camera } }));   // when to save is the page's call
```

| | |
|---|---|
| `saves.snapshot(sim, extra)` | The game as JSON-safe data. `extra` is anything of the page's own (camera, speed); it comes back as `data.extra`. |
| `saves.restore(sim, data)` | Put it back into a simulation built from the same config, replacing its map and people. Returns `false`, changing nothing, if the data is another `version` or map size. |
| `saves.write(sim, extra)`, `saves.read()`, `saves.clear()` | The same through the browser's storage under `key`. `write` returns `false` when storage is not available. |

**What a module does to be saved.** Per-person values and anything written on a building are saved without the module doing anything. For the rest, a module puts `save(sim)` and `load(data, sim)` on its hook object. The calendar, economy, progress and lives modules do; `load` is also called when the data has nothing for that module, so it can bring itself in line with the restored tick.

**Things to know.**

- Buildings are put back in the order they were built and get new ids; people's homes and jobs are pointed at the new ids.
- Restoring on top of a new game is how to load, and restoring a snapshot taken at the start is a way to start over without reloading the page.
- A loaded game is the saved game, but it does not then play out tick for tick like the original would have: positions are kept to six decimals and building ids are renumbered.
- Raise `version` when a change to tiles, prefabs, needs, actions or types makes old saves unusable. There is no migration.
- A 300 × 300 map with a dozen buildings and 16 people is about 23 KB and takes about 10 ms to save.

## slots.js

Saved games by hand. A game keeps itself on the device under a few storage keys; a slot is a copy of all of them at one moment, and loading one writes them back and reloads the page, which then starts from them as it would from its own save. It knows nothing of the game, so whatever a game keeps, a slot keeps. The same copy can be had as a **save code** (text to copy, paste back, or take to another device), and a game can be shipped with a ready-made one: a **showcase**.

```js
import { createSlots } from '../../modules/slots.js';
const slots = createSlots({ game: 'my-game', keys: ['my-game-save', 'my-game-progress'], flush: () => save(), describe: () => `day ${day}` });
if (await slots.takeShowcase('./showcase.txt')) await new Promise(() => {});   // first thing, before the game reads its keys
function save() { if (slots.leaving) return; /* … */ }                          // never save over a game being loaded
// in a menu: ui.full(slots.panel()); slots.wire();
```

| | |
|---|---|
| `slots.panel()`, `slots.wire()` | `{ title, html, button }` for the kit's full-screen panel, and the call that makes its buttons work once it is shown: three slots (save here, load), the undo slot, and copy / paste a save code. Replacing a slot or loading takes a second tap. |
| `slots.save(n)`, `slots.load(n)`, `slots.remove(n)`, `slots.list()` | The same from code. `load` also takes `'undo'`. |
| `slots.code()`, `slots.fromCode(text)` | The game as a save code (`SIMULONE1:<game>:<data>`), and loading one; `fromCode` resolves to `false` with `slots.why` set if the code is not for this game. |
| `slots.takeShowcase(url)` | If the address ends in `#showcase`, put the save code at `url` in place of the player's game and reload without the `#showcase`. The player's game is kept in the undo slot first. |
| `slots.leaving` | True once a load has begun: from then on the page must not save. |

**Things to know.** Everything is kept gzipped and in base64 where the browser has `CompressionStream` (plain JSON where it has not), so a slot of a big settlement is a few hundred KB at most. Before anything is put back, the game as it was goes into the undo slot, so a load is never a loss. The keys are written again on `pagehide`, after anything the game still saves on its way out. All games on one site share the browser's storage (about 5 MB), so a page should not offer many more slots than three.

## events.js

A director: it decides when things happen to the whole game. It changes nothing itself.

```js
const events = createEvents({ events: [
  { id: 'bad harvest', title: 'A bad harvest', text: 'every cell reaped gives two thirds',
    when: () => calendar.seasonName === 'summer', chance: 0.06, every: DAY,           // looked at once a day, in summer
    warn: () => calendar.until('autumn'), lasts: () => calendar.seasonTicks('autumn'), rest: YEAR,
    mods: { yield: 0.67 } },
  { id: 'travellers', title: 'Travellers', text: 'a family asks to settle', chance: 0.1, every: DAY, warn: DAY, otherwise: 'refuse',
    choices: [{ id: 'settle', label: 'let them settle', run: () => rules.welcome(1) }, { id: 'refuse', label: 'send them on', run: () => {} }] },
] });
```

An event goes idle → announced (its warning runs) → active → idle. One with `choices` waits in "asking" until `events.choose(id, choiceId)` or until the warning runs out, when `otherwise` is taken.

| | |
|---|---|
| `mods` and `events.mod(name)` | Named factors in force while an event is active. The game multiplies by `events.mod('yield')` wherever that number matters; several events multiply together; 1 when none. |
| `start`, `end` | Functions of the game's, for anything that is not a factor. |
| `events.current()` | What is announced, asking or active: `{ event, status, startsIn, endsIn }`. |
| `events.onEvent = (kind, event, choice) => …` | `'announced'`, `'asking'`, `'chosen'`, `'started'`, `'ended'`. |
| `events.trigger(id)` | Bring one up now, whatever its odds. |

`when` is any function, so the calendar, the stage or a stock level can all gate an event. Odds are rolled on the simulation's own generator. State is saved with the game.

## policies.js

The handful of settlement-wide dials a player sets. A policy is a named number with a range; the module keeps the values, clamps what the player asks for, and saves them with the game. It decides nothing about what a policy means.

```js
const policies = createPolicies({ policies: [
  { id: 'rations', title: 'Rations', text: 'grain in every bowl', min: 0.7, max: 1.3, step: 0.1, value: 1,
    words: v => (v < 1 ? 'short' : v > 1 ? 'generous' : 'full') },
  { id: 'wage', title: 'Wage', min: 0, max: 4, value: 2, unit: 'coin a shift', when: () => progress.level >= 3 },
] });
// modules: [policies.module, …]
// and wherever the number matters:
{ action: 'work', when: 'finish', resource: 'coin', amount: () => policies.get('wage'), from: 'town', to: 'person' }
```

| | |
|---|---|
| `policies.get(id)` | The value now. Read it in a flow's `amount`, in a mood, in a rate. |
| `policies.set(id, value)`, `policies.nudge(id, steps)` | Change one; the value is brought into its range and onto its steps. |
| `policies.list()` | The ones that are the player's to set now (`when`), with `value`, `min`, `max`, `step` and `words` for a page to draw. |
| `apply: value => …` on a policy | For a policy that has to push its value somewhere: called when it changes, at the start, and after a load. |
| `policies.onChange = (policy, value) => …` | After the player changes one. |

## Modules that live with their game

A module only one game uses lives in that game's folder until a second game needs it:

- The Lord's Will: ambience.js, region.js in [games/lords-will/modules/](../games/lords-will/modules/README.md)
- Atrium: floors.js, reputation.js, staff.js, trade.js, upkeep.js, visitors.js in [games/mall/modules/](../games/mall/modules/README.md)
- The Colony: claims.js, foes.js, ground.js, items.js, scent.js, tasks.js, water.js, weather.js, zones.js in [games/ant-colony/modules/](../games/ant-colony/modules/README.md)
- WAR: campaign.js, combat.js, general.js, morale.js, regiments.js in [games/war/modules/](../games/war/modules/README.md)

