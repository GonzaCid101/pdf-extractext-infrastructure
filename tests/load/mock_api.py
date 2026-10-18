"""Mock del API para ensayar k6/Vegeta sin stack (RECORD=0).

Valida multipart y sha256 de los 4 PDFs oficiales; responde 200 {content, page_count} o 400.
GET / responde 200 (readiness).
"""
import hashlib
import json
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

FIXDIR = Path(__file__).resolve().parent / "pdfs"
NAMES = [
    "2020-Scrum-Guide-Spanish-Latin-South-American.pdf",
    "Essential-Kanban-Condensed-Spanish.pdf",
    "Filosofia Lean.pdf",
    "scrum_manager_historias_usuario.pdf",
]
FIXTURES = {n: (FIXDIR / n).read_bytes() for n in NAMES}
DIGESTS = {n: hashlib.sha256(b).hexdigest() for n, b in FIXTURES.items()}
PAGES = {n: 0 for n in NAMES}
state = {"hits": {n: 0 for n in NAMES}, "bad": 0, "no_file": 0}


def dump():
    with open("/tmp/opencode/mock-hits.json", "w") as f:
        json.dump(state, f)


def hit(kind, name=None):
    if name:
        state["hits"][name] += 1
    else:
        state[kind] += 1
    dump()


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, code, payload):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        self._send(200, b'{"service":"mock","status":"ok"}')

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        ct = self.headers.get("Content-Type", "")
        if "multipart/form-data" not in ct or b'name="file"' not in body:
            hit("no_file")
            self._send(400, b'{"error":"se requiere el campo multipart \'file\'"}')
            return
        m = re.search(rb'filename="([^"]+)"', body)
        if not m or m.group(1).decode() not in FIXTURES:
            hit("bad")
            self._send(400, b'{"error":"filename desconocido"}')
            return
        name = m.group(1).decode()
        part = body.split(b"\r\n\r\n", 1)[1]
        part = part[: part.rfind(b"\r\n--")]
        if hashlib.sha256(part).hexdigest() != DIGESTS[name]:
            hit("bad")
            self._send(400, b'{"error":"payload corrupto"}')
            return
        hit("hits", name)
        resp = json.dumps({"content": f"pdf-extractext mock {name}", "page_count": PAGES[name]}).encode()
        self._send(200, resp)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 8642), Handler).serve_forever()
