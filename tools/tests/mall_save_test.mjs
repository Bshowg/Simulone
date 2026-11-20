// Headless: save the mall in the middle of a trading day, load it into a fresh game, and check the loaded game is
// the saved one and then trades on to the same kind of day.   node tools/tests/mall_save_test.mjs
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import { createSave } from '../../modules/save.js';
import * as M from '../../games/mall/mall.js';

function fresh() {
  const cfg = M.makeConfig({ seed: 7 });
  const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
  const sim = new Sim(world, cfg);
  cfg.map.build(world); sim.setCount(0); sim.assign(); world.work(Infinity);
  return { sim, world, ...cfg.mall };
}
const place = (g, name, x, y) => { if (g.sim.canBuild(name, g.sim) !== true) return null; const b = g.world.place(name, x, y, 'auto'); if (b) g.sim.onPlace(b, g.sim); return b; };
const where = (g, id) => { const b = id >= 0 ? g.world.buildings[id] : null; return b ? b.x * 1000 + b.y : -1; };   // a building by its place: ids are renumbered on load
function digest(g) {
  const s = g.sim; let h = 0;
  for (let i = 0; i < s.count; i++) h = (h * 31 + Math.round(s.px[i] * 100) + Math.round(s.py[i] * 100) * 7 + s.action[i] * 13 + where(g, s.inside[i]) * 23 + Math.round(s.purse[i]) * 5 + s.wants[i] * 3 + s.got[i] + s.going[i] * 11 + Math.round(s.needsOf[i * s.K + 9] * 1000)) | 0;
  const books = g.world.buildings.filter(Boolean).map(b => `${b.name}:${b.books?.day.sales ?? 0}/${Math.round(b.books?.day.takings ?? 0)}/${Math.round(b.stock ?? -1)}`).join(' ');
  return `tick ${s.tick} day ${g.rules.day} ${g.rules.phase} | people ${s.count} visitors ${g.visitors.count} hash ${h} | cash ${g.economy.town.money.toFixed(2)} | in ${g.visitors.tally.arrived} out ${g.visitors.tally.gone} | ${books}`;
}
const failures = [], check = (ok, what) => { if (!ok) failures.push(what); };
const saves = createSave({ version: M.SAVE_VERSION });

// game A: a day and a bit with some building, save at a busy hour, then on to the end of that day
const A = fresh();
let reportsA = [];
A.rules.onEvent = (kind, r) => { if (kind === 'report') reportsA.push(r); };
place(A, 'café', 11, 17); place(A, 'clothes shop', 19, 16); place(A, 'kiosk', 12, 13);
for (let t = 0; t < M.DAY + M.hours(5.3); t++) A.sim.step();                 // into the second day, about 13:20
place(A, 'toilets', 19, 12); A.rules.layTile('bench', 14, 14);
const data = JSON.parse(JSON.stringify(saves.snapshot(A.sim, { note: 'test' })));
console.log(`snapshot: ${(JSON.stringify(data).length / 1024).toFixed(0)} KB, ${data.people.count} people, ${data.buildings.filter(Boolean).length} buildings, modules ${Object.keys(data.modules).join(', ')}`);
const atSave = digest(A);
console.log('A at save :', atSave);
check(data.people.count > 0, 'the save was taken with visitors inside');
while (reportsA.length < 2) A.sim.step();
const endA = reportsA[1];

// game B: a fresh game, load the save, play the same day out
const B = fresh();
let reportsB = [];
B.rules.onEvent = (kind, r) => { if (kind === 'report') reportsB.push(r); };
const ok = saves.restore(B.sim, data);
const atLoad = digest(B);
console.log('B at load :', atLoad);
check(ok, 'the save was read');
check(atLoad === atSave, 'the loaded game is the saved one');
check(B.rules.history.length === 1 && B.rules.lastReport?.day === 1, 'the first day\'s report came with the save');
while (reportsB.length < 1 && B.sim.tick < 3 * M.DAY) B.sim.step();
const endB = reportsB[0];
const line = r => `day ${r.day}: in ${r.arrived} out ${r.gone} takings ${Math.round(r.takings)} rating ${r.rating.toFixed(2)} cash ${Math.round(r.cash)}`;
console.log('A closes  :', line(endA));
console.log('B closes  :', endB ? line(endB) : 'no report');
check(endB && endB.day === 2 && endB.arrived === endB.gone, 'the loaded game closed its day with everyone out');
check(endB && Math.abs(endB.arrived - endA.arrived) <= 6 && Math.abs(endB.takings - endA.takings) < 0.25 * endA.takings + 50, 'and it was the same kind of day');
check(createSave({ version: M.SAVE_VERSION + 1 }).restore(B.sim, data) === false, 'a save of another version is refused');
console.log(failures.length ? 'FAILED:\n  ' + failures.join('\n  ') : 'PASS: the loaded game is the saved one');
process.exit(failures.length ? 1 : 0);
