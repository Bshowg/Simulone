// Headless: the mall game with a scripted manager. node tools/tests/mall.mjs [days] [seed]
// Prints each day's report. Ends with PASS or the list of what did not hold.
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import * as M from '../../games/mall/mall.js';

const days = +(process.argv[2] ?? 6), seed = +(process.argv[3] ?? 7);
const cfg = M.makeConfig({ seed });
const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
const sim = new Sim(world, cfg);
cfg.map.build(world); sim.setCount(0); sim.assign(); world.work(Infinity);
const { calendar: C, economy: E, visitors: V, trade: T, staff: S, policies: P, reputation: REP, progress: G, rules: R } = cfg.mall;
const failures = [], check = (ok, what) => { if (!ok) failures.push(what); };
const money = n => M.MONEY.sign + Math.round(n);

let spentOnBuilding = 0, stageSeen = 1;
// rewards are money from outside the tills: counted with what was spent, as a negative
G.onEvent = (kind, it) => { spentOnBuilding -= it.reward?.grant?.money ?? 0; if (kind === 'level') { stageSeen = it.level; console.log(`   * the mall is now: ${M.STAGE_NAMES[it.level]}`); } else if (kind === 'goal') console.log(`   * goal met: ${it.title}`); };
function place(name, x, y, rot = 'auto') {
  if (sim.canBuild(name, sim) !== true || R.canPlaceAt(name, x, y, rot) !== true) return null;
  const b = world.place(name, x, y, rot);
  if (b) { sim.onPlace(b, sim); spentOnBuilding += E.costOf(name).money; }
  return b;
}
function tile(name, x, y) { const ok = R.layTile(name, x, y) === true; if (ok) spentOnBuilding += R.tileCost(name); return ok; }

// the manager: a café, a clothes shop and a kiosk on day 1, toilets and benches on day 2; then the business side:
// day 3 nobody at the kiosk and dear clothes, day 4 the money runs out at closing and the bank's loan is taken
const unitAt = name => world.buildings.find(b => b && b.name === name);
let drained = 0, loanOffered = false;
const plan = {
  1: () => { check(place('café', 11, 17), 'café placed'); check(place('clothes shop', 19, 16), 'clothes shop placed'); check(place('kiosk', 12, 13), 'kiosk placed');
             check(place('gym', 3, 3) === null, 'a stage 3 unit is refused at stage 1'); check(place('entrance', 5, 5) === null, 'a way in is refused off the edge'); },
  2: () => { check(place('toilets', 19, 12), 'toilets placed'); check(tile('bench', 14, 14), 'bench laid'); check(tile('bench', 18, 14), 'bench laid'); },
  3: () => { S.hire(unitAt('kiosk'), 0); P.set('price:clothes shop', 2); },
  4: () => { S.hire(unitAt('kiosk'), 1); P.set('price:clothes shop', 1); },
};
let reports = 0, allTakings = 0, allCosts = 0, peak = 0, staffSeen = 0;
R.onEvent = (kind, r) => {
  if (kind === 'morning' || (kind === 'opened' && R.day === 1)) { if (kind === 'opened') plan[1]?.(); else plan[R.day]?.(); }
  if (kind === 'closing' && R.day === 4) { drained = E.town.money; E.give('money', -drained); spentOnBuilding += drained; }   // the till is emptied before the bills come
  if (kind === 'loan') { loanOffered = true; check(R.takeLoan(), 'the loan was taken'); spentOnBuilding -= r.amount; }
  if (kind !== 'report') return;
  reports++; allTakings += r.takings; allCosts += r.goods + r.wages + r.upkeep + r.loan;
  console.log(`== day ${r.day} ${r.weekday}: in ${r.arrived} ${JSON.stringify(r.byKind)} (peak ${peak}) | visits ${r.rating.toFixed(2)} rating ${r.ratingBefore.toFixed(2)}>${r.ratingAfter.toFixed(2)} | takings ${money(r.takings)} goods ${money(r.goods)} wages ${money(r.wages)} upkeep ${money(r.upkeep)} profit ${money(r.profit)} cash ${money(r.cash)}${r.owed ? ' OWED ' + money(r.owed) : ''}`);
  console.log('   left:', JSON.stringify(r.left), '| met:', JSON.stringify(r.met));
  for (const u of r.units) console.log(`   ${u.name.padEnd(14)} sales ${String(u.sales).padStart(3)} takings ${money(u.takings).padStart(6)} goods ${money(u.goods).padStart(5)} wages ${money(u.wages).padStart(5)} result ${money(u.result).padStart(6)} staff ${u.staff}/${u.posts} turned ${u.turned} short ${u.short}${u.soldOut ? ' SOLD OUT' : ''}${u.shut ? ' SHUT' : ''}`);
  for (const n of r.notes) console.log('   >', n);
  for (const g of r.worst) console.log('   !', g.text);
  check(V.count === 0, `day ${r.day}: nobody left inside after closing`);
  check(r.arrived === r.gone, `day ${r.day}: everyone who came in went out`);
  const kiosk = r.units.find(u => u.name === 'kiosk'), clothes = r.units.find(u => u.name === 'clothes shop');
  if (r.day === 3) { check(kiosk.sales === 0 && r.notes.some(n => n.includes('kiosk stayed shut')), 'day 3: the kiosk with nobody hired stayed shut, and the report says so');
    check(clothes.sales > 0 && Math.abs(clothes.takings / clothes.sales - 45) < 2.01, `day 3: dear clothes sold at the dear price (${(clothes.takings / clothes.sales).toFixed(1)})`); }
  if (r.day === 4) { check(kiosk.sales > 0, 'day 4: the kiosk is staffed and sells again'); check(r.owed > 0 && r.loanOffer, 'day 4: the bills could not be paid, and the bank offers its loan'); }
  if (r.day === 5) check(r.loan === M.LOAN.daily && r.owed === 0, 'day 5: the loan is being repaid and nothing is owed');
  peak = 0;
};
// every building's head counts match the people inside it (they stay in for a second thing without going out and back)
let countsOff = 0;
const checkCounts = () => {
  for (const b of world.buildings) if (b) {
    let inside = 0, customers = 0;
    for (let i = 0; i < sim.count; i++) if (sim.inside[i] === b.id) { inside++; if (sim.actions[sim.action[i]].at && !sim.actions[sim.action[i]].at.startsWith('@')) customers++; }
    if (inside !== b.inside || customers !== b.customers) countsOff++;
  }
};
const t0 = performance.now();
while (reports < days && sim.tick < (days + 1) * M.DAY) { sim.step(); if (V.count > peak) peak = V.count; if (S.count > staffSeen) staffSeen = S.count; if (sim.tick % 997 === 0) checkCounts(); }
check(countsOff === 0, `building head counts match who is inside (${countsOff} off)`);
for (let t = 0; t < M.hours(1.5); t++) sim.step();                            // the staff see themselves out
console.log(`${sim.tick} ticks in ${(performance.now() - t0).toFixed(0)} ms`);
check(reports === days, `${days} reports came`);
check(allTakings > 0, 'something was sold');
check(Math.abs(E.town.money - R.owed - (M.MONEY.start - spentOnBuilding + allTakings - allCosts)) < 0.01, `the cash adds up (${E.town.money - R.owed} against ${M.MONEY.start - spentOnBuilding + allTakings - allCosts})`);
check(staffSeen >= 5, `staff came in to work (${staffSeen} at most)`);
if (days >= 6) { check(stageSeen >= 2, 'the parade became an arcade'); check(sim.canBuild('grocer', sim) === true || String(sim.canBuild('grocer', sim)).startsWith('it takes'), 'and the grocer is unlocked'); }
check(Object.keys(V.tally.byKind).length === 0 && REP.days.length === days, 'the rating was moved once a day');
check(S.count === 0, 'staff went home');
console.log(failures.length ? 'FAILED:\n  ' + failures.join('\n  ') : 'PASS: the mall trades, closes and reports');
process.exit(failures.length ? 1 : 0);
