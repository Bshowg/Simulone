// The rules of an ant colony, as an engine module. This is game code: the engine knows nothing about
// queens, eggs or castes. It gets all its numbers from nest.js.
//
//   - Only the queen makes new ants. Each finished laying shift adds a clutch of eggs to the brood,
//     as long as the nurseries have room and the larder is not nearly empty. A clutch takes food.
//     She never leaves her chamber for long: a shift with nothing laid is simply a rest.
//   - Eggs are not agents. They are a count: every finished nursing shift is one round of care for the
//     oldest egg, and an egg that has had enough care hatches at that nursery.
//   - A newly hatched ant joins the caste the nest is shortest of: the one with the most unfilled jobs.
//   - Ants die of old age (each has its own lifespan) or of hunger left desperate for too long.
//   - If the queen dies there are no more eggs; the colony lasts as long as its last ants.

/**
 * @param {object} d
 * @param {Array<{name:string, lifespan:number}>} d.castes   lifespan in ticks, 0 = does not die of age
 * @param {number} d.lifespanSpread   each ant's own lifespan is within ± this share of its caste's
 * @param {number} d.starvesAfter     ticks an ant survives with hunger desperate
 * @param {number} d.clutch           eggs per finished laying shift
 * @param {number} d.careToHatch      nursing shifts one egg needs
 * @param {number} d.broodPerNursery  eggs one nursery can hold
 * @param {string} d.nursery, d.lay, d.nurse, d.hunger, d.queen, d.fallbackCaste   names from the game's definitions
 * @param {() => number} d.food       how much food the colony has
 * @param {number} d.layAboveFood     the queen lays only above this
 * @param {number} d.clutchFood       food one clutch takes
 * @param {(n:number) => void} d.spendFood  take that much food from the colony
 */
export function createColony(d) {
  const C = {
    /** Care received so far by each egg, oldest first. */
    brood: [],
    stats: { laid: 0, hatched: 0, died: {}, peak: 0 },
    queenAlive: true,
    /** Called with ('hatched' | 'died' | 'queen died', agent, detail). */
    onEvent: null,
    sim: null,
  };
  let LAY = -1, NURSE = -1, HUNGER = -1, nurseryTile = -1, born = null, span = null, starving = null;
  const CHECK = 30;                                   // ages and hunger are looked at once a second

  /** How many eggs the nurseries can hold. */
  C.room = () => { let n = 0; for (const b of C.sim.world.buildings) if (b && b.tile === nurseryTile) n += d.broodPerNursery; return n; };
  /** Ants per caste, and how many of them have no job. */
  C.census = () => {
    const sim = C.sim, out = Object.fromEntries(sim.types.map(t => [t.name, { count: 0, jobless: 0 }]));
    for (let i = 0; i < sim.count; i++) { const c = out[sim.types[sim.type[i]].name]; c.count++; if (sim.job[i] < 0) c.jobless++; }
    return out;
  };
  /** Age of ant i in ticks. */
  C.ageOf = i => C.sim.tick - born[i];

  // The caste the nest is shortest of: unfilled jobs for it, less the ants of it already waiting for one.
  function casteNeeded() {
    const sim = C.sim, census = C.census();
    let best = d.fallbackCaste, bestScore = 0;
    for (const c of d.castes) {
      if (c.name === d.queen) continue;
      let vacant = 0;
      for (const b of sim.world.buildings) if (b && b.prefab.staff?.includes(c.name)) vacant += b.jobs - b.workers;
      const score = vacant - census[c.name].jobless;
      if (score > bestScore) { bestScore = score; best = c.name; }
    }
    return best;
  }

  function setup(sim) {
    C.sim = sim; C.brood = []; C.queenAlive = true;
    C.stats = { laid: 0, hatched: 0, died: {}, peak: 0 };
    LAY = sim.actionIndex(d.lay); NURSE = sim.actionIndex(d.nurse); HUNGER = sim.needIndex(d.hunger);
    nurseryTile = sim.world.id(d.nursery);
    born = sim.addColumn('bornAt', Int32Array, 0);
    span = sim.addColumn('lifespan', Int32Array, 0);
    starving = sim.addColumn('starving', Int32Array, 0);
  }

  function onSpawn(i, opts, sim) {
    born[i] = sim.tick - (opts.age ?? 0);
    const life = d.castes.find(c => c.name === sim.types[sim.type[i]].name)?.lifespan ?? 0;
    span[i] = life ? Math.round(life * (1 + (sim.rnd() * 2 - 1) * d.lifespanSpread)) : 0;
  }

  /** Would the queen lay right now? Not into full nurseries, and not with the larder nearly empty. */
  C.canLay = () => C.brood.length + d.clutch <= C.room() && d.food() > d.layAboveFood;

  // A nurse has nothing to do without brood.
  function canStart(i, a) { return a !== NURSE || C.brood.length > 0; }

  function onFinish(i, a, sim) {
    if (a === LAY) { if (C.canLay()) { for (let k = 0; k < d.clutch; k++) C.brood.push(0); C.stats.laid += d.clutch; d.spendFood(d.clutchFood); } }
    else if (a === NURSE && C.brood.length) {
      if (++C.brood[0] < d.careToHatch) return;
      C.brood.shift();
      const b = sim.world.buildings[sim.inside[i]];             // the nursery this nurse is in: the new ant walks out of it
      const n = sim.add(b.xx + 0.5, b.xy + 0.5, { type: casteNeeded(), newborn: true });
      if (n < 0) return;
      C.stats.hatched++;
      if (C.onEvent) C.onEvent('hatched', n, sim.types[sim.type[n]].name);
    }
  }

  function onTick(sim) {
    if (sim.tick % CHECK) return;
    if (sim.count > C.stats.peak) C.stats.peak = sim.count;
    for (let i = 0; i < sim.count; i++) {
      if (span[i] && sim.tick - born[i] > span[i]) { sim.remove(i, 'old age'); continue; }
      if (sim.needsOf[i * sim.K + HUNGER] >= 0.97) { starving[i] += CHECK; if (starving[i] > d.starvesAfter) sim.remove(i, 'hunger'); }
      else starving[i] = 0;
    }
  }

  function onGone(i, cause, sim) {
    C.stats.died[cause] = (C.stats.died[cause] ?? 0) + 1;
    const caste = sim.types[sim.type[i]].name;
    if (caste === d.queen) C.queenAlive = false;
    if (C.onEvent) C.onEvent(caste === d.queen ? 'queen died' : 'died', i, cause);
  }

  /** Hand this to the engine: `modules: [colony.module, …]`. */
  C.module = { name: 'colony', setup, onSpawn, canStart, onFinish, onTick, onGone };
  return C;
}
