# The Colony: art style and sprite contract

The look chosen by the owner after two rounds of proposals. Read this before drawing anything.

## The look in one paragraph

An ant nest cut through and seen from the side, in **low resolution, drawn as true to life as the pixels allow**. Real soil colours and textures, real light (daylight from the upper left on the surface; tunnels in shade), real ants. No outlines, no cartoon shapes, no flat fills, no dithering patterns that read as pattern, no invented colours. Nothing is borrowed from the project's other game (no paper, no ink line).

Approved pictures, to match:

- Ground: `art/reference/colony-ground.png` (style 1 of the second round of proposals, at 12 pixels a cell).
- Ants: row **A** of `art/reference/colony-ants.png`: the garden ant, seen from the side, near-black with one touch of light on the abdomen.

Look at both pictures first. The two scripts are the reference for how each thing was drawn; reuse their approach.

## Scale

- **One map cell is 12 × 12 pixels.** Everything is drawn at 1× and never scaled when saved.
- A worker ant is about 11 pixels long and 6 high, legs included.
- A tunnel is one cell wide: an ant fits in it with room to spare.

## Palette

The colours are in `art/colony/lib/px.lua` as `px.PAL`. Use them. A new colour is allowed only where a real thing needs it (a seed is not a crumb), and it must be as muted as the rest: nothing more saturated than the grass.

| Thing | Ramp, dark to light |
|---|---|
| Sky | `#86b2d6 #9cc2de #b4d2e4 #cfe2e8` |
| Topsoil (humus) | `#33241a #3d2b1e #463222` |
| Loam | `#5e4029 #69482e #735034 #7e593a` |
| Sand | `#a98852 #b4935c #c0a068 #ccad76` |
| Clay | `#6d5448 #775c4e #836656`, grey seams `#7b7d84` |
| Stone | `#4e4a46 #6a655f #888279 #a8a298` |
| Grass | `#35602a #467a33 #5f953c #7fae4a` |
| Roots | `#8a7150 #bca27c` |
| Water | `#1f3a4a #2c5468`, light on its surface `#7aa8b8` |
| Crumbs | `#a87c2e #c8a04a #e6c46a` |
| Brood | egg `#f4f0e4`, larva `#d8c49c #e8d8b4`, pupa `#a8875a #c2a070` |
| Fungus | `#bdbab0 #d8d6cc #f0eee6`, leaf bits `#6f8a4a` |
| Ant | body `#140a07`, legs and feelers `#2a160e`, the light on the abdomen `#6a4430` |

## Light

- On the surface, light comes from the **upper left**. Round things (pebbles, seeds, the abdomen of an ant) are lighter at the upper left and darker at the lower right.
- Underground there is no direct light. Things in tunnels are seen against the tunnel's back wall, which the game draws as the earth behind it at 66% brightness. **Everything that lies or walks in a tunnel must read against that dark wall**: test against it (the contact sheet does this for you).
- No cast shadows, no glows, no gradients wider than the thing itself.

## How a thing is drawn

- Pixel by pixel, at 1×, with hard pixels. No anti-aliasing, no blur, no partial transparency: a pixel is either fully opaque or fully transparent.
- Texture comes from grain (single pixels of a neighbouring tone of the same ramp) at two sizes, not from regular patterns.
- Edges of natural things are irregular. Nothing natural has a straight edge longer than three pixels.
- Sprites have a transparent background and no outline.

## Files and how to work

- Write one Lua script per group in `art/colony/` (`ground.lua`, `ants.lua`, `things.lua`). It loads the shared library and saves PNGs into `art/colony/out/<group>/`:

  ```lua
  local px = dofile(app.params.root .. '/art/colony/lib/px.lua')
  local img = px.image(12, 12)
  -- draw with px.put, px.fill, px.sprite …
  px.save(img, 'art/colony/out/things/crumbs_3.png')
  ```

- Run it in Aseprite's batch mode from the project folder:

  ```bash
  "/c/Program Files/Aseprite/Aseprite.exe" -b --script-param root="$(pwd -W)" --script art/colony/<group>.lua
  ```

- **Look at what you drew.** End the script by saving a contact sheet with `px.sheet(...)` to `art/colony/shots/<group>.png`, open it with the Read tool, judge it against the approved pictures, and redraw what is wrong. Do this at least twice. Art that has not been looked at is not done.
- Do not touch any file outside `art/colony/`. Do not edit `lib/px.lua`: if you need a helper, write it in your own script.
- File names and sizes below are a contract with the game's code: keep them exactly.

## The contract

### Ground (`out/ground/`)

| File | Size | What |
|---|---|---|
| `loam.png`, `humus.png`, `sand.png`, `clay.png`, `plug.png` | 48 × 48 | Textures that tile without a seam in both directions (use `px.hashp` and `px.smooth` with `w, h = 48, 48`). `plug` is soil packed into a tunnel by the ants: loam, a little lighter and more even. |
| `mound.png` | 48 × 48 | Dried soil thrown out on the surface: loam at about 125% brightness, crumbly. Tiles. |
| `stone_1.png` … `stone_6.png` | 12 × 12 | Pebbles on a transparent background, to be drawn over loam: one large, or two or three small, different in each. Lit from the upper left. |
| `sky_day.png`, `sky_dusk.png`, `sky_night.png`, `sky_rain.png`, `sky_heat.png` | 12 × 96 | The sky from the top of the map down to the ground: a vertical strip that tiles sideways. Night has a few stars (so make it 48 × 96 for that one only). |
| `grass_1.png` … `grass_6.png` | 12 × 12 | Blades of grass rooted on the bottom edge, transparent elsewhere. Uneven heights, lighter at the tips. |
| `root_1.png` … `root_4.png` | 12 × 36 | A root hanging down from the top edge, wandering, thinner towards its end. Transparent elsewhere. |
| `water.png` | 12 × 12 | Standing water in a tunnel, opaque: dark, slightly uneven. Tiles. |
| `water_top_1.png` … `water_top_4.png` | 12 × 12 | The top cell of standing water, four frames of a slow ripple: the light on the surface in the top two rows, water below. Opaque. |

### Ants (`out/ants/`)

One PNG per kind: a row of frames, each frame the same size, the ant **facing right, its feet on the bottom row of the frame, centred left to right**. The game mirrors it to face left and turns it to climb.

Frames, in this order: `walk 1, walk 2, walk 3, walk 4, work 1, work 2, still`. Walking is the legs alternating in threes, as an ant's do. Working is the head dipping to bite or to tend (two frames). Still is standing, feelers raised.

| File | Frame | What |
|---|---|---|
| `young.png` | 24 × 12 | A newly hatched worker: the same ant, slightly smaller and paler brown (callow), but still clearly readable on the dark wall. |
| `grown.png` | 24 × 12 | The worker of row A. |
| `old.png` | 24 × 12 | The same, the darkest, abdomen a little larger and duller. |
| `major.png` | 24 × 12 | A soldier: about a third larger, with a head as big as its abdomen and heavy jaws. |
| `raider.png` | 24 × 12 | A worker of a rival species: yellow-brown (`#7a5a14` body, `#d8b450` light), the same build. Must be told from the colony's ants at a glance. |
| `queen.png` | 36 × 16 | About twice a worker's length, a long heavy abdomen, a broad thorax. |
| `princess.png` | 36 × 16 | A young queen: between worker and queen in size, with two pairs of clear wings folded along her back. |
| `rival_queen.png` | 36 × 16 | The queen of the rival species, in its colours. |

### Things (`out/things/`)

| File | Size | What |
|---|---|---|
| `crumbs_1.png` … `crumbs_8.png` | 12 × 12 | A food store cell holding 1 to 8 crumbs: irregular golden-brown bits lying on the floor (the bottom edge), heaping up as there are more. Transparent elsewhere. |
| `find_1.png` … `find_4.png` | 12 × 12 | Food lying on the surface, from a few crumbs to a heap that fills most of the cell. |
| `soil_1.png` … `soil_4.png` | 12 × 12 | Loose soil dropped in a tunnel, from one load to a small heap. |
| `eggs_1.png` … `eggs_3.png` | 4 × 12 | One to three eggs lying on the floor of the left third of a brood cell: tiny, white, oval. |
| `larvae_1.png` … `larvae_3.png` | 4 × 12 | One to three larvae: cream, curved grubs, larger than eggs. |
| `pupae_1.png` … `pupae_3.png` | 4 × 12 | One to three pupae: tan cocoons, the largest of the three. |
| `fungus_0.png` … `fungus_3.png` | 12 × 12 | A garden cell: a bare bed of chewed leaf, then pale threads, then a full pale growth, then ripe (with the knobs the ants harvest). On the floor, transparent above. |
| `carry_crumb.png`, `carry_soil.png`, `carry_egg.png`, `carry_larva.png`, `carry_pupa.png` | 4 × 4 | What an ant holds in its jaws. |
| `mark.png` | 12 × 12 | Earth marked to be dug: a broken pale line just inside the cell's edge, transparent in the middle. |
| `rain_1.png`, `rain_2.png` | 12 × 24 | Falling rain: a few short slanted streaks, transparent elsewhere; two frames. |

## Ants from above

Each kind also has `ants/<kind>_top.png`: a row of 5 frames (walk 1-4, still), the ant seen from above, facing right and centred in its frame (workers 24 x 15, queens 36 x 23). The game uses it for an ant crossing the back wall of a tunnel and turns it to its heading. Drawn by `ants.lua` with the same palettes as the side view.
