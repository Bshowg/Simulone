"""Pack the drawn art (art/out/) into one sprite sheet for The Lord's Will.

    python tools/pack-art.py

Reads   art/out/buildings/<item>_r0..3.png   one building in its four rotations (item: the name, spaces as underscores)
        art/out/people/people.png            the figure sheet (cells 13 x 24: 24 rows, 12 columns)
        art/out/nature/tree_<season>_<k>.png trees
        art/out/ground/<key>.png             ground textures that repeat
Writes  games/lords-will/art.png             the sheet
        games/lords-will/art-atlas.js        where everything is on it

Whatever is missing is left out, so the game can be tried while art is still being drawn. A closed (or burnt out)
version of every building is made here: the same drawing, faded towards the paper.
"""
import io
import json
import pathlib
import re
from PIL import Image

root = pathlib.Path(__file__).resolve().parent.parent
src = root / 'art' / 'out'
dst = root / 'games' / 'lords-will'
PAPER = (234, 223, 198)
INK = (74, 56, 44)
SEASONS = ['spring', 'summer', 'autumn', 'winter']
TILE_W, TILE_H = 32, 16
CELL_W, CELL_H = 13, 24


def hard(im):
    """Sprites are hard-edged: alpha is all or nothing."""
    im = im.convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    return im


def faded(im, t=0.32):
    out = im.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a:
                grey = (r * 3 + g * 4 + b) // 8
                px[x, y] = tuple(round((c * 0.55 + grey * 0.45) * (1 - t) + p * t) for c, p in zip((r, g, b), PAPER)) + (255,)
    return out


LIGHTS = {(242, 217, 160), (238, 168, 94), (247, 221, 140), (210, 114, 90)}   # lit window, flame, its core, embers


def lit(im):
    """Mark the lights: alpha 200 tells the engine to draw them at full colour whatever the hour."""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) in LIGHTS:
                px[x, y] = (r, g, b, 200)
    return im


items = []                                   # (key, image)
buildings = {}
for f in sorted((src / 'buildings').glob('*_r0.png')):
    item = f.name[:-len('_r0.png')]
    if item.endswith('_night') or re.search(r'_fire\d$', item):
        continue                             # other states of a building, picked up with it below
    rots = [src / 'buildings' / f'{item}_r{r}.png' for r in range(4)]
    if not all(p.exists() for p in rots):
        print('skipped', item, '(not all four rotations)')
        continue
    ims = [hard(Image.open(p)) for p in rots]
    if len({im.size for im in ims}) != 1:
        print('skipped', item, '(rotations differ in size)')
        continue
    name = item.replace('_', ' ')
    buildings[name] = {'w': ims[0].width, 'h': ims[0].height}
    for r, im in enumerate(ims):
        items.append((('b', name, 'open', r), im))
        items.append((('b', name, 'closed', r), faded(im)))
        night = src / 'buildings' / f'{item}_night_r{r}.png'
        if night.exists():
            items.append((('b', name, 'night', r), lit(hard(Image.open(night)))))
        for k in range(3):
            fire = src / 'buildings' / f'{item}_fire{k}_r{r}.png'
            if fire.exists():
                items.append((('b', name, f'fire{k}', r), lit(hard(Image.open(fire)))))

people = src / 'people' / 'people.png'
if people.exists():
    im = hard(Image.open(people))
    assert im.width % CELL_W == 0 and im.height % CELL_H == 0, f'people.png is {im.size}, not a grid of {CELL_W} x {CELL_H} cells'
    items.append((('people',), im))

trees = {}
for s in SEASONS:
    for f in sorted((src / 'nature').glob(f'tree_{s}_*.png')):
        items.append((('tree', s, int(re.search(r'_(\d+)\.png$', f.name).group(1))), hard(Image.open(f))))

for f in sorted((src / 'ground').glob('*.png')):
    if f.name.startswith('preview'):
        continue
    im = Image.open(f).convert('RGBA')
    im.putalpha(255)
    items.append((('ground', f.stem), im))

# small icons for the page (resources and the like)
for f in sorted((src / 'icons').glob('*.png')):
    if not f.name.startswith('preview'):
        items.append((('icon', f.stem), hard(Image.open(f))))

# pictures for the build menu: each building as first seen (rotation 0), reduced to fit a small box. These are shown
# by the page, not drawn as sprites, so they may be smooth.
THUMB = (60, 46)
for name in list(buildings):
    im = Image.open(src / 'buildings' / f'{name.replace(" ", "_")}_r0.png').convert('RGBA')
    im = im.crop(im.getbbox())
    k = min(1, THUMB[0] / im.width, THUMB[1] / im.height)
    if k < 1:
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    items.append((('thumb', name), im))
for key, tex in (('road', 'road'), ('field', 'field_ripe'), ('garden', 'garden')):
    f = src / 'ground' / f'{tex}.png'
    if f.exists():                                             # a cell of that ground, as a diamond
        t = Image.open(f).convert('RGBA').crop((0, 0, 48, 24))
        for y in range(24):
            for x in range(48):
                if abs(x + 0.5 - 24) / 24 + abs(y + 0.5 - 12) / 12 > 1:
                    t.putpixel((x, y), (0, 0, 0, 0))
        items.append((('thumb', key), t))

# the build-preview marker: one cell, every other pixel inked (sprites have no partial transparency)
marker = Image.new('RGBA', (TILE_W, TILE_H), (0, 0, 0, 0))
for y in range(TILE_H):
    for x in range(TILE_W):
        if (x + y) % 2 == 0 and abs(x + 0.5 - TILE_W / 2) / (TILE_W / 2) + abs(y + 0.5 - TILE_H / 2) / (TILE_H / 2) <= 1:
            marker.putpixel((x, y), INK + (255,))
items.append((('marker',), marker))
bad = Image.new('RGBA', (TILE_W, TILE_H), (0, 0, 0, 0))        # the same in red: "not here"
for y in range(TILE_H):
    for x in range(TILE_W):
        if (x + y) % 2 == 0 and abs(x + 0.5 - TILE_W / 2) / (TILE_W / 2) + abs(y + 0.5 - TILE_H / 2) / (TILE_H / 2) <= 1:
            bad.putpixel((x, y), (164, 70, 58, 255))
items.append((('markerBad',), bad))

# shelf packing, tallest first
WIDTH = 4096
order = sorted(range(len(items)), key=lambda i: -items[i][1].height)
x = y = shelf = 0
place = {}
for i in order:
    im = items[i][1]
    if x + im.width > WIDTH:
        x = 0; y += shelf + 1; shelf = 0
    place[i] = (x, y)
    x += im.width + 1
    shelf = max(shelf, im.height)
height = y + shelf
sheet = Image.new('RGBA', (WIDTH, height), (0, 0, 0, 0))
atlas = {'size': [WIDTH, height], 'buildings': {}, 'people': None, 'trees': {}, 'ground': {}, 'icons': {}, 'thumbs': {}, 'marker': None}
for i, (key, im) in enumerate(items):
    px, py = place[i]
    sheet.paste(im, (px, py))
    if key[0] == 'b':
        b = atlas['buildings'].setdefault(key[1], {**buildings[key[1]], 'open': [None] * 4, 'closed': [None] * 4})
        b.setdefault(key[2], [None] * 4)[key[3]] = [px, py]
    elif key[0] == 'people':
        atlas['people'] = {'x': px, 'y': py, 'cw': CELL_W, 'ch': CELL_H, 'cols': im.width // CELL_W, 'rows': im.height // CELL_H}
    elif key[0] == 'tree':
        atlas['trees'].setdefault(key[1], []).append({'x': px, 'y': py, 'w': im.width, 'h': im.height})
    elif key[0] == 'icon':
        atlas['icons'][key[1]] = {'x': px, 'y': py, 'w': im.width, 'h': im.height}
    elif key[0] == 'thumb':
        atlas['thumbs'][key[1]] = {'x': px, 'y': py, 'w': im.width, 'h': im.height}
    elif key[0] == 'ground':
        atlas['ground'][key[1]] = {'x': px, 'y': py, 'w': im.width, 'h': im.height}
    else:
        atlas[key[0]] = {'x': px, 'y': py, 'w': im.width, 'h': im.height}

sheet.save(dst / 'art.png', optimize=True)
text = ('// Written by tools/pack-art.py: where each drawing is on art.png. Do not edit by hand.\n'
        'export const ATLAS = ' + json.dumps(atlas, indent=1) + ';\n')
io.open(dst / 'art-atlas.js', 'w', encoding='utf-8', newline='\n').write(text)
print(f'art.png {WIDTH}x{height}: {len(atlas["buildings"])} buildings, people {"yes" if atlas["people"] else "no"}, '
      f'trees {sum(len(v) for v in atlas["trees"].values())}, ground {len(atlas["ground"])}')
