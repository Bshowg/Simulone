"""Check every game before a change to the shared code (engine, kit, modules) goes out.

    python tools/test-all.py                 all games
    python tools/test-all.py mall            one game (lords-will, mall, ant-colony, war, shared)

For each game it builds the published folder (which fails on a missing file or a script that does not parse) and runs
its headless tests from tools/tests/. A test passes when it exits cleanly and, where it says so, prints its PASS line.
The tests run side by side; the whole set takes about a minute. Exit code 0 only if everything passed.
"""
import concurrent.futures
import pathlib
import subprocess
import sys
import time

root = pathlib.Path(__file__).resolve().parent.parent
# game -> [(what, command, line the output must contain or None)]
SUITE = {
    'shared': [
        ('build the examples', ['python', 'tools/build-artifact.py', 'anthill'], 'built anthill'),
        ('the town example, money conserved', ['node', 'tools/tests/town.mjs', '.', '6', 'both'], None),
        ('progress module', ['node', 'tools/tests/progress_test.mjs'], None),
        ('goals kept by id, old saves', ['node', 'tools/tests/progress_goals_test.mjs'], 'PASS'),
    ],
    'lords-will': [
        ('build', ['python', 'tools/build-artifact.py', 'lords-will'], 'built lords-will'),
        ('save and load', ['node', 'tools/tests/save_test.mjs'], 'PASS'),
        ('two years with a steward', ['node', 'tools/tests/village.mjs', '2'], None),
        ('several lands and carts', ['node', 'tools/tests/region_test.mjs'], None),
        ('fire', ['node', 'tools/tests/fire_test.mjs'], None),
        ('the late stages', ['node', 'tools/tests/charter_test.mjs'], None),
    ],
    'mall': [
        ('build', ['python', 'tools/build-artifact.py', 'mall'], 'built mall'),
        ('four days with a manager', ['node', 'tools/tests/mall.mjs', '4'], 'PASS'),
        ('save and load', ['node', 'tools/tests/mall_save_test.mjs'], 'PASS'),
        ('events and upkeep', ['node', 'tools/tests/mall_events_test.mjs'], 'PASS'),
        ('floors', ['node', 'tools/tests/mall_floors_test.mjs'], 'PASS'),
    ],
    'ant-colony': [
        ('build', ['python', 'tools/build-artifact.py', 'ant-colony'], 'built ant-colony'),
        ('three minutes, save and load', ['node', 'tools/tests/colony.mjs', '3'], 'PASS'),
    ],
    'war': [
        ('build', ['python', 'tools/build-artifact.py', 'war'], 'built war'),
        ('a battle, 4,000 against 4,000', ['node', 'tools/tests/war_battle.mjs', '4000', '5', 'plain', 'quiet'], 'PASS'),
        ('the war: a march, a battle, saves', ['node', 'tools/tests/war.mjs'], 'PASS'),
    ],
}


def run(game, what, cmd, want):
    t = time.time()
    try:
        r = subprocess.run(cmd, cwd=root, capture_output=True, text=True, timeout=600, encoding='utf-8', errors='replace')
        out = r.stdout + r.stderr
        ok = r.returncode == 0 and (want is None or want in out)
    except subprocess.TimeoutExpired:
        out, ok = 'timed out after 10 minutes', False
    return game, what, ok, time.time() - t, out


pick = sys.argv[1:] or list(SUITE)
jobs = [(g, *t) for g in pick for t in SUITE[g]]
# builds write into dist/<name>/: run them first, one at a time, then the tests side by side
results = [run(*j) for j in jobs if j[2][1].endswith('build-artifact.py')]
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    results += list(pool.map(lambda j: run(*j), [j for j in jobs if not j[2][1].endswith('build-artifact.py')]))
order = {(g, w): k for k, (g, w, *_) in enumerate(jobs)}
results.sort(key=lambda r: order[(r[0], r[1])])
failed = [r for r in results if not r[2]]
for game, what, ok, secs, out in results:
    print(f"{'ok  ' if ok else 'FAIL'} {game:<11} {what:<36} {secs:5.1f} s")
for game, what, ok, secs, out in failed:
    print(f'\n--- {game}: {what} ---\n' + '\n'.join(out.strip().splitlines()[-15:]))
print(f'\n{len(results) - len(failed)} of {len(results)} passed')
sys.exit(1 if failed else 0)
