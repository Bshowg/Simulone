# The Lord's Will: game design document

A medieval settlement builder for phones. You grow a hamlet into a chartered town, then a region of towns. The people run themselves; you decide what is built, where, and what the settlement owes and keeps.

Status: first draft. Numbers are starting points for balancing, not decisions. Sections marked **Open** need an answer before they are built.

## 1. The game in one paragraph

You are the steward of land granted by a lord. You begin with five families, a well and a store of grain. Each year has four seasons: you sow in spring, build in summer, harvest and pay the lord's levy in autumn, and live off what you stored in winter. As the settlement grows it changes kind, not only size: a hamlet shares everything, a village has trades, a market town runs on coin, a chartered town has guilds and trades with its neighbours. Later the lord grants you more land, and then lets you buy it: other settlements on different ground, tied to the first by trade.

## 2. Pillars

1. **People run themselves.** There are no orders to individuals. Every person weighs their needs and picks what to do. The player shapes the place they live in.
2. **Each stage plays differently.** Growth changes the rules of the economy (common store, then trades, then coin), so the late game is not the early game with bigger numbers.
3. **The year is the rhythm.** Seasons give every sitting a beginning, a deadline and a test.
4. **A sitting is a year.** About twelve minutes at normal speed, playable in less at 2× or 4×, and safe to put down at any moment. Nothing happens while the game is closed.
5. **Readable on a phone.** A few numbers that matter, reasons given in words, and anything on the map can be tapped to see what it is doing.

## 3. What the player does

| Verb | What it is |
|---|---|
| Build | Place buildings, drag out fields, lay roads. Costs goods from the common store (later, coin too). Time stops while building. |
| Remove | Take a building or road away. Part of its cost comes back. |
| Set policies | A handful of settlement-wide dials: rations, the share of the harvest kept as seed, and, once coin exists, wages, prices and rent. |
| Answer events | Some events offer a choice (pay the bandits, shelter the refugees, send men to the lord's war). |
| Inspect | Tap a person or building: who they are, what they are doing and why, what the building made this season. |
| Travel | From the market town stage: open the region map, visit another settlement, send goods between them. |

The player never: assigns a person to a job, tells anyone where to walk, or fights.

## 4. The year

A year is four seasons of about three minutes each at 1× speed. A day and night cycle runs inside each season (people sleep at night), with several days to a season.

| Season | Farming | Other effects |
|---|---|---|
| Spring | Fields are sown: takes seed grain and farm work | Roads are muddy: walking is slower off road |
| Summer | Fields grow; little farm work | Best building weather; fairs and travellers |
| Autumn | Harvest: a rush of farm work | The levy is collected on the last day |
| Winter | No farm work; farmers are free for other jobs | Warmth becomes a need; firewood burns; no building of stone |

The end of each season shows a short report: what was made and used, who was born, who died, who arrived or left, and what the next season needs.

## 5. People

### Needs

| Need | Met by | Notes |
|---|---|---|
| Hunger | Eating at home from the common store (hamlet), at a bakery or tavern (later) | Bread satisfies longer than porridge |
| Rest | Sleeping at home | A crowded house rests people less |
| Warmth | A hearth at home, burning firewood | Only grows in winter and on cold nights |
| Faith | Chapel, then church | Appears at the village stage |
| Company | The well, the green, the tavern, the market | Low company lowers mood, and mood decides who leaves |

A need left desperate drains health. Health at zero is death. Mood is the average of how well needs have been met lately; unhappy families leave in spring, and a settlement known to be happy draws newcomers.

### Stations

A person's type in the engine is their station. It decides which work they can do and how they weigh things.

| Station | Appears | Work | Leans towards |
|---|---|---|---|
| Peasant | Hamlet | Fields, woodcutting, building labour | Food and rest |
| Craftsman | Village | Mill, bakery, smithy, carpenter, mason | Coin, once it exists |
| Clergy | Village | Chapel, church, later a school | Faith; lowers others' need for it by serving |
| Merchant | Market town | Market stalls, carts between settlements | Coin and company |

A child grows into the parents' station unless the settlement has unfilled work above it, in which case some rise. Nobody falls a station except through an event.

### Lives

Households, births, ageing, death and moving house work as in the town example: a couple with a free bed may have a child, children grow up and look for a house of their own, the old die. Lifespans are short (about twelve game years) so generations turn over within a few sittings.

Everyone has a name, and families are kept as a tree: parents, partner, children, and the house they hold. Tapping a person shows their card and lets the player walk the tree, including the dead. Family names come with the first settlers and with newcomers; given names are drawn from a list.

## 6. The settlement stages

Each stage is a level in the progress module. Reaching one is a condition on stats; it unlocks buildings and switches on new rules.

### Hamlet (up to about 30 people)

- **Economy:** goods only, one common store. Resources: grain, firewood, timber.
- **Buildings:** hut, well, field, woodcutter's lodge, granary, common green.
- **The test:** enough grain and firewood stored to get through the first winter.
- **To become a village:** 30 people, a granary, and two winters survived without a death from hunger or cold.

### Village (30 to 120)

- **Economy:** still goods only, but with chains. Grain becomes flour at the mill and bread at the bakery; timber becomes planks at the carpenter; ore becomes tools at the smithy. New resources: flour, bread, planks, stone, tools.
- **Buildings:** cottage, mill, bakery, chapel, carpenter, smithy, quarry (if the land has stone), barn, tavern.
- **New rule: the levy.** On the last day of autumn the lord takes a share of the year's grain (a tenth to start). Falling short costs standing with the lord; three shortfalls bring a harsher steward's demand (a fine in goods, or men taken for a season).
- **To become a market town:** 120 people, a church, a tavern, the levy paid in full three years running. The reward is the market charter.

### Market town (120 to 400)

- **Economy:** the charter brings coin. Work pays wages, bread and ale have prices, houses pay rent. The settlement has a treasury. Households become poorer or richer, and the poor weigh paid work more heavily and paid comforts less.
- **Buildings:** market square, town house, brewery, weaver, tailor, guard house, almshouse, stone walls and gates.
- **New rules:** the levy may be paid in coin; fire spreads between timber buildings; poverty lowers mood and feeds unrest.
- **New rule: the region opens** (section 8). With the charter the lord grants a second, smaller piece of land.
- **To become a chartered town:** 400 people, walls, a treasury kept in surplus for three years, and a second settlement at village stage or above.

### Chartered town (400 and more)

- **Economy:** guilds raise what a trade makes but demand wages; a yearly fair brings merchants and a burst of coin.
- **Buildings:** guildhall, great church, fairground, school, hospital.
- **New rules:** plague years, rival towns that draw your merchants, the lord's wars.
- **New rule: land can be bought** (section 8): further pieces of different kinds and sizes.
- **End state:** there is no ending. Titles in the region (section 8) are the long game.

### Sliding back

A settlement that falls below half the population of its stage for a full year drops a stage: its higher buildings close until it recovers. Nothing is ever lost outright.

## 7. Pressure

### The lord

The lord is one fixed character for now, and the game's voice for goals and deadlines. The levy is yearly. Now and then he asks for more: timber for his hall, men for a season, lodging for his retinue. Standing with the lord is a stat; high standing brings charters and gifts, low standing brings fines.

### Events

Events come from the calendar and from chance, and each is announced a little ahead so the player can prepare.

| Event | When | Effect | The player's answer |
|---|---|---|---|
| Hard winter | Winter, some years | Warmth need grows faster, firewood burns faster | Stores laid in beforehand |
| Bad harvest | Autumn, some years | Fields yield half | Granary stock; buy from another settlement |
| Fire | Dry summers; market town onwards | A timber building burns and may spread | Wells nearby, stone buildings, a watch |
| Travellers | Summer | Families ask to settle | Accept if there are beds; refuse |
| Wandering merchant | Any season | Offers a trade of goods | Accept or not |
| Bandits on the road | Village onwards | Demand grain or coin; refusal risks a raid that empties a store | Pay, refuse, or have guards |
| Sickness | Crowded settlements | Health drains for a season | Clean water, an almshouse, later a hospital |
| The lord's war | Chartered town | Asks for men or coin | Send, pay, or lose standing |

Raids, wars and fights are never drawn as combat. They are events with outcomes.

### Losing

There is no game over. Failure is people dying or leaving, standing lost with the lord, and a settlement sliding back a stage.

## 8. The region

The region is the set of lands the player holds. Each land is a settlement map of its own.

| Land | When | Size |
|---|---|---|
| The first grant | Start of the game | 300 × 300 cells |
| The second grant | Becoming a market town | 150 × 150 cells |
| Bought lands | From chartered town onwards, for coin and standing with the lord | Squares and rectangles of various sizes, for example 150 × 300 or 200 × 200 |

- **Lands differ by kind.** Farmland yields more grain; forest has timber and game but poor soil; hills have stone and ore; a river crossing draws travellers and trade. No land has everything, which is the reason to hold a second one. Bought lands are offered a few at a time, each showing its kind, size and price.
- **Shapes.** Every land is a square or a rectangle. Lands differ in size and proportion, not outline.
- **Size on a phone.** 300 × 300 is 90,000 cells, far more ground than the examples use. Route work and the ground picture at that size have to be measured on the phone in step 1; if it is too heavy, the first grant shrinks and the others with it.
- **Every land is generated,** from a seed and its kind, by the map generator (section 11), so no two games have the same ground.
- **One settlement is live at a time.** The one on screen is simulated in full. The others advance by summary: what each made, used and stored per season when it was last watched, applied season by season, with events resolved by their odds. Visiting a settlement makes it live again from its saved state.
- **Trade is counted, not drawn.** A cart sent from one settlement leaves its store and arrives in the other's a season later. A standing order repeats it every season. Merchants (the station) are the carters: a settlement can only run as many carts as it has merchants and a market or barn to load from.
- **Settling new land.** A new settlement costs families, grain and tools from an existing one.
- **Progress at three levels.** Each settlement has its own stage, goals and stats. The region has its own: lands held, charters, titles from the lord (reeve, bailiff, lord mayor). The player's profile keeps achievements across games.
- **Only the player's settlements exist** in the region for now.

## 9. Progression and goals

- **Stages** are the levels (section 6).
- **Goals** run one at a time and teach the game: build a hut, sow a field, store 60 grain before winter, build a granary, and so on through each stage.
- **Unlocks** come from stages, from the lord's standing (stone walls need his leave) and from the land (no quarry without stone).
- **Achievements** are kept in the profile: a winter with no deaths, a town of a thousand, five lands held at once.
- **Titles** are the region's long goals.

## 10. The screen

- **The map fills the screen,** isometric, drag to pan and pinch to zoom.
- **Top strip:** season and day, speed, and the three numbers that matter most at the current stage (hamlet: grain, firewood, people).
- **Bottom bar:** build, policies, people, region, and the current goal as one line.
- **Panels slide up from the bottom** and never cover the whole map.
- **Tapping** a person or building opens a small card.
- **Toasts** for events and things earned; the season report is the one full-screen moment.
- **Art:** pixel art on the engine's sprite sheets, replacing placeholders building by building. Seasons recolour the ground.
- **Sound:** ambient only, no music: wind and birds by season, the mill, the smithy, the church bell, the market's murmur, louder as the view zooms in on its source.

## 11. What exists and what has to be built

The rule for everything below: **a mechanic that another game could use is a generic module with its numbers passed in; anything about lords, grain or winter lives in the game's own files.**

### Already there

| Piece | Used for |
|---|---|
| Engine: agents, needs, matrix decisions, routes, build mode, isometric view | Everything on the map |
| Engine: types, jobs by type | Stations and their work |
| Engine: ages | Children, adults, elders |
| `modules/economy.js` | Common store, chains (a job that uses grain and makes flour), coin, wages, prices, build costs |
| `modules/progress.js` | Stages, unlocks, goals, achievements |
| Town example's `rules.js` | Households, births, deaths, moving house (to be promoted, see below) |

### New generic modules

Each is optional, knows nothing of the others, and talks through the engine's hooks or plain callbacks.

| Module | What it does | What the game gives it | Meets the others through |
|---|---|---|---|
| `calendar.js` | Turns ticks into days, seasons and years. Announces "season began", "year ended". Offers the time of year as inputs to the decision matrix (so warmth can matter only in winter) and as stats. | Lengths, season names, which inputs to expose | Stats for progress; a `when` for events |
| `events.js` | A director. A table of events, each with a condition, odds, a warning time, a duration, effects and optional choices. Decides what happens when, announces it, applies and removes effects. | The table; functions that carry out named effects | Conditions in the progress module's form; seasons from the calendar |
| `lives.js` | Households, births, growing up, death from age and from needs, mood, leaving and arriving. Names and the family tree, including the dead. Promoted from the town example. | Lifespans, odds, what counts as a home, name lists | Engine columns; counters for progress |
| `policies.js` | Named dials with a range and a current value, each bound to something a game exposes. Saved with the game. | The dials and what each one changes | Calls the economy's adjusters |
| `save.js` | Takes a game apart into plain data and puts it back: map, buildings, people, and each module's own part. | A storage key | A `save()` and `load(data)` pair that every module may implement |
| `mapgen.js` | Makes a map from a seed: a rectangle of any size, layers of terrain from noise, and features placed by rule (a river, forest, stone outcrops, a road in). The same seed always gives the same map. | Width and height, the terrain kinds and how much of each, the features | Plain calls on the engine's world; nothing else |
| `region.js` | Several maps under one game. Holds each map's saved state, makes one live, advances the others by summary, moves goods between them after a delay. | The lands; how to summarise a map; what may be moved | `save.js` for map states; the economy's stores; progress scopes |

### Changes to what exists

| Where | Change | Why |
|---|---|---|
| Progress module | A third lifetime between run and profile, and named scopes: a stat, unlock or goal belongs to the **map**, the **game** (the region) or the **profile**. Conditions can read any of them. | Settlement stage, region titles and lifetime achievements are three different lifetimes |
| Economy module | Flows whose amounts can be changed while playing (rations, wages, prices); a store limit per resource that buildings raise (granary, barn); a seasonal multiplier on a flow. | Policies, storage as a reason to build, harvests |
| Engine | A prefab whose size is dragged out, within limits, with jobs and output scaling by area. | Fields |
| Engine | "What is here?": given a point on screen, the person or building under it. | Tap to inspect |
| Engine | Tile colours that can be swapped while running. | Seasons |
| Page | Ambient sound: looping layers whose loudness follows the season and what is on screen. Shared page code, like the kit. | Sound |
| Page | A small kit for the phone layout: top strip, bottom bar, sliding panels, cards, toasts. Not a simulation module; shared page code. | Every game needs it and every example has hand-written its own |

### The game's own files

`games/lords-will/` holds only this game: the numbers (needs, stations, buildings, resources, season lengths), the tables (stages, goals, unlocks, events, policies, lands), the levy and the lord's standing as a small rules module, and the page.

### Not planned

- **Carriers and stock per building.** One common store per settlement. Revisit only if distance inside a settlement should matter.
- **Combat on the map.**
- **Anything needing a server:** accounts, cloud saves, other players.

## 12. Order of work

Each step ends with something playable on the phone.

1. **Hamlet.** `calendar.js`, `mapgen.js` for the first grant (300 × 300, farmland), measured on the phone, the game's files, fields, the first winter. Question to answer: is one year fun?
2. **Keeping it.** `save.js`, so a settlement lasts across sittings.
3. **Village.** `lives.js` promoted with names and family trees, chains, the levy, `events.js` with three events (hard winter, bad harvest, travellers), tap to inspect.
4. **The phone screen.** The page kit, season report, goals as a tutorial.
5. **Market town.** Coin, `policies.js`, fire, poverty.
6. **The region.** Progress scopes, `region.js`, the second grant and carts; then buying land of other kinds and sizes.
7. **Chartered town,** art and ambient sound.

## 13. Decisions and open questions

Decided:

1. **Sound:** ambient only.
2. **The region:** the first land is 300 × 300 cells; becoming a market town unlocks a second land of 150 × 150; a chartered town can buy lands of different kinds and sizes. All lands are squares or rectangles.
3. **Pace across sittings:** nothing happens while the game is closed.
4. **Names and faces:** people have names and family trees the player can follow.
5. **The lord:** one fixed character for now.
6. **Title:** The Lord's Will.
7. **Map generator:** maps are procedural, made by a separate generic module.
8. **Land sizes:** a size unit is 30 cells on a side, so the old "x10" is 300 × 300 and "x5" is 150 × 150. To be tried; it may change after measuring on the phone.

Nothing is open.

## 14. Progress

**Step 1, the hamlet, is built** in `games/lords-will/` (numbers in `hamlet.js`, the farming year in `rules.js`).

What exists: generated 300 × 300 land (forest, a river with fords, a road in), five huts and a well, 16 people with whole lives, the four seasons, fields dragged out to size and sown and reaped by shifts, woodcutters whose yield follows the trees in reach, a common store with a limit that granaries raise, cold in winter answered by firewood at the hearth, newcomers in spring while spirits are high and beds are free, a season report, eight goals and five achievements, and the step to village as a condition.

Built as generic pieces: `calendar.js`, `mapgen.js`, `lives.js` (promoted), store limits and place-dependent amounts in the economy, drag-sized and outdoor buildings in the engine.

First numbers, from headless runs of a scripted steward:

- A steward who marks out fields, builds two lodges and a granary in the first year gets through the first winter with nobody lost, and reaches 30 people in the third year.
- A steward who does nothing loses everyone to loneliness by the first autumn (there is no green to meet on). A steward who builds no lodge loses everyone to cold in the first winter.
- One granary is not enough past about 30 people: grain is lost at harvest and runs out the next summer.
- The simulation takes about 0.02 ms a tick at 40 people on a desktop; repainting the ground after an edit takes about 16 ms there. Neither is measured on a phone yet: the page shows both at the bottom.

**Step 2, keeping it, is built.** `modules/save.js` saves the map, the people and each module's part; the hamlet is saved on the device at the start of every day, after building and when the page is put away, and picked up on the next visit. "New hamlet" starts over. A save is about 23 KB.

**Step 3, the village, is built.**

- **Trades and chains.** Carpenter (timber to planks), mill (grain to flour, never below 120 grain), bakery (flour and firewood to bread), cottage and chapel, all unlocked when the hamlet becomes a village. Bread is eaten in preference to porridge and makes grain go half as far again.
- **Faith** builds up only from the village stage and is answered at the chapel. Like loneliness it lowers spirits but never becomes an emergency; low spirits stop newcomers arriving.
- **The levy.** When autumn ends the lord takes a tenth of the year's harvest. What cannot be paid is owed the next year and costs his regard.
- **Sowing and harvest come first.** While any field has work, every other workplace keeps one worker.
- **Events** (`modules/events.js`): a hard winter, a bad harvest, and travellers asking to settle, which is a choice.
- **Names and family trees** in `modules/lives.js`; tapping a person or a building opens a card, and kin can be followed from it, the dead included.
- **Next stage** as a condition: 120 people, a chapel, and the levy paid in full three years running.

From headless runs: a steward who keeps houses near wells, adds fields as people arrive and builds a second granary holds a village of about 50 for years and pays the levy. A bad harvest with thin stores still empties the village in one summer. Houses built 20 cells from the nearest well cost their people most of the day in walking.

Deferred from step 3:

- **Stations as kinds of people.** The engine uses the "type" of a person for their stage of life, so it cannot also be peasant, craftsman or clergy. For now a trade is whoever holds the job. Doing this properly is an engine change.
- **Smithy, quarry, barn and tavern**, and the resources stone and tools.
- **The lord's harsher demands** after three shortfalls: for now debt and lost regard only.
- **Fire and sickness** as events.

**Step 4, the phone screen, is built.** The game's page now runs on a shared kit (`kit/kit.js`, documented in `kit/README.md`):

- **The map fills the screen** between a top strip (the moment, three or four key numbers, pause and speed, what is coming) and a bottom bar (Build, People, Stores, Goals, News, More).
- **Sheets slide up** from the bar and the map shrinks to make room; it is never covered whole. Build is one of them, and time stands still while it is open.
- **Over the map:** short notices for what matters, the card of whoever was tapped, and an event's question.
- **Full screen, twice only:** the welcome, and the report when a season ends (which can be switched off under More). Becoming a village is announced the same way.
- **Goals as a tutorial:** the current goal is always one line above the bar, the Build button pulses when the goal is something to build, and finishing a goal names the next.

Policies and the region have no button yet; they come with the market town and step 6.

**Step 5, the market town, is built** (the stage is reached at 120 people, a chapel, and the levy paid in full three years running).

- **Coin.** The charter gives the treasury 300 coin and every person 4. The treasury pays a wage for every finished shift and takes rent for every night under a roof and the price of every loaf. Households share one purse. The poor lean towards paid work and away from what costs, and poverty lowers spirits.
- **Policies** (`modules/policies.js`): rations from the start (short rations stretch the grain and sour the mood); wage, rent and the price of bread from the charter.
- **Buildings:** brewery (grain to ale, never below 300 grain), tavern (ale for coin: company), market (brings merchants), watch house.
- **Merchants** come to an open market and buy 100 grain for 50 coin or 100 firewood for 30: the only coin that comes in from outside.
- **The levy** takes coin, one a measure, for what the granary cannot cover.
- **Fire** in summer: a timber building catches, is out of use while it burns, may set light to neighbours within three cells, and after eight hours is saved or lost depending on a well within 10 cells and a watch house within 40.
- **Next stage** as a condition: 400 people, a watch house, 1,000 coin in the treasury.

From headless runs: with the default wage, rent and price the treasury drains towards households within a year, so the steward has to adjust them or sell to merchants. Hamlets saved before this step still load.

Deferred from step 5: the town house, weaver, tailor, almshouse and stone walls; unrest; sickness; seed share as a policy.

**Step 6, the region, is built.**

- **Lands** (`LANDS` in `hamlet.js`): the first grant (farmland, 300 × 300), the second grant (woodland, 150 × 150) given with the market charter, and two lands the lord sells from the chartered-town stage (river meadows 150 × 300, a heath 200 × 200). Kinds differ in how they are generated and in what their fields give: woodland 0.75, farmland 1, riverside 1.2.
- **Settling** a granted land: a party carries 200 grain, 100 timber and 40 firewood from the store, and nine newcomers start there with three huts and a well.
- **One land is played at a time.** Going to another is a button under Region. The others carry on by their book: what each of their last four seasons added to or took from their stores.
- **Carts:** a load of 50 sent once, or the same every season as a standing order (three per land). They set out when the season ends and arrive a season later.
- **Progress at three levels:** each land has its own stage and goals; the lands held and the titles (reeve at two lands, bailiff at two villages) belong to the region; achievements to the profile.
- **Saving:** the whole region is one save. A hamlet saved before this step becomes its first land.

Different from the design:

- **Settlers are newcomers,** not families taken from the old settlement.
- **People in a land that is not being played stand still:** nobody is born, ages or dies there. Only the stores move.
- **A store run to nothing while away costs nothing more:** it is reported, but nobody starves for it.
- **The treasury stands still** while a land is not being played.
- **Events do not happen** in lands that are not being played.
- **Carters are not counted:** the limit is three standing orders a land, not the number of merchants.
- **Buying land** is in place but cannot be reached by playing, because the chartered town stage (step 7) does not exist yet.

**The chartered town (the first part of step 7) is built.** It is reached at 400 people, a watch house, 1,000 coin in the treasury and a second settlement at village stage or above.

- **Guilds.** With a guildhall open, the carpenter, mill, bakery and brewery make half as much again a shift, and the treasury pays a coin more for each.
- **The fair.** With a fairground, a fair is announced on the first day of summer and held on the second: a coin a head for the treasury, and spirits lifted while it lasts.
- **Great church and hospital.** The church holds eighty at mass. An open hospital halves the chance of being struck in a plague.
- **Plague** some springs, lasting through the summer: every hour anyone may be struck and lose more than half their health; a second blow within about ten hours kills. In tests about 8% died without a hospital and 5% with one.
- **A rival town** some autumns: pay the lord 150 coin to forbid it, or no merchants come for a year.
- **The lord's war** some springs: send 10 men (they do not come back), send 300 coin, or refuse and lose 25 of his regard. Under a regard of 30 the levy is 15% of the harvest instead of 10%.
- **Land for sale.** The river meadows (400 coin) and the heath (300 coin) can now be bought and settled.
- **Buildings here cost coin** as well as timber and planks.
- **Title:** lord mayor at four lands.

Still to come in step 7: art and sound. Before that, by agreement: balance and refinements.

Deferred from the chartered town: the school; stone walls; sliding back a stage when a settlement shrinks.

**Balance pass 1: growth and famine.**

- **Stages** are now reached at 30, 80 and 200 people (were 30, 120 and 400).
- **Newcomers** each spring: up to two families for a hamlet, four for a village, six for a town.
- **Cottages** sleep eight (were six).
- **Sowing and reaping** go faster a shift (16 and 20 cells, were 10 and 14), so fields a walk away still get worked.
- **Hunger** kills in five days (was three and a half), and anyone with a need left desperate for a day and a half may walk away (was three days). A famine now empties houses before it fills graves.
- **Seed corn** is kept back from the table through winter and spring: up to four grain a head, or what the unsown fields need if that is less.
- **Relief:** when the store holds under two days of food the lord may offer eight grain a head, at ten off his regard.
- **Merchants sell grain:** 100 for 80 coin.
- **An emptied settlement is taken up again** in spring by two families, if under six people are left and the store holds 100 grain.
- **Bad harvests** not before year four, **hard winters** not before year three.

From three scripted runs of fourteen years: all reached village in year three and market town in year five or six. Two held between 150 and 170 people from year eight on with grain to spare. One ran its grain down and lost its people over three years, which before this pass happened in one season. None reached 200: at that size people living far from a well and fields far from houses hold the place back, which is for the next pass. Firewood and timber still pile up (10,000 and 5,000 by year fourteen).

**Balance pass 2: reaching 200.**

- **Wells give water to the houses within 12 cells.** People in those houses drink at home; everyone else walks to a well for every drink. A house's card says which it is, and a well's card how many houses it serves.
- **Nobody takes work more than 45 cells from their door** (was 80). A field or lodge beyond that stays unworked, and its card says so, where before it was worked badly by people who spent the day walking. A growing place has to be built as neighbourhoods: houses, a well and a green near the fields they work.
- **With no firewood people huddle at home.** It keeps the cold off, takes six hours where a fire takes one, and a winter with an empty wood store takes a fifth off everyone's spirits. Before, a winter without firewood emptied the settlement.
- **Coin:** the charter gives every person 8 coin (was 4), a household is comfortable at 8 coin (was 20), poverty weighs less on spirits, and the default wage is 1 (was 2). The treasury now holds between 600 and 1,300 coin in the test runs, where before it sat near 100.
- **Newcomers** come while spirits are at 70% (was 75%).

From scripted runs with a steward who builds neighbourhoods: one passed 200 people in year eleven and reached 326 by year sixteen. Two others let their firewood run out; before huddling they were emptied, resettled and regrew, and with it they lose about a third of their people in the first fireless winter and then hold. A steward who builds nothing at all now gets through the first winter on the lord's relief and loses the hamlet in the second year, by people leaving.

Still open: a town can live for years with no firewood at the cost of spirits and time, which may be too kind; deaths in an overloaded winter are reported as thirst when the cause is no time to do everything; firewood and timber pile up when lodges are plentiful.

Not in step 1, though the GDD names them for the hamlet: mud in spring, a part refund when removing, and field colours that follow how far sowing has got (a field changes colour only when it is fully sown, grown, ripe or reaped). Timber has little to be spent on yet and piles up.

### Art (pen and wash)

- **Style, chosen after seven rounds of proposals:** a brown ink line with thin, realistic pastel washes on paper; people shaped as in the owner's reference (small head, block body, limbs one pixel wide) in plain clothes. The style sheet is `art/STYLE.md`; the approved picture is `art/reference/lords-will.png`.
- **How it is made:** every drawing is a Lua script run in Aseprite batch mode on the shared library `art/lib/ink.lua`. A building is described once and drawn in the four rotations. `tools/pack-art.py` packs `art/out/` into `games/lords-will/art.png` and `art-atlas.js`, and makes the faded "closed" version of each building.
- **Drawn:** all 18 buildings (the three open places included), 24 figures with walking, field work and standing poses, four trees in four seasons, 23 ground textures (grass and forest floor per season, water, ice, ford, road, five crop states).
- **Engine, generic:** ground textures by key, several sprites for one tile with a small shift per cell, a `look` per person and separate frames for walking and doing.
- **Fire:** a burning building shows a scorched drawing with flames that flicker (three frames, made by `art/fire.lua` from the finished drawings). The engine shows it while the building's `state` is 'fire'.
- **Night:** the whole picture is multiplied by a dim blue as night falls (`renderer.tint`), and open buildings switch to a drawing with lit windows. Lit windows and flames are marked in the sheet as lights, which the tint leaves alone.
- **The page:** parchment and ink in every theme, set in EB Garamond with IM Fell small capitals for titles, by redefining the kit's colour tokens in the game's own page.
- **Still open:** the ground is soft when zoomed in on the largest land; the mill has no lit windows; people carry no lanterns at night.

### Sound (ambient only)

- **No recordings:** every sound is made in the browser by the generic `games/lords-will/modules/ambience.js` (filtered noise, sliding tones, knocks, a bell).
- **What is heard** (`games/lords-will/sound.js`) follows the season, the hour and what the camera looks at: wind (more from far up and in winter), leaves and birds over forest by day, crickets and an owl at night, water near the river (quiet under ice), voices where people are, the axe at a working lodge and the hammer at a carpenter's, fire and its crackle at a burning building.
- **The bell** rings morning and evening where a chapel or church is open, and fast when a building catches fire.
- **Switch:** More, then "sound"; the choice is kept on the device. Sound starts at the first touch.
- **Not judged by ear:** the levels were checked by script; nobody has listened to it yet.

### Other food (garden, foragers, hens)

- **Garden** (3 × 3, open, 2 workers, 3 timber): vegetables, by season 40% / 100% / 130% / shut in winter.
- **Forager's hut** (2 × 2, 2 workers, 6 timber): nuts, berries, mushrooms and greens; like the lodge it needs trees within 10 cells. By season 40% / 80% / 160% / 15%.
- **Hen house** (2 × 2, 1 worker, 6 timber and 30 grain to buy the hens): eats 1 grain a shift and lays 2 eggs; by season 130% / 100% / 80% / 50%.
- **Pottage:** a new meal at home made of whichever of vegetables, forage or eggs the store holds most of; slightly preferred to porridge, so it saves grain while it lasts. All three count towards "days of food".
- **Generic pieces:** an economy flow may name several resources and take the one most in stock; a job may say how much it makes in each season (`job.seasons`, 0 = shut); any job with `reach` gets a yield from the trees around it.
- **Rebalanced:** a reaped cell now gives 1.1 grain (was 1.4) and each granary holds 600 (was 400). In seven-year test runs a settlement on grain alone still grows (151 people by year 7) but its store falls to 200–300 just before each harvest; with gardens, foragers and hens it keeps 500–1,000 in hand at that point, and little is wasted.
- **Not yet:** spoilage, children or elders tending gardens, a mood bonus for a varied diet. Late in the test runs firewood, not food, ran out in winter.

### Storehouse

- **Storehouse** (3 × 2, no workers, 20 timber, from the start): a long barn under a hipped shingle roof. Each one adds room for 240 vegetables, 150 forage, 90 eggs, 80 flour, 80 bread, 60 planks and 60 ale, so the room for each roughly doubles or more with the first one. The granary still holds grain only; firewood and timber have no limit.
- **Goal:** "Build a storehouse", after "Keep hens" (kept by id, so old saves are not moved back).
- **Shown:** the build menu and the building's card list what it adds room for, read from the limits in `RESOURCES`.
