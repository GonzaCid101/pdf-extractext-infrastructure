// k6-spike.js — spike de carga contra POST /extract (Issue #4 / ADR D11).
//
// Perfil: rampa de subida 10s -> 100 VUs, 20s sostenidos a 100 VUs,
// rampa de bajada 10s -> 0. Cada iteración elige al azar uno de los 4
// fixtures PDF (tests/load/pdfs/) y lo envía por multipart/form-data
// en el campo "file" (contrato D14), vía el dominio público con TLS
// local de mkcert (insecureSkipTLSVerify).
//
// Métricas explícitas: p50, p90 y p95 de http_req_duration y el error
// rate (http_req_failed, status fuera de 2xx/3xx). Sin thresholds: el
// spike busca la saturación (503 controlado, D10) y debe medirla, no
// abortar por ella.
//
// Env configurable (defaults del repo):
//   TARGET_URL     endpoint atacado (default https://pdf-extractext.localhost/extract)
//   FIXTURES_DIR   carpeta con los PDFs   (default pdfs — relativa a este script)

import http from 'k6/http';

const TARGET_URL = __ENV.TARGET_URL || 'https://pdf-extractext.localhost/extract';
const FIXTURES_DIR = __ENV.FIXTURES_DIR || 'pdfs';
const FIXTURES = ['fixture-1p.pdf', 'fixture-3p.pdf', 'fixture-8p.pdf', 'fixture-20p.pdf'];

// open() solo es legal en el init context: se pre-cargan los 4 PDFs como
// binario antes de arrancar; cada iteración elige uno al azar.
const pdfs = FIXTURES.map(
  (name) => http.file(open(`${FIXTURES_DIR}/${name}`, 'b'), name, 'application/pdf')
);

export const options = {
  insecureSkipTLSVerify: true,
  stages: [
    { duration: '10s', target: 100 }, // subida
    { duration: '20s', target: 100 }, // sostén del spike
    { duration: '10s', target: 0 },   // bajada
  ],
  summaryTrendStats: ['avg', 'min', 'p(50)', 'p(90)', 'p(95)'],
};

export default function () {
  const pdf = pdfs[Math.floor(Math.random() * pdfs.length)];
  http.post(TARGET_URL, { file: pdf });
}
