// Headless: save the hamlet mid-game, load it into a fresh game, and check that both then play out identically.
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import { createSave } from '../../modules/save.js';
import * as H from '../../games/lords-will/hamlet.js';

function fresh() {
  const cfg = H.makeConfig({}, 7);
  const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
  const sim = new Sim(world, cfg);
  cfg.map.build(world);
  return { sim, world, E: H.economy, P: H.progress, C: H.calendar, R: H.rules, L: H.lives };
}
const place = (g, name, x, y, size) => { for (let r = 0; r < 8; r++) for (let j = -r; j <= r; j++) for (let i = -r; i <= r; i++) {
  if (Math.max(Math.abs(i), Math.abs(j)) !== r) continue; const b = g.world.place(name, x + i, y + j, 'auto', size); if (b) { g.sim.onPlace(b, g.sim); return b; } } return null; };
const digest = g => { const s = g.sim; let h = 0; const where = id => { const b = id >= 0 ? g.world.buildings[id] : null; return b ? b.x * 1000 + b.y : -1; };   // a building by its place: ids are renumbered on load
  for (let i = 0; i < s.count; i++) h = (h * 31 + Math.round(s.px[i] * 100) + Math.round(s.py[i] * 100) * 7 + s.action[i] * 13 + where(s.home[i]) * 17 + where(s.job[i]) * 19 + where(s.inside[i]) * 23 + Math.round(s.needsOf[i * s.K] * 1000) + Math.round(g.L.health[i] * 1000) + Math.round(s.age[i])) | 0;
  return `tick ${s.tick} y${g.C.year} ${g.C.seasonName} d${g.C.dayOfSeason} | people ${s.count} hash ${h} | grain ${g.E.town.grain.toFixed(2)} wood ${g.E.town.firewood.toFixed(2)} timber ${g.E.town.timber.toFixed(2)} | fields ${JSON.stringify(g.R.farmland())} | level ${g.P.level} goal ${g.P.goal()?.id} born ${g.P.get('born')} winters ${g.R.winters} | births ${g.L.stats.births} | buildings ${g.world.buildings.filter(Boolean).length}`; };

const saves = createSave({ version: 1 });
const [cx, cy] = H.CENTRE;
// game A: play 5 days with some building, save, then 9 more days
const A = fresh(); A.sim.setCount(0); H.populate(A.sim);
place(A, 'field', cx - 14, cy + 6, [12, 12]); place(A, 'field', cx + 2, cy + 6, [12, 12]); place(A, 'field', cx - 14, cy - 18, [12, 12]);
place(A, 'lodge', cx - 13, cy - 5); place(A, 'green', cx + 12, cy + 3);
A.world.demolish(A.world.buildings[2].x, A.world.buildings[2].y);            // a gap in the ids
for (let t = 0; t < H.DAY * 5.3; t++) A.sim.step();
place(A, 'granary', cx - 12, cy + 2); place(A, 'hut', cx + 11, cy - 3);
const t0 = performance.now();
const data = JSON.parse(JSON.stringify(saves.snapshot(A.sim, { note: 'test' })));
const bytes = JSON.stringify(data).length;
console.log(`snapshot + JSON in ${(performance.now() - t0).toFixed(1)} ms, ${(bytes / 1024).toFixed(0)} KB (tiles ${data.tiles.length / 2} runs, ${data.buildings.filter(Boolean).length} buildings, ${data.people.count} people, modules ${Object.keys(data.modules).join(', ')})`);
const atSave = digest(A), tilesA = A.world.tiles.slice();
console.log('A at save :', atSave);
for (let t = 0; t < H.DAY * 9; t++) A.sim.step();
const endA = digest(A);
// game B: a fresh game, load the save, play the same 9 days.  (B is built after A finished: the hamlet module keeps one game at a time.)
const B = fresh(); B.sim.setCount(0); H.populate(B.sim);
const t1 = performance.now();
const ok = saves.restore(B.sim, data);
console.log(`restore: ${ok} in ${(performance.now() - t1).toFixed(1)} ms`);
console.log('B at load :', digest(B));
console.log(digest(B) === atSave ? 'PASS: the loaded game is the saved one' : 'DIFFERENT at load');
console.log('tiles equal:', (() => { for (let c = 0; c < A.world.cells; c++) if (tilesA[c] !== B.world.tiles[c]) return false; return true; })(), '| homes', B.sim.housed, '/', B.sim.beds, 'jobs', B.sim.employed);
for (let t = 0; t < H.DAY * 9; t++) B.sim.step();
const endB = digest(B);
console.log('A 9 days on:', endA);
console.log('B 9 days on:', endB);
console.log('wrong version refused:', createSave({ version: 2 }).restore(B.sim, data) === false);
