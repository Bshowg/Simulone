// Headless: the ant nest with progress. node progress_test.mjs <minutes>
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import * as nest from '../../examples/anthill/nest.js';
const mins = +(process.argv[2] ?? 30);
const cfg = nest.makeConfig();
const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, fill: cfg.map.fill });
const sim = new Sim(world, cfg);
cfg.map.build(world);
sim.setCount(0); nest.populate(sim);
const E = nest.economy, P = nest.progress;
const clock = () => (sim.tick / nest.minutes(1)).toFixed(1);
P.onEvent = (kind, it) => console.log(`  [${clock()} min] ${kind}: ${it.title ?? it.id ?? ''} ${it.level ? 'level ' + it.level : ''} | twigs ${E.town.twigs.toFixed(0)}`);
// the same steps game.place / game.line take
const line = (...a) => { const n = world.line('tunnel', ...a); if (n) sim.onLine('tunnel', n, sim); return n; };
const place = (name, x, y) => { const why = sim.canBuild(name, sim); if (why !== true) return why; const b = world.place(name, x, y); if (b) sim.onPlace(b, sim); return b ? 'ok' : 'does not fit'; };
console.log('start: guard post →', place('guard post', 6, 43), '| side entrance →', place('side entrance', 6, 43));
const plan = {
  1: () => console.log('  dig', line(10, 43, 30, 43)),
  2: () => console.log('  nursery', place('nursery', 6, 43), 'twigs', E.town.twigs.toFixed(0)),
  6: () => console.log('  larder', place('larder', 31, 42)),
  10: () => console.log('  nursery 3', (line(20, 47, 30, 47), place('nursery', 31, 46))),
};
let side = false;
for (let m = 1; m <= mins; m++) {
  plan[m]?.();
  if (!side && P.level >= 3 && E.town.twigs >= 60) { line(8, 31, 20, 31); let r = 'does not fit'; for (let j = 28; j <= 32 && r !== 'ok'; j++) for (let i = 3; i <= 8 && r !== 'ok'; i++) r = place('side entrance', i, j); console.log('  side entrance', r); side = r === 'ok'; }
  sim.refresh();
  for (let t = 0; t < nest.minutes(1); t++) sim.step();
  if (m % 5 === 0) {
    const L = P.levelInfo(), g = P.goal();
    console.log(`min ${m}: ants ${sim.count} food ${E.town.food.toFixed(0)} twigs ${E.town.twigs.toFixed(0)} born ${P.get('born')} | level ${L.level}${L.next ? ' next: ' + L.next.text : ''} | goal: ${g ? g.title + ' (' + P.describe(g.when) + ')' : 'all met'}`);
  }
}
console.log('unlocks', JSON.stringify(P.unlocks().map(u => [u.id, u.unlocked])));
console.log('achievements', P.achievements().map(a => `${a.title}${a.done ? ' ✓' : ' ' + Math.round(a.progress.ratio * 100) + '%'}`).join(' · '));
const saved = P.save();
console.log('save bytes', JSON.stringify(saved).length, 'profile', JSON.stringify(saved.profile));
// a new game: the run starts over, the profile stays
const cfg2 = nest.makeConfig();
nest.progress.load(saved);
new Sim(new World({ width: 40, height: 60, tiles: cfg2.tiles, prefabs: cfg2.prefabs, fill: 'earth' }), cfg2);
console.log('new game after load: level', nest.progress.level, 'born', nest.progress.get('born'), 'best', nest.progress.get('population.max'),
  'achieved', Object.keys(nest.progress.save().profile.achieved).length, 'guard post unlocked', nest.progress.isUnlocked('guard post'));
