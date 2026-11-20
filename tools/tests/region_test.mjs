// Headless: the region. Play the first grant, get the second, settle it, play there, send carts home, come back.
import { World } from '../../engine/world.js';
import { Sim } from '../../engine/sim.js';
import { createSave } from '../../modules/save.js';
import * as H from '../../games/lords-will/hamlet.js';
const saves = createSave({ version: 2 }), region = H.region;
const fmt = o => Object.entries(o).filter(([, n]) => Math.abs(n) >= 0.5).map(([k, n]) => `${k} ${Math.round(n)}`).join(', ') || '-';
region.onNews = (kind, x) => { if (kind === 'granted') console.log(`    the lord grants ${x.name} (${x.kind}, ${x.size.join('×')})`); else if (x.arrived.length || x.short.length || x.lean.length) console.log('    region:', JSON.stringify(x)); };
let sim, world;
function open(id) {                                             // what the page does to go to a land
  const land = H.LANDS.find(l => l.id === id), st = region.enter(id), cfg = H.makeConfig({}, land);
  world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
  sim = new Sim(world, cfg); cfg.map.build(world); sim.setCount(0);
  if (st.snapshot) { H.populate(sim); saves.restore(sim, st.snapshot); H.setStores(st.stores); }
  else { H.populate(sim); if (Object.keys(st.stores).length) H.startWith(st.stores); }   // a new settlement has only what its party carried
  if (region.state.tick > sim.tick || st.snapshot) H.catchUp(sim, region.state.tick);
  return land;
}
function close() { region.keep(H.current.id, { snapshot: JSON.parse(JSON.stringify(saves.snapshot(sim))), stores: H.economy.town, caps: Object.fromEntries(Object.keys(H.economy.town).map(r => [r, H.economy.capOf(r)]).filter(([, c]) => c < Infinity)), people: sim.count, info: { stage: H.progress.level }, tick: sim.tick }); }
const place = (name, x, y, size) => { for (let r = 0; r < 24; r++) for (let j = -r; j <= r; j++) for (let i = -r; i <= r; i++) { if (Math.max(Math.abs(i), Math.abs(j)) !== r) continue; if (sim.canBuild(name, sim) !== true) return null; const b = world.place(name, x + i, y + j, 'auto', size); if (b) { sim.onPlace(b, sim); return b; } } return null; };
const play = days => { for (let t = 0; t < H.DAY * days; t++) sim.step(); };
const where = () => `${H.current.id} y${H.calendar.year} ${H.calendar.seasonName} d${H.calendar.dayOfSeason} | people ${sim.count} | ${fmt(H.economy.town)}`;

open('home');
let [cx, cy] = H.CENTRE;
place('field', cx - 14, cy + 6, [12, 12]); place('field', cx + 2, cy + 6, [12, 12]); place('lodge', cx - 14, cy - 5); place('green', cx + 12, cy + 3); place('granary', cx - 12, cy + 2);
play(7);
console.log('home after 7 days :', where(), '| lands held', region.held().map(h => h.def.id).join(','));
H.progress.setLevel(3); play(0.2);
console.log('held now          :', region.held().map(h => h.def.id).join(','), '| can settle second:', H.canSettle('second'));
H.economy.town.timber += 150;                                 // (the test's steward has been saving timber)
console.log('settle second     :', H.settleLand('second'), '| home store after the party left:', fmt(H.economy.town));
play(5.8);                                                      // through to winter, so the book has spring to autumn
console.log('home book         :', JSON.stringify(region.land('home').book));
close();
const homeAtLeave = where(), tickAtLeave = sim.tick;

const land2 = open('second');
[cx, cy] = H.CENTRE;
console.log('second, on arrival:', where(), '| map', world.w + '×' + world.h, JSON.stringify(H.land.counts), '| soil', H.KINDS[land2.kind].soil, '| tick', sim.tick, '=', tickAtLeave);
const lodge = place('lodge', cx - 10, cy - 6); place('green', cx + 8, cy + 3); place('field', cx - 12, cy + 5, [10, 10]);
console.log('  lodge yield here:', lodge?.yield.toFixed(2), '| goals restart:', H.progress.goal()?.title, '| level', H.progress.level, '| lands stat', H.progress.get('lands'), '| reeve', H.progress.hasAchieved('reeve'));
console.log('  order firewood home:', region.order('second', 'home', { firewood: 40 }), '| one-off timber:', JSON.stringify(H.sendGoods('home', { timber: 30 })));
play(12);                                                       // a year in the second land
console.log('second after a year:', where());
console.log('home meanwhile    :', fmt(region.land('home').stores), '| on the road to home', JSON.stringify(region.coming('home')));
close();

open('home');
console.log('home when left    :', homeAtLeave);
console.log('home on return    :', where(), '| tick', sim.tick, '| fields', JSON.stringify(H.rules.farmland()), '| crop', H.rules.fields().map(f => f.crop).join(','));
play(3);
console.log('home, a season on :', where(), '| homeless', sim.count - sim.housed);
const data = JSON.parse(JSON.stringify(region.save()));
console.log('region save', Math.round(JSON.stringify(data).length / 1024), 'KB | reload ok:', region.load(data), '| held', region.held().map(h => `${h.def.id}${h.state.settled ? '' : ' (empty)'}`).join(', '), '| orders', region.state.orders.length);
