"""Local dev server for the project root, with caching switched off.

Plain `python -m http.server` lets browsers keep old copies of the engine's module files,
so an edit can silently not show up. This one tells the browser never to cache.

    python tools/serve.py [port]      (default 8765)
"""
import functools
import os
import http.server
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

    def do_POST(self):
        # A page under test may save a picture of itself: POST /__shot/<name>.png with the image as the body writes
        # dist/_shots/<name>.png. For looking at a canvas when the browser cannot be seen. Local use only.
        name = pathlib.PurePosixPath(self.path).name
        if not self.path.startswith('/__shot/') or not name.endswith('.png') or '..' in name:
            self.send_error(404)
            return
        body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
        out = ROOT / 'dist' / '_shots'
        out.mkdir(parents=True, exist_ok=True)
        (out / name).write_bytes(body)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'saved')


if __name__ == '__main__':
    # A launcher that had to move the server to another port says so in PORT; that wins over the argument.
    port = int(os.environ.get('PORT') or (sys.argv[1] if len(sys.argv) > 1 else 8765))
    handler = functools.partial(NoCacheHandler, directory=str(ROOT))
    with http.server.ThreadingHTTPServer(('', port), handler) as httpd:
        print(f'Serving {ROOT} at http://localhost:{port}/ (no caching)')
        httpd.serve_forever()
