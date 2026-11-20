// Headless: one battle of WAR, both sides commanded by the computer's general, 4,000 men against 4,000.
// Checks that it runs, that the armies meet and fight, that men break and run, that the battle ends with a winner,
// and how many milliseconds a tick costs.
//   node tools/tests/war_battle.mjs [men per side] [seed] [country] [quiet]
// Ends with PASS or the list of what did not hold.
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import * as War from '../../games/war/war.js';

const perSide = +(process.argv[2] ?? 4000), seed = +(process.argv[3] ?? 5), country = process.argv[4] ?? 'plain', quiet = process.argv[5] === 'quiet';
const cfg = War.makeConfig({});
const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
const sim = new Sim(world, cfg);
sim.setCount(0); sim.assign(); world.work(Infinity); sim.fieldBudgetMs = 0;

// An army: mostly foot, some archers and horse, in regiments of 200.
function army(n, side) {
  const mix = ['spear', 'spear', 'sword', 'levy', 'archer', 'spear', 'sword', 'archer', 'rider', 'levy'];
  const list = [];
  for (let k = 0; n > 0; k++) { const men = Math.min(War.REGIMENT_MEN, n); list.push({ id: side * 100 + k, kind: mix[k % mix.length], men, exp: side, name: `${k + 1}` }); n -= men; }
  return list;
}
War.startBattle(sim, { seed, country, sides: [army(perSide, 0), army(perSide, 1)] });
War.battle.player = -1;                                          // nobody's: both generals give orders
const failures = [], check = (ok, what) => { if (!ok) failures.push(what); };
check(sim.count === perSide * 2, `everyone is on the field (${sim.count} of ${perSide * 2})`);

const T = War.TICKS_PER_SECOND, limit = 8 * 60 * T;
let met = false, ran = 0, ms = 0, slowest = 0, maxArrows = 0;
const counts = () => { const c = {}; for (let i = 0; i < sim.count; i++) { const n = sim.actions[sim.action[i]].name; c[n] = (c[n] ?? 0) + 1; } return c; };
for (let t = 0; t < limit && !War.battle.result; t++) {
  const a = performance.now(); sim.step(); const e = performance.now() - a; ms += e; slowest = Math.max(slowest, e);
  maxArrows = Math.max(maxArrows, War.combat.arrows.length);
  if (War.combat.hits.length) met = true;
  if (t % (10 * T) === 0) {
    const c = counts(); ran = Math.max(ran, c.rout ?? 0);
    const side = s => War.regiments.all(s).reduce((n, r) => n + r.active, 0);
    if (!quiet) console.log(`${(t / T).toFixed(0).padStart(4)} s  standing ${side(0)} / ${side(1)}  down k${War.combat.down.killed} w${War.combat.down.wounded}  ${JSON.stringify(c)}  ${(ms / (t + 1)).toFixed(2)} ms/tick`);
  }
}
const ticks = War.battle.elapsed;
console.log(`${(ticks / T).toFixed(0)} s of battle, ${(ms / ticks).toFixed(2)} ms a tick on average, slowest ${slowest.toFixed(1)} ms, up to ${maxArrows} arrows in the air`);
console.log('result:', JSON.stringify(War.battle.result), 'killed', War.combat.down.killed, 'wounded', War.combat.down.wounded);
check(met, 'the armies meet and fight');
check(ran > 0, 'men break and run');
check(!!War.battle.result, 'the battle ends');
check(War.combat.down.killed[0] + War.combat.down.killed[1] > perSide * 0.05, 'men die');
console.log(failures.length ? 'FAIL: ' + failures.join('; ') : 'PASS: the armies meet, fight, break, and the battle ends');
process.exit(failures.length ? 1 : 0);
