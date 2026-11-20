# Atrium: its own modules

Modules that only Atrium uses. They are written like the shared ones in `modules/` (generic: the game passes
its numbers in), but live here until a second game needs one; then it moves to `modules/` and becomes shared.
The shared modules are documented in [modules/README.md](../../../modules/README.md).

## floors.js

Several levels in one simulation. The levels lie side by side on the one grid, each a rectangle the game gives; a level that is not built yet is solid. Levels are joined by connectors: a few cells at the same place on two neighbouring levels with the engine's links between them (`world.addLink`), so people step from one level to the next and routes are found through them. The view shows one level at a time.

```js
const floors = createFloors({
  count: 5, rect: k => [k * 32 + 1, 1, k * 32 + 30, 22],     // where each level lies: [x0, y0, x1, y1], inclusive
  closed: 'void',                                             // the solid tile an unbuilt level is made of
  connectors: {
    escalator: { ticks: 40, cost: 30, cells: [{ dx: 0, dy: 0, tile: 'escalator up', way: 'up' }, { dx: 1, dy: 0, tile: 'escalator down', way: 'down' }] },
    stairs:    { ticks: 90, cost: 90, cells: [{ dx: 0, dy: 0, tile: 'stairs', way: 'both' }] },
  },
});
// map.build: fill every level but the first with the `closed` tile.   modules: [floors.module, …]
```

| Call | Does |
|---|---|
| `open()` | Builds the next level: its rectangle becomes open ground. `built` is how many there are |
| `canConnect(kind, level, lx, ly)`, `connect(…)` | Puts a connector between `level` and the one above, at a place local to the level. It needs the same cells free on both. `connect` lays the tiles and makes the links |
| `at(x, y)`, `disconnect(connector)`, `list` | The connector with a cell there (on either level); taking one out; all of them |
| `kindAt(cell)` | The kind of connector a cell belongs to: with the engine's `onLink` hook, what someone has just ridden |
| `reach(from)` | For every built level: can it be got to from `from`, and can one get back? A level with `there` and no `back` is a trap |
| `pause(connector, stopped)` | Stops a connector carrying people (a breakdown, a power cut) or starts it again. Its cells stay |
| `show(level, renderer, pad)`, `shown` | Draws that level only (`renderer.setRegion`) and keeps the camera to it |
| `of(x, y)`, `cell(level, lx, ly)`, `local(x, y)`, `crowd()` | Which level a cell is on; between grid and level places; how many agents are on each level |

- A connector's cells are plain walkable tiles the game defines; `ticks` is how long the step takes and `cost` what it counts for in a route (4 is one cell of walking).
- Keep levels a multiple of 32 cells apart (the engine's routing sector), and no larger than 32 × 32 with their gap: routes to a person's own building are then found level by level.
- The module costs nothing while people walk: links live in the engine. It is saved with the game; the links are made again on load.

## reputation.js

One slow-moving rating made from many scores, and what it is worth. Scores come in one at a time (a visit, a delivery, a match); when the game closes a day the rating moves part of the way to that day's average, less if the day had few scores. The game reads a factor off a curve it gives. What the factor is used for is the game's.

```js
const reputation = createReputation({ start: 3, follow: 0.35, enough: 20,
  worth: [[0, 0.25], [3, 0.85], [3.5, 1], [5, 1.5]] });   // points [rating, factor]
visitors.onLeft = rec => reputation.add(rec.score);
// at the end of a day:   const moved = reputation.endDay();   // { n, average, before, rating }
// wherever it matters:   visitorsToday = base * reputation.factor();
```

| | |
|---|---|
| `reputation.rating` | The rating now. It only changes in `endDay()`. |
| `reputation.add(score)`, `average()` | One more score today; today's average so far. |
| `reputation.endDay()` | Moves the rating `follow` of the way to the day's average (in proportion, with fewer than `enough` scores). |
| `reputation.factor(rating?)` | What a rating is worth, read between the `worth` points. |
| `reputation.held(mark)` | How many of the latest days in a row ended at `mark` or better. |
| `reputation.shift(delta)` | Move the rating now, for the game's own reason (a fine, a prize). |
| `reputation.days` | Closed days, newest first: `{ n, average, rating }`. |

It has no hooks; it is a module only so that it is saved with the game.

## staff.js

People who come in for a shift, work it in the building that hired them, and go home. The game says how many posts a building has and when a shift runs; the module keeps that many staff at each building while it does, and counts their time so the game can pay them.

```js
const staff = createStaff({
  type: 'staff', offType: 'off duty',         // engine types: `works: true` on shift, `works: false` on the way home
  leave: 'leave',                             // the action that takes them out
  gates: sim => [[16, 21]],                   // the cells they appear on
  posts: building => POSTS[building.name] ?? 0,
  onDuty: sim => open,                        // is a shift running?
  turnOut: (building, sim) => staff.hired(building),   // optional: how many come in today
});
// types: [{ name: 'staff', works: true, grow: {…all 0} }, { name: 'off duty', works: false }]
// actions: [{ name: 'work', at: '@job', duration: 300 }, { name: 'leave', at: 'entrance' }]   modules: [staff.module, …]
```

- A new building has every post filled (`start` sets another number). `staff.hire(b, n)` changes it; `staff.hired(b)` reads it.
- When a shift starts, each building's staff appear at a gate with that building as their job and walk to it. The engine's own jobs do the rest: a building with posts and nobody working is shut, and one that is short-handed holds proportionally fewer customers. A building nobody is hired for is closed with the reason `'staff'`.
- When the shift ends they finish the stretch of work they are on, turn into the off-duty type, walk to the `leave` action and are removed. Someone let go in the middle of a shift goes the same way.
- `staff.endDay()` returns `[{ building, ticks }]`, the time on shift since the last call; `staff.ticksToday(b)` reads it as it grows. What an hour costs is the game's.
- `staff.today(b)` is how many are in today, `staff.present(b)` how many are at work right now, `staff.count` everyone in the building, `staff.is(i)` whether person `i` is on shift.
- **Staff who walk the place.** `roam: building => typeName` names an engine type (with `works: false`) for a building whose staff do not work inside it: a cleaner, a guard. They come and go with the shift and are counted and paid like the others; their building is in `sim.target`. What they do out there is the game's: actions and that type's weights.

**Things to know.** The work action may be as long as the shift, so that staff stay inside all day: when the shift ends (or someone is let go) whoever is at work is made to finish at once. Staff are told apart from other agents by the `staff` column. What a building has hired, who came in today and the time worked sit on the building, so they are saved with the map.

## trade.js

A building sells to whoever is served there. The game says which actions are sales and what each costs; the module takes the money from the buyer's purse as they go in, turns away those who cannot pay, and keeps an account on every building.

```js
const trade = createTrade({
  sells: ['have a coffee', 'shop for clothes'],
  price: (i, action, building, sim) => PRICE[action] * levelOf(building),
  buyer: i => visitors.is(i),                                   // who pays at all (default: everyone)
  income: (amount, building) => economy.give('money', amount),  // where takings go
  onRefuse: (i, action, building, why) => visitors.drop(i, NEED[action], why),   // why: 'price' or 'stock'
  stock: { room: b => SHELF[b.name], cost: b => UNIT_COST[b.name] },             // optional
});
```

- **Purses** are a per-person column kept by someone else (`purse` by default; `modules/visitors.js` has one).
- **Accounts.** `trade.books(b)` is `{ day, all }`, each `{ sales, takings, turned, goods, short }`: sales made, money taken, people turned away by the price, the cost of the goods sold, people turned away by an empty shelf. `trade.endDay()` returns the day's line for every building and starts a new day; `trade.takings()` is today's total so far.
- **Stock.** With `stock`, a building with `room` holds goods (`b.stock`). A sale uses some (`uses`, default 1); with none left the building is closed (`world.setBlocked(b, true, 'stock')`) until `trade.deliver(pay)` fills the shelves, asking `pay(cost, building)` for each one (`false` skips it, a share between 0 and 1 takes part of it). `least` is the stock under which a building shuts (the goods its smallest sale takes). A building with no room never runs out.
- Accounts and stock sit on the buildings, so they are saved with the map.

## upkeep.js

Things that wear a place down, and the work of putting them right: litter on the floor, and buildings that break. Both are plain bookkeeping: when litter falls, what breaks and what either costs are the game's.

```js
const upkeep = createUpkeep({ field: 'litter', clean: 'clean', above: 1, max: 4, reach: 1 });
// actions: [{ name: 'clean', at: upkeep.route, duration: 30 }]   modules: [upkeep.module, …]
upkeep.drop(sim.cell[i]);          // the game drops litter where someone stands
upkeep.break(building);            // closed, for the reason 'broken'…
upkeep.mend(building, 600);        // …and working again 600 ticks from now (0: at once)
```

| Call | Does |
|---|---|
| `drop(cell, n)`, `at(cell)`, `near(cell)` | Litter on a cell (to `max`); what lies there; the most on it or the four cells beside it |
| `route` | The route to the nearest cell with `above` or more: the cleaning action's `at` |
| `sweep(cell, r)`, `clear()` | Clear a cell and those around it (done by itself when someone finishes the `clean` action); clear everything |
| `dirty`, `cleaned`, `endDay()`, `cells(rect)` | Dirty cells now; cells cleaned since `endDay()`; the dirty cells as `[x, y]`, for drawing them |
| `break(b)`, `mend(b, after)`, `broken()` | A building breaks and closes; it is mended now or later (`onMend` is told); what is broken |

Litter is saved by the module; what is broken sits on the buildings and is saved with the map.
## visitors.js

People who come, stay a while and go. A visitor is an ordinary agent with a few values of its own: what they came for, what they can spend, when they must go. The module brings them in at a rate the game gives, sends them home, scores the visit and counts what happened. What a wish is, what things cost and what a score does are the game's.

```js
const visitors = createVisitors({
  kinds: [{ name: 'shopper', type: 'shopper', purse: [40, 170], stay: [720, 1560], patience: 400,
            wishes: { count: [2, 4], of: { clothes: 3, books: 2, hunger: 1.5 } } }],
  needs: { clothes: { wish: true }, books: { wish: true },                       // only ever a wish: nothing unless they came for it
           hunger: { wish: true, lasting: true, start: [0, 0.35], comfort: 0.8 },  // builds up while they are in, wish or not
           toilet: { lasting: true, comfort: 1.2, urgent: true } },
  leave: 'leave',                              // the action that takes them out; the game defines it, at its exits
  gates: sim => [[16, 21]],                    // the cells they appear on
  rate: sim => (open ? 0.02 : 0),              // arrivals per tick right now
  score: { base: 2.4, met: 2.6, missed: 1.4, queued: 1 / 600 },
});
// actions: [{ name: 'leave', at: 'entrance' }, …]   modules: [visitors.module, …]
```

- **Wishes.** Each visitor arrives with a few of the needs marked `wish`, picked by their kind's weights (`wishWeight` can scale a weight by the moment: nothing to buy it from, nothing to wish for). A wish is met when the visitor finishes an action that ends on that need. A wish with nowhere open to go for `lookFor` ticks is given up as `'none'`; `visitors.drop(i, need, why)` gives one up for the game's own reason (too dear, sold out), and `visitors.note(i, need, why)` records a reason while they keep trying. A wish given up at a full door is noted as `'queue'`.
- **Going home.** When no wish is left (and no `lasting` need with a `comfort` that somewhere open could settle is pressing), when `stay` is over, when they have queued longer than `patience`, or when an `urgent` need is at its top with nowhere to settle it. A visitor who is going can choose nothing but the `leave` action; arriving at it removes them. `sendAll(reason)` sends everyone (closing time) and `clear(reason)` takes out whoever is left.
- **The score.** `base + met × (share of wishes met) − missed × (share missed) − queued × ticks queued − walked × ticks walked`, less something for each lasting need with a `comfort` left above `from` (0.6): nothing at `from`, the whole `comfort` at 1. Such a need is seen to before going home from `settle` (0.15 under `from`), and counted as a complaint from 0.15 over it. Plus whatever the game added with `visitors.nudge(i, delta, gripe)`; the whole kept between `min` and `max`.

| | |
|---|---|
| `visitors.onLeft = rec => …` | Every departure: `{ kind, reason, score, spent, met, missed: [[need, why]], stayed, queued }`. |
| `visitors.tally`, `visitors.endDay()` | Counts since the last `endDay()`: `arrived`, `gone`, `byKind`, `left` by reason, `met` by need, `missed` by need and reason, `gripes` by key (`'books:none'`, `'toilet:unmet'`, `'queue'`, and the game's own), `scoreSum`, `spent`. `endDay()` returns them and starts again. |
| `visitors.recent` | The latest departures, newest first. |
| `visitors.count`, `byKind()` | Who is in now. |
| `visitors.is(i)`, `kindOf(i)`, `info(i)`, `scoreOf(i)` | One visitor: their kind, their wishes and how each stands, purse, time left, the score they would give now. |
| `visitors.idOf(i)`, `slotOf(id)` | A number that stays with a visitor while their slot changes. |
| `sim.purse[i]`, `sim.mood[i]` | Columns other modules read and write: what is left to spend, and what has been added to the score. |

**Limits.** People who are not visitors (staff) are left alone: only agents added by the module are counted. There are at most 31 needs. Visitors do not know each other: a family is one agent with a fuller purse.

