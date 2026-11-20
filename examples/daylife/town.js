// A town with believable pacing. Everything about time lives in this file: how long a game hour is,
// how fast people walk, how quickly needs build up, how long a meal or a night's sleep takes.
// The engine itself only counts ticks and has no opinion on any of it.
//
// This file holds the numbers. The rules that use them (what health is, what kills, who has children,
// who leaves) are the generic module in modules/lives.js. The economy is the
// generic module in modules/economy.js, fed with the resources below and the annotations on the buildings.
//
// It is a game, not a simulation of real life: a day lasts six minutes, people cross the town in
// seconds rather than half an hour, a night's sleep is a minute and a half of play, and a whole
// life is about 36 days.

import { createLives } from '../../modules/lives.js';
import { createEconomy, flowsFromDefinitions } from '../../modules/economy.js';

// ───────────────────────── the clock ─────────────────────────
export const TICKS_PER_SECOND = 30;                 // simulation steps per real second at 1× speed
export const REAL_SECONDS_PER_HOUR = 15;            // one game hour; a day is 24 × this = 6 minutes
export const HOUR = REAL_SECONDS_PER_HOUR * TICKS_PER_SECOND;   // ticks in a game hour
export const DAY = 24 * HOUR;
export const START_HOUR = 6;                        // the game opens at 06:00

/** Game time → ticks. */
export const hours = h => h * HOUR;
export const minutes = m => (m * HOUR) / 60;
export const days = d => d * DAY;
/** Hour of the day (0-24, fractional) at a given tick. */
export const hourOfDay = tick => (START_HOUR + tick / HOUR) % 24;
export const dayNumber = tick => 1 + Math.floor((START_HOUR * HOUR + tick) / DAY);

// A need is acted on at around this level, so "takes 30 minutes" means "30 minutes to clear this much".
const TYPICAL = 0.6;

// ───────────────────────── people ─────────────────────────
// `fullAfter`: game time for the need to go from satisfied to desperate if ignored.
// `kills`:     game time a person survives with that need desperate (health drains to nothing). Omit = never fatal.
// `gloom`:     how much the need weighs on mood, relative to the others.
export const NEEDS = [
  { name: 'hunger',  fullAfter: hours(11), weight: 1.2, kills: days(1.5),  gloom: 1.0 },   // about three meals a day
  { name: 'fatigue', fullAfter: hours(24), weight: 1.2, kills: days(4),    gloom: 0.7 },   // tired by the end of a day awake
  { name: 'thirst',  fullAfter: hours(8),  weight: 1.3, kills: days(0.75), gloom: 1.0 },   // a drink every few hours
  { name: 'lonely',  fullAfter: hours(30), weight: 1.0,                    gloom: 1.0 },   // company most days
  { name: 'bored',   fullAfter: hours(22), weight: 0.9,                    gloom: 0.8 },   // some fun every day
  { name: 'dirty',   fullAfter: hours(40), weight: 0.9, kills: days(8),    gloom: 0.5 },   // a wash every day or two
];
export const RECOVERY = days(1.5);                  // from the brink back to full health, once nothing is hurting
export const ROUGH_SLEEP_KILLS = days(6);           // nights on the ground wear health down too (slowly: it mends by day)

// ───────────────────────── a life ─────────────────────────
// People are not sorted into fixed kinds. These are points along a life, and everything between two
// points is blended: a five-day-old is a little faster, a little less bored and a little taller than
// a four-day-old. `walk` is cells per real second at 1× speed (streets multiply it by 1.6);
// `grow` and `weight` multiply how fast a need builds and how much the person cares about it.
// `works` and the name switch at the point's age.
export const LIFESPAN = days(36);                   // a typical life; each person's own is within ±15% of it
export const LIFESPAN_SPREAD = 0.15;
export const AGES = [
  { age: days(0),  name: 'child', walk: 2.6, works: false, grow: { fatigue: 1.3, bored: 1.7 }, weight: { bored: 1.5, dirty: 0.5 }, look: { height: 8 } },
  { age: days(5),  name: 'youth', walk: 3.8, works: true,  grow: { fatigue: 1.1, bored: 1.3 }, weight: { bored: 1.2, dirty: 0.8 }, look: { height: 12 } },
  { age: days(9),  name: 'adult', walk: 3.2, works: true,  look: { height: 14 } },
  { age: days(26), name: 'adult', walk: 3.0, works: true,  look: { height: 14 } },
  { age: days(30), name: 'elder', walk: 2.4, works: false, grow: { fatigue: 1.25, bored: 0.7 }, weight: { fatigue: 1.2, lonely: 1.4 }, look: { height: 14, head: '#6f6a4f' } },
  { age: days(44), name: 'elder', walk: 1.5, works: false, grow: { fatigue: 1.4, bored: 0.6 },  weight: { fatigue: 1.3, lonely: 1.5 }, look: { height: 13, head: '#8f8a74' } },
];
// Children: a household with at least two residents of the right age, a free bed and good enough
// spirits may have one each night. Housing is therefore what limits the population.
export const FAMILY = { from: days(8), to: days(24), chancePerNight: 0.3, moodNeeded: 0.55 };
// Leaving: someone miserable for this long may walk away for good.
export const EMIGRATION = { moodBelow: 0.35, after: days(2), chancePerDay: 0.3 };
export const MOOD_FOLLOWS = hours(8);               // how quickly mood catches up with circumstances
export const START_AGES = [days(0), days(30)];      // the town opens with people of all ages

export const SLEEP_TAKES = hours(7);                // a night in a bed
export const ROUGH_SLEEP_TAKES = hours(15);         // the same rest on the ground
export const ASLEEP_NEEDS_SPEED = 0.2;              // while asleep, needs build up at this fraction of their usual speed
export const WORK_SHIFT = hours(2);                 // people check their needs between shifts

// ───────────────────────── the economy ─────────────────────────
// What exists. A resource people can hold works as money; one only the town holds works as goods.
// Delete `money` for a goods economy, or `food` and `materials` for a money economy: everything
// below that mentions a missing resource is simply ignored.
//   people: people can hold it      pooled: a household shares one purse
//   start:  what the town and each person begin with
//   low:    town stock under which the things that use it start to lose their pull
export const RESOURCES = {
  money:     { people: true, pooled: true, start: { town: 800, person: 12 } },
  food:      { start: { town: 400 }, low: 150 },
  materials: { start: { town: 120 } },
};
export const WAGE = { money: 3 };                   // paid by the town for each finished work shift
export const COMFORTABLE = 30;                      // money at which a person stops feeling poor
export const RENT = { money: 1 };                   // paid to the town for each night in a bed, by those who can

// ───────────────────────── buildings ─────────────────────────
// `serves`: what a visit does and how long it takes. `capacity`: customers inside at once when fully staffed.
// The economy reads these too:
//   serves.uses   what a visit takes from the town store (no stock, no service)
//   serves.price  what the visitor pays the town; with `mustPay`, those who cannot pay are turned away
//   makes         what a finished work shift there adds to the town store
//   cost          what the town pays to build one
export const BUILDINGS = [
  { name: 'house',    w: 3, h: 3, beds: 6, color: '#b9bfa6', height: 12, cost: { materials: 20 } },
  { name: 'canteen',  w: 4, h: 4, jobs: 4, capacity: 24, exit: 'E', color: '#e6cf8f', height: 16, cost: { materials: 50 },
    serves: { action: 'eat', need: 'hunger', takes: minutes(30), color: '#b08a2e', uses: { food: 1 }, price: { money: 1 } } },   // nobody is refused a meal
  { name: 'well',     w: 2, h: 2, jobs: 1, capacity: 8, color: '#a9c4cc', height: 8, cost: { materials: 15 },
    serves: { action: 'drink', need: 'thirst', takes: minutes(6), color: '#3f7f8c' } },                                         // water is free
  { name: 'bath',     w: 4, h: 3, jobs: 2, capacity: 10, color: '#d9c3cf', height: 14, cost: { materials: 40 },
    serves: { action: 'wash', need: 'dirty', takes: minutes(35), color: '#9a5c7c', price: { money: 1 }, mustPay: true } },
  { name: 'plaza',    w: 5, h: 5, jobs: 1, capacity: 30, exit: 'N', color: '#d3dcc0', height: 6, cost: { materials: 30 },
    serves: { action: 'social', need: 'lonely', takes: hours(1), color: '#6f8a44', price: { money: 1 }, mustPay: true } },
  { name: 'park',     w: 5, h: 5, jobs: 1, capacity: 30, exit: 'N', color: '#9dbb7a', height: 6, cost: { materials: 30 },
    serves: { action: 'play', need: 'bored', takes: hours(1), color: '#b5553a', price: { money: 1 } } },                       // the park lets the penniless in
  { name: 'workshop', w: 5, h: 4, jobs: 8, color: '#c9b7a0', height: 18, cost: { materials: 40 }, makes: { materials: 1 } },
  { name: 'farm',     w: 5, h: 5, jobs: 6, color: '#c8d08a', height: 5, cost: { materials: 30 }, makes: { food: 8 } },
];

// What moves when: read off the buildings above, plus rent, which belongs to an action and not to a building kind.
// Without rent, wages pile up in households and the town's own purse runs dry.
function townFlows() {
  const { flows, costs } = flowsFromDefinitions({ buildings: BUILDINGS, work: 'work', wage: WAGE });
  for (const [resource, amount] of Object.entries(RENT)) flows.push({ action: 'sleep', when: 'start', resource, amount, from: 'person', to: 'town' });
  return { flows, costs };
}

/** The economy, for the resources listed (default: all of them). Built on the buildings above. */
export function createTownEconomy(resources = Object.keys(RESOURCES)) {
  return createEconomy({
    resources: Object.fromEntries(resources.map(r => [r, RESOURCES[r]])),
    ...townFlows(),
    wealth: { resource: 'money', comfortable: COMFORTABLE, workPull: 0.15 },   // being poor makes paid work a little more attractive
  });
}
/** The economy of the game most recently created with makeConfig: stores, totals, costs. */
export let economy = null;

// The rules of living and dying, given this file's numbers. `lives.health[i]`, `lives.mood[i]` and `lives.stats`
// can be read by whoever draws the game; `lives.onEvent` reports births, deaths and departures.
export const lives = createLives({
  needs: NEEDS, desperate: 0.9, recovery: RECOVERY, harmfulActions: { 'sleep rough': ROUGH_SLEEP_KILLS },
  slowestWhenIll: 0.5, moodFollows: MOOD_FOLLOWS, homelessGloom: 0.25, joblessGloom: 0.1,
  lifespan: LIFESPAN, lifespanSpread: LIFESPAN_SPREAD, startAges: START_AGES,
  family: FAMILY, emigration: EMIGRATION,
  day: DAY,                            // births, departures and house moves are decided once a day, just before 06:00
});

// ───────────────────────── the rhythm of the day ─────────────────────────
// 0 → 1 as h goes from a to b.
const ramp = (h, a, b) => Math.max(0, Math.min(1, (h - a) / (b - a)));
/** How much it is night: 1 from 23:00 to 05:00, 0 from 07:00 to 21:00, sliding in between. */
export const nightness = h => 1 - ramp(h, 5, 7) * (1 - ramp(h, 21, 23));
/** How much it is working hours: 1 from 08:30 to 17:00, 0 before 07:00 and after 18:30. */
export const workday = h => ramp(h, 7, 8.5) * (1 - ramp(h, 17, 18.5));

// The engine rebuilds its action matrices every few ticks and calls this. Time of day is written into
// them: sleep is strongly preferred at night and resisted by day, work matters during working hours.
// This is the same matrix every agent of a type reads, so the whole town shifts together.
function dayRhythm(sim) {
  const h = hourOfDay(sim.tick), night = nightness(h), work = workday(h);
  const sleepy = 0.15 + 2.6 * night, industrious = 0.15 + 1.25 * work;
  for (let t = 0; t < sim.T; t++) {
    sim.live[sim.at(t, 'fatigue', 'sleep')] *= sleepy;
    sim.live[sim.at(t, 'fatigue', 'sleep rough')] *= sleepy;
    sim.live[sim.at(t, 'bias', 'work')] *= industrious;
  }
}

// ───────────────────────── the map ─────────────────────────
export const MAP = { width: 96, height: 64 };
export const POPULATION = 150;

function buildTown(w) {
  // Streets first: buildings placed afterwards turn their doors towards the nearest one.
  w.line('street', 4, 32, 91, 32);
  w.line('street', 30, 5, 30, 58); w.line('street', 62, 5, 62, 58);
  w.line('street', 4, 26, 30, 26);
  for (let r = 0; r < 5; r++) for (let c = 0; c < 6; c++) w.place('house', 5 + c * 4, 5 + r * 4);   // 30 houses, 180 beds
  w.place('canteen', 34, 22); w.place('canteen', 56, 36);
  w.place('well', 33, 35);    w.place('well', 58, 27);    w.place('well', 22, 35);    w.place('well', 28, 12);
  w.place('bath', 66, 24);
  w.place('plaza', 40, 38);
  w.place('park', 70, 38);
  w.place('workshop', 34, 8);  w.place('workshop', 42, 8);  w.place('workshop', 50, 8);
  w.place('workshop', 66, 8);  w.place('workshop', 74, 8);
  w.place('workshop', 34, 48); w.place('workshop', 44, 48); w.place('workshop', 66, 48);
  w.place('farm', 6, 36);      w.place('farm', 13, 36);     w.place('farm', 6, 44);
}

// ───────────────────────── turned into engine config ─────────────────────────
/**
 * The engine config for this town. Pass the canvas and any overrides.
 * `resources` picks the economy: all of them by default, ['food', 'materials'] for goods only, ['money'] for money only, [] for none.
 */
export function makeConfig(overrides = {}, resources = Object.keys(RESOURCES)) {
  economy = createTownEconomy(resources);
  const growOf = Object.fromEntries(NEEDS.map(n => [n.name, 1 / n.fullAfter]));
  // The engine keeps every need building up all the time, including the one being dealt with. So that
  // "takes 30 minutes" means what it says, an action's effect is its own rate plus that need's growth.
  const clears = (need, amount, takes) => -(amount / takes + growOf[need]);
  // Sleeping slows every need down (`needsPace`), or everyone would wake up parched and starving.
  const rest = takes => ({ fatigue: -(0.8 / takes + growOf.fatigue * ASLEEP_NEEDS_SPEED) });
  return {
    ticksPerSecond: TICKS_PER_SECOND,
    agents: POPULATION,
    view: { background: '#f4f2ea' },
    floor: { color: '#ffffff', color2: '#f1efe4' },
    tiles: [{ name: 'street', color: '#cdc6b0', walkCost: 0.5, speed: 1.6, street: true }],
    prefabs: BUILDINGS,
    map: { ...MAP, build: buildTown },
    needs: NEEDS.map(n => ({ name: n.name, weight: n.weight, grow: 1 / n.fullAfter })),
    actions: [
      // one action per building that serves something
      // `interruptible`: a long activity is broken off when another need turns desperate; a quick one is seen through
      ...BUILDINGS.filter(b => b.serves).map(b => ({
        name: b.serves.action, at: b.name, color: b.serves.color, effects: { [b.serves.need]: clears(b.serves.need, TYPICAL, b.serves.takes) },
        interruptible: b.serves.takes >= minutes(45),
      })),
      { name: 'sleep', at: '@home', color: '#1c1f17', needsPace: ASLEEP_NEEDS_SPEED, interruptible: true, effects: rest(SLEEP_TAKES) },
      { name: 'sleep rough', onlyIf: 'homeless', color: '#5a5d50', needsPace: ASLEEP_NEEDS_SPEED, interruptible: true, effects: rest(ROUGH_SLEEP_TAKES) },
      { name: 'work', at: '@job', color: '#5b6bb0', duration: WORK_SHIFT, interruptible: true },
      { name: 'wander', color: '#a9a493' },
    ],
    // engine speed = tuning.speed × stage.speed, in cells per tick; so with tuning.speed = one second's worth of
    // ticks inverted, `walk` above is in cells per second
    // The engine blends a matrix between these points. That is all it does with age; the rest is in rules.js.
    life: { stages: AGES.map(a => ({ ...a, speed: a.walk })), steps: 32 },
    // This game's rules, as independent modules. Each implements only the hooks it needs; the engine calls them all.
    features: economy.config.features,   // the economy adds "poor" as an input to the matrix…
    weights: economy.config.weights,     // …and how much it pulls towards paid work and away from paid-for things
    modules: [
      economy.module,                                       // stores, wages, prices, build costs (modules/economy.js)
      lives.module,                                         // health, mood, death, births, moving house, leaving (modules/lives.js)
      { name: 'day rhythm', onRebuildMatrix: dayRhythm },   // sleep by night, work by day
    ],
    tuning: {
      speed: 1 / TICKS_PER_SECOND,
      decideEvery: 15,                 // people reconsider twice a second
      matrixEvery: 15,
      queuePatience: minutes(40),      // how long someone waits outside a full building
      giveUpTicks: hours(2),           // …and how long before they try again
      commute: 70,                     // this town is small: anyone can work anywhere in it
    },
    ...overrides,
  };
}
