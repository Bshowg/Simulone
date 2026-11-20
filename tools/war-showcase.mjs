// Make WAR's showcase: a save code of a war on its ninth day, with a battle of 4,000 men against 4,000 at Stonebridge
// caught in the thick of it. Both generals fight the battle up to that moment; the player takes over from there.
//   node tools/war-showcase.mjs [seconds into the battle]      writes games/war/showcase.txt
import { World } from '../engine/world.js';
import { Sim } from '../engine/sim.js';
import { gzipSync } from 'node:zlib';
import { writeFileSync } from 'node:fs';
import * as War from '../games/war/war.js';
import { ordinal } from '../games/war/modules/campaign.js';

const into = +(process.argv[2] ?? 38);
const cfg = War.makeConfig({});
const world = new World({ width: cfg.map.width, height: cfg.map.height, tiles: cfg.tiles, prefabs: cfg.prefabs, floor: cfg.floor });
const sim = new Sim(world, cfg);
sim.setCount(0); sim.assign(); world.work(Infinity); sim.fieldBudgetMs = 0;

// The war so far: both sides have raised armies of twenty regiments and met at the crossing in the middle.
const camp = War.campaign;
camp.newWar(); camp.player = 0;
const S = camp.state;
S.day = 9; S.gold = [180, 140];
S.owner.hallow = 0; S.owner.bright = 1; S.owner.harrow = 1;
const full = (kinds, exp) => kinds.map(k => ({ id: S.next++, kind: k, men: War.REGIMENT_MEN, wounded: 0, exp, name: '' }));
const mine = ['spear', 'spear', 'spear', 'spear', 'spear', 'sword', 'sword', 'sword', 'levy', 'levy', 'levy', 'archer', 'archer', 'archer', 'archer', 'rider', 'rider', 'rider', 'spear', 'sword'];
const theirs = ['spear', 'spear', 'spear', 'spear', 'sword', 'sword', 'sword', 'levy', 'levy', 'levy', 'levy', 'archer', 'archer', 'archer', 'archer', 'rider', 'rider', 'rider', 'spear', 'levy'];
const a = camp.armies(0)[0], b = camp.armies(1)[0];
a.regiments = full(mine, 0.6); a.at = 'stone'; a.path = [];
b.regiments = full(theirs, 0.5); b.at = 'stone'; b.path = [];
for (const r of [...a.regiments, ...b.regiments]) r.name = ordinal(r.id);
S.armies = S.armies.filter(x => x === a || x === b || x.side === 1 && x.at !== 'stone');
S.pending = { at: 'stone', sides: [[a.id], [b.id]], garrison: false };

const field = { at: 'stone', name: 'Stonebridge', country: camp.province('stone').country, seed: 2741, begun: true };
War.startBattle(sim, { seed: field.seed, country: field.country, sides: camp.battleSides() });
War.battle.player = -1;
for (let t = 0; t < into * War.TICKS_PER_SECOND && !War.battle.result; t++) sim.step();
const standing = s => War.regiments.all(s).reduce((n, r) => n + r.active, 0);
console.log(`${into} s in: ${sim.count} men on the field, standing ${standing(0)} / ${standing(1)}, ${War.combat.arrows.length} arrows in the air, result ${JSON.stringify(War.battle.result)}`);
War.battle.player = 0;
const save = { v: 1, campaign: S, battle: War.saveBattle(sim, { seed: field.seed, country: field.country, field }), camera: null, speed: 1 };
const profile = { wars: 1, won: 0, lost: 0, battles: 0, victories: 0, biggest: 0 };
const bundle = { v: 1, game: 'war', keys: { 'war-save': JSON.stringify(save), 'war-profile': JSON.stringify(profile) } };
const code = `SIMULONE1:war:G${gzipSync(JSON.stringify(bundle)).toString('base64')}`;
writeFileSync(new URL('../games/war/showcase.txt', import.meta.url), code + '\n');
console.log(`games/war/showcase.txt: ${(code.length / 1024).toFixed(0)} KB`);
