import { pathToFileURL } from 'node:url';
const root = process.argv[2], days = +(process.argv[3] ?? 60);
const { World } = await import(pathToFileURL(root + '/engine/world.js'));
const { Sim } = await import(pathToFileURL(root + '/engine/sim.js'));
const T = await import(pathToFileURL(root + '/examples/daylife/town.js'));
const modes = { both: ['money', 'food', 'materials'], 'goods only': ['food', 'materials'], 'money only': ['money'], none: [] };
const pick = process.argv[4] ? { [process.argv[4]]: modes[process.argv[4]] } : modes;

for (const [mode, resources] of Object.entries(pick)) {
  const cfg = T.makeConfig({}, resources), E = T.economy;
  const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs });
  cfg.map.build(world);
  const sim = new Sim(world, cfg);
  sim.setCount(cfg.agents);
  console.log(`\n=== ${mode}: resources [${resources.join(', ')}] | features [${sim.featureNames.slice(sim.K).join(', ')}] | ${sim.jobs || world.buildings.reduce((x, b) => x + b.jobs, 0)} jobs`);
  const start = Object.fromEntries(resources.map(r => [r, E.town[r] + E.held(r)]));
  let last = JSON.parse(JSON.stringify(E.totals));
  for (let t = 0; t < days * T.DAY; t++) {
    sim.step();
    if (t % (10 * T.DAY) === 10 * T.DAY - 2) {
      const L = T.lives, n = sim.count; let poor = 0, broke = 0, denied = 0, mood = 0;
      for (let i = 0; i < n; i++) { if (sim.features.poor) poor += sim.features.poor[i]; if (resources.includes('money') && E.balance(i, 'money') < 1) broke++; if (sim.deny[i]) denied++; mood += L.mood[i]; }
      const perDay = r => { const a = E.totals[r], b = last[r]; return `+${((a.made - b.made) / 10).toFixed(0)} −${((a.used - b.used) / 10).toFixed(0)}/day`; };
      const stores = resources.map(r => `${r} town ${E.town[r].toFixed(0)}${E.pockets[r] ? ` held ${E.held(r).toFixed(0)}` : ''} (${perDay(r)}${E.totals[r].refused - last[r].refused ? `, ${E.totals[r].refused - last[r].refused} refusals` : ''})`).join(' | ');
      last = JSON.parse(JSON.stringify(E.totals));
      console.log(`day ${String(T.dayNumber(sim.tick)).padStart(3)} pop ${String(n).padStart(3)} employed ${sim.employed}/${sim.workforce} closed ${world.buildings.filter(b => b && !b.open).length} | mood ${(mood / n).toFixed(2)} poor ${(poor / n).toFixed(2)} broke ${broke} barred ${denied} | ${stores}`);
      console.log(`        born ${L.stats.births} left ${L.stats.left} deaths ${JSON.stringify(L.stats.deaths)}`);
    }
  }
  // money can only move, never appear or vanish
  if (resources.includes('money')) console.log(`money conserved: started ${start.money.toFixed(0)}, now ${(E.town.money + E.held('money')).toFixed(0)} (people who died took ${''}their pockets with them)`);
  console.log(`build: house costs ${JSON.stringify(E.costOf('house'))}, affordable ${E.canAfford('house')}`);
}
