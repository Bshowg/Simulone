// Headless balance run: a scripted manager plays the mall from an empty lot towards a five-floor landmark, reading each
// day's report as a player would and building what it asks for.
//   node tools/tests/mall_balance.mjs [days=160] [seed=7] [quiet]
// Prints a line a day (unless `quiet`), every stage reached, and at the end when each stage and floor came.
// PASS means: a landmark with five floors inside the days given, and no day with visitors left inside.
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import * as M from '../../games/mall/mall.js';

const maxDays = +(process.argv[2] ?? 160), seed = +(process.argv[3] ?? 7), quiet = process.argv[4] === 'quiet';
const cfg = M.makeConfig({ seed });
const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
const sim = new Sim(world, cfg);
cfg.map.build(world); sim.setCount(0); sim.assign(); world.work(Infinity);
const { economy: E, visitors: V, staff: S, floors: F, progress: G, reputation: REP, upkeep: U, events: EV, policies: P, rules: R } = cfg.mall;
const unit = Object.fromEntries(M.UNITS.map(u => [u.name, u]));
const cash = () => E.town.money, W = world.w;
const failures = [], check = (ok, what) => { if (!ok) failures.push(what); };

// ── the plan every floor is laid out to: a spine up the middle, a cross corridor, and two side corridors, which leaves
// four rows of units; pockets beside the spine for benches, bins and plants; cells kept for the ways up
const SPINE = [14, 15, 16], CROSS = [9, 10], SIDE = [3, 17], HUB = [15, 10];
const KEPT = new Set(), POCKET = [];                                 // local cells no unit is built on; the pockets among them
for (const ly of [6, 13]) for (const lx of [12, 13, 17]) KEPT.add(lx + ',' + ly);
for (const ly of [0, 1, 2, 18, 19, 20, 21]) for (const lx of [12, 13, 17, 18]) { KEPT.add(lx + ',' + ly); POCKET.push([lx, ly]); }
for (let ly = 18; ly <= 20; ly++) KEPT.add('23,' + ly);              // the walk up from a second way in
const count = name => world.buildings.filter(b => b && b.name === name).length;
const walkway = world.id('walkway');
const line = (x0, y0, x1, y1) => { const n = world.line('walkway', x0, y0, x1, y1); if (n) sim.onLine('walkway', n, sim); return n; };
function layFloor(k) {                                               // corridors on a new floor
  const [x0, y0] = F.cell(k, 0, 0);
  for (const lx of SPINE) line(x0 + lx, y0, x0 + lx, y0 + M.FLOOR.h - 1);
  for (const ly of [...CROSS, ...SIDE]) line(x0, y0 + ly, x0 + M.FLOOR.w - 1, y0 + ly);
}
// Where a unit can go on floor k: on free ground, clear of the kept cells, with its door on a walkway; nearest the hub first.
function spot(name, k) {
  const [x0, y0] = F.cell(k, 0, 0);
  let best = null, bd = Infinity;
  for (let ly = 0; ly < M.FLOOR.h; ly++) for (let lx = 0; lx < M.FLOOR.w; lx++) {
    const L = world.orient(name, x0 + lx, y0 + ly, 'auto');
    if (!L || world.tiles[L.ey * W + L.ex] !== walkway || R.canPlaceAt(name, x0 + lx, y0 + ly, 'auto') !== true) continue;
    let clear = true;
    for (let j = 0; j < L.h && clear; j++) for (let i = 0; i < L.w; i++) if (KEPT.has((lx + i) + ',' + (ly + j))) { clear = false; break; }
    if (!clear || keptForBig(k, ly, L.w, L.h)) continue;
    const d = Math.abs(L.ex - x0 - HUB[0]) + Math.abs(L.ey - y0 - HUB[1]) + (lx + ly) * 0.001;
    if (d < bd) { bd = d; best = [x0 + lx, y0 + ly, L.rot]; }
  }
  return best;
}
const PULLS = ['cinema', 'gym', 'food court', 'games arcade', 'events space', 'roof garden', 'restaurant'];   // what draws people upstairs
// The deep row (between the cross corridor and the lower side corridor) is kept, upstairs, for units that need its depth.
const keptForBig = (k, ly, w, h) => k >= 1 && ly >= 11 && ly <= 16 && Math.max(w, h) < 5;
const built = [];
function build(name) {
  if (sim.canBuild(name, sim) !== true) return false;
  const order = [...Array(F.built).keys()];
  if (PULLS.includes(name)) order.reverse();
  if (unit[name].gate) order.length = 1;
  for (const k of order) {
    const at = spot(name, k);
    if (!at) continue;
    const b = world.place(name, at[0], at[1], at[2]);
    if (b) { sim.onPlace(b, sim); built.push(name + (k ? '@' + k : '')); return true; }
  }
  return false;
}
function tileNear(name, k, n) {                                      // benches, bins and plants in the pockets beside the spine
  const [x0, y0] = F.cell(k, 0, 0);
  let done = 0;
  for (const [lx, ly] of POCKET) { if (done >= n) break; if (R.layTile(name, x0 + lx, y0 + ly) === true) done++; }
  if (done) built.push(`${done} ${name}${k ? '@' + k : ''}`);
  return done;
}
function addFloor() {
  if (R.canBuyFloor() !== true || cash() < R.floorCost() + 6000) return false;
  check(R.buyFloor() === true, 'a floor was bought');
  const k = F.built - 1, ly = (k - 1) % 2 === 0 ? 6 : 13;
  layFloor(k);
  check(R.connect('escalator', ...F.cell(k - 1, 12, ly)) === true, `an escalator up to floor ${k}`);
  check(R.connect('lift', ...F.cell(k - 1, 17, ly)) === true, `a lift up to floor ${k}`);
  built.push('FLOOR ' + k);
  return true;
}

// ── the manager: each morning, mend what yesterday's report complained of, then grow
const WANT = [                                                        // what to have, in order, by the stage it comes at
  'café', 'clothes shop', 'kiosk', 'toilets',
  'grocer', 'fast food', 'bookshop', 'cleaner\'s cupboard', 'store room', 'staff room',
  'games arcade', 'pharmacy', 'food court', 'electronics', 'gym', 'store room',
  'cinema', 'department store', 'restaurant', 'security office', 'car park entrance',
  'events space', 'roof garden',
];
const SECOND = ['toilets', 'café', 'fast food', 'clothes shop', 'grocer', 'kiosk', 'cleaner\'s cupboard', 'games arcade', 'bookshop', 'pharmacy', 'food court', 'restaurant', 'electronics'];
let last = null, reserve = 1200;
function manage() {
  built.length = 0;
  const stage = R.stage();
  if (last) reserve = Math.max(1200, (last.goods + last.wages + last.upkeep) * 0.5);
  const can = name => !R.locked(name) && cash() - unit[name].cost >= reserve;
  // what the report complained of
  if (last) {
    const gripe = key => last.gripes.find(g => g.key === key)?.n ?? 0, share = n => n / Math.max(1, last.arrived);
    if (share(gripe('toilet:unmet')) > 0.06 && count('toilets') < F.built + Math.floor(last.arrived / 250) && can('toilets')) build('toilets');
    if (share(gripe('legs:unmet')) > 0.04) for (let k = 0; k < F.built; k++) if (cash() > reserve + 300) tileNear('bench', k, 3);
    if (share(gripe('litter')) > 0.08) { for (let k = 0; k < F.built; k++) if (cash() > reserve + 200) tileNear('bin', k, 3); if (can('cleaner\'s cupboard') && count('cleaner\'s cupboard') < F.built * 2 + 1) build('cleaner\'s cupboard'); }
    if (last.units.some(u => u.soldOut) && can('store room') && count('store room') < 2) build('store room');
    for (const u of last.units) if (unit[u.name].capacity && u.sales > unit[u.name].capacity * 22 && count(u.name) < 3 && can(u.name) && SECOND.includes(u.name)) { build(u.name); break; }
    for (const [need, name] of [['thirst', 'café'], ['hunger', 'fast food']]) if (share(gripe(need + ':unmet')) > 0.08 && !R.locked(name) && count(name) < 1 + F.built && can(name)) build(name);
    for (const g of last.gripes) if (g.key.endsWith(':queue') && g.n > last.arrived * 0.05) { const need = g.key.split(':')[0], u = M.UNITS.find(x => x.serves?.some(s => s.need === need) && !R.locked(x.name) && count(x.name) < 3); if (u && can(u.name)) { build(u.name); break; } }
  }
  // grow: a floor when one is allowed, then the next unit on the list
  addFloor();
  if (F.built > 1 && count('walkway-check') === 0) for (let k = 1; k < F.built; k++) if (!tileDone[k]) { tileDone[k] = true; tileNear('bench', k, 2); tileNear('bin', k, 3); }
  for (let n = 0; n < 2; n++) {
    const next = WANT.find((name, at) => !R.locked(name) && count(name) < WANT.slice(0, at + 1).filter(x => x === name).length);
    if (!next || !can(next) || !build(next)) break;
  }
  if (count('car park entrance') === 1 && !carWalk) { carWalk = true; const b = world.buildings.find(x => x && x.name === 'car park entrance'); line(b.ex, b.ey, b.ex, F.cell(0, 0, SIDE[1])[1]); }
  if (stage >= 1 && !tileDone[0] && cash() > reserve + 600) { tileDone[0] = true; tileNear('bench', 0, 3); tileNear('bin', 0, 3); tileNear('plant', 0, 4); }
}
const tileDone = {}; let carWalk = false;
layFloor(0);                                                         // the ground floor's corridors, on the first morning
// what to answer when something happens
const ANSWER = { heatwave: () => (cash() > 3000 ? 'cool' : 'leave'), 'power cut': () => (cash() > 3000 ? 'generator' : 'sit'), 'rival sale': () => 'sale',
  inspector: () => (U.dirty > 8 && cash() > 1000 ? 'clean' : 'trust'), 'première': () => (cash() > 4000 ? 'host' : 'decline'), 'way repair': () => (cash() > 1500 ? 'now' : 'wait'), engineer: () => (cash() > 1500 ? 'now' : 'wait') };
const happened = {};
EV.onNews = (kind, e) => { if (kind === 'asking') EV.choose(e.id, ANSWER[e.id]()); if (kind === 'asking' || kind === 'started') happened[e.id] = (happened[e.id] ?? 0) + 1; };

const stageDay = { 1: 1 }, floorDay = { 1: 1 }, days = [];
G.onEvent = (kind, it) => { if (kind === 'level') { stageDay[it.level] = R.day; console.log(`   *** day ${R.day}: now ${M.STAGE_NAMES[it.level]}`); } };
R.onEvent = (kind, r) => {
  if (kind === 'loan') { R.takeLoan(); console.log(`   *** day ${R.day}: took the bank's loan`); }
  if (kind === 'morning' || (kind === 'opened' && R.day === 1)) { manage(); for (let k = 2; k <= F.built; k++) floorDay[k] ??= R.day; }
  if (kind !== 'report') return;
  last = r; days.push(r);
  check(r.arrived === r.gone, `day ${r.day}: everyone who came in went out`);
  if (!quiet) console.log(`d${String(r.day).padStart(3)} ${r.weekday} S${r.stage} F${r.floors} | in ${String(r.arrived).padStart(4)} ★${r.ratingAfter.toFixed(2)} (${r.rating.toFixed(2)}) | take ${String(Math.round(r.takings)).padStart(6)} profit ${String(Math.round(r.profit)).padStart(6)} cash ${String(Math.round(r.cash)).padStart(7)}${r.owed ? ' OWED ' + Math.round(r.owed) : ''} | units ${r.units.length}` +
    ` | ${r.worst.map(g => g.key + ' ' + g.n).join(', ')}${built.length ? ' | + ' + built.join(', ') : ''}`);
};
const t0 = performance.now();
while (days.length < maxDays && !(R.stage() >= 5 && F.built >= 5 && days.length >= (stageDay[5] ?? 1e9) + 6)) sim.step();
console.log(`${days.length} days, ${sim.tick} ticks, in ${((performance.now() - t0) / 1000).toFixed(1)} s (${((performance.now() - t0) / sim.tick * 1000).toFixed(1)} µs a tick); most people at once ${Math.max(...days.map(d => d.arrived)) } a day`);
console.log('stages reached on day:', JSON.stringify(stageDay), '| floors built on day:', JSON.stringify(floorDay));
console.log('events:', JSON.stringify(happened));
const lastWeek = days.slice(-7), avg = k => Math.round(lastWeek.reduce((n, d) => n + d[k], 0) / lastWeek.length);
console.log(`the last week: ${avg('arrived')} visitors a day, takings ${avg('takings')}, profit ${avg('profit')} a day, rating ${REP.rating.toFixed(2)}, cash ${Math.round(cash())}, units ${last.units.length}`);
const week = {}; for (const d of lastWeek) for (const u of d.units) { const w = (week[u.name] ??= { n: 0, visits: 0, result: 0 }); w.n++; w.visits += u.sales; w.result += u.result; }
console.log('a day, each (last week):', Object.entries(week).map(([n, w]) => `${n} ${Math.round(w.visits / w.n)}v ${Math.round(w.result / w.n)}`).join(' | '));
const final = last.units.map(u => u.name).reduce((o, n) => (o[n] = (o[n] ?? 0) + 1, o), {});
console.log('units:', Object.entries(final).map(([n, k]) => (k > 1 ? `${k} × ${n}` : n)).join(', '));
check(R.stage() >= 5, `the mall became a landmark (it is at stage ${R.stage()} after ${days.length} days)`);
check(F.built >= 5, `it has five floors (${F.built})`);
console.log(failures.length ? 'FAILED:\n  ' + [...new Set(failures)].join('\n  ') : 'PASS: from an empty lot to a five-floor landmark');
process.exit(failures.length ? 1 : 0);
