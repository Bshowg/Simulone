# The Colony (working title): game design document

An ant colony game for phones, seen from the side. You grow one nest downwards and outwards through the dirt. The ants run themselves; you dig, you lay scent, and you decide which ground to take next.

Status: second draft. The first draft followed The Lord's Will too closely (a year, stages, policy dials, a counted store) and was dropped. This one starts from what an ant nest is and adds the modules that needs. Numbers are starting points, not decisions. Items marked **Open** need an answer before they are built.

## 1. The game in one paragraph

A queen sits in a hole in the ground. Everything the colony has is a thing in a place: a crumb on the surface, an egg in a chamber, a pile of dug soil, a dead ant in a tunnel. Ants pick things up and carry them where they belong, along trails of scent that they lay themselves and that you can lay too. You draw where to dig; the ants excavate it grain by grain and haul the soil out. Water runs down what you dug. Enemies walk in through the doors you opened. The nest has one map, and the map grows: you claim the chunk of dirt beside or below you, dig into it, and find out what it holds.

## 2. How it differs from The Lord's Will

| | The Lord's Will | The Colony |
|---|---|---|
| What you place | Buildings from a list | Nothing ready-made: you draw holes in the earth, then say what a hole is for |
| Goods | Counted in one common store | Physical things, carried by ants from place to place |
| How you steer | Policy dials | Scent: marks drawn on the map that ants follow |
| What a person is | A named individual with needs, family and mood | One of thousands; what it does depends on its age and on what the nest around it is asking for |
| The rhythm | The year: seasons, harvest, levy | The push: claim, dig in, discover, defend, settle, claim again |
| Growth | Stages reached by head count; more maps | The map itself grows; what you can build comes from what you find in the dirt |
| Danger | Events with outcomes, never drawn | On the map: water flows, tunnels fall in, enemies walk in and are fought in the tunnels |
| The skill | Balancing an economy through the year | Layout: distance, traffic, depth, and where the doors are |

## 3. Pillars

1. **Everything is somewhere.** No counted stores. If the colony has food, you can point at it. Distance and traffic are the economy.
2. **You draw, they dig.** The nest is made by marking earth and watching it be carried away. Its shape is yours, cell by cell.
3. **Steer by scent, never by order.** No ant is ever told what to do. You change what the nest smells like and the ants respond.
4. **One nest, a growing map.** No other maps. The world gets bigger chunk by chunk, and each chunk is a question: what is in there?
5. **The ground pushes back.** Water, loose sand, rock, roots and whatever else lives down there make every dig a decision.
6. **Readable on a phone.** The nest is drawn upright. Thousands of ants read as flow: thick trails, jams, idle clusters.

## 4. What the player does

| Verb | What it is |
|---|---|
| Mark digging | Drag over earth to mark it for removal: a tunnel one cell wide, or any shape of cavity |
| Name a room | Tap a cavity and say what it is for: brood, food, rest, waste, guard. Ants then bring the right things there |
| Lay scent | Draw a trail or drop a mark: "food this way", "gather here", "keep out", "alarm". Marks fade unless renewed |
| Claim | Take a chunk of dirt next to the nest (section 6) |
| Seal and open | Plug a tunnel or an entrance with soil, or open it again |
| Inspect | Tap anything: an ant, a pile, a room, a chunk |

The player never selects an ant, assigns a job or steers a fight.

## 5. The earth

The map is material, not background.

### Digging

- A marked cell is a job. An ant walks to it, bites out a load of soil and carries the load away. A cell takes several loads.
- **Soil has to go somewhere.** By default it is carried to the surface and dropped by the entrance, where it builds the mound. The player can also name a spent tunnel as a dump, which is how old diggings get filled back in.
- The longer the walk to the surface, the slower deep digging gets. Digging a deep nest is a hauling problem.

### What the ground is made of

| Ground | Digging | Behaviour |
|---|---|---|
| Loam | Normal | Holds |
| Sand | Fast | A wide cavity with nothing under its roof falls in. Wet sand falls in sooner |
| Clay | Slow | Holds any span, and holds water out |
| Gravel | Very slow | Water runs straight through it |
| Rock, roots | Cannot be dug | Must be gone around. Roots can be farmed (section 9) |

### Holding up

A cavity's roof holds for a span that depends on the ground. Past that span it caves: the cells refill with loose soil, and anything inside is buried. Narrow tunnels never cave. This is why chambers have a size and why sand is cheap but dangerous.

### Water

Water is on the map and moves. Rain falls on the surface, enters by the entrances, and runs down through whatever is dug, pooling at the bottom of each run. A flooded cell cannot be walked or used, and brood or food in it is lost. Water soaks slowly into loam, fast into gravel and never into clay.

The player's answers are all in the layout: an entrance on high ground or under a stone, a bend upwards after the door, a sump dug below the main shaft, a clay chamber for the brood, a plug of soil in a storm.

## 6. The growing map

**One map, which gets bigger.** This is the fixed point of the design.

### Chunks

- The world is a grid of chunks of **20 × 20 cells**. The colony starts holding **2 across and 3 down** (40 × 60 cells).
- The full world is **7 across and 6 down** (140 × 120 cells): 42 chunks, 6 held at the start.
- Ground the colony does not hold is dark and cannot be marked for digging. The view covers what is held plus a rim of the neighbours.
- Only a chunk that touches a held chunk along a side can be claimed.

### Claiming

A chunk is claimed in one of three ways:

| Way | How |
|---|---|
| **Bought** | For food, physically: the price is that many pieces carried to the border and consumed. The price rises with each chunk and with depth |
| **Unlocked** | Some chunks open when a condition is met: a colony size, a room of a kind, a discovery made elsewhere |
| **Taken** | A chunk held by something else (a rival nest, a beetle's burrow) is claimed by clearing it (section 10) |

### Scouting and discovery

Before claiming, a chunk shows only a hint: its ground type at the border and one sign ("damp", "roots", "movement", "hollow"). Its real contents are generated from the game's seed and revealed as the ants dig in. **What the colony can do next comes from what it finds:**

| Found in the dirt | Opens |
|---|---|
| Fungus threads | Fungus gardens: leaves in, food out |
| Living roots | Aphid herds: a steady drip of sugar |
| A seed cache | Seed rooms: food that keeps |
| An abandoned nest | Ready-dug rooms, and sometimes old stores |
| A clay seam | Flood-proof chambers |
| A warm stone at the surface | Fast brood rooms beneath it |
| A spring | Water in drought, and a flood risk forever |
| Resin | Sealed doors: an entrance that can be shut and opened quickly |
| A rival's gallery | A fight, then their rooms and their stores |
| Something large asleep | Best left alone, or not |

So there is no list of buildings unlocked by level. The colony's abilities are a map of what it has dug up, different in every game.

### Sideways and down

Surface chunks (the top row) widen the ground above the nest: more places for entrances and more of the surface to forage. Deep chunks are stable, warm and safe from rain, but far from food. The shape the nest grows into, wide and shallow or narrow and deep, is the player's strategy.

## 7. Things and carrying

Everything the colony owns is an item on the map.

| Item | Comes from | Belongs in | Goes bad? |
|---|---|---|---|
| Crumb (sugar) | Surface finds, aphids | A food room | Slowly; faster if damp |
| Meat | Insects, the fallen | A food room | Quickly |
| Seed | Surface, caches | A seed room | No, if dry |
| Leaf | Surface plants | A fungus garden | No |
| Egg, larva, pupa | The queen | A brood room | Dies if cold, wet or untended |
| Soil | Digging | The surface, or a dump | No |
| The dead and the waste | The colony | A waste room, far from the brood | Breeds sickness where it lies |

- **An ant carries one thing.** Large finds (a beetle, a fruit) are cut up where they lie, or dragged by several ants along a wide enough tunnel.
- **Rooms hold what fits.** A room's capacity is its floor area. A room that is full sends carriers on to the next of its kind.
- **Brood is moved.** Nurses carry eggs and larvae between brood rooms towards the best warmth, which changes between day and night. A good nest gives them a short trip.
- **Feeding is carrying too.** Ants eat at a food room. The queen and the larvae cannot walk: food is carried to them.

## 8. Ants

### What an ant does

There are no jobs to hold and no fixed castes among workers. An ant looks at what is near it and what it smells, and takes up the nearest task that is asking loudly enough: a larva asking for food, a marked cell asking to be dug, a pile asking to be moved, a trail leading out.

**Age decides what an ant listens to.** A young ant stays deep and tends brood. As it ages it moves outward: digging and hauling, then guarding, and last of all foraging outside, where ants are lost. A colony therefore spends its oldest ants on its most dangerous work. Losing foragers pulls younger ants outward early, and the brood feels it a little later.

### Needs

Only two, so that attention stays on the colony and not on the individual: an ant must eat, and it must rest. A hungry ant drops its task and goes to a food room. If food is far, the colony pays for it in walking.

### Bodies

| Body | Raised when | Role |
|---|---|---|
| Worker | Always | Everything above, by age |
| Major | The larva is fed meat | A big-headed ant: fights, cuts up large finds, blocks a tunnel with its head. Eats more, carries no brood |
| Princess, drone | The colony is large and the brood room is rich | They leave on the flight (section 11) |
| Queen | Once | Lays. If she dies the colony ends unless a princess is in the nest |

What a larva becomes is decided by how it is fed, so the player shapes the colony's make-up through what food reaches which brood room, not through a dial.

## 9. Scent

Scent is the colony's nervous system and the player's hand.

- **Ants lay it.** An ant carrying food home leaves a trail; others follow it out, and a good source becomes a thick road by itself. An ant that meets an enemy leaves alarm; alarm draws majors and sends carriers away.
- **It fades.** A trail that is not walked disappears, so the colony forgets a spent source without being told.
- **The player lays it too.** The player's marks are the same scents, stronger and slower to fade:

| Mark | Effect |
|---|---|
| Trail | Ants looking for work follow it. Drawn to a new find or a new chunk, it starts traffic before the ants would have found it |
| Gather | Idle ants collect here: a reserve by a door, or diggers at a new face |
| Keep out | Ants avoid the cells: close a flooded branch, or a door with a spider at it |
| Alarm | Majors come, others leave |

- **Traffic is real.** A one-cell tunnel passes ants in single file each way. A busy trail through a narrow tunnel jams, and a jam is visible. Widening a main way, or digging a second one, is the fix.

The player can show any scent as a coloured layer over the nest.

## 10. The surface and what comes from it

### The surface

The top of the map is ground the ants walk on, not a door to somewhere off screen. It is as wide as the held chunks.

- **Finds appear on it:** a fallen fruit, a dead beetle, a scatter of seeds, a leaf-bearing plant. Each is a pile of items that runs out.
- **Day and night.** Foragers work by day. Night is cold on the surface and safe below.
- **Weather.** Rain drives everyone in and sends water down the entrances (section 5). Heat dries the surface finds and makes the deep rooms the only good brood rooms.
- **Where the door is matters.** Every load is walked from the find to an entrance and down to a room. A second entrance near a rich patch is worth a chunk.

### Enemies

Enemies are agents on the map. They come in by the doors and tunnels the colony dug, so the nest's shape is its defence.

| Enemy | Does | Answer |
|---|---|---|
| Rival foragers | Take the same finds on the surface; fight ants they meet | Numbers at the find; trails that get there first |
| Raiders | A column enters by an entrance and heads for the brood and the food | A narrow way a major can block; a guard room on the way; sealing the door |
| A spider or beetle | Sits at a door and takes foragers; or is found asleep in a chunk | Another door; majors; keep out |
| A parasite | Rides in on a forager and spreads among the brood | A waste room; carrying out the dead; distance between brood rooms |
| A rival nest in a chunk | Sends raiders until it is cleared | Dig in and take it: its queen's chamber is the last room |

A fight is ants meeting in a tunnel: each has strength, and width decides how many meet at once. A major in a one-cell tunnel is a gate. Nothing is steered; the player's part is the tunnel, the scent and the timing of a seal.

## 11. Growth and the long game

- **No stages and no levels of the settlement.** The colony's growth is read from the map: how much is held, how deep it goes, what has been found.
- **Goals** still run one at a time to teach the game and to point at the next push: "dig a brood room below the stone", "find water", "reach the fourth row".
- **The flight.** A colony with surplus raises princesses and drones. When the weather is right they fly, and each princess that gets away is a daughter colony. Daughter colonies are a number, not maps: they are the score, kept across games.
- **The deep.** The bottom row holds the rarest finds and the hardest ground. Reaching it is the long goal of a single nest.
- **A colony can end.** If the queen dies with no princess in the nest, no more eggs are laid. The player then founds a new nest in a new world; the score and achievements carry over.

**Open:** whether a dead colony ends for good or can be continued from an earlier save.

## 12. The screen

- **The nest fills the screen,** side on and upright. Drag to pan, pinch to zoom, limited to the held chunks and their rim.
- **Top strip:** time of day and weather, speed, and three counts: ants, brood, food pieces.
- **Bottom bar:** dig, room, scent, claim. Each is a drawing tool, not a menu of buildings.
- **Layers** the player switches on: scent, traffic, damp, warmth, what is stored where.
- **Tapping** an ant, a pile, a room or a chunk opens a small card.
- **Zoomed out,** ants are not drawn one by one: trails are drawn by how busy they are, and rooms show how full they are.
- **Sound:** ambient only. The surface by weather near the entrance; the deep nest quiet, with the tick of digging.

## 13. What has to be built

The rule holds: **a mechanic another game could use is a generic module with its numbers passed in; anything about queens, brood or dirt lives in the game's own files.** But this game is not assembled from The Lord's Will's modules. Most of what it needs does not exist yet.

### New generic modules

| Module | What it does | Another game that could use it |
|---|---|---|
| `items.js` | Things that exist on the map: kinds, piles on cells, capacity by area, pick up, carry, drop, decay over time. Agents hold one. Answers "where is the nearest X" and "where does X belong". | Any game with haulers and warehouses |
| `tasks.js` | Work posted by the world instead of jobs held at buildings: each task has a place, a kind, a loudness and how many may take it. Agents take the task that calls loudest for their type and age, and drop it when done or when a need wins. | Any game where workers are a shared pool |
| `scent.js` | Fields over the grid that agents add to and read, which spread and fade. Named layers. Gives agents a direction to follow and inputs for their decisions; lets the page paint into a layer. | Crowds, animal herds, traffic heat, fear |
| `ground.js` | Cells as material: kinds with hardness and strength, digging by loads, loose soil as an item, roofs that hold a span and cave past it. | Mining and tunnelling games |
| `water.js` | Water on the grid: sources, flow downwards and sideways through open cells, pooling, soaking away by ground kind, flooded cells closed to walking. | Floods, irrigation, lava |
| `zones.js` | Free-shaped areas named by the player. A zone has a purpose, an area and so a capacity, and says which items it accepts. Replaces fixed building shapes. | Stockpiles and districts |
| `claims.js` | The map as plots, held or not. Refuses marking outside held plots, says what can be claimed next, hints at and then reveals a plot's contents, carries out a claim, reports the held bounds. | Buying land beside a town |
| `foes.js` | Sides. Agents belong to one; meeting an enemy is a fight settled by strength and how many can stand side by side; waves that enter at given places with a goal. | Any game with raids drawn on the map |
| `weather.js` | Day and night and a sequence of weather drawn from odds: rain, heat, calm. Announces changes a little ahead. | Any outdoor game |

### Kept from what exists

| Piece | Used for |
|---|---|
| Engine: agents, movement and routes, flat side-on view, types and ages | The ants |
| `modules/progress.js` | Goals, achievements and the score kept across games. Not its levels |
| `modules/save.js` | Keeping the colony between sittings |
| `modules/mapgen.js` | The ground inside each chunk, with one addition: generating into a rectangle of an existing map |
| `kit/kit.js` | The phone layout |

Not used: `economy.js` (items replace the counted store), `calendar.js`, `events.js` and `policies.js` (weather, finds and scent replace them), `lives.js`, `region.js`.

### Changes to the engine

| Change | Why |
|---|---|
| An agent's choice can come from a module (`tasks.js`) as well as from the matrix | Work is taken from the world, not held at a building |
| Movement can follow a field as well as a route | Scent trails |
| Tunnel capacity: how many agents pass a cell at once, with queuing | Traffic and jams; fights at a choke |
| Cells that change kind while running, with routes kept up to date cheaply | Digging, caving, flooding happen all the time |
| View bounds that change while running; a shade over chosen cells | The growing map |
| Value layers drawn over the map | Scent, damp, warmth, traffic |
| Drawing by density when zoomed out | Thousands of ants on a phone |

The amount of constantly changing ground was the main technical risk: routes used to be recomputed when the player builds, and here the map changes every second. Step 1 measured it (section 16): it is cheap.

### The game's own files

`games/ant-colony/`: the numbers (ground kinds, item kinds, ages and what each listens to, bodies, enemy kinds, weather odds), the tables (chunk contents and hints, goals, achievements), the colony's own rules (the queen, brood and how feeding decides a body, the flight), and the page. `examples/anthill` stays as it is: it is the small example, not the start of this game's code.

### Not planned

- Other maps, a world map, travel.
- Selecting or ordering ants.
- A year of seasons. Day, night and weather carry the rhythm. Winter could come later as a long weather.
- Anything needing a server.

## 14. Order of work

Each step ends with something playable on the phone.

1. **Dig and haul.** `ground.js`, `items.js`, `tasks.js`: mark earth, watch it dug and carried out, the mound grows. One queen, workers, food as items carried from a pile on the surface. Measure routes on a changing map. Question: is watching them dig your drawing satisfying?
2. **Rooms and brood.** `zones.js`: free-shaped rooms, brood carried and tended, ages moving outward.
3. **Scent.** `scent.js`: trails the ants lay, marks the player lays, traffic and jams.
4. **The growing map.** `claims.js`: chunks, hints, discovery, the first finds that open new rooms. Question: does a chunk feel like a question worth asking?
5. **Water and weather.** `water.js`, `weather.js`, cave-ins.
6. **Enemies.** `foes.js`, majors, raids, a rival nest in a chunk.
7. **The long game.** The flight, the score, the end of a colony, goals as a tutorial, saving.
8. **Balance, then art and ambient sound.**

## 15. Decisions and open questions

Decided:

1. **One map that grows** by claiming chunks of dirt. No other maps.
2. **Its own game.** New mechanics get new generic modules; modules from The Lord's Will are used only where they fit.

Open:

1. **The end of a colony:** final, or continued from an earlier save.
2. **Chunk and world size:** 20 × 20 cells in a 7 × 6 world is a first guess.
3. **How much the player sees before claiming:** a hint only, as written, or the full contents for a higher price.
4. **How many ants:** the design wants thousands. The engine example runs hundreds. If thousands are too heavy with carrying and scent, one drawn ant could stand for several.
5. **Title.**

## 16. Progress

### Step 1: dig and haul (done)

Playable at `games/ant-colony/`. A queen and 40 workers in a first chamber at the foot of a shaft, on a 40 × 60 map of loam, sand, clay and stone.

- **Digging.** The player drags marks over earth (a one-cell tunnel or a three-cell room brush, and an unmark brush). Ants bite a marked cell out a load at a time (loam 3 loads, sand 2, clay 6, stone never), two ants to a cell at most, from the open side inwards. Time does not stop while marking.
- **Soil.** Every load is carried to the surface and dropped around the way out. The mound is a real pile: lower the further from the hole, and allowed to grow taller when it fills.
- **Food.** A pile of crumbs appears on the surface every 30 seconds. Ants carry them to the floor of the first chamber, which is the food store, and eat one crumb when hungry, from whatever pile is nearest. An ant carrying a crumb when it gets desperate eats that one.
- **Work.** Nobody has a job. Dig, clear loose soil, carry soil out, fetch food and store food are tasks every worker weighs each time it decides.
- **The screen** is on the page kit. Marks, piles and loads in jaws are drawn by the page on a layer over the map. Tapping an ant or a cell shows what it is.

Built for it:

| Piece | What |
|---|---|
| `games/ant-colony/modules/items.js` | Piles, stores and carried things, with routes to them |
| `games/ant-colony/modules/ground.js` | Marked earth dug a load at a time |
| `games/ant-colony/modules/tasks.js` | Work posted by the world, taken by whoever it calls loudest |
| Engine | A game's own route fields (`world.addField`, `at: '#name'`) and the `canUse` question for destinations that are not buildings |
| Kit | `ui.layer()`, a canvas over the map for the page's own drawing |

Measured, headless:

- **Routes on a changing map.** Each dug cell brings eight route fields up to date. That takes about 0.04 ms on the 40 × 60 map and 0.25 ms on the full 140 × 120 world. With a cell dug every few seconds it is under a tenth of the simulation's time. The risk named in section 13 is not a problem at this size.
- **Pace.** 40 workers dig a 51-cell plan (a gallery, a shaft and a room) in about four minutes while keeping themselves fed, and move 198 loads to the mound.

Found on the way:

- Making a busy task call more quietly does not work: every ant hears the same call at the same moment, so the crowd swings between two tasks every half second and nothing gets done. A task with enough takers is now closed to newcomers instead, and those on it carry on.
- Ants must be able to eat where food lies, not only from the store, or a colony starves beside a pile of crumbs it is busy carrying.

Not in this step: rooms named by the player, brood and ages (step 2), scent, claiming chunks, water, enemies, saving.

### Step 2: rooms and brood (done)

- **Rooms.** In the Rooms sheet the player paints dug-out ground with a purpose: **food** (8 crumbs a cell), **brood** (3 eggs, 3 larvae and 3 pupae a cell) or **rest**. Any shape; cells that touch are one room. The first chamber's floor starts as the food room and can be repainted.
- **The queen** cannot feed herself. A crumb is brought to her when she is hungry, and while she is fed she lays an egg every 10 seconds where she sits. She stops when 6 eggs lie about with no brood room to go to, or when 8 larvae are waiting.
- **Brood.** Eggs are carried to a brood room. There an egg becomes a larva after about 40 seconds, a larva becomes a pupa when it is fed one crumb, and a pupa becomes an ant after about a minute. Brood lying anywhere else does not develop. Each kind is drawn as its own dot.
- **Feeding from surplus.** Larvae are fed only from what the store holds beyond 0.8 crumbs for every ant. This is what ties the colony's size to its food room: with the starting store of 64 crumbs, it settles near 70 ants.
- **Ages.** An ant is young for 4 minutes, grown until 13, then old, and lives about 20. The young carry eggs and feed brood and the queen and never go outside; the grown dig and haul; the old fetch food from the surface. Age changes how loudly each task calls, not what an ant is able to do, except where a task is ruled out.
- **Eating.** An ant does not spend a crumb until its hunger passes one half. Without this, idle ants ate at the first twinge and the colony ate twice what it needed.
- **Rest.** A resting room clears tiredness in 8 seconds; a nap in a tunnel takes 20.

Built for it:

| Piece | What |
|---|---|
| `games/ant-colony/modules/zones.js` | Cells with a purpose, rooms, and a route to each purpose |
| `games/ant-colony/modules/items.js` | `count`, `inStores` |
| The colony's rules | The queen, eggs, larvae, pupae, hatching, ages, death of old age |

Measured, headless, over an hour of game time with one brood room and one rest room named: the colony holds between 65 and 79 ants, 211 hatch, 183 die of old age and none of hunger.

Found on the way:

- A colony that feeds every larva it can grows past what the surface can feed and then starves, in waves. Feeding brood only from surplus removes the waves.
- The store's size is now a real lever, which was not planned: the goal line tells the player when the store is full and crumbs lie outside.

Not in this step: brood moved by warmth, what a larva is fed deciding its body, the dead as things to carry out, the waste room, losing foragers pulling the young outward, saving. The queen does not die. Not yet tried on the phone.

### Step 3: scent (done)

- **Finds are not known.** Food still turns up on the surface every 30 seconds, but the colony does not know of a pile until an ant comes within 3.5 cells of it. That ant marks the spot with trail scent.
- **Trails.** An ant carrying food home lays trail on every cell it crosses, and taking a crumb marks the pile's spot afresh. A pile is fetched for as long as its spot smells of trail; when the trail fades (it halves every 40 seconds) the pile is forgotten. Trails are drawn in blue.
- **Scouts.** Up to four grown or old ants with nothing better to do walk to random spots on the surface, and find things on the way.
- **The player's marks**, in a new Scent sheet. They are the same scents, laid on thick, and they fade:
  - **Trail:** drawn to a pile, it makes the pile known at once.
  - **Gather:** idle ants collect on the marked cells.
  - **Keep out:** marked cells count as 40 cells of walking, so ants go round where they can.
  - **Wipe** clears marks.
- **Traffic.** A cell holds two ants at full speed; each one more slows everyone on it. A "show traffic" switch draws where ants have walked and outlines cells that are over their room in red.

Built for it:

| Piece | What |
|---|---|
| `games/ant-colony/modules/scent.js` | Fading layers, with watches and routes on a strength |
| Engine | `world.setExtra` (a cell made dear to route through) and `tuning.cellRoom` / `crowdSlow` with `sim.crowd` (crowded cells slow down) |

Measured, headless, over 40 minutes: the colony holds between 63 and 71 ants with no deaths from hunger, as before scent. With about 65 ants the one-cell shaft is over its room for 5.5% of the time.

Found on the way:

- With piles unknown, the grown ants' pull towards fetching food was too weak to beat the walk to the surface, and the store ran dry. It was raised.
- A task has to call louder than about 0.22 to pull an ant out of wandering. Scouting and gathering were set below that at first and nobody took them up, so a new nest with no old ants found no food.
- An ant with nowhere to put a load dropped it on a full store cell, which overfilled the store and then blocked all fetching. It now keeps hold of it there.

Not in this step: the alarm scent (there are no enemies yet), ants following a trail cell by cell (they still take the shortest route to a known pile), and trails making a way faster to walk. Jams are mild at this colony size. Not yet tried on the phone.

### Step 4: the growing map (done)

- **The world** is now 140 × 120 cells: 7 chunks across and 6 down, each 20 × 20. The colony starts holding 6 of the 42 (two across, three down). Ground it does not hold is dark and cannot be dug, named or scented, and the camera stays within what is held plus a rim of five cells.
- **Each chunk has its own ground:** loam, sand, clay or stones, decided from the seed. Surface chunks are sand or loam; deep ones lean to clay and stones.
- **Claiming.** A chunk that touches held ground can be claimed from the Claim sheet or by tapping it. It is paid in crumbs out of the food rooms: 24 for the first, 1.3 times more for each one after, and 15% more for each row down. The fourth row down needs 60 ants, the fifth 100, the sixth 140, and the two outermost columns 100.
- **Saving.** If the store cannot pay yet, the colony saves: the price is kept back from the larvae, except that one larva is still fed every 15 seconds so the colony replaces its dead. The claim is made the moment the store can pay and still leave the ants half their reserve (0.4 crumbs each), so a claim never empties the store. The food rooms must be able to hold that much.
- **Surface chunks** open more surface: finds turn up in proportion to its width, and scouts and the mound use all of it.
- **What the earth hides.** 15 of the chunks below the surface row hide something, and a claimable chunk shows a sign of it ("a sweet smell", "a hollow sound", "pale threads in the soil"). Once the chunk is held, a **?** shows where to dig:
  - **a cache:** 60 crumbs;
  - **an old nest:** seven by three cells of rooms already dug;
  - **fungus** (three in the world, one always beside the first nest): the colony can then name **garden** rooms.
- **Gardens.** A garden cell gives a crumb when it is tended (5 seconds of work) and is ready again 45 seconds later. It is the first food that does not come from the surface.

Built for it:

| Piece | What |
|---|---|
| `games/ant-colony/modules/claims.js` | Plots held or not, what can be claimed next, prices, bounds |
| `modules/mapgen.js` | `rect`: generate into a part of a larger map |
| `games/ant-colony/modules/tasks.js` | Takers are counted every tick and each agent's choices worked out just before it decides; an agent finishing a full task does not take it straight back |
| Engine | `renderer.setBounds` (the camera kept to a part of the map) and `view.groundSharp` (a small ground texture with hard edges) |
| The colony's rules | The held surface, hidden things and digging them up, gardens, saving for a claim |

Measured, headless, with a scripted player that names a brood room, digs a large food room and is always saving for the next chunk: in an hour it claims 12 chunks, digs up fungus at minute 28 and later an old nest and a cache, grows 1,083 crumbs in 55 garden cells, and the colony moves between 54 and 90 ants with no deaths from hunger. A tick takes about 0.1 ms on the full world, of which 0.04 ms is keeping routes up to date. In the browser a frame's page work and drawing take about 1 ms at phone size.

Found on the way:

- With the brood fed from every surplus crumb, nothing could ever be saved, so a claim dearer than the reserve was impossible. Saving had to be made a state of the colony.
- A colony that stops feeding larvae entirely while it saves dies of old age before it can pay. One larva every 15 seconds keeps it level.
- Ants that had finished a full task took it straight back, so "four scouts" became eleven. Old ants refused to dig or nurse at all, so a colony with no young could never recover; they now do both when nothing else calls.
- On the larger world, counting how much work each task has every tick was the main cost; it is now done every eighth tick.
- A claim that took everything in the store left the ants to starve: 56 died of hunger in one hour's run. A claim now always leaves them half their reserve.

Simpler than the design: a chunk is paid from the store, not carried to the border; its ground is generated at the start and only hidden, not made when dug; the contents are shown as a **?** as soon as the chunk is held. Roots, the warm stone, the spring, resin and rival nests are not in yet. Not yet tried on the phone.

### Step 5: water and weather (done)

- **Day and night.** A day lasts 4 minutes and its last quarter is night. At night nobody sets out for the surface; food still turns up, and is there at dawn. The top strip shows the day, the time of day and the weather.
- **Weather** is calm, rain or heat, each for a minute or two, and what comes next is announced 45 seconds ahead. The first 6 minutes of a game are always calm.
- **Rain.** Nobody goes out and no food turns up. A cell of water comes in by every way out every 3 seconds and runs down through whatever is dug: it falls, spreads where more presses from above, pools, and soaks away (fast into sand, slowly into loam, never into clay or stone). A flooded cell cannot be walked.
  - Brood the water reaches is lost. Food under water is only out of reach until it is dry again.
  - An ant caught in it gets to the nearest dry ground within four cells, or drowns.
- **Plug.** A new tool in Dig packs soil into an open tunnel cell, at once. A plugged entrance keeps the rain out and the foragers in. Marking the plug has it dug open again.
- **Heat.** Finds turn up at 40% of the usual rate, and each pile on the surface loses a crumb every 10 seconds.
- **Cave-ins.** Sand does not hold a roof wider than three cells. Every 5 seconds a wider room under sand has a 15% chance of losing its middle cell (60% in rain). The cell is solid sand again; brood in it is lost and its room purpose is gone. Loam and clay hold any width.

Built for it:

| Piece | What |
|---|---|
| `games/ant-colony/modules/weather.js` | Day and night, and weather drawn by weight with a warning |
| `games/ant-colony/modules/water.js` | Water that falls, spreads, pools and soaks away, as flooded cells |
| `games/ant-colony/modules/ground.js` | `span` per kind of ground, and `settle` |
| The colony's rules | Rain coming in, what flooding and burial ruin, staying in at night and in rain, heat, the plug |

Measured, headless:

- A minute of rain on the untouched starting nest puts 6 to 8 cells of the first chamber's floor under water at a time. With a pit dug below the shaft, the water falls through to it and the chamber stays dry. With the entrance plugged, water stands above the plug and none gets in.
- With the same scripted player as step 4, over an hour of weather: the colony moves between 42 and 87 ants with no deaths from hunger, and claims 7 chunks (12 without weather). A tick takes 0.15 ms, of which 0.10 ms is keeping routes up to date as water moves.

Found on the way:

- The first version of weather starved the colony to 4 ants: nights and rain cut food by more than a third while the flood destroyed the whole store. Food now turns up by night, finds come every 24 seconds instead of 30, night is a quarter of the day, and water no longer destroys food.

Different from the design: food is not lost to water, only put out of reach. There is no gravel, no spring, and no damp or warmth layer yet; brood is not moved by warmth. Not yet tried on the phone.

### Step 6: enemies (done)

- **Fights.** Enemies within 0.9 cells of each other fight where they stand, a blow every third of a second. A worker has strength 1 and health 4.5; a major 5 and 14; a raider 1.1 and 4. Nothing is steered. Ants in a fight are marked with a red cross.
- **Rival nests.** Three of the outer chunks hide a rival nest ("movement in the soil"). While one lies in the earth and the colony has 55 ants, raids come.
- **Raids.** Every 4 to 7 minutes, by day and not in rain, a party of one raider for every 14 ants (4 to 14) comes over one end of the surface, announced 25 seconds ahead. Raiders go down to the food, take a crumb each and make off with it, fighting whatever they meet. One that has not got a crumb in 90 seconds gives up.
- **Majors.** A new room purpose, **guard**. The colony keeps one major for every 3 cells of guard room: new ants hatch as majors until there are enough. A major does no work, gets hungry 1.6 times as fast, stands guard, and goes where there is alarm.
- **Alarm.** A colony ant that sees an enemy within 4 cells leaves alarm scent where it stands, and so does every blow. The player can lay alarm in the Scent sheet to call majors somewhere.
- **Plugging** the entrance keeps raiders out, as it keeps rain out, and the foragers in.
- **Taking a rival nest.** Digging into one wakes its queen and twelve guards, who come for the colony's food. When the rival queen is dead the nest's rooms and its 80 crumbs are the colony's, and one source of raids is gone. When all three are dead, raids stop.

Built for it:

| Piece | What |
|---|---|
| `games/ant-colony/modules/foes.js` | Sides, health, blows, fighters held where they stand, waves |
| The colony's rules | Majors and guard rooms, alarm, raid parties, rival nests |

Measured, headless:

- **Eight raiders on a nest of 41:** with no defence 14 workers die; with six majors, 5 die; with the entrance plugged, none, and nothing comes in or out.
- **Digging into a rival nest:** with eight majors its queen is dead 80 seconds later for 4 losses; with no majors 22 workers die and the queen lives.
- **Over an hour** with the scripted player, weather and a guard room: 6 raids are beaten off (29 raiders killed, 18 of the colony lost, nothing stolen), the colony stays between 53 and 70 ants with no deaths from hunger, and 5 chunks are claimed.

Found on the way:

- Raiders killed the colony's queen as they passed her, which ended the colony in one raid. She cannot be hit for now; the end of a colony belongs to step 7.
- Work far from the nest was never taken up: the walk made it less attractive than wandering. On a world 140 cells wide, distance now counts a quarter as much.
- With nights, rain and raids together the store ran dry and ants starved. A claim now leaves 0.7 crumbs for every ant, and finds come every 18 seconds.

Different from the design: majors come from guard rooms, not from feeding larvae meat. Raiders do not go for the brood. There are no predators at the door, no parasites, no fights over a find on the surface, and other ants do not move away from alarm. A rival's chunk is claimed like any other and then fought for, not won by fighting. Not yet tried on the phone.

### Step 7: the long game (done)

- **Goals.** Fourteen goals run one at a time on the line above the bar, from "dig a tunnel" to "hold ground in the bottom row", each with a bar for how far along it is. Warnings (rain, raiders, enemies in the nest) and a few hints still take the line when they matter more.
- **The flight.** A new room purpose, **flight**. A colony of 100 ants raises a princess for every 4 cells of flight room. On a calm morning with no enemy about, the princesses at least 2 minutes old walk out and fly. Each has an even chance of founding a colony somewhere else.
- **The score** is daughter colonies, kept on the device over all your colonies, with how many colonies you have founded and the most ants any of them had. Seven achievements are kept the same way.
- **The queen can die:** of hunger if she is left desperate for 3 minutes, or in water with no dry ground within four cells. A princess in the nest takes her place at once. With none, the colony is at its end: no more eggs, a full-screen notice, and a "found a new colony" button in the Nest sheet. A new colony gets a new world; the score and achievements stay.
- **Saving.** The colony is saved on the device every 20 seconds and when the page is hidden, and carries on from there when the page is opened again: the map, every ant, the rooms, scent, water, weather, claims, what has been dug up, the goals. A save is about 20 KB.

Built for it:

| Piece | What |
|---|---|
| `modules/progress.js` | Used as it is for goals, achievements and the profile |
| `modules/save.js` | Used as it is; every module of this game has its own `save` and `load` |
| `games/ant-colony/modules/zones.js` | Loading puts back a cell's purpose even if the cell is under water at that moment |
| The colony's rules | Princesses, the flight, the heir, the queen's death, its own `save` and `load` |

Measured, headless:

- **Saving:** a game saved in the rain with a claim made, a room named and marks pending, restored into a new simulation, gives the same numbers for everything compared (ants, the map, stores, brood, rooms, chunks, mound, weather, water, the goal) and plays on.
- **The flight:** six ripe princesses flew on the first calm morning, and four founded colonies.
- **The heir:** with a princess in the nest, the queen's death made her queen and she went on laying; a second death with no princess ended the colony.
- **Three different worlds,** an hour each with the scripted player, weather and raids: the colony stays alive in all three (41 to 80 ants at the hour), no ant dies of hunger, 5 to 8 raids are beaten off, and 3 to 7 chunks are claimed.

Found on the way:

- With the queen open to raiders, she died in the first or second raid even with majors, because she sits at the foot of the shaft where every raider passes. Raiders pass her by; hunger and water can still kill her.
- A run of night, rain and a raid could still starve a colony whose store had just paid for a claim. An ant now lasts 150 seconds once desperately hungry (it was 60), and a claim leaves a crumb for every ant.
- A flooded food cell lost its purpose on loading, because a purpose can only be given to open ground. Loading now puts it back regardless.

Different from the design: there is no title screen or founding stage with the queen alone; a new colony starts with 40 workers as before. A dead colony cannot be continued from an earlier save. Not yet tried on the phone.

### Where it stands

Steps 1 to 7 are done. Step 8 is balance, then art and ambient sound. Nine generic modules were written for this game (`items`, `ground`, `tasks`, `zones`, `scent`, `claims`, `weather`, `water`, `foes`); `progress`, `save`, `mapgen` and the page kit were reused.

Things the design asked for that are not in: gravel and a spring, damp and warmth layers and brood moved by warmth, food deciding a larva's body, the dead and a waste room, predators and parasites, fights over a find on the surface, ants following a trail cell by cell, chunks paid for by carrying, and drawing by density when zoomed out.

### Step 8: art (first pass done)

- **The look,** chosen after two rounds of proposals: low resolution, drawn as true to life as the pixels allow. A cell is 12 pixels. Real soil (dark topsoil, loam, sand, clay with grey seams, pebbles), roots, grass and sky; tunnels are the earth behind them in shade; the ant is a garden ant seen from the side, near-black with one touch of light on the abdomen. Nothing is shared with The Lord's Will. The style sheet and the sprite contract are `art/colony/STYLE.md`; the approved pictures are `art/proposals/colony2/2-soil-12px.png` and row A of `art/proposals/ants/ants-large.png`.
- **How it was made:** three agents drew in parallel, each with a Lua script run in Aseprite's batch mode on a shared library (`art/colony/lib/px.lua`), each looking at its own contact sheet and redrawing. 77 drawings: 32 of ground (six tiling textures, pebbles, grass, roots, five skies, water), 8 sheets of ants (young, grown, old, major, raider, queen, princess, rival queen; seven frames each) and 37 of things (heaps of crumbs and soil, eggs, larvae, pupae, four stages of fungus, what an ant carries, the dig mark, rain).
- **In the game:** `tools/pack-colony-art.py` packs them into `games/ant-colony/art.png` with `art-atlas.js`. The ground is painted by the game's own view (`view.js`): each cell from its texture, with the edge between earth and hollow bitten unevenly, the roof of a tunnel in shadow and its floor lit. Only cells that changed are painted and sent again. Ants and everything that lies about are drawn by `painter.js` on the layer over the map: an ant stands on the floor under it and faces the way it walks, and is turned a quarter in a shaft with its feet to the wall.
- **Rooms are known by what is in them.** A room's colour is only a line along its floor, and a tint while the Rooms sheet is open. Scent is shown only while the Scent sheet is open.
- **Engine, generic:** a view may repaint and re-send only the part of the ground that changed (`view.groundMipmaps: false`, `_rebuildStatic()` returning rectangles).
- **Measured in the browser at phone size:** the whole ground paints once in about 240 ms at the start; after that a frame's page work and drawing take about 1 ms.
- **Seen:** the local server can now save a picture of the page (`POST /__shot/<name>.png`), which is how this pass was looked at.

**Polish pass:**

- **Things lie on floors.** Only the cells of a room that have solid ground under them hold anything. A food cell holds 16 crumbs (it was 8, in every cell of the room), and its heap shows how full it is. If the ground under a floor is dug out, that part of the floor holds nothing.
- **Ants stand on the floor of the room they are in:** the first solid ground under them, up to four cells down.
- **The mound is one heap:** its top runs smoothly from each cell's height to the next and falls to the ground at its ends, with the texture taken from where each pixel is on the map.
- **Borders between kinds of earth wander** by a few pixels instead of following the cells.
- **The page has the earth's colours:** dark brown with pale text, the same by day and by night.
- **Tunnels are a little darker** against the soil (60% of its brightness, from 66%).

Still open: an ant on a ceiling is not turned over; the sky's lightest band meets the dark topsoil in a thin pale line; no sound. Not yet tried on the phone.

### The queen room

The queen sits and lays only in the **queen** room, on a floor with dry earth under it. The colony starts with one, a side chamber off the shaft above the main chamber (`QUEEN_ROOM` in nest.js). There is one at a time: the player takes the purpose off the old room, then names the new one in one stroke. With no queen room, or none of it dry, she lays nothing and the goal line says so.

### Rain reworked: one water level, and a surface event

- **Underground**: water is an amount. Rain lets 0.25 cells a second in by each open way out; it lies flat in the lowest space it can reach and its surface rises row by row. A row floods only when the whole of it is full, so a wide room takes long and a pit below the rooms takes the water first. It soaks away into loam slowly, into sand faster, into clay never. What is under the level is shut to the ants; brood there is lost, food only out of reach.
- **On the surface**: nobody goes out, every trail up there is washed away when the rain starts (what was known must be found again), and three finds turn up when it stops.
- **The starting nest**: the shaft comes down into a central room with no purpose, the lowest place in the nest. A tunnel from the top of its right wall climbs to the food room, one from the top of its left wall to the queen's room; both rooms' floors are above the central room's roof. The central room takes the rain first (25 cells before the side rooms' floors get wet), and the ways to the rooms are the last part of it to go under.
