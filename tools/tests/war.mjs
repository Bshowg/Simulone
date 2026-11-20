// Headless: WAR's campaign and its saves. A new war; the player's army marches on the enemy until armies meet; the
// battle is fought out by both generals; its losses go back to the campaign; then a battle under way is saved and
// loaded into a fresh simulation, and the campaign's state goes through JSON and back.
//   node tools/tests/war.mjs
// Ends with PASS or the list of what did not hold.
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import * as War from '../../games/war/war.js';

const failures = [], check = (ok, what) => { if (!ok) failures.push(what); };
const make = () => {
  const cfg = War.makeConfig({});
  const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
  const sim = new Sim(world, cfg);
  sim.setCount(0); sim.assign(); world.work(Infinity); sim.fieldBudgetMs = 0;
  return sim;
};

// ── the campaign
const camp = War.campaign;
camp.newWar(); camp.player = 0;
const army = camp.armies(0)[0], startMen = camp.men(army), startGold = camp.state.gold[0];
check(army && startMen === 12 * War.REGIMENT_MEN, `the player starts with an army of 12 full regiments (${startMen})`);
check(camp.raise(army, 'spear') !== null, 'a regiment can be raised in the capital');
check(camp.state.gold[0] === startGold - War.KINDS.spear.cost, 'raising costs gold');
check(camp.march(army, 'corvane'), 'the army can be sent to the enemy capital');
let days = 0;
while (!camp.pending() && !camp.state.over && days++ < 40) camp.endDay();
const pe = camp.pending();
console.log(`day ${camp.state.day}: ${pe ? `a battle at ${pe.at}${pe.garrison ? ' (a garrison)' : ''}` : 'no battle'}`);
check(!!pe, 'armies meet within 40 days');

// ── the battle it brings
const sim = make();
const sides = camp.battleSides();
War.startBattle(sim, { seed: 11, country: camp.province(pe.at).country, sides });
War.battle.player = -1;
check(sim.count === sides[0].reduce((n, r) => n + r.men, 0) + sides[1].reduce((n, r) => n + r.men, 0), 'every man of both armies is on the field');
let t = 0, live = sim;
for (; t < 8 * 60 * War.TICKS_PER_SECOND && !War.battle.result; t++) {
  sim.step();
  if (t === 30 * War.TICKS_PER_SECOND) {
    // save the battle under way and load it into a fresh simulation
    const data = JSON.parse(JSON.stringify(War.saveBattle(sim, { seed: 11, country: camp.province(pe.at).country })));
    const living = () => War.regiments.all().reduce((n, r) => n + r.men, 0);   // the fallen are not kept in a save
    const regs = War.regiments.all().length, men = living();
    const sim2 = make();                                         // makeConfig made new modules: load into them, check, then carry on with the copy
    War.loadBattle(sim2, data);
    check(living() === men, `the loaded battle has every man (${living()} of ${men})`);
    check(War.regiments.all().length === regs, 'and every regiment');
    for (let k = 0; k < 200; k++) sim2.step();
    check(sim2.count > 0 && !Number.isNaN(sim2.px[0]), 'the loaded battle runs on');
    live = sim2;                                                 // and the battle goes on in the loaded copy
    for (; t < 8 * 60 * War.TICKS_PER_SECOND && !War.battle.result; t++) sim2.step();
    break;
  }
}
const res = War.battle.result;
console.log(`the battle took ${(War.battle.elapsed / War.TICKS_PER_SECOND).toFixed(0)} s: ${JSON.stringify(res)}`);
check(!!res, 'the battle ends');
const losses = War.battleLosses(live);
const lostMen = Object.values(losses).reduce((n, l) => n + l.killed + l.wounded, 0);
check(lostMen > 0, 'men were lost');
const before = camp.armies().reduce((n, a) => n + camp.men(a), 0);
camp.afterBattle(res.winner, losses);
const after = camp.armies().reduce((n, a) => n + camp.men(a), 0) + camp.armies().reduce((n, a) => n + camp.wounded(a), 0);
console.log(`the armies had ${before} men; now ${after} with the wounded, in ${camp.armies().length} armies`);
check(!camp.pending(), 'the battle is cleared from the campaign');
check(camp.armies().some(a => a.regiments.some(r => r.exp > 0)), 'regiments gained experience');

// ── the campaign goes on, and survives JSON
for (let k = 0; k < 10; k++) { if (camp.pending()) camp.afterBattle(0, {}); camp.endDay(); }
const copy = JSON.parse(JSON.stringify(camp.state));
camp.load(copy);
check(camp.state.day === copy.day && camp.armies().length === copy.armies.length, 'the campaign loads back from JSON');
const wounded = camp.armies(0).reduce((n, a) => n + camp.wounded(a), 0);
console.log(`day ${camp.state.day}: gold ${camp.state.gold.map(Math.round)}, provinces ${[0, 1].map(s => camp.provinces().filter(p => camp.owner(p.id) === s).length)}, wounded ${wounded}`);

console.log(failures.length ? 'FAIL: ' + failures.join('; ') : 'PASS: the war marches, a battle is fought and saved, and the campaign takes its losses');
process.exit(failures.length ? 1 : 0);
