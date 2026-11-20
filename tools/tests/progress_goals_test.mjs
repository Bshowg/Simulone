// Goals are kept by id: a goal put into the list later does not throw a saved game onto the wrong goal, and a save
// from before 0.3.1 (which kept only how many goals were met) comes back to the right one.
import { createProgress } from '../../modules/progress.js';

const fake = { actions: [], types: [], tick: 0 };
let failed = 0;
const check = (what, got, want) => { const ok = got === want; if (!ok) failed++; console.log(`${ok ? 'ok  ' : 'FAIL'} ${what}: ${got}${ok ? '' : ` (wanted ${want})`}`); };
const goals = (extra) => [
  { id: 'a', when: { stat: 'a', atLeast: 1 } },
  ...(extra ? [{ id: 'new1', when: { stat: 'n1', atLeast: 1 }, addedLater: true }] : []),
  { id: 'b', when: { stat: 'b', atLeast: 1 } },
  { id: 'c', when: { stat: 'c', atLeast: 1 } },
  ...(extra ? [{ id: 'new2', when: { stat: 'n2', atLeast: 1 }, addedLater: true }] : []),
  { id: 'd', when: { stat: 'd', atLeast: 1 } },
];
const make = extra => { const p = createProgress({ goals: goals(extra), count: false }); p.module.setup(fake); return p; };

// a game played with the old list: a, b and c met, on d
const old = make(false);
for (const s of ['a', 'b', 'c']) old.set(s, 1);
old.check();
check('old list: on goal', old.goal().id, 'd');
const saved = JSON.parse(JSON.stringify(old.save()));

// loaded with the new list: a, b, c still met; the first one not met is new1
const now = make(true);
now.module.load(saved);
check('new list, new save: on goal', now.goal().id, 'new1');

// the same game as a save from before 0.3.1: only a count of 3
const legacy = JSON.parse(JSON.stringify(saved));
delete legacy.run.goals; legacy.run.goal = 3;
const fromLegacy = make(true);
fromLegacy.module.load(legacy);
check('new list, old-style save: on goal', fromLegacy.goal().id, 'new1');
check('old-style save: b counted as met', fromLegacy.goal().n, 2);

// meeting new1 moves on past the met ones to new2, without emitting the old ones again
const seen = [];
fromLegacy.onEvent = (k, g) => { if (k === 'goal') seen.push(g.id); };
fromLegacy.set('n1', 1); fromLegacy.check();
check('after new1: on goal', fromLegacy.goal().id, 'new2');
check('goals announced', seen.join(','), 'new1');

console.log(failed ? `${failed} FAILED` : 'PASS');
process.exit(failed ? 1 : 0);
