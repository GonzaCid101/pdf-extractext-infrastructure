import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const extractOk = new Rate('extract_ok');

// Perfil del TP: 0→100 VUs en 10s, 100 VUs 20s, 100→0 en 10s (40s).
// TARGET_VUS permite parametrizar el spike (p. ej. ensayo con 10 VUs).
const TARGET_VUS = Number(__ENV.TARGET_VUS || 100);

export const options = {
    stages: [
        { duration: '10s', target: TARGET_VUS },
        { duration: '20s', target: TARGET_VUS },
        { duration: '10s', target: 0 },
    ],
    // Percentiles explícitos para el informe (p50/p90/p95/p99).
    summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

const BASE_URL = __ENV.BASE_URL || 'https://pdf-extractext.localhost';

const PDFS = [
    { path: './pdfs/2020-Scrum-Guide-Spanish-Latin-South-American.pdf', name: '2020-Scrum-Guide-Spanish-Latin-South-American.pdf' },
    { path: './pdfs/Essential-Kanban-Condensed-Spanish.pdf', name: 'Essential-Kanban-Condensed-Spanish.pdf' },
    { path: './pdfs/Filosofia Lean.pdf', name: 'Filosofia Lean.pdf' },
    { path: './pdfs/scrum_manager_historias_usuario.pdf', name: 'scrum_manager_historias_usuario.pdf' },
];

const pdfData = PDFS.map(({ path }) => open(path, 'b'));

export default function () {
    const idx = Math.floor(Math.random() * PDFS.length);
    const { name } = PDFS[idx];

    const payload = {
        file: http.file(pdfData[idx], name, 'application/pdf'),
    };

    const res = http.post(`${BASE_URL}/extract`, payload);

    const ok = check(res, {
        'estado HTTP 200': (r) => r.status === 200,
        'JSON con content y page_count': (r) => {
            try {
                const json = r.json();
                return typeof json.content === 'string' && json.content.length > 0
                    && Number.isInteger(json.page_count) && json.page_count > 0;
            } catch (_) {
                return false;
            }
        },
    });

    extractOk.add(ok);

    sleep(0.5);
}

// k6 v2.x ya no soporta --summary-export: el resumen se escribe aquí.
// Ruta configurable vía K6_SUMMARY_PATH (default: cwd/k6-summary.json).
export function handleSummary(data) {
    const path = __ENV.K6_SUMMARY_PATH || 'k6-summary.json';
    return {
        [path]: JSON.stringify(data, null, 2),
        stdout: textSummary(data),
    };
}

// Resumen de consola legible (equivalente mínimo al de k6).
function textSummary(data) {
    const m = data.metrics || {};
    const dur = m.http_req_duration ? m.http_req_duration.values : {};
    const reqs = m.http_reqs ? m.http_reqs.values : {};
    const okv = m.extract_ok ? m.extract_ok.values : {};
    const failed = m.http_req_failed ? m.http_req_failed.values : {};
    const line = (k, v) => `${k.padEnd(28)} ${v}`;
    return [
        '',
        '== k6 spike (/extract) ==',
        line('http_reqs (total)', reqs.count ?? 0),
        line('http_reqs (rate req/s)', (reqs.rate ?? 0).toFixed(2)),
        line('checks success (extract_ok)', ((okv.rate ?? 0) * 100).toFixed(1) + ' %'),
        line('http_req_failed', ((failed.rate ?? 0) * 100).toFixed(2) + ' %'),
        line('p50 (ms)', (dur['med'] ?? 0).toFixed(1)),
        line('p90 (ms)', (dur['p(90)'] ?? 0).toFixed(1)),
        line('p95 (ms)', (dur['p(95)'] ?? 0).toFixed(1)),
        line('p99 (ms)', (dur['p(99)'] ?? 0).toFixed(1)),
        line('max (ms)', (dur['max'] ?? 0).toFixed(1)),
        '',
    ].join('\n');
}
