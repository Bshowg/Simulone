# Atrium (working title): game design document

A shopping-mall management game for phones (web). The second full game on the Simulone engine, after The Lord's Will
(`docs/GDD.md`). It must be a game of its own: its own mechanics and its own new modules, not The Lord's Will with
new names.

## 1. Decisions the owner has made

| Question | Decision |
|---|---|
| Subject | A mall. People come and go to buy things, eat, use the gym and have fun. |
| Growth of the map | Building new floors. |
| View | Isometric, one floor on screen at a time, with a floor selector. |
| The player's role | Owns every unit: builds it, sets prices, hires staff, keeps the takings. |
| Time | Day by day: the mall opens and closes; a report closes each day. |
| Setting | Present day. |
| Platform | Phone first (Android, 120 Hz), published as a Claude artifact, tested by the owner on their phone. |
| Sound | Ambient only, last. |

Standing rules from the owner (they apply to all work on this project):

- **The engine stays generic.** Game mechanics, numbers and pacing live in the game's own files, never in `engine/`.
- **What is missing is built as a generic module** in `modules/`, with every number passed in by the game.
- **A new game gets its own gameplay**, not a reskin of an earlier one.

## 2. The game in one paragraph

You run a mall. Each day people arrive with a few wishes, some money and a limited amount of time. They walk to what
they want, queue, spend, and leave pleased or annoyed. What they thought of today decides how many come tomorrow.
Profit pays for more units, better ones, and in the end another floor. The pleasure is in the flow: where the
escalator goes, what sits beside the food court, why there is a queue at the toilets at one o'clock.

## 3. What is different from The Lord's Will

| | The Lord's Will | Atrium |
|---|---|---|
| People | residents: born, age, die | visitors: arrive, stay a few hours, leave |
| Pressure | survival (food, warmth, water) | flow (queues, distance, variety, price) |
| Money | arrives at stage 3 | central from the first minute |
| Time | seasons and years | one day: opening, lunch rush, evening peak, closing |
| Growth | more land, more people living there | more floors, more visitors a day |
| Failure | people die or walk away for good | visitors leave unserved, rating falls, the mall runs at a loss |

## 4. People

**Visitors** are the many simple agents. Each arrives at an entrance with:

- **wishes**: two to five of: shop (by kind: clothes, food to take home, books, electronics, gifts), eat, drink,
  exercise, play, watch a film. Wishes are the "needs" of the engine's needs-and-actions matrix: a wish presses harder
  the longer it goes unmet, and is cleared by a visit to a unit that serves it;
- **bodily needs** that build while they are there: hunger, thirst, the toilet, tired legs (benches);
- **a purse**: what they can spend today;
- **patience and time**: how long they will queue, and when they must go.

Kinds of visitor differ in all of these (numbers in the game's tables): teenagers (little money, long stay, play and
snacks), families (big baskets, need toilets and seats), office workers (lunch hour only, fast food and coffee),
pensioners (mornings, benches, café), shoppers (the default). The mix changes through the day and the week.

A visitor leaves when the wishes are met, the purse is empty, the time is up, or patience has run out. On leaving they
give the visit a **score** from what happened: wishes met, time spent queueing and walking, prices, cleanliness, a seat
when they wanted one.

**Staff** are the second kind of person: they arrive before opening, work a shift in the unit that hired them, and go
home. A unit without enough staff serves slowly or stays shut. Cleaners and guards walk the floors.

## 5. The mall

**Floors.** The game starts with a small ground floor. Each floor is a grid of the same size; a new floor is bought
when the stage allows it. People move between floors by **escalators** (fast, take space, one direction each),
**stairs** (cheap, slow, some visitors avoid them) and **lifts** (slow, needed by families and pensioners). A floor
nobody can reach earns nothing. Upper floors are worth less footfall unless something up there pulls people (the
cinema, the gym, the food court): this is the central layout puzzle.

**Units** are the buildings. Indicative list by stage (the developer tunes sizes, costs and numbers):

| Stage | Units |
|---|---|
| 1 Parade of shops | entrance, walkway, kiosk, clothes shop, café, toilets, bench, plant |
| 2 Arcade | grocer, bookshop, fast food, staff room, store room, bin, cleaner's cupboard |
| 3 Mall (second floor) | escalator, stairs, lift, food court seating, gym, games arcade, electronics, pharmacy |
| 4 Destination | cinema, restaurant, department store (large), security office, car park entrance |
| 5 Landmark | roof garden, events space, up to five floors |

Each unit has: what it serves, how many it serves at once, how long a visit takes, a price level, staff needed, stock
it uses, what it costs to build and to run. Things on the walkway (benches, plants, bins) change comfort and
cleanliness nearby.

## 6. Money

- **In:** every sale. A visit to a unit takes money from the visitor's purse according to the unit's price level.
- **Out:** wages for every shift worked, stock for what was sold, upkeep per unit per day, the cost of building,
  and a loan repayment if one was taken.
- **Price levels** (cheap, fair, dear) are set per kind of unit. Dear earns more per sale, lowers the visit score and
  turns poorer visitors away; cheap does the opposite.
- **The day's report** shows takings and costs by unit, visitors in and out, wishes met and missed, the rating, and
  the three worst things visitors complained about. This report is the main teaching tool: it must say plainly what
  went wrong and where.
- A mall that cannot pay its wages closes units until it can. There is one loan, offered once, as a way back.

## 7. Reputation

The mall has a **rating** from 0 to 5 stars: a slow-moving average of visit scores. Tomorrow's number of visitors is
`base for the stage × rating × variety`, shaped by the hour-of-day curve and the day of the week. Variety counts the
different kinds of unit open. A new kind of unit also brings the kind of visitor who wants it.

## 8. The day

Opening hours are a policy. Before opening: staff arrive, deliveries fill the store rooms. Morning: pensioners and
parents. Lunch: the office rush on food. Afternoon: shoppers, then teenagers after school. Evening: cinema,
restaurant, gym. Closing: visitors are asked to leave, cleaners finish, the report is shown. Nothing happens while the
game is closed. The player may build at any time; time stands still while building, as in The Lord's Will.

Days of the week differ (Saturday is the big day). There are no seasons at first; a few calendar days matter (sales,
holidays), which the events module provides.

## 9. Stages, goals, events

- **Stages** (the progress module's levels): parade of shops → arcade → mall → destination → landmark. Each asks for a
  number of visitors in a day, a rating held for some days and a profit, and unlocks the next units and floor.
- **Goals** teach the game one step at a time (first shop, first profit, a toilet before the complaints, a second
  floor that pays for itself…). Achievements for feats.
- **Events:** a rainy day (more visitors), a heatwave (drinks and the cinema), a power cut, a rival mall's sale
  (answer with one of your own or lose trade), a health inspector (cleanliness), a film première, school holidays,
  a broken escalator. Each is a choice with a cost.

## 10. Screen

The shared page kit (`kit/kit.js`), as in The Lord's Will: a top strip (day and hour, money, rating, visitors now), the
map, a floor selector at the map's corner, a goal line, and sheets from the bottom bar: Build, Units (each unit's day
so far), Visitors (who is here, what they want, why they left), Money, Policy (hours, price levels, wages), Goals,
More. Tap a person or a unit for its card. Phone width first; nothing scrolls sideways.

## 11. What must be built

**Engine (generic additions only):**

- **Links between cells.** A person can step from one cell to a linked cell far away, taking a set time, and routes
  are found through links. This is what an escalator, a lift or a stair is. It is the largest new piece; keep it
  small and general (it would equally serve a tunnel or a ferry).
- Showing one part of the map at a time (a floor), if floors are laid out as separate areas of one grid. The developer
  may choose another way to hold floors if it is cleaner, as long as it is generic.

**New generic modules** (numbers passed in by the game):

| Module | What it does |
|---|---|
| `visitors` | arrivals by a curve over time and by kind; each with wishes, a purse, patience and a leaving time; departure and a visit score |
| `floors` | several levels in one simulation, the links between them, which one is on screen |
| `trade` | a unit sells to whoever is served: price, stock, takings, per-unit accounts |
| `reputation` | a rating from visit scores, and what it does to tomorrow |
| `staff` | shifts: who works where and when, wages, arriving and going home |
| `upkeep` (optional) | litter and cleaning, breakdowns and repair |

**Reused as they are:** calendar, economy (for stock and money, if it fits), progress, events, policies, save, the kit.
Where an existing module nearly fits, extend it generically rather than writing a second one.

**The game itself:** `games/mall/` with its numbers and tables in one file, its own rules in another, and the page.

## 12. Order of work

Each step ends playable and published, with the regression tests passing.

1. **The ground floor.** Visitors arrive, want things, walk, queue, buy, leave. Entrance, walkway, three units, money,
   the day and its report. No staff, no stock: units simply work.
2. **Saving.** The mall survives closing the page. One save, versioned.
3. **Running a business.** Staff and shifts, stock and deliveries, price levels, upkeep. The report explains losses.
4. **Reputation and progress.** Visit scores, the rating, the arrival curve, kinds of visitor, stages, goals, unlocks.
5. **Floors.** Links in the engine, the floors module, escalators, stairs and lifts, the floor selector, upper-floor units.
6. **Events and upkeep.** The events table, litter and cleaners, breakdowns.
7. **Balance.** Scripted runs from an empty lot to a five-floor mall; fix what stalls.
8. **Art, then ambient sound.** Not started without the owner: the look is the owner's choice.

## 13. How to work on this project

- Read `engine/README.md`, `modules/README.md` and `kit/README.md` first; they are the manuals. `games/lords-will/`
  is a complete example of a game built on them. Do not change it.
- Page: `games/mall/index.html`, served by `tools/serve.py` (launch configuration `game-b`, port 8765).
- Publish with `python tools/build-artifact.py games/mall`, then the Artifact tool with `dist/mall.html` and a `files`
  map of every file the page needs (`dist/mall/*.js`, `engine/*.js`, the `modules/*.js` it imports, `kit/kit.js`).
  Before publishing, load a staged copy laid out exactly like the published page and check it starts: an import
  that points outside the published folder blanks the game.
- Regression tests are in `tools/tests/` (see its README). Run them after any change to `engine/` or `modules/`.
- The owner has declined git for this folder. There is no undo: change files with small, exact edits.
- **Other sessions work in this folder at the same time** (an ant-colony game, and the art for The Lord's Will).
  Touch only the mall's own files, plus additive, generic changes to `engine/`, `modules/` and `kit/`. Read an engine
  file again immediately before editing it, never rewrite one whole, and never remove or rename something another
  game uses.
- The owner's details and the project are private: nothing about them goes to outside services.

## 14. Progress

(The developer records each finished step here: what was built, what was decided, what is still open.)

Published at https://claude.ai/artifact/V5DqdJqbCNm1fGZVCxb5Z9 (one artifact, updated at every step).
Files: `games/mall/mall.js` (numbers and tables), `games/mall/rules.js` (the game's own rules), `games/mall/index.html` (the page).
Test: `node tools/tests/mall.mjs [days]`. To check a build as it is published: `python tools/build-artifact.py games/mall`,
then (since the restructure) open `dist/mall/index.html`, which the build lays out as published (it follows the page's imports, lays the files out in `dist/_stage/mall/` and
prints the `files` map for the Artifact tool).

### Step 1: the ground floor (done)

**Built.**
- `games/mall/modules/visitors.js` (new, generic): arrivals at a rate, kinds, wishes, purse, stay, patience, going home, the visit's score, the day's tally.
- `games/mall/modules/trade.js` (new, generic): sales, purses, an account per building. Stock is written but switched on in step 3.
- `engine/renderer.js`: `setRegion()`, to draw one rectangle of the grid and keep the camera to it. Additive; nothing else changed.
- The game: a ground floor of 30 × 22 cells with a way in and a few cells of walkway. Buildable now: walkway, bench, plant,
  entrance, kiosk, clothes shop, café, toilets. Money (economy module, one resource). The trading day: doors open 09:00,
  close 21:00, visitors are shown out, a full-screen report closes the day, and closing the report passes the night at once.
- The page on the shared kit: Build, Units, Visitors, Money, More; a card for a tapped visitor or unit; a hint line.

**Decided (the owner may want to revisit).**
- *One grid for every floor.* The map is 160 × 24: five floors of 30 × 22 side by side, 32 cells apart, the others solid until
  bought. The view shows one. 32 is the engine's routing sector, which keeps routes to one's own workplace exact per floor.
- *The whole catalogue is in the tables from the start* (every unit, need, action and type of all five stages), locked by
  stage. A save then stays readable as steps are added. Until step 4 the stage is 1.
- *Wishes.* Nine things only wished for (clothes, groceries, books, electronics, gifts, remedy, workout, play, film), plus
  hunger and thirst, which are wishes for some and build up in everyone. Toilet and tired legs only build up.
  A wish the mall could serve at its stage but does not is 0.3 times as likely as one it serves: enough for the report to
  say "12 came for a book and found nowhere open that has it".
- *The kiosk sells gifts* (cards, magazines, sweets); the café sells a coffee (thirst) and a lunch (hunger).
- *A way in is a unit* (3 × 1, on the edge of the ground floor). Visitors appear at its door and leave through it. The last
  one cannot be removed.
- *Money is €.* Start €8,000. Nothing is refunded when a unit is removed.
- *Time.* 30 ticks a second; a game hour is 20 seconds at 1×, so a trading day is 4 minutes at 1× and 30 seconds at 8×.
  The night is not played: it passes when the report is closed.
- *The score* of a visit: 2.4 stars, +2.6 × share of wishes met, −1.4 × share missed, −1 an hour queued, −0.25 an hour
  walked, less for leaving hungry, thirsty, needing a toilet or with tired legs. The rating shown is the day's average
  (the slow-moving rating comes in step 4).
- *Bare floor is walkable.* Walkway is faster (×1.4), draws routes to it, and is where idle visitors stroll.

**Open.**
- Only shoppers come until step 4. Units need no staff and never run out until step 3, so a day's profit is far too easy.
- Visitors choose the nearest place for a wish; price does not steer them yet except by turning away a purse that is too thin.
- The picture was checked by reading the canvas from script (the browser pane was hidden): layout, colours and the sheets
  are right at 375 px wide. Nothing was tried by touch or on a phone.

### Step 2: saving (done)

**Built.** One save on the device (`modules/save.js`, as it is), under the key `atrium-save`, with a version number
(`SAVE_VERSION` in `mall.js`). It is written every game hour, when the Build sheet closes, when a day's report is closed and
when the page is put away. It keeps the map, everyone inside with their wishes and purses, every unit's account, the money,
the day and its phase, the last report and the last 14 days, plus where the camera was and the speed. Test:
`node tools/tests/mall_save_test.mjs` (saved at 13:17 with six visitors inside; the loaded game matches and closes the same day).

**Decided.**
- A save from another version is not migrated: the game starts a new mall and says so in a line over the map.
- A page put away while the report is up comes back with the report up.
- "New mall" (under More, tap twice) forgets the save.

**Open.** Adding a need, an action or a type to the tables makes old saves unreadable (the version must then be raised);
adding a unit or a tile does not.

### Step 3: running a business (done)

**Built.**
- `games/mall/modules/staff.js` (new, generic): posts, hiring, a shift, arriving and going home, time worked.
- `games/mall/modules/trade.js`: stock is on. `modules/policies.js` is used as it is.
- Staff: every unit with posts hires its own (all posts filled when built; fewer or more on the unit's card). They come in an
  hour before opening, work until closing and walk out. A unit with nobody is shut; a short-handed one serves fewer at once.
- Stock: every shop holds a shelf of goods, counted in money. A sale takes goods worth a share of its fair price. An empty
  shelf shuts the shop until the next morning's delivery.
- Price levels per kind of unit (cheap, fair, dear), on the unit's card and under Policy.
- Policy sheet: opening hour (7 to 11), closing hour (18 to 23), wages (low, fair, generous), a price level per kind of unit.
- The report now has a line per unit (visits, takings, costs, result), what was paid at closing, and "what went wrong":
  a unit shut for want of staff, a unit sold out, a unit that lost money and why, staff who did not come in, money owed.
- Debts and the loan. Bills that cannot be paid at closing are owed. The next morning, units that lost money the day before
  stay shut until the debt is paid. The first time it happens the bank offers its one loan.

**Decided (the owner may want to revisit).**
- *Bills are paid at closing*, for the day: goods for what was sold, wages for the hours on shift, upkeep. The morning
  delivery is then free. So the day's profit in the report is exactly the change in the bank (building apart).
- *Wages* are 9 an hour per member of staff at fair pay; a day is about 13 hours of shift. Low pay is ×0.8 and each member
  of staff has a 15% chance of not coming in; generous pay is ×1.25 and every sale adds 0.06 stars. At fair pay 1% do not come.
- *Price levels*: cheap ×0.8 (+0.12 stars a sale, draws 15% more), dear ×1.25 (−0.2 stars a sale, draws 15% less, and thin
  purses are turned away).
- *Goods* cost 35% to 70% of the fair price, by kind of unit (café 35%, clothes 50%, grocer 65%, electronics 70%).
- *The loan* is 6,000, repaid at 500 a day for 15 days (7,500 in all), offered once.
- *Longer hours bring the visitors of those hours*: the day's visitors are for 9 to 21, and each hour has its share.
- *Staff room and store room* (stage 2) are in the rules already: a staff room adds 0.05 stars to every sale by staffed
  units; each store room (up to two) lets every shop hold half as much again.
- *One shift a day.* Nobody works part of the day.

**Open.**
- A unit opens when its staff are assigned, a few seconds before they have walked in (the engine staffs by assignment).
- Staff who lose their post in the middle of the day (let go, unit removed) may be taken on by another unit that is short.
- Cleaners and guards come with step 6.

### Step 4: reputation and progress (done)

**Built.**
- `games/mall/modules/reputation.js` (new, generic): a rating moved once a day towards that day's average score, and a factor read
  off a curve. `modules/progress.js` is used as it is for stages, unlocks, goals and achievements.
- The rating (shown in the top strip) opens at ★3.0 and moves 35% of the way to each day's average visit. It multiplies
  the next day's visitors: ×0.85 at 3.0, ×1 at 3.5, ×1.35 at 4.5, ×0.55 at 2.0.
- Five kinds of visitor, each with its hours and its weekend (table `MIX`): office workers at lunch and not at weekends,
  pensioners in the morning, teenagers after school and all Saturday, families mostly at weekends, shoppers all day.
  A kind's share also follows how much of what it wants the mall has.
- Stages (the progress module's levels): parade of shops, arcade, mall, destination, landmark. Each asks for visitors in
  one day, a rating held some days in a row, and a profit in one day; it unlocks units and pays a grant.
- Seventeen goals, one at a time, on the line above the bar and in the Goals sheet, most with a small reward. Six achievements.
- A full-screen moment at each new stage: what changed, which units are new.

**Decided (the owner may want to revisit).**
- *What each stage asks:* arcade 60 visitors, ★3.5 for 2 days, 600 profit; mall 140, ★3.7 for 3, 1,500; destination 260,
  ★3.9 for 3, 3,500; landmark 450, ★4.1 for 4, 7,000. Grants: 2,000, 5,000, 12,000, 25,000.
- *Footfall by stage* (visitors a day at ★3.5 with three kinds of unit, Monday being ×0.8 and Saturday ×1.5): 80, 160,
  300, 500, 800. *Variety:* 40% plus 20% for every kind of unit open that visitors come for, up to 220%.
- *Floors by stage:* one until the mall stage, then 2, 3 and 5.
- *A stage is never lost*, even if the rating falls afterwards.
- *Achievements are kept on the device* across malls; everything else belongs to one mall.

**Open.**
- The goals about floors (11 to 13 and 17) read stats that step 5 sets.
- Balance is rough until step 7: at stage 1 a day's profit is a few hundred.

### Step 5: floors (done)

**Built.**
- Engine, generic and additive: **links** (`world.addLink` / `removeLink`, followed by every full-map route; `sim.ride`,
  the `onLink` hook) and, from step 1, drawing one rectangle of the grid (`renderer.setRegion`). Documented in `engine/README.md`.
- `games/mall/modules/floors.js` (new, generic): levels on one grid, building the next one, connectors, which levels can be reached
  and left, which one is shown.
- Floors: a button under Build builds the next floor when the stage allows it (1 floor up to the arcade, 2 at the mall,
  3 at the destination, 5 at the landmark). Buttons at the corner of the map choose the floor on screen and show how
  many people are on each.
- Ways between floors, placed on the lower floor: escalator (two cells, one up and one down), stairs, lift (one cell each,
  both ways). They take the same cells on the floor above. Removing one removes both ends.
- Upper-floor units from the stage tables (gym, games arcade, electronics, pharmacy, food court and later ones) can be
  built on any floor. A way in can only stand on the ground floor.
- The report says when a floor cannot be reached or cannot be left, and counts the upper floors' result (goal 13).
- Test: `node tools/tests/mall_floors_test.mjs`.

**Decided (the owner may want to revisit).**
- *Lifts are wanted, not required.* Everyone can take any way. Families lose 0.4 stars and pensioners 0.5 for each ride
  on stairs, and the report counts it ("26 times a family or a pensioner had to take the stairs: they look for a lift").
  Making stairs impassable for them would need a second set of routes for every destination; it can be done later if
  the soft version is not enough.
- *Which way people take* follows one cost each: escalator 30 (about 8 cells of walking), lift 60, stairs 90. So an
  escalator nearby wins, and a lift beats stairs. Ride times: 40, 120 and 90 ticks (4, 12 and 9 game minutes).
- *An escalator is a pair* (up and down), so a floor with one can always be left. Stairs and lifts go both ways.
- *Costs:* escalator 2,500 (+60 a day), stairs 600 (+5), lift 1,800 (+40). Floors: 15,000, 30,000, 50,000, 70,000.
- *Floors are called* ground floor, level 1, level 2… ("second floor" means different floors to different people).
- *Nothing limits how many ride at once.* A lift is slow but never full.
- *Staff always go to their post*, however far: the pull of their work does not fall with distance.

**Open.**
- The roof garden can stand on any floor, not only the top one.
- Upper floors have no walls or atrium opening: each floor is a flat plan of its own.

### Step 6: events and upkeep (done)

**Built.**
- `games/mall/modules/upkeep.js` (new, generic): litter per cell with a route to it for whoever cleans, and buildings that break
  and are mended. `modules/events.js` is used as it is. `staff.js` gained staff who walk the place (`roam`),
  `floors.js` `pause()`, `reputation.js` `shift()`.
- **Litter.** Visitors out walking drop it, more after eating or drinking; a bin within 4 cells keeps 85% of it off the
  floor. Walking over litter takes a little off the visit each time; enough of it and the visitor complains. The page
  draws it on the floor. It is all cleared overnight.
- **Cleaners.** A cleaner's cupboard (arcade stage) brings one cleaner for the shift, who walks to the nearest litter
  and clears it and the cells around. Paid like other staff.
- **Guards.** A security office (destination stage) brings a guard who walks a round of the ways in and the ways between
  floors. With a guard on shift, visitors in after 18:00 add 0.1 stars, and shoplifters keep away.
- **Plants** now matter: a visit gains a little each time a visitor is within 2 cells of one (up to 0.15 stars).
- **Breakdowns.** A unit with machines (café, toilets, fast food, food court, gym, arcade, cinema, restaurant) or an
  escalator or lift can break. It stops at once and the player is asked: mend it today for a fee (an hour), or wait
  for the contractor overnight, free. A mark over the unit shows it.
- **Events** (a table in `rules.js`, numbers in `mall.js`), each looked at when the staff come in, none before day 3:
  a rainy day (more visitors); a heatwave (air conditioning for a fee, or fewer and unhappier visitors; drinks and the
  cinema are wanted); a power cut announced for the afternoon (a generator, or staffed units shut and escalators and
  lifts stop for two hours); the rival mall's sale (a sale of your own, advertising, or a quarter of the trade lost);
  the health inspector (a deep clean first, or let them look: commended or fined); a film première (with a cinema);
  school holidays (teenagers and families on weekdays); shoplifters (without a guard, from the mall stage).
- What an event costs is paid at once and listed in the day's report; what happened is kept under More.
- Test: `node tools/tests/mall_events_test.mjs`.

**Decided (the owner may want to revisit).**
- *Litter is cleared every night for nothing.* Cleaners are for the day: without one a big mall is dirty by the afternoon.
  Bins are available from the first stage.
- *Breakdowns are events with a question*, not wear that builds up: about one unit breakdown every twelve days and one
  escalator or lift every sixteen.
- *The inspector's fine* is 600 and 0.25 stars; a pass adds 0.1. More than 12 dirty cells, or toilets out of order, fails.
- *One cleaner per cupboard, one guard per office.* More cupboards, more cleaners.
- *Guards do not stop anything that can be seen.* Their effect is on the evening's visits and on the shoplifters event.

**Open.**
- An event's question waits over the map for a few game hours and then takes the cautious answer by itself.
- Litter is drawn as specks by the page, on top of everything (it is not part of the engine's picture).

### Step 7: balance (done)

**Built.** `tools/tests/mall_balance.mjs`: a scripted manager that plays from the empty lot, reading each day's report
as a player would (toilets, benches and bins when they are complained of, a second unit where one is always full, a
store room when shelves empty, the next unit on its list when the money is there, a floor with an escalator and a lift
when the stage allows) and answering events. With seeds 7, 3, 11 and 23 it now reaches every stage and five floors:

| | arcade | mall | destination | landmark | five floors |
|---|---|---|---|---|---|
| day reached | 4 to 5 | 8 to 12 | 26 to 28 | 41 to 46 | 54 to 57 |

At a minute a day (4×) that is about an hour of play from the first shop to the fifth floor, building time apart.
The landmark's last week: about 1,000 visitors a day (1,500 to 1,900 on a Saturday), takings near 48,000, profit near
11,000 a day, rating ★3.5 to ★3.9.

**What stalled, and what was changed.**
- *Stages came in a rush* (a mall on day 5): a stage now also asks for kinds of unit built (4, 9, 14, 19) and, later,
  floors (2 for the destination, 3 for the landmark); the visitor and profit marks were raised.
- *Visitors doubled overnight at a new stage* and swamped the units: the stage's footfall is now approached by 15% of
  the gap each day. Variety is judged against the stage (3, 6, 11, 14, 16 kinds give 100%; from 35% to 125%).
- *No event ever came up* (they were looked at one tick before the morning began): fixed.
- *Visitors left needing a toilet or a seat that was a few steps away*: they now see to such a need before going home
  from a little under the level at which it spoils the visit, and the loss grows from nothing at that level.
- *Tired legs was the top complaint of every big mall*: sitting down in a café, a food court, a restaurant, a cinema or
  at a show now rests the legs too (benches still draw tired people more).
- *Thirst had one outlet*: the kiosk and the food court also sell a drink.
- *The gym and the restaurant stood empty*: more kinds of visitor want a workout (office workers above all), and a meal
  out is a wish of its own that only the restaurant settles (it settles hunger as well).
- *Film-goers ran out of time*: someone who comes for a film has 2.2 hours more, for a workout or a meal out one more.
  Nothing is begun that would run more than half an hour past closing (it is counted as missed "when the mall closed").
- *Margins were too thin at the arcade stage*: wages 7.5 an hour (were 9); goods a little cheaper; clothes 36 (were 42);
  thinner purses wish for clothes less often. Fast food needs one member of staff.
- *Litter drowned out every other complaint in a big mall*: visitors drop a third less, a cleaner takes 2 minutes a cell.
- *The roof garden had no visitors*: it is now a free place to enjoy (it settles "some fun", rests the legs and adds a
  quarter of a star to the visit).

**Decided (the owner may want to revisit).**
- The pace above. To slow it, raise the stage marks in `STAGES`; to make money tighter, `WAGES.perHour` and the units'
  `goods` shares are the two dials that move everything.
- A big Saturday (×1.5 visitors, families ×3) is by design the day that strains the mall and pulls the rating down.

**Open.**
- The scripted manager lays every floor out the same way (a spine, a cross corridor and two side corridors) and never
  removes anything. A person will build differently: the numbers are a floor, not a guarantee.
- At the landmark the events space competes with the arcade and the roof garden for the same wish and can lose money.
- After the fifth floor there is nothing more to earn towards: the game becomes a sandbox.
- Nothing has been played by hand or on a phone. Speeds, tap targets and the feel of the pace are untested.

### What the owner should look at (steps 1 to 7)

1. **Lifts are wanted, not required** (step 5): families and pensioners can take stairs and resent it.
2. **Floor names**: ground floor, level 1 to level 4.
3. **The night is skipped** when the report is closed; one shift a day; bills are paid at closing.
4. **Wishes**: twelve things people come for, and the kiosk sells gifts and drinks. A meal out belongs to the restaurant.
5. **Stage requirements and pace** (table above).
6. **Breakdowns and events** ask a question that waits a few game hours and then answers itself with the cautious choice.
7. **Litter is cleared free every night**; cleaners are for the day.
8. **Money is €**, 8,000 to start, one loan of 6,000, no refund for removing a unit.
9. **Step 8**: the unit art is begun (see below); ambient sound is not started.

### Step 8: art (begun, at the owner's direction)

**Asked for.** First: shops visible inside (no roof, the two walls facing the screen left out), animated by how full
they are. Then, on seeing the first version: everything more defined and more alive; the sprites were flat and too
low in resolution.

**Built (second version).** `games/mall/art.js` draws the whole sprite sheet by code when the page starts (no image
files; about 4096 × 3100 pixels).
- **Resolution.** A cell is 64 × 32 pixels (it was 16 × 8 with the placeholders), and the map is drawn at the screen's
  own resolution: on a phone with three device pixels to a page pixel the picture has nine times the pixels it had.
- **Rooms.** Every unit is a room seen from inside: its floor (tiles or boards), the two back walls shaded from top to
  bottom with a skirting, a band in the unit's colour carrying its name, the door where it is in a back wall, and a
  dark line where the two front walls are cut away. Everything standing in it is a piece of its own, outlined and
  shaded, with a shadow on the floor: shelves with rows of goods, clothes rails, produce crates, display tables,
  tills, counters with machines and menu boards, tables and chairs, cubicles and basins with mirrors, treadmills,
  arcade cabinets, cinema seats, a stage with drums and speakers, lockers, crates, a desk under a wall of monitors.
- **The people inside are the real ones.** The visitors and staff who went into a unit are drawn in it, each at a
  place of their own: browsing to and fro along a shelf, standing at the till, sitting at a table or in a cinema seat,
  running on a treadmill; staff behind their counters, moving along them now and then. A room is exactly as full as
  the unit, and people are hidden by the furniture in front of them and stand in front of what is behind them.
- **Things that move by themselves:** arcade screens, the cinema's film, stage lamps, candles, security monitors.
  A shut unit is the same room with the lights out.
- **People.** Each kind of visitor is drawn differently (a shopper with a bag, a teenager in a cap with a backpack,
  a parent with a child at their side, an office worker in a suit with a case, a pensioner with a stick), in eight
  looks each (skin, hair, clothes), with a four-step walk, a standing and a sitting pose. Staff wear white with an
  apron, cleaners teal with a mop, guards navy with a cap. People no longer wear the colour of what they are heading for.
- **The floor** has textures (bare concrete, polished walkway tiles); plants, benches, bins, escalators with their
  arrows, stairs and lifts are drawn as small models.
- **Engine, generic and additive** (`engine/README.md`, Sprites): a building's art may be a room (`open`), with
  `parts` (pieces with their own depth) and `stand` (where a person inside is drawn); more than one pose besides
  walking (`stills`); a tap is now measured in page pixels, so it still works on a finely drawn canvas.

**Decided (the owner may want to revisit).**
- Drawn by code, not painted: a new unit gets a room from its size and kind without new drawing. A painted sheet in
  the same shape can replace it without other changes.
- Clothing no longer shows where someone is going; the card on a tapped person says it.
- If a device cannot take a sheet that size, the engine's plain boxes are shown instead.

**Open.**
- The sheet is about 50 MB of graphics memory. It has not been tried on a phone.
- The roof garden is still painted flat on the ground. Ambient sound is not started.
- Someone sitting is drawn a little lower, not properly on the chair; people appear at their place in a room at once
  when they go in (they do not walk to it).
