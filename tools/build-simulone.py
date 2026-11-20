"""Build Simulone: every game together behind one menu page, ready to publish as one artifact.

    python tools/build-simulone.py

Builds each game with tools/build-artifact.py, then lays out dist/simulone/:

    index.html               the menu (from simulone/index.html), with each game's build line filled in
    previews/                the menu's pictures (from simulone/previews/)
    <game>/index.html        the game's page as a full document, with a 'menu' button that comes back here
    <game>/...               everything that game needs, exactly as its own build has it (its own copy of the shared code)

and dist/simulone.html (the menu as published) and dist/simulone/manifest.json ("publish" is the files map).
Each game keeps the shared code it was built with, so the games inside Simulone can be at different versions.
"""
import datetime
import io
import json
import pathlib
import shutil
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parent.parent
GAMES = ['lords-will', 'mall', 'ant-colony', 'war']
HEADER = '<!doctype html>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n'
# Run before the game's own script: the kit then shows a 'menu' button that leads back to the page that opened the game.
EXIT = ("<script>try { globalThis.KIT_EXIT = { href: sessionStorage.getItem('simulone-home') || '../index.html', label: 'menu' }; }"
        " catch (e) { globalThis.KIT_EXIT = { href: '../index.html', label: 'menu' }; }</script>\n")

out = root / 'dist' / 'simulone'
if out.exists():
    shutil.rmtree(out)
out.mkdir(parents=True)
files, lines = {}, {}
for g in GAMES:
    r = subprocess.run([sys.executable, str(root / 'tools' / 'build-artifact.py'), g], capture_output=True, text=True, encoding='utf-8', errors='replace')
    if r.returncode != 0:
        sys.exit(f'{g} did not build:\n{r.stdout}{r.stderr}')
    built = root / 'dist' / g
    manifest = json.loads(io.open(built / 'manifest.json', encoding='utf-8').read())
    for pub in manifest['files']:
        (out / g / pub).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(built / pub, out / g / pub)
        files[f'{g}/{pub}'] = out / g / pub
    page = io.open(built / 'index.html', encoding='utf-8').read()
    assert page.startswith(HEADER), f'{g}: unexpected page header'
    page = HEADER.replace('initial-scale=1', 'initial-scale=1, viewport-fit=cover') + EXIT + page[len(HEADER):]
    io.open(out / g / 'index.html', 'w', encoding='utf-8', newline='\n').write(page)
    files[f'{g}/index.html'] = out / g / 'index.html'
    s = manifest['shared']
    lines[g] = f"engine {s['engine']} · kit {s['kit']} · modules {s['modules']}"
    print(f'  {g}: {len(manifest["files"]) + 1} files · {lines[g]}')

for f in sorted((root / 'simulone' / 'previews').glob('*')):
    (out / 'previews').mkdir(exist_ok=True)
    shutil.copyfile(f, out / 'previews' / f.name)
    files[f'previews/{f.name}'] = out / 'previews' / f.name

versions = {p: json.loads(io.open(root / p / 'package.json', encoding='utf-8').read()).get('version', '?') for p in ('engine', 'kit', 'modules')}
menu = io.open(root / 'simulone' / 'index.html', encoding='utf-8').read()
for k, v in {**lines, **versions, 'date': datetime.date.today().isoformat()}.items():
    menu = menu.replace('{{' + k + '}}', v)
assert '{{' not in menu, 'a placeholder in simulone/index.html was not filled'
assert menu.startswith(HEADER)
io.open(out / 'index.html', 'w', encoding='utf-8', newline='\n').write(menu)
# the menu's other pages (what Simulone can do…): published beside it as whole documents, placeholders filled the same way
for f in sorted((root / 'simulone').glob('*.html')):
    if f.name == 'index.html':
        continue
    page = io.open(f, encoding='utf-8').read()
    for k, v in {**lines, **versions, 'date': datetime.date.today().isoformat()}.items():
        page = page.replace('{{' + k + '}}', v)
    assert '{{' not in page, f'a placeholder in simulone/{f.name} was not filled'
    io.open(out / f.name, 'w', encoding='utf-8', newline='\n').write(page)
    files[f.name] = out / f.name
io.open(root / 'dist' / 'simulone.html', 'w', encoding='utf-8', newline='\n').write(menu[len(HEADER):])
manifest = {'name': 'simulone', 'built': datetime.datetime.now().isoformat(timespec='seconds'), 'games': lines, 'shared': versions,
            'page': 'dist/simulone.html', 'publish': {p: f.relative_to(root).as_posix() for p, f in sorted(files.items())}}
io.open(out / 'manifest.json', 'w', encoding='utf-8', newline='\n').write(json.dumps(manifest, indent=1) + '\n')
print(f'built simulone: {len(files)} files · open http://localhost:8765/dist/simulone/index.html')
