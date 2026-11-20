# The Colony: its own modules

Modules that only The Colony uses. They are written like the shared ones in `modules/` (generic: the game passes
its numbers in), but live here until a second game needs one; then it moves to `modules/` and becomes shared.
The shared modules are documented in [modules/README.md](../../../modules/README.md).

## claims.js

A map as plots, held or not. The whole map exists from the start; the player holds some rectangles of it and may claim more, one that touches what is already held at a time.

```js
const claims = createClaims({
  size: 20, cols: 7, rows: 6, held: [[2, 0], [3, 0]],
  describe: (col, row) => ({ kind: 'clay' }),                 // kept as plot.info
  price: (bought, plot) => 24 * 1.3 ** bought,
  allowed: plot => population >= 60 || 'the colony must have 60 ants',
  pay: amount => takeFromStores(amount),                       // false if it cannot be paid
  onClaim: plot => openItsSurface(plot),
});
```

| Call | Does |
|---|---|
| `held(x, y)`, `at(x, y)`, `plot(col, row)` | Is a cell held; the plot of a cell; a plot by position |
| `claimable()`, `touches(plot)` | The plots that could be claimed next |
| `priceOf(plot)`, `why(plot)` | What a claim costs now; why it cannot be tried (or null) |
| `claim(plot)` | Pay and take it: true, or a sentence saying why not |
| `bounds()` | The rectangle around everything held, in cells |

- The module refuses nothing by itself: a game asks `held(x, y)` wherever holding matters (digging, naming rooms, laying scent).
- What a plot contains is the game's. Generate it with `generateMap(world, { rect, … })`, which only touches cells inside the rectangle.
- Saved through `claims.save()` / `claims.load()`.

## foes.js

Sides, and fights between them. Agent types belong to sides; agents of different sides that come within reach of each other fight where they stand. Every so often each fighter hits the nearest enemy in reach for about its strength, and one whose health runs out is removed. Nothing is steered.

```js
const foes = createFoes({
  sides: { colony: ['worker', 'major'], rivals: ['raider'] },
  fighters: { worker: { strength: 1, health: 4 }, major: { strength: 5, health: 14 }, raider: { strength: 1.1, health: 4 } },
  reach: 0.9, every: 10, heal: 0.05,
});
foes.wave({ type: 'raider', count: 6, cells: [cell], gap: 12, init: i => { … } });   // send them in, one at a time
foes.onEvent = (kind, a, b) => { … };       // ('blow', cell), ('killed', agent, killer)
```

- A type not listed in `fighters` cannot be hit and does not hit.
- A fighter in reach of an enemy is held where it stands until the fight is over. How many can reach one enemy is decided by the room there is to stand in, so a narrow passage can be held by a few.
- `health`, `engaged`, `sideOf(i)`, `count(side)` and `killed` say how it stands. `route(side)` leads to the nearest agent of a side.
- What a side wants is not the module's business: where its agents walk and what they take are ordinary actions and tasks.

## ground.js

Ground as material. Some solid tiles can be dug: cells are marked, and a marked cell is removed a load at a time by whoever works at it from an open cell beside it. When the last load is out, the cell becomes open.

```js
const ground = createGround({ kinds: { loam: { loads: 3 }, clay: { loads: 6 } }, open: 'tunnel', perFace: 2 });
actions: [{ name: 'dig', at: ground.route, duration: 45 }]
```

| Call | Does |
|---|---|
| `mark(x, y)`, `unmark(x, y)` | Mark a cell, or take the mark away. `mark` is false for ground that cannot be dug |
| `face(cell, busy)` | The marked cell someone standing on `cell` should work at: the one beside it with the fewest already at it (`busy(c)` says how many), or -1 |
| `bite(c)` | One load out of a marked cell; the last one opens it |
| `loadsAt(x, y)`, `progress(c)`, `faces()`, `count`, `dug`, `marked`, `left` | What is marked, how far along, how much can be reached |

- It does not move anyone and does not know what a load becomes. A game's task calls `face` when an agent arrives and `bite` when it finishes.
- Only marked cells that touch open ground can be reached, so a drawn shape is dug from the open side inwards.
- **Cave-ins.** A kind may have a `span`: the widest run of open cells it stands over as a roof. `ground.settle(rnd, chance, ok)` lets each run wider than that lose one cell from its middle, with the given chance; the cell fills with the ground that was above it, and `onCave(cell)` is called. Call it now and then, with a higher chance when the ground is wet.
- Digging a cell out changes the map, so every route is brought up to date. On a 40 × 60 map that costs about 0.04 ms a time, on 140 × 120 about 0.25 ms.

## items.js

Things that exist on the map. An item has a kind and lies on a cell, in a pile, or is in the hands of an agent, who carries one thing at a time. A cell can be a **store** for a kind, with a limit; what lies anywhere else is **loose**.

```js
const items = createItems({ kinds: { soil: { slow: 0.8 }, crumb: { slow: 0.9 } }, dropAfter: 150 });
// before the simulation is built, ask for the routes the game's actions will follow:
actions: [{ name: 'eat', at: items.route('any', 'crumb'), … }]
modules: [items.module]
```

| Route | Leads to |
|---|---|
| `items.route('any', kind)` | the nearest pile of the kind, wherever it lies |
| `items.route('loose', kind)` | the nearest pile outside a store |
| `items.route('room', kind)` | the nearest store of the kind with room left |
| `items.route('stock', kind)` | the nearest store of the kind that holds some |

| Call | Does |
|---|---|
| `put(kind, cell, n)`, `take(kind, cell, n)` | Items appear on a cell, or leave the game from it |
| `setStore(kind, cell, limit)` | Make a cell a store (0: no longer one) |
| `pick(i, kind, cell)`, `drop(i, cell)` | An agent picks one up or puts down what it carries. `drop` refuses a full store |
| `give(i, kind)`, `use(i)` | Put one in an agent's hands from nowhere; what it carries leaves the game |
| `carrying(i)`, `at(kind, cell)`, `on(cell)`, `limit(kind, cell)` | What is where |
| `loose(kind)`, `room(kind)`, `total`, `stored`, `space` | Counts, kept up to date |
| `carried(kind)`, `spare(kind)` | How many are in someone's jaws now; room left once those have been put down. Open a fetching task on `spare`, not `room`, or ten ants set out for one free place |

- It moves nothing by itself. A game's tasks or rules call `pick`, `give` and `drop`.
- `slow` multiplies the walking speed of whoever carries one of the kind.
- With `dropAfter`, someone carrying a thing that has no store they can reach puts it down after that many ticks.
- Someone who leaves the game puts down what they carried.
- Piles and stores are saved through `items.save()` / `items.load()`; what agents carry is a column of the simulation and is saved with it.

## scent.js

Fields over the grid that fade. A layer holds one number per cell; agents, rules or the player add to it, and it halves every `halfLife` by itself.

```js
const scent = createScent({ layers: { trail: { halfLife: 1200, max: 3 }, gather: { halfLife: 1800 } } });
scent.watch('trail', 0.1, (cell, isAbove) => { … });            // be told when a cell crosses a strength
actions: [{ name: 'gather', at: scent.route('gather', 0.1), … }] // send agents to the cells above a strength
modules: [scent.module]
```

| Call | Does |
|---|---|
| `add(layer, cell, amount)`, `set(layer, cell, value)` | Lay scent; a cell never holds more than the layer's `max` |
| `at(layer, cell)`, `data(layer)` | Read one cell, or the whole layer |
| `watch(layer, above, fn)` | Call `fn(cell, isAbove)` whenever a cell goes above that strength or back below it |
| `route(layer, above)` | The route to the nearest cell stronger than that, for an action's `at` |

- `watch` and `route` must be asked for before the simulation is built.
- The module only keeps the numbers and fades them. What a layer means is the game's: a trail that makes a pile known, a mark that collects idle agents, a mark that makes a cell dear to cross (`world.setExtra`), a record of where agents walk.
- Layers are saved through `scent.save()` / `scent.load()`.

## tasks.js

Work posted by the world. A task is a kind of work done at places the game names with a route. Nobody holds a task as a job: each time an agent decides, it weighs every task it is able to do against its needs, takes the one that calls loudest, walks to the nearest place for it, does it, and decides again.

```js
const tasks = createTasks({ tasks: [
  { name: 'dig', at: ground.route, takes: 45, bias: 0.3,
    open: i => !items.carrying(i),                    // may this agent choose it at all right now?
    can: (i, cell) => chooseFace(i, cell),             // asked on arrival; false sends it away for a moment
    done: i => bite(i),                                // it finished
    slots: () => ground.faces() * 2 },                 // how many agents it has work for
] });
actions: [...tasks.actions, …], weights: { ...tasks.weights }, modules: [tasks.module]
```

- `bias` is how loudly the task calls an idle agent. A type can have its own in its `weights`.
- With `slots`, a task that has that many agents heading for it or doing it is closed to newcomers; those already on it carry on. This is what stops the whole crowd from setting off for one job.
- `tasks.refresh(i)` works out again what agent i may choose. The module does it every few ticks and whenever i finishes a task; call it when something `open` depends on changes for another reason.
- `tasks.doing()` and `tasks.heading` say how many agents are on each task.
- A task is an engine action, so needs still win: a hungry agent leaves the work for a meal.

## water.js

Water in dug-out ground, as one level. It is an amount, not blocks: it lies flat in the lowest space it can reach from where it comes in, its surface rises as more comes in and falls as it soaks away.

```js
const water = createWater({ wet: 'flooded', into: ['tunnel'], sources: () => waysIn(), soak: { loam: 0.002, sand: 0.008 }, dry: 0.0003, puddle: 0.01, every: 6 });
water.pour(0.25);                            // that much water (in cells) comes in
water.onFlood = cell => { … };               // a cell has gone under
water.filling(cell);                         // 0..1: how deep the water stands in a cell of the surface row (for drawing)
```

- Water runs down and sideways freely, and gets over a rise only once it stands that high: a pit below the way in fills first, a wide room takes long to fill, a hollow beyond a hump stays dry until the water tops it.
- A cell wholly under water becomes the solid `wet` tile, so nothing walks through it and routes go round; when the water leaves, the cell becomes what it was. The row the surface is in is not flooded yet.
- Each flooded cell loses `soak` of the most absorbent ground it touches, each step; the shallow top row loses `puddle`.
- A row that has flooded stays so until the level is clearly below it, so a level at a row's brim does not flood and dry it over and over.
- `volume`, `count`, `row`, `part`, `wet[cell]` say where things stand. A pool cut off from every way in stays and soaks away a cell at a time.

## weather.js

Day and night, and a run of weather. The day is a fixed length with night as its last part. The weather is one kind at a time, each lasting a while and followed by another drawn by weight; the kind that comes next is known ahead.

```js
const weather = createWeather({ day: 7200, night: 0.25, start: 'calm', quiet: 10800, warn: 1350, kinds: {
  calm: { weight: 5, lasts: [1800, 4500] }, rain: { weight: 2, lasts: [1200, 2400] } } });
weather.onEvent = (kind, what) => { … };     // 'warn' (next kind), 'begin' (kind), 'dusk', 'dawn'
```

- Read `now`, `next`, `isNight`, `hour` (0..1 through the day), `dayNo`, `left()` (ticks to the next kind) and `warned()`.
- It only keeps time. What night or rain do is the game's.

## zones.js

Areas named by the player. A zone is not a building: it has no fixed shape and no door. It is whatever open cells have been given a purpose, in any shape; cells of one purpose that touch form a room.

```js
const zones = createZones({
  kinds: { food: {}, brood: {}, rest: {} },
  onChange: (cell, kind, was) => { /* e.g. make the cell a store: items.setStore('crumb', cell, kind === 'food' ? 8 : 0) */ },
});
actions: [{ name: 'rest', at: zones.route('rest'), … }]
modules: [zones.module]
```

| Call | Does |
|---|---|
| `set(x, y, kind or null)` | Give a cell a purpose, or none. Only open ground that is not a building can have one. True if it changed |
| `at(cell)`, `open(x, y)` | A cell's purpose; whether a cell may have one |
| `cells(kind)`, `count(kind)` | Every cell of a purpose |
| `rooms()` | The rooms: `[{ kind, cells }]`, cells of one purpose that touch |
| `route(kind)` | The route to the nearest cell of a purpose, for an action's `at`. Ask before the simulation is built |

- What a purpose means is the game's: `onChange` is where a game makes a cell a store, or stops it being one.
- Zones are saved through `zones.save()` / `zones.load()`; loading calls `onChange` for every cell again.

