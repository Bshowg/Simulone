# Working on Simulone (for Claude Code)

Simulone is a set of phone web games on one generic engine of the same name. Read `README.md` for the layout and the commands,
`CONTRIBUTING.md` for how the team works, and the README in each folder you touch (`engine/`, `kit/`, `modules/`,
`games/<game>/modules/`, `tools/tests/`, `art/*/STYLE.md`). Several people work here, each with their own Claude
sessions: these rules are what keeps the code coherent between them.

## The rules

1. **The engine stays generic.** `engine/` holds only mechanisms any game could use. A game's mechanics, numbers,
   pacing and tuning that encodes game feel live in that game's own files (its data file such as `hamlet.js`, `mall.js`,
   `nest.js`, `war.js`, and its `rules.js`). When a feature needs the engine, put in only the general part (a hook, a
   per-person column, an option with a neutral default) and say so before building it.
2. **Modules are generic**: the game passes its numbers in. A module lives in `games/<game>/modules/` while one game uses
   it, and moves to `modules/` when a second game needs it.
3. **A new game has its own gameplay.** Design what the subject calls for first; do not carry over another game's
   structure or modules by default. Reuse a module only where it truly fits. Games are original: never recreate an
   existing commercial game, its names, art or levels.
4. **Shared code is versioned.** `engine/`, `kit/` and `modules/` each carry a `version` in their `package.json`: raise the
   middle number for an addition, the first for a change a game must follow, the last for a fix. Write `package.json`
   files without a byte-order mark (PowerShell's `Set-Content -Encoding utf8` adds one and breaks every build).
5. **Test before and after any shared change**: `python tools/test-all.py` builds every game and runs every headless
   test. A new game adds its own scripted test there (see `tools/tests/README.md`).
6. **Saves.** Raise a game's save version when a change makes old saves unreadable; its `showcase.txt` (a save code
   loaded by the menu's Showcase button) then has to be made again. A page must not save while `slots.leaving` is true.
7. **Phone first.** The games are played on Android phones. Check a change in the browser preview at phone width
   (launch configuration `game-b`, `.claude/launch.json`) before calling it done, and say what was not checked.
8. **Art is drawn by scripts** in Aseprite batch mode (`art/`, `art/colony/`, `art/war/`), each with its `STYLE.md`. Change
   the script and run it again; never edit a packed sheet by hand.
9. **Plain words.** Comments, docs and messages in clear, plain English. Say what was and was not tested.
10. **Privacy.** No personal names, emails, user folders or keys in files: write paths relative to the project folder.

## Working with others

- Work on a branch, one change per branch, and leave `main` working.
- Before changing a game someone else owns (see `CONTRIBUTING.md`), say so in the pull request.
- Do not publish to anyone's claude.ai artifact unless its owner asks: publishing the Simulone menu is the owner's job.
- `dist/` is build output and is not in git; build it again rather than editing it.
