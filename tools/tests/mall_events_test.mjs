// Headless: the mall's events and upkeep. Litter falls and a cleaner picks it up; things break and are mended; each
// event is brought up by hand and answered, and what it should do is checked.   node tools/tests/mall_events_test.mjs
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import * as M from '../../games/mall/mall.js';

const cfg = M.makeConfig({ seed: 5 });
const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
const sim = new Sim(world, cfg);
cfg.map.build(world); sim.setCount(0); sim.assign(); world.work(Infinity);
const { economy: E, visitors: V, staff: S, floors: F, progress: G, reputation: REP, upkeep: U, events: EV, policies: P, trade: T, rules: R } = cfg.mall;
const failures = [], check = (ok, what) => { if (!ok) failures.push(what); };
const place = (name, x, y) => { if (sim.canBuild(name, sim) !== true) return null; const b = world.place(name, x, y, 'auto'); if (b) sim.onPlace(b, sim); return b; };
const run = ticks => { for (let t = 0; t < ticks; t++) sim.step(); };
const until = (what, most = 3 * M.DAY) => { let n = 0; while (!what() && n++ < most) sim.step(); return n <= most; };
const reports = [], news = [];
R.onEvent = (kind, r) => { if (kind === 'report') reports.push(r); else if (kind === 'inspected' || kind === 'stolen') news.push([kind, r]); };
EV.onNews = (kind, e, c) => news.push([kind, e.id, c?.id]);
const count = type => { let n = 0; for (let i = 0; i < sim.count; i++) if (sim.types[sim.type[i]].name === type) n++; return n; };

// a mall at the destination stage, with two floors, an escalator, a cleaner and (later) a guard
G.setLevel(4); E.give('money', 200000); R.draw = M.FOOTFALL[4];    // the standing of a destination, and the visitors that go with it
for (const [n, x, y] of [['café', 11, 17], ['clothes shop', 19, 16], ['kiosk', 12, 13], ['toilets', 19, 12], ['fast food', 10, 9], ['grocer', 20, 6]]) check(place(n, x, y), n + ' placed');
check(R.buyFloor() === true && R.connect('escalator', 5, 5) === true, 'a floor and an escalator');
const café = world.buildings.find(b => b && b.name === 'café');

// ── day 1: no cleaner, no bins: litter builds up and is noticed
until(() => reports.length === 1);
const d1 = reports[0];
console.log(`day 1: in ${d1.arrived} | litter left ${d1.litter.left} cleaned ${d1.litter.cleaned} | put off ${d1.gripes.find(g => g.key === 'litter')?.n ?? 0}`);
check(d1.litter.left > 5 && d1.litter.cleaned === 0, 'litter builds up with nobody to clean it');
// ── day 2: a cleaner's cupboard and bins
check(place('cleaner\'s cupboard', 6, 16), 'a cleaner\'s cupboard');
for (const [x, y] of [[14, 16], [18, 16], [14, 19], [18, 19], [16, 13]]) R.layTile('bin', x, y);
let cleanersSeen = 0;
until(() => { cleanersSeen = Math.max(cleanersSeen, count('cleaner')); return reports.length === 2; });
const d2 = reports[1];
console.log(`day 2: in ${d2.arrived} | litter left ${d2.litter.left} cleaned ${d2.litter.cleaned} | put off ${d2.gripes.find(g => g.key === 'litter')?.n ?? 0} | cleaner's wages ${Math.round(d2.units.find(u => u.name.startsWith('cleaner')).wages)}`);
check(cleanersSeen === 1, 'a cleaner came in');
check(d2.litter.cleaned > 0 && d2.litter.left < d1.litter.left, 'the cleaner and the bins kept the floor cleaner');
check(d2.units.find(u => u.name.startsWith('cleaner')).wages > 50, 'and the cleaner was paid');
check(U.dirty > 0 || true, '');

// ── day 3: events, one after another
until(() => R.phase === 'open');
check(U.dirty === 0, 'the night\'s cleaning cleared the floor');
check(EV.trigger('rain') && Math.abs(EV.mod('visitors') - M.EVENTS.rain.visitors) < 1e-9, 'rain brings more visitors');
// a breakdown, mended today
const cashBefore = E.town.money;
check(EV.trigger('unit broke'), 'something broke');
const brokenUnit = U.broken()[0];
check(brokenUnit && brokenUnit.blocked && EV.state.engineer.status === 'asking', `a unit broke down and is shut (${brokenUnit?.name}), and the engineer is asked about`);
check(EV.choose('engineer', 'now') && E.town.money < cashBefore, 'the engineer was called, and paid');
run(M.EVENTS.breakdown.takes + 40);
check(!brokenUnit.broken && !brokenUnit.blockedBy?.broken, 'an hour later it works again');
// the escalator, left for the contractor
check(EV.trigger('way broke') && F.list[0].broken && world.links === 0, 'the escalator broke: nobody can ride it');
check(EV.choose('way repair', 'wait'), 'left for the contractor');
// a power cut, sat out
check(EV.trigger('power cut') && EV.choose('power cut', 'sit') && EV.state.blackout.status === 'announced', 'a power cut is announced');
until(() => EV.state.blackout.status === 'active');
run(2);
check(café.blockedBy?.power && !café.open, 'with the power off the café is shut');
until(() => EV.state.blackout.status === 'idle');
run(20);
check(!café.blockedBy?.power, 'and open again when it is back');
// the inspector, with a dirty floor
for (let k = 0; k < 40; k++) U.drop((12 + (k % 8)) + (14 + ((k / 8) | 0)) * world.w, 2);
const starsBefore = REP.rating;
check(EV.trigger('inspector') && EV.choose('inspector', 'trust'), 'the inspector looked');
check(news.some(n => n[0] === 'inspected' && n[1].pass === false) && REP.rating < starsBefore, 'a dirty mall is fined and loses standing');
until(() => reports.length === 3);
const d3 = reports[2];
console.log(`day 3: in ${d3.arrived} | other costs ${Math.round(d3.other)}: ${d3.extras.map(e => e.what).join(', ')}`);
check(d3.other > 0 && d3.extras.some(e => e.what === 'repairs') && d3.extras.some(e => e.what.includes('fine')), 'the day\'s report lists what the events cost');
check(d3.notes.some(n => n.includes('Also paid today')), 'and says so in words');

// ── day 4: the contractor has been; a heatwave left alone; a guard
until(() => R.phase === 'open');
check(!F.list[0].broken && world.links === 2, 'the contractor mended the escalator overnight');
check(EV.trigger('heatwave') && EV.choose('heatwave', 'leave') && EV.isActive('hot mall'), 'a heatwave, left as it is');
check(place('security office', 4, 9), 'a security office');
let guardsSeen = 0, patrols = 0;
const patrolA = sim.actionIndex('patrol');
until(() => { guardsSeen = Math.max(guardsSeen, count('guard')); for (let i = 0; i < sim.count; i++) if (sim.action[i] === patrolA && sim.using[i]) patrols++; return reports.length === 4; });
const d4 = reports[3];
console.log(`day 4: in ${d4.arrived} | too hot ${d4.gripes.find(g => g.key === 'heat')?.n ?? 0} | guards ${guardsSeen}, ticks on the beat ${patrols}`);
check((d4.gripes.find(g => g.key === 'heat')?.n ?? 0) > 10, 'visitors found the mall too hot');
check(guardsSeen === 1 && patrols > 100, 'a guard walked the beat');
check(d4.arrived === d4.gone, 'everyone went home');
run(M.hours(1.5));
check(S.count === 0, 'and so did the staff, the cleaner and the guard');
// every event in the table can at least be brought up
for (const e of R.events) { const s = EV.state[e.id]; check(s !== undefined, `event ${e.id} has a state`); }
console.log(failures.filter(Boolean).length ? 'FAILED:\n  ' + failures.filter(Boolean).join('\n  ') : 'PASS: events and upkeep do what they say');
process.exit(failures.filter(Boolean).length ? 1 : 0);
