"""Pack The Colony's drawn art (art/colony/out/) into one sheet.

    python tools/pack-colony-art.py

Reads   art/colony/out/<group>/<name>.png     every PNG, whatever its size
Writes  games/ant-colony/art.png              the sheet
        games/ant-colony/art-atlas.js         where each drawing is: ATLAS['<group>/<name>'] = [x, y, w, h]

Whatever is missing is simply not in the atlas; the game draws that thing the plain way.
Pixels are made all-or-nothing: a sprite is either there or it is not.
"""
import io
import json
import pathlib
from PIL import Image

root = pathlib.Path(__file__).resolve().parent.parent
src = root / 'art' / 'colony' / 'out'
dst = root / 'games' / 'ant-colony'
WIDTH = 512

items = []
for path in sorted(src.rglob('*.png')):
    im = Image.open(path).convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    items.append((path.relative_to(src).with_suffix('').as_posix(), im))

# shelves: tallest first, left to right, a pixel of space round everything
items.sort(key=lambda it: (-it[1].height, -it[1].width, it[0]))
x = y = 1
shelf = 0
place = {}
for name, im in items:
    if x + im.width + 1 > WIDTH:
        x, y, shelf = 1, y + shelf + 1, 0
    place[name] = [x, y, im.width, im.height]
    x += im.width + 1
    shelf = max(shelf, im.height)
height = y + shelf + 1
sheet = Image.new('RGBA', (WIDTH, max(1, height)), (0, 0, 0, 0))
for name, im in items:
    sheet.paste(im, tuple(place[name][:2]))
sheet.save(dst / 'art.png')

body = ',\n'.join(f'  {json.dumps(n)}: {json.dumps(place[n])}' for n in sorted(place))
io.open(dst / 'art-atlas.js', 'w', encoding='utf-8', newline='\n').write(
    "// Written by tools/pack-colony-art.py: where each drawing is on art.png, as [x, y, w, h].\n"
    f"export const ATLAS = {{\n{body}\n}};\n")
print(f'packed {len(items)} drawings into games/ant-colony/art.png ({WIDTH} x {height})')
