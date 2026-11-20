// Headless: the chartered town's pieces, forced. node charter_test.mjs
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import * as H from '../../games/lords-will/hamlet.js';
function town(people) {
  H.region.reset();
  const cfg = H.makeConfig({}, H.LANDS[0]);
  const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
  const sim = new Sim(world, cfg); cfg.map.build(world); sim.setCount(0); H.populate(sim);
  const [cx, cy] = H.CENTRE;
  const place = (name, x, y, size) => { for (let r = 0; r < 30; r++) for (let j = -r; j <= r; j++) for (let i = -r; i <= r; i++) { if (Math.max(Math.abs(i), Math.abs(j)) !== r) continue; const why = sim.canBuild(name, sim); if (why !== true) return why; const b = world.place(name, x + i, y + j, 'auto', size); if (b) { sim.onPlace(b, sim); return b; } } return 'no room'; };
  // a town big enough to matter: plenty of everything, and people
  for (const [r, n] of Object.entries({ grain: 3000, firewood: 3000, timber: 2000 })) H.economy.town[r] = n;
  for (let k = 0; k < 6; k++) place('granary', cx - 20 + k * 4, cy - 14);
  H.economy.town.grain = 2600;
  place('green', cx + 12, cy + 3); place('well', cx - 12, cy + 4); place('well', cx + 16, cy - 6);
  H.progress.setLevel(2);
  H.economy.town.planks = 60; place('carpenter', cx + 6, cy - 9); place('chapel', cx + 18, cy - 2);
  for (let k = 0; k < 14; k++) { H.economy.town.planks = 60; place('cottage', cx - 24 + (k % 7) * 4, cy + 8 + Math.floor(k / 7) * 4); }
  H.rules.welcome(Math.ceil((people - sim.count) / 3));
  H.economy.town.planks = 60; place('mill', cx + 10, cy - 9); H.economy.town.planks = 60; place('bakery', cx + 14, cy - 9);
  return { sim, world, place, cx, cy };
}
const E = () => H.economy, R = () => H.rules, V = () => H.events, P = () => H.progress;
const run = (g, days) => { for (let t = 0; t < H.DAY * days; t++) g.sim.step(); };
const log = [];
const hook = g => { R().onEvent = (k, r) => { if (['fair', 'war', 'regard', 'levy'].includes(k)) log.push(`${k} ${JSON.stringify(r)}`); }; V().onNews = (k, e, c) => log.push(`event ${k}: ${e.title}${c ? ' → ' + c.label : ''}`); };

// 1. guilds and locks
let g = town(60); hook(g);
console.log('chartered buildings before the stage:', g.place('guildhall', g.cx, g.cy - 20));
P().setLevel(4); run(g, 0.1);
console.log('stage', P().level, P().levelInfo().title, '| next', P().levelInfo().next, '| coin', Math.round(E().town.coin), '| offers', H.offers().map(o => `${o.land.name} for ${JSON.stringify(o.price)}${o.affordable ? '' : ' (cannot afford)'}`).join('; '));
E().town.coin = 2000; E().town.planks = 60;
const before = { ...E().totals.planks }; run(g, 2);
const plain = E().totals.planks.made - before.made;
E().town.planks = 60; const hall = g.place('guildhall', g.cx, g.cy - 20); E().town.planks = 0; run(g, 0.2);
const mid = E().totals.planks.made; E().town.planks = 0; run(g, 2);
console.log('guildhall', typeof hall === 'object' ? 'built' : hall, '| guilded', R().guilded, '| planks made in 2 days without a guild', plain, 'and with', Math.round(E().totals.planks.made - mid));
// 2. the fair
E().town.planks = 60; console.log('fairground', typeof g.place('fairground', g.cx - 30, g.cy - 20) === 'object' ? 'built' : 'not built');
const c0 = E().town.coin; V().trigger('fair'); run(g, 1.2); console.log('fair: coin', Math.round(c0), '→', Math.round(E().town.coin), '| active', V().isActive('fair'), '| people', g.sim.count);
// 3. buying land
console.log('buy the heath:', H.buyLand('heath'), '| held', H.region.held().map(h => h.def.id).join(','), '| can settle', H.canSettle('heath'));
// 4. the lord's war and the rival
const n0 = g.sim.count; V().trigger('war'); V().choose('war', 'men'); run(g, 0.05); console.log('war, men sent: people', n0, '→', g.sim.count, '| deaths', JSON.stringify(H.lives.stats.deaths));
V().state.war.restUntil = 0; V().trigger('war'); V().choose('war', 'refuse'); console.log('war refused: regard', R().standing, '| levy share now', R().standing < H.DISFAVOUR.below ? H.DISFAVOUR.levyShare : H.LEVY.share);
V().trigger('rival'); V().choose('rival', 'refuse'); console.log('rival refused: merchants away', V().isActive('merchants away'), '| merchant may come', V().state.merchant.status, H.events.current().map(c => c.event.id).join(','));
console.log(log.join('\n  '));

// 5. plague, with and without a hospital
for (const withHospital of [false, true]) {
  g = town(120); P().setLevel(4); run(g, 0.5);
  if (withHospital) { E().town.coin = 500; E().town.planks = 60; console.log('  hospital', typeof g.place('hospital', g.cx, g.cy - 22) === 'object' ? 'built' : 'not built'); run(g, 1); }
  const n = g.sim.count; V().trigger('plague'); run(g, 5.2);
  console.log(`plague ${withHospital ? 'with' : 'without'} a hospital: people ${n} → ${g.sim.count}, died of plague ${H.lives.stats.deaths.plague ?? 0} (${Math.round(100 * (H.lives.stats.deaths.plague ?? 0) / n)}%), still active ${V().isActive('plague')}`);
}
