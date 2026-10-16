import http from 'k6/http';
import { check } from 'k6';
import { Rate } from 'k6/metrics';

const extractOk = new Rate('extract_ok');

export const options = {
    stages: [
        { duration: '10s', target: 1 },
        { duration: '20s', target: 1 },
        { duration: '10s', target: 0 },
    ],
};

const BASE_URL = 'https://pdf-extractext.localhost';

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
}
