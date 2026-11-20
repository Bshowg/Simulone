// An ant nest seen from the side. Earth is solid; tunnels are dug through it and chambers are carved
// beside them. This file holds the numbers; the rules of the colony (the queen, the brood, who a new
// ant becomes, dying) are in rules.js. Neither is part of the engine.
//
// The engine pieces this game leans on:
//   map.fill: 'earth'            the map starts solid and is dug out
//   view.projection: 'flat'      the grid drawn straight on, ants turned to face where they walk
//   prefab.staff: ['nurse']      only that caste can work there
//   modules/economy.js           food and twigs, as goods held by the colony
//   modules/progress.js          the player's level, what is unlocked, goals and achievements

import { createEconomy } from '../../modules/economy.js';
import { createProgress } from '../../modules/progress.js';
import { createColony } from './rules.js';

// ───────────────────────── the clock ─────────────────────────
export const TICKS_PER_SECOND = 30;
/** Real seconds at 1× speed → ticks. */
export const seconds = s => s * TICKS_PER_SECOND;
export const minutes = m => seconds(m * 60);

const TYPICAL = 0.6;               // a need is acted on at around this level

// ───────────────────────── ants ─────────────────────────
// `fullAfter`: time for the need to go from satisfied to desperate if ignored.
export const NEEDS = [
  { name: 'hunger', fullAfter: seconds(110), weight: 1.3 },
  { name: 'tired',  fullAfter: seconds(170), weight: 1.0 },
];
export const STARVES_AFTER = seconds(50);          // how long an ant lasts once it is desperately hungry

// Castes. `walk` is cells per second. An ant is born into a caste and stays in it.
// `job` is the one kind of work the caste does; `lifespan` 0 = does not die of age.
export const CASTES = [
  { name: 'forager', walk: 4.2, job: 'forage', lifespan: minutes(14), look: { color: '#2a1d14', size: 1.0 } },
  { name: 'nurse',   walk: 3.4, job: 'nurse',  lifespan: minutes(18), look: { color: '#7a3f1d', size: 0.85 } },
  { name: 'soldier', walk: 3.0, job: 'guard',  lifespan: minutes(16), look: { color: '#5a1410', size: 1.3 } },
  // The queen is fed and tended where she sits: she has no needs of her own, and lays as long as the larder allows.
  { name: 'queen',   walk: 1.2, job: 'lay',    lifespan: 0, grow: { hunger: 0, tired: 0 }, look: { color: '#4a2a5a', size: 1.5 } },
];
export const LIFESPAN_SPREAD = 0.2;

// ───────────────────────── the brood ─────────────────────────
// Only the queen makes new ants. She lays a clutch at a time; each egg then needs a nurse's care a few times over
// before it hatches, and every round of care takes food. Nurseries limit how much brood there can be at once.
export const CLUTCH = 3;
export const CARE_TO_HATCH = 3;                    // nursing shifts one egg needs
export const BROOD_PER_NURSERY = 12;
export const LAY_ABOVE_FOOD = 40;                  // the queen stops laying when the larder is this low
export const CLUTCH_FOOD = 2;                      // food one clutch takes

// ───────────────────────── what the colony keeps ─────────────────────────
// Both are goods: held by the colony, not by ants. Foraging happens off the map; all that comes back is the count.
export const RESOURCES = {
  food:  { start: { town: 150 }, low: 60 },
  twigs: { start: { town: 45 } },
};

// ───────────────────────── chambers ─────────────────────────
// `job`:    the work done there: which caste (through the action), how long a shift is, what it makes and uses.
// `serves`: what a visit does for an ant and how long it takes.
// `cost`:   what carving one takes. `fixed`: part of the starting nest, not offered for building or removal.
const FORAGE = { action: 'forage', takes: seconds(22), makes: { food: 1, twigs: 0.06 }, color: '#6f8a44' };   // one trip outside
export const CHAMBERS = [
  { name: 'entrance', w: 4, h: 2, jobs: 60, staff: ['forager'], door: 'S', color: '#cfe3b0', fixed: true, job: FORAGE },
  // A second way out, dug from inside: more foragers can be out at once.
  { name: 'side entrance', w: 3, h: 2, jobs: 30, staff: ['forager'], door: 'S', color: '#bcd69a', cost: { twigs: 60 }, job: FORAGE },
  { name: 'royal chamber', w: 5, h: 3, jobs: 1, staff: ['queen'], door: 'N', color: '#e3cfe8', fixed: true,
    job: { action: 'lay', takes: seconds(12), color: '#9a5c7c' } },
  { name: 'nursery', w: 4, h: 2, jobs: 6, staff: ['nurse'], door: 'W', color: '#f2e6c4', cost: { twigs: 30 },
    job: { action: 'nurse', takes: seconds(9), uses: { food: 1 }, color: '#d9a441' } },
  { name: 'guard post', w: 3, h: 2, jobs: 4, staff: ['soldier'], door: 'E', color: '#e2c1b4', cost: { twigs: 20 },
    job: { action: 'guard', takes: seconds(20), color: '#b5553a' } },
  { name: 'larder', w: 4, h: 2, capacity: 10, door: 'W', color: '#dfe8c0', cost: { twigs: 25 },
    serves: { action: 'eat', need: 'hunger', takes: seconds(5), uses: { food: 1 }, color: '#b08a2e' } },
  { name: 'resting chamber', w: 4, h: 2, capacity: 14, door: 'E', color: '#c9d6e2', cost: { twigs: 25 },
    serves: { action: 'rest', need: 'tired', takes: seconds(12), color: '#3f7f8c' } },
];

// What moves when, read off the chambers above.
function nestFlows() {
  const flows = [], costs = {};
  const each = (o, f) => { for (const [r, n] of Object.entries(o ?? {})) f(r, n); };
  for (const c of CHAMBERS) {
    if (c.cost) costs[c.name] = c.cost;
    const what = c.job ?? c.serves;
    each(what.uses, (r, n) => flows.push({ action: what.action, at: c.name, when: 'start', resource: r, amount: n, from: 'town', to: null, required: true }));
    each(what.makes, (r, n) => flows.push({ action: what.action, at: c.name, when: 'finish', resource: r, amount: n, from: null, to: 'town' }));
  }
  return { flows, costs };
}

// ───────────────────────── the player's progress ─────────────────────────
// All of it is conditions on stats (see modules/progress.js). The stats used here:
//   population, food, twigs, eggs, reign   sampled from the nest (the gauges in makeConfig); reign = minutes with the queen alive
//   born                                   ants hatched
//   built.<chamber>, laid.tunnel           what the player has carved and dug
// `label` is how a condition reads on the page.
const ants = n => ({ stat: 'population', atLeast: n, label: 'ants' });
const carved = (chamber, n = 1) => ({ stat: 'built.' + chamber, atLeast: n, label: chamber + ' carved' });

// The nest starts at level 1; each entry is the step to the next level.
export const LEVELS = [
  { title: 'first brood',  when: { stat: 'born', atLeast: 20, label: 'ants hatched' }, reward: { grant: { twigs: 20 } } },
  { title: 'busy nest',    when: { all: [ants(80), carved('nursery')] }, reward: { grant: { twigs: 30 } } },
  { title: 'two ways out', when: { all: [ants(120), carved('side entrance')] }, reward: { grant: { twigs: 40 } } },
  { title: 'great colony', when: ants(200) },
];
// Chambers that cannot be carved from the start. The others always can.
export const UNLOCKS = [
  { id: 'guard post',    when: { level: 2 }, text: 'reach level 2' },
  { id: 'side entrance', when: { level: 3 }, text: 'reach level 3' },
];
// One at a time, in this order: they walk a new player through the game.
export const GOALS = [
  { id: 'dig',      title: 'Dig a tunnel', text: 'in dig mode, pick tunnel and drag through the earth', when: { stat: 'laid.tunnel', atLeast: 4, label: 'cells dug' }, reward: { grant: { twigs: 10 } } },
  { id: 'nursery',  title: 'Carve a second nursery', text: 'a chamber needs its opening on a tunnel', when: carved('nursery'), reward: { grant: { twigs: 15 } } },
  { id: 'sixty',    title: 'Grow to 60 ants', when: ants(60), reward: { grant: { twigs: 15 } } },
  { id: 'larder',   title: 'Carve a second larder', text: 'more ants can eat at once', when: carved('larder'), reward: { grant: { twigs: 15 } } },
  { id: 'side',     title: 'Open a side entrance', text: 'unlocked at level 3', when: carved('side entrance'), reward: { grant: { twigs: 20 } } },
  { id: 'stock',    title: 'Store 300 food', when: { stat: 'food', atLeast: 300, label: 'food' }, reward: { grant: { twigs: 20 } } },
  { id: 'onefifty', title: 'Grow to 150 ants', when: ants(150) },
];
// Earned once and kept from one nest to the next (stored on the device).
export const ACHIEVEMENTS = [
  { id: 'first hatch', title: 'First hatch',  text: 'an egg hatches', when: { stat: 'born', atLeast: 1 } },
  { id: 'digger',      title: 'Digger',       text: 'dig 40 cells of tunnel', when: { stat: 'laid.tunnel', atLeast: 40, label: 'cells dug' } },
  { id: 'architect',   title: 'Architect',    text: 'carve 6 chambers', when: { stat: 'built', atLeast: 6, label: 'chambers carved' } },
  { id: 'hundred',     title: 'A hundred',    text: '100 ants in the nest', when: ants(100) },
  { id: 'stocked',     title: 'Full larders', text: 'hold 400 food', when: { stat: 'food', atLeast: 400, label: 'food' } },
  { id: 'long reign',  title: 'Long reign',   text: 'the queen lives 20 minutes', when: { stat: 'reign', atLeast: 20, label: 'minutes' } },
  { id: 'generations', title: 'Generations',  text: '300 ants hatched in one nest', when: { stat: 'born', atLeast: 300, label: 'ants hatched' } },
];

/** The economy, the colony rules and the player's progress of the game most recently created with makeConfig. */
export let economy = null;
export let colony = null;
export let progress = null;

// ───────────────────────── the nest at the start ─────────────────────────
export const MAP = { width: 40, height: 60 };   // 2:3, the shape of a phone held upright
const SKY_ROWS = 5, SHAFT_X = 20;
export const START = { forager: 26, nurse: 6, soldier: 4 };

function digNest(w) {
  for (let y = 1; y <= SKY_ROWS; y++) for (let x = 1; x < w.w - 1; x++) w.set(x, y, 'sky');
  // Tunnels first: a chamber can only be carved where its opening meets one.
  w.line('tunnel', SHAFT_X, SKY_ROWS + 3, SHAFT_X, 50);        // the main shaft
  w.line('tunnel', 14, 12, SHAFT_X, 12);
  w.line('tunnel', SHAFT_X, 19, 30, 19);
  w.line('tunnel', 10, 27, SHAFT_X, 27);
  w.line('tunnel', SHAFT_X, 35, 30, 35);
  const must = (name, x, y) => { if (!w.place(name, x, y)) throw new Error('could not carve the ' + name); };
  must('entrance', SHAFT_X - 2, SKY_ROWS + 1);
  must('guard post', 11, 11);
  must('larder', 31, 18);
  must('resting chamber', 6, 26);
  must('nursery', 31, 34);
  must('royal chamber', SHAFT_X - 2, 51);
}

/** Put the first ants in the nest. Call once, right after createGame (or after building the Sim, headless). */
export function populate(sim) {
  progress.add('nests');
  sim.add(SHAFT_X + 0.5, 49.5, { type: 'queen' });
  let k = 0;
  for (const [caste, n] of Object.entries(START)) for (let j = 0; j < n; j++, k++) {
    const i = sim.add(SHAFT_X + 0.5, 10.5 + (k * 7) % 38, { type: caste, age: Math.floor(sim.rnd() * minutes(8)) });
    for (let n2 = 0; n2 < sim.K; n2++) sim.needsOf[i * sim.K + n2] *= 0.6;
  }
}

// ───────────────────────── turned into engine config ─────────────────────────
export function makeConfig(overrides = {}) {
  economy = createEconomy({ resources: RESOURCES, ...nestFlows() });
  colony = createColony({
    castes: CASTES, lifespanSpread: LIFESPAN_SPREAD, starvesAfter: STARVES_AFTER,
    clutch: CLUTCH, careToHatch: CARE_TO_HATCH, broodPerNursery: BROOD_PER_NURSERY, nursery: 'nursery',
    lay: 'lay', nurse: 'nurse', hunger: 'hunger', queen: 'queen', fallbackCaste: 'forager',
    food: () => economy.town.food, layAboveFood: LAY_ABOVE_FOOD, clutchFood: CLUTCH_FOOD,
    spendFood: n => { const took = Math.min(n, economy.town.food); economy.town.food -= took; economy.totals.food.used += took; },
  });
  progress = createProgress({
    gauges: {
      population: sim => sim.count,
      food: () => Math.floor(economy.town.food),
      twigs: () => Math.floor(economy.town.twigs),
      eggs: () => colony.brood.length,
      reign: sim => colony.queenAlive ? Math.floor(sim.tick / minutes(1)) : 0,
    },
    // kept across nests: the best a nest has ever done, and how many were started
    stats: { 'population.max': { scope: 'profile' }, nests: { scope: 'profile' } },
    levels: LEVELS, unlocks: UNLOCKS, goals: GOALS, achievements: ACHIEVEMENTS,
    grant: (resource, amount) => economy.give(resource, amount),
    storage: { key: 'anthill-progress' },
  });
  const growOf = Object.fromEntries(NEEDS.map(n => [n.name, 1 / n.fullAfter]));
  const clears = (need, takes) => -(TYPICAL / takes + growOf[need]);   // "takes 5 seconds" means 5 seconds to clear a typical need
  const jobs = [...new Set(CHAMBERS.filter(c => c.job).map(c => c.job))];   // chambers may share a kind of work
  return {
    ticksPerSecond: TICKS_PER_SECOND,
    agents: 0,                                   // the first ants are put in by populate()
    maxAgents: 600,
    view: { projection: 'flat', cell: 16, background: '#8a6844', ink: '#1c130c' },
    tiles: [
      { name: 'sky', solid: true, color: '#bfe0ee' },
      { name: 'earth', solid: true, color: '#8a6844', color2: '#836240' },
      { name: 'tunnel', color: '#e0cda6', street: true },
    ],
    prefabs: CHAMBERS,
    map: { ...MAP, fill: 'earth', build: digNest },
    needs: NEEDS.map(n => ({ name: n.name, weight: n.weight, grow: 1 / n.fullAfter })),
    actions: [
      ...CHAMBERS.filter(c => c.serves).map(c => ({ name: c.serves.action, at: c.name, color: c.serves.color, effects: { [c.serves.need]: clears(c.serves.need, c.serves.takes) } })),
      ...jobs.map(j => ({ name: j.action, at: '@job', color: j.color, duration: j.takes, interruptible: j.takes >= seconds(15) })),
      { name: 'wander', color: '#8a8474' },
    ],
    // A caste does its own kind of work and no other: the other jobs are written out of its matrix.
    types: CASTES.map(c => ({
      name: c.name, share: 0, speed: c.walk, grow: c.grow ?? {}, look: c.look,
      weights: Object.fromEntries(jobs.filter(j => j.action !== c.job).map(j => [j.action, { bias: -100 }])),
    })),
    features: economy.config.features,
    weights: economy.config.weights,
    modules: [progress.module, economy.module, colony.module],   // progress first: "locked" is said before "cannot pay"
    tuning: {
      speed: 1 / TICKS_PER_SECOND,
      decideEvery: 15, matrixEvery: 15,
      commute: 400,                              // any ant can work anywhere in the nest
      queuePatience: seconds(12), giveUpTicks: seconds(10),
      sepRadius: 0.45, sepPush: 0.8,             // ants squeeze past each other in a tunnel one cell wide
      leash: 30,
    },
    ...overrides,
  };
}
