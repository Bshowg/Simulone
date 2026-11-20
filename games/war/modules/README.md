# WAR: its own modules

Modules that only WAR uses. They are written like the shared ones in `modules/` (generic: the game passes its numbers
in), but live here until a second game needs one. The shared modules are documented in
[modules/README.md](../../../modules/README.md).

A battle is ordinary agents with an action matrix. Every action is a point the man walks to (the engine's `@point`
actions, see engine/README.md, Points): his slot in the ranks, the enemy he goes for, a step back, the edge of the field.
The game turns orders and what a man sees into matrix inputs (`rules.js`), so the same fear weighs differently under
"hold" and under "charge".

## regiments.js

Regiments: a standard that faces a way and moves, a formation that gives every man a slot around it, and an order.

```js
const regiments = createRegiments({ sides: ['march', 'crown'], formations: FORMATIONS,
  speedOf: type => cellsPerTick, engaged: i => inAFight(i), away: i => running(i) });
const r = regiments.add({ side: 0, kind: 'spear', type, x, y, face, files: 24, formation: 'line' });
sim.add(x, y, { type, regiment: r, slot: 0 });      // its men
regiments.order(r, 'advance', { x, y, face });       // or null to stay; the order's name is the game's
```

| Call | Does |
|---|---|
| `slotPos(r, s, out)`, `slotOf(i, out)` | Where slot s of a regiment is now, or man i's slot |
| `size(r)` | [width, depth] in cells as it stands |
| `order(r, name, dest)`, `setFormation(r, name, files)` | Give an order and a destination; change formation or width |
| `all(side)`, `get(id)`, `of(i)`, `clear()` | The regiments on the field |
| `save()`, `load(data)` | The regiments as plain data |

- Formations are shapes: `ranks` (a line or column, `files` wide), `wedge`, `square` (three deep, every side out).
- Each tick the standard walks to its destination at its men's pace, slower while they are out of their places, not at all
  while a fifth of them are fighting, and wheels before marching off at an angle. Two standards of one side are kept apart.
- Every few ticks it counts how each regiment stands: `men`, `active` (not running), `cohesion` (in their places),
  `engagedShare`, average `fear` and `fatigue`, `broken` (fewer than a third still standing with it). It closes up the
  ranks now and then: slots handed out again front first.

## combat.js

Fighting for armies of thousands. Every man knows the nearest enemy he can see, strikes him in reach, and archers loose
arrows that fly and land.

```js
const combat = createCombat({ kinds: KINDS, sight: 12, flank: { dot: -0.35, damage: 1.7 }, woundedShare: 0.55,
  sideOf, facing, canStrike, braced, away, cover, rise, onHit, onDown });
combat.shoot(i);                                     // when an archer's loosing action finishes
```

- The nearest enemy is looked for a sixth of the men each tick, ring by ring through a grid of 4-cell blocks, so empty
  ground costs nothing. The same pass counts friends, enemies and friends running around each man (`near`, `nearFoe`,
  `nearAway`), for morale.
- A blow: attack against armour, times a flank bonus from behind the man's facing, a charge (mounted, at speed), broken on
  a braced line (spears, a square), more against a man running, more from higher ground.
- Arrows fly for distance ÷ speed ticks, aimed where the target will be, with spread growing with range; trees stop some.
- A man at no health is removed as `'killed'` or `'wounded'`. `down` counts them per side.
- For the page: `hits` keeps the blows, arrow hits and men struck down of the last `marks` ticks (12), with where and when;
  `blowT[i]` and `hitT[i]` count down the ticks of a man's striking pose and of his reeling from a blow.
- Agents whose type has no entry in `kinds` (WAR's fallen) are not fighters: they are left off the grid and never targeted.

## morale.js

Fear and fatigue as two needs. Nothing here makes anyone run: running scores higher when fear is high.

- Fear rises with blows (more from behind, a little more from arrows), friends struck down near him, enemies outnumbering
  his friends, friends running past (running is catching), and his regiment wasting away. It falls among friends, in his
  place, near the standard, and faster with no enemy near. Each kind has a `nerve`; experience steadies.
- Fatigue rises while hurrying and fighting, and falls while standing.

## general.js

A general for one side, giving the same orders the player gives: foot advance in line and close; archers keep at bow
range and step back from foot; horse wait on the flank, then ride round to strike archers or a busy regiment from behind;
spears square against horse. When his army is far weaker he falls back (`yielded`). `on` turns him off.

## campaign.js

The war around the battles: provinces joined by roads, a day at a time. Not an engine module; its state is plain data.

```js
const campaign = createCampaign({ provinces, roads, kinds, full: 200, most: 20, rules });
campaign.newWar(); campaign.march(army, 'corvane'); campaign.endDay();
if (campaign.pending()) { /* fight campaign.battleSides(), then */ campaign.afterBattle(winner, lossesByRegiment); }
```

| Call | Does |
|---|---|
| `march(a, to)`, `route(from, to)`, `daysTo(a, to)` | Send an army by road |
| `canRaise(a, kind)`, `raise(a, kind)`, `fillCost(a, r)`, `fill(a, r)`, `canTrain(a)` | Regiments from a town of one's own |
| `endDay()` | The other side's turn, marches, a battle or a town taken, gold, men, the wounded, training |
| `pending()`, `battleSides()`, `afterBattle(winner, losses)` | A battle to fight, who is in it, what it cost; losers fall back or give up |
| `owner(id)`, `armies(side)`, `income(side)`, `upkeep(side)` | How the war stands |

- A town keeps a garrison: an army at an enemy town fights it first. The war is won by taking the other capital, and lost
  with no army and no gold to raise one.
- Men who fled a battle come back; the wounded heal a share a day, faster in a town of one's own, and some die.
