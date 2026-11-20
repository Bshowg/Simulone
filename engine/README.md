# agent-matrix-engine

Many simple autonomous agents that satisfy their needs in a town of placed buildings, drawn as isometric sprites.

- **Decisions:** `scores = features(agent) × matrix(agent type)`, best score wins. Matrices are rebuilt from design values every few ticks, adjusted for the state of the world.
- **Agents:** besides their type, each stores a `home`, a `job` and a `speed`.
- **Buildings:** solid prefabs with a door. Agents walk to the door, go inside and come out at the exit. A building holds a fixed number of customers; the rest queue outside.
- **Crowd-driven building art:** agents inside are not drawn. Each building's image is chosen by how full it is.
- **Age:** the action matrix can vary continuously with a person's age, blended between a few points you define.
- **Room for a game's own rules:** per-person values of your own, adding and removing people during play, and a hook every tick. Health, death, births and the like are not here: they are an optional module (`modules/lives.js`) or a game's own file.
- **Streets:** cheaper to route across and faster to walk on, so agents prefer them without being forced to; idle agents stroll along them.
- **Build mode:** the simulation pauses while the map is edited. On exit, routes are recomputed in the background while the game keeps running on the old ones.
- **Movement:** free (any direction), steering along distance fields, with crowd separation.
- **Drawing:** WebGL2, one instanced draw call, depth buffer for overlap.
- **No build step, no dependencies.** Plain ES modules; serve the folder and import `engine/index.js`.

## Quick start

```html
<canvas id="cv" width="768" height="512"></canvas>
<script type="module">
import { createGame } from './engine/index.js';

const game = createGame({
  canvas: document.getElementById('cv'),
  agents: 60,
  prefabs: [
    { name: 'house',   w: 3, h: 3, beds: 6, color: '#b9bfa6' },
    { name: 'canteen', w: 4, h: 4, jobs: 3, capacity: 8, color: '#e6cf8f' },
  ],
  map: { width: 40, height: 30, build(w) { w.place('house', 4, 4); w.place('canteen', 28, 18); } },
  needs: [{ name: 'hunger', grow: 0.0008 }, { name: 'fatigue', grow: 0.0005 }],
  actions: [
    { name: 'eat',   at: 'canteen', effects: { hunger: -0.010 } },
    { name: 'sleep', at: '@home',   effects: { fatigue: -0.006 } },
    { name: 'sleep rough', onlyIf: 'homeless', effects: { fatigue: -0.0015 } },
    { name: 'work',  at: '@job', duration: 300 },
  ],
});
game.tool = (x, y, phase) => { if (phase === 'down') game.place('house', x, y); };   // tap to build
</script>
```

Modules need a web server, not `file://`. Use `python tools/serve.py` in the project root: it serves on port 8765 with caching off. (A plain `python -m http.server` lets browsers keep stale copies of the engine files after you edit them.)
Working examples:

- `examples/minimal/`: the smallest setup.
- `examples/colony/`: a stress test with map sizes up to 960×640 and a benchmark. Everything in it is fast on purpose.
- `examples/anthill/`: an ant nest seen from the side. Tunnels dug through solid earth, chambers carved beside them, castes that each do one job, and a queen who is the only one to make new ants. It uses the flat view, a solid-fill map and jobs by type; its numbers are in `nest.js` and its colony rules in `rules.js`.
- `examples/daylife/`: a town at a believable pace, with a day and night cycle, whole lives and an economy of goods and money. Its numbers are in `town.js`; lives and the economy are the generic `modules/lives.js` and `modules/economy.js`.
- `games/lords-will/`: the first full game, at its first stage (see `docs/GDD.md`). A hamlet on generated land, with seasons, fields dragged out to size, a common store and the first winter. Numbers in `hamlet.js`, its own rules in `rules.js`.
- `games/war/`: battles of thousands. Every soldier is an agent whose actions are points (`@point`): his slot in a formation, the enemy he goes for, the edge of the field behind him. Orders and what he sees are matrix inputs of the game's own. Numbers in `war.js`, battle rules in `rules.js`.

## Config

| Key | Meaning |
|---|---|
| `canvas` | The `<canvas>`. Its `width`/`height` attributes are the render resolution. |
| `agents` | Starting population (default 1000). |
| `maxAgents` | Array capacity (default 20000). |
| `map` | `{ width, height, fill, build(world) }`. The outermost ring of cells is solid and invisible: the ground just ends. `fill` names the tile the map starts as (default: open floor); see Dug-out maps. |
| `floor` | `{ color, color2? }` for empty ground; `color2` adds a 4×4 checker. |
| `tiles` | Plain tile kinds such as streets, see below. Optional. |
| `prefabs` | Buildings that can be placed, see below. |
| `needs`, `actions`, `types` | See below. `types` is optional: one plain type by default. |
| `weights` | Matrix overrides for all types: `{ action: { feature: value } }`. |
| `tuning` | Overrides for `DEFAULT_TUNING` in `sim.js` (speed, pace, queueing, separation…). |
| `sprites` | Real art (see Sprites). Omit for generated placeholders. |
| `view` | `{ projection: 'iso', tileW: 16, tileH: 8, background, ink, minZoom, maxZoom, maxGroundSize, doorLinger }`, or `{ projection: 'flat', cell: 16, … }`. See Views. |
| `renderer` | A view class of your own, instead of the two built in. See Views. |
| `ticksPerSecond` | Simulation ticks per real second at speed 1 (default 60). See Time. |
| `life` | `{ stages, steps }`: blend the matrix across ages. See Age. |
| `seed` | Random seed; the same seed gives the same run. |
| `spawn` | `'buildings'` (default) or `'anywhere'`: where new agents appear. |
| `fieldBudgetMs` | Milliseconds of background route work per frame (default 2). |
| `maxWindowCells`, `maxSectorCells` | Memory caps for routes, in cells of 2 bytes (defaults 40 and 4 million). |
| `onFrame(game)` | Called after every drawn frame. |
| `onSpawn`, `onTick`, `onStart`, `onFinish`, `onGone`, `onRebuildMatrix` | The same hooks given directly in the config; together they act as a first module. |
| `modules` | A list of independent rule modules, each implementing the hooks it needs. See Your own rules. |
| `features` | Names of extra per-person inputs to the matrix, written by modules (for example `'poor'`). See Your own rules. |
| `autostart` | `false` to create the game without starting the loop. |

### Prefabs (buildings)

```js
{ name: 'house',   w: 3, h: 3, beds: 6, color: '#b9bfa6' }
{ name: 'canteen', w: 4, h: 4, jobs: 4, capacity: 16, door: 'S', exit: 'E', color: '#e6cf8f', height: 16 }
```

A prefab is a building type; `world.place(name, x, y, rot)` creates one building from it. The footprint is **solid**: agents walk around it.

- `beds`: how many agents can live there.
- `jobs`: worker slots. A building with jobs is **closed until at least one worker is assigned**. A building with no jobs is always open.
- `staff`: names of the types that may work there, for example `['nurse']`. Without it, anyone whose type works can.
- `capacity`: customers it holds when fully staffed. With fewer workers it holds proportionally fewer (at least one). Arrivals beyond that queue at the door.
- `door`: the side the entrance is on before rotation: `'N'`, `'E'`, `'S'` (default) or `'W'`, or `{ side: 'S', at: 1 }` to choose the cell along that side.
- `exit`: same form; defaults to the door. A separate exit lets people flow through instead of meeting head-on.
- `color`, `height`: placeholder art only (roof colour, wall height in pixels).
- `resize: { min: [w, h], max: [w, h] }`: the player drags out its footprint (a field, a yard). `perCell: { jobs: 1 / 14, beds: 0 }` then sets jobs and beds from its area. See below.
- `flat: true`: no image; it is painted on the ground in its colour. `outdoor: true` does the same and also shows the people in it, spread over the footprint (in a field, on a green).

A building can only be placed on untouched ground: open floor, or the map's `fill` tile.

The **entry cell** is the ground cell just outside the door, and the **exit cell** the one outside the exit. Both must be walkable, nothing can be built on them (streets can run over them), and no two buildings share an entry cell.

Rotation `rot` is 0-3 quarter turns clockwise, or `'auto'` (the default): the rotation that fits and puts the door closest to a street within 10 cells, else the first that fits.

**Dragged buildings.** For a prefab with `resize`, pass the size as a fifth argument: `game.place('field', x, y, rot, [w, h])`, where (x, y) is the footprint's corner. `world.sizeFor(name, w, h)` gives the size a drag is allowed to take: cut down to `max`, or `null` below `min`. `game.canPlace` and `game.footprint` take the same argument. Placed without a size it uses its `w`, `h` and `jobs` like any other prefab. A resizable prefab is always painted on the ground.

Each building is an object in `world.buildings` (by id; `null` once demolished):

| Field | Meaning |
|---|---|
| `x, y, w, h, rot` | Footprint and rotation. |
| `ex, ey` / `xx, xy` | Entry and exit cells. |
| `beds, jobs` / `residents, workers` | Capacity for, and number of, agents assigned. |
| `open`, `staff` | Whether it is staffed, and `workers / jobs`. |
| `cap`, `customers` | Customers it can hold now, and how many are inside. |
| `inside` | Everyone inside: customers, workers at work, residents asleep. |
| `load` | Smoothed fullness 0..1 (`inside` over everything it can hold). Drives the crowd level of its image. |
| `area` | Cells it covers. |
| `color` | Optional, yours to set: a colour of its own for a building painted on the ground (a ripening field). Add 1 to `world.version` afterwards so it is repainted. |

`jobs` and `beds` on a building may be changed while playing (a field with nothing to do offers no work); add 1 to `world.version` and the next tick reassigns people.

### Tiles

Plain cells, set with `world.set`, `world.rect` or `world.line`. Walls are no longer needed, since buildings are the obstacles, but solid tiles still work.

- `solid`: blocks walking. `block`: height in pixels of its generated placeholder block (isometric view).
- `color`, `color2`: its colour on the ground; in the flat view `color2` is scattered over it so large areas are not flat.
- `walkCost`: routing cost relative to ordinary ground (default 1). Below 1, routes bend towards the tile.
- `speed`: walking speed multiplier while standing on it (default 1).
- `street`: idle agents within `tuning.strollRange` cells walk to these tiles and stroll along them.

```js
{ name: 'street', color: '#cdc6b0', walkCost: 0.5, speed: 1.6, street: true }
```

### Dug-out maps

With `map.fill` set to a solid tile, the map starts solid and is dug out instead of built on:

```js
tiles: [{ name: 'earth', solid: true, color: '#8a6844' }, { name: 'tunnel', color: '#e0cda6', street: true }],
map: { width: 40, height: 60, fill: 'earth', build: w => { w.line('tunnel', 20, 8, 20, 50); w.place('larder', 31, 18); } },
```

- `world.line(tile, …)` replaces only the fill tile, so a tunnel is a street dug through earth.
- A building replaces fill tiles too, and its entry cell must already be walkable: a chamber can only be carved where its opening meets a tunnel. `'auto'` rotation finds the turn that does.
- `world.demolish` puts the fill tile back, so removing a tunnel or a chamber fills it in. A cell that is some building's entry cannot be filled.
- Nothing else changes: routes, streets, strolling and build mode work as on an open map.

With `walkCost: 0.5` an agent takes a street whenever the detour is less than twice the direct path. Keeping `walkCost` near `1 / speed` makes that preference match real travel time.

### Needs

```js
{ name: 'hunger', grow: 0.0008, weight: 1.2 }
```

A need runs from 0 (satisfied) to 1 (desperate) and rises by `grow` per tick. `weight` is how much agents care (default 1). The score uses the need **squared**, so urgent needs dominate. `max` (default 1) stops a need building up short of desperate: it still draws people to what answers it and can weigh on mood, but it never breaks off their work or sleep the way a desperate need does. Use it for wants that should not become emergencies.

### Actions

```js
{ name: 'eat',   at: 'canteen', effects: { hunger: -0.010 } }   // nearest open canteen, as a customer
{ name: 'sleep', at: '@home',   effects: { fatigue: -0.006 } }  // the agent's own home; unavailable if homeless
{ name: 'work',  at: '@job',    duration: 300 }                 // the agent's own workplace; unavailable if jobless
{ name: 'sleep rough', onlyIf: 'homeless', effects: { fatigue: -0.0015 } }   // on the spot, only without a home
{ name: 'wander' }                                              // idle; added automatically if missing
```

- `at`: a prefab name (nearest open one), `'@home'`, `'@job'`, `'@target'`, `'@point'`, a plain tile name, or nothing (done where the agent stands).
- `effects`: change per tick to each need **while performing**, which for buildings means while inside.
- The action ends when its most strongly reduced need reaches 0 (override with `until: 'need'`), or after `duration` ticks. The agent then steps out onto the exit cell.
- `onlyIf`: `'homeless'`, `'housed'`, `'jobless'` or `'employed'`. Agents that don't match never pick the action.
- `interruptible`: the action is broken off when another need reaches `tuning.interruptAbove` (0.9) and something else now scores higher. Use it for long activities (sleep, work, leisure); a meal or a drink should be seen through, or people run back and forth between two urgent needs and finish neither.
- `needsPace`: how fast all needs build up while performing, as a fraction (for example 0.2 while asleep).
- `color`: placeholder body colour.

**Queueing.** An agent that reaches the door of a full building steps a little aside and then stands still until there is room. A standing agent does no steering and no pushing, so a large queue costs almost nothing. After `tuning.queuePatience` ticks (200) it gives up and will not choose that action again for `tuning.giveUpTicks` (600). Residents and workers always get in.

Default weights: each action scores on every need it reduces, loses score with distance to its destination, `@job` actions get `tuning.workBias` (0.25) and idle actions `tuning.idleBias` (0.12). So an employed agent works when nothing is urgent, and a jobless one wanders. Change any weight with `weights`.

### Types

```js
{ name: 'child', share: 1, speed: 1.25, works: false,
  grow:   { bored: 1.6 },          // this need builds up 1.6× faster
  weight: { dirty: 0.5 },          // cares half as much about it
  weights: { play: { bias: 0.1 } },// raw matrix overrides for this type only
  look: { height: 10, head: '#888' } }  // placeholder art only (flat view: look: { color, size })
```

`share` sets the mix: shares 3, 1, 1 give 60% / 20% / 20%. `works: false` keeps the type out of the workforce. Every agent also gets individual traits: each need's growth varies by ±30% and speed by ±10% (`tuning.traitSpread`, `tuning.speedSpread`).

## Time

The engine counts **ticks** and nothing else. Every rate in the config is per tick: `need.grow`, action `effects`, `duration`, walking speed (`tuning.speed × type.speed`, in cells per tick), and the tick-based tuning values such as `queuePatience`.

`ticksPerSecond` ties ticks to real time. The game loop runs exactly that many ticks per second at `game.speed = 1`, whatever the display's refresh rate, and draws every frame with agents slid part-way along their last step, so motion stays smooth even at a low tick rate. `game.speed` is a multiplier (2 = double speed, 0 = paused).

So how fast a game feels is entirely a matter of its definitions. `examples/daylife/town.js` shows one way to keep them readable: pick how many real seconds a game hour lasts, write needs as "desperate after 11 hours" and buildings as "a meal takes 30 minutes", and convert to per-tick numbers in one place. Two things to know when doing that:

- A need keeps building up while it is being satisfied, so an effect must be the rate you want **plus** that need's growth.
- Effects on other needs (for example, hunger building more slowly while asleep) give the action a default weight on those needs too. Zero those weights with `weights` unless you want hungry people to go to bed.

The same file drives a day and night cycle from `onRebuildMatrix`: sleep is weighted up at night and down by day, work up during working hours.

## Age

`sim.age[i]` is how many ticks person `i` has existed; the engine advances it. With `life`, age also selects the matrix:

```js
life: {
  stages: [
    { age: 0,        name: 'child', speed: 2.6, works: false, grow: { bored: 1.7 }, weight: { bored: 1.5 }, look: { height: 8 } },
    { age: days(9),  name: 'adult', speed: 3.2, works: true,  look: { height: 14 } },
    { age: days(30), name: 'elder', speed: 2.4, works: false, weight: { lonely: 1.4 }, look: { head: '#6f6a4f' } },
  ],
  steps: 32,     // how finely a life is divided
}
```

Instead of fixed types you give points along a life, and the engine blends between them into `steps` matrices. Numbers (`speed`, `grow`, `weight`, `look.height`) are blended between neighbouring stages; `name`, `works`, `weights` and `look.head` switch at the stage's age. A person's weights, need rates, speed and look therefore drift as they age. Each step is one type, so anything written for types (`sim.at`, `onRebuildMatrix`, sprites by type) works per step. `sim.types[sim.type[i]].stage` is the stage name, and `sim.setAge(i, ticks)` sets an age directly.

That is all the engine does with age. It does not decide that anyone dies of it.

## Your own rules

The engine has no health, no death, no births and no economy. A game writes those as **modules**: independent objects, each with a name and the hooks it cares about.

```js
const purse = {
  name: 'purse',
  setup(sim) { this.coins = sim.addColumn('coins', Float32Array, 0); },       // run once, when plugged in
  onFinish(i, action, sim) { if (sim.actions[action].name === 'work') this.coins[i] += 1; },
};
createGame({ …, modules: [lives.module, purse] });
```

Every module's hook is called, in the order the modules were listed, so modules never overwrite each other. They do not import each other either: a module's per-person values are columns on the simulation (`sim.coins`, `sim.health`), which any other module can read. `sim.module(name)` finds a module by name and `sim.use(module)` plugs one in later.

| Hook | Called |
|---|---|
| `setup(sim)` | Once, when the module is plugged in. Add your columns here. |
| `onSpawn(i, opts, sim)` | A person was just created: at the start, by `setCount`, or by `add`. Initialise your values here. |
| `onTick(sim)` | Once per tick after movement. Run your rules here; schedule anything daily with `sim.tick`. |
| `onStart(i, action, sim)` | A person starts performing an action (enters the building). |
| `canUse(i, action, cell, sim)` | A question: may this person do the action on this cell? Asked on arrival at a destination that is not a building (a plain tile, or a cell of one of the game's own fields). Any module answering `false` sends them away. |
| `onFinish(i, action, sim)` | A person completes one (a work shift ends, a meal is eaten). |
| `onGone(i, cause, sim)` | Just before a person removed with `sim.remove` disappears. |
| `onRebuildMatrix(sim)` | After the engine has reset the live matrices, to adjust them. |
| `canStart(i, action, building, sim)` | A question, not a notice: return `false` to refuse the person entry (cannot pay, nothing in stock). They give up on that action for a while. |
| `canBuild(prefabName, sim)` | A question about the player: return `false`, or a string saying why, to refuse them a building (cannot pay, not unlocked). Asked by `game.canBuild` and `game.place`. |
| `onPlace(building, sim)` | The player placed a building with `game.place`. |
| `onDemolish(building, sim)` | The player removed something with `game.demolish`; `building` is `null` for a plain tile. |
| `onLine(tileName, cells, sim)` | The player laid that many cells of a plain tile with `game.line`. |
| `onLink(i, fromCell, sim)` | A person has just stepped through the link out of that cell (see Routes). |

A module may also carry `save(sim)` and `load(data, sim)` beside its hooks: `modules/save.js` asks each module for its own part of a saved game and hands it back (see `modules/README.md`).

The four building hooks are about what the player does through the game object. The starting map, laid out in `map.build` with the world directly, does not fire them.

And the tools a module can call:

| Tool | Use |
|---|---|
| `sim.addColumn(name, ArrayType, fill, width)` | A per-person value of your own (health, money, mood…). Returns the array; also `sim[name]`. It travels with the person and resets to `fill` for each new one. |
| `sim.add(x, y, opts)` | Add a person during play. `opts.age`, `opts.home` (a building with a free bed), `opts.type` (a type name or index), plus anything your `onSpawn` wants. Returns their index, or -1 at capacity. |
| `sim.snapshot()`, `sim.restore(data, buildingId)` | Everyone as plain data (your own columns included), and putting it back into a simulation built from the same config. `buildingId` maps the building ids in the data to the ids they have now. No `onSpawn` is called on restore. |
| `world.loadTiles(tiles)` | Replace every plain tile at once (one id per cell); routes are recomputed. |
| `sim.remove(i, cause)` | Remove a person at the end of the tick. `cause` is any string of yours; it is passed to `onGone`. |
| `sim.moveHome(i, building)` | Give a person a different home, or none. |
| `sim.setAge(i, ticks)` | Set an age (and with `life`, the matching step). |
| `sim.speedScale[i]` | Multiplier on walking speed, for illness, loads and the like. |
| `sim.target[i]` | A building id to send person `i` to, or -1. An action with `at: '@target'` goes to that building, whatever its kind, and is only available to people who have a target. They are let in even if it is closed or full, and do not count as customers. Set it, change it in `onFinish` for the next leg, set -1 when done. |
| `sim.goalX[i]`, `sim.goalY[i]` | A point of a person's own, in cells (NaN = none). See Points. |
| `sim.deny[i]` | Bit `a` set means person `i` may not choose action `a` for now. Set it when you know in advance they would be refused. |
| `sim.features.<name>[i]` | A matrix input of your own, declared with `features: ['<name>']` in the config. It gets a row in every matrix like a need does, so `weights: { work: { poor: 0.2 } }` makes it steer decisions. |
| `world.setBlocked(building, on, why)` | Close a building for the game's own reasons, or reopen it. `why` names the reason (`'economy'`, `'fire'`…): several rules can each close it, and it reopens when the last reason is gone. The reasons are in `building.blockedBy`. |

Two engine features exist mainly to make such rules work well: `interruptible` actions (someone asleep can wake for a desperate need) and `needsPace` (needs build more slowly during an action).

A person's slot in the arrays is not stable: when someone is removed, the last person takes their slot. Don't keep agent indexes across ticks.

`onFinish` runs while the person is still inside, so `sim.inside[i]` tells a module where the work was done.

`modules/economy.js` is a generic, optional economy built from these tools, and `modules/progress.js` keeps the player's level, unlocks, goals and achievements (see `modules/README.md` for both). The other modules there are `lives.js` (health, mood, death, births, moving house, leaving), `calendar.js` (days, seasons, years) and `mapgen.js` (land from a seed). A game's own rules are one more module of the same kind: `games/lords-will/rules.js` is the farming year, about 150 lines.

## Points

An action with `at: '@point'` goes to a point of the person's own: `sim.goalX[i]`, `sim.goalY[i]`, in cells, set by a module (a slot in a marching line, the enemy it is going for, a spot to fall back to). It is only available to people who have one (NaN means none). The person walks straight at it, round anything solid, and is there within `reach` cells (the action's own, else `tuning.pointReach`, 0.25).

- There, the action is performed on the spot, like on a plain destination tile: `canUse` is asked, `onStart` is called, its `effects` apply, and it ends by `until` or `duration` as usual.
- An action with neither `until` nor `duration` is **held**: the person stands at the point and thinks again at each of its ordinary decisions, as if it were free, so it can be called away by something that now scores higher.
- The point may move every tick. Someone at a point that moves more than twice `reach` away stops performing and goes after it, so a line of people each holding a slot marches when the slots do.
- The distance feature (`dist:<action>`) is the straight distance to the point.

The engine does not decide where points are or what they mean.

## Homes and jobs

Per agent: `sim.home[i]` and `sim.job[i]` are building ids, or `-1` for homeless / jobless; `sim.speed[i]` is cells per tick; `sim.inside[i]` is the building the agent is in right now, or `-1`.

`sim.assign()` runs automatically whenever the map or the population changes:

1. Agents keep the home and job they have while that building exists.
2. Each homeless agent takes the nearest house with a free bed.
3. Unstaffed buildings get one worker first, so they can open; then jobless agents take the nearest vacancy. Jobs are only taken within `tuning.commute` cells (48) of home, and only at buildings whose `staff` list allows the agent's type.
4. If a building is still unstaffed and nobody is jobless, one worker moves over from the best-staffed building.

Totals are on the sim: `housed`, `beds`, `employed`, `jobs`, `workforce`.

## Build mode

```js
game.beginBuild();                       // simulation freezes; drawing and the camera keep working
game.place('house', x, y);               // edits show immediately…
game.line('street', x0, y0, x1, y1);
const ms = game.endBuild();              // homes and jobs are reassigned here; routes follow in the background
```

Editing outside build mode also works. Either way nothing blocks: after an edit the simulation keeps using the routes it has, and each one is replaced when its new version is finished. `game.routesBusy` is true until that is done. Until then agents may briefly walk towards a building that was just removed, or ignore one that was just added.

`game.preview = [[x, y], …]` marks cells on the ground for placement previews. `game.footprint(prefab, x, y, rot)` gives a building's cells plus its doorstep (empty if it does not fit); `world.lineCells(x0, y0, x1, y1)` gives a street's.

## Routes

Agents steer along distance fields that lead to **entry cells**. There are four kinds:

- **Shared fields**, one full-map array per service kind ("nearest open canteen") plus one for streets.
- **Building windows**, for "my home" and "my job": a rectangle around the entry, built the first time an agent needs it and widened when an agent further away does, up to 56 cells out.
- **Sector fields**, for agents beyond a window's reach: a full-map field towards any home or workplace door in the destination's 32-cell sector. It brings the agent within reach, where the window takes over. Only a limited number are kept (`maxSectorCells`).

- **A game's own fields**, for destinations that are not buildings or tile kinds: "the nearest cell asking to be dug", "the nearest pile of crumbs". A module names the cells:

  ```js
  world.addField('dig', push => { for (const c of cellsBesideMarks) push(c); });   // called whenever the field is recomputed
  world.fieldChanged('dig');                                                       // the cells changed: recompute this field only
  actions: [{ name: 'dig', at: '#dig', duration: 45 }]                             // an action goes there with '#name'
  ```

  An agent that arrives does the action on the cell it stands on, like on a plain destination tile. Because a field can be a moment out of date, a module can turn an arrival away with the `canUse(agent, action, cell, sim)` hook; the agent then leaves that action alone for `tuning.retryTicks` (30). Edits to the map recompute these fields along with the shared ones.

**Links.** `world.addLink(x0, y0, x1, y1, { ticks, cost })` joins one cell to another, however far apart, one way: someone standing on the first steps to the second, taking `ticks`. Routes are found through links, at `cost` (4 is one cell of ordinary walking; by default as much as walking for `ticks`). A cell has one link out at most; a link the other way makes a pair that works both ways. `world.removeLink(x, y)` takes one away. It is what a stair, a lift, a tunnel or a ferry is. Shared fields, a game's own fields and sector fields follow links; a building's own window does not, so someone going to their home or job across a link is led by the sector field until they are near. Idle strolling does not use them. The `onLink(agent, fromCell, sim)` hook tells modules when someone has stepped through one.

**Cells to avoid.** `world.setExtra(x, y, cost)` makes one cell dearer to route through, whatever its tile (4 = as bad as one more step, up to 255). Routes go round it where they can and still cross it when there is no other way. Use it for danger, or for a mark the player drew.

**Crowding.** With `tuning.cellRoom` set, a cell holds that many agents at full walking speed; each one more slows everyone on it (speed ÷ (1 + `tuning.crowdSlow` × extra agents)), so a busy passage one cell wide jams. `sim.crowd[cell]` is how many stood on each cell last tick.

If none is available yet, the agent walks straight at the door and steps sideways around what it hits.

All of it is computed by `world.work(budgetMs)`, a slice at a time. An edit to the map puts every field back in the queue without moving the ones already waiting, so a map that changes many times a second (running water) still has each field refreshed in turn. `createGame` calls it once per frame with `cfg.fieldBudgetMs`. Headless, `sim.step()` finishes all outstanding work each tick unless you set `sim.fieldBudgetMs`.

After an edit, the shared fields are redone in full in the background, windows only where they overlap the change, and sector fields only when an agent next needs one. Redoing a window in place allocates no memory.

Three settings keep trips local, which is what keeps windows small: `tuning.commute` (48), `tuning.leash` (40: idle agents turn back this far from home), and `spawn: 'buildings'`.

## The matrices

Features, in order: one per need (squared), `dist:<action>` for every action with a destination, then `bias` (always 1). See `sim.featureNames`.

- `sim.base`: design values, one `F × A` block per type.
- `sim.live`: what agents use. Reset to `base` every `tuning.matrixEvery` ticks, then adjusted.
- `sim.at(type, feature, action)`: index of one weight in either array (names or indexes).

Built-in adjustment: a service's pull drops as its open buildings fill up (`tuning.crowding`). Add your own in a module's `onRebuildMatrix`:

```js
onRebuildMatrix(sim) {
  if (isNight) for (let t = 0; t < sim.T; t++) sim.live[sim.at(t, 'fatigue', 'sleep')] *= 2;   // everyone gets sleepier at night
}
```

## Views

The simulation does not know how it is drawn. Two views come with the engine, and both draw through the same core (thousands of sprites in one WebGL call):

| `view.projection` | File | What it shows |
|---|---|---|
| `'iso'` (default) | `renderer.js` | The grid as 2:1 isometric diamonds. Buildings are cut into depth strips so agents pass behind and in front of them. |
| `'flat'` | `flat.js` | The grid straight on, `view.cell` pixels per cell (default 16). Read it as a side cut (a nest, a mine, a tower) or as a top-down map. Agents are turned to face the way they walk; set `view.turn: false` to keep them upright. |

There is no gravity in either: a side view works because the things in it climb. Input, build previews, crowd-level building images and placeholders work the same in both.

**People going in and out.** Someone inside a building is not drawn (an `outdoor` one shows them on its footprint, and a sprite's `stand` may place them). With `view.doorLinger: ticks` they are still seen on the building's entry cell for that long after going in, and on its exit cell for that long before coming out, so a short visit (a drink, a quick meal) is never a blink in and out of sight. `sim.ticksLeft(i)` is the estimate it uses: how many more ticks i will go on with what it is performing, and `sim.staysAfter(i)` says whether i will go straight on to something in the same building (then it is not shown at the exit). `sim.timer[i]` counts the ticks into any action being performed, `sim.inFor[i]` the ticks since going into the building it is in. Default 0: off.

**Staying in for the next thing.** With `tuning.stayForNext` (on by default), someone who finishes an action inside a building chooses the next one before going out; if that is done in the same building (at their home, at their job, at their `@target`, or another service of the same building with room), it starts there without walking out and back in. A drink, a meal and warming up at home become one visit. `onFinish` runs before the choice, so a module can still send someone off (staff whose shift ended); `canStart` is asked as at the door, and a refusal sends them out to think again.

In the flat view a building image is exactly `w × cell` by `h × cell` pixels for its footprint in that rotation, and an agent frame is drawn centred on the agent, facing right before it is turned. `tiles` sprites are not used; tiles are painted in their colours.

**One part of the map at a time.** `renderer.setRegion({ x0, y0, x1, y1 }, pad)` (isometric view) draws only that rectangle of cells: the ground outside it is left as background, buildings, tall tiles and agents outside it are not drawn, and the camera is kept to it with `pad` pixels of room. `setRegion(null)` shows everything again. It is for a map that holds several places side by side and shows one at a time (the floors of a building). The simulation is not affected: everyone everywhere keeps moving. `renderer.setBounds(rect)` only keeps the camera to a rectangle of view pixels.

For a view of your own, pass a class as `renderer`. Extend `View` (`view.js`), which provides the camera, the sprite sheet bookkeeping and the frame routine, and implement `screenToCell`, `_rebuildStatic`, `_fill` and `placeholders`. With `groundMipmaps: false`, `_rebuildStatic` may return the rectangles it repainted, `[[x, y, w, h, pixels?], …]` (`pixels` an ImageData of that size, sent as it is), and only those are sent to the screen. The drawing core is `QuadBatch` in `quads.js`: one instance is 8 floats (position, size, atlas position, depth key, angle).

**A part of the map.** `game.renderer.setBounds({ x0, y0, x1, y1 })` (view pixels, or null) keeps the camera to a part of the map; the zoom-out limit follows it, so that part always fills the screen. Call it again when the part changes (a map that grows).

**A cheap ground.** With `view: { groundSharp: true, maxGroundSize: … }` the ground is painted smaller than it is shown and drawn with hard edges. For a ground of flat colours it looks the same and costs next to nothing to repaint and re-send, which matters when the map changes every second.

## Sprites

Pass `sprites` (or call `game.setSprites(sprites)` later) with this shape:

```js
{
  image,                       // one atlas: <img>, canvas or ImageBitmap
  agent: {
    w: 16, h: 24,              // size of one agent frame, feet at the bottom centre
    frames: 4,                 // frames in a cycle
    variants: 6,               // optional: how many different looks a person can have
    still: true,               // optional: separate frames for someone doing the action, not walking to it
    rect: (type, action, frame, variant, still) => [x, y],   // top-left of that frame in the atlas
  },
  buildings: {
    canteen: {
      w: 64, h: 48,            // one image for the whole footprint (see below)
      levels: 4,               // crowd levels: 0 = empty … levels-1 = full
      frames: 6,               // animation frames per level
      frameTicks: 8,           // simulation ticks per frame (default 8)
      rect: (level, frame, rot) => [x, y],
      closed: rot => [x, y],   // shown while the building has no workers
      level: building => 0,    // optional: which crowd level to show, instead of the engine's reading of `building.load`
      states: { fire: { frames: 3, frameTicks: 6, rect: (frame, rot) => [x, y] } },   // optional: see below
    },
  },
  tiles: { fence: { x, y, w, h },    // tall sprites for plain tiles; the bottom sits on the cell's diamond
           forest: [ {…}, {…} ] },   // a list: each cell takes one of them, always the same one;
                                     // `jitter: 12` on a sprite shifts it up to 6 px off its cell, so trees do not stand in rows
  ground: { floor: { x, y, w, h } }, // optional textures for the ground (see below)
  marker: { x, y, w, h },            // optional tile-sized sprite drawn on previewed cells
}
```

**Building images.** Agents inside a building are not drawn; the building shows them. The engine picks the crowd level from `building.load`, with some stickiness so an image does not flicker between two levels, and advances `frame` on a timer.

**A building seen from inside.** Three optional members of a building's sprite turn it into a room people are seen in:

- `open: true`: the image is the room's shell (floor and back walls). It is drawn behind everything standing on its footprint.
- `parts: rot => [{ x, y, w, h, ox, oy, key, frames?, frameTicks? or frameMs?, shut? }]` (`frameMs` goes by `renderer.clockMs` if a page sets it, to stop it while paused, else by the real clock): the things in the room, each a rectangle of the atlas (`x, y, w, h`) placed `ox, oy` pixels from the image's top-left corner, with its own depth: `key` is how far it stands from the footprint's back corner, in cells (x + y of its middle). People and parts then hide each other correctly. With `frames`, the frames lie side by side in the atlas; with `shut: true`, the look while the building is closed lies directly below.
- `stand: (building, person, tick) => [x, y, still] | null`: where someone inside is drawn, in grid cells (`still` 1 = standing or doing, 0 = the walking frames; a fourth value names the walking frame, for art that paces its own movement instead of following the simulation's ticks). Without it people inside are not drawn. Return the same array every time if you like: it is read at once.

With `level`, the art itself says which crowd level to show for a building (from its `customers`, say), and the engine's own reading of `load` is not used.

An image must be exactly `(w + h) × tileW / 2` pixels wide for a `w × h` footprint, and as tall as you like: its bottom edge sits on the bottom corner of the footprint's diamond. Because a footprint of 4×3 turns into 3×4 when rotated, the width is the same in every rotation. Supply each rotation you allow; `rect` and `closed` receive `rot`.

You supply one image per state. The engine draws it as vertical strips half a tile wide, each at its own depth, so an agent walking past any side of the building is hidden or shown correctly.

**States and light.** A game can give a building a `state` of its own (`building.state = 'fire'`); if the sprite has `states[that name]`, those images are shown instead, animated, until the state is cleared. `renderer.tint = [r, g, b]` multiplies the whole picture (a blue-grey for night). Pixels of the sheet whose alpha is between 0.5 and 0.9 are **lights**: they are drawn at full colour whatever the tint, so a lit window or a flame glows in the dark.

**People's looks.** With `variants`, each person shows the look in the simulation's `look` column. The engine does not decide it: a game adds the column (`sim.addColumn('look', Uint8Array, 0)`) and sets `sim.look[i]` when a person appears, from whatever it knows about them. With `stills: n` instead of `still`, there are n poses besides walking (standing, sitting…): `rect`'s last argument is 0 for walking and 1 to n for those, and a building's `stand` chooses among them. With `still: true`, `rect` is asked twice per frame: `still = 0` for someone walking to the action and `still = 1` for someone who has arrived and is doing it (in an `outdoor` place, where they can be seen, or on the spot).

**Ground textures.** `ground` maps a key to a rectangle of the atlas that repeats seamlessly. Where there is one, it is painted instead of the flat colour, in screen space (it is not turned into the isometric plane). Keys: `floor`; a plain tile's name (painted under its sprite, if it has one); a prefab's name, or a building's own `ground` property, which wins (a field can change texture as its crop grows); `entry` for the cell at a door; and `base` under a building that has an image and no texture of its own.

Buildings without a sprite are painted flat on the ground in their `color`. Sprites are drawn with hard edges (alpha below 0.5 is cut out), which is what lets the depth buffer handle overlap without sorting.

## Placing in two steps

On a touch screen a building dropped where the finger lifts is easy to misplace. `game.offer(prefab, { rot, at, check, onChange })` holds it over the map instead, as a ghost: its image on marked cells where it may stand, red marks (`sprites.markerBad`) where it may not.

- A touch on the ghost drags it; a tap elsewhere moves it there; any other one-finger drag pans the map.
- `game.offered` is `{ prefab, x, y, rot, layout, ok, why, reason }`. `why` is `'build'` (`canBuild` refused; `reason` holds its answer), `'space'` (it does not fit), or the string your `check(prefab, cornerX, cornerY, rot, layout)` returned.
- `game.turn()` turns it, `game.accept()` builds it and keeps offering (for the next one), `game.withdraw()` puts it away. `endBuild()` withdraws.

Underneath, a tool may now return `false` from its `'down'` call to leave that touch to the map; if the touch lifts without moving, the tool gets one more call with the phase `'tap'`.

## Game object

| Member | Use |
|---|---|
| `game.sim`, `game.world`, `game.renderer`, `game.camera` | Direct access to state. |
| `game.ticksPerSecond`, `game.speed` | Ticks per real second at speed 1, and the time multiplier (0 pauses). Both can be changed while running. |
| `game.tool` | `null` = drag pans. `(x, y, phase) => …` is called with the cell under the pointer; `phase` is `'down'`, `'drag'`, `'up'` (finger lifted) or `'cancel'` (a second finger started a pinch). |
| `game.beginBuild()`, `game.endBuild()`, `game.buildMode` | Pause for editing. `endBuild()` reassigns homes and jobs and returns the ms that took. |
| `game.routesBusy` | True while routes are still catching up with an edit. |
| `game.place(prefab, x, y, rot, size)` | Place a building centred on the cell (or, with a dragged `size`, with its corner there). Returns it, or `null` if it doesn't fit or a module's `canBuild` refuses it. |
| `game.resize(w, h)` | Change the drawing resolution when the canvas's place on the page changes size. The camera keeps looking at the same spot. |
| `game.onTap = (what, sx, sy) => …` | Called when the player taps the map while no tool is active, with what `pick` found there. |
| `game.pick(sx, sy, reach)` | What is under a canvas pixel: `{ person: i }` for the nearest person in the open within `reach` cells (1.1), else `{ building }`, else nothing but `{ cell: [x, y] }`. `cell` is always there. |
| `game.canBuild(prefab)` | May the player build this at all, wherever? `true`, or what a module answered: `false` or a reason to show. |
| `game.canPlace(prefab, x, y, rot)` | Check without placing. |
| `game.footprint(prefab, x, y, rot)`, `game.preview` | Placement previews. |
| `game.line(tile, x0, y0, x1, y1)` | Lay a plain tile along a straight line, on empty floor only. |
| `game.demolish(x, y)` | Remove the building or plain tile on the cell. Anyone inside steps out. |
| `game.paint(x, y, tile)` | Set a plain tile. |
| `game.setCount(n)` | Change the population. |
| `game.step(n)` | Advance n ticks without drawing. |
| `game.bench(ticks)` | Average ms per simulation tick. |
| `game.stats` | `{ simMs, renderMs, frameMs, fps }`, smoothed. |
| `game.logFrames`, `game.frameLog` | Set `logFrames = true` to record every frame of the real loop: `frameLog.routes/sim/draw/ui[k]` are the milliseconds frame `k` spent on each part and `frameLog.interval[k]` how long it lasted. Set `frameLog.n = 0` to start over. |
| `sim.profile`, `renderer.profile` | Accumulate per-phase timings in `sim.prof` and `renderer.prof`. `sim.routeUse` counts walkers by what guided them last tick. |
| `game.start()`, `game.stop()`, `game.destroy()` | Loop control. |

Agent state lives in flat arrays on `sim`, indexed by agent: `px`, `py`, `speed`, `home`, `job`, `inside`, `type`, `action`, `using`, `wait`, `age`, and `needsOf[i * sim.K + need]`, plus any columns the game added.

## Headless

`world.js` and `sim.js` use no browser APIs, so balance tests and benchmarks can run in Node:

```js
import { World } from './engine/world.js';
import { Sim } from './engine/sim.js';
const world = new World({ width: 96, height: 64, tiles, prefabs });
world.place('house', 5, 5);
const sim = new Sim(world, { needs, actions, types });
sim.setCount(200);
for (let t = 0; t < 10000; t++) sim.step();
```

## Known limits

- Staffing is by assignment, not presence: a building stays open while its workers are away eating or sleeping.
- A queue is a loose group near the door, not an ordered line; when a place frees up, any of them may get it.
- Crowding in the matrix is still counted per building kind across the whole map; only the hard capacity is per building.
- The straight-line fallback only steps sideways around obstacles. With few sector fields available (very large maps) a far-away agent can take a long time to get round a large block of buildings.
- Jobs further than `commute` cells from an agent's home are not taken, so a map can show vacancies and jobless agents at once.
- Assignment looks at straight-line distance and ignores obstacles.
- Route memory on the 960×640 test map with 3,500 buildings: about 60-90 MB, capped by `maxWindowCells` and `maxSectorCells`.
- The map size is fixed when the game is created. To change it, call `game.destroy()` and create a new game (see `examples/colony`).
- The ground is one texture, capped at 4096 px (`view.maxGroundSize`). Larger maps are painted at reduced resolution, so the ground looks blurry when zoomed in on the 960×640 map. Sprites stay sharp.
- Zoomed all the way out on very large maps, agents are smaller than a pixel and mostly disappear.
- A door on the north or west side is hidden behind the building in this view; the doormat painted on the entry cell is the only sign of it.
- Streets are single tiles on the grid; a diagonal street is a staircase of cells.
- Sprites have no partial transparency, so the placement preview is a pixel checker rather than a tint, and it does not show whether a spot is invalid (nothing is drawn there).
