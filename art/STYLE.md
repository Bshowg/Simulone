# The Lord's Will: art style sheet

The game is a medieval settlement builder seen in isometric view, growing from a hamlet to a chartered town.
All art is drawn by Lua scripts run in Aseprite batch mode, using the shared library `art/lib/ink.lua`.

## The look

**A pen-and-wash drawing on paper.** Brown ink line, with thin, realistic pastel washes: each thing has the colour it
really has, thinned with water. Nothing is saturated and nothing is black.

- Reference image (approved by the owner): `art/proposals/round7/pastel-full-fixed.png`. Reference buildings drawn with
  the library: `art/buildings/hut.lua`, `art/buildings/well.lua` (previews in `art/out/preview/`).
- **Line:** every separate part gets a brown ink outline (the library does this). Detail inside a surface is drawn with
  short pen strokes and small patterns (courses of stone, strokes of thatch, boards), never with gradients.
- **Light** comes from the left. Faces turned to the lower left of the screen are lit, faces turned to the lower right
  are in shade. The library picks the lit or shaded version of a material for you.
- **Palette:** only the colours in `ink.P`. If you truly need another, define it at the top of your own script as a
  soft pastel in the same family, and say so in your report. No pure white, no pure black, no saturated colour.
- **Period:** England or northern France, about 1100 to 1350. Thatch, wattle and daub, rubble stone, timber framing,
  wooden shingles; clay tile and slate only on rich buildings. No glass except in churches and the guildhall. No
  chimneys of brick; a smoke hole or a small stone or wattle chimney. Nothing later than the period.
- **People** (for scale and for the figure sheet): a small head, a block of a body, legs and arms one pixel wide.
  Plain clothes with a belt: undyed wool and linen, or soft plant dyes (madder red, woad blue, weld yellow, green,
  russet). Women wear a long dress and a linen veil. **Never stripes or patterns on clothes.**

## Scale

- One ground cell is a diamond 32 pixels wide and 16 high. One cell of height is 16 pixels.
- An adult is 9 pixels wide and 22 high. A door is about 12 pixels high and 0.5 cell wide. A hut's walls are 19 high.
- Sprites are hard-edged: every pixel is either fully opaque or fully transparent. No partial transparency, no
  anti-aliasing.

## Tools

Aseprite is at `C:\Program Files\Aseprite\Aseprite.exe`. Run scripts from Git Bash, in the project folder, like this (forward slashes; `$(pwd -W)` is that folder's Windows path):

```bash
"/c/Program Files/Aseprite/Aseprite.exe" -b --script-param root="$(pwd -W)/art" --script-param item=hut --script "$(pwd -W)/art/run.lua"
```

A Lua error is printed to the console and no file is written, so always read the output. After every run, **look at
the preview PNG with the Read tool** and fix what is wrong before going on. Looking is the only test there is.

Read `art/lib/ink.lua` before you start: its comments are the manual. Do not edit it, `art/run.lua`, or anybody
else's files; other agents are using them at the same moment. If the library lacks something, write the helper in
your own script (the raw calls `c:part`, `c:poly3`, `c:line3`, `c:post`, `c:dot3` and `ink.sprite` let you draw
anything).

## Buildings

One file per building: `art/buildings/<item>.lua` (item = the name with spaces as underscores). It returns
`function(ink) return { name, w, h, height, draw = function(c) ... end } end`, exactly like `hut.lua`.
`art/run.lua` draws it in the four rotations and writes `art/out/buildings/<item>_r0.png` to `_r3.png` plus the
preview `art/out/preview/<item>.png` (rotations 0, 1, 2, 3 from left to right).

Rules the game depends on:

1. **Describe the building once, in model space; never branch on the rotation to redraw it.** The library turns it.
   Use `c:visible(side)` only for small things that must face the camera.
2. **The footprint is `w` by `h` cells as given in your list. Nothing may reach outside it**: the image is exactly
   `(w + h) * 16` pixels wide and anything further out is cut off. Set walls in by about 0.1 cell so eaves can overhang.
3. **`height`** is the room above the ground in pixels, the same for all four rotations. Make it just enough for the
   tallest point plus 2.
4. **The entrance is on the S side**, centred on the cell at x = floor(w / 2) (so its centre is at
   x = floor(w / 2) + 0.5: u = that / w along the S wall). People walk in and out there. Put the main door there.
5. Draw **all four sides**: every rotation shows two of them, and a blank wall looks unfinished. Windows are small.
6. Parts are sorted back to front by their bounding boxes, so give each `box`, roof and `part` honest bounds, and do
   not let two parts interpenetrate.
7. The building must read at a glance and differ from the others by **silhouette and roof**, not by colour alone.
   Show its trade outside: a wood pile, a water wheel, an oven dome, barrels, a sign, a bell.
8. Open yards are fine: leave ground empty (transparent) and the game's ground shows through. People are drawn by the
   game; do not draw people.

Check every preview for: the door on the S side and visible in rotations 0 and 3; roofs sitting on their walls with
no gaps and nothing floating; no part cut off at the image edge; the four rotations clearly the same building.

## Report

When you finish, reply with: the files you wrote, anything you could not get right, any colour you added, and any
rule above you had to bend. Keep it short.
