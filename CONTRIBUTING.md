# Contributing to Simulone

Thanks for helping. Simulone is a set of phone web games built on one engine of the same name. This page is how we work together
so that four games, a shared engine and several people (and their Claude sessions) don't step on each other.
`README.md` has the layout and the commands; `CLAUDE.md` holds the same rules for Claude Code.

## Setting up

- **Python 3** and **Node.js** are needed. **Aseprite** only if you redraw art.
- `python tools/serve.py` starts a local server on http://localhost:8765 with caching off.
- `python tools/build-simulone.py` builds every game behind the menu: open http://localhost:8765/dist/simulone/index.html.
- `python tools/test-all.py` builds every game and runs every headless test (about a minute).
- Try what you change on a phone if you can: the games are made for Android phones first. On the same Wi-Fi, the local
  server can be opened from a phone at your computer's address.

## How we work

1. **One branch per change**, named for what it does (`war-cavalry-charge`, `engine-door-linger`). Keep `main` working.
2. **Open a pull request** and say in it: what changed, how you tested it, and what you did not test.
3. **Run `python tools/test-all.py`** before asking for a review. Every test must pass.
4. **Small pull requests** are easier to review than big ones. A new game can land in steps.

### Who looks after what

Each game has an owner who reviews changes to its rules and balance. Changing someone else's game is welcome: say so in
the pull request and let them review it. Changes to shared code are reviewed by whoever owns the project.

| Area | Owner |
|---|---|
| `engine/`, `kit/`, `modules/`, `tools/`, `simulone/` | the project owner |
| `games/lords-will` (The Lord's Will) | _to fill in_ |
| `games/mall` (Atrium) | _to fill in_ |
| `games/ant-colony` (The Colony) | _to fill in_ |
| `games/war` (WAR) | _to fill in_ |

## The rules of the code

- **The engine stays generic.** Nothing about one game's mechanics, numbers or pacing goes into `engine/`. If your
  feature needs the engine, add only the part any game could use (a hook, a per-person column, an option that is off
  by default), and say why in the pull request.
- **Modules are generic** and take their numbers from the game. A module lives in `games/<game>/modules/` while only that
  game uses it, and moves to `modules/` when a second game needs it.
- **Shared code is versioned.** If you change `engine/`, `kit/` or `modules/`, raise the `version` in its `package.json`:
  the middle number for something added, the first for a change games must follow, the last for a fix. Save
  `package.json` without a byte-order mark.
- **Saves.** If your change makes old saves unreadable, raise the game's save version and make its `showcase.txt` again
  (the game's README or its tools say how).
- **New games have their own gameplay**, not another game reskinned, and add a scripted test to `tools/tests/` and
  `tools/test-all.py`. Games are original: no recreations of existing games, their names, art or levels.
- **Art is drawn by scripts** in Aseprite (`art/STYLE.md`, `art/colony/STYLE.md`, `art/war/STYLE.md`). Change the script
  and run it again; don't paint over a packed sheet, or the next run will undo your work.
- **Plain words** in comments and docs.
- **No personal data** in files: no names, emails, home-folder paths or keys. Write paths relative to the project folder.

## Publishing

`dist/` is build output and is not in git. Publishing is the project owner's: send your change as a pull request, and
the owner publishes it.

**On the website** (gianmarcobiscini.it/static/simulone/): publishing a **release** on GitHub does it. The workflow
`.github/workflows/publish-website.yml` tests every game, builds Simulone and copies the build into the website's
repository at `static/simulone/`; the website's own deploy then uploads it. A failed test stops it before anything is
copied. It can also be run by hand from the Actions tab.

It needs one repository secret, `GB_WEBSITE_TOKEN`: a fine-grained personal access token of the website's owner, for
the `gb-website` repository only, with **Contents: read and write** and nothing else, and an expiry date. Anyone with
write access here can run workflows that use it, so keep it that narrow, and replace it when it expires.
