// Headless: a mall with a second floor. People must find their way up and down through the links the engine makes of
// an escalator, staff must reach a unit upstairs, and a floor with no way up must earn nothing.
//   node tools/tests/mall_floors_test.mjs
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import { createSave } from '../../modules/save.js';
import * as M from '../../games/mall/mall.js';

function fresh() {
  const cfg = M.makeConfig({ seed: 11 });
  const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
  const sim = new Sim(world, cfg);
  cfg.map.build(world); sim.setCount(0); sim.assign(); world.work(Infinity);
  return { sim, world, ...cfg.mall };
}
const g = fresh(), { sim, world, economy: E, visitors: V, staff: S, floors: F, progress: G, rules: R } = g;
const failures = [], check = (ok, what) => { if (!ok) failures.push(what); };
const place = (name, x, y) => { const why = sim.canBuild(name, sim); if (why !== true) return null; const b = world.place(name, x, y, 'auto'); if (b) sim.onPlace(b, sim); return b; };

// a mall at stage 3 with money to spend
check(R.canBuyFloor() !== true, 'a second floor is refused before the mall stage');
G.setLevel(3); E.give('money', 60000); R.draw = M.FOOTFALL[3];    // the standing of a mall, and the visitors that go with it
for (const [n, x, y] of [['café', 11, 17], ['clothes shop', 19, 16], ['kiosk', 12, 13], ['toilets', 19, 12]]) check(place(n, x, y), n + ' placed');
check(R.buyFloor() === true && F.built === 2, 'the second floor was built');
check(R.buyFloor() !== true, 'a third floor is refused at the mall stage');
const [ux, uy] = F.cell(1, 0, 0);                                    // the corner of the first floor on the grid
// upstairs: a gym and an arcade on a walkway, in the same place as the ground floor's walkway
world.rect(ux + 14, uy + 6, 3, 15, 'walkway');
const gym = place('gym', ux + 8, uy + 8), arcade = place('games arcade', ux + 18, uy + 9);
check(gym && arcade, 'a gym and an arcade were built upstairs');
check(R.connect('escalator', 5, 5) === true, 'an escalator was put in');                 // at local (4, 4), away from everything
check(R.connect('escalator', 5, 5) !== true, 'a second one in the same place is refused');
check(F.reach(0).every(f => f.there && f.back), 'both floors can be reached and left');
check(world.links === 2, `the escalator made two links (${world.links})`);

let reports = [], upstairsNoon = 0, staffUp = 0, visitorsUp = 0;
R.onEvent = (kind, r) => { if (kind === 'report') reports.push(r); };
const line = r => `day ${r.day}: in ${r.arrived} out ${r.gone} left ${JSON.stringify(r.left)} | upstairs ${Math.round(r.upstairs)} | ` + r.units.filter(u => u.floor === 1).map(u => `${u.name} ${u.sales} visits staff ${u.staff}/${u.posts}`).join(', ');
while (reports.length < 1) {
  sim.step();
  if (sim.tick % 600 === 0) { const c = F.crowd(); if (c[1] > visitorsUp) visitorsUp = c[1]; staffUp = Math.max(staffUp, S.present(gym) + S.present(arcade)); }
}
console.log(line(reports[0]));
for (const n of reports[0].notes) console.log('   >', n);
const up = reports[0].units.filter(u => u.floor === 1);
check(up.length === 2 && up.every(u => u.sales > 0), 'both units upstairs had visitors');
check(staffUp >= 3, `staff reached their posts upstairs (${staffUp} seen at work)`);
check(visitorsUp > 0, 'people were upstairs during the day');
check(reports[0].arrived === reports[0].gone && (reports[0].left['shown out'] ?? 0) <= reports[0].arrived / 50, 'everyone, or all but a straggler, found the way out at closing');

// save and load: the links must come back
const saves = createSave({ version: M.SAVE_VERSION }), data = JSON.parse(JSON.stringify(saves.snapshot(sim)));
const h = fresh();
check(saves.restore(h.sim, data) && h.floors.built === 2 && h.floors.list.length === 1 && h.world.links === 2, 'a loaded game has its floors and its links');
let reportsH = [];
h.rules.onEvent = (kind, r) => { if (kind === 'report') reportsH.push(r); };
while (reportsH.length < 1 && h.sim.tick < 4 * M.DAY) h.sim.step();
console.log('loaded:', reportsH[0] ? line(reportsH[0]) : 'no report');
check(reportsH[0]?.units.filter(u => u.floor === 1).every(u => u.sales > 0), 'and people go upstairs in it');

// stairs instead: families and pensioners resent them
check(R.disconnect(5, 5) === 'escalator' && world.links === 0, 'the escalator was taken out');
while (reports.length < 2) sim.step();
console.log(line(reports[1]));
for (const n of reports[1].notes) console.log('   >', n);
check(reports[1].units.filter(u => u.floor === 1).every(u => u.sales === 0), 'with no way up, the units upstairs sold nothing');
check(reports[1].notes.some(n => n.includes('Nobody can get to level 1')), 'and the report says why');
check(R.connect('stairs', 5, 5) === true && world.links === 2, 'stairs were put in');
while (reports.length < 3) sim.step();
console.log(line(reports[2]), '| gripes', JSON.stringify(reports[2].gripes.filter(x => x.key.includes('rode'))));
check(reports[2].units.filter(u => u.floor === 1).some(u => u.sales > 0), 'people take the stairs');
console.log(failures.length ? 'FAILED:\n  ' + failures.join('\n  ') : 'PASS: floors are joined, reached and left');
process.exit(failures.length ? 1 : 0);
