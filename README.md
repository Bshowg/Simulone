# Simulone

Phone games built on one engine, **Simulone**: many simple people (or ants, or soldiers) who look after their own needs,
and a player who shapes the place they live in. Four games so far: **The Lord's Will** (a medieval settlement),
**Atrium** (a shopping mall), **The Colony** (an ant nest) and **WAR** (a campaign and its battles).

## Getting started

You need Python 3 and Node.js (Node is used by the tests and to check that every page's scripts parse). Aseprite is only
needed to redraw the art; the drawn sheets are kept in the repository.

```bash
python tools/serve.py              # local server on http://localhost:8765, with caching off
python tools/build-simulone.py     # build every game behind one menu: open http://localhost:8765/dist/simulone/index.html
python tools/test-all.py           # build every game and run all the headless tests
```

`dist/` is build output and is not kept in the repository: build it again with the commands above.

Working with others: read [CONTRIBUTING.md](CONTRIBUTING.md) (branches, tests, who looks after which game). The same
rules for Claude Code are in [CLAUDE.md](CLAUDE.md), which every Claude session in this folder reads.

## How the project is laid out

| Folder | What it is | Shared? |
|---|---|---|
| `engine/` | the grid, the people and their decisions, drawing, touch input | by every game, versioned |
| `kit/` | the screen every game is laid out on: top strip, sheets, tray, cards | by every game, versioned |
| `modules/` | generic game modules **used by more than one game**: progress, save, saved-game slots, calendar, economy, events, policies, lives, mapgen, loader | versioned |
| `games/<game>/` | one game (`lords-will`, `mall`, `ant-colony`, `war`): its page, its numbers, its rules, its art, its showcase save | no |
| `games/<game>/modules/` | generic modules **only this game uses** so far | no, until a second game needs one |
| `simulone/` | the menu page that puts the games together, and its preview pictures | — |
| `examples/` | small demos and stress tests of the engine | no |
| `art/` | the Aseprite scripts that draw the art: The Lord's Will at the top, `art/colony/` and `art/war/` for theirs. Each has a `STYLE.md`; `out/` folders hold the drawn pieces the sheets are packed from | no |
| `tools/` | build, test, art packing, local server | — |
| `docs/` | the design documents of each game | — |
| `index.html` | the first prototype of the engine, kept for reference | — |

### The rules

1. **The engine stays generic.** No game's mechanics or pacing go into `engine/`.
2. **Modules are written generically** (the game passes its numbers in), wherever they live.
3. **A module lives with its game until a second game needs it.** Then it moves from `games/<game>/modules/` to
   `modules/`, and every game that uses it is tested before the change goes out.
4. **Shared code carries a version** (`version` in `engine/package.json`, `kit/package.json`, `modules/package.json`).
   Raise the middle number when something is added, the first when a game would have to change to keep working, the
   last for a fix. Every build records which versions it was made from.

## Building and shipping a game

Each game builds into a folder of its own that holds everything it needs and nothing else, so each can ship
separately:

```bash
python tools/build-artifact.py lords-will
```

This follows the page's imports and writes `dist/lords-will/` (the game's own files, plus the shared files it uses
under `shared/`), `dist/lords-will.html` (the page to publish) and `dist/lords-will/manifest.json` (every file, where it
came from, the shared versions, and the `files` map for publishing). Open `http://localhost:8765/dist/lords-will/index.html`
to try the built game exactly as it will be published (`python tools/serve.py` starts the local server).

## Before changing shared code

```bash
python tools/test-all.py
```

builds every game and runs its headless tests side by side (about half a minute). See `tools/tests/README.md`.

## Simulone: all the games behind one menu

```bash
python tools/build-simulone.py
```

builds every game and lays them out in `dist/simulone/` behind a menu page (source: `simulone/index.html`, pictures in
`simulone/previews/`). Each game keeps its own copy of the shared code it was built with. Opened from the menu, a game
shows a **menu** button at the top (the kit adds it when the page sets `globalThis.KIT_EXIT`); the game saves, then goes
back. Publish `dist/simulone.html` with the `publish` map in `dist/simulone/manifest.json`.
