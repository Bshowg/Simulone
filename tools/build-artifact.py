"""Build one game (or example) into a folder that holds everything it needs, ready to publish or ship on its own.

    python tools/build-artifact.py games/lords-will        (or: lords-will, mall, ant-colony, an example's name)

It starts from the page (<folder>/index.html), follows every import, and copies exactly the files the game uses into
dist/<name>/, rewriting each import to the file's new place:

    the game's own files            keep their paths            (hamlet.js, art.png, modules/region.js)
    the shared engine, kit, modules go under shared/            (shared/engine/index.js, shared/modules/save.js)

It writes:
    dist/<name>.html            the page as it is published (the artifact host adds the document header)
    dist/<name>/index.html      the same page with a header, to open locally: http://localhost:8765/dist/<name>/index.html
    dist/<name>/...             every file the page needs, nothing else
    dist/<name>/manifest.json   what went in: each file and where it came from, and the version of the shared code
                                (engine, kit, modules) it was built from. `publish` is the `files` map for the Artifact tool.

It refuses to build if an import points at a file that does not exist, or if a script does not parse.
"""
import datetime
import io
import json
import pathlib
import re
import shutil
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parent.parent
arg = sys.argv[1] if len(sys.argv) > 1 else 'colony'
folder = next((p for p in (root / arg, root / 'games' / arg, root / 'examples' / arg) if (p / 'index.html').exists()), None)
if not folder:
    sys.exit(f'no page found for {arg}: looked for {arg}/index.html, games/{arg}/index.html and examples/{arg}/index.html')
name = folder.name
SHARED = ('engine', 'kit', 'modules')
HEADER = '<!doctype html>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1">\n'
# from '…', import '…', import('…'): only relative specifiers (bare names would need an import map, and none are used)
IMPORT = re.compile(r"""(\b(?:from|import)\s*\(?\s*)(['"])(\.{1,2}/[^'"]+)\2""")


def published(src):
    """Where a source file goes in the built folder."""
    try:
        return src.relative_to(folder).as_posix()
    except ValueError:
        return 'shared/' + src.relative_to(root).as_posix()


def version(part):
    try:
        return json.loads(io.open(root / part / 'package.json', encoding='utf-8').read()).get('version', '?')
    except FileNotFoundError:
        return '?'


src_page = io.open(folder / 'index.html', encoding='utf-8').read()
if not src_page.startswith(HEADER):
    sys.exit(f'{folder}/index.html must start with the standard header')
body = src_page[len(HEADER):]

files = {}                                    # published path -> source path
todo = []


def rewrite(text, here_src, here_pub):
    """Point every relative import in `text` (from the file at here_src, to be published at here_pub) at its new place."""
    def fix(m):
        target = (here_src.parent / m.group(3)).resolve()
        if not target.exists():
            sys.exit(f'{here_src.relative_to(root)} imports {m.group(3)}, which does not exist')
        if root not in target.parents:
            sys.exit(f'{here_src.relative_to(root)} imports {m.group(3)}, which is outside the project')
        pub = published(target)
        if pub not in files:
            files[pub] = target; todo.append(target)
        rel = pathlib.PurePosixPath(*([".."] * (len(pathlib.PurePosixPath(here_pub).parts) - 1)), pub).as_posix()
        return f"{m.group(1)}{m.group(2)}{rel if rel.startswith('.') else './' + rel}{m.group(2)}"
    return IMPORT.sub(fix, text)


out = root / 'dist' / name
if out.exists():
    shutil.rmtree(out)
out.mkdir(parents=True)
page = rewrite(body, folder / 'index.html', 'index.html')
written = {}
while todo:
    src = todo.pop()
    pub = published(src)
    text = rewrite(io.open(src, encoding='utf-8').read(), src, pub)
    written[pub] = text
    dst = out / pub
    dst.parent.mkdir(parents=True, exist_ok=True)
    io.open(dst, 'w', encoding='utf-8', newline='\n').write(text)
# the game's other files (art, sounds, data): everything in its folder that is not a script, a page or a note
for f in sorted(folder.rglob('*')):
    if f.is_file() and f.suffix not in ('.js', '.mjs', '.html', '.md', '.py', '.lua') and f.name != 'package.json':
        pub = published(f)
        (out / pub).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(f, out / pub)
        files[pub] = f

# refuse a page whose scripts do not parse: a syntax error there blanks the whole game
if shutil.which('node'):
    io.open(out / 'package.json', 'w', encoding='utf-8', newline='\n').write('{ "type": "module" }\n')   # so Node reads the copies as modules (not published)
    check = out / '_check_page.mjs'
    a = page.index('<script type="module">') + len('<script type="module">')
    io.open(check, 'w', encoding='utf-8', newline='\n').write(page[a:page.index('</script>', a)])
    for f in [check] + [out / p for p in written]:
        r = subprocess.run(['node', '--check', str(f)], capture_output=True, text=True)
        if r.returncode != 0:
            check.unlink(missing_ok=True)
            sys.exit(f'{f.relative_to(root)} has a script error:\n{r.stderr}')
    check.unlink()

versions = {p: version(p) for p in SHARED}
stamp = f"{name} · engine {versions['engine']} · kit {versions['kit']} · modules {versions['modules']} · built {datetime.date.today().isoformat()}"
page = page.replace('<title>', f'<meta name="build" content="{stamp}">\n<title>', 1)
published_page = '<meta name="claude:viewport-fit-sides" content="cover">\n' + page
io.open(root / 'dist' / f'{name}.html', 'w', encoding='utf-8', newline='\n').write(published_page)
io.open(out / 'index.html', 'w', encoding='utf-8', newline='\n').write(HEADER + page)
manifest = {
    'name': name, 'built': datetime.datetime.now().isoformat(timespec='seconds'), 'shared': versions,
    'page': f'dist/{name}.html',
    'files': {p: s.relative_to(root).as_posix() for p, s in sorted(files.items())},
    'publish': {p: f'dist/{name}/{p}' for p in sorted(files)},
}
io.open(out / 'manifest.json', 'w', encoding='utf-8', newline='\n').write(json.dumps(manifest, indent=1) + '\n')
own = sum(1 for p in files if not p.startswith('shared/'))
print(f'built {name}: {own} files of its own, {len(files) - own} shared · {stamp}')
print(f'  open   http://localhost:8765/dist/{name}/index.html')
print(f'  publish dist/{name}.html with the files map in dist/{name}/manifest.json ("publish")')
