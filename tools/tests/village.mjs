// Headless: hamlet to village with a steward who reacts to what the settlement needs. node village.mjs <years> [seed]
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import * as H from '../../games/lords-will/hamlet.js';
const yearsToRun = +(process.argv[2] ?? 8), seed = +(process.argv[3] ?? 7);
const cfg = H.makeConfig({}, seed);
const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
const sim = new Sim(world, cfg);
cfg.map.build(world); sim.setCount(0); H.populate(sim); world.work(Infinity); sim.fieldBudgetMs = 0;
const E = H.economy, P = H.progress, C = H.calendar, R = H.rules, L = H.lives, V = H.events, POL = H.policies;
const forceTown = +(process.argv[5] ?? 0);
const when = () => `y${C.year} ${C.seasonName} d${C.dayOfSeason}`;
const log = (...a) => console.log(`    [${when()}]`, ...a);
P.onEvent = (kind, it) => { if (kind !== 'goal') log(kind + ':', it.title ?? it.id ?? '', it.level ? 'level ' + it.level : ''); };
V.onNews = (kind, e, c) => { log('event', kind + ':', e.title, c ? '→ ' + c.label : ''); if (kind === 'asking') V.choose(e.id, e.id === 'relief' ? 'accept' : ['war', 'rival'].includes(e.id) ? (E.town.coin > 400 ? (e.id === 'war' ? 'coin' : 'pay') : 'refuse') : e.id === 'merchant' ? (R.foodDays() < 6 && E.town.coin >= 80 ? 'buy' : E.town.grain > 900 ? 'grain' : E.town.firewood > 400 ? 'firewood' : 'nothing') : sim.beds - sim.housed >= 3 ? 'settle' : 'refuse'); };
const avg = a => { let s = 0; for (let i = 0; i < sim.count; i++) s += a[i]; return sim.count ? s / sim.count : 0; };
R.onEvent = (kind, r) => {
  if (kind === 'levy') log(`levy: due ${r.due} paid ${r.paid} coin ${r.coin} owed ${r.owed} | standing ${R.standing}`);
  if (kind === 'fire') log(`FIRE ${r.what}: ${r.building.name}`);
  if (kind === 'sold') log(`sold ${r.sold} ${r.resource} for ${r.coin} coin`);
  if (kind !== 'season') return;
  const f = o => Object.entries(o).filter(([, n]) => n > 0.5).map(([k, n]) => `${k} ${Math.round(n)}`).join(', ') || '-';
  console.log(`  == ${r.season} y${r.year}: people ${r.people} born ${r.born} arr ${r.arrived} left ${r.left} died ${JSON.stringify(r.deaths)} | made ${f(r.made)} | used ${f(r.used)} | wasted ${f(r.wasted)} | sown ${r.sown} lost ${r.lost} | store ${f(E.town)} | coin held ${E.held('coin').toFixed(0)} poor ${avg(sim.features.poor).toFixed(2)} | mood ${avg(L.mood).toFixed(2)} work ${sim.employed}/${sim.workforce} beds ${sim.housed}/${sim.beds}`); };
const [cx, cy] = H.CENTRE;
const wellField = () => sim.field[sim.actionIndex('drink')];
L.onEvent = (kind, i, cause) => { if (kind !== 'gone' || cause !== 'thirst' || process.argv[4] !== 'thirst') return;
  const c = sim.cell[i], d = wellField()[c], hb = sim.home[i] >= 0 ? world.buildings[sim.home[i]] : null, jb = sim.job[i] >= 0 ? world.buildings[sim.job[i]] : null;
  log(`THIRST age ${(sim.age[i] / H.years(1)).toFixed(1)}y ${sim.types[sim.type[i]].name} doing ${sim.actions[sim.action[i]].name}${sim.using[i] ? '' : '>'} inside ${sim.inside[i] >= 0 ? world.buildings[sim.inside[i]].name : '-'} at ${(c % 300)},${(c / 300) | 0} wellDist ${d === 65535 ? 'INF' : (d / 4).toFixed(0)} home ${hb ? hb.name + '@' + hb.x + ',' + hb.y : '-'} job ${jb ? jb.name : '-'} wait ${sim.wait[i]} blocked ${sim.tick < sim.blockUntil[i] ? sim.actions[sim.blockAct[i]]?.name : '-'} needs ${Array.from(sim.needsOf.subarray(i * sim.K, i * sim.K + sim.K), v => v.toFixed(2)).join(' ')} wells ${count('well')} wellInside ${world.buildings.filter(b => b && b.name === 'well').map(b => b.customers + '/' + b.cap).join(',')}`); };
const count = name => world.buildings.filter(b => b && b.name === name).length;
let ring = 0;
const place = (name, x, y, size) => {
  if (sim.canBuild(name, sim) !== true) return false;
  for (let r = 0; r < 12; r++) for (let j = -r; j <= r; j++) for (let i = -r; i <= r; i++) {
    if (Math.max(Math.abs(i), Math.abs(j)) !== r) continue;
    const b = world.place(name, x + i, y + j, 'auto', size); if (b) { sim.onPlace(b, sim); return b; }
  }
  return false;
};
const spot = () => { const a = (ring++) * 2.4, r = 9 + (ring % 14); return [Math.round(cx + Math.cos(a) * r), Math.round(cy - 4 + Math.sin(a) * r * 0.8)]; };
const fieldSpot = () => { const k = count('field'); return [cx - 74 + (k % 10) * 15, cy + 30 + Math.floor(k / 10) * 15]; };   // a block of fields south of the houses, with lanes between
// A steward who builds neighbourhoods: each hub gets a well, houses close around it and fields in a ring beyond them.
const HUBS = [[0, -2], [-48, 36], [48, 36], [-48, -46], [48, -46], [0, 78], [-96, -4], [96, -4]].map(([dx, dy]) => [cx + dx, cy + dy]);
const near = (name, hub, r) => world.buildings.filter(b => b && (name === 'beds' ? b.beds : b.name === name) && Math.hypot(b.cx - hub[0], b.cy - hub[1]) <= r);
const fieldRing = [[-30, -8], [18, -8], [-30, 8], [18, 8], [-6, -32], [-6, 20], [-30, -24], [18, -24], [-30, 24], [18, 24], [-44, 0], [32, 0]];
function steward() {
  const people = sim.count, hubs = HUBS.slice(0, Math.min(HUBS.length, 1 + Math.floor(people / 28)));
  if (!count('green')) place('green', cx + 12, cy + 3);
  for (const h of hubs) { if (!near('well', h, 9).length) place('well', h[0] + 2, h[1] + 2); if (h !== hubs[0] && !near('green', h, 16).length) place('green', h[0] + 6, h[1] - 8); }
  for (let k = 0; k < 3 && count('lodge') < 1 + Math.floor(people / 8); k++) {   // a lodge at the wood nearest the hub with fewest lodges
    const h = hubs.map(h => [h, near('lodge', h, 40).length]).sort((x, y) => x[1] - y[1])[0][0];
    let best = null;
    for (let r = 4; r <= 36 && !best; r += 4) for (let q = 0; q < 12 && !best; q++) { const x = Math.round(h[0] + Math.cos(q * 0.5236) * r), y = Math.round(h[1] + Math.sin(q * 0.5236) * r); if (world.inside(x, y) && world.get(x, y) === 0 && R.woodYield(x, y) >= 0.8) best = [x, y]; }
    if (!best || !place('lodge', best[0], best[1])) break;
  }
  for (let k = 0; k < 6 && R.farmland().area < people * 38; k++) {            // a field by the hub that has least land for its beds
    const h = hubs.map(h => [h, near('field', h, 46).reduce((n, f) => n + f.area, 0) / (1 + near('beds', h, 14).reduce((n, f) => n + f.beds, 0))]).sort((x, y) => x[1] - y[1])[0][0];
    const o = fieldRing[near('field', h, 46).length % fieldRing.length];
    if (!place('field', h[0] + o[0], h[1] + o[1], [12, 12])) break;
  }
  for (let k = 0; k < 3 && E.capOf('grain') < people * 34 + 300; k++) place('granary', ...spot());
  if (P.level >= 2) for (const n of ['carpenter', 'chapel', 'mill', 'bakery']) if (!count(n)) place(n, ...spot());
  if (P.level >= 2) for (const h of hubs) if (count('chapel') < Math.ceil(people / 50) && !near('chapel', h, 20).length) { place('chapel', h[0] - 8, h[1] - 8); break; }
  if (forceTown && C.year >= forceTown && P.level === 2) P.setLevel(3);
  if (P.level >= 3) for (const n of ['market', 'brewery', 'tavern', 'watch house']) if (!count(n)) place(n, ...spot());
  for (let k = 0; k < 3 && sim.beds - sim.housed < 6 + P.level * 6; k++) {    // a house at the hub with fewest beds
    const h = hubs.map(h => [h, near('beds', h, 14).reduce((n, f) => n + f.beds, 0)]).sort((x, y) => x[1] - y[1])[0][0];
    const a = (ring++) * 2.4, r = 4 + (ring % 7);
    place(P.level >= 2 ? 'cottage' : 'hut', Math.round(h[0] + Math.cos(a) * r), Math.round(h[1] + Math.sin(a) * r)) || place('hut', Math.round(h[0] + Math.cos(a) * r), Math.round(h[1] + Math.sin(a) * r));
  }
}
for (let day = 0; day < yearsToRun * 12; day++) {
  steward();
  for (let k = 0; k < H.DAY; k++) { world.work(2); sim.step(); }
}
const tally = {}; for (const b of world.buildings) if (b) tally[b.name] = (tally[b.name] ?? 0) + 1;
console.log('buildings', JSON.stringify(tally));
console.log('houses with water', world.buildings.filter(b => b && b.beds && b.water).length, 'of', world.buildings.filter(b => b && b.beds).length, '| fields with no house in reach', world.buildings.filter(b => b && b.name === 'field' && R.nearestHouse(b) > H.COMMUTE).length, '| doing', (() => { const d = {}; for (let i = 0; i < sim.count; i++) { const a = sim.actions[sim.action[i]].name; d[a] = (d[a] ?? 0) + 1; } return JSON.stringify(d); })());
{ const f = sim.field[sim.actionIndex('drink')]; console.log('cut off from a well:', world.buildings.filter(b => b && f[b.ey * world.w + b.ex] === 65535).map(b => b.name + '@' + b.x + ',' + b.y).join(' ') || 'none'); }
console.log('stage', P.level, P.levelInfo().next?.text ?? '', '| goal', P.goal()?.title ?? 'all met', '| standing', R.standing, 'levies', R.leviesPaid);
console.log('achievements', P.achievements().filter(a => a.done).map(a => a.title).join(', '));
const recs = L.records, alive = recs.filter(r => r.died === null), withKids = recs.filter(r => r.children.length);
console.log(`records ${recs.length} (alive ${alive.length}), with children ${withKids.length}, couples ${recs.filter(r => r.partner !== null).length / 2}, families ${new Set(recs.map(r => r.family)).size}, unnamed ${alive.filter(r => !r.family).length}`);
const eg = withKids[withKids.length - 1]; if (eg) { const k = L.kin(eg); console.log('e.g.', L.nameOf(eg), '| partner', L.nameOf(k.partner), '| children', k.children.map(L.nameOf).join(', '), '| parents', k.parents.map(L.nameOf).join(', ')); }
const doing = {}; for (let i = 0; i < sim.count; i++) { const a = sim.actions[sim.action[i]].name; doing[a] = (doing[a] ?? 0) + 1; } console.log(JSON.stringify(doing));
