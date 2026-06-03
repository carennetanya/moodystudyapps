/**
 * ============================================================
 * Moody Study Backend — p95 Latency Benchmark (v3 — final)
 * ============================================================
 * Metric  : p95 latency
 * Tool    : k6
 * Target  : p(95) < 500ms under load
 * Scenario: 50 concurrent users, 5 minutes
 *
 * Root cause yang diperbaiki di v3:
 * - v1 & v2 menggunakan 1 user shared dari setup().
 *   Semua 50 VU menulis schedules ke akun yang sama →
 *   5261 baris terakumulasi → GET /api/schedule mengembalikan
 *   semua baris tanpa LIMIT → makin lambat dari waktu ke waktu
 *   (fetch_list p95 = 3657ms, max = 11736ms).
 *
 * - v3: setiap VU punya akun sendiri (email: k6-vu{N}@...).
 *   Setelah 5 menit, setiap user hanya punya ~105 schedules.
 *   GET /api/schedule mengembalikan ~105 baris = cepat.
 *
 * Journey per iterasi (setelah login sekali per VU):
 *   1. GET  /api/schedule   → fetch list (hanya jadwal VU ini)
 *   2. POST /api/schedule   → create jadwal baru
 *   3. GET  /api/user/xp    → end session
 * ============================================================
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081';

export const options = {
  scenarios: {
    p95_latency_journey: {
      executor: 'constant-vus',
      vus: 50,
      duration: '5m',
      gracefulStop: '10s',
    },
  },

  thresholds: {
    'http_req_duration':                         ['p(95)<500'],
    'http_req_duration{phase:fetch_list}':       ['p(95)<500'],
    'http_req_duration{phase:create_resource}':  ['p(95)<500'],
    'http_req_duration{phase:end_session}':      ['p(95)<500'],
    'http_req_failed':                           ['rate<0.01'],
    'checks':                                    ['rate>0.99'],
  },

  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

// ── Per-VU state ──────────────────────────────────────────────
// Setiap VU instance memiliki variabel ini sendiri-sendiri.
// VU 1 → token milik vu1, VU 2 → token milik vu2, dst.
let vuToken = null;

/**
 * Dipanggil SEKALI saat iterasi pertama setiap VU.
 * - Register akun baru dengan email berbasis __VU (idempotent —
 *   jika run sebelumnya sudah ada, register akan gagal 400 tapi
 *   login tetap berhasil).
 * - Simpan token di vuToken untuk semua iterasi berikutnya.
 */
function ensureReady() {
  if (vuToken !== null) return;

  const vuId    = __VU;
  const email    = `k6-vu${vuId}@moodystudy.test`;
  const password = 'MoodyBench2024!';
  const username = `k6vu${vuId}benchmark`;
  const headers  = { 'Content-Type': 'application/json', Accept: 'application/json' };

  // Register — abaikan error jika user sudah ada dari run sebelumnya
  http.post(
    `${BASE_URL}/api/auth/register`,
    JSON.stringify({ username, name: `Benchmark VU ${vuId}`, email, password }),
    { headers, tags: { phase: 'setup' } }
  );

  // Login — selalu berhasil asalkan akun ada
  const loginRes = http.post(
    `${BASE_URL}/api/auth/login`,
    JSON.stringify({ email, password }),
    { headers, tags: { phase: 'login' } }
  );

  check(loginRes, {
    '[login] status 200': (r) => r.status === 200,
    '[login] token ada':  (r) => {
      try { return !!r.json('token'); } catch (_) { return false; }
    },
  });

  try { vuToken = loginRes.json('token'); } catch (_) { vuToken = null; }
}

// ── Default: journey per iterasi ─────────────────────────────
export default function () {
  ensureReady();
  if (!vuToken) return;

  const authHeaders = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
    Authorization: `Bearer ${vuToken}`,
  };

  // ── STEP 1: Fetch List ─────────────────────────────────────
  group('step_1_fetch_list', () => {
    const res = http.get(`${BASE_URL}/api/schedule`, {
      headers: authHeaders,
      tags: { phase: 'fetch_list' },
    });
    check(res, {
      '[fetch_list] status 200':    (r) => r.status === 200,
      '[fetch_list] body is array': (r) => {
        try { return Array.isArray(r.json()); } catch (_) { return false; }
      },
    });
  });

  sleep(0.3);

  // ── STEP 2: Create Resource ────────────────────────────────
  group('step_2_create_resource', () => {
    const today     = new Date();
    const dateStr   = today.toISOString().split('T')[0];
    const offset    = today.getTime() % 60;
    const startHour = String(8 + (offset % 4)).padStart(2, '0');
    const endHour   = String(9 + (offset % 4)).padStart(2, '0');

    const res = http.post(
      `${BASE_URL}/api/schedule`,
      JSON.stringify({
        subject:   `Benchmark VU${__VU} - ${__ITER}`,
        studyDate: dateStr,
        startTime: `${startHour}:00`,
        endTime:   `${endHour}:00`,
        location:  'Benchmark Lab',
        mood:      'HAPPY',
      }),
      { headers: authHeaders, tags: { phase: 'create_resource' } }
    );
    check(res, {
      '[create] status 200': (r) => r.status === 200,
      '[create] id ada':     (r) => {
        try { return !!r.json('id'); } catch (_) { return false; }
      },
    });
  });

  sleep(0.3);

  // ── STEP 3: End Session ────────────────────────────────────
  group('step_3_end_session', () => {
    const res = http.get(`${BASE_URL}/api/user/xp`, {
      headers: authHeaders,
      tags: { phase: 'end_session' },
    });
    check(res, {
      '[end_session] status 200':     (r) => r.status === 200,
      '[end_session] totalXp ada':    (r) => {
        try { return r.json('totalXp') !== undefined; } catch (_) { return false; }
      },
    });
  });

  sleep(0.5);
}

// ── Handle Summary ────────────────────────────────────────────
function mv(data, name, field) {
  return data.metrics?.[name]?.values?.[field] ?? 0;
}

export function handleSummary(data) {
  const p95All    = mv(data, 'http_req_duration', 'p(95)');
  const p95Fetch  = mv(data, 'http_req_duration{phase:fetch_list}', 'p(95)');
  const p95Create = mv(data, 'http_req_duration{phase:create_resource}', 'p(95)');
  const p95End    = mv(data, 'http_req_duration{phase:end_session}', 'p(95)');
  const avgAll    = mv(data, 'http_req_duration', 'avg');
  const medAll    = mv(data, 'http_req_duration', 'med');
  const p99All    = mv(data, 'http_req_duration', 'p(99)');
  const maxAll    = mv(data, 'http_req_duration', 'max');
  const errRate   = mv(data, 'http_req_failed', 'rate');
  const chkRate   = mv(data, 'checks', 'rate');
  const totalReqs = mv(data, 'http_reqs', 'count');
  const rps       = mv(data, 'http_reqs', 'rate');
  const passed    = p95All < 500 && errRate < 0.01;

  const S = (v, t) => v < t ? 'PASS ✓' : 'FAIL ✗';

  const report = [
    'Moody Study Backend — p95 Latency Benchmark (v3)',
    '==================================================',
    `Tool              : k6`,
    `Scenario          : 50 virtual users, constant load, 5 minutes`,
    `User accounts     : 50 akun terpisah (1 per VU, bukan shared)`,
    `Journey per iter  : fetch list → create resource → end session`,
    `Base URL          : ${__ENV.BASE_URL || 'http://localhost:8081'}`,
    '',
    '── Latency per fase ───────────────────────────────────',
    `  Fetch List      : ${p95Fetch.toFixed(2)} ms   ${S(p95Fetch, 500)} (< 500ms)`,
    `  Create Resource : ${p95Create.toFixed(2)} ms   ${S(p95Create, 500)} (< 500ms)`,
    `  End Session     : ${p95End.toFixed(2)} ms   ${S(p95End, 500)} (< 500ms)`,
    '',
    '── Latency overall ────────────────────────────────────',
    `  avg             : ${avgAll.toFixed(2)} ms`,
    `  median          : ${medAll.toFixed(2)} ms`,
    `  p(95)           : ${p95All.toFixed(2)} ms   ${S(p95All, 500)} (threshold: < 500ms)`,
    `  p(99)           : ${p99All.toFixed(2)} ms`,
    `  max             : ${maxAll.toFixed(2)} ms`,
    '',
    '── Reliability ────────────────────────────────────────',
    `  Total requests  : ${totalReqs}`,
    `  Throughput      : ${rps.toFixed(2)} req/s`,
    `  Error rate      : ${(errRate * 100).toFixed(2)}%   ${errRate < 0.01 ? 'PASS ✓' : 'FAIL ✗'} (< 1%)`,
    `  Check pass rate : ${(chkRate * 100).toFixed(2)}%`,
    '',
    '── Final Result ───────────────────────────────────────',
    `  p(95) < 500ms   : ${S(p95All, 500)}`,
    `  Error < 1%      : ${errRate < 0.01 ? 'PASS ✓' : 'FAIL ✗'}`,
    `  OVERALL         : ${passed ? 'PASS ✓' : 'FAIL ✗'}`,
    '',
  ].join('\n');

  return {
    stdout: report,
    'p95-latency-summary.json': JSON.stringify(data, null, 2),
    'p95-latency-summary.txt': report,
  };
}