"""Mock del API para validar k6/vegeta: verifica el multipart byte a byte.

POST /extract: parsea el multipart, extrae el payload del campo "file" y lo
compara por sha256 contra los fixtures reales. Responde 200 con el contrato
{content, page_count} o 400 si el binario no coincide.
GET  /: 200 (readiness).
Vuelca hits por fixture y rechazos a /tmp/opencode/mock-hits.json en cada request.
"""
import hashlib
import json
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

FIXDIR = Path(__file__).resolve().parent / "pdfs"
NAMES = ["fixture-1p.pdf", "fixture-3p.pdf", "fixture-8p.pdf", "fixture-20p.pdf"]
FIXTURES = {n: (FIXDIR / n).read_bytes() for n in NAMES}
PAGES = {"fixture-1p.pdf": 1, "fixture-3p.pdf": 3, "fixture-8p.pdf": 8, "fixture-20p.pdf": 20}
state = {"hits": {n: 0 for n in NAMES}, "bad": 0, "no_file": 0}


def dump():
    with open("/tmp/opencode/mock-hits.json", "w") as f:
        json.dump(state, f)


# Dump por request: el estado sobrevive a cualquier apagado del mock.
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
        payload = body.split(b"\r\n\r\n", 1)[1]
        payload = payload[: payload.rfind(b"\r\n--")]
        if hashlib.sha256(payload).hexdigest() != hashlib.sha256(FIXTURES[name]).hexdigest():
            hit("bad")
            self._send(400, b'{"error":"payload corrupto"}')
            return
        hit("hits", name)
        resp = json.dumps(
            {"content": f"pdf-extractext load fixture p1/{PAGES[name]}", "page_count": PAGES[name]}
        ).encode()
        self._send(200, resp)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 8642), Handler).serve_forever()
