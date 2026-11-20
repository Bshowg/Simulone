// Headless: The Colony (ant game) left to itself for a few minutes of game time, then saved and loaded.
// Nobody plays it, so nothing is dug: this checks that it runs, the queen lays, and a save loads back the same.
//   node tools/tests/colony.mjs [minutes]
// Ends with PASS or the list of what did not hold.
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import { createSave } from '../../modules/save.js';
import * as N from '../../games/ant-colony/nest.js';

globalThis.localStorage ??= { _: {}, getItem(k) { return this._[k] ?? null; }, setItem(k, v) { this._[k] = String(v); }, removeItem(k) { delete this._[k]; } };
const minutes = +(process.argv[2] ?? 4);
const make = () => {
  const cfg = N.makeConfig({});
  const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor, fill: cfg.map.fill });   // the earth is solid loam, as createGame makes it
  const sim = new Sim(world, cfg);
  if (cfg.map.build) cfg.map.build(world);
  sim.setCount(0); sim.assign(); world.work(Infinity); sim.fieldBudgetMs = 0;
  return { cfg, world, sim };
};
const failures = [], check = (ok, what) => { if (!ok) failures.push(what); };

const { world, sim } = make();
N.populate(sim);
const start = sim.count, ticks = minutes * 60 * N.TICKS_PER_SECOND;
const t0 = performance.now();
for (let k = 0; k < ticks; k++) { world.work(2); sim.step(); }
const queen = Array.from({ length: sim.count }, (_, i) => sim.types[sim.type[i]].name).includes('queen');
console.log(`${minutes} min of game time in ${((performance.now() - t0) / 1000).toFixed(1)} s: ants ${start} -> ${sim.count}, brood ${JSON.stringify(N.colony.brood())}, hatched ${N.colony.stats.hatched}`);
check(queen, 'the queen is alive');
check(sim.count >= start * 0.8, `the colony holds on (${sim.count} of ${start})`);
const brood = N.colony.brood();
check(brood.eggs + brood.larvae + brood.pupae + N.colony.stats.hatched > 0, 'the queen lays');
const busy = Array.from({ length: sim.count }, (_, i) => sim.using[i] || sim.actions[sim.action[i]].name !== 'wander').filter(Boolean).length;
check(busy > 0, 'ants are doing something besides wandering');

// save, and load into a fresh game: the same ants in the same places
const saves = createSave({ key: 'colony-test', version: 1 });
const data = saves.snapshot(sim, {});
const B = make();
let ok = false;
try { ok = saves.restore(B.sim, data); } catch (e) { console.error(e); }
check(ok, 'the save loads');
check(B.sim.count === sim.count, `the loaded colony has the same ants (${B.sim.count} of ${sim.count})`);
let moved = 0; for (let i = 0; i < Math.min(sim.count, B.sim.count); i++) moved += Math.abs(sim.px[i] - B.sim.px[i]) + Math.abs(sim.py[i] - B.sim.py[i]);
check(moved < 1e-3, 'every ant is where it was');
for (let k = 0; k < 600; k++) { B.world.work(2); B.sim.step(); }
check(B.sim.count > 0, 'the loaded colony runs on');

console.log(failures.length ? 'FAIL: ' + failures.join('; ') : 'PASS: the colony lives, the queen lays, and it saves and loads');
process.exit(failures.length ? 1 : 0);
